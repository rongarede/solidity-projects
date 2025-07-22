// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../contracts/UniswapV2Router02.sol";
import "../test/mocks/MockWETH.sol";

contract DeployRouter is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // From contracts-addresses.json
        address factory = 0x2E2812638232c64eeC81B4a2DFd4ca975887d571;
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy MockWETH first
        MockWETH mockWETH = new MockWETH();
        console.log("MockWETH deployed to:", address(mockWETH));
        
        // Deploy Router with MockWETH
        UniswapV2Router02 router = new UniswapV2Router02(factory, address(mockWETH));
        
        vm.stopBroadcast();
        
        console.log("UniswapV2Router02 deployed to:", address(router));
        console.log("Factory address:", factory);
        console.log("MockWETH address:", address(mockWETH));
        console.log("Router deployed successfully with MockWETH");
    }
}