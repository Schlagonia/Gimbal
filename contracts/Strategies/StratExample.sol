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
//import "../interfaces/<protocol>/<Interface>.sol";

contract Strategy is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;

    constructor(address _vault) BaseStrategy(_vault) {
        // You can set these parameters on deployment to whatever you underlying
        // maxReportDelay = 6300;
        // profitFactor = 100;
        // debtThreshold = 0;
    }

    // ******** OVERRIDE THESE METHODS FROM BASE CONTRACT ************

    function name() external pure override returns (string memory) {
        // Add your own name here, suggestion e.g. "StrategyCreamYFI"
        return "Strategy<ProtocolName><TokenType>";
    }

    function estimatedTotalAssets() public view override returns (uint256) {
        // TODO: Build a more accurate estimate using the value of all positions in terms of `underlying`
        return underlying.balanceOf(address(this));
    }

    /// @notice Internal Function called after deposit to perform deposit logic
    /// @param _amount The amount of underlying to be deposited
    /// @return An error code, or 0 if the deposit was successful.
    function _depositSome(uint256 _amount) internal override returns(uint256){

    }

    /// @notice Internal Function called to perform withdraw logi
    /// @param _amount The amount of underlying to be made available
    /// @return error error code, or 0 if the withdraw was successful.
    /// @return _amountFreed amount actually freed
    function _withdrawSome(uint256 _amount) internal override returns(uint256 error, uint256 _amountFreed){

    }

    /// @notice This function is used during emergency exit to liquidate all of the Strategy's positions back to the Underlying.
    /// @dev is only called during after the emercentExit is set to True
    function liquidateAllPositions() internal override {

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
