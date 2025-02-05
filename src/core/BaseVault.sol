// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IBaseVault} from "./interfaces/IBaseVault.sol";
import {IConfigurationManager} from "./interfaces/IConfigurationManager.sol";
import {IStrategy} from "../strategies/interfaces/IStrategy.sol";

contract BaseVault is 
   IBaseVault, 
   ERC4626, 
   Initializable, 
   ReentrancyGuard, 
   Ownable, 
   Pausable
{
    using SafeERC20 for ERC20;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    IConfigurationManager public configManager;
    IStrategy public strategy;
    address public feeReceiver;
    uint256 public managementFee;
    uint256 public performanceFee;
    uint256 public lastHarvestTimestamp;
    uint256 private constant MAX_BPS = 10000; // 100% in basis points

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        IERC20 asset_,
        IConfigurationManager configManager_,
        string memory name_,
        string memory symbol_
    ) ERC4626(asset_) ERC20(name_, symbol_) Ownable(msg.sender) {
        if (address(configManager_) == address(0)) revert BaseVault__InvalidAddress(address(0));
        configManager = configManager_;
    }

    /*//////////////////////////////////////////////////////////////
                            CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function initialize(
        address strategy_,
        address feeReceiver_,
        uint256 managementFee_,
        uint256 performanceFee_
    ) external override initializer {
        if (strategy_ == address(0)) revert BaseVault__InvalidAddress(strategy_);
        if (feeReceiver_ == address(0)) revert BaseVault__InvalidAddress(feeReceiver_);
        
        IConfigurationManager.FeeConfig memory feeConfig = configManager.getFeeConfig();
        if (managementFee_ > feeConfig.maxManagementFee) revert BaseVault__InvalidFee(managementFee_);
        if (performanceFee_ > feeConfig.maxPerformanceFee) revert BaseVault__InvalidFee(performanceFee_);

        strategy = IStrategy(strategy_);
        feeReceiver = feeReceiver_;
        managementFee = managementFee_;
        performanceFee = performanceFee_;
        lastHarvestTimestamp = block.timestamp;

        emit StrategyUpdated(address(0), strategy_);
        emit FeeReceiverUpdated(address(0), feeReceiver_);
        emit FeesUpdated(managementFee_, performanceFee_);
    }

    function deposit(uint256 assets, address receiver) 
        public 
        override(IBaseVault, ERC4626) 
        nonReentrant 
        whenNotPaused 
        returns (uint256 shares) 
    {
        if (!configManager.validateDeposit(assets)) revert BaseVault__InvalidAmount(assets);

        shares = super.deposit(assets, receiver);

        // Invest in strategy if needed
        _investInStrategy();

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override(IBaseVault, ERC4626) nonReentrant returns (uint256 shares) {
        if (!configManager.validateWithdraw(assets)) revert BaseVault__ExceedsLimit(assets, maxWithdraw(owner));

        // Withdraw from strategy if needed
        if (assets > _idleAssets()) {
            _withdrawFromStrategy(assets - _idleAssets());
        }

        shares = super.withdraw(assets, receiver, owner);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    function depositWithPermit(
        uint256 assets,
        address receiver,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint256) {
        IERC20Permit(address(asset())).permit(
            msg.sender,
            address(this),
            assets,
            deadline,
            v,
            r,
            s
        );
        return deposit(assets, receiver);
    }

    /*//////////////////////////////////////////////////////////////
                        MANAGEMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setStrategy(address newStrategy) external override onlyOwner {
        if (newStrategy == address(0)) revert BaseVault__InvalidAddress(newStrategy);
        if (!configManager.validateStrategyChange(newStrategy)) revert BaseVault__InvalidStrategy(newStrategy);

        address oldStrategy = address(strategy);
        
        // Withdraw all funds from current strategy
        if (oldStrategy != address(0)) {
            uint256 strategyBalance = strategy.getTotalAssets();
            if (strategyBalance > 0) {
                _withdrawFromStrategy(strategyBalance);
            }
        }

        strategy = IStrategy(newStrategy);
        emit StrategyUpdated(oldStrategy, newStrategy);

        // Invest in new strategy
        _investInStrategy();
    }

    function setFees(uint256 managementFee_, uint256 performanceFee_) external override onlyOwner {
        IConfigurationManager.FeeConfig memory feeConfig = configManager.getFeeConfig();
        if (managementFee_ > feeConfig.maxManagementFee) revert BaseVault__InvalidFee(managementFee_);
        if (performanceFee_ > feeConfig.maxPerformanceFee) revert BaseVault__InvalidFee(performanceFee_);

        managementFee = managementFee_;
        performanceFee = performanceFee_;
        emit FeesUpdated(managementFee_, performanceFee_);
    }

    function setFeeReceiver(address newFeeReceiver) external override onlyOwner {
        if (newFeeReceiver == address(0)) revert BaseVault__InvalidAddress(newFeeReceiver);
        
        address oldFeeReceiver = feeReceiver;
        feeReceiver = newFeeReceiver;
        emit FeeReceiverUpdated(oldFeeReceiver, newFeeReceiver);
    }

    function harvestYield() external override returns (uint256 yieldAmount) {
        if (address(strategy) == address(0)) revert BaseVault__InvalidStrategy(address(0));

        yieldAmount = strategy.harvestYield();
        uint256 fee = (yieldAmount * performanceFee) / MAX_BPS;
        
        if (fee > 0) {
            IERC20(asset()).safeTransfer(feeReceiver, fee);
        }

        lastHarvestTimestamp = block.timestamp;
        emit YieldHarvested(yieldAmount, fee);
        return yieldAmount;
    }

    function emergencyWithdraw(uint256 amount) external override onlyOwner {
        if (address(strategy) == address(0)) return;

        uint256 withdrawnAmount;
        if (amount == 0) {
            withdrawnAmount = strategy.getTotalAssets();
            _withdrawFromStrategy(withdrawnAmount);
        } else {
            _withdrawFromStrategy(amount);
            withdrawnAmount = amount;
        }

        emit EmergencyWithdraw(address(strategy), withdrawnAmount);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view override(IBaseVault, ERC4626) returns (uint256) {
        return _idleAssets() + (address(strategy) != address(0) ? strategy.getTotalAssets() : 0);
    }

    function maxDeposit(address) public view override(IBaseVault, ERC4626) returns (uint256) {
        if (paused()) return 0;
        IConfigurationManager.VaultLimits memory limits = configManager.getVaultLimits();
        return limits.maxDeposit;
    }

    function maxWithdraw(address owner) public view override(IBaseVault, ERC4626) returns (uint256) {
        IConfigurationManager.VaultLimits memory limits = configManager.getVaultLimits();
        return Math.min(limits.maxWithdraw, convertToAssets(balanceOf(owner)));
    }

    function getStrategy() external view override returns (address) {
        return address(strategy);
    }

    function getFees() external view override returns (uint256, uint256) {
        return (managementFee, performanceFee);
    }

    function getFeeReceiver() external view override returns (address) {
        return feeReceiver;
    }

    function getAPY() external view override returns (uint256) {
        if (address(strategy) == address(0)) return 0;
        return strategy.getExpectedAPY();
    }

    function isPaused() external view override returns (bool) {
        return paused();
    }

    function getSharePrice() external view override returns (uint256) {
        return convertToAssets(10 ** decimals());
    }

    function getConfiguration() external view override returns (bytes memory) {
        return abi.encode(
            address(strategy),
            feeReceiver,
            managementFee,
            performanceFee,
            lastHarvestTimestamp
        );
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _investInStrategy() internal {
        if (address(strategy) == address(0)) return;

        uint256 idle = _idleAssets();
        if (idle > 0) {
            IERC20(asset()).safeApprove(address(strategy), idle);
            strategy.invest(idle);
        }
    }

    function _withdrawFromStrategy(uint256 amount) internal {
        if (address(strategy) == address(0)) return;
        strategy.withdraw(amount);
    }

    function _idleAssets() internal view returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }

    /// @dev Hook that is called before any deposit/mint.
    function _beforeTokenTransfer(address from, address to, uint256) internal {
        if (from == address(0)) { // mint
            if (paused()) revert BaseVault__VaultPaused();
        }
    }

    /// @notice Pause the vault
    function pause() external override onlyOwner {
        _pause();
    }

    /// @notice Unpause the vault
    function unpause() external override onlyOwner {
        _unpause();
    }
}