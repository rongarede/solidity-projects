#[cfg(test)]
mod tests {
    use crate::*;

    #[test]
    fn test_is_meme_token() {
        // Test valid meme tokens
        assert!(is_meme_token("0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce")); // SHIB
        assert!(is_meme_token("0x6982508145454ce325ddbe47a25d4ec3d2311933")); // PEPE
        assert!(is_meme_token("0x95AD61B0A150D79219DCF64E1E6CC01F0B64C4CE")); // SHIB uppercase
        
        // Test invalid tokens
        assert!(!is_meme_token("0x1234567890123456789012345678901234567890"));
        assert!(!is_meme_token("0x0000000000000000000000000000000000000000"));
        assert!(!is_meme_token(""));
    }

    #[test]
    fn test_get_token_symbol() {
        assert_eq!(get_token_symbol("0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce"), "SHIB");
        assert_eq!(get_token_symbol("0x6982508145454ce325ddbe47a25d4ec3d2311933"), "PEPE");
        assert_eq!(get_token_symbol("0xba11d00c5f74255f56a5e366f4f77f5a186d7f55"), "BAND");
        assert_eq!(get_token_symbol("0x4d224452801aced8b2f0aebe155379bb5d594381"), "APE");
        assert_eq!(get_token_symbol("0x853d955acef822db058eb8505911ed77f175b99e"), "FRAX");
        
        // Test uppercase
        assert_eq!(get_token_symbol("0x95AD61B0A150D79219DCF64E1E6CC01F0B64C4CE"), "SHIB");
        
        // Test unknown token
        assert_eq!(get_token_symbol("0x1234567890123456789012345678901234567890"), "UNKNOWN");
    }

    #[test]
    fn test_transfer_event_signature() {
        // Verify the Transfer event signature is correct
        let expected_sig = "ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef";
        assert_eq!(TRANSFER_EVENT_SIG.trim_start_matches("0x"), expected_sig);
    }

    #[test] 
    fn test_meme_token_addresses_format() {
        // Verify all addresses are lowercase and properly formatted
        for &address in MEME_TOKENS {
            assert_eq!(address.len(), 42); // 0x + 40 hex chars
            assert!(address.starts_with("0x"));
            assert_eq!(address, address.to_lowercase());
            
            // Verify hex characters
            let hex_part = &address[2..];
            assert!(hex_part.chars().all(|c| c.is_ascii_hexdigit()));
        }
    }

    #[test]
    fn test_empty_token_transfers() {
        let empty_transfers = TokenTransfers {
            transfers: vec![]
        };
        
        let result = calculate_token_rankings(empty_transfers).unwrap();
        
        assert_eq!(result.rankings.len(), 0);
        assert_eq!(result.total_transfers, 0);
        assert_eq!(result.block_range_start, 0);
        assert_eq!(result.block_range_end, 0);
    }

    #[test]
    fn test_token_rankings_sorting() {
        let transfers = TokenTransfers {
            transfers: vec![
                TokenTransfer {
                    token_address: "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce".to_string(), // SHIB
                    from: "0x1111111111111111111111111111111111111111".to_string(),
                    to: "0x2222222222222222222222222222222222222222".to_string(),
                    amount: "1000".to_string(),
                    block_number: 18000000,
                    transaction_hash: "0xabc".to_string(),
                    log_index: 0,
                },
                TokenTransfer {
                    token_address: "0x6982508145454ce325ddbe47a25d4ec3d2311933".to_string(), // PEPE
                    from: "0x3333333333333333333333333333333333333333".to_string(),
                    to: "0x4444444444444444444444444444444444444444".to_string(),
                    amount: "2000".to_string(),
                    block_number: 18000001,
                    transaction_hash: "0xdef".to_string(),
                    log_index: 1,
                },
                TokenTransfer {
                    token_address: "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce".to_string(), // SHIB again
                    from: "0x5555555555555555555555555555555555555555".to_string(),
                    to: "0x6666666666666666666666666666666666666666".to_string(),
                    amount: "3000".to_string(),
                    block_number: 18000002,
                    transaction_hash: "0xghi".to_string(),
                    log_index: 2,
                },
            ]
        };

        let result = calculate_token_rankings(transfers).unwrap();
        
        // Should have 2 unique tokens
        assert_eq!(result.rankings.len(), 2);
        
        // Total transfers should be 3
        assert_eq!(result.total_transfers, 3);
        
        // SHIB should be first (2 transfers), PEPE second (1 transfer)
        assert_eq!(result.rankings[0].address, "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce");
        assert_eq!(result.rankings[0].transfer_count, 2);
        assert_eq!(result.rankings[0].symbol, "SHIB");
        
        assert_eq!(result.rankings[1].address, "0x6982508145454ce325ddbe47a25d4ec3d2311933");
        assert_eq!(result.rankings[1].transfer_count, 1);
        assert_eq!(result.rankings[1].symbol, "PEPE");
        
        // Block range
        assert_eq!(result.block_range_start, 18000000);
        assert_eq!(result.block_range_end, 18000002);
    }
}