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
     
    
    //      Aave will send the aTokens to the Strategy contract or to the vault ?     
    //     How should i do it ? aTokens in the vault, or in the strategy?
    //      What is best????


    function invest(uint256 amount) external override onlyVault whenActive nonReentrant returns (uint256 invested) {
        // Input validation
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

            // Verify correct amounts
            if (daiSpent != amount) revert("Incorrect DAI amount spent");
            
            totalInvested += invested;
            emit Invested(invested);
            return invested;
        } catch (bytes memory reason) {
            revert ProtocolError(string(reason));
        }
    }

    function withdraw(uint256 amount) external override onlyVault whenActive nonReentrant returns (uint256 withdrawn) {
        // Input validation
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

            // Verify we received expected amount
            if (withdrawn < amount) revert SlippageExceeded(amount, withdrawn);

            totalInvested -= aTokensBurned;
            emit Withdrawn(withdrawn);
            return withdrawn;
        } catch (bytes memory reason) {
            revert ProtocolError(string(reason));
        }
    }
    
}
