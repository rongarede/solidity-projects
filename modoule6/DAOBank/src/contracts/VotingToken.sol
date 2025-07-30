// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title VotingToken
 * @dev ERC20 token with voting capabilities for DAO governance
 * Features:
 * - Standard ERC20 functionality
 * - Vote delegation system
 * - Historical vote tracking with checkpoints
 * - Permit functionality for gasless approvals
 */
contract VotingToken is ERC20, ERC20Permit, ERC20Votes, Ownable {
    
    /// @dev Total supply of tokens (1 million tokens with 18 decimals)
    uint256 public constant TOTAL_SUPPLY = 1_000_000 * 10**18;
    
    /**
     * @dev Contract constructor
     * @param _name Token name
     * @param _symbol Token symbol
     * @param _initialOwner Initial owner of the contract
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _initialOwner
    ) 
        ERC20(_name, _symbol) 
        ERC20Permit(_name)
        Ownable(_initialOwner)
    {
        // Mint total supply to the initial owner
        _mint(_initialOwner, TOTAL_SUPPLY);
    }

    /**
     * @dev Mints tokens to a specified address (owner only)
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Burns tokens from a specified address (owner only)
     * @param from Address to burn tokens from
     * @param amount Amount of tokens to burn
     */
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    /**
     * @dev Get the current voting power of an account
     * @param account Address to check voting power for
     * @return Current voting power
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        return getVotes(account);
    }

    /**
     * @dev Get the voting power at a specific block number
     * @param account Address to check voting power for
     * @param blockNumber Block number to check at
     * @return Historical voting power
     */
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256) {
        return getPastVotes(account, blockNumber);
    }

    // Required overrides for multiple inheritance

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from, to, value);
    }

    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}