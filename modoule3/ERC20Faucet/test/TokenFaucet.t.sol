// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/TestToken.sol";
import "../src/TokenFaucet.sol";

contract TokenFaucetTest is Test {
    TestToken public token;
    TokenFaucet public faucet;
    
    address public owner;
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    
    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10**18;
    uint256 public constant FAUCET_AMOUNT = 100; // 100 TST per request
    uint256 public constant COOLDOWN_TIME = 24 * 60 * 60; // 24 hours
    uint256 public constant FAUCET_FUNDING = 10_000 * 10**18; // 10,000 TST
    
    function setUp() public {
        owner = address(this);
        
        // 部署代币合约
        token = new TestToken();
        
        // 部署水龙头合约
        faucet = new TokenFaucet(address(token), FAUCET_AMOUNT, COOLDOWN_TIME);
        
        // 向水龙头转入代币
        token.transfer(address(faucet), FAUCET_FUNDING);
    }
    
    function testInitialState() public view {
        assertEq(token.name(), "TestToken");
        assertEq(token.symbol(), "TST");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - FAUCET_FUNDING);
        
        assertEq(address(faucet.token()), address(token));
        assertEq(faucet.faucetAmount(), FAUCET_AMOUNT * 10**18);
        assertEq(faucet.cooldownTime(), COOLDOWN_TIME);
        assertEq(faucet.getFaucetBalance(), FAUCET_FUNDING);
    }
    
    function testRequestTokens() public {
        vm.prank(user1);
        faucet.requestTokens();
        
        assertEq(token.balanceOf(user1), FAUCET_AMOUNT * 10**18);
        assertEq(faucet.lastRequestTime(user1), block.timestamp);
        assertTrue(faucet.getRemainingCooldown(user1) > 0);
        assertFalse(faucet.canRequestTokens(user1));
    }
    
    function testCooldownPeriod() public {
        // 第一次领取
        vm.prank(user1);
        faucet.requestTokens();
        
        // 立即再次尝试领取应该失败
        vm.prank(user1);
        vm.expectRevert();
        faucet.requestTokens();
        
        // 跳过冷却时间
        vm.warp(block.timestamp + COOLDOWN_TIME);
        
        // 现在应该可以再次领取
        vm.prank(user1);
        faucet.requestTokens();
        
        assertEq(token.balanceOf(user1), FAUCET_AMOUNT * 10**18 * 2);
    }
    
    function testMultipleUsers() public {
        // User1 领取
        vm.prank(user1);
        faucet.requestTokens();
        
        // User2 立即领取（无冷却时间限制）
        vm.prank(user2);
        faucet.requestTokens();
        
        assertEq(token.balanceOf(user1), FAUCET_AMOUNT * 10**18);
        assertEq(token.balanceOf(user2), FAUCET_AMOUNT * 10**18);
    }
    
    function testSetAmount() public {
        uint256 newAmount = 200;
        faucet.setAmount(newAmount);
        
        assertEq(faucet.faucetAmount(), newAmount * 10**18);
        
        vm.prank(user1);
        faucet.requestTokens();
        
        assertEq(token.balanceOf(user1), newAmount * 10**18);
    }
    
    function testSetAmountOnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        faucet.setAmount(200);
    }
    
    function testWithdraw() public {
        uint256 balanceBefore = token.balanceOf(owner);
        uint256 withdrawAmount = 1000 * 10**18;
        
        faucet.withdraw(withdrawAmount);
        
        assertEq(token.balanceOf(owner), balanceBefore + withdrawAmount);
        assertEq(faucet.getFaucetBalance(), FAUCET_FUNDING - withdrawAmount);
    }
    
    function testCanRequestTokens() public {
        // 初始状态应该可以领取
        assertTrue(faucet.canRequestTokens(user1));
        
        // 领取后应该不能立即再次领取
        vm.prank(user1);
        faucet.requestTokens();
        assertFalse(faucet.canRequestTokens(user1));
        
        // 冷却时间过后应该可以再次领取
        vm.warp(block.timestamp + COOLDOWN_TIME);
        assertTrue(faucet.canRequestTokens(user1));
    }
}