// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title IBaseVault - Core interface for the vault system
/// @notice Defines the core functionality for the upgradeable, yield-generating vault
interface IBaseVault {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event StrategyUpdated(address indexed oldStrategy, address indexed newStrategy);
    event FeesUpdated(uint256 managementFee, uint256 performanceFee);
    event FeeReceiverUpdated(address indexed oldFeeReceiver, address indexed newFeeReceiver);
    event Deposit(address indexed user, address indexed receiver, uint256 assets, uint256 shares);
    event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);
    event YieldHarvested(uint256 yieldAmount, uint256 performanceFee);
    event EmergencyWithdraw(address indexed strategy, uint256 amount);
    event APYUpdated(uint256 newAPY);
    event Paused(address indexed account);
    event Unpaused(address indexed account);
    event SharePriceUpdated(uint256 oldPrice, uint256 newPrice);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidAmount(uint256 amount);
    error InvalidAddress(address addr);
    error ExceedsLimit(uint256 amount, uint256 limit);
    error InsufficientBalance(uint256 requested, uint256 available);
    error SlippageExceeded(uint256 expected, uint256 received);
    error InvalidStrategy(address strategy);
    error InvalidFee(uint256 fee);
    error Paused();
    error Unauthorized(address caller);
    error StrategyFailed(bytes reason);

    /*//////////////////////////////////////////////////////////////
                            CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Initialize the vault with initial parameters
    /// @param strategy Initial strategy address
    /// @param feeReceiver Address to receive fees
    /// @param managementFee Annual management fee (in basis points)
    /// @param performanceFee Performance fee (in basis points)
    function initialize(
        address strategy,
        address feeReceiver,
        uint256 managementFee,
        uint256 performanceFee
    ) external;

    /// @notice Deposit assets and mint shares
    /// @param assets Amount of assets to deposit
    /// @param receiver Address to receive the shares
    /// @return shares Amount of shares minted
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /// @notice Deposit assets with permit and mint shares
    /// @param assets Amount of assets to deposit
    /// @param receiver Address to receive the shares
    /// @param deadline Permit deadline
    /// @param v,r,s Permit signature components
    function depositWithPermit(
        uint256 assets,
        address receiver,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 shares);

    /// @notice Withdraw assets by burning shares
    /// @param assets Amount of assets to withdraw
    /// @param receiver Address to receive the assets
    /// @param owner Owner of the shares
    /// @return shares Amount of shares burned
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /*//////////////////////////////////////////////////////////////
                          CONVERSION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get total assets held by vault
    function totalAssets() external view returns (uint256);

    /// @notice Convert an amount of assets to shares
    /// @param assets Amount of assets to convert
    function convertToShares(uint256 assets) external view returns (uint256);

    /// @notice Convert an amount of shares to assets
    /// @param shares Amount of shares to convert
    function convertToAssets(uint256 shares) external view returns (uint256);

    /// @notice Maximum deposit possible for an address
    /// @param receiver Address that would receive shares
    function maxDeposit(address receiver) external view returns (uint256);

    /// @notice Maximum withdrawal possible for an address
    /// @param owner Address that owns the shares
    function maxWithdraw(address owner) external view returns (uint256);

    /// @notice Preview deposit outcome
    /// @param assets Amount of assets to simulate depositing
    function previewDeposit(uint256 assets) external view returns (uint256);

    /// @notice Preview withdrawal outcome
    /// @param assets Amount of assets to simulate withdrawing
    function previewWithdraw(uint256 assets) external view returns (uint256);

    /*//////////////////////////////////////////////////////////////
                        MANAGEMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Update vault strategy
    /// @param newStrategy Address of new strategy
    function setStrategy(address newStrategy) external;

    /// @notice Update fee structure
    /// @param managementFee New management fee (basis points)
    /// @param performanceFee New performance fee (basis points)
    function setFees(uint256 managementFee, uint256 performanceFee) external;

    /// @notice Update fee receiver
    /// @param newFeeReceiver Address to receive fees
    function setFeeReceiver(address newFeeReceiver) external;

    /// @notice Harvest yield from current strategy
    function harvestYield() external returns (uint256 yieldAmount);

    /// @notice Pause vault operations
    function pause() external;

    /// @notice Unpause vault operations
    function unpause() external;

    /// @notice Emergency withdraw from strategy
    /// @param amount Amount to withdraw (0 for all)
    function emergencyWithdraw(uint256 amount) external;

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get current strategy address
    function getStrategy() external view returns (address);

    /// @notice Get current fee structure
    /// @return managementFee Current management fee (basis points)
    /// @return performanceFee Current performance fee (basis points)
    function getFees() external view returns (uint256 managementFee, uint256 performanceFee);

    /// @notice Get vault configuration
    /// @return config Various configuration parameters
    function getConfiguration() external view returns (bytes memory config);

    /// @notice Get current vault APY
    /// @return apy Current APY (in basis points)
    function getAPY() external view returns (uint256 apy);

    /// @notice Get fee receiver address
    function getFeeReceiver() external view returns (address);

    /// @notice Check if vault is paused
    function isPaused() external view returns (bool);

    /// @notice Get current share price
    function getSharePrice() external view returns (uint256);
}