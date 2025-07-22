// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Script.sol";
import "../src/interfaces/IUniswapV2Router02.sol";
import "../src/interfaces/IUniswapV2Factory.sol";

contract QuickTest is Script {
    // Polygon addresses
    address constant QUICKSWAP_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    
    function run() external view {
        console.log("=== QuickSwap Integration Test ===");
        console.log("Chain ID:", block.chainid);
        console.log("Block number:", block.number);
        
        // Check if addresses have code (exist on the network)
        console.log("QuickSwap Router code length:", QUICKSWAP_ROUTER.code.length);
        console.log("WMATIC code length:", WMATIC.code.length);
        
        if (QUICKSWAP_ROUTER.code.length > 0) {
            IUniswapV2Router02 router = IUniswapV2Router02(QUICKSWAP_ROUTER);
            
            try router.factory() returns (address factory) {
                console.log("QuickSwap Factory:", factory);
                console.log("Factory code length:", factory.code.length);
            } catch {
                console.log("Failed to get factory address");
            }
            
            try router.WETH() returns (address weth) {
                console.log("Router WETH:", weth);
                console.log("Expected WMATIC:", WMATIC);
                console.log("WETH matches WMATIC:", weth == WMATIC);
            } catch {
                console.log("Failed to get WETH address");
            }
        } else {
            console.log("ERROR: QuickSwap Router not found");
        }
        
        console.log("=== Test completed ===");
    }
}