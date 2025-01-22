// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ChadVault} from "../src/ChadVault.sol";
import {Test} from "forge-std/Test.sol";
import {MockDAI} from "../src/mock/MockDAI.sol";

contract VaultTest is Test {
    event LogDigest(bytes32 digest);
    event LogSigner(address signer);
    event LogDomainSeparator(bytes32 domainSeparator);

    ChadVault vault;
    MockDAI dai;

    address USER1 = makeAddr("USER1");

    uint256 constant STARTING_BALANCE = 10e18; // 10 DAI
    uint256 depositAmount = 1e18;   

    function setUp() public {
        dai = new MockDAI();
        vault = new ChadVault(dai);
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
        emit LogDigest(digest);
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
}
