// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@rari-capital/solmate/src/tokens/ERC4626.sol";
import "./Bridgerton.sol";

contract GimbalVault is Bridgerton, ERC4626 {
    using SafeERC20 for IERC20;
    using Address for address;

    constructor(
        address _stargateRouter,
        address _usdc,
        address _usdt
    ) 
    Bridgerton(_stargateRouter, _usdc, _usdt) 
    ERC4626(ERC20(_usdc), "Gimbal Vault", "gUSDC")
    {

    }

    function beforeWithdraw(uint256 assets, uint256 shares) internal override{}

    function afterDeposit(uint256 assets, uint256 shares) internal override {}
    
}