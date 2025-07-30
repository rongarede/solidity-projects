// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Bank
 * @dev Simple vault contract for managing funds with admin-only withdrawal
 * Features:
 * - Accept ETH deposits from anyone
 * - Admin-only withdrawals (typically the DAO governance contract)
 * - Reentrancy protection
 * - Comprehensive event logging
 */
contract Bank is ReentrancyGuard, Ownable {
    
    /// @dev Mapping to track individual user deposits
    mapping(address => uint256) public userDeposits;
    
    /// @dev Total amount deposited in the bank
    uint256 public totalDeposits;

    // Events
    event Deposit(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawal(address indexed to, uint256 amount, address indexed admin, uint256 timestamp);
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    /**
     * @dev Contract constructor
     * @param _admin Initial admin address (typically will be the DAO governance contract)
     */
    constructor(address _admin) Ownable(_admin) {
        require(_admin != address(0), "Bank: Admin cannot be zero address");
    }

    /**
     * @dev Allows anyone to deposit ETH into the bank
     */
    function deposit() external payable {
        require(msg.value > 0, "Bank: Deposit amount must be greater than 0");
        
        userDeposits[msg.sender] += msg.value;
        totalDeposits += msg.value;
        
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }

    /**
     * @dev Allows admin to withdraw funds to a specified address
     * @param to Address to send funds to
     * @param amount Amount to withdraw in wei
     */
    function withdraw(address to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "Bank: Cannot withdraw to zero address");
        require(amount > 0, "Bank: Withdrawal amount must be greater than 0");
        require(amount <= address(this).balance, "Bank: Insufficient balance");
        
        totalDeposits -= amount;
        
        emit Withdrawal(to, amount, msg.sender, block.timestamp);
        
        // Use call for safe ETH transfer
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "Bank: ETH transfer failed");
    }

    /**
     * @dev Get the current balance of the bank
     * @return Current ETH balance in wei
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Get the deposit amount for a specific user
     * @param user Address to check deposits for
     * @return Amount deposited by the user
     */
    function getUserDeposit(address user) external view returns (uint256) {
        return userDeposits[user];
    }

    /**
     * @dev Emergency function to change admin (current admin only)
     * @param newAdmin New admin address
     */
    function changeAdmin(address newAdmin) external onlyOwner {
        require(newAdmin != address(0), "Bank: New admin cannot be zero address");
        require(newAdmin != owner(), "Bank: New admin is the same as current admin");
        
        address previousAdmin = owner();
        _transferOwnership(newAdmin);
        
        emit AdminChanged(previousAdmin, newAdmin);
    }

    /**
     * @dev Allow the contract to receive ETH directly
     */
    receive() external payable {
        userDeposits[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }
}