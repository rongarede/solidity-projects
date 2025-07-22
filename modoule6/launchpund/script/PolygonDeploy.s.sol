// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Script.sol";
import "../src/MemeToken.sol";
import "../src/MemeFactory.sol";

contract PolygonDeploy is Script {
    // Polygon Mainnet addresses
    address constant QUICKSWAP_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    
    function run() external returns (address template, address factory) {
        // Handle private key with or without 0x prefix
        string memory privateKeyStr = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey;
        if (bytes(privateKeyStr).length == 64) {
            // No 0x prefix, add it
            deployerPrivateKey = vm.parseUint(string(abi.encodePacked("0x", privateKeyStr)));
        } else {
            // Has 0x prefix
            deployerPrivateKey = vm.parseUint(privateKeyStr);
        }
        address platformWallet = vm.envOr("PLATFORM_WALLET", vm.addr(deployerPrivateKey));
        
        console.log("=== Polygon Mainnet Deployment ===");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Platform Wallet:", platformWallet);
        console.log("Chain ID:", block.chainid);
        console.log("QuickSwap Router:", QUICKSWAP_ROUTER);
        console.log("WMATIC:", WMATIC);
        
        // Verify we're on Polygon
        require(block.chainid == 137, "This script is for Polygon Mainnet only");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy MemeToken template
        template = address(new MemeToken());
        console.log("MemeToken template deployed:", template);
        
        // Deploy MemeFactory
        factory = address(new MemeFactory(
            template,
            QUICKSWAP_ROUTER,
            WMATIC,
            platformWallet
        ));
        console.log("MemeFactory deployed:", factory);
        
        vm.stopBroadcast();
        
        console.log("\n=== Deployment Summary ===");
        console.log("Network: Polygon Mainnet");
        console.log("Chain ID:", block.chainid);
        console.log("Template:", template);
        console.log("Factory:", factory);
        console.log("Platform Wallet:", platformWallet);
        console.log("Gas Price:", tx.gasprice);
        
        // Save to file for later use
        string memory deploymentData = string(abi.encodePacked(
            "FACTORY_ADDRESS=", vm.toString(factory), "\n",
            "TEMPLATE_ADDRESS=", vm.toString(template), "\n",
            "PLATFORM_WALLET=", vm.toString(platformWallet), "\n"
        ));
        
        console.log("\n=== Add to .env file ===");
        console.log(deploymentData);
        
        return (template, factory);
    }
}