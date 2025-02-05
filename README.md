# **ChadVault: DeFi Yield-Generating Vault (ERC-4626)**

---

## **Overview**
ChadVault is a modular, secure, and upgradeable decentralized finance (DeFi) vault system built on the ERC-4626 tokenized vault standard. It enables users to deposit assets (currently focusing on DAI) and earn yield from external protocols like Aave. Users receive vault shares representing their proportional ownership, which grows as the underlying assets generate returns.

The project will include a **full-stack web application** with a backend to handle on-chain interactions and off-chain monitoring, along with a **React-based frontend** that provides a user-friendly interface for deposits, withdrawals, and real-time performance tracking.

---

## **Architecture**
The system follows a modular design for scalability and security, allowing for future expansion to support multiple tokens and protocols.

### **Core Contracts**
1. **BaseVault (abstract):**
   - Manages core deposit, withdrawal, and accounting logic.
   - Implements ERC-4626.
   - Provides basic security mechanisms, such as reentrancy protection.

2. **ChadVault (implementation):**
   - Extends the BaseVault for DAI-specific implementation.
   - Allocates deposited funds to a yield manager (e.g., Aave).
   - Manages permit-based deposits and withdrawals to save gas.

3. **DAIYieldManager (Yield Manager for Aave):**
   - Handles the allocation of DAI to Aave.
   - Tracks total invested assets and manages withdrawals.
   - Designed to support future multi-protocol expansion.

4. **ConfigurationManager:**
   - Manages system parameters, including deposit limits, fee settings, and emergency configurations.
   - Controlled through role-based access.

5. **VaultAccessControl:**
   - Provides role-based access control for managing emergency functions, strategy updates, and system configuration.

6. **Strategies:**
   - Pluggable strategy contracts handle yield generation and rebalancing across various protocols.

---

## **Key Features**
### **Phase 1: Foundational Components (Current Progress ✅)**
- **Single-Token Vault:** Supports deposits and withdrawals of DAI using the ERC-4626 standard.
- **Basic Yield Generation:** Allocates DAI to Aave for yield.
- **Permit-Based Interactions:** Saves users gas by allowing them to deposit or withdraw using signed approvals.
- **Upgradeable Contracts:** Designed using OpenZeppelin’s proxy patterns for future upgrades.

### **Phase 2: Security Enhancements**
- **Cross-Contract Reentrancy Protection:** Mitigates risks associated with external contract interactions.
- **Access Control:** Role-based permissions using VaultAccessControl for emergency functions and system management.
- **Emergency Mechanisms:** Pause/unpause deposits and withdrawals in case of critical issues.
- **Slippage Protection:** Plans to implement slippage checks on withdrawals to prevent losses due to volatile market conditions.

### **Phase 3: Yield Optimization**
- **Multi-Protocol Support:** Expand to include multiple yield sources (e.g., Compound, Yearn).
- **Rebalancing Mechanism:** Reallocate funds between protocols based on yield performance.
- **Fee Structures:** Introduce management and performance fees.
  
### **Phase 4: Multi-Token Support**
- **Multi-Asset Vault:** Enable deposits of multiple ERC-20 tokens.
- **Decimal Handling:** Ensure proper conversions for tokens with different decimals.

### **Phase 5: Monitoring and Analytics**
- **On-Chain Monitoring:** Track APY, total value locked (TVL), and risk metrics.
- **Advanced Events:** Emit detailed events for deposit, withdrawal, rebalancing, and strategy updates.

### **Phase 6: Full-Stack Integration**
- **Backend (Rust):**
  - Manage off-chain logic such as yield monitoring, strategy rebalancing, and event handling.
  - Handle secure interactions with on-chain contracts and user authentication.
  - Implement APIs for frontend interaction, including deposit/withdrawal requests and performance data.

- **Frontend (React):**
  - User-friendly UI for depositing and withdrawing assets.
  - Display performance metrics like APY, user balances, and yield distribution.
  - Visualize share growth, yield generation, and portfolio breakdown.

- **Key UI Features:**
  - **Deposit/Withdraw Dashboard:** Easy-to-use interface for managing vault shares.
  - **Performance Monitoring:** Real-time APY, share price, and protocol exposure.
  - **Historical Tracking:** Graphs displaying past performance and growth.
  - **Strategy Insights:** Information about current yield sources and allocation.

---

## **Security Considerations**
ChadVault prioritizes security at every level of the architecture, with the following key measures:
- **Reentrancy Protection:** OpenZeppelin’s `ReentrancyGuard` prevents reentrancy attacks.
- **Access Control:** Role-based permissions restrict sensitive operations to authorized addresses.
- **Emergency Mechanisms:** Immediate pause/unpause functionality for critical issues.
- **Rate Limiting:** Limit large deposits and withdrawals to protect system stability.
- **Fallback Mechanisms:** Circuit breakers and recovery procedures for failed protocol interactions.

---

## **Fee Structure (Planned)**
ChadVault will introduce a hybrid fee structure:
- **Management Fee:** A percentage of the total assets under management (charged annually).
- **Performance Fee:** A percentage of the yield generated.

Fees will be accrued via virtual shares to ensure accurate accounting and minimize gas usage.

---

## **Contract Interaction Flow**
### **Deposit Flow**
1. **Frontend Interaction:** Users initiate deposits through the UI.
2. **Backend Handling:** Backend API validates and routes the request.
3. **On-Chain Execution:** The Vault checks limits and routes funds to the yield manager.
4. **Event Tracking:** Deposits trigger events for monitoring and analytics.

### **Withdrawal Flow**
1. **Frontend Interaction:** Users request withdrawals via the UI.
2. **Backend Handling:** Backend validates the request and initiates withdrawal.
3. **On-Chain Execution:** The Vault retrieves funds from the YieldManager and transfers assets.
4. **Event Tracking:** Withdrawals emit events for monitoring and analytics.

### **Rebalancing Flow**
1. **Monitoring:** The backend monitors yield performance and protocol health.
2. **Trigger Mechanism:** Threshold-based or time-based triggers initiate rebalancing.
3. **On-Chain Execution:** The Vault reallocates assets between protocols.
4. **Event Tracking:** Events are emitted to track rebalancing actions.

---

## **Roadmap**
1. **Single-Token ERC-4626 Vault:** ✅  
2. **Basic Yield Generation through Aave:** ✅  
3. **Security Enhancements:** 🚧  
4. **Multi-Protocol and Multi-Token Support:** 🚧  
5. **Fee Structure Implementation:** 🚧  
6. **Rebalancing Mechanism:** 🚧  
7. **Full-Stack Integration (Backend/Frontend):** 🚧  
8. **Monitoring and Analytics:** 🚧  

---

## **Installation and Testing**
1. **Clone the repository:**
   ```bash
   git clone https://github.com/0xChaddB/ChadVault
   cd ChadVault
   ```

2. **Compile contracts:**
   ```bash
   forge build
   ```

3. **Run tests:**
   ```bash
   forge test
   ```

4. **Run forked integration tests:**
   ```bash
   forge test --fork-url <RPC_ENDPOINT>
   ```

---

## **Planned Testing Approach**
- **Unit Tests:** Validate core functionalities such as deposits, withdrawals, and yield generation.
- **Fuzz Tests:** Test the system under randomized input conditions.
- **Invariant Tests:** Ensure critical properties remain consistent across state transitions.
- **Integration Tests:** Test interactions with real protocols on forked networks.

---

## **Future Enhancements**
- **Dynamic Strategy Rebalancing:** Automatically optimize protocol allocation based on performance.
- **Multi-Chain Deployment:** Expand deployment to chains beyond Ethereum (e.g., Polygon, Arbitrum).
- **Advanced Risk Management:** Implement risk-adjusted yield strategies.
- **Analytics Dashboard:** Provide users with actionable insights into their investments.

---

## **License**
This project is licensed under the MIT License.

---