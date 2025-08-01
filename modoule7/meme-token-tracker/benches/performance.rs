use substreams::{TokenTransfer, TokenTransfers, calculate_token_rankings, MEME_TOKENS};
use std::time::Instant;

fn benchmark_token_rankings(transfer_count: usize) {
    let mut transfers = Vec::with_capacity(transfer_count);
    
    // Generate test data
    for i in 0..transfer_count {
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
    
    // Benchmark the function
    let start = Instant::now();
    let result = calculate_token_rankings(transfers).unwrap();
    let duration = start.elapsed();
    
    println!("Processing {} transfers:", transfer_count);
    println!("  Time: {:?}", duration);
    println!("  Tokens processed: {}", result.rankings.len());
    println!("  Total transfers: {}", result.total_transfers);
    println!("  Throughput: {:.2} transfers/ms", transfer_count as f64 / duration.as_millis() as f64);
    println!();
}

fn main() {
    println!("🚀 Meme Token Tracker Performance Benchmark");
    println!("===========================================");
    
    // Test different data sizes
    let test_sizes = vec![100, 1000, 5000, 10000, 25000];
    
    for size in test_sizes {
        benchmark_token_rankings(size);
    }
    
    println!("✅ Performance benchmark completed!");
}