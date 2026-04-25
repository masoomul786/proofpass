# ProofPass — Configuration Guide
## All APIs, Keys & External Services

## ─────────────────────────────────────────────────────────────
## 1. LM STUDIO (Qwen AI) — REQUIRED for full AI features
## ─────────────────────────────────────────────────────────────

Step 1: Download LM Studio from https://lmstudio.ai/
Step 2: Open LM Studio → Search tab → search "Qwen"
Step 3: Download any Qwen model (recommended: Qwen2.5-7B-Instruct-GGUF Q4)
Step 4: Go to "Local Server" tab (≡ icon left sidebar)
Step 5: Select your Qwen model in the dropdown
Step 6: Click "Start Server"
Step 7: LM Studio runs on http://localhost:1234 by default

⚠️  ProofPass works WITHOUT LM Studio — it automatically falls back
    to a rule-based trust engine. You won't lose any features,
    just the "ai_powered: true" flag in responses.

## ─────────────────────────────────────────────────────────────
## 2. ENVIRONMENT VARIABLES (optional overrides)
## ─────────────────────────────────────────────────────────────

Create  ai_service/.env  with these values if you need to change defaults:

    LM_STUDIO_URL=http://localhost:1234/v1/chat/completions
    CRYPTO_SVC_URL=http://localhost:8001

## ─────────────────────────────────────────────────────────────
## 3. INITIA CHAIN CONFIG (for real on-chain deployment)
## ─────────────────────────────────────────────────────────────

This hackathon demo simulates the Initia rollup via the crypto service API.
For a real Initia deployment:

  Chain ID    : proofpass-1
  RPC         : https://rpc.initia.xyz  (mainnet)
               https://rpc.testnet.initia.xyz  (testnet)
  REST        : https://lcd.initia.xyz
  Chain Docs  : https://docs.initia.xyz

InterwovenKit config (used in frontend):
  Network     : "interwoven-1" (Initia mainnet)
  Testnet     : "stone-1"
  Wallet      : Initia Wallet browser extension

## ─────────────────────────────────────────────────────────────
## 4. NO API KEYS REQUIRED
## ─────────────────────────────────────────────────────────────

ProofPass uses ONLY local/free services:
  ✅  dilithium-py     — local Python library, no API key
  ✅  LM Studio/Qwen  — runs locally on your machine, free
  ✅  FastAPI          — local server, no key needed
  ✅  Initia testnet   — free, no key needed
  ✅  InterwovenKit    — open source, no key needed

## ─────────────────────────────────────────────────────────────
## 5. PORTS USED
## ─────────────────────────────────────────────────────────────

  8001  — ProofPass Crypto Service (Dilithium2)
  8002  — ProofPass AI Service (Qwen)
  1234  — LM Studio local server

Make sure these ports are free before running start.bat / start.sh.

## ─────────────────────────────────────────────────────────────
## 6. TROUBLESHOOTING
## ─────────────────────────────────────────────────────────────

Problem: "Services Offline" in UI header
Fix    : Make sure start.bat ran successfully. Check windows titled
         "ProofPass - Crypto Service" and "ProofPass - AI Service"
         are open and show "Application startup complete"

Problem: "AI service unreachable" in trust analysis
Fix    : Start LM Studio → Load Qwen model → Start Server
         OR just proceed — the fallback engine works fine for demo

Problem: Port already in use
Fix    : taskkill /f /im python.exe (Windows)
         pkill -f uvicorn (Linux/Mac)
         Then restart start.bat

Problem: Module not found (dilithium_py)
Fix    : pip install dilithium-py --break-system-packages
         (Linux) or pip install dilithium-py (Windows)
