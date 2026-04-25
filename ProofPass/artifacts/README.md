# artifacts/

This directory contains the compiled CosmWasm contract WASM file.

## How to get proofpass.wasm

**Option 1: Docker (reproducible build)**
```bash
cd ../contract
docker run --rm -v "$(pwd)":/code \
  --mount type=volume,source="proofpass_cache",target=/target \
  --mount type=volume,source=registry_cache,target=/usr/local/cargo/registry \
  cosmwasm/optimizer:0.16.0
cp artifacts/proofpass.wasm ../artifacts/
```

**Option 2: Cargo (faster, no Docker)**
```bash
cd ../contract
rustup target add wasm32-unknown-unknown
RUSTFLAGS='-C link-arg=-s' cargo build --release --target wasm32-unknown-unknown
cp target/wasm32-unknown-unknown/release/proofpass.wasm ../artifacts/
```

**Option 3: GitHub Actions**
See the CI/CD config in BROWSER_DEPLOY.md — the workflow compiles and uploads automatically.

## After compiling

Upload `proofpass.wasm` via:
- **Celatone**: https://celatone.osmosis.zone (browser, no CLI)
- **initiad CLI**: `./scripts/deploy_testnet.sh`

See `../BROWSER_DEPLOY.md` for complete instructions.
