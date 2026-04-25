# 🌐 ProofPass — Browser One-Click Deploy Guide
### Deploy the CosmWasm contract to Initia Testnet without installing anything

---

## Option A: Deploy via Initia's Web Interface (Easiest — No CLI Needed)

### Step 1: Get Testnet Funds
1. Open **https://faucet.testnet.initia.xyz**
2. Connect your wallet (Compass or Keplr with Initia network)
3. Request testnet INIT tokens
4. Wait ~30 seconds for confirmation

### Step 2: Get the Pre-compiled Contract
The pre-compiled `.wasm` file is in `artifacts/proofpass.wasm` in this zip.

*(If you want to compile yourself, see Option B below)*

### Step 3: Upload via Celatone (Initia's CosmWasm Explorer)
1. Open **https://celatone.osmosis.zone** → switch network to **Initia Testnet (initiation-2)**
2. Click **"Deploy Contract"** → **"Upload New Contract"**
3. Upload `artifacts/proofpass.wasm` from this folder
4. Sign the transaction — this stores the code on-chain
5. Copy the **Code ID** that appears (e.g., `1234`)

### Step 4: Instantiate the Contract
1. In Celatone, go to **"Instantiate Contract"**
2. Enter the Code ID from Step 3
3. Paste this instantiation message:
```json
{
  "admin": "YOUR_WALLET_ADDRESS_HERE"
}
```
4. Set label: `ProofPass v1.0 - Quantum-Safe Identity Registry`
5. Click **Instantiate** → sign the transaction
6. Copy the **Contract Address** (starts with `init1...`)

### Step 5: Configure ProofPass to Use the Contract
Edit `ai_service/.env`:
```bash
PROOFPASS_CONTRACT_ADDR=init1...your_contract_address_here
INITIA_REST=https://rest.testnet.initia.xyz
```

Restart the AI service:
```bash
uvicorn main:app --port 8002 --reload
```

**Done!** ProofPass now reads credentials from your live on-chain contract. 🎉

---

## Option B: One-Command Deploy (Requires initiad CLI)

```bash
# 1. Install initiad
git clone https://github.com/initia-labs/initia.git
cd initia && git checkout v0.6.0 && make install

# 2. Run the automated deploy script
chmod +x scripts/deploy_testnet.sh
./scripts/deploy_testnet.sh
```

The script will:
- Create a deployer wallet
- Guide you to the faucet
- Compile the contract
- Upload + instantiate on Initia testnet
- Save the contract address to `.env.deployed`

---

## Option C: GitHub Actions (CI/CD Deploy)

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy ProofPass to Initia Testnet
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Rust
        uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
          target: wasm32-unknown-unknown
          
      - name: Compile Contract
        run: |
          cd contract
          RUSTFLAGS='-C link-arg=-s' cargo build --release --target wasm32-unknown-unknown
          cp target/wasm32-unknown-unknown/release/proofpass.wasm ../artifacts/
          
      - name: Install initiad
        run: |
          wget https://github.com/initia-labs/initia/releases/download/v0.6.0/initiad_linux_amd64.tar.gz
          tar -xzf initiad_linux_amd64.tar.gz
          sudo mv initiad /usr/local/bin/
          
      - name: Deploy to Testnet
        env:
          MNEMONIC: ${{ secrets.DEPLOYER_MNEMONIC }}
        run: |
          echo "$MNEMONIC" | initiad keys add deployer --recover
          initiad tx wasm store artifacts/proofpass.wasm \
            --from deployer \
            --chain-id initiation-2 \
            --node https://rpc.testnet.initia.xyz:443 \
            --gas auto --gas-adjustment 1.5 \
            --gas-prices 0.015uinit \
            --broadcast-mode sync --yes
```

---

## Verify Your Deployment

After deploying, verify everything works:

```bash
# Check contract exists on-chain
curl "https://rest.testnet.initia.xyz/cosmwasm/wasm/v1/contract/YOUR_CONTRACT_ADDR"

# Check AI service reads from contract
curl "http://localhost:8002/health"
# Should show: "contract": "init1...your_address"

# Register a credential on-chain via the API
curl -X POST http://localhost:8001/credential/register \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "wallet_address": "init1..."}'
```

---

## Explorer Links (for judges)

Once deployed, share these links with hackathon judges:

| Link | Purpose |
|------|---------|
| `https://scan.testnet.initia.xyz/initiation-2/contracts/YOUR_ADDR` | Live contract |
| `https://scan.testnet.initia.xyz/initiation-2/txs/YOUR_TX_HASH` | Deploy transaction |
| `https://celatone.osmosis.zone/initiation-2/contracts/YOUR_ADDR` | Contract interaction UI |
| `http://localhost:8002/health` | AI service with contract address |

---

## Pre-compiled WASM

> **For judges who want to verify immediately without compiling:**
> The pre-compiled `artifacts/proofpass.wasm` is included in this repository.
> You can upload it directly to Celatone or use the deploy script.
> SHA-256 checksum is in `artifacts/proofpass.wasm.sha256`.

---

*ProofPass — Quantum-Safe Identity for Initia DeFi*
*Built for the Initia Hackathon — AI Track*
