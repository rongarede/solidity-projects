// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/PerfectArbitrage.sol";

interface IERC20Extended {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IUniswapV2PairExtended {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

/**
 * @title Test - 套利测试脚本
 * @dev 完整的FlashSwap套利测试，包含执行、验证和调试功能
 */
contract TestScript is Script {
    
    // 从环境变量读取的合约地址
    address public tokenA;
    address public tokenB;
    address public tokenC;
    address public pairAB;
    address public pairBC;
    address public pairAC;
    address public flashSwapContract;
    address public deployer;
    
    // 测试参数
    uint256 public testAmount = 1 ether; // 默认测试1个TokenA
    
    function run() external {
        // 读取环境变量
        loadEnvironmentVariables();
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== FLASHSWAP ARBITRAGE TEST ===");
        console.log("Testing contract:", flashSwapContract);
        console.log("Strategy: A -> C -> B -> A");
        console.log("Test amount:", testAmount);
        console.log("");
        
        // 步骤1：预执行分析
        analyzeArbitrageOpportunity();
        
        // 步骤2：显示初始状态
        displayInitialState();
        
        // 步骤3：执行套利
        vm.startBroadcast(deployerPrivateKey);
        executeArbitrage();
        vm.stopBroadcast();
        
        // 步骤4：分析结果
        analyzeResults();
        
        console.log("=== TEST COMPLETED ===");
    }
    
    /**
     * @notice 从环境变量加载所有合约地址
     */
    function loadEnvironmentVariables() internal {
        tokenA = vm.envAddress("TOKEN_A_ADDRESS");
        tokenB = vm.envAddress("TOKEN_B_ADDRESS");
        tokenC = vm.envAddress("TOKEN_C_ADDRESS");
        pairAB = vm.envAddress("PAIR_AB_ADDRESS");
        pairBC = vm.envAddress("PAIR_BC_ADDRESS");
        pairAC = vm.envAddress("PAIR_AC_ADDRESS");
        flashSwapContract = vm.envAddress("FLASHSWAP_CONTRACT_ADDRESS");
        
        console.log("[INFO] Loaded addresses from environment:");
        console.log("  TokenA:", tokenA);
        console.log("  TokenB:", tokenB);
        console.log("  TokenC:", tokenC);
        console.log("  FlashSwap:", flashSwapContract);
        console.log("");
    }
    
    /**
     * @notice 分析套利机会，计算预期收益
     */
    function analyzeArbitrageOpportunity() internal view {
        console.log("[ANALYSIS] ARBITRAGE OPPORTUNITY ANALYSIS");
        console.log("");
        
        // 首先验证合约是否存在
        if (!contractExists(pairAB)) {
            console.log("[ERROR] PairAB contract does not exist at:", pairAB);
            return;
        }
        if (!contractExists(pairBC)) {
            console.log("[ERROR] PairBC contract does not exist at:", pairBC);
            return;
        }
        if (!contractExists(pairAC)) {
            console.log("[ERROR] PairAC contract does not exist at:", pairAC);
            return;
        }
        
        console.log("[VERIFICATION] All pair contracts exist, proceeding with analysis...");
        
        // 获取各个池子的储备量 (添加错误处理)
        (uint112 reserveAB0, uint112 reserveAB1,) = tryGetReserves(pairAB, "PairAB");
        (uint112 reserveBC0, uint112 reserveBC1,) = tryGetReserves(pairBC, "PairBC");
        (uint112 reserveAC0, uint112 reserveAC1,) = tryGetReserves(pairAC, "PairAC");
        
        address token0AB = IUniswapV2PairExtended(pairAB).token0();
        address token0BC = IUniswapV2PairExtended(pairBC).token0();
        address token0AC = IUniswapV2PairExtended(pairAC).token0();
        
        console.log("[RESERVES] POOL RESERVES:");
        
        // PairAB储备
        if (token0AB == tokenA) {
            console.log("  PairAB: TokenA =", uint256(reserveAB0), "TokenB =", uint256(reserveAB1));
            console.log("    Rate: 1 A =", (uint256(reserveAB1) * 1e18) / uint256(reserveAB0), "B");
        } else {
            console.log("  PairAB: TokenA =", uint256(reserveAB1), "TokenB =", uint256(reserveAB0));
            console.log("    Rate: 1 A =", (uint256(reserveAB0) * 1e18) / uint256(reserveAB1), "B");
        }
        
        // PairBC储备
        if (token0BC == tokenB) {
            console.log("  PairBC: TokenB =", uint256(reserveBC0), "TokenC =", uint256(reserveBC1));
            console.log("    Rate: 1 B =", (uint256(reserveBC1) * 1e18) / uint256(reserveBC0), "C");
        } else {
            console.log("  PairBC: TokenB =", uint256(reserveBC1), "TokenC =", uint256(reserveBC0));
            console.log("    Rate: 1 B =", (uint256(reserveBC0) * 1e18) / uint256(reserveBC1), "C");
        }
        
        // PairAC储备
        if (token0AC == tokenA) {
            console.log("  PairAC: TokenA =", uint256(reserveAC0), "TokenC =", uint256(reserveAC1));
            console.log("    Rate: 1 A =", (uint256(reserveAC1) * 1e18) / uint256(reserveAC0), "C");
        } else {
            console.log("  PairAC: TokenA =", uint256(reserveAC1), "TokenC =", uint256(reserveAC0));
            console.log("    Rate: 1 A =", (uint256(reserveAC0) * 1e18) / uint256(reserveAC1), "C");
        }
        
        console.log("");
        console.log("[SIMULATION] ARBITRAGE PATH SIMULATION:");
        simulateArbitragePath();
        console.log("");
    }
    
    /**
     * @notice 模拟套利路径，预测收益
     */
    function simulateArbitragePath() internal view {
        console.log("  Simulating path for", testAmount / 1e18, "TokenA...");
        
        // 这里可以添加详细的数学计算来预测套利结果
        // 由于涉及复杂的AMM公式，这里提供框架
        
        uint256 estimatedTokenC = calculateAtoC(testAmount);
        uint256 estimatedTokenB = calculateCtoB(estimatedTokenC);
        uint256 feeAmount = (testAmount * 3) / 997 + 1;
        uint256 repayAmount = testAmount + feeAmount;
        
        console.log("  1. A->C:", testAmount / 1e18);
        console.log("     Output:", estimatedTokenC / 1e18, "C");
        console.log("  2. C->B:", estimatedTokenC / 1e18);
        console.log("     Output:", estimatedTokenB / 1e18, "B");
        console.log("  3. Need to repay:", repayAmount / 1e18, "A (including 0.3% fee)");
        
        if (estimatedTokenB > repayAmount) {
            console.log("  [SUCCESS] PROFITABLE! Estimated profit:", (estimatedTokenB - repayAmount) / 1e18, "TokenB");
        } else {
            console.log("  [WARNING] NOT PROFITABLE. Loss:", (repayAmount - estimatedTokenB) / 1e18, "TokenB");
            console.log("  [TIP] Try smaller amount or check pool ratios");
        }
    }
    
    /**
     * @notice 计算A->C的预期输出（简化版）
     */
    function calculateAtoC(uint256 amountA) internal view returns (uint256) {
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2PairExtended(pairAC).getReserves();
        address token0 = IUniswapV2PairExtended(pairAC).token0();
        
        if (token0 == tokenA) {
            return getAmountOut(amountA, uint256(reserve0), uint256(reserve1));
        } else {
            return getAmountOut(amountA, uint256(reserve1), uint256(reserve0));
        }
    }
    
    /**
     * @notice 计算C->B的预期输出（简化版）
     */
    function calculateCtoB(uint256 amountC) internal view returns (uint256) {
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2PairExtended(pairBC).getReserves();
        address token0 = IUniswapV2PairExtended(pairBC).token0();
        
        if (token0 == tokenC) {
            return getAmountOut(amountC, uint256(reserve0), uint256(reserve1));
        } else {
            return getAmountOut(amountC, uint256(reserve1), uint256(reserve0));
        }
    }
    
    /**
     * @notice Uniswap V2 AmountOut计算公式
     */
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256) {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        return numerator / denominator;
    }
    
    /**
     * @notice 显示所有账户的初始余额
     */
    function displayInitialState() internal view {
        console.log("[BALANCES] INITIAL BALANCES:");
        console.log("  Deployer TokenA:", IERC20Extended(tokenA).balanceOf(deployer) / 1e18);
        console.log("  Deployer TokenB:", IERC20Extended(tokenB).balanceOf(deployer) / 1e18);
        console.log("  Deployer TokenC:", IERC20Extended(tokenC).balanceOf(deployer) / 1e18);
        console.log("  Contract TokenA:", IERC20Extended(tokenA).balanceOf(flashSwapContract) / 1e18);
        console.log("  Contract TokenB:", IERC20Extended(tokenB).balanceOf(flashSwapContract) / 1e18);
        console.log("  Contract TokenC:", IERC20Extended(tokenC).balanceOf(flashSwapContract) / 1e18);
        console.log("");
    }
    
    /**
     * @notice 执行FlashSwap套利
     */
    function executeArbitrage() internal {
        console.log("[EXECUTE] EXECUTING FLASHSWAP ARBITRAGE...");
        console.log("  Amount:", testAmount / 1e18, "TokenA");
        console.log("");
        
        PerfectArbitrage arbitrage = PerfectArbitrage(flashSwapContract);
        
        try arbitrage.executePerfectArbitrage(testAmount) {
            console.log("[SUCCESS] Arbitrage executed successfully!");
        } catch Error(string memory reason) {
            console.log("[ERROR] Arbitrage failed:");
            console.log("  Reason:", reason);
            console.log("  [TIP] Try adjusting the test amount or check pool liquidity");
        } catch (bytes memory lowLevelData) {
            console.log("[ERROR] Arbitrage failed with low-level error");
            console.log("  [TIP] Check contract state and pool configurations");
            // 可以添加更详细的错误解析
            if (lowLevelData.length > 0) {
                console.log("  Error data length:", lowLevelData.length);
            }
        }
        
        console.log("");
    }
    
    /**
     * @notice 分析执行结果
     */
    function analyzeResults() internal view {
        console.log("[RESULTS] FINAL ANALYSIS:");
        
        // 显示最终余额
        uint256 finalDeployerA = IERC20Extended(tokenA).balanceOf(deployer);
        uint256 finalDeployerB = IERC20Extended(tokenB).balanceOf(deployer);
        uint256 finalDeployerC = IERC20Extended(tokenC).balanceOf(deployer);
        uint256 finalContractA = IERC20Extended(tokenA).balanceOf(flashSwapContract);
        uint256 finalContractB = IERC20Extended(tokenB).balanceOf(flashSwapContract);
        uint256 finalContractC = IERC20Extended(tokenC).balanceOf(flashSwapContract);
        
        console.log("[BALANCES] FINAL BALANCES:");
        console.log("  Deployer TokenA:", finalDeployerA / 1e18);
        console.log("  Deployer TokenB:", finalDeployerB / 1e18);
        console.log("  Deployer TokenC:", finalDeployerC / 1e18);
        console.log("  Contract TokenA:", finalContractA / 1e18);
        console.log("  Contract TokenB:", finalContractB / 1e18);
        console.log("  Contract TokenC:", finalContractC / 1e18);
        console.log("");
        
        // 计算净收益
        if (finalContractA > 0 || finalContractB > 0 || finalContractC > 0) {
            console.log("[PROFIT] PROFIT DETECTED IN CONTRACT:");
            if (finalContractA > 0) console.log("  TokenA profit:", finalContractA / 1e18);
            if (finalContractB > 0) console.log("  TokenB profit:", finalContractB / 1e18);
            if (finalContractC > 0) console.log("  TokenC profit:", finalContractC / 1e18);
        } else {
            console.log("[INFO] No tokens remaining in contract");
            console.log("   (Profits may have been transferred to deployer)");
        }
        
        console.log("");
        console.log("[DEBUG] DEBUGGING TIPS:");
        console.log("  1. If failed: Check pool liquidity ratios");
        console.log("  2. If failed: Try smaller test amounts");
        console.log("  3. If failed: Verify all addresses are correct");
        console.log("  4. Monitor gas usage for optimization");
        console.log("  5. Check transaction traces for detailed execution flow");
    }
    
    /**
     * @notice 设置自定义测试金额
     * @param amount 测试金额（以TokenA为单位）
     */
    function setTestAmount(uint256 amount) external {
        testAmount = amount;
        console.log("Test amount updated to:", amount / 1e18, "TokenA");
    }
    
    /**
     * @notice 快速测试多个金额
     */
    function runMultipleTests() external {
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 0.1 ether;   // 0.1 TokenA
        amounts[1] = 0.5 ether;   // 0.5 TokenA  
        amounts[2] = 1 ether;     // 1 TokenA
        amounts[3] = 5 ether;     // 5 TokenA
        
        for (uint i = 0; i < amounts.length; i++) {
            console.log("=== TESTING WITH", amounts[i] / 1e18, "TokenA ===");
            testAmount = amounts[i];
            this.run();
            console.log("");
        }
    }
}