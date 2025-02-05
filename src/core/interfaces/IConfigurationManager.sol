// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title IConfigurationManager - Configuration interface for vault system parameters
/// @notice Manages all configurable parameters for the vault system
interface IConfigurationManager {
   /*//////////////////////////////////////////////////////////////
                                EVENTS
   //////////////////////////////////////////////////////////////*/
   
   event MaxTotalDepositUpdated(uint256 oldLimit, uint256 newLimit);
   event WithdrawLimitUpdated(uint256 oldLimit, uint256 newLimit);
   event MinDepositUpdated(uint256 oldMin, uint256 newMin);
   event MaxDepositUpdated(uint256 oldLimit, uint256 newLimit);
   event MaxTVLUpdated(uint256 oldMax, uint256 newMax);
   event TimelockUpdated(bytes32 paramType, uint256 oldTime, uint256 newTime);
   event FeeCapUpdated(bytes32 feeType, uint256 oldCap, uint256 newCap);
   event StrategyLimitUpdated(address strategy, uint256 oldLimit, uint256 newLimit);
   event RebalanceThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);
   event RiskLevelUpdated(address strategy, uint256 oldLevel, uint256 newLevel);
   event StrategyAdded(address strategy, uint256 weight, uint256 riskLevel);
   event StrategyRemoved(address strategy);

    event ManagementFeeUpdated(uint256 oldFee, uint256 newFee);
    event PerformanceFeeUpdated(uint256 oldFee, uint256 newFee);
    event InvestmentLimitUpdated(uint256 oldLimit, uint256 newLimit);
    event FeeCollectorUpdated(address oldCollector, address newCollector);
   
   /*//////////////////////////////////////////////////////////////
                                ERRORS
   //////////////////////////////////////////////////////////////*/

   error InvalidFee(uint256 fee);
   error InvalidAddress(address addr);
   error InvalidParameter(bytes32 param, uint256 value);
   error InvalidTimelock(uint256 timelock);
   error InvalidLimit(uint256 limit);
   error InvalidStrategy(address strategy);
   error InvalidRiskLevel(uint256 riskLevel);
   error Unauthorized(address caller);
   error TimelockNotExpired(bytes32 paramType, uint256 remainingTime);
   error StrategyAlreadyExists(address strategy);
   error StrategyNotFound(address strategy);
   error MaxStrategiesReached();

   /*//////////////////////////////////////////////////////////////
                           CONFIGURATION STRUCTS
   //////////////////////////////////////////////////////////////*/
   
   struct VaultLimits {
       uint256 maxDeposit;
       uint256 maxWithdraw;
       uint256 minDeposit;
       uint256 maxTVL;
   }

   struct TimelockConfig {
       uint256 withdrawalTimelock;
       uint256 strategyTimelock;
       uint256 emergencyCooldown;
   }

   struct FeeConfig {
       uint256 maxManagementFee;
       uint256 maxPerformanceFee;
       uint256 feeDistributionRatio;  // ratio for fee split (in basis points)
   }

   struct StrategyConfig {
       uint256 maxStrategies;
       uint256 rebalanceThreshold;  // in basis points
       mapping(address => uint256) strategyWeights;  // in basis points
       mapping(address => uint256) strategyRiskLevels;
   }

   /*//////////////////////////////////////////////////////////////
                           CORE FUNCTIONS
   //////////////////////////////////////////////////////////////*/

   /// @notice Initialize configuration with default values
   function initialize() external;

   /*//////////////////////////////////////////////////////////////
                           SETTER FUNCTIONS
   //////////////////////////////////////////////////////////////*/

   function setVaultLimits(
       uint256 maxDeposit,
       uint256 maxWithdraw,
       uint256 minDeposit,
       uint256 maxTVL
   ) external;

   function setTimelockConfig(
       uint256 withdrawalTimelock,
       uint256 strategyTimelock,
       uint256 emergencyCooldown
   ) external;

   function setFeeConfig(
       uint256 maxManagementFee,
       uint256 maxPerformanceFee,
       uint256 feeDistributionRatio
   ) external;

   function setStrategyWeight(address strategy, uint256 weight) external;
   function setRebalanceThreshold(uint256 threshold) external;
   function setStrategyRiskLevel(address strategy, uint256 riskLevel) external;

   /*//////////////////////////////////////////////////////////////
                        STRATEGY MANAGEMENT
   //////////////////////////////////////////////////////////////*/

   /// @notice Add a new strategy to the vault
   /// @param strategy Strategy address
   /// @param weight Initial weight in basis points
   /// @param riskLevel Initial risk level
   function addStrategy(address strategy, uint256 weight, uint256 riskLevel) external;

   /// @notice Remove a strategy from the vault
   /// @param strategy Strategy address to remove
   function removeStrategy(address strategy) external;

   /*//////////////////////////////////////////////////////////////
                           GETTER FUNCTIONS
   //////////////////////////////////////////////////////////////*/

   function getVaultLimits() external view returns (VaultLimits memory);
   function getTimelockConfig() external view returns (TimelockConfig memory);
   function getFeeConfig() external view returns (FeeConfig memory);
   function getStrategyWeight(address strategy) external view returns (uint256);
   function getRebalanceThreshold() external view returns (uint256);
   
   /// @notice Get list of all active strategies
   function getActiveStrategies() external view returns (address[] memory);
   
   /// @notice Get maximum number of strategies allowed
   function getMaxStrategies() external view returns (uint256);
   
   /// @notice Get sum of all strategy weights
   function getTotalStrategyWeight() external view returns (uint256);
   
   /// @notice Get last rebalance timestamp
   function getLastRebalanceTimestamp() external view returns (uint256);
   
   /// @notice Get last fee collection timestamp
   function getLastFeeCollection() external view returns (uint256);
   
   /// @notice Get strategy risk level
   function getStrategyRiskLevel(address strategy) external view returns (uint256);
   
   /// @notice Get maximum allowed risk level
   function getMaxRiskLevel() external view returns (uint256);

   /// @notice Get minimum allowed fee distribution ratio
   function getMinimumFeeDistributionRatio() external view returns (uint256);

   /// @notice Get maximum allowed fee distribution ratio
   function getMaximumFeeDistributionRatio() external view returns (uint256);

   /// @notice Get minimum allowed rebalance threshold
   function getMinimumRebalanceThreshold() external view returns (uint256);

   /*//////////////////////////////////////////////////////////////
                           VALIDATION FUNCTIONS
   //////////////////////////////////////////////////////////////*/

   function validateDeposit(uint256 amount) external view returns (bool);
   function validateWithdraw(uint256 amount) external view returns (bool);
   function validateStrategyChange(address strategy) external view returns (bool);
   function isRebalanceNeeded() external view returns (bool);
   
   /// @notice Check if operation is within timelock period
   function isWithinTimelockPeriod(bytes32 paramType) external view returns (bool);
}