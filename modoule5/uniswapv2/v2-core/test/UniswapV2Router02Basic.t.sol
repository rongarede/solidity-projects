// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/UniswapV2Factory.sol";
import "../contracts/UniswapV2Router02.sol";
import "../contracts/UniswapV2Pair.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockWETH.sol";

contract UniswapV2Router02BasicTest is Test {
    UniswapV2Factory factory;
    UniswapV2Router02 router;
    MockERC20 tokenA;
    MockERC20 tokenB;
    MockWETH weth;
    UniswapV2Pair pair;
    
    address deployer;
    address user1;
    address user2;
    
    uint256 constant INITIAL_SUPPLY = 1000000 * 1e18;
    uint256 constant LIQUIDITY_AMOUNT = 10000 * 1e18;
    
    function setUp() public {
        deployer = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        
        // 部署合约
        factory = new UniswapV2Factory(deployer);
        weth = new MockWETH();
        router = new UniswapV2Router02(address(factory), address(weth));
        
        // 部署代币
        tokenA = new MockERC20("Token A", "TKA", 18);
        tokenB = new MockERC20("Token B", "TKB", 18);
        
        // 为测试账户铸造代币
        tokenA.mint(deployer, INITIAL_SUPPLY);
        tokenB.mint(deployer, INITIAL_SUPPLY);
        tokenA.mint(user1, INITIAL_SUPPLY);
        tokenB.mint(user1, INITIAL_SUPPLY);
        
        // 给合约一些 ETH
        vm.deal(deployer, 100 ether);
        vm.deal(user1, 100 ether);
        vm.deal(address(router), 1 ether);
    }
    
    // Router 部署和初始化测试
    function testRouterDeployment() public {
        assertEq(router.factory(), address(factory), "Factory address mismatch");
        assertEq(router.WETH(), address(weth), "WETH address mismatch");
    }
    
    function testRouterFactoryConnection() public {
        // 测试 Router 能正确与 Factory 交互
        address factoryFromRouter = router.factory();
        assertEq(factoryFromRouter, address(factory), "Router factory connection failed");
    }
    
    // 基础流动性测试
    function testAddLiquidityBasic() public {
        uint256 amountA = LIQUIDITY_AMOUNT;
        uint256 amountB = LIQUIDITY_AMOUNT;
        
        // 授权代币给 Router
        tokenA.approve(address(router), amountA);
        tokenB.approve(address(router), amountB);
        
        // 添加流动性
        (uint256 actualAmountA, uint256 actualAmountB, uint256 liquidity) = router.addLiquidity(
            address(tokenA),
            address(tokenB),
            amountA,
            amountB,
            0, // amountAMin
            0, // amountBMin
            deployer,
            block.timestamp + 300
        );
        
        // 验证返回值
        assertEq(actualAmountA, amountA, "Amount A mismatch");
        assertEq(actualAmountB, amountB, "Amount B mismatch");
        assertGt(liquidity, 0, "No liquidity tokens received");
        
        // 验证交易对已创建
        address pairAddress = factory.getPair(address(tokenA), address(tokenB));
        assertNotEq(pairAddress, address(0), "Pair not created");
        
        // 验证流动性代币余额
        pair = UniswapV2Pair(pairAddress);
        uint256 lpBalance = pair.balanceOf(deployer);
        assertGt(lpBalance, 0, "No LP tokens in deployer balance");
    }
    
    function testAddLiquidityCalculation() public {
        uint256 amountA = 1000 * 1e18;
        uint256 amountB = 2000 * 1e18; // 1:2 比例
        
        tokenA.approve(address(router), amountA);
        tokenB.approve(address(router), amountB);
        
        // 第一次添加流动性
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            amountA,
            amountB,
            0,
            0,
            deployer,
            block.timestamp + 300
        );
        
        // 获取储备量验证比例
        address pairAddress = factory.getPair(address(tokenA), address(tokenB));
        pair = UniswapV2Pair(pairAddress);
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        
        // 验证储备量比例正确
        address token0 = pair.token0();
        if (token0 == address(tokenA)) {
            assertEq(uint256(reserve0), amountA, "Reserve A incorrect");
            assertEq(uint256(reserve1), amountB, "Reserve B incorrect");
        } else {
            assertEq(uint256(reserve0), amountB, "Reserve B incorrect");
            assertEq(uint256(reserve1), amountA, "Reserve A incorrect");
        }
    }
    
    // 基础交换测试
    function testSwapExactTokensForTokensBasic() public {
        // 先添加流动性
        uint256 liquidityA = 10000 * 1e18;
        uint256 liquidityB = 20000 * 1e18; // 1:2 比例
        
        tokenA.approve(address(router), liquidityA);
        tokenB.approve(address(router), liquidityB);
        
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            liquidityA,
            liquidityB,
            0,
            0,
            deployer,
            block.timestamp + 300
        );
        
        // 执行交换
        uint256 swapAmountIn = 100 * 1e18; // 100 tokenA
        uint256 balanceBefore = tokenB.balanceOf(user1);
        
        vm.startPrank(user1);
        tokenA.approve(address(router), swapAmountIn);
        
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        
        uint256[] memory amounts = router.swapExactTokensForTokens(
            swapAmountIn,
            0, // amountOutMin
            path,
            user1,
            block.timestamp + 300
        );
        vm.stopPrank();
        
        // 验证交换结果
        assertEq(amounts[0], swapAmountIn, "Input amount mismatch");
        assertGt(amounts[1], 0, "No output tokens received");
        
        uint256 balanceAfter = tokenB.balanceOf(user1);
        uint256 tokensReceived = balanceAfter - balanceBefore;
        assertEq(tokensReceived, amounts[1], "Token balance mismatch");
        
        // 验证交换比例合理（考虑手续费）
        assertGt(tokensReceived, swapAmountIn * 190 / 100, "Output too low"); // 至少 1.9x (考虑 0.3% 手续费)
        assertLt(tokensReceived, swapAmountIn * 2, "Output too high"); // 小于 2x
    }
    
    function testSwapCalculationAccuracy() public {
        // 添加流动性
        uint256 liquidityA = 1000 * 1e18;
        uint256 liquidityB = 1000 * 1e18; // 1:1 比例
        
        tokenA.approve(address(router), liquidityA);
        tokenB.approve(address(router), liquidityB);
        
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            liquidityA,
            liquidityB,
            0,
            0,
            deployer,
            block.timestamp + 300
        );
        
        // 小额交换测试精度
        uint256 swapAmount = 1 * 1e18;
        
        vm.startPrank(user1);
        tokenA.approve(address(router), swapAmount);
        
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        
        // 先查询预期输出
        uint256[] memory expectedAmounts = router.getAmountsOut(swapAmount, path);
        
        // 执行实际交换
        uint256[] memory actualAmounts = router.swapExactTokensForTokens(
            swapAmount,
            0,
            path,
            user1,
            block.timestamp + 300
        );
        vm.stopPrank();
        
        // 验证预期输出与实际输出一致
        assertEq(actualAmounts[1], expectedAmounts[1], "Price calculation inaccuracy");
    }
    
    function testPriceImpactReasonable() public {
        // 添加大量流动性
        uint256 liquidityA = 100000 * 1e18;
        uint256 liquidityB = 100000 * 1e18;
        
        tokenA.approve(address(router), liquidityA);
        tokenB.approve(address(router), liquidityB);
        
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            liquidityA,
            liquidityB,
            0,
            0,
            deployer,
            block.timestamp + 300
        );
        
        // 小额交换应该价格影响很小
        uint256 smallSwap = 100 * 1e18; // 0.1% of liquidity
        
        vm.startPrank(user1);
        tokenA.approve(address(router), smallSwap);
        
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        
        uint256[] memory amounts = router.swapExactTokensForTokens(
            smallSwap,
            0,
            path,
            user1,
            block.timestamp + 300
        );
        vm.stopPrank();
        
        // 小额交换的价格影响应该很小（接近 1:1 减去手续费）
        uint256 expectedMin = smallSwap * 997 / 1000; // 0.3% 手续费
        assertGe(amounts[1], expectedMin * 995 / 1000, "Price impact too high for small swap");
    }
    
    function testDeadlineEnforcement() public {
        uint256 amountA = 1000 * 1e18;
        uint256 amountB = 1000 * 1e18;
        
        tokenA.approve(address(router), amountA);
        tokenB.approve(address(router), amountB);
        
        // 测试过期的 deadline
        vm.expectRevert("UniswapV2Router: EXPIRED");
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            amountA,
            amountB,
            0,
            0,
            deployer,
            block.timestamp - 1 // 已过期
        );
    }
}