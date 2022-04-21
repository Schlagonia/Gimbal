// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { IStargateRouter } from "./Interfaces/Stargate/IStargateRouter.sol";

contract Bridgerton is Ownable{
    using SafeERC20 for IERC20;
    using Address for address;

    uint8 public constant TYPE_SWAP_REMOTE = 1;

    mapping (address => uint256) public pids;

    address public stargateRouter;

    uint256 slippageProtectionOut = 50; //out of 10000. 50 = 0.5%
    uint256 constant DENOMINATOR = 10_000;

    event sgReceived(
        uint16 _chainId,
        bytes _srcAddress,
        address _token,
        uint256 amountLD
    );

    constructor(
        address _stargateRouter,
        address _usdc,
        address _usdt
    ) {
        stargateRouter = _stargateRouter;

        pids[_usdc] = 1;
        pids[_usdt] = 2;
    }

    function _changeStargateRouter(address _router) external onlyOwner {
        require(_router != address(0), 'Must be validly address');
        stargateRouter = _router;
    }

    //can be used to add a new asset or change a current one
    function addAsset(address _address, uint256 _pid) external onlyOwner {
        pids[_address] = _pid;
    }

    //get the expected gas fee\
    function getSwapFee(
        uint16 _dstChainId, 
        address[] memory _vaultTo
    ) external view returns(uint256) {

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

    //get the expected gas fee\
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

    function getMinOut(uint256 _amountIn) internal view returns(uint256) {
        return (_amountIn * (DENOMINATOR - slippageProtectionOut)) / DENOMINATOR;
    }

    //call the swap function to swap accorss chains
    function _swap(
        uint16 chainId, 
        address _asset, 
        uint256 _amount,
        address[] memory _vaultTo
    ) external payable onlyOwner returns(bool){
        require(IERC20(_asset).balanceOf(address(this)) >= _amount, "Contract doesn't Hold enough tokens");

        uint256 pid = pids[_asset];
        require(pid != 0, "Asset Not Added");

        uint256 qty = _amount;
        uint256 amountOutMin = getMinOut(_amount);

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

    receive() external payable{}

}