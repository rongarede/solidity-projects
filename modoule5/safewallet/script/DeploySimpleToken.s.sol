// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {SimpleToken} from "../src/SimpleToken.sol";

contract DeploySimpleToken is Script {
    function run() external returns (SimpleToken) {
        vm.startBroadcast();
        
        SimpleToken token = new SimpleToken(
            "Simple Token",
            "SIM",
            1000000
        );
        
        vm.stopBroadcast();
        return token;
    }
}