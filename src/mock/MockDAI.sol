// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
    
// its seems DAI has special ERC2612 allowance, DAI here is just for the name...
contract MockDAI is ERC20, IERC20Permit {

    mapping(address => uint256) private _nonces;
    bytes32 private immutable _DOMAIN_SEPARATOR;

    // Event for logging the calculated digest
    event LogDigest(bytes32 digest);
    // Event for logging the recovered signer
    event LogSigner(address signer);
    // Event for logging the expected owner (signer)
    event LogExpectedSigner(address expectedSigner);
    // Event for logging the DOMAIN_SEPARATOR
    event LogDomainSeparator(bytes32 domainSeparator);


    constructor() ERC20("Mock DAI", "mDAI") {
        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name())),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    // Mint function for testing purposes
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(block.timestamp <= deadline, "Permit expired");

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                owner,
                spender,
                value,
                _nonces[owner]++,
                deadline
            )
        );

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", _DOMAIN_SEPARATOR, structHash));
        address signer = ecrecover(digest, v, r, s);
        emit LogDigest(digest);
        emit LogSigner(signer);

        require(signer == owner, "Invalid signature");
        _approve(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _DOMAIN_SEPARATOR;
    }

    function nonces(address owner) external view override returns (uint256) {
        return _nonces[owner];
    }
}
