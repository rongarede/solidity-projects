// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/UniswapV2Factory.sol";
import "../contracts/UniswapV2Pair.sol";
import "./mocks/MockERC20.sol";

contract UniswapV2PairTest is Test {
    UniswapV2Factory factory;
    UniswapV2Pair pair;
    MockERC20 token0;
    MockERC20 token1;
    address user1;
    address user2;

    function setUp() public {
        user1 = address(0x1111);
        user2 = address(0x2222);
        
        factory = new UniswapV2Factory(address(this));
        
        MockERC20 tokenA = new MockERC20("Token A", "TKA", 18);
        MockERC20 tokenB = new MockERC20("Token B", "TKB", 18);
        
        if (address(tokenA) < address(tokenB)) {
            token0 = tokenA;
            token1 = tokenB;
        } else {
            token0 = tokenB;
            token1 = tokenA;
        }
        
        address pairAddress = factory.createPair(address(token0), address(token1));
        pair = UniswapV2Pair(pairAddress);
        
        token0.mint(address(this), 1000e18);
        token1.mint(address(this), 1000e18);
        token0.mint(user1, 1000e18);
        token1.mint(user1, 1000e18);
    }

    function testPairInitialization() public {
        assertEq(pair.factory(), address(factory));
        assertEq(pair.token0(), address(token0));
        assertEq(pair.token1(), address(token1));
        assertEq(pair.totalSupply(), 0);
    }

    function testPairERC20Properties() public {
        assertEq(pair.name(), "Uniswap V2");
        assertEq(pair.symbol(), "UNI-V2");
        assertEq(pair.decimals(), 18);
    }

    function testGetReserves() public {
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair.getReserves();
        assertEq(reserve0, 0);
        assertEq(reserve1, 0);
        assertEq(blockTimestampLast, 0);
    }

    function testFirstMint() public {
        uint256 token0Amount = 100e18;
        uint256 token1Amount = 200e18;
        
        token0.transfer(address(pair), token0Amount);
        token1.transfer(address(pair), token1Amount);
        
        uint256 expectedLiquidity = sqrt(token0Amount * token1Amount) - pair.MINIMUM_LIQUIDITY();
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), address(0), pair.MINIMUM_LIQUIDITY());
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), address(this), expectedLiquidity);
        
        uint256 liquidity = pair.mint(address(this));
        
        assertEq(liquidity, expectedLiquidity);
        assertEq(pair.totalSupply(), expectedLiquidity + pair.MINIMUM_LIQUIDITY());
        assertEq(pair.balanceOf(address(this)), expectedLiquidity);
        assertEq(pair.balanceOf(address(0)), pair.MINIMUM_LIQUIDITY());
        
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        assertEq(reserve0, token0Amount);
        assertEq(reserve1, token1Amount);
    }

    function testSubsequentMint() public {
        uint256 token0Amount1 = 100e18;
        uint256 token1Amount1 = 200e18;
        
        token0.transfer(address(pair), token0Amount1);
        token1.transfer(address(pair), token1Amount1);
        pair.mint(address(this));
        
        uint256 token0Amount2 = 50e18;
        uint256 token1Amount2 = 100e18;
        
        token0.transfer(address(pair), token0Amount2);
        token1.transfer(address(pair), token1Amount2);
        
        uint256 totalSupply = pair.totalSupply();
        uint256 expectedLiquidity = min(
            (token0Amount2 * totalSupply) / token0Amount1,
            (token1Amount2 * totalSupply) / token1Amount1
        );
        
        uint256 liquidity = pair.mint(address(this));
        assertEq(liquidity, expectedLiquidity);
    }

    function testBurn() public {
        uint256 token0Amount = 100e18;
        uint256 token1Amount = 200e18;
        
        token0.transfer(address(pair), token0Amount);
        token1.transfer(address(pair), token1Amount);
        uint256 liquidity = pair.mint(address(this));
        
        pair.transfer(address(pair), liquidity);
        (uint256 amount0, uint256 amount1) = pair.burn(user1);
        
        // 账户要考虑最小流动性锁定，实际返回金额会略少于投入金额
        assertGt(amount0, 0);
        assertGt(amount1, 0);
        assertEq(token0.balanceOf(user1), 1000e18 + amount0);
        assertEq(token1.balanceOf(user1), 1000e18 + amount1);
        assertEq(pair.totalSupply(), pair.MINIMUM_LIQUIDITY());
    }

    function testSwapToken0() public {
        uint256 token0Amount = 500e18;
        uint256 token1Amount = 1000e18;
        
        token0.transfer(address(pair), token0Amount);
        token1.transfer(address(pair), token1Amount);
        pair.mint(address(this));
        
        uint256 swapAmount = 10e18;
        uint256 expectedOutputAmount = getAmountOut(swapAmount, token0Amount, token1Amount);
        
        token0.transfer(address(pair), swapAmount);
        pair.swap(0, expectedOutputAmount, user1, "");
        
        assertEq(token1.balanceOf(user1), 1000e18 + expectedOutputAmount);
    }

    function testSwapToken1() public {
        uint256 token0Amount = 500e18;
        uint256 token1Amount = 1000e18;
        
        token0.transfer(address(pair), token0Amount);
        token1.transfer(address(pair), token1Amount);
        pair.mint(address(this));
        
        uint256 swapAmount = 20e18;
        uint256 expectedOutputAmount = getAmountOut(swapAmount, token1Amount, token0Amount);
        
        // 给 user1 提供足够的 token1 用于交换
        token1.mint(user1, swapAmount);
        
        vm.startPrank(user1);
        token1.transfer(address(pair), swapAmount);
        pair.swap(expectedOutputAmount, 0, user1, "");
        vm.stopPrank();
        
        assertEq(token0.balanceOf(user1), 1000e18 + expectedOutputAmount);
    }

    function testCannotSwapWithoutInput() public {
        uint256 token0Amount = 500e18;
        uint256 token1Amount = 1000e18;
        
        token0.transfer(address(pair), token0Amount);
        token1.transfer(address(pair), token1Amount);
        pair.mint(address(this));
        
        vm.expectRevert('UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
        pair.swap(1, 0, user1, "");
    }

    function testCannotSwapWithInsufficientLiquidity() public {
        vm.expectRevert('UniswapV2: INSUFFICIENT_LIQUIDITY');
        pair.swap(1, 0, user1, "");
    }

    // Helper functions
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) 
        internal pure returns (uint256 amountOut) 
    {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
}