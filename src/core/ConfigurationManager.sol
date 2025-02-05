// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IConfigurationManager.sol";

/// @title ConfigurationManager
/// @notice Manages essential configuration parameters for the vault system
abstract contract ConfigurationManager is IConfigurationManager, Ownable, Pausable, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    // Deposit limits
    uint256 public maxDeposit;        // Maximum single deposit
    uint256 public maxTotalDeposit;   // Maximum TVL
    
    // Fee configuration
    uint256 public managementFee;     // Annual management fee (basis points)
    uint256 public performanceFee;    // Performance fee on yield (basis points)
    address public feeCollector;      // Address to receive fees
    
    // Investment configuration
    uint256 public investmentLimit;   // Maximum amount to invest in protocol
    
    // Constants
    uint256 private constant MAX_BPS = 10000;  // 100% in basis points
    uint256 private constant MAX_FEE = 2000;   // 20% max fee
    
    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        _initializeDefaults();
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Set maximum single deposit limit
    /// @param newLimit New maximum deposit limit
    function setMaxDeposit(uint256 newLimit) external onlyOwner {
        if (newLimit == 0) revert InvalidLimit(newLimit);
        
        emit MaxDepositUpdated(maxDeposit, newLimit);
        maxDeposit = newLimit;
    }

    /// @notice Set maximum total deposit (TVL) limit
    /// @param newLimit New maximum total deposit limit
    function setMaxTotalDeposit(uint256 newLimit) external onlyOwner {
        if (newLimit < maxDeposit) revert InvalidLimit(newLimit);
        
        emit MaxTotalDepositUpdated(maxTotalDeposit, newLimit);
        maxTotalDeposit = newLimit;
    }

    /// @notice Set management fee
    /// @param newFee New management fee in basis points
    function setManagementFee(uint256 newFee) external onlyOwner {
        if (newFee > MAX_FEE) revert InvalidFee(newFee);
        
        emit ManagementFeeUpdated(managementFee, newFee);
        managementFee = newFee;
    }

    /// @notice Set performance fee
    /// @param newFee New performance fee in basis points
    function setPerformanceFee(uint256 newFee) external onlyOwner {
        if (newFee > MAX_FEE) revert InvalidFee(newFee);
        
        emit PerformanceFeeUpdated(performanceFee, newFee);
        performanceFee = newFee;
    }

    /// @notice Set investment limit
    /// @param newLimit New investment limit
    function setInvestmentLimit(uint256 newLimit) external onlyOwner {
        if (newLimit > maxTotalDeposit) revert InvalidLimit(newLimit);
        
        emit InvestmentLimitUpdated(investmentLimit, newLimit);
        investmentLimit = newLimit;
    }

    /// @notice Set fee collector address
    /// @param newCollector New fee collector address
    function setFeeCollector(address newCollector) external onlyOwner {
        if (newCollector == address(0)) revert InvalidAddress(newCollector);
        
        emit FeeCollectorUpdated(feeCollector, newCollector);
        feeCollector = newCollector;
    }

    /*//////////////////////////////////////////////////////////////
                          VALIDATION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Check if deposit amount is within limits
    /// @param amount Amount to validate
    /// @param totalDeposited Current total deposited
    function validateDeposit(uint256 amount, uint256 totalDeposited) external view returns (bool) {
        if (amount == 0) return false;
        if (amount > maxDeposit) return false;
        if (totalDeposited + amount > maxTotalDeposit) return false;
        return true;
    }

    /// @notice Check if investment amount is within limits
    /// @param amount Amount to validate
    function validateInvestment(uint256 amount) external view returns (bool) {
        return amount <= investmentLimit;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Initialize default parameters
    function _initializeDefaults() private {
        maxDeposit = 100_000e18;        // 100k tokens
        maxTotalDeposit = 1_000_000e18; // 1M tokens
        managementFee = 200;            // 2%
        performanceFee = 2000;          // 20%
        investmentLimit = 500_000e18;   // 500k tokens
        feeCollector = msg.sender;
    }

    /// @notice Emergency pause
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause
    function unpause() external onlyOwner {
        _unpause();
    }
}