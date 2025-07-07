// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/BigBank.sol";
import "../src/Admin.sol";
import "../src/IBank.sol";

contract BigBankSystemTest is Test {
    BigBank public bigBank;
    Admin public admin;
    
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public user3 = address(0x3);
    address public adminOwner = address(0x4);

    function setUp() public {
        bigBank = new BigBank();
        
        vm.prank(adminOwner);
        admin = new Admin();
        
        // 转移 BigBank 所有权给 Admin 合约
        bigBank.transferOwnership(address(admin));
    }

    function testMinDepositRequirement() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        
        // 应该失败：低于最小存款
        vm.expectRevert("Minimum deposit is 0.001 ether");
        bigBank.deposit{value: 0.0001 ether}();
        
        // 应该成功：满足最小存款
        bigBank.deposit{value: 0.001 ether}();
        assertEq(bigBank.balances(user1), 0.001 ether);
    }

    function testAdminWithdraw() public {
        // 用户存款
        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
        
        vm.prank(user1);
        bigBank.deposit{value: 0.01 ether}();
        
        vm.prank(user2);
        bigBank.deposit{value: 0.02 ether}();
        
        uint256 totalDeposits = 0.03 ether;
        assertEq(address(bigBank).balance, totalDeposits);
        
        // Admin 提取资金
        vm.prank(adminOwner);
        admin.adminWithdraw(IBank(address(bigBank)));
        
        // 验证资金已转移到 Admin 合约
        assertEq(address(bigBank).balance, 0);
        assertEq(admin.getBalance(), totalDeposits);
    }

    function testOnlyAdminOwnerCanWithdraw() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        bigBank.deposit{value: 0.01 ether}();
        
        // 非 admin owner 不能提取
        vm.prank(user1);
        vm.expectRevert();
        admin.adminWithdraw(IBank(address(bigBank)));
    }

    function testAdminMustBebankOwner() public {
        // 创建另一个银行合约，不转移所有权
        BigBank anotherBank = new BigBank();
        
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        anotherBank.deposit{value: 0.01 ether}();
        
        // Admin 不是这个银行的 owner，应该失败
        vm.prank(adminOwner);
        vm.expectRevert("Admin is not the bank owner");
        admin.adminWithdraw(IBank(address(anotherBank)));
    }
}