// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {DAIYieldManager} from "../src/Yield/DAIYieldManager.sol";
import {ChadVault} from "../src/ChadVault.sol";
import {MockDAI} from "../src/mock/MockDAI.sol";
import {MockPool} from "../src/mock/MockAavePool.sol"; 
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TestUtils} from "./TestUtils.sol";


contract DAIYieldManagerTest is Test, TestUtils {
    DAIYieldManager public yieldManager;
    ChadVault public vault;
    MockDAI public dai;
    MockPool public mockPool;

    address public aaveProvider;
    address public user1;

    uint256 constant INITIAL_BALANCE = 1_000e18;

    function setUp() public {
        // Create mock addresses
        user1 = makeAddr("USER1");
        aaveProvider = makeAddr("MockAaveProvider");

        vm.label(user1, "USER1");
        vm.label(aaveProvider, "MockAaveProvider");

        // Deploy MockDAI and mint tokens for user
        dai = new MockDAI();
        dai.mint(user1, INITIAL_BALANCE);

        // Deploy MockPool
        mockPool = new MockPool();

        // Compute the address of the YieldManager before deployment
        uint256 deployNonce = vm.getNonce(address(this));
        address predictedYieldManager = addressFrom(address(this), deployNonce + 1);

        // Deploy ChadVault with the predicted YieldManager address
        vault = new ChadVault(IERC20(address(dai)), predictedYieldManager);

        // Deploy DAIYieldManager using the actual Vault address
        yieldManager = new DAIYieldManager(address(vault), address(dai), address(mockPool));

        // Label contracts for debugging
        vm.label(address(dai), "MockDAI");
        vm.label(address(mockPool), "MockPool");
        vm.label(address(vault), "ChadVault");
        vm.label(address(yieldManager), "DAIYieldManager");
    }

    function testInvest() public {
        vm.startPrank(user1);

        uint256 depositAmount = 100e18;

        // Approve Vault for DAI
        dai.approve(address(vault), depositAmount);

        // Deposit into Vault
        vault.deposit(depositAmount, user1);

        // Check Vault and YieldManager balances
        assertEq(vault.totalAssets(), depositAmount, "Vault total assets mismatch");
        assertEq(yieldManager.totalInvested(), depositAmount, "YieldManager invested amount mismatch");

        // Check MockPool balances
        assertEq(mockPool.suppliedTokens(address(yieldManager), address(dai)), depositAmount, "MockPool balance mismatch");

        vm.stopPrank();
    }

    function testWithdraw() public {
        vm.startPrank(user1);

        uint256 depositAmount = 100e18;

        // Approve and deposit into the Vault
        dai.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user1);

        // Withdraw from the Vault
        vault.withdraw(depositAmount, user1, user1);

        // Assert balances and state
        assertEq(dai.balanceOf(user1), INITIAL_BALANCE, "User DAI balance mismatch after withdraw");
        assertEq(vault.totalAssets(), 0, "Vault total assets mismatch after withdraw");

        // Check that the funds were withdrawn from the MockPool
        assertEq(mockPool.suppliedTokens(address(yieldManager), address(dai)), 0, "MockPool supplied tokens mismatch after withdraw");

        vm.stopPrank();
    }

    function testUnauthorizedInvest() public {
        vm.startPrank(user1);
        vm.expectRevert("Caller is not the Vault");
        yieldManager.invest(100e18);
        vm.stopPrank();
    }

    function testUnauthorizedWithdraw() public {
        vm.startPrank(user1);
        vm.expectRevert("Caller is not the Vault");
        yieldManager.withdraw(100e18);
        vm.stopPrank();
    }
}