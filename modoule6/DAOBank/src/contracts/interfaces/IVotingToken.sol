// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC5805.sol";

/**
 * @title IVotingToken
 * @dev Interface for the VotingToken contract
 */
interface IVotingToken is IERC20, IERC5805 {
    
    /**
     * @dev Mints tokens to a specified address (owner only)
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Burns tokens from a specified address (owner only) 
     * @param from Address to burn tokens from
     * @param amount Amount of tokens to burn
     */
    function burn(address from, uint256 amount) external;

    /**
     * @dev Get the current voting power of an account
     * @param account Address to check voting power for
     * @return Current voting power
     */
    function getCurrentVotes(address account) external view returns (uint256);

    /**
     * @dev Get the voting power at a specific block number
     * @param account Address to check voting power for
     * @param blockNumber Block number to check at
     * @return Historical voting power
     */
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);
}