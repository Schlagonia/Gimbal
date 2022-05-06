// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import {IStargateRouter} from "./Interfaces/Stargate/IStargateRouter.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract Bridgerton is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    /// @notice Type variable to pass in to router per Stargate Docs
    uint8 public constant TYPE_SWAP_REMOTE = 1;

    /// @notice Mapping to retrive the PID based on the address of the token
    mapping(address => uint256) public pids;

    /// @notice Address of Stargate Router on this chain
    address public stargateRouter;

    /// @notice Mapping of the Vaults that are allowed to call the contract
    /// returns true if they have been allowed or false otherwise
    mapping(address => bool) public vaults;

    /// @notice Variables to calculate Min amount welll accept to be recieved. i.e. Slippage
    uint256 slippageProtectionOut = 50; //out of 10000. 50 = 0.5%
    uint256 constant DENOMINATOR = 10_000;

    /// @notice Emitted when the Funds are received by this contract from Stargate router.
    /// @param _chainId The chain from which the funds were sent.
    /// @param _srcAddress The address the sent the transaction. Should be the same as address(this).
    /// @param _token Address of the token that was received. Should Be UNDERLYING
    /// @param amountLD Amount of token received
    event sgReceived(
        uint16 _chainId,
        bytes _srcAddress,
        address _token,
        uint256 amountLD
    );

    /// @notice Called when vault is deployed. Sets router and PID for Underlying
    /// @dev PID needs to be adjusted before deployment for what chain and asset is being deployed per Stargate Docs
    /// @param _stargateRouter Address of the router
    constructor(address _stargateRouter) {
        stargateRouter = _stargateRouter;
    }

    /// @notice Changes the status of whether or not a vault can call the swap function.
    /// @param _vault address of the Vault
    function setVault(address _vault) external onlyOwner {
        require(_vault != address(0));
        bool current = vaults[_vault];
        vaults[_vault] = !current;
    }

    /// @notice Used to add a new asset or change a current one
    /// @param _address Address of a supported token for this chain
    /// @param _pid Associated stargate PID for the token
    function addAsset(address _address, uint256 _pid) external onlyOwner {
        pids[_address] = _pid;
    }

    /// @notice Updates the stargate Router used for cross chain swaps
    /// @param _router The new Stargate Router Address
    function _changeStargateRouter(address _router) external onlyOwner {
        require(_router != address(0), "Must be valid address");
        stargateRouter = _router;
    }

    /// @notice Updates the allowed slippage for cross chain swaps
    /// @param _slippage The new slippage param
    function _setSlippageProtectionOut(uint256 _slippage) external onlyOwner {
        require(_slippage < 10000, "Slippage to High");
        slippageProtectionOut = _slippage;
    }

    /// @notice Function for external Account or Keeper to call to estimate cross chain Gas fee
    /// @param _dstChainId ID of chain we are swapping to
    /// @param _toAddress Address of the vault that we want to swap on behalf of
    /// @param _vaultTo The Strategy that the receiving Vault should send funds to
    function externalGetSwapFee(
        uint16 _dstChainId,
        address _toAddress,
        address _vaultTo
    ) external view returns (uint256) {
        bytes memory toAddress = abi.encodePacked(_toAddress);
        bytes memory _data = abi.encodePacked(_vaultTo);

        (uint256 nativeFee, ) = IStargateRouter(stargateRouter)
            .quoteLayerZeroFee(
                _dstChainId,
                TYPE_SWAP_REMOTE,
                toAddress,
                _data,
                IStargateRouter.lzTxObj(0, 0, "0x")
            );

        return nativeFee;
    }

    /// @notice Internal Function call for contract to assure we have enough gas before sending transaction
    /// @param _dstChainId CHain Id for where assets are going
    /// @param _toAddress Encoded address for where assets are going. Should be address(this)
    /// @param _data Encoded payload for any info we are sending off chain
    function _getSwapFee(
        uint16 _dstChainId,
        bytes memory _toAddress,
        bytes memory _data
    ) internal view returns (uint256) {
        (uint256 nativeFee, ) = IStargateRouter(stargateRouter)
            .quoteLayerZeroFee(
                _dstChainId,
                TYPE_SWAP_REMOTE,
                _toAddress,
                _data,
                IStargateRouter.lzTxObj(0, 0, "0x")
            );

        return nativeFee;
    }

    /// @notice internal function to get min aount we will accept out of swap. i.e. slippage
    /// @param _amountIn Amount that we are sending in
    function _getMinOut(uint256 _amountIn) internal view returns (uint256) {
        return
            (_amountIn * (DENOMINATOR - slippageProtectionOut)) / DENOMINATOR;
    }

    /// @notice Initiates a Cross chain tx to the dstChain
    /// @dev Must be called by a vault that has been previously approved.
    /// @param chainId The Stargate ChainId for the destination chain
    /// @param _asset Asset that should be swapped and recieved.
    /// @param _amount The amount of underlying that should be swapped
    /// @param _vaultTo The Strategy that the receiving Vault should send funds to if applicable
    function swap(
        uint16 chainId,
        address _asset,
        uint256 _amount,
        address _vaultTo
    ) external payable returns (bool) {
        require(vaults[msg.sender] == true, "Get your own contract bruh");
        require(
            IERC20(_asset).balanceOf(address(this)) >= _amount,
            "Contract doesn't Hold enough tokens"
        );

        uint256 pid = pids[_asset];
        require(pid != 0, "Asset Not Added");

        uint256 qty = _amount;
        uint256 amountOutMin = _getMinOut(_amount);

        bytes memory _toAddress = abi.encodePacked(msg.sender);
        bytes memory data = abi.encodePacked(_vaultTo);

        require(
            msg.value >= _getSwapFee(chainId, _toAddress, data),
            "Not enough funds for gas"
        );

        IERC20(_asset).approve(stargateRouter, qty);

        IStargateRouter(stargateRouter).swap{value: msg.value}(
            chainId, // send to Fuji (use LayerZero chainId)
            pid, // source pool id
            pid, // dest pool id
            payable(tx.origin), // refund adddress. extra gas (if any) is returned to this address
            qty, // quantity to swap
            amountOutMin, // the min qty you would accept on the destination
            IStargateRouter.lzTxObj(0, 0, "0x"), // 0 additional gasLimit increase, 0 airdrop, at 0x address
            _toAddress, // the address to send the tokens to on the destination
            data // bytes param, if you wish to send additional payload you can abi.encode() them here
        );

        return true;
    }

    /// @notice function for the stargate router to call when funds are being received from another chain
    /// @param _chainId Chain from which the assets came
    /// @param _srcAddress Address who initiated the transfer. Should be address(this)
    /// @param _nonce Nonce the transaction occured on
    /// @param _token Address of token that was transferred. Should be UNDERLYING
    /// @param amountLD The amount that was received
    /// @param payload Encoded payload with any instructions sent over
    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external {
        emit sgReceived(_chainId, _srcAddress, _token, amountLD);
    }

    /// @notice Sweep function in case any tokens get stuck in the contract
    /// @param _asset Address of the token to sweep
    function sweep(address _asset) external onlyOwner {
        IERC20(_asset).safeTransfer(
            msg.sender,
            IERC20(_asset).balanceOf(address(this))
        );
    }

    /// @dev Required for the Vault to receive unwrapped ETH.
    receive() external payable {}
}
