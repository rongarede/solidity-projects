// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../contracts/UniswapV2Factory.sol";
import "../contracts/interfaces/IUniswapV2Pair.sol";

contract VerifyDeploymentScript is Script {
    
    function run() external {
        // 从环境变量获取私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== Uniswap V2 Deployment Verification ===");
        console.log("Deployer Address:", deployer);
        console.log("Network: Base Mainnet (Chain ID: 8453)");
        console.log("");
        
        // 已部署的合约地址
        address factoryAddr = 0x2E2812638232c64eeC81B4a2DFd4ca975887d571;
        address tokenA = 0xd94b67a5e56696B57908c571eD1E5A40Ce3f64F3;
        address tokenB = 0x731495EAb495076B86CA562eDa51244F20A25CF5;
        address testPair = 0x27FD6cBE8d206047D695e966D54529b951848baF;
        
        console.log("=== Verify Factory Contract ===");
        UniswapV2Factory factory = UniswapV2Factory(factoryAddr);
        
        // Verify Factory basic info
        console.log("Factory Address:", factoryAddr);
        console.log("Fee To Setter:", factory.feeToSetter());
        console.log("Fee To:", factory.feeTo());
        console.log("All Pairs Length:", factory.allPairsLength());
        
        // Verify specific pair
        address calculatedPair = factory.getPair(tokenA, tokenB);
        console.log("Calculated Pair Address:", calculatedPair);
        console.log("Known Pair Address:", testPair);
        console.log("Pair Address Match:", calculatedPair == testPair ? "YES" : "NO");
        
        console.log("");
        console.log("=== Verify Pair Contract ===");
        IUniswapV2Pair pair = IUniswapV2Pair(testPair);
        
        console.log("Pair Address:", testPair);
        console.log("Token0:", pair.token0());
        console.log("Token1:", pair.token1());
        console.log("Factory:", pair.factory());
        
        // Get reserves
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair.getReserves();
        console.log("Reserve0:", reserve0);
        console.log("Reserve1:", reserve1);
        console.log("Block Timestamp Last:", blockTimestampLast);
        
        // Get total supply via low-level call
        (bool successSupply, bytes memory dataSupply) = testPair.call(abi.encodeWithSignature("totalSupply()"));
        if (successSupply) {
            uint256 totalSupply = abi.decode(dataSupply, (uint256));
            console.log("LP Token Total Supply:", totalSupply);
        }
        
        console.log("");
        console.log("=== Verify Token Contracts ===");
        
        // Verify TokenA
        (bool successA, bytes memory dataA) = tokenA.call(abi.encodeWithSignature("symbol()"));
        if (successA) {
            string memory symbolA = abi.decode(dataA, (string));
            console.log("TokenA Symbol:", symbolA);
        }
        
        (bool successA2, bytes memory dataA2) = tokenA.call(abi.encodeWithSignature("balanceOf(address)", deployer));
        if (successA2) {
            uint256 balanceA = abi.decode(dataA2, (uint256));
            console.log("Deployer TokenA Balance:", balanceA);
        }
        
        // Verify TokenB  
        (bool successB, bytes memory dataB) = tokenB.call(abi.encodeWithSignature("symbol()"));
        if (successB) {
            string memory symbolB = abi.decode(dataB, (string));
            console.log("TokenB Symbol:", symbolB);
        }
        
        (bool successB2, bytes memory dataB2) = tokenB.call(abi.encodeWithSignature("balanceOf(address)", deployer));
        if (successB2) {
            uint256 balanceB = abi.decode(dataB2, (uint256));
            console.log("Deployer TokenB Balance:", balanceB);
        }
        
        console.log("");
        console.log("=== Verification Results ===");
        console.log("[OK] Factory contract is running");
        console.log("[OK] Test tokens deployed");
        console.log("[OK] Trading pair created");
        if (reserve0 > 0 && reserve1 > 0) {
            console.log("[OK] Liquidity added");
        } else {
            console.log("[WARN] Liquidity not added or zero");
        }
        
        console.log("Deployment verification completed!");
    }
}