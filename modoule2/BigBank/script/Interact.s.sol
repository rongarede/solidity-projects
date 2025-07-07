// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/BigBank.sol";
import "../src/Admin.sol";
import "../src/IBank.sol";

contract InteractScript is Script {
    function run() external {
        // 从环境变量获取合约地址，或在此处设置
        address bigBankAddress = vm.envAddress("BIGBANK_ADDRESS");
        address adminAddress = vm.envAddress("ADMIN_ADDRESS");
        
        BigBank bigBank = BigBank(payable(bigBankAddress));
        Admin admin = Admin(payable(adminAddress));

        vm.startBroadcast();

        // 模拟用户存款
        console.log("=== User Deposits ===");
        console.log("BigBank balance before deposits:", address(bigBank).balance);
        
        // 用户1存款 0.01 ether
        bigBank.deposit{value: 0.01 ether}();
        console.log("Deposited 0.01 ether");
        
        // 用户2存款 0.02 ether  
        bigBank.deposit{value: 0.02 ether}();
        console.log("Deposited 0.02 ether");
        
        // 用户3存款 0.005 ether
        bigBank.deposit{value: 0.005 ether}();
        console.log("Deposited 0.005 ether");

        console.log("BigBank balance after deposits:", address(bigBank).balance);

        // Admin 提取资金
        console.log("=== Admin Withdraw ===");
        console.log("Admin balance before withdraw:", admin.getBalance());
        
        admin.adminWithdraw(IBank(address(bigBank)));
        
        console.log("Admin balance after withdraw:", admin.getBalance());
        console.log("BigBank balance after withdraw:", address(bigBank).balance);

        vm.stopBroadcast();
    }
}