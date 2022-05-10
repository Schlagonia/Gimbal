
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC4626 } from './IERC4626.sol';

import { Strategy } from './IStrategy.sol'; 

interface IVault is IERC4626 {
    /*///////////////////////////////////////////////////////////////
                                Custom ERC4626 add ons
    //////////////////////////////////////////////////////////////*/

    /// @notice Mapping that tracks how many shares are pending withdraw for each address in waitingOnWithdrawls
    /// @dev To find the amount user can withdraw take balanceOf[owner] - sharesPending[owner]
    /// The value of all shares pending will be sent to the owner on the next harvest 
    function sharesPending(address _address) external view returns(uint256);

    /// @notice Returns the total amount of shares that needs to be pulled on the next harvest from another chain
    function pendingWithdrawals() external view returns(uint256);

    /// @notice Returns  dynamic Array of addresses that need to be payed a certain amount of shares on next harvest
    function waitingOnWithdrawals() external view returns(uint256[] memory);

    /*///////////////////////////////////////////////////////////////
                                IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The underlying token the Vault accepts.
    function UNDERLYING() external view returns(ERC20);

    /// @notice The percentage of profit recognized each harvest to reserve as fees.
    /// @dev A fixed point number where 1e18 represents 100% and 0 represents 0%.
    function feePercent() external view returns(uint256);
   
    /// @notice Sets a new fee percentage.
    /// @param newFeePercent The new fee percentage.
    function setFeePercent(uint256 newFeePercent) external;

    /// @notice The desired percentage of the Vault's holdings to keep as float.
    /// @dev A fixed point number where 1e18 represents 100% and 0 represents 0%.
    function targetFloatPercent() external view returns(uint256);

    /// @notice The total amount of underlying tokens held in strategies at the time of the last harvest.
    /// @dev Includes maxLockedProfit, must be correctly subtracted to compute available/free holdings.
    function totalStrategyHoldings() external view returns(uint256);

    /// @dev Packed struct of strategy data.
    /// @param trusted Whether the strategy is trusted.
    /// @param balance The amount of underlying tokens held in the strategy.
    struct StrategyData {
        // Used to determine if the Vault will operate on a strategy.
        bool trusted;
        // Used to determine profit and loss during harvests of the strategy.
        uint248 balance;
    }

    /// @notice Maps strategies to data the Vault holds on them.
    function getStrategyData(Strategy _strategy) external view returns(StrategyData memory);

    /// @notice Calculates the total amount of underlying tokens the Vault holds.
    /// @return totalUnderlyingHeld The total amount of underlying tokens the Vault holds.
    function totalAssets() external view returns (uint256 totalUnderlyingHeld);

    /// @notice Returns the amount of underlying tokens that idly sit in the Vault.
    /// @return The amount of underlying tokens that sit idly in the Vault.
    function totalFloat() external view returns (uint256);

    /// @notice Whether the Vault has been initialized yet.
    /// @dev Can go from false to true, never from true to false.
    function isInitialized() external view returns(bool);

}
