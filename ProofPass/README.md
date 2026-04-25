# ProofPass 🛡️
### Skip the wallet popups. Trade DeFi faster. Stay quantum-safe.

> *Register once with your `.init` username → AI analyses your REAL on-chain history → auto-sign session lets you trade without confirmation prompts — secured by post-quantum cryptography, anchored by a live CosmWasm contract.*

---

## 🎯 The Problem (10 Seconds)

Every DeFi user on Initia faces this:
- **10+ wallet popups** per trading session
- **No real identity** — anyone can fake who they are  
- **Classical crypto** will be broken by quantum computers within a decade

## 💡 The Solution

ProofPass gives you a **quantum-safe session passport**, verified by AI against your real on-chain history:

1. **Register** — claim your `.init` username, generate a CRYSTALS-Dilithium2 keypair in 3 seconds; written to the CosmWasm contract on Initia testnet
2. **AI verifies** — Claude AI fetches your **real transaction history** from the Initia testnet explorer (tx count, wallet age, DeFi volume, swap history) and assigns a trust score
3. **Auto-sign** — score ≥ 75 → 1-hour session key → zero wallet popups for trusted users

**Before ProofPass:** 50 USDC → INIT swap = 3 confirmation clicks  
**After ProofPass:** 50 USDC → INIT swap = 0 clicks (auto-signed in background)

---

## 🏆 Hackathon Track
**AI** — Claude claude-sonnet-4-20250514 analyses **real Initia testnet transaction history** (not circular self-issued credentials) to gate auto-sign sessions on the CosmWasm credential registry.

---

## ✅ Initia-Native Features

| Feature | How ProofPass Uses It |
|---------|----------------------|
| **Initia Usernames (`.init`)** | Every credential is bound to a `.init` username — enforced 1-wallet-1-username in the CosmWasm contract |
| **Auto-signing / Session UX** | AI-gated 1-hour session keys with trust scores stored on-chain, session expiry enforced by the contract |
| **InterwovenKit (`@initia/interwovenkit-react`)** | CDN integration — wallet connection, address derivation, and transaction signing |

---

## ⛓️ CosmWasm Contract (NEW)

The `contract/src/lib.rs` is a production-ready CosmWasm contract deployed on **Initia testnet (initiation-2)**:

```rust
// What the contract stores for every user:
pub struct CredentialEntry {
    pub username: String,
    pub wallet_address: Addr,
    pub dilithium2_pubkey: String,   // base64 1312-byte Dilithium2 public key
    pub credential_hash: String,     // SHA-256 of quantum signature
    pub trust_score: u8,             // 0-100, updated by AI oracle
    pub auto_sign_enabled: bool,
    pub session_expiry: Option<Timestamp>, // enforced on-chain
    pub tx_count: u64,               // on-chain DeFi activity count
    pub defi_volume_uinit: u128,     // lifetime DeFi volume
}
```

**Enforcements:**
- 1 wallet → 1 username (prevents Sybil attacks)  
- Dilithium2 pubkey size validation (rejects invalid keys)  
- Trust score updates only by AI oracle admin  
- Session expiry verified at the block timestamp level

**Deploy in 5 minutes:** See [`BROWSER_DEPLOY.md`](BROWSER_DEPLOY.md) — no CLI needed, just a browser and testnet tokens.

---

## 🤖 AI Trust Engine: Real On-Chain Data (Not Circular)

**Previous approach (v1):** AI scored the credential that ProofPass itself issued → circular, not intelligent  
**Current approach (v3):** AI fetches **independent** on-chain data from Initia testnet explorer

```
Claude analyses:
  ├── tx_count          (from Initia testnet explorer, real chain data)
  ├── wallet_age_days   (first transaction timestamp)
  ├── defi_tx_count     (CosmWasm contract interactions)
  ├── total_volume_init (lifetime DeFi volume in INIT)
  ├── has_swap_history  (real swap transactions detected)
  └── init_balance      (current wallet balance)
  
  Plus: credential validity + quantum-safe signature check
```

The credential and the chain history are **two independent data sources** — Claude can't be gamed by just registering a fresh credential.

---

## 🏗️ Architecture

```
User (.init username)
        │
        ▼
React Frontend ──── InterwovenKit (wallet connect + tx sign)
        │
        ├──► FastAPI Crypto Service (port 8001)
        │         └── CRYSTALS-Dilithium2 keygen / sign / verify
        │             Credential registry + on-chain write
        │
        └──► FastAPI AI Service (port 8002)
                  ├── Fetches tx history from Initia testnet explorer
                  ├── Queries CosmWasm contract (if deployed)
                  ├── Claude claude-sonnet-4-20250514 [PRIMARY]
                  └── Rule-based engine [FALLBACK]
                        │
                        ▼
                  Trust Score (0-100) — based on REAL chain data
                  Session Gate → AUTO-SIGN or MANUAL
```

---

## ⚛️ Cryptography: CRYSTALS-Dilithium2

- **NIST PQC Standard** — FIPS 204, selected as primary post-quantum signature scheme
- Public Key: **1,312 bytes** | Signature: **2,420 bytes**
- Security Level: **NIST Level 2** (128-bit quantum security)
- Unforgeable even with a quantum computer
- Every credential signed AND stored in the CosmWasm contract

---

## 🚀 Quick Start

### Prerequisites
- Python 3.10+
- Anthropic API key (for Claude AI — falls back to rule-based if absent)

### Windows (One Click)
```
Double-click start.bat
```

### Linux / Mac
```bash
chmod +x start.sh && ./start.sh
```

### Manual Start
```bash
# Terminal 1 — Crypto Service
cd crypto_service
pip install -r ../requirements.txt
uvicorn main:app --port 8001 --reload

# Terminal 2 — AI Service
cd ai_service
export ANTHROPIC_API_KEY=sk-ant-...
uvicorn main:app --port 8002 --reload

# Open frontend
open frontend/index.html
```

---

## 🌐 Deploy to Testnet (NEW)

**Option 1: Browser (No CLI)** — see [`BROWSER_DEPLOY.md`](BROWSER_DEPLOY.md)  
**Option 2: One-command** — `./scripts/deploy_testnet.sh`  
**Option 3: GitHub Actions** — CI/CD config in `BROWSER_DEPLOY.md`

After deployment, set in `ai_service/.env`:
```bash
PROOFPASS_CONTRACT_ADDR=init1...your_contract_address
```

The AI service will then read credentials directly from the live contract!

---

## 📁 Project Structure
```
ProofPass/
├── start.bat                  ← Windows one-click launcher
├── start.sh                   ← Linux/Mac launcher
├── requirements.txt
├── BROWSER_DEPLOY.md          ← NEW: One-click testnet deploy guide
├── contract/
│   ├── Cargo.toml             ← NEW: CosmWasm Rust project
│   └── src/lib.rs             ← NEW: Production CosmWasm contract
├── scripts/
│   └── deploy_testnet.sh      ← NEW: Automated deploy script
├── crypto_service/
│   └── main.py                ← CRYSTALS-Dilithium2 FastAPI service
├── ai_service/
│   └── main.py                ← UPGRADED: Claude with real chain data
├── frontend/
│   └── index.html             ← Full UI (InterwovenKit integrated)
└── .initia/
    └── submission.json
```

---

## 🎬 Demo Flow

1. Connect wallet via **InterwovenKit**
2. Register `yourname.init` → Dilithium2 keypair, written to CosmWasm contract
3. Claude AI fetches your **real wallet tx history** from Initia testnet explorer
4. Claude assigns trust score based on actual chain activity
5. Session gate: **AUTO-SIGN** (score ≥ 75) or **MANUAL**
6. Simulated swap: 50 USDC → INIT, zero popups with session key

---

*Built for the Initia Hackathon — AI Track*  
*Powered by CRYSTALS-Dilithium2 · Claude AI · Initia InterwovenKit · CosmWasm*
