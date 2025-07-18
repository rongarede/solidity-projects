// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MemeToken is ERC20, Ownable {
    uint256 public totalSupplyLimit;
    address public factory;
    bool private initialized;
    string private _tokenName;
    string private _tokenSymbol;

    event Initialized(string symbol, uint256 totalSupply, address owner);
    event TokensMinted(address to, uint256 amount);

    error AlreadyInitialized();
    error OnlyFactory();
    error ExceedsTotalSupply();
    error ZeroAddress();
    error ZeroAmount();

    constructor() ERC20("", "") Ownable(msg.sender) {
        // factory will be set during initialization for clones
    }

    function initialize(
        string memory tokenSymbol,
        uint256 totalSupply,
        address owner
    ) external {
        if (initialized) revert AlreadyInitialized();
        if (owner == address(0)) revert ZeroAddress();
        if (totalSupply == 0) revert ZeroAmount();

        _tokenName = "MemeToken";
        _tokenSymbol = tokenSymbol;
        totalSupplyLimit = totalSupply;
        factory = msg.sender; // Set factory to the caller (MemeFactory)
        _transferOwnership(owner);
        initialized = true;

        emit Initialized(tokenSymbol, totalSupply, owner);
    }

    function name() public view override returns (string memory) {
        return _tokenName;
    }

    function symbol() public view override returns (string memory) {
        return _tokenSymbol;
    }

    function mint(address to, uint256 amount) external {
        if (msg.sender != factory) revert OnlyFactory();
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        if (totalSupply() + amount > totalSupplyLimit) revert ExceedsTotalSupply();

        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    function getRemainingSupply() external view returns (uint256) {
        return totalSupplyLimit - totalSupply();
    }

    function isInitialized() external view returns (bool) {
        return initialized;
    }
}