// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../test/mocks/MockERC20.sol";

contract DeployTestTokensPolygon is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy Test Token A
        MockERC20 tokenA = new MockERC20("Test Token A", "TTA", 18);
        tokenA.mint(deployer, 1000000 * 10**18); // Mint 1M tokens to deployer
        
        // Deploy Test Token B  
        MockERC20 tokenB = new MockERC20("Test Token B", "TTB", 18);
        tokenB.mint(deployer, 1000000 * 10**18); // Mint 1M tokens to deployer
        
        vm.stopBroadcast();
        
        console.log("=== Polygon Test Tokens Deployment ===");
        console.log("Test Token A (TTA) deployed to:", address(tokenA));
        console.log("Test Token B (TTB) deployed to:", address(tokenB));
        console.log("Chain ID:", block.chainid);
        console.log("Initial supply per token: 1,000,000");
        console.log("Tokens minted to deployer:", deployer);
        
        console.log("Test tokens deployment successful on Polygon!");
        console.log("Next: Update token addresses in tokens.ts");
    }
}