// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../contracts/UniswapV2Factory.sol";

contract DeployFactoryPolygon is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address feeToSetter = vm.envAddress("FEE_TO_SETTER");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy Factory
        UniswapV2Factory factory = new UniswapV2Factory(feeToSetter);
        
        vm.stopBroadcast();
        
        console.log("=== Polygon Factory Deployment ===");
        console.log("UniswapV2Factory deployed to:", address(factory));
        console.log("Fee to setter:", feeToSetter);
        console.log("Chain ID:", block.chainid);
        console.log("Gas used for Factory deployment");
        
        // Verification
        require(factory.feeToSetter() == feeToSetter, "Fee to setter not set correctly");
        console.log("Factory deployment verification successful!");
        
        console.log("Next step: Set FACTORY_ADDRESS in .env:");
        console.log("FACTORY_ADDRESS=", address(factory));
    }
}