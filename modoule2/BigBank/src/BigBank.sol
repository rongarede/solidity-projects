// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Bank.sol";

contract BigBank is Bank {
    modifier minDeposit() {
        require(msg.value >= 0.001 ether, "Minimum deposit is 0.001 ether");
        _;
    }

    function deposit() external payable override minDeposit {
        _handleDeposit(msg.sender, msg.value);
    }

    receive() external payable override minDeposit {
        _handleDeposit(msg.sender, msg.value);
    }
}