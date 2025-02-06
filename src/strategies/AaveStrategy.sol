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

}
