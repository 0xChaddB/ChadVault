// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockPool {
    mapping(address => mapping(address => uint256)) public suppliedTokens;

    event Supplied(address asset, uint256 amount, address onBehalfOf);
    event Withdrawn(address asset, uint256 amount, address to);

    function supply(address asset, uint256 amount, address onBehalfOf, uint16) external {
        require(asset != address(0), "Invalid asset");
        require(amount > 0, "Invalid amount");

        suppliedTokens[onBehalfOf][asset] += amount;

        emit Supplied(asset, amount, onBehalfOf);
    }

    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
        require(asset != address(0), "Invalid asset");
        require(amount > 0, "Invalid amount");
        require(suppliedTokens[msg.sender][asset] >= amount, "Insufficient balance");

        suppliedTokens[msg.sender][asset] -= amount;

        emit Withdrawn(asset, amount, to);
        return amount;
    }

    // Mock function to simulate interest accrual (optional)
    function simulateInterest(address asset, uint256 interestAmount) external {
        // Mint additional tokens to simulate interest
        IERC20(asset).transfer(address(this), interestAmount);
    }

    // Mock function to return the pool address
    function getPool() external view returns (address) {
        return address(this);
    }
}