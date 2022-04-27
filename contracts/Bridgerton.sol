// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import { IStargateRouter } from "./Interfaces/Stargate/IStargateRouter.sol";

contract Bridgerton{
    using SafeERC20 for IERC20;
    using Address for address;

    /// @notice Type variable to pass in to router per Stargate Docs
    uint8 public constant TYPE_SWAP_REMOTE = 1;

    /// @notice PID repersenting the Underlying per Stargate Docs
    uint256 PID;

    /// @notice Address of Stargate Router on this chain
    address public stargateRouter;

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
    constructor(
        address _stargateRouter
    ) {
        stargateRouter = _stargateRouter;
        //Set th PID for underlying token. Currently 1 for USDC
        PID = 1;

    }

    /// @notice Updates the stargate Router used for cross chain swaps
    /// @param _router The new Stargate Router Address
    function _changeStargateRouter(address _router) internal  {
        require(_router != address(0), 'Must be validly address');
        stargateRouter = _router;
    }

    /// @notice Updates the allowed slippage for cross chain swaps
    /// @param _slippage The new slippage param
    function _setSlippageProtectionOut(uint256 _slippage) internal {
        require(_slippage < 10000, "Slippage to High");
        slippageProtectionOut = _slippage;
    }

    /// @notice Updates the PID for the Underlying asset
    /// @param _pid New PID for the underlying token
    function _setPid(uint256 _pid) internal  {
        PID = _pid;
    }

    /// @notice Function for external Account or Keeper to call to estimate cross chain Gas fee
    /// @param _dstChainId ID of chain we are swapping to
    /// @param _vaultTo The Strategy that the receiving Vault should send funds to
    function _externalGetSwapFee(
        uint16 _dstChainId, 
        address _vaultTo
    ) internal view returns(uint256) {

        bytes memory _toAddress = abi.encodePacked(address(this));
        bytes memory _data =  abi.encodePacked(_vaultTo);

        (uint256 nativeFee, ) = IStargateRouter(stargateRouter).quoteLayerZeroFee(
            _dstChainId, 
            TYPE_SWAP_REMOTE, 
            _toAddress, 
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
    ) internal view returns(uint256) {

        (uint256 nativeFee,) = IStargateRouter(stargateRouter).quoteLayerZeroFee(
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
    function _getMinOut(uint256 _amountIn) internal view returns(uint256) {
        return (_amountIn * (DENOMINATOR - slippageProtectionOut)) / DENOMINATOR;
    }

    /// @notice Initiates a Cross chain to the dstChain
    /// @dev Must be called by contract owner or Keeper. Calls to Bridgerton Function.
    /// @param chainId The Stargate ChainId for the destination chain
    /// @param _asset Asset that should be swapped and recieved. Should be UNDERLYING
    /// @param _amount The amount of underlying that should be swapped
    /// @param _vaultTo The Strategy that the receiving Vault should send funds to
    function _swap(
        uint16 chainId, 
        address _asset, 
        uint256 _amount,
        address _vaultTo
    ) internal returns(bool) {
        require(IERC20(_asset).balanceOf(address(this)) >= _amount, "Contract doesn't Hold enough tokens");

        uint256 pid = PID;

        uint256 qty = _amount;
        uint256 amountOutMin = _getMinOut(_amount);

        bytes memory _toAddress = abi.encodePacked(address(this));
        bytes memory data =  abi.encodePacked(_vaultTo);

        require(msg.value >= _getSwapFee(chainId, _toAddress, data), "Not enough funds for gas");

        IERC20(_asset).approve(stargateRouter, qty);

        IStargateRouter(stargateRouter).swap{value:msg.value}(
            chainId,                         // send to Fuji (use LayerZero chainId)
            pid,                             // source pool id
            pid,                             // dest pool id                 
            payable(address(this)),          // refund adddress. extra gas (if any) is returned to this address
            qty,                             // quantity to swap
            amountOutMin,                    // the min qty you would accept on the destination
            IStargateRouter.lzTxObj(0, 0, "0x"),  // 0 additional gasLimit increase, 0 airdrop, at 0x address
            _toAddress,    // the address to send the tokens to on the destination
            data         // bytes param, if you wish to send additional payload you can abi.encode() them here
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
        

        emit sgReceived(
            _chainId,
            _srcAddress,
            _token,
            amountLD
        );
    }

}