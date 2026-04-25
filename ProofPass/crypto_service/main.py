"""
ProofPass — Quantum-Safe Crypto Service
CRYSTALS-Dilithium2 signing & verification API
Port: 8001

BUG FIX: Enforced 1 wallet <-> 1 username binding.
Previously, the same wallet address could register unlimited usernames,
breaking the identity system. Now, each wallet can only have ONE .init username.
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dilithium_py.dilithium import Dilithium2
import base64, json, hashlib, time
from typing import Optional

app = FastAPI(title="ProofPass Crypto Service", version="2.0.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

# In-memory registry
credential_registry: dict = {}   # username -> credential
wallet_registry: dict = {}       # wallet_address -> username  [THE FIX: enforces 1:1 binding]
known_issuer_keys: list = []


class KeygenRequest(BaseModel):
    username: str

class RegisterCredentialRequest(BaseModel):
    username: str
    display_name: Optional[str] = ""
    wallet_address: Optional[str] = ""

class VerifyRequest(BaseModel):
    username: str
    public_key_b64: str
    message: str
    signature_b64: str

class RevokeRequest(BaseModel):
    username: str


@app.get("/")
def root():
    return {"service": "ProofPass Crypto Service", "status": "online",
            "algorithm": "CRYSTALS-Dilithium2", "port": 8001,
            "version": "2.0.0", "fix": "1-wallet-1-username binding enforced"}


@app.get("/stats")
def get_stats():
    active = sum(1 for c in credential_registry.values() if c.get("status") == "active")
    revoked = sum(1 for c in credential_registry.values() if c.get("status") == "revoked")
    return {
        "total_credentials": len(credential_registry),
        "active": active,
        "revoked": revoked,
        "algorithm": "CRYSTALS-Dilithium2",
        "security_level": "NIST Level 2 (128-bit quantum security)",
        "public_key_size_bytes": 1312,
        "signature_size_bytes": 2420,
        "known_issuers": len(known_issuer_keys),
        "wallet_bindings": len(wallet_registry),
    }


@app.post("/credential/register")
def register_credential(req: RegisterCredentialRequest):
    """
    Issue a new ProofPass credential.
    BUG FIX: Enforces strict 1 wallet <-> 1 username binding.
    - A username cannot be registered twice.
    - A wallet cannot own more than one username.
    """

    # CHECK 1: Username uniqueness
    if req.username in credential_registry:
        raise HTTPException(
            status_code=409,
            detail=f"Username '{req.username}.init' is already taken."
        )

    # CHECK 2: Wallet uniqueness [THE BUG FIX]
    wallet = req.wallet_address or f"init1{hashlib.sha256(req.username.encode()).hexdigest()[:38]}"

    if wallet in wallet_registry:
        existing_username = wallet_registry[wallet]
        raise HTTPException(
            status_code=409,
            detail=(
                f"This wallet is already bound to '{existing_username}.init'. "
                f"Each wallet can only own ONE .init username (1-wallet=1-username rule). "
                f"Revoke '{existing_username}.init' first if you want to re-register."
            )
        )

    # GENERATE KEYPAIR & SIGN
    pk, sk = Dilithium2.keygen()
    pk_b64 = base64.b64encode(pk).decode()
    sk_b64 = base64.b64encode(sk).decode()
    known_issuer_keys.append(pk_b64)

    now = int(time.time())

    credential_data = {
        "username": req.username,
        "display_name": req.display_name or req.username,
        "wallet_address": wallet,
        "public_key": pk_b64,
        "status": "active",
        "issued_at": now,
        "issued_at_readable": time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime(now)),
        "chain": "proofpass-1",
        "chain_id": "proofpass-1",
        "algorithm": "CRYSTALS-Dilithium2",
        "quantum_safe": True,
        "trust_level": "unverified",
        "tx_hash": "0x" + hashlib.sha256(f"{req.username}{now}".encode()).hexdigest(),
    }

    payload = json.dumps(credential_data, sort_keys=True).encode()
    sig = Dilithium2.sign(sk, payload)
    sig_b64 = base64.b64encode(sig).decode()
    cred_hash = hashlib.sha256(sig).hexdigest()

    credential_data["signature"] = sig_b64
    credential_data["credential_hash"] = cred_hash

    # WRITE BOTH REGISTRIES — atomic identity binding
    credential_registry[req.username] = credential_data
    wallet_registry[wallet] = req.username   # THE FIX

    return {
        "success": True,
        "credential": credential_data,
        "secret_key": sk_b64,
        "message": f"ProofPass credential issued for {req.username}.init",
        "wallet_bound": wallet,
        "identity_rule": "1 wallet = 1 username enforced",
    }


@app.get("/credential/{username}")
def get_credential(username: str):
    if username not in credential_registry:
        raise HTTPException(status_code=404, detail=f"No credential for {username}.init")
    return credential_registry[username]


@app.get("/wallet/{wallet_address}")
def get_credential_by_wallet(wallet_address: str):
    """Look up which username is bound to a wallet address."""
    if wallet_address not in wallet_registry:
        raise HTTPException(status_code=404, detail=f"No credential bound to this wallet")
    username = wallet_registry[wallet_address]
    return credential_registry[username]


@app.post("/credential/revoke")
def revoke_credential(req: RevokeRequest):
    if req.username not in credential_registry:
        raise HTTPException(status_code=404, detail="Credential not found")

    cred = credential_registry[req.username]
    cred["status"] = "revoked"
    cred["revoked_at"] = int(time.time())
    cred["trust_level"] = "revoked"

    # Free the wallet so it can re-register a new username
    wallet = cred.get("wallet_address", "")
    if wallet in wallet_registry:
        del wallet_registry[wallet]

    return {"success": True, "message": f"Credential for {req.username}.init revoked. Wallet is now free to re-register."}


@app.post("/verify")
def verify_signature(req: VerifyRequest):
    try:
        pk = base64.b64decode(req.public_key_b64)
        sig = base64.b64decode(req.signature_b64)
        msg_bytes = req.message.encode()
        valid = Dilithium2.verify(pk, msg_bytes, sig)
        is_known = req.public_key_b64 in known_issuer_keys
        return {"username": req.username, "valid": valid,
                "is_known_issuer": is_known, "quantum_safe": True}
    except Exception as e:
        return {"username": req.username, "valid": False, "error": str(e)}


@app.get("/registry")
def list_registry():
    pub = {}
    for u, c in credential_registry.items():
        pub[u] = {
            "username": c["username"],
            "display_name": c.get("display_name", u),
            "wallet_address": c["wallet_address"],
            "status": c["status"],
            "issued_at": c["issued_at"],
            "issued_at_readable": c.get("issued_at_readable", ""),
            "trust_level": c.get("trust_level", "unverified"),
            "quantum_safe": True,
            "credential_hash": c.get("credential_hash", "")[:16] + "...",
        }
    return {"total": len(pub), "credentials": pub, "wallet_bindings": len(wallet_registry)}
