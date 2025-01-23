// SPDX-License-Idetnifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPoolAddressesProvider} from "@aave/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "@aave/contracts/interfaces/IPool.sol";
import {IYieldManager} from "../IYieldManager.sol";
// Since YieldManager have no balance, how can ensure they transfer the tokens to the Vault, and how the vault react from tokens being send to him ?
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
    function invest(uint256 amount) external onlyVault {
        // Ensure the Vault has approved the tokens for this contract
        asset.safeTransferFrom(vault, address(this), amount);

        // Supply the tokens to Aave
        pool.supply(address(asset), amount, address(this), 0);

        emit LogInvested(amount);
    }


    function withdraw(uint256 amount) external onlyVault {
        // Withdraw the tokens from Aave
        pool.withdraw(address(asset), amount, vault);

        emit LogWithdrawn(amount);
    }

    // Returns the total DAI currently managed by the YieldManager
    function totalInvested() external view override returns (uint256) {
        return totalInvestedAssets;
    }
}