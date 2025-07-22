// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {esRNT} from "../src/ReadLock.sol";

contract ReadLockScript is Script {
    esRNT public readLock;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        readLock = new esRNT();

        console.log("ReadLock deployed to:", address(readLock));

        vm.stopBroadcast();
    }
}