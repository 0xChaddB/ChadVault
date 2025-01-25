// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPoolAddressesProvider} from "@aave/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "@aave/contracts/interfaces/IPool.sol";
import {IYieldManager} from "../IYieldManager.sol";

contract DAIYieldManager is IYieldManager {
    using SafeERC20 for IERC20;

    // State variables
    address public immutable vault;
    address public immutable dai;
    IPool public immutable aavePool;

    uint256 private totalInvestedDai;

    // Events
    event LogInvested(address indexed vault, uint256 amount);
    event LogWithdrawn(address indexed vault, uint256 amount);

    // Errors

    error InsufficientBalance(uint256 requested, uint256 available);
    error ApprovalFailed();
    error InvalidAmount();
    error AaveInteractionFailed();

    // Constructor
    constructor(address _vault, address _dai, address _aaveProvider) {
        require(_vault != address(0), "Invalid Vault address");
        require(_dai != address(0), "Invalid DAI address");
        require(_aaveProvider != address(0), "Invalid Aave Provider address");

        vault = _vault;
        dai = _dai;

        // Initialize Aave pool
        IPoolAddressesProvider provider = IPoolAddressesProvider(_aaveProvider);
        aavePool = IPool(provider.getPool());

        // Approve Aave to use DAI
        IERC20(_dai).safeApprove(address(aavePool), type(uint256).max);
    }

    // Modifiers
    modifier onlyVault() {
        require(msg.sender == vault, "Caller is not the Vault");
        _;
    }

    // Invest DAI into Aave
    function invest(uint256 amount) external onlyVault {
        if (amount == 0) {
            revert InvalidAmount();
        }

        uint256 vaultBalance = IERC20(dai).balanceOf(vault);
        if (amount > vaultBalance) {
            revert InsufficientBalance({requested: amount, available: vaultBalance});
        }

        uint256 allowance = IERC20(dai).allowance(address(this), address(aavePool));
        if (allowance < amount) {
            if (!IERC20(dai).approve(address(aavePool), type(uint256).max)) {
                revert ApprovalFailed();
            }
            emit LogAllowanceUpdated(address(aavePool), type(uint256).max);
        }

        // Assuming the external protocol will not fail if preconditions are met
        bool success = _supplyToAave(amount);
        if (!success) {
            revert AaveInteractionFailed();
        }

        totalInvestedDai += amount;
        emit LogInvested(vault, amount);
    }

    function _supplyToAave(uint256 amount) internal returns (bool) {
        // External call to Aave
        aavePool.supply(dai, amount, address(this), 0);
        return true; // If it reverts, the whole transaction reverts
    }


    // Withdraw DAI from Aave
    function withdraw(uint256 amount) external onlyVault validateAmount(amount) {
        require (amount <= totalInvestedDai, "Not enough invested DAI");
        // Withdraw the tokens from Aave
        uint256 withdrawnAmount = aavePool.withdraw(dai, amount, vault);

        // Update total invested assets
        totalInvestedDai -= withdrawnAmount;

        emit LogWithdrawn(vault, withdrawnAmount);  
    }

    // Returns the total DAI currently managed by the YieldManager
    function totalInvested() external view override returns (uint256) {
        return totalInvestedDai;
    }

    // Returns the total assets (sum of idle and invested)
    function totalAssets() external view returns (uint256) {
        return IERC20(dai).balanceOf(address(this)) + totalInvestedDai;
    }
}
