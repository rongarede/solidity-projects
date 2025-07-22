// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMemeToken.sol";

contract MemeToken is ERC20, Ownable, IMemeToken {
    TokenConfig private _tokenConfig;
    address public factory;
    bool private _initialized;

    modifier onlyFactory() {
        require(msg.sender == factory, "Only factory can call this function");
        _;
    }

    constructor() ERC20("", "") Ownable(msg.sender) {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _pricePerToken,
        address _creator,
        address _factory
    ) external override {
        require(!_initialized, "Already initialized");
        require(_factory != address(0), "Invalid factory address");
        require(_creator != address(0), "Invalid creator address");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_symbol).length > 0, "Symbol cannot be empty");
        require(_totalSupply > 0, "Total supply must be greater than zero");
        require(_pricePerToken > 0, "Price per token must be greater than zero");

        _tokenConfig = TokenConfig({
            name: _name,
            symbol: _symbol,
            totalSupply: _totalSupply,
            pricePerToken: _pricePerToken,
            creator: _creator
        });

        factory = _factory;
        _initialized = true;

        _transferOwnership(_factory);
    }

    function name() public view override returns (string memory) {
        return _tokenConfig.name;
    }

    function symbol() public view override returns (string memory) {
        return _tokenConfig.symbol;
    }

    function mint(address to, uint256 amount) external override onlyFactory {
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Amount must be greater than zero");
        require(
            totalSupply() + amount <= _tokenConfig.totalSupply,
            "Cannot exceed total supply"
        );

        _mint(to, amount);
    }

    function getTokenInfo() external view override returns (TokenConfig memory) {
        return _tokenConfig;
    }

    function _disableInitializers() internal {
        _initialized = true;
    }
}