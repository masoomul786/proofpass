#!/bin/bash
echo ""
echo " ╔══════════════════════════════════════════════════════════╗"
echo " ║          ProofPass — Quantum-Safe DeFi Identity          ║"
echo " ║      CRYSTALS-Dilithium2  ·  Claude AI  ·  Initia        ║"
echo " ╚══════════════════════════════════════════════════════════╝"
echo ""
echo " SELECT MODE:"
echo " ----------------------------------------------------------"
echo " [1]  DEMO MODE   — Instant working demo, score 80-95+"
echo "      Perfect for hackathon judges and presentations."
echo "      Uses realistic simulated on-chain data."
echo ""
echo " [2]  REAL MODE   — Live Initia testnet connection"
echo "      Requires: wallet with testnet txs + ANTHROPIC_API_KEY"
echo "      Real blockchain data, real AI scoring."
echo " ----------------------------------------------------------"
echo ""
read -p " Enter choice [1 or 2, default=1]: " CHOICE
CHOICE=${CHOICE:-1}

if [ "$CHOICE" = "2" ]; then
  echo ""
  echo " Starting in REAL MODE (live Initia testnet)..."
  export PROOFPASS_MODE=real
  read -p " Enter Anthropic API key (or press Enter to skip): " APIKEY
  if [ -n "$APIKEY" ]; then
    export ANTHROPIC_API_KEY="$APIKEY"
  fi
else
  echo ""
  echo " Starting in DEMO MODE..."
  export PROOFPASS_MODE=demo
fi

echo ""
echo " Installing dependencies..."
pip install -r requirements.txt -q --break-system-packages 2>/dev/null || pip install -r requirements.txt -q

echo ""
echo " Starting Crypto Service (port 8001)..."
cd crypto_service
uvicorn main:app --port 8001 --host 0.0.0.0 &
CRYPTO_PID=$!
cd ..

sleep 2

echo " Starting AI Service (port 8002) in $PROOFPASS_MODE mode..."
cd ai_service
uvicorn main:app --port 8002 --host 0.0.0.0 &
AI_PID=$!
cd ..

sleep 2

echo ""
echo " ╔══════════════════════════════════════════════════════════╗"
if [ "$PROOFPASS_MODE" = "demo" ]; then
echo " ║  DEMO MODE ACTIVE — Score will show 80-95+              ║"
else
echo " ║  REAL MODE ACTIVE — Live Initia Testnet                 ║"
fi
echo " ║                                                          ║"
echo " ║  Crypto : http://localhost:8001                         ║"
echo " ║  AI     : http://localhost:8002                         ║"
echo " ║  Docs   : http://localhost:8002/docs                    ║"
echo " ║  Debug  : http://localhost:8002/debug/chain/<wallet>    ║"
echo " ╚══════════════════════════════════════════════════════════╝"
echo ""
echo " Opening ProofPass UI..."
if command -v xdg-open &>/dev/null; then
  xdg-open frontend/index.html
elif command -v open &>/dev/null; then
  open frontend/index.html
else
  echo " Open: frontend/index.html in your browser"
fi

echo ""
echo " Press Ctrl+C to stop all services."
wait $CRYPTO_PID $AI_PID
