// SPDX-License-Identifier: AGPL-3.0
// Feel free to change the license, but this is what we use
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

// These are the core Yearn libraries
import {BaseStrategy} from "../BaseStrategy.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import { IPool } from "../Interfaces/Vector/IPool.sol";

import { IUniswapV2Router02 } from "../Interfaces/Uni/IUniswapV2Router02.sol";

import "hardhat/console.sol";

interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}


contract Vectorfied is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;

    IPool public pool; //0x1338b4065e25AD681c511644Aa319181FC3d64CC
    address staker;
    address ptp = 0x22d4002028f537599bE9f666d1c4Fa138522f9c8;
    uint256 minPtp = 1e16;
    address vtx = 0x5817D4F0b62A59b17f75207DA1848C2cE75e7AF4;
    uint256 minVtx = 1e16;

    address wavax = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    uint256 minUnderlying;

    uint256 slippageProtectionOut = 50; //out of 10000. 50 = 0.5%
    uint256 constant DENOMINATOR = 10_000;

    IUniswapV2Router02 router;

    constructor(
        address _vault,
        address _pool,
        address _router
    ) BaseStrategy(_vault) {
        pool = IPool(_pool);

        uint256 underlying_decimals = IERC20Extended(address(underlying)).decimals();
        minUnderlying = 10 ** (underlying_decimals - 2);

        staker = pool.mainStaking();
        approveMaxSpend(address(underlying), staker);
        
        setRouter(_router);
    }

    function setRouter(address _router) internal {
        approveMaxSpend(ptp, _router);
        approveMaxSpend(vtx, _router);

        router = IUniswapV2Router02(_router);
    }

    function approveMaxSpend(address token, address spender) internal {
        IERC20(token).safeApprove(spender, type(uint256).max);
    }

    // ******** OVERRIDE THESE METHODS FROM BASE CONTRACT ************

    function name() external pure override returns (string memory) {
        // Add your own name here, suggestion e.g. "StrategyCreamYFI"
        return "Vectorfied";
    }

    function balanceOfToken(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function estimatedTotalAssets() public view override returns (uint256 balance) {
        uint256 underlyingBalance = underlying.balanceOf(address(this));

        uint256 vBalance = pool.depositTokenBalance(address(this));

        unchecked{
            balance = underlyingBalance + vBalance;
        }
    }

    function harvest() internal {
        pool.getReward();

        disposeOfPtp();
        disposeOfVtx();

        uint256 underlyingBalance = underlying.balanceOf(address(this));
        if(underlyingBalance < minUnderlying) return;

        _depositCollateral(underlyingBalance);
    }

    /// @notice This is called to get an accurate non-manipulatable amount the strategy holds
    /// Used by the vault to get an accurate account during the harvest
    /// @dev may change the state pending on the current strategy being deployed
    /// @return The actual amount of assets the strategy hold in underlying
    function actualTotalAssets() public override returns(uint256){
        harvest();

        return estimatedTotalAssets();
    }

    /// @notice Internal Function called after deposit to perform deposit logic
    /// @param _amount The amount of underlying to be deposited
    /// @return An error code, or 0 if the deposit was successful.
    function _depositSome(uint256 _amount) internal override returns(uint256){
        _depositCollateral(_amount);
        return 0;
    }

    /// @notice Internal Function called to perform withdraw logic
    /// @param _amount The amount of underlying to be made available
    /// @return err error code, or 0 if the withdraw was successful.
    /// @return _amountFreed amount actually freed
    function _withdrawSome(uint256 _amount) internal override returns(uint256 err, uint256 _amountFreed){
        uint256 bal = underlying.balanceOf(address(this));

        if(bal >= _amount){
            return (0, _amount);
        }
        uint256 diff;

        unchecked{
            diff = _amount - bal;
        }

        uint256 vBal = pool.depositTokenBalance(address(this));
        if(diff > vBal) {
            liquidateAllPositions();

            return (0, Math.min(underlying.balanceOf(address(this)), _amount));
        }

        _withdrawCollateral(diff);
        err = 0;
        _amountFreed = Math.min(underlying.balanceOf(address(this)), _amount);
    }

    function _depositCollateral(uint256 amount) internal  {
        if (amount == 0) return;
        pool.deposit(amount);
    }

    function _withdrawCollateral(uint256 amount) internal {
        if (amount == 0) return;
        uint256 min = getMinOut(amount);
        pool.withdraw(amount, min);
    }

    function getMinOut(uint256 amount) internal view returns (uint256 minOut) {
        unchecked {
            minOut = amount * (DENOMINATOR - slippageProtectionOut) / DENOMINATOR;
        }
    }

    /// @notice This function is used during emergency exit to liquidate all of the Strategy's positions back to the Underlying.
    /// @dev is only called during after the emercentExit is set to True
    function liquidateAllPositions() internal override {
        uint256 vBal = pool.depositTokenBalance(address(this));

        _withdrawCollateral(vBal);

        disposeOfPtp();

        disposeOfVtx();
    }

    function disposeOfPtp() internal {
        uint256 pBal = balanceOfToken(ptp);
        console.log("Balance of PTP", pBal);
        if(pBal < minPtp) {
            return;
        }

        _swapFrom(ptp, address(underlying), pBal);

    }

    function disposeOfVtx() internal {
        uint256 vBal = balanceOfToken(vtx);
        console.log("Balance of VtX", vBal);
        if(vBal < minVtx) {
            return;
        }

        _swapFrom(vtx, address(underlying), vBal);
    }

    //WARNING. manipulatable and simple routing. Only use for safe functions
    function _checkPrice(
        address start,
        address end,
        uint256 _amount
    ) internal view returns (uint256) {
        if (_amount == 0) {
            return 0;
        }

        uint256[] memory amounts = router.getAmountsOut(_amount, getTokenOutPath(start, end));

        return amounts[amounts.length - 1];
    }

    //need to go from PTP to AVAX to USDC.e
    function _swapFromWithAmount(
        address _from,
        address _to,
        uint256 _amountIn,
        uint256 _amountOut
    ) internal returns (uint256) {
        //IERC20(_from).approve(address(router), _amountIn);

        uint256[] memory amounts = router.swapExactTokensForTokens(
            _amountIn,
            _amountOut,
            getTokenOutPath(_from, _to),
            address(this),
            block.timestamp
        );

        return amounts[amounts.length - 1];
    }

    function _swapFrom(
        address _from,
        address _to,
        uint256 _amountIn
    ) internal returns (uint256) {
        uint256 amountOut = _checkPrice(_from, _to, _amountIn);

        return _swapFromWithAmount(_from, _to, _amountIn, amountOut);
    }


    function getTokenOutPath(address _tokenIn, address _tokenOut) internal view returns (address[] memory _path) {
        bool isWeth = _tokenIn == wavax || _tokenOut == wavax;
        _path = new address[](isWeth ? 2 : 3);
        _path[0] = _tokenIn;

        if (isWeth) {
            _path[1] = _tokenOut;
        } else {
            _path[1] = wavax;
            _path[2] = _tokenOut;
        }
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
