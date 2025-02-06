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
    // What is best????



    function invest(uint256 amount) external override onlyVault whenActive nonReentrant returns (uint256 invested) {
        if (amount == 0) revert InvalidAmount();
        if (amount > investmentLimit - totalInvested) revert ExceedsLimit(amount, investmentLimit - totalInvested);

        // Track invested amount before investing
        // track dai too?
        uint256 beforeBalance = IERC20(aToken).balanceOf(address(this));
        
        // Instead of transferring to strategy first, supply directly from vault to Aave
        // The vault should already approved Aave to spend its DAI (not the case in BaseVault)
        try aavePool.supply(dai, amount, address(this), 0) {
            // If the supply operation succeeds, this code runs
            // wecan safely check our new balance and update our state
            uint256 afterBalance = IERC20(aToken).balanceOf(address(this));
            invested = afterBalance - beforeBalance;
            totalInvested += invested;
            emit Invested(invested);
            return invested;
        } catch (bytes memory reason) {
            // If the supply operation fails, this code runs
            // We can capture the failure reason and handle it gracefully
            revert ProtocolError(string(reason));
        }
    }

    function redeem(uint256 amount) external override onlyVault whenActive nonReentrant returns (uint256 redeemed) {
        if (amount == 0) revert InvalidAmount();
        if (amount > totalInvested) revert ExceedsLimit(amount, totalInvested);

        // Track balances before withdrawal
        uint256 aTokenBefore = IERC20(aToken).balanceOf(address(this));
        uint256 daiBefore = IERC20(dai).balanceOf(vault);

        try aavePool.withdraw(dai, amount, vault) returns (uint256 acutalWithdrawn) {
            uint256 aTokenAfter = IERC20(aToken).balanceOf(address(this));
            

    }

}
