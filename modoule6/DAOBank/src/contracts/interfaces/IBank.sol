// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IBank
 * @dev Interface for the Bank contract
 */
interface IBank {
    
    // Events
    event Deposit(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawal(address indexed to, uint256 amount, address indexed admin, uint256 timestamp);
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    /**
     * @dev Allows anyone to deposit ETH into the bank
     */
    function deposit() external payable;

    /**
     * @dev Allows admin to withdraw funds to a specified address
     * @param to Address to send funds to
     * @param amount Amount to withdraw in wei
     */
    function withdraw(address to, uint256 amount) external;

    /**
     * @dev Get the current balance of the bank
     * @return Current ETH balance in wei
     */
    function getBalance() external view returns (uint256);

    /**
     * @dev Get the deposit amount for a specific user
     * @param user Address to check deposits for
     * @return Amount deposited by the user
     */
    function getUserDeposit(address user) external view returns (uint256);

    /**
     * @dev Emergency function to change admin (current admin only)
     * @param newAdmin New admin address
     */
    function changeAdmin(address newAdmin) external;
}