// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title IStrategy - Interface for vault investment strategies
/// @notice Defines the standard interface for all vault investment strategies
interface IStrategy {
   /*//////////////////////////////////////////////////////////////
                                EVENTS
   //////////////////////////////////////////////////////////////*/
   
   event Invested(uint256 amount);
   event Withdrawn(uint256 amount);
   event YieldHarvested(uint256 yield, uint256 timestamp);
   event EmergencyWithdrawal(uint256 amount, address recipient);
   event LossReported(uint256 amount, string reason);
   event ProtocolInteraction(string action, uint256 amount);
   event StrategyEnabled();
   event StrategyDisabled();
   event InvestmentLimitUpdated(uint256 oldLimit, uint256 newLimit);

   /*//////////////////////////////////////////////////////////////
                                ERRORS
   //////////////////////////////////////////////////////////////*/
   
   error InsufficientBalance(uint256 requested, uint256 available);
   error ExceedsLimit(uint256 amount, uint256 limit);
   error StrategyIsDisabled();
   error InvalidAmount();
   error ProtocolError(string reason);
   error Unauthorized(address caller);
   error EmergencyExitFailed();
   error InvalidProtocolState();
   error SlippageExceeded(uint256 expected, uint256 received);

   /*//////////////////////////////////////////////////////////////
                           STRATEGY STRUCTS
   //////////////////////////////////////////////////////////////*/
   
   struct StrategyStats {
       uint256 totalInvested;
       uint256 totalHarvested;
       uint256 lastHarvestYield;
       uint256 lastHarvestTime;
       uint256 totalLoss;
       bool isActive;
   }

   struct RiskMetrics {
       uint256 collateralRatio;
       uint256 utilizationRate;
       uint256 volatilityIndex;
       uint256 liquidityRatio;
   }

   /*//////////////////////////////////////////////////////////////
                          CORE FUNCTIONS
   //////////////////////////////////////////////////////////////*/

   /// @notice Initialize the strategy with required parameters
   /// @param params Initialization parameters (ABI encoded)
   function initialize(bytes memory params) external;

   /// @notice Invest funds into the underlying protocol
   /// @param amount Amount to invest
   /// @return invested Actual amount invested
   function invest(uint256 amount) external returns (uint256 invested);

   /// @notice Withdraw funds from the underlying protocol
   /// @param amount Amount to withdraw
   /// @return withdrawn Actual amount withdrawn
   function withdraw(uint256 amount) external returns (uint256 withdrawn);

   /// @notice Harvest yield from the protocol
   /// @return yieldAmount Amount of yield harvested
   function harvestYield() external returns (uint256 yieldAmount);

   /// @notice Emergency withdraw all funds
   /// @param recipient Address to receive withdrawn funds
   /// @return withdrawn Amount successfully withdrawn
   function emergencyExit(address recipient) external returns (uint256 withdrawn);

   /*//////////////////////////////////////////////////////////////
                           STATE FUNCTIONS
   //////////////////////////////////////////////////////////////*/

   /// @notice Enable the strategy
   function enable() external;

   /// @notice Disable the strategy
   function disable() external;

   /// @notice Set investment limit
   /// @param limit New investment limit
   function setInvestmentLimit(uint256 limit) external;

   /*//////////////////////////////////////////////////////////////
                           VIEW FUNCTIONS
   //////////////////////////////////////////////////////////////*/

   /// @notice Get current strategy statistics
   function getStats() external view returns (StrategyStats memory);

   /// @notice Get current risk metrics
   function getRiskMetrics() external view returns (RiskMetrics memory);

   /// @notice Get expected annual percentage yield
   /// @return apy Current APY in basis points
   function getExpectedAPY() external view returns (uint256 apy);

   /// @notice Get total assets currently managed
   function getTotalAssets() external view returns (uint256);

   /// @notice Get maximum investment capacity
   function getInvestmentLimit() external view returns (uint256);

   /// @notice Check if strategy is currently active
   function isActive() external view returns (bool);

   /// @notice Get underlying protocol health status
   /// @return status 0: Healthy, 1: Warning, 2: Critical
   function getProtocolHealth() external view returns (uint8 status);

   /// @notice Get historical performance metrics
   /// @param timeframe Timeframe in seconds to look back
   /// @return bps Returns in basis points
   function getHistoricalReturns(uint256 timeframe) external view returns (uint256 bps);

   /*//////////////////////////////////////////////////////////////
                           SAFETY CHECKS
   //////////////////////////////////////////////////////////////*/

   /// @notice Validate if amount can be safely invested
   function canInvest(uint256 amount) external view returns (bool);

   /// @notice Validate if amount can be safely withdrawn
   function canWithdraw(uint256 amount) external view returns (bool);

   /// @notice Check if harvesting yield is currently possible
   function canHarvest() external view returns (bool);

   /// @notice Estimate gas cost for investment
   function estimateInvestmentGas(uint256 amount) external view returns (uint256);
}