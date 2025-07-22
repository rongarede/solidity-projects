// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMemeToken is IERC20 {
    struct TokenConfig {
        string name;
        string symbol;
        uint256 totalSupply;
        uint256 pricePerToken;
        address creator;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _pricePerToken,
        address _creator,
        address _factory
    ) external;

    function mint(address to, uint256 amount) external;
    
    function getTokenInfo() external view returns (TokenConfig memory);
    
    function factory() external view returns (address);
}