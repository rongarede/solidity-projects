// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../test/mocks/MockWETH.sol";

contract DeployMockWETHPolygon is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy MockWETH for Polygon
        MockWETH mockWETH = new MockWETH();
        
        vm.stopBroadcast();
        
        console.log("=== Polygon MockWETH Deployment ===");
        console.log("MockWETH deployed to:", address(mockWETH));
        console.log("Chain ID:", block.chainid);
        console.log("Name:", mockWETH.name());
        console.log("Symbol:", mockWETH.symbol());
        console.log("Decimals:", mockWETH.decimals());
        
        console.log("MockWETH deployment successful on Polygon!");
        console.log("Next: Update WETH_ADDRESS in .env and contracts.ts");
    }
}