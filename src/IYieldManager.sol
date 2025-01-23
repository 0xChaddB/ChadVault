// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IYieldManager {
    function invest(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function totalInvested() external view returns (uint256);
}