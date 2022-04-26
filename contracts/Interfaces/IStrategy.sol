// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "../Solmate/tokens/ERC20.sol";

interface Strategy {   

    /// @notice Returns the Name of the Strategy
    function name() external view returns (string memory);

    /// @notice Returns the Vault this Strategy is assigned to
    function vault() external view returns (address);

    /// @notice Returns the underlying ERC20 token the strategy accepts.
    /// @return The underlying ERC20 token the strategy accepts.
    function underlying() external view returns (ERC20);

    /// @notice Returns the addrss of the Owner that deployed the strategy
    function owner() external view returns (address);

    /// @notice returns True if the Strategy is in Emerceny Exit mode
    /// @dev If this is true all assets should be sitting in Underlying
    function emergencyExit() external view returns(bool);

    /// @notice returns the current liquid value of the Strategy
    /// @dev This call relys on outside contracts and has the potential to be manipulated
    /// @return The value in Underlying the strategy currently holds
    function estimatedTotalAssets() external view returns (uint256);

    /// @notice Returns the total amount of debt the Strategy is currently allocated from the Vault
    /// @return The amount the strategy owes the vault in Underlying
    function currentDebt() external view returns(uint256);

    /// @notice Returns true if the strategy is currently active
    /// @dev Check if EITHER the the strategy has any asset OR Debt from the vault
    ///         could have dust left in and return true but Vault wont call it
    function isActive() external view returns (bool);

    /// @notice Deposit a specific amount of underlying tokens into the strategy.
    /// @param amount The amount of underlying tokens to deposit.
    /// @return An error code, or 0 if the deposit was successful.
    function deposit(uint256 amount) external returns (uint256);

    /// @notice Withdraws a specific amount of underlying tokens from the strategy.
    /// @param amount The amount of underlying tokens to withdraw.
    /// @return An error code, or 0 if the withdrawal was successful.
    function withdraw(uint256 amount) external returns (uint256);

}