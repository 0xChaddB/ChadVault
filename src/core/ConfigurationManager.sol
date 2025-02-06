// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IConfigurationManager} from "./interfaces/IConfigurationManager.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract ConfigurationManager is IConfigurationManager, Initializable, Ownable, Pausable, ReentrancyGuard {

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    // Vault Limits
    VaultLimits public vaultLimits;

    // Timelock Configuration
    TimelockConfig public timelockConfig;

    // Fee Configuration
    FeeConfig public feeConfig;

    // Strategy Configuration
    StrategyConfig private strategyConfig;
    address[] private activeStrategies;
    uint256 public lastRebalanceTimestamp;
    uint256 public lastFeeCollectionTimestamp;

    mapping(address => bool) private isStrategyActive;
    mapping(address => uint256) private strategyWeights;

    // Constants
    uint256 private constant MAX_BPS = 10000;              // 100%
    uint256 private constant MAX_FEE = 2000;              // 20%
    uint256 private constant MAX_RISK_LEVEL = 5;
    uint256 private constant MIN_FEE_DISTRIBUTION = 1000;  // 10%
    uint256 private constant MAX_FEE_DISTRIBUTION = 5000;  // 50%
    uint256 private constant MIN_REBALANCE_THRESHOLD = 500;// 5%

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() Ownable(msg.sender) {
        initialize();
    }

    /*//////////////////////////////////////////////////////////////
                            CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function initialize() public override initializer {
        vaultLimits = VaultLimits({
            maxDeposit: 100_000e18,        // 100k tokens
            maxWithdraw: 100_000e18,
            minDeposit: 100e18,            // 100 tokens
            maxTVL: 1_000_000e18           // 1M tokens
        });

        timelockConfig = TimelockConfig({
            withdrawalTimelock: 1 days,
            strategyTimelock: 2 days,
            emergencyCooldown: 6 hours
        });

        feeConfig = FeeConfig({
            maxManagementFee: 200,         // 2%
            maxPerformanceFee: 2000,       // 20%
            feeDistributionRatio: 5000     // 50% Implemented this but we may not need it now 
        });

        strategyConfig.maxStrategies = 10;
        strategyConfig.rebalanceThreshold = 1000; // 10%
        
        lastRebalanceTimestamp = block.timestamp;
        lastFeeCollectionTimestamp = block.timestamp;
    }

    /*//////////////////////////////////////////////////////////////
                            SETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setVaultLimits(
        uint256 maxDeposit_,
        uint256 maxWithdraw_,
        uint256 minDeposit_,
        uint256 maxTVL_
    ) external override onlyOwner {
        if (minDeposit_ >= maxDeposit_) revert InvalidLimit(maxDeposit_);
        if (maxTVL_ < maxDeposit_) revert InvalidLimit(maxTVL_);

        emit MaxDepositUpdated(vaultLimits.maxDeposit, maxDeposit_);
        emit WithdrawLimitUpdated(vaultLimits.maxWithdraw, maxWithdraw_);
        emit MinDepositUpdated(vaultLimits.minDeposit, minDeposit_);
        emit MaxTVLUpdated(vaultLimits.maxTVL, maxTVL_);

        vaultLimits = VaultLimits({
            maxDeposit: maxDeposit_,
            maxWithdraw: maxWithdraw_,
            minDeposit: minDeposit_,
            maxTVL: maxTVL_
        });
    }

    function setTimelockConfig(
        uint256 withdrawalTimelock_,
        uint256 strategyTimelock_,
        uint256 emergencyCooldown_
    ) external override onlyOwner {
        timelockConfig = TimelockConfig({
            withdrawalTimelock: withdrawalTimelock_,
            strategyTimelock: strategyTimelock_,
            emergencyCooldown: emergencyCooldown_
        });

        emit TimelockUpdated("WITHDRAWAL", timelockConfig.withdrawalTimelock, withdrawalTimelock_);
        emit TimelockUpdated("STRATEGY", timelockConfig.strategyTimelock, strategyTimelock_);
        emit TimelockUpdated("EMERGENCY", timelockConfig.emergencyCooldown, emergencyCooldown_);
    }

    function setFeeConfig(
        uint256 maxManagementFee_,
        uint256 maxPerformanceFee_,
        uint256 feeDistributionRatio_
    ) external override onlyOwner {
        if (maxManagementFee_ > MAX_FEE) revert InvalidFee(maxManagementFee_);
        if (maxPerformanceFee_ > MAX_FEE) revert InvalidFee(maxPerformanceFee_);
        if (feeDistributionRatio_ < MIN_FEE_DISTRIBUTION || feeDistributionRatio_ > MAX_FEE_DISTRIBUTION) 
            revert InvalidParameter("FEE_DISTRIBUTION", feeDistributionRatio_);

        feeConfig = FeeConfig({
            maxManagementFee: maxManagementFee_,
            maxPerformanceFee: maxPerformanceFee_,
            feeDistributionRatio: feeDistributionRatio_
        });

        emit FeeCapUpdated("MANAGEMENT", feeConfig.maxManagementFee, maxManagementFee_);
        emit FeeCapUpdated("PERFORMANCE", feeConfig.maxPerformanceFee, maxPerformanceFee_);
    }

    function setStrategyWeight(address strategy, uint256 weight) external override onlyOwner {
        if (!isStrategyActive[strategy]) revert StrategyNotFound(strategy);
        if (weight > MAX_BPS) revert InvalidParameter("WEIGHT", weight);

        strategyConfig.strategyWeights[strategy] = weight;
        emit StrategyLimitUpdated(strategy, strategyWeights[strategy], weight);
    }

    function setRebalanceThreshold(uint256 threshold) external override onlyOwner {
        if (threshold < MIN_REBALANCE_THRESHOLD) revert InvalidParameter("THRESHOLD", threshold);
        
        emit RebalanceThresholdUpdated(strategyConfig.rebalanceThreshold, threshold);
        strategyConfig.rebalanceThreshold = threshold;
    }

    function setStrategyRiskLevel(address strategy, uint256 riskLevel) external override onlyOwner {
        if (!isStrategyActive[strategy]) revert StrategyNotFound(strategy);
        if (riskLevel > MAX_RISK_LEVEL) revert InvalidRiskLevel(riskLevel);

        emit RiskLevelUpdated(strategy, strategyConfig.strategyRiskLevels[strategy], riskLevel);
        strategyConfig.strategyRiskLevels[strategy] = riskLevel;
    }

    /*//////////////////////////////////////////////////////////////
                        STRATEGY MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function addStrategy(address strategy, uint256 weight, uint256 riskLevel) external override onlyOwner {
        if (strategy == address(0)) revert InvalidAddress(strategy);
        if (isStrategyActive[strategy]) revert StrategyAlreadyExists(strategy);
        if (activeStrategies.length >= strategyConfig.maxStrategies) revert MaxStrategiesReached();
        if (riskLevel > MAX_RISK_LEVEL) revert InvalidRiskLevel(riskLevel);
        if (weight > MAX_BPS) revert InvalidParameter("WEIGHT", weight);

        activeStrategies.push(strategy);
        isStrategyActive[strategy] = true;
        strategyConfig.strategyWeights[strategy] = weight;
        strategyConfig.strategyRiskLevels[strategy] = riskLevel;

        emit StrategyAdded(strategy, weight, riskLevel);
    }

    function removeStrategy(address strategy) external override onlyOwner {
        if (!isStrategyActive[strategy]) revert StrategyNotFound(strategy);

        // Remove from active strategies array
        for (uint i = 0; i < activeStrategies.length; i++) {
            if (activeStrategies[i] == strategy) {
                activeStrategies[i] = activeStrategies[activeStrategies.length - 1];
                activeStrategies.pop();
                break;
            }
        }

        isStrategyActive[strategy] = false;
        delete strategyConfig.strategyWeights[strategy];
        delete strategyConfig.strategyRiskLevels[strategy];

        emit StrategyRemoved(strategy);
    }

    /*//////////////////////////////////////////////////////////////
                            GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getVaultLimits() external view override returns (VaultLimits memory) {
        return vaultLimits;
    }

    function getTimelockConfig() external view override returns (TimelockConfig memory) {
        return timelockConfig;
    }

    function getFeeConfig() external view override returns (FeeConfig memory) {
        return feeConfig;
    }

    function getStrategyWeight(address strategy) external view override returns (uint256) {
        return strategyConfig.strategyWeights[strategy];
    }

    function getRebalanceThreshold() external view override returns (uint256) {
        return strategyConfig.rebalanceThreshold;
    }

    function getActiveStrategies() external view override returns (address[] memory) {
        return activeStrategies;
    }

    function getMaxStrategies() external view override returns (uint256) {
        return strategyConfig.maxStrategies;
    }

    function getTotalStrategyWeight() external view override returns (uint256) {
        uint256 total = 0;
        for (uint i = 0; i < activeStrategies.length; i++) {
            total += strategyConfig.strategyWeights[activeStrategies[i]];
        }
        return total;
    }

    function getLastRebalanceTimestamp() external view override returns (uint256) {
        return lastRebalanceTimestamp;
    }

    function getLastFeeCollection() external view override returns (uint256) {
        return lastFeeCollectionTimestamp;
    }

    function getStrategyRiskLevel(address strategy) external view override returns (uint256) {
        return strategyConfig.strategyRiskLevels[strategy];
    }

    function getMaxRiskLevel() external pure override returns (uint256) {
        return MAX_RISK_LEVEL;
    }

    function getMinimumFeeDistributionRatio() external pure override returns (uint256) {
        return MIN_FEE_DISTRIBUTION;
    }

    function getMaximumFeeDistributionRatio() external pure override returns (uint256) {
        return MAX_FEE_DISTRIBUTION;
    }

    function getMinimumRebalanceThreshold() external pure override returns (uint256) {
        return MIN_REBALANCE_THRESHOLD;
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function validateDeposit(uint256 amount) external view override returns (bool) {
        return amount >= vaultLimits.minDeposit && 
                amount <= vaultLimits.maxDeposit;
    }

    function validateWithdraw(uint256 amount) external view override returns (bool) {
        return amount <= vaultLimits.maxWithdraw;
    }

    function validateStrategyChange(address strategy) external view override returns (bool) {
        return isStrategyActive[strategy];
    }

    function isRebalanceNeeded() external view override returns (bool) {
        return (block.timestamp - lastRebalanceTimestamp) >= timelockConfig.strategyTimelock;
    }

    function isWithinTimelockPeriod(bytes32 paramType) external view override returns (bool) {
        if (paramType == "WITHDRAWAL") {
            return block.timestamp >= timelockConfig.withdrawalTimelock;
        } else if (paramType == "STRATEGY") {
            return block.timestamp >= timelockConfig.strategyTimelock;
        } else if (paramType == "EMERGENCY") {
            return block.timestamp >= timelockConfig.emergencyCooldown;
        }
        return false;
    }
}