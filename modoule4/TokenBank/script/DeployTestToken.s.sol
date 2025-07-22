// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {TestToken} from "../src/TestToken.sol";

contract DeployTestToken is Script {
    function run() external {
        vm.startBroadcast();
        
        TestToken testToken = new TestToken("Test Token", "TEST", 1000000);
        
        console.log("TestToken deployed to:", address(testToken));
        console.log("Initial supply:", testToken.totalSupply());
        
        vm.stopBroadcast();
    }
}