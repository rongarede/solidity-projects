// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Script.sol";
import "../src/MemeToken.sol";
import "../src/MemeFactory.sol";
import "../src/NetworkConfig.sol";

contract DeployScript is Script {
    function run() external returns (address template, address factory, address networkConfig) {
        NetworkConfig configContract = new NetworkConfig();
        NetworkConfig.Config memory config = configContract.getConfigForCurrentChain();
        
        console.log("Deploying to network:", config.name);
        console.log("Router address:", config.router);
        console.log("WETH address:", config.weth);

        vm.startBroadcast();

        // Deploy MemeToken template
        template = address(new MemeToken());
        console.log("MemeToken template deployed at:", template);

        // Deploy MemeFactory
        address platformWallet = vm.envOr("PLATFORM_WALLET", msg.sender);
        factory = address(new MemeFactory(
            template,
            config.router,
            config.weth,
            platformWallet
        ));
        console.log("MemeFactory deployed at:", factory);
        console.log("Platform wallet:", platformWallet);

        // Deploy NetworkConfig for reference
        networkConfig = address(configContract);
        console.log("NetworkConfig deployed at:", networkConfig);

        vm.stopBroadcast();

        // Verification info
        console.log("\n=== Deployment Summary ===");
        console.log("Network:", config.name);
        console.log("Chain ID:", block.chainid);
        console.log("Template:", template);
        console.log("Factory:", factory);
        console.log("Config:", networkConfig);
        console.log("========================\n");
    }

    function deployToSpecificNetwork(uint256 chainId, address platformWallet) 
        external 
        returns (address template, address factory) 
    {
        NetworkConfig configContract = new NetworkConfig();
        NetworkConfig.Config memory config = configContract.getConfig(chainId);
        
        console.log("Deploying to specific network:", config.name);
        console.log("Chain ID:", chainId);
        console.log("Router address:", config.router);
        console.log("WETH address:", config.weth);

        vm.startBroadcast();

        // Deploy MemeToken template
        template = address(new MemeToken());
        console.log("MemeToken template deployed at:", template);

        // Deploy MemeFactory
        factory = address(new MemeFactory(
            template,
            config.router,
            config.weth,
            platformWallet
        ));
        console.log("MemeFactory deployed at:", factory);

        vm.stopBroadcast();
    }
}