// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TokenBank} from "../src/TokenBank.sol";
import {TestToken} from "../src/TestToken.sol";

contract TokenBankTest is Test {
    TokenBank public tokenBank;
    TestToken public token1;
    TestToken public token2;
    
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    
    uint256 public constant INITIAL_SUPPLY = 1000000;
    uint256 public constant DEPOSIT_AMOUNT = 1000;

    function setUp() public {
        tokenBank = new TokenBank();
        token1 = new TestToken("Test Token 1", "TT1", INITIAL_SUPPLY);
        token2 = new TestToken("Test Token 2", "TT2", INITIAL_SUPPLY);
        
        token1.transfer(user1, 10000 * 10**18);
        token1.transfer(user2, 10000 * 10**18);
        token2.transfer(user1, 10000 * 10**18);
        token2.transfer(user2, 10000 * 10**18);
    }

    function testDeposit() public {
        vm.startPrank(user1);
        
        uint256 depositAmount = DEPOSIT_AMOUNT * 10**18;
        token1.approve(address(tokenBank), depositAmount);
        
        vm.expectEmit(true, true, false, true);
        emit TokenBank.Deposit(user1, address(token1), depositAmount);
        
        tokenBank.deposit(address(token1), depositAmount);
        
        assertEq(tokenBank.getBalance(user1, address(token1)), depositAmount);
        assertEq(token1.balanceOf(address(tokenBank)), depositAmount);
        
        vm.stopPrank();
    }

    function testWithdraw() public {
        vm.startPrank(user1);
        
        uint256 depositAmount = DEPOSIT_AMOUNT * 10**18;
        uint256 withdrawAmount = 500 * 10**18;
        
        token1.approve(address(tokenBank), depositAmount);
        tokenBank.deposit(address(token1), depositAmount);
        
        uint256 balanceBefore = token1.balanceOf(user1);
        
        vm.expectEmit(true, true, false, true);
        emit TokenBank.Withdraw(user1, address(token1), withdrawAmount);
        
        tokenBank.withdraw(address(token1), withdrawAmount);
        
        assertEq(tokenBank.getBalance(user1, address(token1)), depositAmount - withdrawAmount);
        assertEq(token1.balanceOf(user1), balanceBefore + withdrawAmount);
        
        vm.stopPrank();
    }

    function testMultipleTokens() public {
        vm.startPrank(user1);
        
        uint256 depositAmount = DEPOSIT_AMOUNT * 10**18;
        
        token1.approve(address(tokenBank), depositAmount);
        token2.approve(address(tokenBank), depositAmount);
        
        tokenBank.deposit(address(token1), depositAmount);
        tokenBank.deposit(address(token2), depositAmount);
        
        assertEq(tokenBank.getBalance(user1, address(token1)), depositAmount);
        assertEq(tokenBank.getBalance(user1, address(token2)), depositAmount);
        
        vm.stopPrank();
    }

    function testMultipleUsers() public {
        uint256 depositAmount = DEPOSIT_AMOUNT * 10**18;
        
        vm.startPrank(user1);
        token1.approve(address(tokenBank), depositAmount);
        tokenBank.deposit(address(token1), depositAmount);
        vm.stopPrank();
        
        vm.startPrank(user2);
        token1.approve(address(tokenBank), depositAmount);
        tokenBank.deposit(address(token1), depositAmount);
        vm.stopPrank();
        
        assertEq(tokenBank.getBalance(user1, address(token1)), depositAmount);
        assertEq(tokenBank.getBalance(user2, address(token1)), depositAmount);
        assertEq(token1.balanceOf(address(tokenBank)), depositAmount * 2);
    }

    function testRevertWhen_DepositZeroAmount() public {
        vm.startPrank(user1);
        vm.expectRevert("Amount must be greater than 0");
        tokenBank.deposit(address(token1), 0);
        vm.stopPrank();
    }

    function testRevertWhen_DepositInvalidToken() public {
        vm.startPrank(user1);
        vm.expectRevert("Invalid token address");
        tokenBank.deposit(address(0), DEPOSIT_AMOUNT);
        vm.stopPrank();
    }

    function testRevertWhen_WithdrawInsufficientBalance() public {
        vm.startPrank(user1);
        vm.expectRevert("Insufficient balance");
        tokenBank.withdraw(address(token1), DEPOSIT_AMOUNT);
        vm.stopPrank();
    }

    function testRevertWhen_WithdrawZeroAmount() public {
        vm.startPrank(user1);
        vm.expectRevert("Amount must be greater than 0");
        tokenBank.withdraw(address(token1), 0);
        vm.stopPrank();
    }

    function testRevertWhen_WithdrawInvalidToken() public {
        vm.startPrank(user1);
        vm.expectRevert("Invalid token address");
        tokenBank.withdraw(address(0), DEPOSIT_AMOUNT);
        vm.stopPrank();
    }

    function testGetBalance() public {
        assertEq(tokenBank.getBalance(user1, address(token1)), 0);
        
        vm.startPrank(user1);
        uint256 depositAmount = DEPOSIT_AMOUNT * 10**18;
        token1.approve(address(tokenBank), depositAmount);
        tokenBank.deposit(address(token1), depositAmount);
        vm.stopPrank();
        
        assertEq(tokenBank.getBalance(user1, address(token1)), depositAmount);
    }
}