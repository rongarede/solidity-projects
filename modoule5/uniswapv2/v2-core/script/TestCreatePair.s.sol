// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../contracts/UniswapV2Factory.sol";

contract TestCreatePair is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // 已部署的合约地址
        address factoryAddress = 0x2E2812638232c64eeC81B4a2DFd4ca975887d571;
        address tokenA = 0xd94b67a5e56696B57908c571eD1E5A40Ce3f64F3;
        address tokenB = 0x731495EAb495076B86CA562eDa51244F20A25CF5;
        
        vm.startBroadcast(deployerPrivateKey);
        
        UniswapV2Factory factory = UniswapV2Factory(factoryAddress);
        
        console.log("Factory address:", address(factory));
        console.log("Token A address:", tokenA);
        console.log("Token B address:", tokenB);
        console.log("Pairs before creation:", factory.allPairsLength());
        
        // 创建交易对
        address pair = factory.createPair(tokenA, tokenB);
        
        console.log("Pair created at:", pair);
        console.log("Pairs after creation:", factory.allPairsLength());
        console.log("getPair(A, B):", factory.getPair(tokenA, tokenB));
        console.log("getPair(B, A):", factory.getPair(tokenB, tokenA));
        
        vm.stopBroadcast();
        
        console.log("CreatePair test completed successfully!");
    }
}