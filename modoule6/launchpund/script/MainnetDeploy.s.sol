// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Script.sol";
import "../src/MemeToken.sol";
import "../src/MemeFactory.sol";
import "../src/NetworkConfig.sol";

contract MainnetDeploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address platformWallet = vm.envAddress("PLATFORM_WALLET");
        
        console.log("=== Mainnet Deployment ===");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Platform Wallet:", platformWallet);
        console.log("Chain ID:", block.chainid);
        
        // Get network configuration
        NetworkConfig configContract = new NetworkConfig();
        NetworkConfig.Config memory config = configContract.getConfigForCurrentChain();
        
        console.log("Network:", config.name);
        console.log("Router:", config.router);
        console.log("WETH:", config.weth);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy MemeToken template
        MemeToken template = new MemeToken();
        console.log("MemeToken template deployed:", address(template));
        
        // Deploy MemeFactory
        MemeFactory factory = new MemeFactory(
            address(template),
            config.router,
            config.weth,
            platformWallet
        );
        console.log("MemeFactory deployed:", address(factory));
        
        vm.stopBroadcast();
        
        // Save deployment addresses
        string memory deploymentInfo = string(abi.encodePacked(
            "Network: ", config.name, "\n",
            "Chain ID: ", vm.toString(block.chainid), "\n",
            "Template: ", vm.toString(address(template)), "\n",
            "Factory: ", vm.toString(address(factory)), "\n",
            "Platform Wallet: ", vm.toString(platformWallet), "\n"
        ));
        
        console.log("\n=== Deployment Summary ===");
        console.log(deploymentInfo);
        
        // Verify contracts if enabled
        if (vm.envBool("VERIFY_CONTRACTS")) {
            console.log("Contract verification enabled");
            console.log("Run the following commands to verify:");
            console.log("forge verify-contract %s src/MemeToken.sol:MemeToken", vm.toString(address(template)));
            console.log("forge verify-contract %s src/MemeFactory.sol:MemeFactory --constructor-args %s", vm.toString(address(factory)), vm.toString(abi.encode(address(template), config.router, config.weth, platformWallet)));
        }
    }
}