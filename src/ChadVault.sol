// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC4626, IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";


contract ChadVault is ERC4626 {

    constructor(IERC20 _asset)   
        ERC20("vChadDAI", "VCD") 
        ERC4626(_asset) 
    {
        require(address(_asset) != address(0), "Invalid asset address");
    }
}