// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../test/mocks/MockWETHWithInitialSupply.sol";

contract DeployMockWETHWithSupplyPolygon is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy MockWETH with 1 million initial supply to deployer
        uint256 initialSupply = 1000000 * 10**18; // 1 million WETH
        MockWETHWithInitialSupply mockWETH = new MockWETHWithInitialSupply(deployer, initialSupply);
        
        vm.stopBroadcast();
        
        console.log("=== Polygon MockWETH With Initial Supply Deployment ===");
        console.log("MockWETH deployed to:", address(mockWETH));
        console.log("Initial owner:", deployer);
        console.log("Initial supply:", initialSupply / 10**18, "WETH");
        console.log("Chain ID:", block.chainid);
        console.log("Name:", mockWETH.name());
        console.log("Symbol:", mockWETH.symbol());
        console.log("Decimals:", mockWETH.decimals());
        console.log("Total supply:", mockWETH.totalSupply() / 10**18, "WETH");
        console.log("Owner balance:", mockWETH.balanceOf(deployer) / 10**18, "WETH");
        
        console.log("MockWETH with initial supply deployment successful!");
        console.log("Next: Update WETH address in contracts.ts to:", address(mockWETH));
    }
}