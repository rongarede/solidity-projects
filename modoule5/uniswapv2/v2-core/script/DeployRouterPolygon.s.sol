// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../contracts/UniswapV2Router02.sol";

contract DeployRouterPolygon is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Factory will be deployed separately for Polygon
        address factory = vm.envAddress("FACTORY_ADDRESS"); // Set in .env after factory deployment
        
        // Use our new MockWETH with initial supply
        address mockWETH = 0xaEC13518815Fb88ad241dC945e00dAe350c426Db;
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy Router with our MockWETH
        UniswapV2Router02 router = new UniswapV2Router02(factory, mockWETH);
        
        vm.stopBroadcast();
        
        console.log("=== Polygon Router Deployment ===");
        console.log("UniswapV2Router02 deployed to:", address(router));
        console.log("Factory address:", factory);
        console.log("MockWETH address:", mockWETH);
        console.log("Chain ID:", block.chainid);
        console.log("Gas used for Router deployment");
        console.log("Router deployed successfully on Polygon with MockWETH");
    }
}