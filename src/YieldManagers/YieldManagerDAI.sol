// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IPool} from "@aave/contracts/interfaces/IPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// This contract will only use DAI for now
// Use supplywithpermit with ERC2612 tokens (DAI)
// Use supply + approve with non ERC2612 (USDT)
contract YieldManagerDAI {

    IPool public aavePool; // Aave lending pool
    IERC20 public asset;   // Underlying ERC-20 token (DAI)

    constructor(address _aavePool, IERC20 _asset) {
        aavePool = IPool(_aavePool);
        asset = _asset;
    }

    /* We will not use SupplyWithPermit from Aave, because ERC2612 is user-facing feature.
    * Yield Manager doesn’t care about ERC-2612. It handles assets passed by the vault.
    */

    // Deposit with assets into Aave for DAI
    function depositToAave(address asset, uint256 amount) external {
        require(asset.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        asset.approve(address(aavePool), amount);
        aavePool.supply(address(asset), amount, address(this), 0);
    }

    /**
    * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
    * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
    * @param asset The address of the underlying asset to withdraw
    * @param amount The underlying amount to be withdrawn
    *   - Send the value type(uint256).max in order to withdraw the whole   aToken balance
    * @param to The address that will receive the underlying, same as msg.sender if the user
    *   wants to receive it on his own wallet, or a different address if the beneficiary is a
    *   different wallet
    * @return The final amount withdrawn
    */
    function withdrawToAave(address asset, uint256 amount, address to) external returns (uint256) {
        
    }

}