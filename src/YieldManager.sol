// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IPool} from "@aave/contracts/interfaces/IPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Use supplywithpermit with ERC2612 tokens (DAI)
// Use supply + approve with non ERC2612 (USDT)
contract YieldManager {

    IPool public aavePool; // Aave lending pool
    IERC20 public asset;   // Underlying ERC-20 token (DAI)

    constructor(address _aavePool, IERC20 _asset) {
        aavePool = IPool(_aavePool);
        asset = _asset;
    }
    /**
    * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
    * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
    * @param asset The address of the underlying asset to supply
    * @param amount The amount to be supplied
    * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
    *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
    *   is a different wallet
    * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
    *   0 if the action is executed directly by the user, without any middle-man
    */
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external {}

        /**
    * @notice Supply with transfer approval of asset to be supplied done via permit function
    * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
    * @param asset The address of the underlying asset to supply
    * @param amount The amount to be supplied
    * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
    *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
    *   is a different wallet
    * @param deadline The deadline timestamp that the permit is valid
    * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
    *   0 if the action is executed directly by the user, without any middle-man
    * @param permitV The V parameter of ERC712 permit sig
    * @param permitR The R parameter of ERC712 permit sig
    * @param permitS The S parameter of ERC712 permit sig
    */
    function supplyWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external {}
    
    // Deposit with permit assets into Aave 
    function depositPermitAave(uint256 amount) external {
        require(asset.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        asset.approve(address(aavePool), amount);
        aavePool.supplyWithPermit();

    }
        
    }
    /**
    * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
    * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
    * @param asset The address of the underlying asset to withdraw
    * @param amount The underlying amount to be withdrawn
    *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
    * @param to The address that will receive the underlying, same as msg.sender if the user
    *   wants to receive it on his own wallet, or a different address if the beneficiary is a
    *   different wallet
    * @return The final amount withdrawn
    */
    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {}

}