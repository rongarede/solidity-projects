// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../contracts/UniswapV2Pair.sol";

contract GetInitCodeHash is Script {
    function run() external {
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 hash = keccak256(bytecode);
        console.log("UniswapV2Pair init code hash:");
        console.logBytes32(hash);
        console.log("Hex representation:");
        console.log("hex'%s'", vm.toString(hash));
    }
}