@echo off
setlocal enabledelayedexpansion
title ProofPass — Quantum-Safe DeFi Identity

echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║          ProofPass — Quantum-Safe DeFi Identity          ║
echo  ║      CRYSTALS-Dilithium2  ·  Claude AI  ·  Initia        ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.
echo  SELECT MODE:
echo  ----------------------------------------------------------
echo  [1]  DEMO MODE   — Instant working demo, score 80-95+
echo       Perfect for hackathon judges and presentations.
echo       Uses realistic simulated on-chain data.
echo.
echo  [2]  REAL MODE   — Live Initia testnet connection
echo       Requires: wallet with testnet txs + ANTHROPIC_API_KEY
echo       Real blockchain data, real AI scoring.
echo  ----------------------------------------------------------
echo.

set /p CHOICE=  Enter choice [1 or 2]: 

if "%CHOICE%"=="2" goto REAL_MODE
goto DEMO_MODE

:DEMO_MODE
echo.
echo  Starting in DEMO MODE...
set PROOFPASS_MODE=demo
goto START_SERVICES

:REAL_MODE
echo.
echo  Starting in REAL MODE (live Initia testnet)...
set PROOFPASS_MODE=real
echo.
set /p APIKEY=  Enter Anthropic API key (or press Enter to skip): 
if not "%APIKEY%"=="" set ANTHROPIC_API_KEY=%APIKEY%
echo.

:START_SERVICES
echo  Installing dependencies...
pip install -r requirements.txt -q 2>nul

echo.
echo  Starting Crypto Service (port 8001)...
start "ProofPass Crypto Service" cmd /k "cd crypto_service && uvicorn main:app --port 8001 --host 0.0.0.0"

timeout /t 3 >nul

echo  Starting AI Service (port 8002) in %PROOFPASS_MODE% mode...
start "ProofPass AI Service" cmd /k "cd ai_service && set PROOFPASS_MODE=%PROOFPASS_MODE%&& set ANTHROPIC_API_KEY=%ANTHROPIC_API_KEY%&& uvicorn main:app --port 8002 --host 0.0.0.0"

timeout /t 3 >nul

echo.
echo  Services running!
echo    Crypto : http://localhost:8001
echo    AI     : http://localhost:8002
echo    Docs   : http://localhost:8002/docs
echo.
echo  Opening ProofPass UI...
timeout /t 2 >nul
start "" "frontend\index.html"

echo.
echo  ProofPass is running. Close the terminal windows to stop.
pause
