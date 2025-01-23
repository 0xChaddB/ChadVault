// SPDX-License-Idetnifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPoolAddressesProvider} from "@aave/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "@aave/contracts/interfaces/IPool.sol";
import {IYieldManager} from "../IYieldManager.sol";

contract DAIYieldManager is IYieldManager {
    address public immutable vault;
    address public immutable dai;
    IPool public immutable aavePool;

    uint256 private totalInvestedAssets;

    constructor(address _vault, address _dai, address _aaveProvider) {
        vault = _vault;
        dai = _dai;

        IPoolAddressesProvider provider = IPoolAddressesProvider(_aaveProvider);
        aavePool = IPool(provider.getPool());
    }

    modifier onlyVault() {
        require(msg.sender == vault);
        _;
    }

    //Invest DAI into Aave
    function invest(uint256 amount) external override onlyVault() {
        IERC20(dai).safeTransferFrom(vault, address(this), amount); //Pull DAI from Vault
        IERC20(dai).approve(address(aavePool), amount); //Aaprove Aave to spend DAI
        aavePool.deposit(dai, amount, address(this), 0); // Deposit into Aave

        totalInvestedAssets += amount; //Update accounting

        emit LogInvested(amount);
    }

    function withdraw(uint256 amount) external override onlyVault() {
        uint256 withdrawn = aavePool.withdraw(dai, amount, vault); //Withdraw from Aave to the vault
        totalInvestedAssets -= withdrawn; //Update accounting

        emit LogWithdrawn(withdrawn);
    }

    // Returns the total DAI currently managed by the YieldManager
    function totalInvested() external view override returns (uint256) {
        return totalInvestedAssets;
    }
}