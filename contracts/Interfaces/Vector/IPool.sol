// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

interface IPool {

    //Underlying
    function depositToken() external view returns (address);

    //Token received from Vector for staking
    function stakingToken() external view returns(address);

    //MasterChef address for Vector
    function masterVtx() external view returns(address);

    //PTP lP token for asset
    function assetToken() external view returns(address);
    
    //Main staking contract address
    function mainStaking() external view returns(address);

    function xptp() external view returns(address);


    /// @notice get the total amount of shares of a user
    /// @param _address the user
    /// @return the amount of shares
    function balance(address _address) external view returns (uint256);

    /// @notice get the total amount of stables deposited by a user
    /// @return the amount of stables deposited
    function depositTokenBalance(address _user) external view returns (uint256);    

    /// @notice get the total amount of rewards for a given token for a user
    /// @param token the address of the token to get the number of rewards for
    /// @return vtxAmount the amount of VTX ready for harvest
    /// @return tokenAmount the amount of token inputted
    function earned(address token)
        external
        view
        returns (uint256 vtxAmount, uint256 tokenAmount);

    /// @notice deposit stables in mainStaking, autostake in masterchief of VTX
    /// @dev performs a harvest of PTP just before depositing
    /// @param amount the amount of stables to deposit
    function deposit(uint256 amount) external;

    /// @notice stake the receipt token in the masterchief of VTX on behalf of the caller
    function stake(uint256 _amount) external;

    /// @notice withdraw stables from mainStaking, auto unstake from masterchief of VTX
    /// @dev performs a harvest of PTP before withdrawing
    /// @param amount the amount of stables to deposit
    function withdraw(uint256 amount, uint256 minAmount) external;

    /// @notice Harvest VTX and PTP rewards
    function getReward() external;
}