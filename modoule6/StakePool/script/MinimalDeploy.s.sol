// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {MockWETH} from "../src/MockWETH.sol";
import {KKToken} from "../src/KKToken.sol";
import {StakingPool} from "../src/StakingPool.sol";

contract MinimalDeploy is Script {
    function run() public {
        string memory privateKeyStr = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(string.concat("0x", privateKeyStr));
        address deployer = vm.addr(deployerPrivateKey);
        
        console2.log("Deploying with:", deployer);
        console2.log("Balance:", deployer.balance);
        console2.log("Chain ID:", block.chainid);
        
        vm.startBroadcast(deployerPrivateKey);
        
        MockWETH weth = new MockWETH();
        console2.log("WETH deployed:", address(weth));
        
        KKToken kkToken = new KKToken(deployer);
        console2.log("KKToken deployed:", address(kkToken));
        
        StakingPool stakingPool = new StakingPool(payable(address(weth)), address(kkToken), deployer);
        console2.log("StakingPool deployed:", address(stakingPool));
        
        kkToken.grantMinterRole(address(stakingPool));
        console2.log("Permissions granted");
        
        vm.stopBroadcast();
        
        console2.log("=== DEPLOYMENT COMPLETE ===");
        console2.log("WETH:        ", address(weth));
        console2.log("KKToken:     ", address(kkToken));
        console2.log("StakingPool: ", address(stakingPool));
    }
}