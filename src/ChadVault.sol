// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ChadVault is ERC4626 {

    address public strategy;


    constructor(IERC20 _asset) ERC4626(_asset)  ERC20("ChadToken", "CTN"){} // ERC4626 = Underlying asset (MockDAI) CTN = v share Token


    /* This function is the main function called by user to deposit asset to the token
    It will be called by other deposit function? */

    function deposit(uint256 assets, address receiver) public override returns (uint256) {
        require(assets > 0, "ChadVault: Cannot deposit zero assets");
        return super.deposit(assets, receiver); // Use inherited ERC4626 logic
    }


    /* This function is the deposit function ONLY for DAI special ERC2612 */
    function depositWithPermitDAI(
    uint256 assets,
    address receiver,
    uint256 deadline,
    bool allowed,
    uint8 v,
    bytes32 r,
    bytes32 s
    ) external returns (uint256) {
        // Use DAI's specific permit format
        IDaiPermit(address(asset)).permit(
            msg.sender,  // Holder (owner of DAI)
            address(this), // Spender (Vault)
            asset.nonces(msg.sender), // Current nonce
            deadline,      // Expiry timestamp
            allowed,       // True to approve, false to revoke
            v, r, s        // Signature components
        );

        // Proceed with a standard deposit
        return deposit(assets, receiver);
    }

    /* This function is the base deposit function for bsasic token with permit ERC2612 */
    function depositWithPermit(
    uint256 assets,
    address receiver,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
    ) external returns (uint256) {
        IERC20Permit(address(asset)).permit(
            msg.sender,
            address(this),
            assets,
            deadline,
            v,
            r,
            s
        );
        return deposit(assets, receiver);
    }

    function allocate(uint256 amount) external onlyOwner {
        asset.transfer(strategy, amount);
        IStrategy(strategy).deposit(amount);
    }

    function withdrawFromStrategy(uint256 amount) external onlyOwner {
        IStrategy(strategy).withdraw(amount);
        asset.transfer(address(this), amount);
    }

    function setStrategy(address _strategy) external onlyOwner {
        strategy = _strategy;
    }


}
   