// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {ChadVault} from "../src/ChadVault.sol";
import {MockDAI} from "../src/mock/MockDAI.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract ChadVaultTest is Test {
    ChadVault public vault;
    MockDAI public dai;

    function setUp() public {
        dai = new MockDAI();
        vault = new ChadVault(dai);

        // Mint MockDAI to the test account
        dai.mint(address(this), 1000 * 10**18);
    }

    function testInitialDepositAndShares() public {
        // Approve and deposit MockDAI
        dai.approve(address(vault), 100 * 10**18);
        vault.deposit(100 * 10**18, address(this));

        // Assert that shares are minted at a 1:1 ratio
        assertEq(vault.balanceOf(address(this)), 100 * 10**18);
        assertEq(vault.totalAssets(), 100 * 10**18);
    }

    function testWithdrawAndBurnShares() public {
        // Deposit MockDAI first
        dai.approve(address(vault), 100 * 10**18);
        vault.deposit(100 * 10**18, address(this));

        // Withdraw 50 MockDAI
        vault.withdraw(50 * 10**18, address(this), address(this));

        // Assert remaining shares and total assets
        assertEq(vault.balanceOf(address(this)), 50 * 10**18);
        assertEq(vault.totalAssets(), 50 * 10**18);
    }

    function testWithdrawMoreThanAvailable() public {
        dai.approve(address(vault), 100 * 10**18);
        vault.deposit(100 * 10**18, address(this));

        // Expect the custom error for exceeding withdrawal limit
        vm.expectRevert(abi.encodeWithSelector(
            ERC4626.ERC4626ExceededMaxWithdraw.selector,
            address(this),    // Account trying to withdraw
            150 * 10**18,     // Requested amount
            100 * 10**18      // Maximum available amount
        ));
        vault.withdraw(150 * 10**18, address(this), address(this));
    }


    function testShareToAssetRatioUpdates() public {
        dai.approve(address(vault), 100 * 10**18);
        vault.deposit(100 * 10**18, address(this));

        // Simulate external yield
        dai.mint(address(vault), 50 * 10**18); // Add 50 extra DAI to the vault

        // Assert total assets
        assertEq(vault.totalAssets(), 150 * 10**18);

        // Assert share-to-asset ratio with a tolerance
        uint256 expectedAssets = 150 * 10**18;
        uint256 actualAssets = vault.convertToAssets(100 * 10**18);

        assertApproxEqRel(actualAssets, expectedAssets, 1e15); // Allow 0.01% tolerance
    }
}
