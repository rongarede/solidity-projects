// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/BaseERC20.sol";
import "../src/TokenBank.sol";

contract TokenBankTest is Test {
    BaseERC20 public token;
    TokenBank public bank;
    
    address public owner;
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 10**18;
    uint256 public constant DEPOSIT_AMOUNT = 1000 * 10**18;

    function setUp() public {
        owner = address(this);
        
        // 部署代币合约
        token = new BaseERC20();
        
        // 部署银行合约
        bank = new TokenBank(address(token));
        
        // 给用户分配一些代币进行测试
        token.transfer(user1, DEPOSIT_AMOUNT * 10);
        token.transfer(user2, DEPOSIT_AMOUNT * 5);
    }

    function testDeposit() public {
        vm.startPrank(user1);
        
        // 用户需要先授权
        token.approve(address(bank), DEPOSIT_AMOUNT);
        
        // 存入代币
        bank.deposit(DEPOSIT_AMOUNT);
        
        // 验证余额
        assertEq(bank.balanceOf(user1), DEPOSIT_AMOUNT);
        assertEq(bank.totalDeposits(), DEPOSIT_AMOUNT);
        assertEq(token.balanceOf(address(bank)), DEPOSIT_AMOUNT);
        
        vm.stopPrank();
    }

    function testWithdraw() public {
        // 先存入
        vm.startPrank(user1);
        token.approve(address(bank), DEPOSIT_AMOUNT);
        bank.deposit(DEPOSIT_AMOUNT);
        
        uint256 withdrawAmount = DEPOSIT_AMOUNT / 2;
        uint256 userBalanceBefore = token.balanceOf(user1);
        
        // 取出部分代币
        bank.withdraw(withdrawAmount);
        
        // 验证余额
        assertEq(bank.balanceOf(user1), DEPOSIT_AMOUNT - withdrawAmount);
        assertEq(bank.totalDeposits(), DEPOSIT_AMOUNT - withdrawAmount);
        assertEq(token.balanceOf(user1), userBalanceBefore + withdrawAmount);
        
        vm.stopPrank();
    }

    function testDepositWithoutApproval() public {
        vm.prank(user1);
        
        // 没有授权就存入，应该失败
        vm.expectRevert();
        bank.deposit(DEPOSIT_AMOUNT);
    }

    function testWithdrawInsufficientBalance() public {
        vm.prank(user1);
        
        // 尝试取出比余额更多的代币
        vm.expectRevert(TokenBank.InsufficientBalance.selector);
        bank.withdraw(DEPOSIT_AMOUNT);
    }

    function testZeroAmountDeposit() public {
        vm.prank(user1);
        
        vm.expectRevert(TokenBank.ZeroAmount.selector);
        bank.deposit(0);
    }

    function testZeroAmountWithdraw() public {
        vm.prank(user1);
        
        vm.expectRevert(TokenBank.ZeroAmount.selector);
        bank.withdraw(0);
    }

    function testMultipleUsersDeposit() public {
        // 用户1存入
        vm.startPrank(user1);
        token.approve(address(bank), DEPOSIT_AMOUNT);
        bank.deposit(DEPOSIT_AMOUNT);
        vm.stopPrank();
        
        // 用户2存入
        vm.startPrank(user2);
        token.approve(address(bank), DEPOSIT_AMOUNT * 2);
        bank.deposit(DEPOSIT_AMOUNT * 2);
        vm.stopPrank();
        
        // 验证各自余额
        assertEq(bank.balanceOf(user1), DEPOSIT_AMOUNT);
        assertEq(bank.balanceOf(user2), DEPOSIT_AMOUNT * 2);
        assertEq(bank.totalDeposits(), DEPOSIT_AMOUNT * 3);
    }

    function testContractInfo() public view {
        assertEq(bank.getTokenAddress(), address(token));
        assertEq(bank.getContractBalance(), 0); // 初始为0
    }
}