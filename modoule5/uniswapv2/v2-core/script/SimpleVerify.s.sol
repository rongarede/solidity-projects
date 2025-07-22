// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../contracts/UniswapV2Factory.sol";

contract SimpleVerifyScript is Script {
    
    function run() external {
        console.log("=== Uniswap V2 Deployment Verification ===");
        
        // Contract addresses
        address factoryAddr = 0x2E2812638232c64eeC81B4a2DFd4ca975887d571;
        address tokenA = 0xd94b67a5e56696B57908c571eD1E5A40Ce3f64F3;
        address tokenB = 0x731495EAb495076B86CA562eDa51244F20A25CF5;
        
        console.log("Factory Address:", factoryAddr);
        
        UniswapV2Factory factory = UniswapV2Factory(factoryAddr);
        
        console.log("Fee To Setter:", factory.feeToSetter());
        console.log("All Pairs Length:", factory.allPairsLength());
        
        address pair = factory.getPair(tokenA, tokenB);
        console.log("Pair Address:", pair);
        
        if (pair != address(0)) {
            console.log("[OK] Trading pair exists");
        } else {
            console.log("[ERROR] Trading pair not found");
        }
        
        console.log("Verification completed!");
    }
}