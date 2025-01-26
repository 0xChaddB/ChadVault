// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ChadVault} from "../src/ChadVault.sol";
import {Test} from "forge-std/Test.sol";
import {MockDAI} from "../src/mock/MockDAI.sol";
import {DAIYieldManager} from "../src/Yield/DAIYieldManager.sol";

contract VaultTest is Test {
    event LogSigner(address signer);
    event LogDomainSeparator(bytes32 domainSeparator);
    event LogNonceFromTest(uint256 nonce);
    event LogDigestFromTest(bytes32 digest);

    ChadVault vault;
    MockDAI dai;
    DAIYieldManager yielder;

    address USER1 = makeAddr("USER1");

    uint256 constant STARTING_BALANCE = 10e18; // 10 DAI
    uint256 depositAmount = 1e18;   

    function setUp() public {
        //yielder = new DAIYieldManager();
        dai = new MockDAI();
        vault = new ChadVault(dai, address(yielder));
        dai.mint(USER1, STARTING_BALANCE);
    }

    // for ERC2612 tokens like DAI, we can just call depositWithpermit, instead of Approve and then deposit ! nice :) 
    // its seems DAI has special ERC2612 allowance, DAI here is just for the name...
    function testDepositWithPermit() public {
        uint256 deadline = block.timestamp + 1 hours;

        // Ensure the DOMAIN_SEPARATOR matches
        bytes32 expectedDomainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(dai.name())),
                keccak256(bytes("1")),
                block.chainid,
                address(dai)
            )
        );
        assertEq(dai.DOMAIN_SEPARATOR(), expectedDomainSeparator, "DOMAIN_SEPARATOR mismatch");

        uint256 nonce = dai.nonces(USER1);
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                dai.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                        USER1,
                        address(vault),
                        depositAmount,
                        nonce,
                        deadline
                    )
                )
            )
        );

        // Log the digest and DOMAIN_SEPARATOR for debugging
        emit LogDigestFromTest(digest);
        emit LogDomainSeparator(dai.DOMAIN_SEPARATOR());

        uint256 USER1_PRIVATE_KEY = uint256(keccak256("USER1"));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(USER1_PRIVATE_KEY, digest);

        vm.startPrank(USER1);

        // Deposit using permit
        vault.depositWithPermit(depositAmount, USER1, deadline, v, r, s);

        // Assertions
        assertEq(vault.totalAssets(), depositAmount, "Vault assets mismatch");
        assertEq(vault.balanceOf(USER1), depositAmount, "User shares mismatch");

        vm.stopPrank();
    }

    function testWithdrawWithPermit() public {
        uint256 withdrawAmount = 1e18;
        uint256 deadline = block.timestamp + 1 hours;

        vm.startPrank(USER1);

        // Deposit assets
        dai.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, USER1);

        vm.stopPrank();

        // Check DOMAIN_SEPARATOR
        bytes32 expectedDomainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(dai.name())),
                keccak256(bytes("1")),
                block.chainid,
                address(dai)
            )
        );
        assertEq(dai.DOMAIN_SEPARATOR(), expectedDomainSeparator, "DOMAIN_SEPARATOR mismatch");

        uint256 nonce = dai.nonces(USER1);

        // Compute digest
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                dai.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                        USER1,
                        address(vault),
                        withdrawAmount,
                        nonce,
                        deadline
                    )
                )
            )
        );

        // Sign the digest
        uint256 USER1_PRIVATE_KEY = uint256(keccak256("USER1"));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(USER1_PRIVATE_KEY, digest);

        vm.startPrank(USER1);

        // Withdraw with permit
        vault.withdrawWithPermit(withdrawAmount, USER1, USER1, deadline, v, r, s);

        // Assertions
        assertEq(vault.totalAssets(), 0, "Vault assets mismatch after withdraw");
        assertEq(vault.balanceOf(USER1), 0, "User shares mismatch after withdraw");
        // USER1's final DAI balance should match the initial balance (10e18)
        assertEq(
            dai.balanceOf(USER1),
            STARTING_BALANCE,
            "DAI balance mismatch after withdraw"
        );

        vm.stopPrank();
    }




}
