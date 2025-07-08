// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/SimpleNFT.sol";

contract DeploySimpleNFT is Script {
    function run() external {
        vm.startBroadcast();
        
        SimpleNFT nft = new SimpleNFT(
            "My Simple NFT",
            "MSN",
            "https://api.example.com/metadata/"
        );
        
        console.log("SimpleNFT deployed at:", address(nft));
        
        vm.stopBroadcast();
    }
}
