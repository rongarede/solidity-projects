// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Address.sol";
import "./IBank.sol";

contract Bank is Ownable, IBank {
    using Address for address payable;

    constructor() Ownable(msg.sender) {}

    struct Depositor {
        address user;
        uint256 amount;
    }

    mapping(address => uint256) public balances;
    Depositor[3] public top3;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed admin, uint256 amount);

    receive() external payable virtual {
        _handleDeposit(msg.sender, msg.value);
    }

    function deposit() external payable virtual {
        _handleDeposit(msg.sender, msg.value);
    }

    // 实现 IBank 接口的 withdraw 函数
    function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(owner()).sendValue(amount);
        emit Withdraw(owner(), amount);
    }

    function getTop3() external view returns (address[3] memory users, uint256[3] memory amounts) {
        for (uint8 i = 0; i < 3; i++) {
            users[i] = top3[i].user;
            amounts[i] = top3[i].amount;
        }
    }

    function _handleDeposit(address user, uint256 amount) internal {
        require(amount > 0, "Zero deposit");
        balances[user] += amount;
        emit Deposit(user, amount);
        _updateTop3(user);
    }

    function _updateTop3(address user) internal {
        uint256 bal = balances[user];

        // If already in top 3
        for (uint8 i = 0; i < 3; i++) {
            if (top3[i].user == user) {
                top3[i].amount = bal;
                while (i > 0 && top3[i].amount > top3[i - 1].amount) {
                    Depositor memory temp = top3[i];
                    top3[i] = top3[i - 1];
                    top3[i - 1] = temp;
                    i--;
                }
                return;
            }
        }

        // Not in top 3, insert if larger than current third
        if (bal > top3[2].amount) {
            top3[2] = Depositor(user, bal);
            uint8 i = 2;
            while (i > 0 && top3[i].amount > top3[i - 1].amount) {
                Depositor memory temp = top3[i];
                top3[i] = top3[i - 1];
                top3[i - 1] = temp;
                i--;
            }
        }
    }
}