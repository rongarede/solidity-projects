// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/SimpleTWAPOracle.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("Deploying to network with chain ID:", block.chainid);
        console.log("Deployer address:", vm.addr(deployerPrivateKey));
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy SimpleTWAPOracle
        SimpleTWAPOracle oracle = new SimpleTWAPOracle();
        
        console.log("SimpleTWAPOracle deployed at:", address(oracle));
        console.log("Owner:", oracle.owner());
        console.log("DAI address:", oracle.DAI());
        console.log("WMATIC address:", oracle.WMATIC());
        console.log("Factory address:", oracle.FACTORY());
        console.log("Time window:", oracle.TIME_WINDOW());
        
        vm.stopBroadcast();
        
        // Note: To verify the pair exists, you can call:
        // cast call $FACTORY "getPair(address,address)(address)" $DAI $WMATIC --rpc-url $RPC_URL
        console.log("To verify DAI/WMATIC pair exists, run:");
        console.log("To verify DAI/WMATIC pair exists on Polygon:");
    }
}