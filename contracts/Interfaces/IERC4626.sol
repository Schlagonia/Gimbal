
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import { IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC4626 is IERC20 {
    
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) external  returns (uint256 shares);

    function mint(uint256 shares, address receiver) external  returns (uint256 assets);

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external  returns (uint256 shares);

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external  returns (uint256 assets);

    
    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/


    function totalAssets() external view  returns (uint256);

    function convertToAssets(uint256 shares) external view  returns (uint256);

    function previewDeposit(uint256 assets) external view  returns (uint256);

    function previewMint(uint256 shares) external view  returns (uint256);

    function previewWithdraw(uint256 assets) external view  returns (uint256);

    function previewRedeem(uint256 shares) external view  returns (uint256);  
    
    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) external view  returns (uint256);

    function maxMint(address) external view  returns (uint256);

    function maxWithdraw(address owner) external view  returns (uint256);

    function maxRedeem(address owner) external view  returns (uint256);
    
}
