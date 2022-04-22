// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "../Solmate/tokens/ERC20.sol";

interface Strategy {   
    function name() external view returns (string memory);

    function vault() external view returns (address);

    /// @notice Returns the underlying ERC20 token the strategy accepts.
    /// @return The underlying ERC20 token the strategy accepts.
    function underlying() external view returns (ERC20);

    function owner() external view returns (address);

    function isActive() external view returns (bool);

    /// @notice Deposit a specific amount of underlying tokens into the strategy.
    /// @param amount The amount of underlying tokens to deposit.
    /// @return An error code, or 0 if the deposit was successful.
    function deposit(uint256 amount) external returns (uint256);

    /// @notice Withdraws a specific amount of underlying tokens from the strategy.
    /// @param amount The amount of underlying tokens to withdraw.
    /// @return An error code, or 0 if the withdrawal was successful.
    function withdraw(uint256 amount) external returns (uint256);

    /// @notice Returns a user's strategy balance in underlying tokens.
    /// @return The user's strategy balance in underlying tokens.
    /// @dev May mutate the state of the strategy by accruing interest.
    function estimatedTotalAssets() external view returns (uint256);

}