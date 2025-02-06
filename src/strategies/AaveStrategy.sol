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

}
