// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPoolAddressesProvider} from "@aave/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "@aave/contracts/interfaces/IPool.sol";
import {IYieldManager} from "../IYieldManager.sol";


// @Dev Need to implement Yield managing...
contract DAIYieldManager is IYieldManager {

    // State variables
    address public immutable vault;
    address public immutable dai;
    IPool public immutable aavePool;

    uint256 private totalInvestedDai;

    // Events
    event LogInvested(address indexed vault, uint256 amount);
    event LogWithdrawn(address indexed vault, uint256 amount);
    event LogAllowanceUpdated(address token, uint256 amount);

    // Errors

    error InsufficientBalance(uint256 requested, uint256 available);
    error ApprovalFailed();
    error InvalidAmount();
    error AaveSupplyFailed();
    error AaveWithdrawalFailed();


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
            //@dev useless ??
        // IERC20(dai).approve(address(aavePool), type(uint256).max);
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

        uint256 allowance = IERC20(dai).allowance(address(vault), address(aavePool));
        //@Dev Following if statement may be useless ?
        if (allowance < amount) {
            if (!IERC20(dai).approve(address(aavePool), type(uint256).max)) {
                revert ApprovalFailed();
            }
            emit LogAllowanceUpdated(address(aavePool), type(uint256).max);
        }

        // Assuming the aave protocol will not fail if preconditions are met
        bool success = _supplyToAave(amount);
        if (!success) {
            revert AaveSupplyFailed();
        }

        totalInvestedDai += amount;
        emit LogInvested(vault, amount);
    }

    function _supplyToAave(uint256 _amount) internal returns (bool) {
        // External call to Aave
        aavePool.supply(dai, _amount, address(this), 0);
        return true; // If it reverts, the whole transaction reverts
    }


    // Withdraw DAI from Aave
    function withdraw(uint256 amount) external onlyVault {
        if (amount == 0) {
            revert InvalidAmount();
        }

        // Check if sufficient assets are invested
        if (amount > totalInvestedDai) {
            revert InsufficientBalance({requested: amount, available: totalInvestedDai});
        }

        // Assuming the Aave interaction will not fail if preconditions are met
        bool success = _withdrawFromAave(amount);
        if (!success) {
            revert AaveWithdrawalFailed();
        }

        // Update total invested assets
        totalInvestedDai -= amount;

        emit LogWithdrawn(vault, amount);
    }

    function _withdrawFromAave(uint256 _amount) internal returns (bool) {
        // External call to Aave for withdrawing funds
        uint256 withdrawnAmount = aavePool.withdraw(dai, _amount, vault);

        // Ensure the withdrawn amount matches the requested amount
        if (withdrawnAmount != _amount) {
            return false;
        }

        return true; // If this fails, the whole transaction reverts
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
