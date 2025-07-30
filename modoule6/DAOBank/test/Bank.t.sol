// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Bank} from "../src/contracts/Bank.sol";

contract BankTest is Test {
    Bank public bank;
    address public admin;
    address public alice;
    address public bob;
    address public attacker;

    event Deposit(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawal(address indexed to, uint256 amount, address indexed admin, uint256 timestamp);
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    function setUp() public {
        admin = makeAddr("admin");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        attacker = makeAddr("attacker");

        vm.prank(admin);
        bank = new Bank(admin);
        
        // Fund test accounts
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(attacker, 10 ether);
    }

    function test_InitialState() public view {
        assertEq(bank.owner(), admin);
        assertEq(bank.getBalance(), 0);
        assertEq(bank.totalDeposits(), 0);
    }

    function test_Deposit() public {
        uint256 amount = 1 ether;
        
        vm.expectEmit(true, false, false, true);
        emit Deposit(alice, amount, block.timestamp);
        
        vm.prank(alice);
        bank.deposit{value: amount}();
        
        assertEq(bank.getBalance(), amount);
        assertEq(bank.getUserDeposit(alice), amount);
        assertEq(bank.totalDeposits(), amount);
    }

    function test_MultipleDeposits() public {
        uint256 amount1 = 1 ether;
        uint256 amount2 = 2 ether;
        
        vm.prank(alice);
        bank.deposit{value: amount1}();
        
        vm.prank(bob);
        bank.deposit{value: amount2}();
        
        assertEq(bank.getBalance(), amount1 + amount2);
        assertEq(bank.getUserDeposit(alice), amount1);
        assertEq(bank.getUserDeposit(bob), amount2);
        assertEq(bank.totalDeposits(), amount1 + amount2);
    }

    function test_DepositViaReceive() public {
        uint256 amount = 1 ether;
        
        vm.expectEmit(true, false, false, true);
        emit Deposit(alice, amount, block.timestamp);
        
        vm.prank(alice);
        (bool success, ) = address(bank).call{value: amount}("");
        require(success, "Transfer failed");
        
        assertEq(bank.getBalance(), amount);
        assertEq(bank.getUserDeposit(alice), amount);
    }

    function test_DepositZeroAmount() public {
        vm.prank(alice);
        vm.expectRevert("Bank: Deposit amount must be greater than 0");
        bank.deposit{value: 0}();
    }

    function test_WithdrawByAdmin() public {
        uint256 depositAmount = 5 ether;
        uint256 withdrawAmount = 2 ether;
        
        // Alice deposits
        vm.prank(alice);
        bank.deposit{value: depositAmount}();
        
        // Admin withdraws to Bob
        vm.expectEmit(true, true, true, true);
        emit Withdrawal(bob, withdrawAmount, admin, block.timestamp);
        
        vm.prank(admin);
        bank.withdraw(bob, withdrawAmount);
        
        assertEq(bank.getBalance(), depositAmount - withdrawAmount);
        assertEq(bob.balance, 10 ether + withdrawAmount);
        assertEq(bank.totalDeposits(), depositAmount - withdrawAmount);
    }

    function test_WithdrawOnlyAdmin() public {
        uint256 amount = 1 ether;
        
        vm.prank(alice);
        bank.deposit{value: amount}();
        
        vm.prank(alice);
        vm.expectRevert();
        bank.withdraw(alice, amount);
    }

    function test_WithdrawZeroAddress() public {
        uint256 amount = 1 ether;
        
        vm.prank(alice);
        bank.deposit{value: amount}();
        
        vm.prank(admin);
        vm.expectRevert("Bank: Cannot withdraw to zero address");
        bank.withdraw(address(0), amount);
    }

    function test_WithdrawZeroAmount() public {
        uint256 amount = 1 ether;
        
        vm.prank(alice);
        bank.deposit{value: amount}();
        
        vm.prank(admin);
        vm.expectRevert("Bank: Withdrawal amount must be greater than 0");
        bank.withdraw(alice, 0);
    }

    function test_WithdrawInsufficientBalance() public {
        uint256 depositAmount = 1 ether;
        uint256 withdrawAmount = 2 ether;
        
        vm.prank(alice);
        bank.deposit{value: depositAmount}();
        
        vm.prank(admin);
        vm.expectRevert("Bank: Insufficient balance");
        bank.withdraw(alice, withdrawAmount);
    }

    function test_ChangeAdmin() public {
        address newAdmin = makeAddr("newAdmin");
        
        vm.expectEmit(true, true, false, false);
        emit AdminChanged(admin, newAdmin);
        
        vm.prank(admin);
        bank.changeAdmin(newAdmin);
        
        assertEq(bank.owner(), newAdmin);
    }

    function test_ChangeAdminOnlyAdmin() public {
        address newAdmin = makeAddr("newAdmin");
        
        vm.prank(alice);
        vm.expectRevert();
        bank.changeAdmin(newAdmin);
    }

    function test_ChangeAdminZeroAddress() public {
        vm.prank(admin);
        vm.expectRevert("Bank: New admin cannot be zero address");
        bank.changeAdmin(address(0));
    }

    function test_ChangeAdminSameAddress() public {
        vm.prank(admin);
        vm.expectRevert("Bank: New admin is the same as current admin");
        bank.changeAdmin(admin);
    }

    function test_ReentrancyProtection() public {
        // Deploy a malicious contract that attempts reentrancy
        MaliciousReceiver malicious = new MaliciousReceiver(bank);
        
        // Fund the malicious contract and bank with more than needed for one withdrawal
        vm.deal(address(malicious), 3 ether);
        vm.prank(address(malicious));
        bank.deposit{value: 3 ether}(); // Deposit 3 ETH so there's enough for reentrancy
        
        // Set admin to malicious contract for testing
        vm.prank(admin);
        bank.changeAdmin(address(malicious));
        
        // Attempt reentrancy attack - should be blocked by ReentrancyGuard
        vm.expectRevert(); // Any revert is fine - the important thing is it reverts
        malicious.attack();
    }

    function test_MultipleWithdrawals() public {
        uint256 totalDeposit = 10 ether;
        
        vm.prank(alice);
        bank.deposit{value: totalDeposit}();
        
        uint256 bobInitialBalance = bob.balance;
        uint256 aliceInitialBalance = alice.balance;
        uint256 adminInitialBalance = admin.balance;
        
        // Multiple withdrawals by admin
        vm.startPrank(admin);
        bank.withdraw(bob, 3 ether);
        bank.withdraw(alice, 2 ether);
        bank.withdraw(admin, 1 ether);
        vm.stopPrank();
        
        assertEq(bank.getBalance(), 4 ether);
        assertEq(bob.balance, bobInitialBalance + 3 ether);
        assertEq(alice.balance, aliceInitialBalance + 2 ether);
        assertEq(admin.balance, adminInitialBalance + 1 ether);
    }

    function test_DepositsByMultipleUsers() public {
        vm.prank(alice);
        bank.deposit{value: 3 ether}();
        
        vm.prank(bob);
        bank.deposit{value: 2 ether}();
        
        vm.prank(alice);
        bank.deposit{value: 1 ether}();
        
        assertEq(bank.getUserDeposit(alice), 4 ether);
        assertEq(bank.getUserDeposit(bob), 2 ether);
        assertEq(bank.getBalance(), 6 ether);
        assertEq(bank.totalDeposits(), 6 ether);
    }
}

// Malicious contract for reentrancy testing
contract MaliciousReceiver {
    Bank public bank;
    bool public attacking;
    
    constructor(Bank _bank) {
        bank = _bank;
    }
    
    function attack() external {
        attacking = true;
        bank.withdraw(address(this), 1 ether);
    }
    
    receive() external payable {
        if (attacking && address(bank).balance >= 1 ether) {
            // This should trigger reentrancy protection
            bank.withdraw(address(this), 1 ether);
        }
    }
}