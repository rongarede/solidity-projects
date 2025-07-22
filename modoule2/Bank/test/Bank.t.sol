// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/Bank.sol";

contract BankTest is Test {
    Bank bank;
    address owner;
    address user1;
    address user2;
    address user3;
    address user4;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        user4 = makeAddr("user4");
        
        bank = new Bank();
        
        // 给测试用户一些ETH
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);
        vm.deal(user4, 10 ether);
    }

    function testConstructor() public {
        assertEq(bank.owner(), owner);
    }

    function testDeposit() public {
        vm.startPrank(user1);
        bank.deposit{value: 1 ether}();
        vm.stopPrank();
        
        assertEq(bank.balances(user1), 1 ether);
        assertEq(address(bank).balance, 1 ether);
    }

    function testReceiveFunction() public {
        vm.startPrank(user1);
        (bool success,) = address(bank).call{value: 2 ether}("");
        require(success, "Transfer failed");
        vm.stopPrank();
        
        assertEq(bank.balances(user1), 2 ether);
        assertEq(address(bank).balance, 2 ether);
    }

    function testWithdraw() public {
        // 先存款
        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        
        // 给测试合约ETH以便接收提款
        vm.deal(address(this), 1 ether);
        
        uint256 initialOwnerBalance = address(this).balance;
        bank.withdraw(1 ether);
        
        assertEq(address(bank).balance, 0);
        assertEq(address(this).balance, initialOwnerBalance + 1 ether);
        assertEq(bank.balances(user1), 1 ether);
    }

    function testWithdrawOnlyOwner() public {
        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        
        vm.prank(user1);
        vm.expectRevert();
        bank.withdraw(1 ether);
    }

    function testWithdrawInsufficientBalance() public {
        vm.expectRevert("Insufficient balance");
        bank.withdraw(1 ether);
    }

    function testZeroDeposit() public {
        vm.prank(user1);
        vm.expectRevert("Zero deposit");
        bank.deposit{value: 0}();
    }

    function testDepositEvent() public {
        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit Bank.Deposit(user1, 1 ether);
        bank.deposit{value: 1 ether}();
    }

    function testWithdrawEvent() public {
        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        
        vm.deal(address(this), 1 ether);
        
        vm.expectEmit(true, false, false, true);
        emit Bank.Withdraw(address(this), 1 ether);
        bank.withdraw(1 ether);
    }

    function testTop3InitialState() public {
        (address[3] memory users, uint256[3] memory amounts) = bank.getTop3();
        
        for (uint i = 0; i < 3; i++) {
            assertEq(users[i], address(0));
            assertEq(amounts[i], 0);
        }
    }

    function testTop3SingleDeposit() public {
        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        
        (address[3] memory users, uint256[3] memory amounts) = bank.getTop3();
        
        assertEq(users[0], user1);
        assertEq(amounts[0], 1 ether);
        assertEq(users[1], address(0));
        assertEq(amounts[1], 0);
    }

    function testTop3MultipleDeposits() public {
        // user1 存款 3 ether
        vm.prank(user1);
        bank.deposit{value: 3 ether}();
        
        // user2 存款 1 ether  
        vm.prank(user2);
        bank.deposit{value: 1 ether}();
        
        // user3 存款 2 ether
        vm.prank(user3);
        bank.deposit{value: 2 ether}();
        
        (address[3] memory users, uint256[3] memory amounts) = bank.getTop3();
        
        // 应该按降序排列: user1(3), user3(2), user2(1)
        assertEq(users[0], user1);
        assertEq(amounts[0], 3 ether);
        assertEq(users[1], user3);
        assertEq(amounts[1], 2 ether);
        assertEq(users[2], user2);
        assertEq(amounts[2], 1 ether);
    }

    function testTop3UpdateExistingUser() public {
        // 初始存款
        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        
        vm.prank(user2);
        bank.deposit{value: 2 ether}();
        
        vm.prank(user3);
        bank.deposit{value: 3 ether}();
        
        // user1 再次存款，总额变为 3 ether
        vm.prank(user1);
        bank.deposit{value: 2 ether}();
        
        (address[3] memory users, uint256[3] memory amounts) = bank.getTop3();
        
        // 验证排序正确
        assertEq(amounts[0], 3 ether);
        assertEq(amounts[1], 3 ether);
        assertEq(amounts[2], 2 ether);
        
        // 验证用户地址
        assertTrue(users[0] == user3 || users[0] == user1);
        assertTrue(users[1] == user3 || users[1] == user1);
        assertEq(users[2], user2);
    }

    function testTop3MoreThanThreeUsers() public {
        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        
        vm.prank(user2);
        bank.deposit{value: 2 ether}();
        
        vm.prank(user3);
        bank.deposit{value: 3 ether}();
        
        vm.prank(user4);
        bank.deposit{value: 4 ether}();
        
        (address[3] memory users, uint256[3] memory amounts) = bank.getTop3();
        
        // 应该只显示前3名: user4(4), user3(3), user2(2)
        assertEq(users[0], user4);
        assertEq(amounts[0], 4 ether);
        assertEq(users[1], user3);
        assertEq(amounts[1], 3 ether);
        assertEq(users[2], user2);
        assertEq(amounts[2], 2 ether);
    }

    function testMultipleDepositsFromSameUser() public {
        vm.startPrank(user1);
        
        bank.deposit{value: 1 ether}();
        assertEq(bank.balances(user1), 1 ether);
        
        bank.deposit{value: 2 ether}();
        assertEq(bank.balances(user1), 3 ether);
        
        bank.deposit{value: 0.5 ether}();
        assertEq(bank.balances(user1), 3.5 ether);
        
        vm.stopPrank();
    }

    fallback() external payable {}
}