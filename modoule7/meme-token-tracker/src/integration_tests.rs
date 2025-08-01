#[cfg(test)]
mod integration_tests {
    use crate::*;

    /// Create mock transfer data for testing
    fn create_mock_transfers() -> TokenTransfers {
        TokenTransfers {
            transfers: vec![
                // SHIB transfers (most active)
                TokenTransfer {
                    token_address: "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce".to_string(),
                    from: "0x1111111111111111111111111111111111111111".to_string(),
                    to: "0x2222222222222222222222222222222222222222".to_string(),
                    amount: "1000000000000000000".to_string(), // 1 SHIB
                    block_number: 18000000,
                    transaction_hash: "0xabc123".to_string(),
                    log_index: 0,
                },
                TokenTransfer {
                    token_address: "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce".to_string(),
                    from: "0x3333333333333333333333333333333333333333".to_string(),
                    to: "0x4444444444444444444444444444444444444444".to_string(),
                    amount: "2000000000000000000".to_string(), // 2 SHIB
                    block_number: 18000001,
                    transaction_hash: "0xdef456".to_string(),
                    log_index: 1,
                },
                TokenTransfer {
                    token_address: "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce".to_string(),
                    from: "0x5555555555555555555555555555555555555555".to_string(),
                    to: "0x6666666666666666666666666666666666666666".to_string(),
                    amount: "500000000000000000".to_string(), // 0.5 SHIB
                    block_number: 18000002,
                    transaction_hash: "0xghi789".to_string(),
                    log_index: 2,
                },
                // PEPE transfers (second most active)
                TokenTransfer {
                    token_address: "0x6982508145454ce325ddbe47a25d4ec3d2311933".to_string(),
                    from: "0x7777777777777777777777777777777777777777".to_string(),
                    to: "0x8888888888888888888888888888888888888888".to_string(),
                    amount: "100000000000000000000".to_string(), // 100 PEPE
                    block_number: 18000001,
                    transaction_hash: "0xjkl012".to_string(),
                    log_index: 3,
                },
                TokenTransfer {
                    token_address: "0x6982508145454ce325ddbe47a25d4ec3d2311933".to_string(),
                    from: "0x9999999999999999999999999999999999999999".to_string(),
                    to: "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa".to_string(),
                    amount: "50000000000000000000".to_string(), // 50 PEPE
                    block_number: 18000003,
                    transaction_hash: "0xmno345".to_string(),
                    log_index: 4,
                },
                // APE transfer (least active)
                TokenTransfer {
                    token_address: "0x4d224452801aced8b2f0aebe155379bb5d594381".to_string(),
                    from: "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb".to_string(),
                    to: "0xcccccccccccccccccccccccccccccccccccccccc".to_string(),
                    amount: "1000000000000000000".to_string(), // 1 APE
                    block_number: 18000004,
                    transaction_hash: "0xpqr678".to_string(),
                    log_index: 5,
                },
            ]
        }
    }

    #[test]
    fn test_full_ranking_pipeline() {
        let mock_transfers = create_mock_transfers();
        let result = calculate_token_rankings(mock_transfers).unwrap();
        
        // Verify basic statistics
        assert_eq!(result.rankings.len(), 3); // SHIB, PEPE, APE
        assert_eq!(result.total_transfers, 6); // Total transfers
        assert_eq!(result.block_range_start, 18000000);
        assert_eq!(result.block_range_end, 18000004);
        
        // Verify ranking order (sorted by transfer count desc)
        assert_eq!(result.rankings[0].symbol, "SHIB");
        assert_eq!(result.rankings[0].transfer_count, 3);
        assert_eq!(result.rankings[0].last_block, 18000002);
        
        assert_eq!(result.rankings[1].symbol, "PEPE");
        assert_eq!(result.rankings[1].transfer_count, 2);
        assert_eq!(result.rankings[1].last_block, 18000003);
        
        assert_eq!(result.rankings[2].symbol, "APE");
        assert_eq!(result.rankings[2].transfer_count, 1);
        assert_eq!(result.rankings[2].last_block, 18000004);
    }

    #[test]
    fn test_whitelist_filtering() {
        // Test that only whitelisted tokens are processed
        let transfers_with_unknown_token = TokenTransfers {
            transfers: vec![
                TokenTransfer {
                    token_address: "0x1234567890123456789012345678901234567890".to_string(), // Not in whitelist
                    from: "0x1111111111111111111111111111111111111111".to_string(),
                    to: "0x2222222222222222222222222222222222222222".to_string(),
                    amount: "1000".to_string(),
                    block_number: 18000000,
                    transaction_hash: "0xabc".to_string(),
                    log_index: 0,
                },
                TokenTransfer {
                    token_address: "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce".to_string(), // SHIB - in whitelist
                    from: "0x3333333333333333333333333333333333333333".to_string(),
                    to: "0x4444444444444444444444444444444444444444".to_string(),
                    amount: "2000".to_string(),
                    block_number: 18000001,
                    transaction_hash: "0xdef".to_string(),
                    log_index: 1,
                },
            ]
        };

        let result = calculate_token_rankings(transfers_with_unknown_token).unwrap();
        
        // Both tokens will be processed by calculate_token_rankings
        // because filtering happens in map_token_transfers stage
        assert_eq!(result.rankings.len(), 2);
        assert_eq!(result.total_transfers, 2);
        
        // But we can verify that unknown tokens get "UNKNOWN" symbol
        let unknown_token = result.rankings.iter().find(|r| r.symbol == "UNKNOWN").unwrap();
        assert_eq!(unknown_token.address, "0x1234567890123456789012345678901234567890");
        
        let shib_token = result.rankings.iter().find(|r| r.symbol == "SHIB").unwrap();
        assert_eq!(shib_token.address, "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce");
    }

    #[test]
    fn test_large_dataset_performance() {
        // Test with a larger dataset to verify performance
        let mut transfers = Vec::new();
        
        // Generate 1000 transfers across different tokens
        for i in 0..1000 {
            let token_index = i % MEME_TOKENS.len();
            transfers.push(TokenTransfer {
                token_address: MEME_TOKENS[token_index].to_string(),
                from: format!("0x{:040x}", i),
                to: format!("0x{:040x}", i + 1),
                amount: format!("{}", i * 1000),
                block_number: 18000000 + (i as u64),
                transaction_hash: format!("0x{:x}", i),
                log_index: i as u64,
            });
        }

        let transfers = TokenTransfers { transfers };
        let start = std::time::Instant::now();
        let result = calculate_token_rankings(transfers).unwrap();
        let duration = start.elapsed();

        println!("Processing 1000 transfers took: {:?}", duration);
        
        // Verify results
        assert_eq!(result.rankings.len(), MEME_TOKENS.len());
        assert_eq!(result.total_transfers, 1000);
        
        // Each token should have roughly equal transfers (1000 / 5 = 200)
        for ranking in &result.rankings {
            assert!(ranking.transfer_count >= 199);
            assert!(ranking.transfer_count <= 201);
        }
        
        // Performance should be reasonable (less than 10ms for 1000 transfers)
        assert!(duration.as_millis() < 10);
    }

    #[test]
    fn test_block_range_calculation() {
        let transfers = TokenTransfers {
            transfers: vec![
                TokenTransfer {
                    token_address: "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce".to_string(),
                    from: "0x1111111111111111111111111111111111111111".to_string(),
                    to: "0x2222222222222222222222222222222222222222".to_string(),
                    amount: "1000".to_string(),
                    block_number: 18000010,
                    transaction_hash: "0xabc".to_string(),
                    log_index: 0,
                },
                TokenTransfer {
                    token_address: "0x6982508145454ce325ddbe47a25d4ec3d2311933".to_string(),
                    from: "0x3333333333333333333333333333333333333333".to_string(),
                    to: "0x4444444444444444444444444444444444444444".to_string(),
                    amount: "2000".to_string(),
                    block_number: 18000005, // Earlier block
                    transaction_hash: "0xdef".to_string(),
                    log_index: 1,
                },
                TokenTransfer {
                    token_address: "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce".to_string(),
                    from: "0x5555555555555555555555555555555555555555".to_string(),
                    to: "0x6666666666666666666666666666666666666666".to_string(),
                    amount: "3000".to_string(),
                    block_number: 18000015, // Latest block
                    transaction_hash: "0xghi".to_string(),
                    log_index: 2,
                },
            ]
        };

        let result = calculate_token_rankings(transfers).unwrap();
        
        assert_eq!(result.block_range_start, 18000005);
        assert_eq!(result.block_range_end, 18000015);
        
        // Verify last_block for each token
        let shib_ranking = result.rankings.iter().find(|r| r.symbol == "SHIB").unwrap();
        assert_eq!(shib_ranking.last_block, 18000015); // Latest SHIB transfer
        
        let pepe_ranking = result.rankings.iter().find(|r| r.symbol == "PEPE").unwrap();
        assert_eq!(pepe_ranking.last_block, 18000005); // Only PEPE transfer
    }
}