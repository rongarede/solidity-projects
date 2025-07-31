// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

/**
 * @title KKToken
 * @dev Reward token for the StakingPool system
 * Only addresses with MINTER_ROLE can mint new tokens
 * Designed for use in DeFi staking and reward distribution
 */
contract KKToken is ERC20, AccessControlEnumerable {
    // Role identifier for minting permissions
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Custom errors
    error UnauthorizedMinter();
    error InvalidAmount();
    error InvalidAddress();

    // Events
    event TokenMinted(address indexed to, uint256 amount, address indexed minter);
    event MinterRoleGranted(address indexed account, address indexed admin);
    event MinterRoleRevoked(address indexed account, address indexed admin);

    /**
     * @dev Constructor sets up the token with 18 decimals
     * Grants DEFAULT_ADMIN_ROLE and MINTER_ROLE to the deployer
     * @param initialAdmin Address that will have admin privileges
     */
    constructor(address initialAdmin) ERC20("KK Token", "KK") {
        if (initialAdmin == address(0)) revert InvalidAddress();
        
        // Grant roles to initial admin
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(MINTER_ROLE, initialAdmin);
    }

    /**
     * @dev Mint new tokens to a specified address
     * Can only be called by addresses with MINTER_ROLE
     * @param to Address to receive the minted tokens
     * @param amount Amount of tokens to mint (in wei, 18 decimals)
     */
    function mint(address to, uint256 amount) external {
        if (!hasRole(MINTER_ROLE, msg.sender)) revert UnauthorizedMinter();
        if (to == address(0)) revert InvalidAddress();
        if (amount == 0) revert InvalidAmount();

        _mint(to, amount);
        emit TokenMinted(to, amount, msg.sender);
    }

    /**
     * @dev Grant MINTER_ROLE to an address
     * Can only be called by addresses with DEFAULT_ADMIN_ROLE
     * @param account Address to grant minter role to
     */
    function grantMinterRole(address account) external {
        if (account == address(0)) revert InvalidAddress();
        
        grantRole(MINTER_ROLE, account);
        emit MinterRoleGranted(account, msg.sender);
    }

    /**
     * @dev Revoke MINTER_ROLE from an address
     * Can only be called by addresses with DEFAULT_ADMIN_ROLE
     * @param account Address to revoke minter role from
     */
    function revokeMinterRole(address account) external {
        revokeRole(MINTER_ROLE, account);
        emit MinterRoleRevoked(account, msg.sender);
    }

    /**
     * @dev Check if an address has minter role
     * @param account Address to check
     * @return bool True if address has minter role
     */
    function isMinter(address account) external view returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }

    /**
     * @dev Get the total number of addresses with minter role
     * Useful for governance and monitoring
     * @return count Number of minters
     */
    function getMinterCount() external view returns (uint256 count) {
        return getRoleMemberCount(MINTER_ROLE);
    }

    /**
     * @dev Get minter address by index
     * @param index Index in the minter list
     * @return address Address of the minter
     */
    function getMinter(uint256 index) external view returns (address) {
        return getRoleMember(MINTER_ROLE, index);
    }

    /**
     * @dev Override supportsInterface to include AccessControl
     */
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(AccessControlEnumerable) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }
}