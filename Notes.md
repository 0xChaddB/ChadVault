### **Quick Notes: Multi-Token, Multi-Protocol Yield System**

---

### **How the System Works**
1. **Vault (Central Manager):**
   - Users deposit tokens (e.g., DAI, USDC) into the Vault.
   - The Vault mints **share tokens** representing the user's proportional ownership of the total assets in the Vault.
   - The Vault:
     - Retains custody of the assets.
     - Allocates funds to **modular Strategy contracts** for yield generation.

2. **Strategy Contracts (Modular Yield Generators):**
   - Each Strategy interacts with a specific protocol (e.g., Aave, Compound, or a custom strategy).
   - The Vault sends funds to these Strategies for yield generation.
   - The Strategy manages the assets and reports their status back to the Vault.
   - The Vault can retrieve funds from the Strategies when users withdraw or during rebalancing.

---

### **Key Features**
1. **Multi-Token Support:**
   - The Vault supports multiple ERC-20 tokens.
   - Each token has its own accounting (e.g., total assets, shares).

2. **Multi-Protocol Strategies:**
   - Strategies handle interactions with yield protocols like Aave, Compound, or custom yield strategies.
   - Modular design allows adding or removing Strategies without changing the Vault logic.

3. **Share Accounting:**
   - Users receive **share tokens** proportional to their deposit.
   - Share-to-asset ratio adjusts as yield is generated.

4. **Rebalancing:**
   - The Vault can rebalance funds across multiple Strategies based on their performance.
   - Example: Move funds from Aave to Compound if Compound offers better yield.

5. **Emergency Withdrawals:**
   - The Vault can withdraw all funds from a Strategy in case of a protocol failure.

---

### **Key Workflow**
#### **1. User Deposit**
- User deposits a supported ERC-20 token (e.g., DAI) into the Vault.
- Vault mints share tokens for the user.
- Vault may keep some funds for withdrawals or send excess funds to a Strategy.

#### **2. Yield Generation**
- Vault allocates assets to Strategies.
- Strategies interact with protocols (e.g., deposit funds into Aave).
- Yield is generated and added to the Strategy’s balance.

#### **3. User Withdrawal**
- User redeems their shares for the underlying assets.
- Vault retrieves assets from the Strategy if needed and sends them to the user.

#### **4. Strategy Rebalancing**
- Vault reallocates funds between Strategies to optimize yield.
- Example: Move 50% of assets from AaveStrategy to CompoundStrategy.

---

### **Key Things to Know**
1. **Vault is the Custodian:**
   - The Vault retains ownership of all assets and only delegates operational control to Strategies.
   - Strategies don’t hold assets—they simply manage them on behalf of the Vault.

2. **Modular Strategies:**
   - Each Strategy is designed for a specific protocol.
   - Example: `AaveStrategy`, `CompoundStrategy`.

3. **Share Tokens:**
   - Users interact only with the Vault.
   - Share tokens are ERC-20 tokens representing a user’s proportional ownership in the Vault.

4. **Multi-Token Accounting:**
   - The Vault tracks balances for each supported token separately.
   - Example: 1,000 DAI in Aave, 500 USDC in Compound.

5. **Flexibility:**
   - Strategies can be upgraded or replaced without affecting the Vault.
   - New protocols can be added by deploying new Strategy contracts.

6. **Security:**
   - Funds are always owned by the Vault.
   - Strategies have limited permissions, reducing the risk of loss.

---