// ProofPass CosmWasm Smart Contract
// Quantum-Safe Identity Registry on Initia
// CRYSTALS-Dilithium2 credential anchoring

use cosmwasm_std::{
    entry_point, to_json_binary, Binary, Deps, DepsMut, Env, MessageInfo,
    Response, StdError, StdResult, Addr, Timestamp,
};
use cw_storage_plus::{Item, Map};
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

// ── STATE ─────────────────────────────────────────────────────────

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct CredentialEntry {
    pub username: String,
    pub wallet_address: Addr,
    pub dilithium2_pubkey: String,  // base64 encoded 1312-byte Dilithium2 public key
    pub credential_hash: String,    // SHA-256 of the quantum signature
    pub trust_score: u8,            // 0-100, updated by AI oracle
    pub trust_level: String,        // HIGH / MEDIUM / LOW
    pub auto_sign_enabled: bool,
    pub session_expiry: Option<Timestamp>,
    pub issued_at: Timestamp,
    pub status: String,             // active / revoked
    pub tx_count: u64,              // on-chain tx history count (for AI scoring)
    pub defi_volume_uinit: u128,    // lifetime DeFi volume in uINIT
}

// 1 wallet → 1 username (the key fix)
const CREDENTIALS: Map<&str, CredentialEntry> = Map::new("credentials"); // key: username
const WALLET_INDEX: Map<&Addr, String> = Map::new("wallet_index");        // key: wallet → username
const ADMIN: Item<Addr> = Item::new("admin");
const TOTAL_ISSUED: Item<u64> = Item::new("total_issued");

// ── MSG TYPES ─────────────────────────────────────────────────────

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct InstantiateMsg {
    pub admin: Option<String>,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum ExecuteMsg {
    /// Register a new quantum-safe identity credential
    Register {
        username: String,
        dilithium2_pubkey: String,
        credential_hash: String,
    },
    /// Update trust score (called by AI oracle — admin only in v1)
    UpdateTrustScore {
        username: String,
        trust_score: u8,
        trust_level: String,
        auto_sign_enabled: bool,
        session_duration_secs: u64,
    },
    /// Record on-chain DeFi activity (called post-swap to build tx history)
    RecordActivity {
        username: String,
        volume_uinit: u128,
    },
    /// Revoke a credential
    Revoke {
        username: String,
    },
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum QueryMsg {
    GetCredential { username: String },
    GetByWallet { wallet: String },
    GetStats {},
    IsAutoSignEnabled { username: String },
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct CredentialResponse {
    pub credential: Option<CredentialEntry>,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct StatsResponse {
    pub total_issued: u64,
    pub algorithm: String,
    pub chain_id: String,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct AutoSignResponse {
    pub enabled: bool,
    pub trust_score: u8,
    pub trust_level: String,
    pub session_expiry: Option<Timestamp>,
}

// ── ENTRY POINTS ──────────────────────────────────────────────────

#[entry_point]
pub fn instantiate(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    msg: InstantiateMsg,
) -> StdResult<Response> {
    let admin = match msg.admin {
        Some(a) => deps.api.addr_validate(&a)?,
        None => info.sender.clone(),
    };
    ADMIN.save(deps.storage, &admin)?;
    TOTAL_ISSUED.save(deps.storage, &0u64)?;

    Ok(Response::new()
        .add_attribute("action", "instantiate")
        .add_attribute("admin", admin)
        .add_attribute("contract", "ProofPass v1.0")
        .add_attribute("algorithm", "CRYSTALS-Dilithium2"))
}

#[entry_point]
pub fn execute(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    msg: ExecuteMsg,
) -> StdResult<Response> {
    match msg {
        ExecuteMsg::Register { username, dilithium2_pubkey, credential_hash } =>
            execute_register(deps, env, info, username, dilithium2_pubkey, credential_hash),
        ExecuteMsg::UpdateTrustScore { username, trust_score, trust_level, auto_sign_enabled, session_duration_secs } =>
            execute_update_trust(deps, env, info, username, trust_score, trust_level, auto_sign_enabled, session_duration_secs),
        ExecuteMsg::RecordActivity { username, volume_uinit } =>
            execute_record_activity(deps, info, username, volume_uinit),
        ExecuteMsg::Revoke { username } =>
            execute_revoke(deps, info, username),
    }
}

fn execute_register(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    username: String,
    dilithium2_pubkey: String,
    credential_hash: String,
) -> StdResult<Response> {
    // Username uniqueness check
    if CREDENTIALS.has(deps.storage, &username) {
        return Err(StdError::generic_err(format!(
            "Username '{}.init' is already registered", username
        )));
    }

    // 1-wallet-1-username check
    if WALLET_INDEX.has(deps.storage, &info.sender) {
        let existing = WALLET_INDEX.load(deps.storage, &info.sender)?;
        return Err(StdError::generic_err(format!(
            "Wallet already owns '{}.init'. Each wallet can only have ONE identity.", existing
        )));
    }

    // Validate Dilithium2 pubkey length (~1312 bytes → ~1748 base64 chars)
    let decoded_len = (dilithium2_pubkey.len() * 3) / 4;
    if decoded_len < 1200 || decoded_len > 1400 {
        return Err(StdError::generic_err("Invalid Dilithium2 public key size"));
    }

    let credential = CredentialEntry {
        username: username.clone(),
        wallet_address: info.sender.clone(),
        dilithium2_pubkey,
        credential_hash,
        trust_score: 0,
        trust_level: "PENDING".to_string(),
        auto_sign_enabled: false,
        session_expiry: None,
        issued_at: env.block.time,
        status: "active".to_string(),
        tx_count: 0,
        defi_volume_uinit: 0,
    };

    CREDENTIALS.save(deps.storage, &username, &credential)?;
    WALLET_INDEX.save(deps.storage, &info.sender, &username)?;
    TOTAL_ISSUED.update(deps.storage, |n| Ok::<u64, StdError>(n + 1))?;

    Ok(Response::new()
        .add_attribute("action", "register")
        .add_attribute("username", format!("{}.init", username))
        .add_attribute("wallet", info.sender)
        .add_attribute("credential_hash", &credential.credential_hash)
        .add_attribute("algorithm", "CRYSTALS-Dilithium2")
        .add_attribute("chain", "proofpass-1"))
}

fn execute_update_trust(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    username: String,
    trust_score: u8,
    trust_level: String,
    auto_sign_enabled: bool,
    session_duration_secs: u64,
) -> StdResult<Response> {
    // Only admin (AI oracle) can update trust scores
    let admin = ADMIN.load(deps.storage)?;
    if info.sender != admin {
        return Err(StdError::generic_err("Only the AI oracle admin can update trust scores"));
    }

    CREDENTIALS.update(deps.storage, &username, |cred| {
        let mut c = cred.ok_or_else(|| StdError::generic_err("Credential not found"))?;
        c.trust_score = trust_score;
        c.trust_level = trust_level.clone();
        c.auto_sign_enabled = auto_sign_enabled;
        c.session_expiry = if auto_sign_enabled {
            Some(Timestamp::from_nanos(
                env.block.time.nanos() + session_duration_secs * 1_000_000_000
            ))
        } else {
            None
        };
        Ok(c)
    })?;

    Ok(Response::new()
        .add_attribute("action", "update_trust")
        .add_attribute("username", &username)
        .add_attribute("trust_score", trust_score.to_string())
        .add_attribute("auto_sign", auto_sign_enabled.to_string()))
}

fn execute_record_activity(
    deps: DepsMut,
    info: MessageInfo,
    username: String,
    volume_uinit: u128,
) -> StdResult<Response> {
    CREDENTIALS.update(deps.storage, &username, |cred| {
        let mut c = cred.ok_or_else(|| StdError::generic_err("Credential not found"))?;
        // Only the credential owner can record their own activity
        if c.wallet_address != info.sender {
            return Err(StdError::generic_err("Not your credential"));
        }
        c.tx_count += 1;
        c.defi_volume_uinit += volume_uinit;
        Ok(c)
    })?;

    Ok(Response::new()
        .add_attribute("action", "record_activity")
        .add_attribute("username", &username)
        .add_attribute("volume_uinit", volume_uinit.to_string()))
}

fn execute_revoke(
    deps: DepsMut,
    info: MessageInfo,
    username: String,
) -> StdResult<Response> {
    let admin = ADMIN.load(deps.storage)?;
    let cred = CREDENTIALS.load(deps.storage, &username)
        .map_err(|_| StdError::generic_err("Credential not found"))?;

    // Only owner or admin can revoke
    if info.sender != cred.wallet_address && info.sender != admin {
        return Err(StdError::generic_err("Not authorized to revoke this credential"));
    }

    // Free wallet binding so it can re-register
    WALLET_INDEX.remove(deps.storage, &cred.wallet_address);

    CREDENTIALS.update(deps.storage, &username, |c| {
        let mut cred = c.unwrap();
        cred.status = "revoked".to_string();
        cred.auto_sign_enabled = false;
        cred.session_expiry = None;
        Ok::<CredentialEntry, StdError>(cred)
    })?;

    Ok(Response::new()
        .add_attribute("action", "revoke")
        .add_attribute("username", &username))
}

#[entry_point]
pub fn query(deps: Deps, env: Env, msg: QueryMsg) -> StdResult<Binary> {
    match msg {
        QueryMsg::GetCredential { username } => {
            let cred = CREDENTIALS.may_load(deps.storage, &username)?;
            to_json_binary(&CredentialResponse { credential: cred })
        }
        QueryMsg::GetByWallet { wallet } => {
            let addr = deps.api.addr_validate(&wallet)?;
            let username = WALLET_INDEX.may_load(deps.storage, &addr)?;
            let cred = username.and_then(|u| CREDENTIALS.may_load(deps.storage, &u).ok().flatten());
            to_json_binary(&CredentialResponse { credential: cred })
        }
        QueryMsg::GetStats {} => {
            let total = TOTAL_ISSUED.load(deps.storage)?;
            to_json_binary(&StatsResponse {
                total_issued: total,
                algorithm: "CRYSTALS-Dilithium2 (NIST PQC FIPS 204)".to_string(),
                chain_id: "proofpass-1".to_string(),
            })
        }
        QueryMsg::IsAutoSignEnabled { username } => {
            let cred = CREDENTIALS.may_load(deps.storage, &username)?;
            let response = match cred {
                None => AutoSignResponse {
                    enabled: false,
                    trust_score: 0,
                    trust_level: "NONE".to_string(),
                    session_expiry: None,
                },
                Some(c) => {
                    // Check if session is still valid
                    let still_valid = c.session_expiry
                        .map(|exp| exp.nanos() > env.block.time.nanos())
                        .unwrap_or(false);
                    AutoSignResponse {
                        enabled: c.auto_sign_enabled && still_valid,
                        trust_score: c.trust_score,
                        trust_level: c.trust_level,
                        session_expiry: c.session_expiry,
                    }
                }
            };
            to_json_binary(&response)
        }
    }
}
