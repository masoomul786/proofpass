Got it — clean **README.md only**, no explanation.

---

```md
# 🚀 ProofPass — No More Wallet Popups in DeFi

> AI + Quantum-Safe Identity that auto-signs transactions based on trust score  
> Register once. Get AI-scored. Trade without wallet popups — forever.

---

## 🎥 Demo

👉 Demo Video: [Add your link here]  
👉 Run Locally: `start.bat` or `start.sh` (2 min setup)

---

## ⚡ Why ProofPass?

- ❌ Stop clicking "Confirm" on every transaction  
- 🤖 AI decides if your transaction is safe  
- 🔐 Quantum-safe identity (future-proof)  
- ⚡ Seamless DeFi UX with auto-sign  

---

## 🧠 What Is ProofPass?

ProofPass is a **decentralized identity passport for DeFi users on the Initia blockchain**.

Every time you use a DeFi app — swap, lend, bridge — your wallet asks you to sign a transaction popup. On mobile, this is painful. Across 10 protocols, it's 10 popups. ProofPass eliminates this.

You register your `.init` username once. Claude AI reads your **real on-chain transaction history** from Initia testnet and issues a **trust score from 0–100**. Score ≥ 75 = a 1-hour AUTO-SIGN session key. No more popups. Just seamless DeFi.

Your credential is secured by **CRYSTALS-Dilithium2** — the NIST-approved post-quantum signature algorithm.

---

## 🏆 Hackathon Fit

- Uses `.init` identity  
- Implements auto-sign session UX  
- Built on Initia testnet  
- Working end-to-end demo  
- Focus on real product UX  

---

## 🔥 How It's Different

| Feature | Normal Wallet | MetaMask Snap | ProofPass |
|---|---|---|---|
| Signs every tx manually | ✅ | ✅ | ❌ |
| Quantum-safe identity | ❌ | ❌ | ✅ |
| AI trust score | ❌ | ❌ | ✅ |
| Auto-sign | ❌ | ❌ | ✅ |
| Cross-dApp usage | Partial | Single chain | ✅ |

---

## 🚀 Live Demo

### Quick Start

**Windows**
```

Double-click start.bat
→ Choose [1] DEMO MODE

````

**Mac / Linux**
```bash
chmod +x start.sh && ./start.sh
````

---

### Demo Flow

1. Register username + wallet
2. Click "Analyse with AI"
3. Get trust score
4. Click "Sign Transaction" → no popup

---

## 🧱 Architecture

```
Frontend (index.html)
   │
   ├── Crypto Service (Dilithium2)
   │
   └── AI Service
         ├── Initia chain data
         └── Claude AI

Smart Contract (CosmWasm)
```

---

## ⚙️ Tech Stack

* Initia (Cosmos SDK, CosmWasm)
* CRYSTALS-Dilithium2
* Claude AI
* Python + FastAPI
* HTML/CSS/JS

---

## 📡 API

Base: `http://localhost:8002`

* `/analyse`
* `/session/gate`
* `/chain/{wallet}`
* `/health`

---

## 📊 Trust Logic

* 75+ → Auto-sign
* 45–74 → Manual
* <45 → Reject

---

## 🔮 Future

* Cross-chain identity
* DeFi credit score
* DAO identity
* Web3 KYC replacement

---

## 🔐 Why Quantum-Safe?

ProofPass uses **CRYSTALS-Dilithium2**, making identity secure against future quantum attacks.

---

## 📂 Structure

```
ProofPass/
├── frontend/
├── ai_service/
├── crypto_service/
├── contract/
├── scripts/
```

---

## 👨‍💻 Author

Masoomul Haque Choudhury

---

## 🏁 Tagline

ProofPass — Identity layer for trust in Web3

```
```
