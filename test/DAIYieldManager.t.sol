// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DAIYieldManager} from "../src/DAIYieldManager.sol"; 

contract DAIYieldManagerTest is Test {
    DAIYieldManager public dAIYieldManager;

    function setUp() public {
        dAIYieldManager = new DAIYieldManager();
    }
}
