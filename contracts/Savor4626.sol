// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "./Solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "./Solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "./Solmate/utils/FixedPointMathLib.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol)
abstract contract Savor4626 is ERC20, ReentrancyGuard {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, _asset.decimals()) {
        asset = _asset;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mapping that tracks how many shares are pending withdraw for each address in waitingOnWithdrawls
    /// @dev To find the amount user can withdraw take balanceOf[owner] - sharesPending[owner]
    /// The value of all shares pending will be sent to the owner on the next harvest 
    mapping (address => uint256) public sharesPending;

    /// @notice The total amount of shares that needs to be pulled on the next harvest from another chain
    uint256 public pendingWithdrawals;

    /// @notice A dynamic Array of addresses that need to be payed a certain amount of shares on next harvest
    address[] waitingOnWithdrawals;

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual nonReentrant returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            require(allowed >= shares, "Not enough Allowance");

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        //Check to see if they have a pending withdraw for these shares
        require(balanceOf[owner] >= shares, "Not enough shares for this Withdraw");

        (bool _allAvailable, uint256 _amountAvailable) = beforeWithdraw(assets, receiver);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        if(_allAvailable) {
            asset.safeTransfer(receiver, assets);
        } else {
            asset.safeTransfer(receiver, _amountAvailable);
        }
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual nonReentrant returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            require(allowed >= shares, "Not enough Allowance");

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        //Check to see if they have a pending withdraw for these shares
        require(balanceOf[owner] >= shares, "Not enough shares for this Withdraw");

        (bool _allAvailable, uint256 _amountAvailable) = beforeWithdraw(assets, receiver);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        if(_allAvailable) {
            asset.safeTransfer(receiver, assets);
        } else {
            asset.safeTransfer(receiver, _amountAvailable);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice the PPS scaled 1e18 for calculating shares to assets and back
    /// @dev This number is s combination of total supply and assets accross all chains and can only be updated by the Keeper
    uint256 public virtualPrice;

    function totalAssets() public view virtual returns (uint256);

    function _totalSupply() public view virtual returns(uint256);

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        return assets.divWadDown(virtualPrice);
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        return shares.mulWadDown(virtualPrice);
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        return shares.mulWadUp(virtualPrice);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        return assets.divWadUp(virtualPrice);
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(maxRedeem(owner));
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    function totalUserBalance(address owner) public view returns (uint256) {
        return balanceOf[owner] + sharesPending[owner];
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, address owner) internal virtual returns (bool, uint256) {}

    function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
}