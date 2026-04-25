#!/bin/bash
# ================================================================
# ProofPass — One-Click Testnet Deploy Script
# Deploys the CosmWasm contract to Initia testnet automatically
# ================================================================

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
BOLD='\033[1m'

echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║     ProofPass — Initia Testnet Deploy                ║"
echo "║     Quantum-Safe Identity Registry v1.0              ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── STEP 1: Prerequisites Check ──────────────────────────────────
echo -e "${YELLOW}[1/7] Checking prerequisites...${NC}"

if ! command -v initiad &> /dev/null; then
    echo -e "${RED}✗ initiad not found. Installing...${NC}"
    echo ""
    echo "Run this first:"
    echo "  git clone https://github.com/initia-labs/initia.git"
    echo "  cd initia && git checkout v0.6.0"
    echo "  make install"
    echo ""
    echo "Or use the browser deploy option: see BROWSER_DEPLOY.md"
    exit 1
fi

if ! command -v docker &> /dev/null && ! command -v cargo &> /dev/null; then
    echo -e "${RED}✗ Need either Docker or Rust/cargo to compile the contract${NC}"
    echo "  Install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites OK${NC}"

# ── STEP 2: Config ────────────────────────────────────────────────
echo -e "${YELLOW}[2/7] Configuration...${NC}"

CHAIN_ID="initiation-2"
NODE="https://rpc.testnet.initia.xyz:443"
KEYNAME="proofpass-deployer"
GAS_PRICES="0.015uinit"

# Check for existing key
if initiad keys show $KEYNAME &> /dev/null 2>&1; then
    echo -e "${GREEN}✓ Key '$KEYNAME' already exists${NC}"
    DEPLOYER_ADDR=$(initiad keys show $KEYNAME -a)
else
    echo -e "${YELLOW}Creating new deployer key...${NC}"
    initiad keys add $KEYNAME --output json > /tmp/proofpass_key.json 2>&1 || true
    DEPLOYER_ADDR=$(initiad keys show $KEYNAME -a 2>/dev/null || echo "")
    if [ -z "$DEPLOYER_ADDR" ]; then
        echo -e "${RED}Key creation failed. Try: initiad keys add proofpass-deployer${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ New key created: $DEPLOYER_ADDR${NC}"
fi

echo ""
echo -e "${BOLD}Deployer address: ${CYAN}$DEPLOYER_ADDR${NC}"
echo ""

# ── STEP 3: Check Balance ─────────────────────────────────────────
echo -e "${YELLOW}[3/7] Checking testnet balance...${NC}"

BALANCE_JSON=$(curl -s "https://rest.testnet.initia.xyz/cosmos/bank/v1beta1/balances/$DEPLOYER_ADDR" 2>/dev/null || echo "{}")
UINIT_BALANCE=$(echo $BALANCE_JSON | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    balances = data.get('balances', [])
    for b in balances:
        if 'uinit' in b.get('denom',''):
            print(int(b['amount']))
            sys.exit(0)
    print(0)
except:
    print(0)
" 2>/dev/null || echo "0")

echo -e "Balance: ${CYAN}$(echo "scale=6; $UINIT_BALANCE / 1000000" | bc 2>/dev/null || echo $UINIT_BALANCE) INIT${NC}"

if [ "$UINIT_BALANCE" -lt "5000000" ] 2>/dev/null; then
    echo ""
    echo -e "${YELLOW}⚠ Low testnet balance. Get free testnet INIT from the faucet:${NC}"
    echo -e "${CYAN}  https://faucet.testnet.initia.xyz${NC}"
    echo ""
    echo -e "Your address: ${BOLD}$DEPLOYER_ADDR${NC}"
    echo ""
    read -p "Press Enter after getting testnet tokens to continue..."
fi

# ── STEP 4: Compile Contract ──────────────────────────────────────
echo -e "${YELLOW}[4/7] Compiling CosmWasm contract...${NC}"

CONTRACT_DIR="$(dirname "$0")/../contract"
ARTIFACTS_DIR="$(dirname "$0")/../artifacts"
mkdir -p $ARTIFACTS_DIR

if command -v docker &> /dev/null; then
    echo "Using Docker optimizer for reproducible build..."
    cd $CONTRACT_DIR
    docker run --rm -v "$(pwd)":/code \
        --mount type=volume,source="proofpass_cache",target=/target \
        --mount type=volume,source=registry_cache,target=/usr/local/cargo/registry \
        cosmwasm/optimizer:0.16.0 2>&1 | tail -5
    cp artifacts/proofpass.wasm $ARTIFACTS_DIR/proofpass.wasm 2>/dev/null || \
    cp artifacts/*.wasm $ARTIFACTS_DIR/proofpass.wasm 2>/dev/null || true
    cd - > /dev/null
else
    echo "Using cargo build (no Docker)..."
    cd $CONTRACT_DIR
    RUSTFLAGS='-C link-arg=-s' cargo build --release --target wasm32-unknown-unknown 2>&1 | tail -3
    cp target/wasm32-unknown-unknown/release/proofpass.wasm $ARTIFACTS_DIR/proofpass.wasm
    cd - > /dev/null
fi

WASM_FILE="$ARTIFACTS_DIR/proofpass.wasm"
if [ ! -f "$WASM_FILE" ]; then
    echo -e "${RED}✗ Compilation failed — wasm file not found${NC}"
    echo "See BROWSER_DEPLOY.md for manual deploy option"
    exit 1
fi

WASM_SIZE=$(du -sh $WASM_FILE | cut -f1)
echo -e "${GREEN}✓ Contract compiled: $WASM_FILE ($WASM_SIZE)${NC}"

# ── STEP 5: Store Contract on Testnet ────────────────────────────
echo -e "${YELLOW}[5/7] Storing contract on Initia testnet...${NC}"

STORE_TX=$(initiad tx wasm store $WASM_FILE \
    --from $KEYNAME \
    --chain-id $CHAIN_ID \
    --node $NODE \
    --gas auto \
    --gas-adjustment 1.5 \
    --gas-prices $GAS_PRICES \
    --broadcast-mode sync \
    --yes \
    --output json 2>&1)

TXHASH=$(echo $STORE_TX | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('txhash',''))" 2>/dev/null || echo "")
if [ -z "$TXHASH" ]; then
    echo -e "${RED}✗ Store transaction failed${NC}"
    echo "$STORE_TX" | head -20
    exit 1
fi

echo -e "${GREEN}✓ Store tx: ${CYAN}$TXHASH${NC}"
echo "Waiting for block confirmation..."
sleep 8

# Get Code ID
CODE_ID=$(initiad query tx $TXHASH \
    --node $NODE \
    --output json 2>/dev/null | python3 -c "
import json,sys
d=json.load(sys.stdin)
for ev in d.get('events',[]):
    if ev.get('type')=='store_code':
        for attr in ev.get('attributes',[]):
            if attr.get('key')=='code_id':
                print(attr['value'])
                sys.exit(0)
" 2>/dev/null || echo "")

if [ -z "$CODE_ID" ]; then
    echo -e "${RED}✗ Could not get code ID from tx${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Code ID: ${CYAN}$CODE_ID${NC}"

# ── STEP 6: Instantiate Contract ─────────────────────────────────
echo -e "${YELLOW}[6/7] Instantiating contract...${NC}"

INIT_MSG="{\"admin\": \"$DEPLOYER_ADDR\"}"
INST_TX=$(initiad tx wasm instantiate $CODE_ID "$INIT_MSG" \
    --from $KEYNAME \
    --label "ProofPass v1.0 - Quantum-Safe Identity Registry" \
    --chain-id $CHAIN_ID \
    --node $NODE \
    --gas auto \
    --gas-adjustment 1.5 \
    --gas-prices $GAS_PRICES \
    --broadcast-mode sync \
    --yes \
    --output json 2>&1)

INST_TXHASH=$(echo $INST_TX | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('txhash',''))" 2>/dev/null || echo "")
echo -e "${GREEN}✓ Instantiate tx: ${CYAN}$INST_TXHASH${NC}"
echo "Waiting for block confirmation..."
sleep 8

CONTRACT_ADDR=$(initiad query tx $INST_TXHASH \
    --node $NODE \
    --output json 2>/dev/null | python3 -c "
import json,sys
d=json.load(sys.stdin)
for ev in d.get('events',[]):
    if ev.get('type')=='instantiate':
        for attr in ev.get('attributes',[]):
            if attr.get('key')=='_contract_address':
                print(attr['value'])
                sys.exit(0)
" 2>/dev/null || echo "")

if [ -z "$CONTRACT_ADDR" ]; then
    echo -e "${YELLOW}⚠ Could not parse contract address automatically${NC}"
    echo "Check: https://scan.testnet.initia.xyz/initiation-2/txs/$INST_TXHASH"
else
    echo -e "${GREEN}✓ Contract deployed: ${CYAN}$CONTRACT_ADDR${NC}"
fi

# ── STEP 7: Save Config ───────────────────────────────────────────
echo -e "${YELLOW}[7/7] Saving deployment config...${NC}"

cat > "$(dirname "$0")/../.env.deployed" << EOF
# ProofPass Deployment Config — $(date)
PROOFPASS_CONTRACT_ADDR=$CONTRACT_ADDR
PROOFPASS_CODE_ID=$CODE_ID
PROOFPASS_CHAIN_ID=initiation-2
PROOFPASS_DEPLOYER=$DEPLOYER_ADDR
PROOFPASS_STORE_TX=$TXHASH
PROOFPASS_INST_TX=$INST_TXHASH
INITIA_REST=https://rest.testnet.initia.xyz
EOF

echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════╗"
echo "║        ✅ DEPLOYMENT SUCCESSFUL!                     ║"
echo "╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}Contract Address:${NC} ${CYAN}$CONTRACT_ADDR${NC}"
echo -e "${BOLD}Code ID:${NC}          ${CYAN}$CODE_ID${NC}"
echo -e "${BOLD}Chain:${NC}            ${CYAN}initiation-2 (Initia Testnet)${NC}"
echo ""
echo -e "${BOLD}Explorer:${NC}"
echo -e "  ${CYAN}https://scan.testnet.initia.xyz/initiation-2/txs/$INST_TXHASH${NC}"
echo -e "  ${CYAN}https://scan.testnet.initia.xyz/initiation-2/contracts/$CONTRACT_ADDR${NC}"
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo "  1. Add to ai_service/.env:"
echo -e "     ${CYAN}PROOFPASS_CONTRACT_ADDR=$CONTRACT_ADDR${NC}"
echo "  2. Restart the AI service: uvicorn main:app --port 8002 --reload"
echo "  3. The AI will now read credentials directly from the on-chain contract!"
echo ""
