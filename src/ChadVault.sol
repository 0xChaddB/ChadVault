// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


import {MockDAI} from "./mock/MockDAI.sol";
import {ERC4626, IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// ChadVault implemented ReentrancyGuard, but what about cross-contract Reentracys?
// Does the permit disable attacks? Should implement a whitelist for trusted tokens ?
// What about Tokens contract permits function? What are their different usage and restrictions? 
contract ChadVault is ERC4626, ReentrancyGuard {

    constructor(IERC20 _asset)   
        ERC20("vChadDAI", "VCD") 
        ERC4626(_asset) 
    {
        require(address(_asset) != address(0), "Invalid asset address");
    }

    /**
     * @dev Deposit with permit to save an extra transaction.
     * @param amount The amount of tokens to deposit.
     * @param receiver The address that will receive the Vault shares.
     * @param deadline The deadline for the signature to be valid.
     * @param v, r, s The components of the signature for permit.
     */
    function depositWithPermit(
        uint256 amount,
        address receiver,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant() {
        // Use permit to approve the Vault
        MockDAI(address(asset())).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );

        // Deposit the tokens after approval
        deposit(amount, receiver);
    }

    /**
     * @dev Withdraw with permit to save an extra transaction.
     * @param shares The amount of Vault shares to redeem.
     * @param receiver The address to receive the withdrawn assets.
     * @param owner The address that owns the shares to be redeemed.
     * @param deadline The deadline for the signature to be valid.
     * @param v, r, s The components of the signature for the permit.
    */
    function withdrawWithPermit(
        uint256 shares,
        address receiver,
        address owner,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        // Call permit on the underlying token (MockDAI)
        IERC20Permit(address(asset())).permit(
            owner,
            address(this),
            shares,
            deadline,
            v,
            r,
            s
        );

        // Proceed with the withdraw process
        withdraw(shares, receiver, owner);
    }
    
}
