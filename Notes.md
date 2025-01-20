# Notes for DeFi Yield Farming Project

## Overview
This project aims to build a DeFi yield farming platform leveraging a **real yield model**, starting with basic functionalities and progressively adding advanced features.

## Phase 1: Initial Implementation
### Key Features
1. **Single Token Support:**
   - Use **DAI** as the only token for staking and yield generation.
   - Showcase ERC-4626 compliance for tokenized vaults.
2. **Single Yield App Integration:**
   - Integrate **Aave** to generate yield from staked DAI.
3. **Basic Functionality:**
   - Deposit, withdraw, and track yield.
   - Implement a simple `YieldManager` contract to interact with Aave.
4. **Testing:**
   - Include Foundry test cases for core functionalities such as:
     - Deposit and withdrawal.
     - Yield calculation and distribution.
     - Edge case handling for minimum/maximum deposits.

## Phase 2: Advanced Features
### Multi-Token Support
1. Add support for **USDT** alongside DAI.
2. Showcase **ERC-2612** (Permit) capabilities for gasless approvals on DAI and USDT.
   - Ensure off-chain signing and validation on-chain.

### Multiple Yield Apps
1. Integrate **Uniswap** as an additional yield source.
   - Utilize liquidity pools for generating yield.
   - Allow users to choose between Aave and Uniswap for yield generation.

### Additional Features
1. **Dynamic Strategy Allocation:**
   - Allow users to allocate a percentage of their funds to different yield apps.
2. **Performance Metrics:**
   - Track and display APY and historical yield performance for both tokens and strategies.
3. **Security Enhancements:**
   - Implement pause mechanisms and access control.
   - Include upgradeability using OpenZeppelin’s proxy pattern.

## Technical Details
1. **Contracts:**
   - **Vault Contract:**
     - Handle deposits, withdrawals, and ERC-4626 compliance.
   - **YieldManager Contract:**
     - Interact with Aave and Uniswap protocols.
     - Manage allocation and switching between yield apps.
2. **ERC Standards:**
   - **ERC-4626:** For vaults.
   - **ERC-2612:** For gasless approvals.
3. **Libraries:**
   - Use OpenZeppelin libraries for security and standard implementations.

## Testing Plan
1. **Unit Tests:**
   - Test deposit, withdrawal, and yield calculations.
   - Validate ERC-2612 signature approvals.
2. **Integration Tests:**
   - Ensure smooth interaction between contracts and external protocols (Aave, Uniswap).
3. **Stress Tests:**
   - Simulate high traffic and edge cases.

## Deployment
1. Deploy the contracts on a testnet (e.g., Goerli or Sepolia) for validation.
2. Use a basic frontend to showcase functionality (optional).

## Next Steps
1. Complete Phase 1 implementation and testing.
2. Plan for Phase 2 with detailed integration steps for USDT and Uniswap.
3. Continuously iterate and add features based on skill improvement and project goals.

---
### Notes
- Prioritize clean, modular code to ensure extensibility.
- Focus on writing clear, reusable test cases to validate each feature.
- Highlight compliance with ERC standards to demonstrate expertise.
