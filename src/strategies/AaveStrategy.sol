// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IPool} from "@aave/contracts/interfaces/IPool.sol";
import {IPoolAddressesProvider} from "@aave/contracts/interfaces/IPoolAddressesProvider.sol";
import {IStrategy} from "./interfaces/IStrategy.sol";

contract AaveStrategy is Ownable, ReentrancyGuard, IStrategy {

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    // Core addresses
    address public vault;
    address public dai;
    IPool public  aavePool;
    address public aToken;

    // Strategy states
    bool public isActive;
    uint256 public investmentLimit;
    uint256 public totalInvested;
    uint256 public lastHarvestAmount;
    uint256 public lastHarvestTimestamp;

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor (
        address _vault,
        address _dai,
        address _aaveProvider
    ) Ownable(msg.sender) {
        if (_vault == address(0)) revert InvalidAddress(_vault);
        if (_dai == address(0)) revert InvalidAddress(_dai);
        if (_aaveProvider == address(0)) revert InvalidAddress(_aaveProvider);
            
        vault = _vault;
        dai = _dai;

        // Initialize Aave Pool
        IPoolAddressesProvider provider = IPoolAddressProvider(_aaveProvider);
        aavePool = IPool(provider.getPool());
        // get aToken for dai
        aToken = aavePool.getReserveData(dai).aTokenAddress;
    }

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyVault() {
        if (msg.sender != vault) revert Unauthorized(msg.sender);
        _;
    }

    modifier whenActive() {
        if (!isActive) revert StrategyNotActive();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                          INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    function initialize(bytes memory params) external override onlyOwner {
        if (isActive) revert ("Already initialied");
        
        investmentLimit = 1_000_000e18;
        isActive = true;
        lastHarvestTimestamp = block.timestamp;

        emit StrategyEnabled(address(this));
    }

    /*//////////////////////////////////////////////////////////////
                          INVESTMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    // Do we need additional safety checks in the next functions?
    // eg: aave health check, 
    // is slippage protection a thing here????? Rate change ?
    // Balance change checks ?
    // I do not check fot maximum invested amount...
    // We will try with test cases
    
    /** 
     * @notice Invests DAI from the vault into Aave lending pool
     * @dev DAI moves directly from vault to Aave, but aTokens are held by strategy
     * @param amount The amount of DAI to invest
     * @return invested The amount of aTokens received
     */
    function invest(uint256 amount) external override onlyVault whenActive nonReentrant returns (uint256 invested) {
        if (amount == 0) revert InvalidAmount();
        if (amount > investmentLimit - totalInvested) revert ExceedsLimit(amount, investmentLimit - totalInvested);

        // Track both balances before investing
        uint256 aTokenBefore = IERC20(aToken).balanceOf(address(this));
        uint256 daiBefore = IERC20(dai).balanceOf(vault);

        // Supply DAI to Aave (DAI from vault, aTokens to strategy)
        try aavePool.supply(dai, amount, address(this), 0) {
            // Verify balances after operation
            uint256 aTokenAfter = IERC20(aToken).balanceOf(address(this));
            uint256 daiAfter = IERC20(dai).balanceOf(vault);

            // Calculate actual amounts
            invested = aTokenAfter - aTokenBefore;
            uint256 daiSpent = daiBefore - daiAfter;

            // I think this check isnt enough
            if (daiSpent != amount) revert("Incorrect DAI amount spent");
            
            totalInvested += invested;
            emit Invested(invested);
            return invested;
        } catch (bytes memory reason) {
            revert ProtocolError(string(reason));
        }
    }

    /**
     * @notice Withdraws DAI from Aave and sends it back to the vault
     * @dev Burns aTokens held by strategy to receive DAI in the vault
     * @param amount The amount of DAI to withdraw
     * @return withdrawn The actual amount of DAI withdrawn to the vault
     */
    function withdraw(uint256 amount) external override onlyVault whenActive nonReentrant returns (uint256 withdrawn) {
        if (amount == 0) revert InvalidAmount();
        if (amount > totalInvested) revert InsufficientBalance(amount, totalInvested);

        // Track both balances before withdrawal
        uint256 aTokenBefore = IERC20(aToken).balanceOf(address(this));
        uint256 daiBefore = IERC20(dai).balanceOf(vault);

        // Withdraw from Aave to vault
        try aavePool.withdraw(dai, amount, vault) returns (uint256 actualWithdrawn) {
            // Verify balances after operation
            uint256 aTokenAfter = IERC20(aToken).balanceOf(address(this));
            uint256 daiAfter = IERC20(dai).balanceOf(vault);

            // Calculate actual amounts
            uint256 aTokensBurned = aTokenBefore - aTokenAfter;
            withdrawn = daiAfter - daiBefore;

            // I think this check only isnt enough
            if (withdrawn < amount) revert SlippageExceeded(amount, withdrawn);

            totalInvested -= aTokensBurned;
            emit Withdrawn(withdrawn);
            return withdrawn;
        } catch (bytes memory reason) {
            revert ProtocolError(string(reason));
        }
    }
    
}
