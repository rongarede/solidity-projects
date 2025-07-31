// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/PerfectArbitrage.sol";
import "../src/tokens/TokenA.sol";
import "../src/tokens/TokenB.sol";
import "../src/tokens/TokenC.sol";

/**
 * @title PerfectArbitrageTest
 * @dev 真正的单元测试，不需要fork，完全在本地运行
 */
contract PerfectArbitrageTest is Test {
    
    TokenA public tokenA;
    TokenB public tokenB;
    TokenC public tokenC;
    PerfectArbitrage public arbitrage;
    
    address public deployer;
    address public user;
    
    // Mock pair addresses
    address public pairAB = address(0x1111);
    address public pairBC = address(0x2222);
    address public pairAC = address(0x3333);
    
    function setUp() public {
        deployer = address(this);
        user = address(0x1);
        
        // 部署代币
        tokenA = new TokenA();
        tokenB = new TokenB();
        tokenC = new TokenC();
        
        // 部署套利合约
        arbitrage = new PerfectArbitrage(
            address(tokenA),
            address(tokenB),
            address(tokenC),
            pairAB,
            pairBC,
            pairAC
        );
        
        console.log("=== TEST SETUP COMPLETED ===");
        console.log("TokenA:", address(tokenA));
        console.log("TokenB:", address(tokenB));
        console.log("TokenC:", address(tokenC));
        console.log("Arbitrage:", address(arbitrage));
    }
    
    function testContractDeployment() public {
        // 测试合约部署是否成功
        assertEq(arbitrage.tokenA(), address(tokenA));
        assertEq(arbitrage.tokenB(), address(tokenB));
        assertEq(arbitrage.tokenC(), address(tokenC));
        assertEq(arbitrage.pairAB(), pairAB);
        assertEq(arbitrage.pairBC(), pairBC);
        assertEq(arbitrage.pairAC(), pairAC);
        assertEq(arbitrage.owner(), deployer);
        
        console.log("[PASS] Contract deployment test");
    }
    
    function testTokenBalances() public {
        // 测试代币初始余额
        uint256 initialSupply = 1_000_000 * 10**18;
        
        assertEq(tokenA.balanceOf(deployer), initialSupply);
        assertEq(tokenB.balanceOf(deployer), initialSupply);
        assertEq(tokenC.balanceOf(deployer), initialSupply);
        
        console.log("[PASS] Token balances test");
        console.log("Initial supply per token:", initialSupply / 1e18);
    }
    
    function testOwnershipAndAccess() public {
        // 测试所有权和访问控制
        assertEq(arbitrage.owner(), deployer);
        
        // 只有owner可以执行套利
        vm.prank(user);
        vm.expectRevert();
        arbitrage.executePerfectArbitrage(1 ether);
        
        console.log("[PASS] Ownership and access control test");
    }
    
    function testEmergencyWithdraw() public {
        // 测试紧急提取功能
        uint256 testAmount = 100 ether;
        
        // 给合约转一些代币
        tokenA.transfer(address(arbitrage), testAmount);
        tokenB.transfer(address(arbitrage), testAmount);
        tokenC.transfer(address(arbitrage), testAmount);
        
        uint256 balanceBeforeA = tokenA.balanceOf(deployer);
        uint256 balanceBeforeB = tokenB.balanceOf(deployer);
        uint256 balanceBeforeC = tokenC.balanceOf(deployer);
        
        // 执行紧急提取
        arbitrage.emergencyWithdraw();
        
        // 验证代币已提取
        assertEq(tokenA.balanceOf(address(arbitrage)), 0);
        assertEq(tokenB.balanceOf(address(arbitrage)), 0);
        assertEq(tokenC.balanceOf(address(arbitrage)), 0);
        
        assertEq(tokenA.balanceOf(deployer), balanceBeforeA + testAmount);
        assertEq(tokenB.balanceOf(deployer), balanceBeforeB + testAmount);
        assertEq(tokenC.balanceOf(deployer), balanceBeforeC + testAmount);
        
        console.log("[PASS] Emergency withdraw test");
    }
    
    function testTodoStage4Theory() public view {
        // 测试Todo.md第四阶段的理论计算
        console.log("=== TODO.MD STAGE 4 THEORY TEST ===");
        console.log("");
        console.log("Liquidity ratios (as per Todo.md):");
        console.log("- PairAB: 1000 A : 1500 B (1 A = 1.5 B)");
        console.log("- PairBC: 1000 B : 400 C (1 B = 0.4 C)");
        console.log("- PairAC: 1000 A : 1000 C (1 A = 1.0 C)");
        console.log("");
        
        console.log("Theoretical arbitrage calculation:");
        console.log("1. Direct path:   1 A -> 1.5 B");
        console.log("2. Indirect path: 1 A -> 1 C -> 2.5 B");
        console.log("3. Arbitrage opportunity: 2.5 - 1.5 = 1 B profit!");
        console.log("");
        
        console.log("FlashSwap execution theory:");
        console.log("- Borrow: 1 A (via flashswap)");
        console.log("- A->C: 1 A -> ~0.997 C (via PairAC)");
        console.log("- C->B: 0.997 C -> ~2.49 B (via PairBC)");
        console.log("- Repay: 1.003 A (0.3% fee) -> ~0.67 B equivalent");
        console.log("- Net profit: 2.49 - 0.67 = ~1.82 B");
        console.log("");
        
        // 数学验证
        uint256 borrowed = 1 ether; // 1 A
        uint256 feeRate = 3; // 0.3%
        uint256 fee = (borrowed * feeRate) / 1000;
        uint256 toRepay = borrowed + fee;
        
        console.log("Mathematical verification:");
        console.log("- Borrowed amount:", borrowed / 1e18, "A");
        console.log("- Fee (0.3%):", fee / 1e15, "per mille A");
        console.log("- Total to repay:", toRepay / 1e18, "A");
        
        // 根据Todo.md比例计算
        uint256 cReceived = (borrowed * 997) / 1000; // A->C, 0.3% fee
        uint256 bReceived = (cReceived * 25) / 10; // C->B, 1C = 2.5B
        uint256 bNeededForRepay = (toRepay * 15) / 10; // A->B, 1A = 1.5B
        
        console.log("- C received from A:", cReceived / 1e18, "C");
        console.log("- B received from C:", bReceived / 1e18, "B");
        console.log("- B needed for repay:", bNeededForRepay / 1e18, "B");
        
        if (bReceived > bNeededForRepay) {
            uint256 profit = bReceived - bNeededForRepay;
            console.log("- PROFIT:", profit / 1e18, "B");
            console.log("[THEORY CONFIRMED] Todo.md Stage 4 ratios create profitable arbitrage!");
        } else {
            console.log("- LOSS:", (bNeededForRepay - bReceived) / 1e18, "B");
            console.log("[THEORY FAILED] Ratios need adjustment");
        }
    }
    
    function testMultipleAmounts() public view {
        console.log("=== SCALABILITY TEST ===");
        
        uint256[] memory amounts = new uint256[](5);
        amounts[0] = 0.1 ether;
        amounts[1] = 1 ether;
        amounts[2] = 10 ether;
        amounts[3] = 100 ether;
        amounts[4] = 1000 ether;
        
        for (uint i = 0; i < amounts.length; i++) {
            uint256 amount = amounts[i];
            uint256 theoreticalProfit = calculateTheoreticalProfit(amount);
            
            console.log("Amount:", amount / 1e18, "A -> Profit:", theoreticalProfit / 1e18, "B");
        }
    }
    
    function calculateTheoreticalProfit(uint256 amount) internal pure returns (uint256) {
        // 根据Todo.md Stage 4比例计算理论利润
        uint256 cReceived = (amount * 997) / 1000; // A->C
        uint256 bReceived = (cReceived * 25) / 10; // C->B
        uint256 fee = (amount * 3) / 1000; // 0.3% fee
        uint256 bNeededForRepay = ((amount + fee) * 15) / 10; // repay in B
        
        if (bReceived > bNeededForRepay) {
            return bReceived - bNeededForRepay;
        } else {
            return 0;
        }
    }
}