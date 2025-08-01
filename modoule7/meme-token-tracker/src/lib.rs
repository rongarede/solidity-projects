mod pb;
mod tests;
mod integration_tests;

use hex;
use pb::meme::{TokenTransfer, TokenTransfers, TokenActivity, TokenRankings};
use substreams::{log};
use substreams_ethereum::pb::eth::v2 as eth;
use std::collections::HashMap;

// Meme token whitelist
pub const MEME_TOKENS: &[&str] = &[
    "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce", // SHIB
    "0x6982508145454ce325ddbe47a25d4ec3d2311933", // PEPE
    "0xba11d00c5f74255f56a5e366f4f77f5a186d7f55", // BAND
    "0x4d224452801aced8b2f0aebe155379bb5d594381", // APE
    "0x853d955acef822db058eb8505911ed77f175b99e", // FRAX
];

// ERC20 Transfer event signature
pub const TRANSFER_EVENT_SIG: &str = "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef";

/// Check if a token address is in the meme token whitelist
pub fn is_meme_token(address: &str) -> bool {
    let addr_lower = address.to_lowercase();
    MEME_TOKENS.contains(&addr_lower.as_str())
}

#[substreams::handlers::map]
fn map_token_transfers(blk: eth::Block) -> Result<TokenTransfers, substreams::errors::Error> {
    let mut transfers = Vec::new();

    for trx in blk.transaction_traces.iter() {
        for (log_index, log) in trx.receipt.as_ref().unwrap().logs.iter().enumerate() {
            // Check if this is a Transfer event
            if log.topics.is_empty() || log.topics[0].as_slice() != hex::decode(TRANSFER_EVENT_SIG.trim_start_matches("0x")).unwrap() {
                continue;
            }

            let token_address = format!("0x{}", hex::encode(&log.address));
            
            // Check if this token is in our whitelist
            if !is_meme_token(&token_address) {
                continue;
            }

            // Parse Transfer event data
            if log.topics.len() >= 3 {
                let from = if log.topics[1].len() == 32 {
                    format!("0x{}", hex::encode(&log.topics[1][12..]))
                } else {
                    format!("0x{}", hex::encode(&log.topics[1]))
                };

                let to = if log.topics[2].len() == 32 {
                    format!("0x{}", hex::encode(&log.topics[2][12..]))
                } else {
                    format!("0x{}", hex::encode(&log.topics[2]))
                };

                let amount = if !log.data.is_empty() {
                    format!("0x{}", hex::encode(&log.data))
                } else {
                    "0x0".to_string()
                };

                transfers.push(TokenTransfer {
                    token_address: token_address.to_lowercase(),
                    from,
                    to,
                    amount,
                    block_number: blk.number,
                    transaction_hash: format!("0x{}", hex::encode(&trx.hash)),
                    log_index: log_index as u64,
                });
            }
        }
    }

    log::info!("Found {} meme token transfers in block {}", transfers.len(), blk.number);

    Ok(TokenTransfers { transfers })
}

/// Internal function for testing token rankings logic
pub fn calculate_token_rankings(transfers: TokenTransfers) -> Result<TokenRankings, substreams::errors::Error> {
    let mut activity_map: HashMap<String, TokenActivity> = HashMap::new();
    let mut block_range_start = u64::MAX;
    let mut block_range_end = 0u64;

    // Count transfers per token
    for transfer in transfers.transfers.iter() {
        let entry = activity_map.entry(transfer.token_address.clone()).or_insert(TokenActivity {
            address: transfer.token_address.clone(),
            transfer_count: 0,
            last_block: 0,
            symbol: get_token_symbol(&transfer.token_address),
        });

        entry.transfer_count += 1;
        entry.last_block = entry.last_block.max(transfer.block_number);
        
        block_range_start = block_range_start.min(transfer.block_number);
        block_range_end = block_range_end.max(transfer.block_number);
    }

    // Convert to vector and sort by transfer count (descending)
    let mut rankings: Vec<TokenActivity> = activity_map.into_values().collect();
    rankings.sort_by(|a, b| b.transfer_count.cmp(&a.transfer_count));

    let total_transfers = rankings.iter().map(|r| r.transfer_count).sum();

    if block_range_start == u64::MAX {
        block_range_start = 0;
    }

    Ok(TokenRankings {
        rankings,
        total_transfers,
        block_range_start,
        block_range_end,
    })
}

#[substreams::handlers::map]
fn map_token_rankings(transfers: TokenTransfers) -> Result<TokenRankings, substreams::errors::Error> {
    calculate_token_rankings(transfers)
}


/// Get token symbol for known meme tokens
pub fn get_token_symbol(address: &str) -> String {
    match address.to_lowercase().as_str() {
        "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce" => "SHIB".to_string(),
        "0x6982508145454ce325ddbe47a25d4ec3d2311933" => "PEPE".to_string(),
        "0xba11d00c5f74255f56a5e366f4f77f5a186d7f55" => "BAND".to_string(),
        "0x4d224452801aced8b2f0aebe155379bb5d594381" => "APE".to_string(),
        "0x853d955acef822db058eb8505911ed77f175b99e" => "FRAX".to_string(),
        _ => "UNKNOWN".to_string(),
    }
}