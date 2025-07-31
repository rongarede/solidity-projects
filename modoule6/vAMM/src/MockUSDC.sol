// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockUSDC
 * @dev A mock USDC token for testing purposes
 */
contract MockUSDC is ERC20 {
    uint8 private _decimals;

    constructor() ERC20("Mock USDC", "USDC") {
        _decimals = 6; // USDC has 6 decimals
        // Mint initial supply to deployer for testing
        _mint(msg.sender, 1000000 * 10**_decimals); // 1M USDC
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Mint tokens to a specific address (for testing)
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /**
     * @dev Burn tokens from a specific address (for testing)
     */
    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}