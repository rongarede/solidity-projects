// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title MockWETH
 * @dev A mock implementation of Wrapped Ether (WETH)
 * Allows users to deposit ETH and receive equivalent WETH tokens,
 * and withdraw ETH by burning WETH tokens
 */
contract MockWETH is ERC20, ReentrancyGuard {
    // Custom errors for better gas efficiency and clearer error messages
    error InsufficientBalance();
    error TransferFailed();
    error InvalidAmount();

    // Events for tracking deposits and withdrawals
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    constructor() ERC20("Mock Wrapped Ether", "WETH") {}

    /**
     * @dev Deposit ETH and mint equivalent WETH tokens
     * Callable via direct function call or fallback/receive
     */
    function deposit() external payable nonReentrant {
        if (msg.value == 0) revert InvalidAmount();
        
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Withdraw ETH by burning WETH tokens
     * @param amount Amount of WETH to burn and ETH to withdraw
     */
    function withdraw(uint256 amount) external nonReentrant {
        if (amount == 0) revert InvalidAmount();
        if (balanceOf(msg.sender) < amount) revert InsufficientBalance();

        _burn(msg.sender, amount);
        
        // Send ETH to user
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();
        
        emit Withdrawal(msg.sender, amount);
    }

    /**
     * @dev Fallback function to handle direct ETH transfers
     * Automatically converts sent ETH to WETH
     */
    receive() external payable {
        if (msg.value > 0) {
            _mint(msg.sender, msg.value);
            emit Deposit(msg.sender, msg.value);
        }
    }

    /**
     * @dev Fallback function for any other calls
     * Also handles ETH deposits
     */
    fallback() external payable {
        if (msg.value > 0) {
            _mint(msg.sender, msg.value);
            emit Deposit(msg.sender, msg.value);
        }
    }

    /**
     * @dev Get the total amount of ETH held by this contract
     * Should equal totalSupply of WETH tokens
     */
    function totalETH() external view returns (uint256) {
        return address(this).balance;
    }
}