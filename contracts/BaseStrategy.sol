// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IVault } from './Interfaces/IVault.sol';
import { Strategy } from './Interfaces/IStrategy.sol';
/**
 * This interface is here for the keeper bot to use.
 */
interface StrategyAPI is Strategy {}

/**
 * @title Savor Base Strategy
 * @author Schlagonia adapted from Yearn.Finance BaseStrategy.sol
 * @notice
 *  BaseStrategy implements all of the required functionality to interoperate
 *  closely with the Vault contract. This contract should be inherited and the
 *  abstract methods implemented to adapt the Strategy to the particular needs
 *  it has to create a return.
 *
 */

abstract contract BaseStrategy {
    using SafeERC20 for IERC20;
    
    /**
     * @notice This Strategy's name.
     * @dev
     *  You can use this field to manage the identity of this Strategy, e.g.
     *  `StrategySomethingOrOtherV1`. 
     * @return This Strategy's name.
     */
    function name() external view virtual returns (string memory);

    /// @notice Instance of the vault this strategy is assigned to
    IVault public vault;

    /// @notice instance of the asset that is being used
    IERC20 public underlying;

    //Owner of contract set on deploy
    address public owner;

    // See note on `setEmergencyExit()`.
    bool public emergencyExit;

    /// @notice Emmited if a new owner of the contract is updated
    /// @param newOwner The address of the new contract owner
    event UpdatedOwner(address newOwner);

    /// @notice Emmited if the Emercency Exit is called
    event EmergencyExitEnabled();

    // modifiers
    /// @notice Checks if called is owner
    /// @dev keeping as a modifier depsite gas cost in case of futer Authorizations
    modifier onlyAuthorized() {
        _onlyAuthorized();
        _;
    }

    function _onlyAuthorized() internal view {
        require(msg.sender == owner);
    }

    constructor(address _vault)  {
        _initialize(_vault, msg.sender);
    }

    /**
     * @notice
     *  Initializes the Strategy, this is called only once, when the
     *  contract is deployed.
     * @dev `_vault` should implement `IVault`.
     * @param _vault The address of the Vault responsible for this Strategy.
     * @param _owner The address to assign as owner.
     */
    function _initialize(
        address _vault,
        address _owner
    ) internal {
        require(address(underlying) == address(0), "Strategy already initialized");

        vault = IVault(_vault);
        underlying = IERC20(vault.UNDERLYING());
        underlying.safeApprove(_vault, type(uint256).max); // Give Vault unlimited access (might save gas)
        owner = _owner;
    }

    /**
     * @notice
     *  Used to change `owner`.
     *  This may only be called by current owner.
     * @param _owner The new address to assign as `_owner`.
     */
    function setOwner(address _owner) external onlyAuthorized {
        require(_owner != address(0));
        owner = _owner;
        emit UpdatedOwner(_owner);
    }

    /**
     * @notice
     *  Provide an accurate conversion from `_amtInWei` (denominated in wei)
     *  to `underlying` (using the native decimal characteristics of `underlying`).
     * @dev
     *  Care must be taken when working with decimals to assure that the conversion
     *  is compatible. As an example:
     *
     *      given 1e17 wei (0.1 ETH) as input, and underlying is USDC (6 decimals),
     *      with USDC/ETH = 1800, this should give back 180000000 (180 USDC)
     *
     * @param _amtInWei The amount (in wei/1e-18 ETH) to convert to `underlying`
     * @return The amount in `underlying` of `_amtInEth` converted to `underlying`
     **/
    function ethTounderlying(uint256 _amtInWei) public view virtual returns (uint256);

    /**
     * @notice
     *  Provide an accurate estimate for the total amount of assets
     *  (principle + return) that this Strategy is currently managing,
     *  denominated in terms of `underlying` tokens.
     *
     *  This total should be "realizable" e.g. the total value that could
     *  *actually* be obtained from this Strategy if it were to divest its
     *  entire position based on current on-chain conditions.
     * @dev
     *  Care must be taken in using this function, since it relies on external
     *  systems, which could be manipulated by the attacker to give an inflated
     *  (or reduced) value produced by this function, based on current on-chain
     *  conditions (e.g. this function is possible to influence through
     *  flashloan attacks, oracle manipulations, or other DeFi attack
     *  mechanisms).
     *
     *  It is up to governance to use this function to correctly order this
     *  Strategy relative to its peers in the withdrawal queue to minimize
     *  losses for the Vault based on sudden withdrawals. This value should be
     *  higher than the total debt of the Strategy and higher than its expected
     *  value to be "safe".
     * @return The estimated total assets in this Strategy.
     */
    function estimatedTotalAssets() public view virtual returns (uint256);

    /// @notice This is called to get an accurate non-manipulatable amount the strategy holds
    /// Used by the vault to get an accurate account during the harvest
    /// @dev may change the state pending on the current strategy being deployed
    /// @return The actual amount of assets the strategy hold in underlying
    function actualTotalAssets() public virtual returns(uint256);

    /// @notice Returns the total amount of debt the Strategy is currently allocated from the Vault
    /// @return The amount the strategy owes the vault in Underlying
    function currentDebt() public view returns(uint256) {
        IVault.StrategyData memory data = vault.getStrategyData(Strategy(address(this)));
        return data.balance;
    }

    /*
     * @notice
     *  Provide an indication of whether this strategy is currently "active"
     *  in that it is managing an active position, or will manage a position in
     *  the future. This should correlate to `harvest()` activity, so that Harvest
     *  events can be tracked externally by indexing agents.
     * @return True if the strategy is actively managing a position.
     */
    function isActive() public view returns (bool) {
        return currentDebt() > 0 || estimatedTotalAssets() > 0;
    }

    /// @notice Deposit a specific amount of underlying tokens into the strategy.
    /// @dev Can only be called by the vault
    /// @param amount The amount of underlying tokens to deposit.
    /// @return An error code, or 0 if the deposit was successful.
    function deposit(uint256 amount) external returns (uint256) {
        require(msg.sender == address(vault), "!Vault");

        underlying.safeTransferFrom(msg.sender, address(this), amount);
        return _depositSome(amount);
    }

    /// @notice Internal Function called after deposit to perform deposit logic
    /// @param _amount The amount of underlying to be deposited
    /// @return An error code, or 0 if the deposit was successful.
    function _depositSome(uint256 _amount) internal virtual returns(uint256);

    
    /// @notice This function is used during emergency exit to liquidate all of the Strategy's positions back to the Underlying.
    /// @dev is only called during after the emercentExit is set to True
    function liquidateAllPositions() internal virtual;

    
    /// @notice Withdraws `_amountNeeded` to `vault`.
    /// @dev This may only be called by the Vault.
    /// @param _amountNeeded How much `underlying` to withdraw.
    /// @return err error code, or 0 if the withdraw was successful.
    function withdraw(uint256 _amountNeeded) external returns (uint256 err) {
        require(msg.sender == address(vault), "!vault");
        // Liquidate as much as possible to `underlying`, up to `_amountNeeded`
        uint256 amountFreed;
        ( err, amountFreed) = _withdrawSome(_amountNeeded);
        // Send it directly back (NOTE: Using `msg.sender` saves some gas here)
        SafeERC20.safeTransfer(underlying, msg.sender, amountFreed);
    
    }

    /// @notice Internal Function called to perform withdraw logi
    /// @param _amount The amount of underlying to be made available
    /// @return error error code, or 0 if the withdraw was successful.
    /// @return _amountFreed amount actually freed
    function _withdrawSome(uint256 _amount) internal virtual returns(uint256 error, uint256 _amountFreed);


    /**
     * Do anything necessary to prepare this Strategy for migration, such as
     * transferring any reserve or LP tokens, CDPs, or other tokens or stores of
     * value.
     */
    function prepareMigration(address _newStrategy) internal virtual;

    /**
     * @notice
     *  Transfers all `underlying` from this Strategy to `_newStrategy`.
     *
     *  This may only be called by the Vault.
     * @dev
     * The new Strategy's Vault must be the same as this Strategy's Vault.
     *  The migration process should be carefully performed to make sure all
     * the assets are migrated to the new address, which should have never
     * interacted with the vault before.
     * @param _newStrategy The Strategy to migrate to.
     */
    function migrate(address _newStrategy) external {
        require(msg.sender == address(vault));
        require(Strategy(_newStrategy).vault() == address(vault));
        prepareMigration(_newStrategy);
        SafeERC20.safeTransfer(underlying, _newStrategy, underlying.balanceOf(address(this)));
    }

    /**
     * @notice
     *  Activates emergency exit. Once activated, the Strategy will exit its
     *  position upon the next harvest, depositing all funds into the Vault as
     *  quickly as is reasonable given on-chain conditions.
     *
     *  This may only be called by governance or the strategist.
     * @dev
     *  See `vault.setEmergencyShutdown()` and `harvest()` for further details.
     */
    function setEmergencyExit() external onlyAuthorized {
        emergencyExit = true;
        liquidateAllPositions();

        emit EmergencyExitEnabled();
    }

    /**
     * Override this to add all tokens/tokenized positions this contract
     * manages on a *persistent* basis (e.g. not just for swapping back to
     * underlying ephemerally).
     *
     * NOTE: Do *not* include `underlying`, already included in `sweep` below.
     *
     * Example:
     * ```
     *    function protectedTokens() internal override view returns (address[] memory) {
     *      address[] memory protected = new address[](3);
     *      protected[0] = tokenA;
     *      protected[1] = tokenB;
     *      protected[2] = tokenC;
     *      return protected;
     *    }
     * ```
     */
    function protectedTokens() internal view virtual returns (address[] memory);

    /**
     * @notice
     *  Removes tokens from this Strategy that are not the type of tokens
     *  managed by this Strategy. This may be used in case of accidentally
     *  sending the wrong kind of token to this Strategy.
     *
     *  Tokens will be sent to `governance()`.
     *
     *  This will fail if an attempt is made to sweep `underlying`, or any tokens
     *  that are protected by this Strategy.
     *
     *  This may only be called by governance.
     * @dev
     *  Implement `protectedTokens()` to specify any additional tokens that
     *  should be protected from sweeping in addition to `underlying`.
     * @param _token The token to transfer out of this vault.
     */
    function sweep(address _token) external onlyAuthorized {
        require(_token != address(underlying), "!underlying");
        require(_token != address(vault), "!shares");

        address[] memory _protectedTokens = protectedTokens();
        for (uint256 i; i < _protectedTokens.length; i++) require(_token != _protectedTokens[i], "!protected");

        SafeERC20.safeTransfer(IERC20(_token), owner, IERC20(_token).balanceOf(address(this)));
    }
}

abstract contract BaseStrategyInitializable is BaseStrategy {
    bool public isOriginal = true;
    event Cloned(address indexed clone);

    constructor(address _vault) BaseStrategy(_vault) {}

    function initialize(
        address _vault,
        address _owner
    ) external virtual {
        _initialize(_vault, _owner);
    }

    function clone(address _vault) external returns (address) {
        return this.clone(_vault, msg.sender);
    }

    function clone(
        address _vault,
        address _owner
    ) external returns (address newStrategy) {
        require(isOriginal, "!clone");
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(address(this));

        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(clone_code, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(add(clone_code, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            newStrategy := create(0, clone_code, 0x37)
        }

        BaseStrategyInitializable(newStrategy).initialize(_vault, _owner);

        emit Cloned(newStrategy);
    }
}