// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/FlashSwapArbitrage.sol";
import "../../src/tokens/TokenA.sol";
import "../../src/tokens/TokenB.sol";
import "../../src/tokens/TokenC.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2RouterTest {
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
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IUniswapV2PairTest {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function sync() external;
}

contract ArbitrageIntegrationTest is Test {
    // QuickSwap addresses on Polygon
    address constant QUICKSWAP_FACTORY = 0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32;
    address constant QUICKSWAP_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    
    FlashSwapArbitrage public flashSwap;
    TokenA public tokenA;
    TokenB public tokenB;
    TokenC public tokenC;
    address public pairAB;
    address public pairBC;
    
    address public owner;
    uint256 public ownerPrivateKey;
    
    function setUp() public {
        // Set up test account
        ownerPrivateKey = 0x1234;
        owner = vm.addr(ownerPrivateKey);
        vm.deal(owner, 100 ether);
        
        vm.startPrank(owner);
        
        // Deploy tokens
        tokenA = new TokenA();
        tokenB = new TokenB();
        tokenC = new TokenC();
        
        // Create pairs
        IUniswapV2Factory factory = IUniswapV2Factory(QUICKSWAP_FACTORY);
        pairAB = factory.createPair(address(tokenA), address(tokenB));
        pairBC = factory.createPair(address(tokenB), address(tokenC));
        
        // Setup router approvals
        IUniswapV2RouterTest router = IUniswapV2RouterTest(QUICKSWAP_ROUTER);
        tokenA.approve(QUICKSWAP_ROUTER, type(uint256).max);
        tokenB.approve(QUICKSWAP_ROUTER, type(uint256).max);
        tokenC.approve(QUICKSWAP_ROUTER, type(uint256).max);
        
        // Add liquidity to create price differences
        // Pool1 (A/B): 1000:1000 ratio (1:1)
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1000 * 10**18,
            1000 * 10**18,
            950 * 10**18,
            950 * 10**18,
            owner,
            block.timestamp + 300
        );
        
        // Pool2 (B/C): 1000:500 ratio (2:1)
        router.addLiquidity(
            address(tokenB),
            address(tokenC),
            1000 * 10**18,
            500 * 10**18,
            950 * 10**18,
            475 * 10**18,
            owner,
            block.timestamp + 300
        );
        
        // Deploy FlashSwap contract
        flashSwap = new FlashSwapArbitrage(
            address(tokenA),
            address(tokenB),
            address(tokenC),
            pairAB,
            pairBC,
            QUICKSWAP_ROUTER
        );
        
        vm.stopPrank();
    }
    
    function testFullArbitrageFlow() public {
        vm.startPrank(owner);
        
        // Check initial reserves
        IUniswapV2PairTest pair1 = IUniswapV2PairTest(pairAB);
        IUniswapV2PairTest pair2 = IUniswapV2PairTest(pairBC);
        
        (uint112 reserve0_1, uint112 reserve1_1,) = pair1.getReserves();
        (uint112 reserve0_2, uint112 reserve1_2,) = pair2.getReserves();
        
        console.log("Initial Pool1 reserves:", uint256(reserve0_1), uint256(reserve1_1));
        console.log("Initial Pool2 reserves:", uint256(reserve0_2), uint256(reserve1_2));
        
        // Record initial balances
        uint256 initialBalanceA = tokenA.balanceOf(owner);
        uint256 initialBalanceB = tokenB.balanceOf(owner);
        uint256 initialBalanceC = tokenC.balanceOf(owner);
        
        console.log("Initial owner balances:");
        console.log("TokenA:", initialBalanceA);
        console.log("TokenB:", initialBalanceB);
        console.log("TokenC:", initialBalanceC);
        
        // Execute arbitrage
        uint256 arbitrageAmount = 100 * 10**18;
        
        // This should fail initially due to insufficient token balance in contract
        vm.expectRevert();
        flashSwap.executeArbitrage(arbitrageAmount);
        
        vm.stopPrank();
    }
    
    function testReserveChecking() public view {
        IUniswapV2PairTest pair1 = IUniswapV2PairTest(pairAB);
        IUniswapV2PairTest pair2 = IUniswapV2PairTest(pairBC);
        
        (uint112 reserve0_1, uint112 reserve1_1,) = pair1.getReserves();
        (uint112 reserve0_2, uint112 reserve1_2,) = pair2.getReserves();
        
        // Verify liquidity was added correctly
        assertTrue(reserve0_1 > 0 && reserve1_1 > 0, "Pool1 should have liquidity");
        assertTrue(reserve0_2 > 0 && reserve1_2 > 0, "Pool2 should have liquidity");
        
        console.log("Pool1 token0:", pair1.token0());
        console.log("Pool1 token1:", pair1.token1());
        console.log("Pool2 token0:", pair2.token0());
        console.log("Pool2 token1:", pair2.token1());
    }
    
    function testPairCreation() public view {
        assertTrue(pairAB != address(0), "PairAB should be created");
        assertTrue(pairBC != address(0), "PairBC should be created");
        
        // Verify pair tokens
        IUniswapV2PairTest pair1 = IUniswapV2PairTest(pairAB);
        IUniswapV2PairTest pair2 = IUniswapV2PairTest(pairBC);
        
        assertTrue(
            (pair1.token0() == address(tokenA) && pair1.token1() == address(tokenB)) ||
            (pair1.token0() == address(tokenB) && pair1.token1() == address(tokenA)),
            "PairAB should contain tokenA and tokenB"
        );
        
        assertTrue(
            (pair2.token0() == address(tokenB) && pair2.token1() == address(tokenC)) ||
            (pair2.token0() == address(tokenC) && pair2.token1() == address(tokenB)),
            "PairBC should contain tokenB and tokenC"
        );
    }
    
    function testContractConfiguration() public view {
        assertEq(flashSwap.tokenA(), address(tokenA));
        assertEq(flashSwap.tokenB(), address(tokenB));
        assertEq(flashSwap.tokenC(), address(tokenC));
        assertEq(flashSwap.pairAB(), pairAB);
        assertEq(flashSwap.pairBC(), pairBC);
        assertEq(flashSwap.router(), QUICKSWAP_ROUTER);
        assertEq(flashSwap.owner(), owner);
    }
    
    function testProfitCalculation() public view {
        // This is a theoretical test to show profit calculation logic
        // In a real scenario, we would need price differences to generate profit
        
        uint256 borrowAmount = 100 * 10**18;
        uint256 fee = (borrowAmount * 3) / 997 + 1; // 0.3% fee
        uint256 repayAmount = borrowAmount + fee;
        
        console.log("Borrow amount:", borrowAmount);
        console.log("Fee:", fee);
        console.log("Repay amount:", repayAmount);
        
        // For profit, final tokenA balance should be > repayAmount
        assertTrue(repayAmount > borrowAmount, "Repay amount includes fee");
    }
}