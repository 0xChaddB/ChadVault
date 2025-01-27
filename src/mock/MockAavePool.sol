// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IPool} from "@aave/contracts/interfaces/IPool.sol";
import {IPoolAddressesProvider} from "@aave/contracts/interfaces/IPoolAddressesProvider.sol";
// Since no mocks (NOT SURE) simulate supply/withdraw functions on aave mocks, this is our Aave mock
contract MockAavePool is IPool {
    event Supply(address indexed asset, uint256 amount, address indexed onBehalfOf, uint16 referralCode);
    event Withdraw(address indexed asset, uint256 amount, address indexed to);

    mapping(address => mapping(address => uint256)) public balances; // user => asset => balance

    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external override {
        require(amount > 0, "Amount must be greater than zero");

        // Simulate adding the supplied amount to the user's balance
        balances[onBehalfOf][asset] += amount;

        emit Supply(asset, amount, onBehalfOf, referralCode);
    }

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external override returns (uint256) {
        uint256 userBalance = balances[msg.sender][asset];
        require(amount <= userBalance, "Insufficient balance");

        // Simulate subtracting the withdrawn amount from the user's balance
        balances[msg.sender][asset] -= amount;

        emit Withdraw(asset, amount, to);
        return amount;
    }
}
