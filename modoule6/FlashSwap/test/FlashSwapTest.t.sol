// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/FlashSwapArbitrage.sol";
import "../src/tokens/TokenA.sol";
import "../src/tokens/TokenB.sol";
import "../src/tokens/TokenC.sol";

contract MockUniswapV2Pair {
    address public token0;
    address public token1;
    bool public swapCalled = false;
    
    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
    }
    
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external {
        swapCalled = true;
        // Mock implementation - would normally transfer tokens and call callback
        if (data.length > 0) {
            IUniswapV2Callee(to).uniswapV2Call(address(this), amount0Out, amount1Out, data);
        }
    }
    
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) {
        return (1000 * 10**18, 1000 * 10**18, uint32(block.timestamp));
    }
}

contract MockUniswapV2Router {
    bool public swapCalled = false;
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        swapCalled = true;
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        amounts[1] = amountIn; // 1:1 swap for testing
        
        // Mock token transfer
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        IERC20(path[1]).transfer(to, amountIn);
        
        return amounts;
    }
    
    function getAmountsOut(uint amountIn, address[] calldata path)
        external pure returns (uint[] memory amounts) {
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        amounts[1] = amountIn; // 1:1 for testing
        return amounts;
    }
}

contract FlashSwapTest is Test {
    FlashSwapArbitrage public flashSwap;
    TokenA public tokenA;
    TokenB public tokenB;
    TokenC public tokenC;
    MockUniswapV2Pair public pairAB;
    MockUniswapV2Pair public pairBC;
    MockUniswapV2Router public router;
    
    address public owner = address(this);
    address public user = address(0x1);
    
    function setUp() public {
        tokenA = new TokenA();
        tokenB = new TokenB();
        tokenC = new TokenC();
        
        pairAB = new MockUniswapV2Pair(address(tokenA), address(tokenB));
        pairBC = new MockUniswapV2Pair(address(tokenB), address(tokenC));
        router = new MockUniswapV2Router();
        
        flashSwap = new FlashSwapArbitrage(
            address(tokenA),
            address(tokenB),
            address(tokenC),
            address(pairAB),
            address(pairBC),
            address(router)
        );
        
        // Setup router with tokens for mock swaps
        tokenA.transfer(address(router), 100000 * 10**18);
        tokenB.transfer(address(router), 100000 * 10**18);
        tokenC.transfer(address(router), 100000 * 10**18);
    }
    
    function testContractInitialization() public {
        assertEq(flashSwap.tokenA(), address(tokenA));
        assertEq(flashSwap.tokenB(), address(tokenB));
        assertEq(flashSwap.tokenC(), address(tokenC));
        assertEq(flashSwap.pairAB(), address(pairAB));
        assertEq(flashSwap.pairBC(), address(pairBC));
        assertEq(flashSwap.router(), address(router));
        assertEq(flashSwap.owner(), owner);
    }
    
    function testOnlyOwnerCanExecuteArbitrage() public {
        vm.expectRevert();
        vm.prank(user);
        flashSwap.executeArbitrage(1000 * 10**18);
    }
    
    function testExecuteArbitrageCallsPairSwap() public {
        uint256 amount = 1000 * 10**18;
        flashSwap.executeArbitrage(amount);
        assertTrue(pairAB.swapCalled());
    }
    
    function testExecuteArbitrageRequiresPositiveAmount() public {
        vm.expectRevert("Amount must be greater than 0");
        flashSwap.executeArbitrage(0);
    }
    
    function testUniswapV2CallRequiresAuthorizedCaller() public {
        bytes memory data = abi.encode(1000 * 10**18, owner);
        
        vm.expectRevert("Unauthorized caller");
        flashSwap.uniswapV2Call(address(this), 1000 * 10**18, 0, data);
    }
    
    function testUniswapV2CallRequiresCorrectSender() public {
        bytes memory data = abi.encode(1000 * 10**18, owner);
        
        vm.expectRevert("Unauthorized sender");
        vm.prank(address(pairAB));
        flashSwap.uniswapV2Call(user, 1000 * 10**18, 0, data);
    }
    
    function testWithdrawToken() public {
        uint256 amount = 1000 * 10**18;
        tokenA.transfer(address(flashSwap), amount);
        
        uint256 balanceBefore = tokenA.balanceOf(owner);
        flashSwap.withdrawToken(address(tokenA), amount);
        uint256 balanceAfter = tokenA.balanceOf(owner);
        
        assertEq(balanceAfter - balanceBefore, amount);
    }
    
    function testOnlyOwnerCanWithdrawToken() public {
        vm.expectRevert();
        vm.prank(user);
        flashSwap.withdrawToken(address(tokenA), 1000 * 10**18);
    }
    
    function testEmergencyWithdraw() public {
        uint256 amountA = 1000 * 10**18;
        uint256 amountB = 2000 * 10**18;
        
        tokenA.transfer(address(flashSwap), amountA);
        tokenB.transfer(address(flashSwap), amountB);
        
        uint256 balanceABefore = tokenA.balanceOf(owner);
        uint256 balanceBBefore = tokenB.balanceOf(owner);
        
        flashSwap.emergencyWithdraw();
        
        uint256 balanceAAfter = tokenA.balanceOf(owner);
        uint256 balanceBAfter = tokenB.balanceOf(owner);
        
        assertEq(balanceAAfter - balanceABefore, amountA);
        assertEq(balanceBAfter - balanceBBefore, amountB);
    }
    
    function testOnlyOwnerCanEmergencyWithdraw() public {
        vm.expectRevert();
        vm.prank(user);
        flashSwap.emergencyWithdraw();
    }
}