// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../contracts/interfaces/IUniswapV2Pair.sol";

contract CheckLiquidityScript is Script {
    
    function run() external {
        console.log("=== Check Liquidity Status ===");
        
        address pairAddr = 0x27FD6cBE8d206047D695e966D54529b951848baF;
        
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddr);
        
        console.log("Pair Address:", pairAddr);
        console.log("Token0:", pair.token0());
        console.log("Token1:", pair.token1());
        
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair.getReserves();
        console.log("Reserve0:", reserve0);
        console.log("Reserve1:", reserve1);
        console.log("Last Update:", blockTimestampLast);
        
        if (reserve0 > 0 && reserve1 > 0) {
            console.log("[OK] Liquidity exists");
            // Simple price calculation without overflow risk
            console.log("Price Token0/Token1 (basis points):", (reserve1 * 10000) / reserve0);
            console.log("Price Token1/Token0 (basis points):", (reserve0 * 10000) / reserve1);
        } else {
            console.log("[WARN] No liquidity found");
        }
    }
}