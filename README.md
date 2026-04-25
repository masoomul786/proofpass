# ProofPass — Quantum-Safe DeFi Identity on Initia

> **Register once. Get AI-scored. Trade without wallet popups — forever.**

---

## What Is ProofPass?

ProofPass is a **decentralized identity passport for DeFi users on the Initia blockchain**.

Every time you use a DeFi app — swap, lend, bridge — your wallet asks you to sign a transaction popup. On mobile, this is painful. Across 10 protocols, it's 10 popups. ProofPass eliminates this.

You register your `.init` username once. Claude AI reads your **real on-chain transaction history** from Initia testnet and issues a **trust score from 0–100**. Score ≥ 75 = a 1-hour AUTO-SIGN session key. No more popups. Just seamless DeFi.

Your credential is secured by **CRYSTALS-Dilithium2** — the NIST-approved post-quantum signature algorithm. Quantum computers cannot forge or steal your ProofPass identity.

---

## How It's Different From Every Other Wallet Project

Most hackathon projects connect a wallet. ProofPass replaces the need to keep confirming it.

| Feature | Normal Wallet | MetaMask Snap | ProofPass |
|---|---|---|---|
| Signs every tx manually | ✅ Always | ✅ Always | ❌ Not needed (session key) |
| Quantum-safe identity | ❌ No | ❌ No | ✅ CRYSTALS-Dilithium2 |
| AI behavioral trust score | ❌ No | ❌ No | ✅ Claude AI + on-chain data |
| Works across all dApps | Partial | Single chain | ✅ Any app that calls /session/gate |
| Auto-sign duration | Never | Never | ✅ 1 hour, renewable |
| On-chain credential registry | ❌ | ❌ | ✅ CosmWasm contract |
| Multi-wallet single identity | ❌ | ❌ | ✅ `.init` username = one identity |

**The key insight:** DeFi's UX problem is not "which wallet" — it's "why do I keep clicking Confirm?" ProofPass answers that with cryptographic proof + AI trust scoring.

---

## Live Demo

### Quick Start (2 minutes)

**Windows:**
```
Double-click start.bat
→ Choose [1] DEMO MODE
→ Browser opens automatically
```

**Mac / Linux:**
```bash
chmod +x start.sh && ./start.sh
# Choose [1] DEMO MODE
```

### Demo Flow for Judges

1. **Register** — enter any username (e.g. `alice`) + paste any `init1...` address
2. **Analyse** — click "Analyse with Claude AI" — watch score animate to 80-95
3. **Session** — click "Sign Transaction" — no popup, auto-signed in 0.3 seconds
4. **Verify** — hit `http://localhost:8002/chain/<wallet>` — see the raw chain data JSON

### DEMO vs REAL Mode

| | DEMO MODE | REAL MODE |
|---|---|---|
| Chain data | Realistic simulation | Live Initia testnet RPC |
| Score | Always 80-95 (HIGH) | Based on actual wallet history |
| AI | ProofPass scoring engine | Claude claude-sonnet-4-20250514 |
| Setup needed | None | Testnet wallet + txs |
| Use case | Presentations, judging | Production testing |

Judges who want to test with real data: choose **[2] REAL MODE**, paste your `init1` testnet address (get funds from faucet.testnet.initia.xyz), click Analyse.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   ProofPass System                   │
│                                                      │
│  Frontend (index.html)                               │
│      │                                               │
│      ├──▶ Crypto Service (port 8001)                 │
│      │       CRYSTALS-Dilithium2 keygen              │
│      │       Credential registry (local + contract)  │
│      │                                               │
│      └──▶ AI Service (port 8002)                     │
│              │                                       │
│              ├──▶ Initia Testnet REST API            │
│              │       5 query strategies              │
│              │       + Initia scan fallback          │
│              │       + balance heuristic             │
│              │                                       │
│              └──▶ Claude claude-sonnet-4-20250514    │
│                      Trust scoring (0-100)           │
│                      Auto-sign gate (≥75 = YES)      │
│                                                      │
│  CosmWasm Contract (Initia testnet)                  │
│      Immutable on-chain credential store             │
└─────────────────────────────────────────────────────┘
```

### Why It Works Without Full RPC Integration

ProofPass uses the **Cosmos SDK REST API** that every Initia node exposes — no custom indexer needed. It queries 5 different URL formats (because Initia testnet has quirky event-filter behavior), falls back to the Initia scan API, and uses a balance heuristic for freshly funded wallets where the faucet receive transaction is indexed under `transfer.sender` not `message.sender`.

---

## Technical Stack

| Layer | Technology |
|---|---|
| Blockchain | Initia (Cosmos SDK, CosmWasm) |
| Crypto | CRYSTALS-Dilithium2 (NIST PQC standard) |
| AI Trust Engine | Claude claude-sonnet-4-20250514 (Anthropic) |
| AI Fallback | LM Studio (any local model) |
| Backend | Python + FastAPI (2 microservices) |
| Frontend | Vanilla HTML/CSS/JS (zero dependencies) |
| Smart Contract | CosmWasm (Rust) |

---

## API Reference

All endpoints at `http://localhost:8002`

```
GET  /            — Service info + current mode
GET  /health      — Health check (chain connectivity, AI status)
GET  /mode        — Returns {"mode": "demo"|"real"}
POST /analyse     — Main trust scoring endpoint
POST /session/gate — Auto-sign gate (returns session key if HIGH trust)
GET  /chain/{wallet}       — Raw on-chain data for any wallet
GET  /debug/chain/{wallet} — Diagnostic: shows all query attempts
```

**POST /analyse** body:
```json
{
  "username": "alice",
  "action": "defi_swap",
  "context": "Swapping 10 USDC for INIT on Initia DEX"
}
```

**Response:**
```json
{
  "trust_score": 87,
  "trust_level": "HIGH",
  "auto_sign_enabled": true,
  "recommendation": "APPROVE",
  "reasoning": "Wallet shows 34 on-chain txs over 95 days...",
  "on_chain_tx_count": 34,
  "wallet_age_days": 95,
  "chain_data_source": "initia_testnet_live",
  "ai_powered": true,
  "analysis_method": "claude_sonnet_with_chain_data"
}
```

---

## What Makes the Score

Claude AI reads these signals from the live Initia testnet:

| Signal | Weight | Logic |
|---|---|---|
| Transaction count | High | 20+ txs → strong behavioral history |
| Wallet age | High | 30+ days → established user |
| DeFi interactions | Medium | Smart contract calls = sophisticated user |
| Distinct contracts | Medium | Multi-protocol usage = real DeFi participant |
| INIT volume | Low | Economic stake in the ecosystem |
| Quantum-safe credential | Medium | CRYSTALS-Dilithium2 verified |
| Credential status | Critical | Revoked = instant REJECT |

Score ≥ 75 → **HIGH TRUST** → AUTO-SIGN session key issued (1 hour)
Score 45–74 → **MEDIUM** → Manual confirm required
Score < 45 → **LOW** → Rejected

---

## Future Vision (Why This Is Bigger Than a Hackathon)

### Year 1 — Multi-Chain Identity
ProofPass credentials become portable across Cosmos chains. Your `alice.init` trust score works on Osmosis, Celestia, any IBC-connected chain. One identity, all of DeFi.

### Year 2 — Institutional Grade
Banks and fintech companies use ProofPass as a DeFi KYC layer. Instead of submitting passport scans to every exchange, users share their on-chain trust credential. Privacy-preserving (zero-knowledge proofs). Quantum-safe.

### Year 3 — The Trust Standard
ProofPass becomes the behavioral credit score of Web3. Just as TradFi has FICO scores, DeFi has ProofPass scores. Protocols offer better rates to HIGH trust users. Undercollateralized lending becomes possible because the borrower's on-chain history proves creditworthiness.

### Cross-Chain Use Cases
- **DeFi**: Auto-sign all swaps under $500 for HIGH trust users
- **Gaming**: One-click in-game asset transfers, no popups
- **DAOs**: Weighted voting based on on-chain participation score
- **Lending**: Undercollateralized loans for proven participants
- **Bridges**: Skip confirmation steps for trusted wallets
- **CEX onboarding**: Replace KYC paperwork with on-chain credential

### Why Quantum-Safe Matters Now
The "harvest now, decrypt later" attack is real. Adversaries are recording encrypted blockchain transactions today to decrypt once quantum computers become viable (est. 2030–2035). CRYSTALS-Dilithium2 credentials issued today are safe against that future threat. Every other wallet project at this hackathon is using ECDSA — which quantum computers will break. ProofPass is the only identity system here that is future-proof.

---

## Team

Built solo for this hackathon. All code written from scratch during the event.

---

## Running in Production / Real Mode

1. Get testnet funds: `https://faucet.testnet.initia.xyz`
2. Do at least 1 transaction on Initia testnet
3. Get a free Anthropic API key: `https://console.anthropic.com`
4. Run `start.bat` or `start.sh` → choose **[2] REAL MODE**
5. Enter your API key when prompted
6. Register your wallet → Analyse → watch the real score

For contract deployment (on-chain credential registry):
```bash
bash scripts/deploy_testnet.sh
```
Then paste the contract address in `ai_service/.env` as `PROOFPASS_CONTRACT_ADDR`.

---

## Files

```
ProofPass_WINNER/
├── start.bat                  ← Windows launcher (DEMO/REAL mode selector)
├── start.sh                   ← Mac/Linux launcher
├── requirements.txt
├── frontend/
│   └── index.html             ← Complete UI (zero dependencies)
├── ai_service/
│   ├── main.py                ← Trust scoring engine + chain data fetcher
│   └── .env.example
├── crypto_service/
│   └── main.py                ← CRYSTALS-Dilithium2 credential issuer
├── contract/
│   └── src/lib.rs             ← CosmWasm credential registry
└── scripts/
    └── deploy_testnet.sh      ← One-command contract deployment
```

---

*ProofPass — Because in the quantum era, your identity needs to be unbreakable.*
# proofpass
