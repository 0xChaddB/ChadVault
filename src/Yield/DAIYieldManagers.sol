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

    uint256 private totalInvestedAssets;

    // Events
    event LogInvested(address indexed vault, uint256 amount);
    event LogWithdrawn(address indexed vault, uint256 amount);

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

    modifier validateAmount(uint256 amount) {
        require(amount > 0, "Amount must be greater than zero");
        _;
    }

    // Invest DAI into Aave
    function invest(uint256 amount) external onlyVault validateAmount(amount) {
        // Transfer DAI from the Vault to this contract
        IERC20(dai).safeTransferFrom(vault, address(this), amount);

        // Supply the tokens to Aave
        aavePool.supply(dai, amount, address(this), 0);

        // Update total invested assets
        totalInvestedAssets += amount;

        emit LogInvested(vault, amount);
    }

    // Withdraw DAI from Aave
    function withdraw(uint256 amount) external onlyVault validateAmount(amount) {
        // Withdraw the tokens from Aave
        uint256 withdrawnAmount = aavePool.withdraw(dai, amount, vault);

        // Update total invested assets
        totalInvestedAssets -= withdrawnAmount;

        emit LogWithdrawn(vault, withdrawnAmount);
    }

    // Returns the total DAI currently managed by the YieldManager
    function totalInvested() external view override returns (uint256) {
        return totalInvestedAssets;
    }

    // Returns the total assets (both idle and invested)
    function totalAssets() external view returns (uint256) {
        return IERC20(dai).balanceOf(address(this)) + totalInvestedAssets;
    }
}
