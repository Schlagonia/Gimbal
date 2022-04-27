// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;


interface IBridgerton {
    /// @notice Initiates a Cross chain tx to the dstChain
    /// @dev Must be called by a vault that has been previously approved.
    /// @param chainId The Stargate ChainId for the destination chain
    /// @param _asset Asset that should be swapped and recieved.
    /// @param _amount The amount of underlying that should be swapped
    /// @param _vaultTo The Strategy that the receiving Vault should send funds to if applicable
    /// @return Will return True if transaction does not revert.
    function swap(
        uint16 chainId, 
        address _asset, 
        uint256 _amount,
        address _vaultTo
    ) external payable returns(bool);
}
