// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/tokens/TokenA.sol";
import "../src/tokens/TokenB.sol";
import "../src/tokens/TokenC.sol";
import "../src/PerfectArbitrage.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

interface IERC20Extended {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title Deploy - 一站式部署脚本
 * @dev 完整的FlashSwap项目部署，包含代币、交易对、流动性和合约
 */
contract DeployScript is Script {
    // QuickSwap地址（Polygon网络）
    address constant QUICKSWAP_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address constant QUICKSWAP_FACTORY = 0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32;
    
    // 部署的合约地址存储
    address public tokenA;
    address public tokenB; 
    address public tokenC;
    address public pairAB;
    address public pairBC;
    address public pairAC;
    address public flashSwapContract;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== FLASHSWAP PROJECT - ONE-CLICK DEPLOYMENT ===");
        console.log("Deployer:", deployer);
        console.log("Network: Polygon (QuickSwap)");
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 第一步：部署ERC20代币
        deployTokens();
        
        // 第二步：创建Uniswap交易对
        createPairs();
        
        // 第三步：添加初始流动性
        addInitialLiquidity(deployer);
        
        // 第四步：部署FlashSwap套利合约
        deployFlashSwapContract();
        
        vm.stopBroadcast();
        
        // 第五步：输出所有关键信息
        outputDeploymentInfo();
        
        console.log("=== DEPLOYMENT COMPLETED SUCCESSFULLY ===");
        console.log("Ready for arbitrage testing!");
    }
    
    /**
     * @notice 部署三个ERC20测试代币
     */
    function deployTokens() internal {
        console.log("Step 1: Deploying ERC20 Tokens...");
        
        // 部署TokenA（基础代币）
        TokenA _tokenA = new TokenA();
        tokenA = address(_tokenA);
        console.log("  TokenA deployed:", tokenA);
        
        // 部署TokenB（中间代币）  
        TokenB _tokenB = new TokenB();
        tokenB = address(_tokenB);
        console.log("  TokenB deployed:", tokenB);
        
        // 部署TokenC（目标代币）
        TokenC _tokenC = new TokenC();
        tokenC = address(_tokenC);
        console.log("  TokenC deployed:", tokenC);
        
        console.log("[SUCCESS] All tokens deployed successfully");
        console.log("");
    }
    
    /**
     * @notice 创建Uniswap V2交易对
     */
    function createPairs() internal {
        console.log("Step 2: Creating Uniswap V2 Pairs...");
        
        IUniswapV2Factory factory = IUniswapV2Factory(QUICKSWAP_FACTORY);
        
        // 检查是否已存在交易对，不存在则创建
        pairAB = factory.getPair(tokenA, tokenB);
        if (pairAB == address(0)) {
            pairAB = factory.createPair(tokenA, tokenB);
            console.log("  Created PairAB:", pairAB);
        } else {
            console.log("  Using existing PairAB:", pairAB);
        }
        
        pairBC = factory.getPair(tokenB, tokenC);
        if (pairBC == address(0)) {
            pairBC = factory.createPair(tokenB, tokenC);
            console.log("  Created PairBC:", pairBC);
        } else {
            console.log("  Using existing PairBC:", pairBC);
        }
        
        pairAC = factory.getPair(tokenA, tokenC);
        if (pairAC == address(0)) {
            pairAC = factory.createPair(tokenA, tokenC);
            console.log("  Created PairAC:", pairAC);
        } else {
            console.log("  Using existing PairAC:", pairAC);
        }
        
        console.log("[SUCCESS] All pairs created successfully");
        console.log("");
    }
    
    /**
     * @notice 添加Todo.md第四阶段指定的精心设计的流动性比例
     * @dev 实现极大套利空间：间接路径(A->C->B)比直接路径(A->B)获得更多收益
     */
    function addInitialLiquidity(address deployer) internal {
        console.log("Step 3: Adding Optimized Liquidity (Todo.md Stage 4)...");
        
        IUniswapV2Router02 router = IUniswapV2Router02(QUICKSWAP_ROUTER);
        uint256 deadline = block.timestamp + 3600;
        
        // 为每个代币铸造足够的数量
        TokenA(tokenA).mint(deployer, 10000 ether);
        TokenB(tokenB).mint(deployer, 10000 ether);
        TokenC(tokenC).mint(deployer, 10000 ether);
        
        // 批准路由器使用代币
        IERC20Extended(tokenA).approve(QUICKSWAP_ROUTER, type(uint256).max);
        IERC20Extended(tokenB).approve(QUICKSWAP_ROUTER, type(uint256).max);
        IERC20Extended(tokenC).approve(QUICKSWAP_ROUTER, type(uint256).max);
        
        console.log("  Adding liquidity with Todo.md specified ratios...");
        
        // PairAB: 1000 TokenA : 1500 TokenB (1 A = 1.5 B) - 直接路径基准
        console.log("  PairAB: 1000 A : 1500 B (1 A = 1.5 B) - Direct path");
        router.addLiquidity(
            tokenA, tokenB,
            1000 ether, 1500 ether,
            950 ether, 1425 ether,
            deployer, deadline
        );
        
        // PairBC: 1000 TokenB : 400 TokenC (1 B = 0.4 C) - 关键的套利环节
        console.log("  PairBC: 1000 B : 400 C (1 B = 0.4 C) - Key arbitrage link");
        router.addLiquidity(
            tokenB, tokenC,
            1000 ether, 400 ether,
            950 ether, 380 ether,
            deployer, deadline
        );
        
        // PairAC: 1000 TokenA : 1000 TokenC (1 A = 1 C) - 套利起点
        console.log("  PairAC: 1000 A : 1000 C (1 A = 1 C) - Arbitrage starting point");
        router.addLiquidity(
            tokenA, tokenC,
            1000 ether, 1000 ether,
            950 ether, 950 ether,
            deployer, deadline
        );
        
        console.log("[SUCCESS] Todo.md Stage 4 liquidity ratios applied");
        console.log("");
    }
    
    /**
     * @notice 部署FlashSwap套利合约
     */
    function deployFlashSwapContract() internal {
        console.log("Step 4: Deploying FlashSwap Arbitrage Contract...");
        
        // 部署PerfectArbitrage合约
        PerfectArbitrage arbitrage = new PerfectArbitrage(
            tokenA,
            tokenB, 
            tokenC,
            pairAB,
            pairBC,
            pairAC
        );
        
        flashSwapContract = address(arbitrage);
        console.log("  PerfectArbitrage deployed:", flashSwapContract);
        console.log("[SUCCESS] FlashSwap contract deployed successfully");
        console.log("");
    }
    
    /**
     * @notice 输出所有部署信息和环境变量设置
     */
    function outputDeploymentInfo() internal view {
        console.log("=== DEPLOYMENT SUMMARY ===");
        console.log("");
        console.log("[INFO] CONTRACT ADDRESSES:");
        console.log("TokenA:           ", tokenA);
        console.log("TokenB:           ", tokenB);
        console.log("TokenC:           ", tokenC);
        console.log("PairAB:           ", pairAB);
        console.log("PairBC:           ", pairBC);
        console.log("PairAC:           ", pairAC);
        console.log("FlashSwap:        ", flashSwapContract);
        console.log("");
        
        console.log("[CONFIG] ENVIRONMENT VARIABLES (.env file):");
        console.log("# Copy these to your .env file");
        console.log("TOKEN_A_ADDRESS=", tokenA);
        console.log("TOKEN_B_ADDRESS=", tokenB);
        console.log("TOKEN_C_ADDRESS=", tokenC);
        console.log("PAIR_AB_ADDRESS=", pairAB);
        console.log("PAIR_BC_ADDRESS=", pairBC);
        console.log("PAIR_AC_ADDRESS=", pairAC);
        console.log("FLASHSWAP_CONTRACT_ADDRESS=", flashSwapContract);
        console.log("");
        
        console.log("[DATA] LIQUIDITY CONFIGURATION (Todo.md Stage 4):");
        console.log("PairAB: 1000 A : 1500 B (1 A = 1.5 B) - Direct path");
        console.log("PairBC: 1000 B :  400 C (1 B = 0.4 C) - Key link");
        console.log("PairAC: 1000 A : 1000 C (1 A = 1.0 C) - Starting point");
        console.log("");
        
        console.log("[STRATEGY] MASSIVE ARBITRAGE OPPORTUNITY:");
        console.log("Direct path:   1 A -> 1.5 B (via PairAB)");
        console.log("Indirect path: 1 A -> 1 C -> 2.5 B (via PairAC->PairBC)");
        console.log("Arbitrage space: 2.5B - 1.5B = 1B profit per transaction!");
        console.log("");
        console.log("FlashSwap execution:");
        console.log("1. Borrow 1 TokenA via flashswap from PairAB");
        console.log("2. A -> C: 1 A -> ~0.997 C (via PairAC, minimal fee)");
        console.log("3. C -> B: 0.997 C -> ~2.49 B (via PairBC, huge gain!)");
        console.log("4. Repay: 1.003 A (0.3% fee) = ~0.67 B equivalent");
        console.log("5. Net profit: 2.49B - 0.67B = ~1.82B per arbitrage!");
        console.log("");
        
        console.log("[NEXT] TESTING STEPS:");
        console.log("1. Update .env with the addresses above");
        console.log("2. Run: forge script script/Test.s.sol --broadcast --fork-url https://polygon-rpc.com");
        console.log("3. Monitor arbitrage execution and profits");
    }
}