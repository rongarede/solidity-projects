// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./IBank.sol";

contract Admin is Ownable {
    constructor() Ownable(msg.sender) {}

    event AdminWithdraw(address indexed bank, uint256 amount);

    receive() external payable {}

    function adminWithdraw(IBank bank) external onlyOwner {
        // 确保 Admin 合约是目标 bank 的 owner
        address bankAddress = address(bank);
        Ownable ownableBank = Ownable(bankAddress);
        require(ownableBank.owner() == address(this), "Admin is not the bank owner");
        
        // 获取当前 bank 合约余额
        uint256 balance = bankAddress.balance;
        require(balance > 0, "No funds to withdraw");
        
        // 调用 bank 的 withdraw 方法，资金会转入到 bank 的 owner（即 Admin 合约）
        bank.withdraw(balance);
        
        emit AdminWithdraw(bankAddress, balance);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}