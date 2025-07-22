// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../contracts/UniswapV2Factory.sol";

contract DeployFactory is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address feeToSetter = vm.envAddress("FEE_TO_SETTER");
        
        vm.startBroadcast(deployerPrivateKey);
        
        UniswapV2Factory factory = new UniswapV2Factory(feeToSetter);
        
        vm.stopBroadcast();
        
        console.log("UniswapV2Factory deployed to:", address(factory));
        console.log("FeeToSetter:", feeToSetter);
        console.log("Factory deployed successfully");
    }
}