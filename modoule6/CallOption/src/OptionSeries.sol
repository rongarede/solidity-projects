// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OptionSeries is ERC20, Ownable {
    uint256 public strikePrice;
    uint256 public expiry;
    uint256 public totalCollateral;
    
    // Trading functionality state variables
    bool public pairCreated;
    uint256 public optionReserve;
    uint256 public usdtReserve;
    IERC20 public usdtToken;

    event PairCreated(address indexed usdtAddress, uint256 optionAmount, uint256 usdtAmount);
    event OptionPurchased(address indexed buyer, uint256 usdtAmount, uint256 optionAmount);

    constructor() ERC20("Call Option", "CALL") Ownable(msg.sender) {
        strikePrice = 2000 ether;
        expiry = block.timestamp + 7 days;
    }

    // Original mint function - users provide ETH collateral to mint options
    function mint() external payable {
        require(msg.value > 0, "Must send ETH as collateral");
        
        totalCollateral += msg.value;
        _mint(msg.sender, msg.value);
    }

    // Original exercise function - users pay strike price to exercise options
    function exercise(uint256 amount) external payable {
        require(block.timestamp <= expiry, "Option has expired");
        require(balanceOf(msg.sender) >= amount, "Insufficient option tokens");
        require(msg.value == amount * strikePrice / 1 ether, "Incorrect exercise payment");
        
        _burn(msg.sender, amount);
        totalCollateral -= amount;
        payable(msg.sender).transfer(amount);
    }

    // Original collectExpired function - owner collects remaining collateral after expiry
    function collectExpired() external onlyOwner {
        require(block.timestamp > expiry, "Option not yet expired");
        
        uint256 remainingCollateral = totalCollateral;
        totalCollateral = 0;
        payable(owner()).transfer(remainingCollateral);
    }

    // NEW: Create trading pair - owner provides initial liquidity
    function createPair(address usdtAddress, uint256 optionAmount, uint256 usdtAmount) external onlyOwner {
        require(!pairCreated, "Pair already created");
        require(usdtAddress != address(0), "Invalid USDT address");
        require(optionAmount > 0 && usdtAmount > 0, "Invalid amounts");
        require(balanceOf(msg.sender) >= optionAmount, "Insufficient option tokens");

        usdtToken = IERC20(usdtAddress);
        require(usdtToken.transferFrom(msg.sender, address(this), usdtAmount), "USDT transfer failed");

        // Transfer option tokens from owner to contract as initial liquidity
        _transfer(msg.sender, address(this), optionAmount);
        
        optionReserve = optionAmount;
        usdtReserve = usdtAmount;
        pairCreated = true;

        emit PairCreated(usdtAddress, optionAmount, usdtAmount);
    }

    // NEW: Buy options with USDT - simple fixed price trading
    function buyOption(uint256 usdtAmount) external {
        require(pairCreated, "Trading pair not created");
        require(usdtAmount > 0, "Invalid USDT amount");
        require(block.timestamp <= expiry, "Option has expired");

        // Simple pricing: 100 USDT = 1 option token (assuming 18 decimals for both tokens)
        uint256 optionAmount = usdtAmount / 100;
        require(optionAmount > 0, "USDT amount too small");
        require(optionReserve >= optionAmount, "Insufficient option liquidity");

        // Transfer USDT from buyer to contract
        require(usdtToken.transferFrom(msg.sender, address(this), usdtAmount), "USDT transfer failed");

        // Update reserves
        optionReserve -= optionAmount;
        usdtReserve += usdtAmount;

        // Transfer option tokens to buyer
        _transfer(address(this), msg.sender, optionAmount);

        emit OptionPurchased(msg.sender, usdtAmount, optionAmount);
    }

    // View function to get current reserves
    function getReserves() external view returns (uint256 _optionReserve, uint256 _usdtReserve) {
        return (optionReserve, usdtReserve);
    }

    // View function to calculate option amount for given USDT
    function getOptionAmountOut(uint256 usdtAmount) external pure returns (uint256) {
        return usdtAmount / 100; // Simple 100 USDT = 1 option pricing
    }
}