// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {TokenBank} from "../src/TokenBank.sol";

contract DeployTokenBank is Script {
    function run() external {
        vm.startBroadcast();
        
        TokenBank tokenBank = new TokenBank();
        
        console.log("TokenBank deployed to:", address(tokenBank));
        
        vm.stopBroadcast();
    }
}