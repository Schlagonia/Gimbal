// SPDX-License-Identifier: AGPL-3.0
// Feel free to change the license, but this is what we use
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

// These are the core Yearn libraries
import {BaseStrategy} from "../BaseStrategy.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

// Import interfaces for many popular DeFi projects, or add your own!
import '../Interfaces/Aave/V3/IPool.sol';
import '../Interfaces/Aave/V3/IProtocolDataProvider.sol';
import {IAToken} from '../Interfaces/Aave/V3/IAToken.sol';

contract AaveLender is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;

     // AAVE protocol address
    IProtocolDataProvider private protocolDataProvider;
    IPool private lendingPool;
    IAToken aToken;

    uint16 private constant referral = 0; // Aave's referral code

    constructor(
        address _vault, 
        address _protocolDataProvider,
        address _lendingPool
    ) BaseStrategy(_vault) {
        initializeThis(_protocolDataProvider, _lendingPool);
    }

    function initializeThis(
        address _protocolDataProvider,
        address _lendingPool
    ) internal {
        protocolDataProvider = IProtocolDataProvider(_protocolDataProvider);
        lendingPool = IPool(_lendingPool);

        // Set aave tokens
        (address _aToken, , ) =
            protocolDataProvider.getReserveTokensAddresses(address(underlying));
        aToken = IAToken(_aToken);

        // approve spend aave spend
        approveMaxSpend(address(underlying), _lendingPool);
        approveMaxSpend(_aToken, _lendingPool);
    }

    function approveMaxSpend(address token, address spender) internal {
        IERC20(token).safeApprove(spender, type(uint256).max);
    }

    // ******** OVERRIDE THESE METHODS FROM BASE CONTRACT ************

    function name() external pure override returns (string memory) {
        // Add your own name here, suggestion e.g. "StrategyCreamYFI"
        return "Generic Aave Lender";
    }

    function aaveBalance() public view returns(uint256) {
        return aToken.balanceOf(address(this));
    }

    function balanceOfToken(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function estimatedTotalAssets() public view override returns (uint256) {
        return balanceOfToken(address(underlying)) + aaveBalance();
    } 

    /// @notice This is called to get an accurate non-manipulatable amount the strategy holds
    /// Used by the vault to get an accurate account during the harvest
    /// @dev may change the state pending on the current strategy being deployed
    /// @return The actual amount of assets the strategy hold in underlying
    function actualTotalAssets() public view override returns(uint256){
        return estimatedTotalAssets();
    }

    /// @notice Internal Function called after deposit to perform deposit logic
    /// @param _amount The amount of underlying to be deposited
    /// @return An error code, or 0 if the deposit was successful.
    function _depositSome(uint256 _amount) internal override returns(uint256){
        _depositCollateral(_amount);
        return 0;
    }

    /// @notice Internal Function called to perform withdraw logi
    /// @param _amount The amount of underlying to be made available
    /// @return err error code, or 0 if the withdraw was successful.
    /// @return _amountFreed amount actually freed
    function _withdrawSome(uint256 _amount) internal override returns(uint256 err, uint256 _amountFreed){
        _withdrawCollateral(_amount);
        err = 0;
        _amountFreed = Math.min(_amount, balanceOfToken(address(underlying)));
    }

    /// @notice This function is used during emergency exit to liquidate all of the Strategy's positions back to the Underlying.
    /// @dev is only called after the emercentExit is set to True
    function liquidateAllPositions() internal override {
        _withdrawCollateral(type(uint256).max);
    }

    function _depositCollateral(uint256 amount) internal returns (uint256) {
        if (amount == 0) return 0;
        lendingPool.supply(address(underlying), amount, address(this), referral);
        return amount;
    }

    function _withdrawCollateral(uint256 amount) internal returns (uint256) {
        if (amount == 0) return 0;
        lendingPool.withdraw(address(underlying), amount, address(this));
        return amount;
    }

    function prepareMigration(address _newStrategy) internal override {
        // TODO: Transfer any non-`underlying` tokens to the new strategy
        // NOTE: `migrate` will automatically forward all `underlying` in this strategy to the new one
    }

    // Override this to add all tokens/tokenized positions this contract manages
    // on a *persistent* basis (e.g. not just for swapping back to underlying ephemerally)
    // NOTE: Do *not* include `underlying`, already included in `sweep` below
    //
    // Example:
    //
    //    function protectedTokens() internal override view returns (address[] memory) {
    //      address[] memory protected = new address[](3);
    //      protected[0] = tokenA;
    //      protected[1] = tokenB;
    //      protected[2] = tokenC;
    //      return protected;
    //    }
    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {}

    /**
     * @notice
     *  Provide an accurate conversion from `_amtInWei` (denominated in wei)
     *  to `underlying` (using the native decimal characteristics of `underlying`).
     * @dev
     *  Care must be taken when working with decimals to assure that the conversion
     *  is compatible. As an example:
     *
     *      given 1e17 wei (0.1 ETH) as input, and underlying is USDC (6 decimals),
     *      with USDC/ETH = 1800, this should give back 1800000000 (180 USDC)
     *
     * @param _amtInWei The amount (in wei/1e-18 ETH) to convert to `underlying`
     * @return The amount in `underlying` of `_amtInEth` converted to `underlying`
     **/
    function ethTounderlying(uint256 _amtInWei)
        public
        view
        virtual
        override
        returns (uint256)
    {
        // TODO create an accurate price oracle
        return _amtInWei;
    }
}
