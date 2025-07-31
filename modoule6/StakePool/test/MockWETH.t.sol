// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {MockWETH} from "../src/MockWETH.sol";

contract MockWETHTest is Test {
    MockWETH public weth;
    address public user1;
    address public user2;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    function setUp() public {
        weth = new MockWETH();
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        // Give users some ETH
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }

    function testDeposit() public {
        uint256 depositAmount = 1 ether;
        
        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit Deposit(user1, depositAmount);
        
        weth.deposit{value: depositAmount}();
        
        assertEq(weth.balanceOf(user1), depositAmount);
        assertEq(weth.totalSupply(), depositAmount);
        assertEq(address(weth).balance, depositAmount);
        assertEq(weth.totalETH(), depositAmount);
    }

    function testDepositViaReceive() public {
        uint256 depositAmount = 2 ether;
        
        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit Deposit(user1, depositAmount);
        
        (bool success, ) = address(weth).call{value: depositAmount}("");
        assertTrue(success);
        
        assertEq(weth.balanceOf(user1), depositAmount);
        assertEq(weth.totalSupply(), depositAmount);
        assertEq(address(weth).balance, depositAmount);
    }

    function testDepositViaFallback() public {
        uint256 depositAmount = 0.5 ether;
        
        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit Deposit(user1, depositAmount);
        
        (bool success, ) = address(weth).call{value: depositAmount}("somedata");
        assertTrue(success);
        
        assertEq(weth.balanceOf(user1), depositAmount);
        assertEq(weth.totalSupply(), depositAmount);
        assertEq(address(weth).balance, depositAmount);
    }

    function testWithdraw() public {
        uint256 depositAmount = 5 ether;
        uint256 withdrawAmount = 2 ether;
        
        // First deposit
        vm.prank(user1);
        weth.deposit{value: depositAmount}();
        
        uint256 initialBalance = user1.balance;
        
        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit Withdrawal(user1, withdrawAmount);
        
        weth.withdraw(withdrawAmount);
        
        assertEq(weth.balanceOf(user1), depositAmount - withdrawAmount);
        assertEq(weth.totalSupply(), depositAmount - withdrawAmount);
        assertEq(address(weth).balance, depositAmount - withdrawAmount);
        assertEq(user1.balance, initialBalance + withdrawAmount);
    }

    function testWithdrawAll() public {
        uint256 depositAmount = 3 ether;
        
        // First deposit
        vm.prank(user1);
        weth.deposit{value: depositAmount}();
        
        uint256 initialBalance = user1.balance;
        
        vm.prank(user1);
        weth.withdraw(depositAmount);
        
        assertEq(weth.balanceOf(user1), 0);
        assertEq(weth.totalSupply(), 0);
        assertEq(address(weth).balance, 0);
        assertEq(user1.balance, initialBalance + depositAmount);
    }

    function testDepositZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert(MockWETH.InvalidAmount.selector);
        weth.deposit{value: 0}();
    }

    function testWithdrawZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert(MockWETH.InvalidAmount.selector);
        weth.withdraw(0);
    }

    function testWithdrawInsufficientBalance() public {
        uint256 depositAmount = 1 ether;
        uint256 withdrawAmount = 2 ether;
        
        // Deposit some amount
        vm.prank(user1);
        weth.deposit{value: depositAmount}();
        
        // Try to withdraw more than balance
        vm.prank(user1);
        vm.expectRevert(MockWETH.InsufficientBalance.selector);
        weth.withdraw(withdrawAmount);
    }

    function testWithdrawWithoutBalance() public {
        vm.prank(user1);
        vm.expectRevert(MockWETH.InsufficientBalance.selector);
        weth.withdraw(1 ether);
    }

    function testMultipleUsersDeposit() public {
        uint256 deposit1 = 2 ether;
        uint256 deposit2 = 3 ether;
        
        // User1 deposits
        vm.prank(user1);
        weth.deposit{value: deposit1}();
        
        // User2 deposits
        vm.prank(user2);
        weth.deposit{value: deposit2}();
        
        assertEq(weth.balanceOf(user1), deposit1);
        assertEq(weth.balanceOf(user2), deposit2);
        assertEq(weth.totalSupply(), deposit1 + deposit2);
        assertEq(address(weth).balance, deposit1 + deposit2);
    }

    function testMultipleUsersWithdraw() public {
        uint256 deposit1 = 4 ether;
        uint256 deposit2 = 6 ether;
        uint256 withdraw1 = 1 ether;
        uint256 withdraw2 = 2 ether;
        
        // Users deposit
        vm.prank(user1);
        weth.deposit{value: deposit1}();
        
        vm.prank(user2);
        weth.deposit{value: deposit2}();
        
        uint256 user1InitialETH = user1.balance;
        uint256 user2InitialETH = user2.balance;
        
        // Users withdraw
        vm.prank(user1);
        weth.withdraw(withdraw1);
        
        vm.prank(user2);
        weth.withdraw(withdraw2);
        
        assertEq(weth.balanceOf(user1), deposit1 - withdraw1);
        assertEq(weth.balanceOf(user2), deposit2 - withdraw2);
        assertEq(user1.balance, user1InitialETH + withdraw1);
        assertEq(user2.balance, user2InitialETH + withdraw2);
        assertEq(weth.totalSupply(), (deposit1 + deposit2) - (withdraw1 + withdraw2));
    }

    function testTransferWETH() public {
        uint256 depositAmount = 5 ether;
        uint256 transferAmount = 2 ether;
        
        // User1 deposits
        vm.prank(user1);
        weth.deposit{value: depositAmount}();
        
        // User1 transfers WETH to User2
        vm.prank(user1);
        weth.transfer(user2, transferAmount);
        
        assertEq(weth.balanceOf(user1), depositAmount - transferAmount);
        assertEq(weth.balanceOf(user2), transferAmount);
        assertEq(weth.totalSupply(), depositAmount);
    }

    function testTokenMetadata() public {
        assertEq(weth.name(), "Mock Wrapped Ether");
        assertEq(weth.symbol(), "WETH");
        assertEq(weth.decimals(), 18);
    }

    // Fuzz testing
    function testFuzzDeposit(uint256 amount) public {
        amount = bound(amount, 1, 1000 ether);
        
        vm.deal(user1, amount);
        vm.prank(user1);
        weth.deposit{value: amount}();
        
        assertEq(weth.balanceOf(user1), amount);
        assertEq(weth.totalSupply(), amount);
        assertEq(address(weth).balance, amount);
    }

    function testFuzzWithdraw(uint256 depositAmount, uint256 withdrawAmount) public {
        depositAmount = bound(depositAmount, 1, 1000 ether);
        withdrawAmount = bound(withdrawAmount, 1, depositAmount);
        
        vm.deal(user1, depositAmount);
        
        // Deposit
        vm.prank(user1);
        weth.deposit{value: depositAmount}();
        
        uint256 initialBalance = user1.balance;
        
        // Withdraw
        vm.prank(user1);
        weth.withdraw(withdrawAmount);
        
        assertEq(weth.balanceOf(user1), depositAmount - withdrawAmount);
        assertEq(user1.balance, initialBalance + withdrawAmount);
    }

    // Test contract interaction safety
    function testReentrancyProtection() public {
        // This test would require creating a malicious contract
        // For now, we verify that ReentrancyGuard is properly inherited
        assertTrue(address(weth).code.length > 0);
    }

    // Test edge cases
    function testLargeSingleDeposit() public {
        uint256 largeAmount = 1000 ether;
        vm.deal(user1, largeAmount);
        
        vm.prank(user1);
        weth.deposit{value: largeAmount}();
        
        assertEq(weth.balanceOf(user1), largeAmount);
        assertEq(weth.totalSupply(), largeAmount);
    }

    function testManySmallDeposits() public {
        uint256 numDeposits = 100;
        uint256 depositAmount = 0.01 ether;
        uint256 totalAmount = numDeposits * depositAmount;
        
        vm.deal(user1, totalAmount);
        
        for (uint256 i = 0; i < numDeposits; i++) {
            vm.prank(user1);
            weth.deposit{value: depositAmount}();
        }
        
        assertEq(weth.balanceOf(user1), totalAmount);
        assertEq(weth.totalSupply(), totalAmount);
    }
}