// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MemeToken.sol";

contract MemeFactory is Ownable {
    using Clones for address;

    address public immutable memeTokenImplementation;
    uint256 public constant PLATFORM_FEE_PERCENTAGE = 1;
    uint256 public constant CREATOR_FEE_PERCENTAGE = 99;

    struct MemeInfo {
        address creator;
        uint256 totalSupply;
        uint256 perMint;
        uint256 price;
        uint256 totalMinted;
    }

    mapping(address => MemeInfo) public memeTokens;
    address[] public allMemeTokens;

    event MemeDeployed(
        address indexed tokenAddress,
        address indexed creator,
        string symbol,
        uint256 totalSupply,
        uint256 perMint,
        uint256 price
    );

    event MemeMinted(
        address indexed tokenAddress,
        address indexed buyer,
        uint256 amount,
        uint256 totalCost,
        uint256 platformFee,
        uint256 creatorFee
    );

    error ZeroAddress();
    error ZeroAmount();
    error InsufficientPayment();
    error ExceedsRemainingSupply();
    error InvalidMemeToken();
    error TransferFailed();

    constructor() Ownable(msg.sender) {
        memeTokenImplementation = address(new MemeToken());
    }

    function deployMeme(
        string memory symbol,
        uint256 totalSupply,
        uint256 perMint,
        uint256 price
    ) external returns (address) {
        if (totalSupply == 0) revert ZeroAmount();
        if (perMint == 0) revert ZeroAmount();
        if (perMint > totalSupply) revert ExceedsRemainingSupply();

        address clone = memeTokenImplementation.clone();
        
        MemeToken(clone).initialize(symbol, totalSupply, msg.sender);

        memeTokens[clone] = MemeInfo({
            creator: msg.sender,
            totalSupply: totalSupply,
            perMint: perMint,
            price: price,
            totalMinted: 0
        });

        allMemeTokens.push(clone);

        emit MemeDeployed(clone, msg.sender, symbol, totalSupply, perMint, price);

        return clone;
    }

    function mintMeme(address tokenAddr) external payable {
        MemeInfo storage memeInfo = memeTokens[tokenAddr];
        if (memeInfo.creator == address(0)) revert InvalidMemeToken();

        uint256 totalCost = memeInfo.perMint * memeInfo.price;
        if (msg.value < totalCost) revert InsufficientPayment();

        uint256 remainingSupply = memeInfo.totalSupply - memeInfo.totalMinted;
        if (remainingSupply < memeInfo.perMint) revert ExceedsRemainingSupply();

        memeInfo.totalMinted += memeInfo.perMint;

        MemeToken(tokenAddr).mint(msg.sender, memeInfo.perMint);

        if (totalCost > 0) {
            uint256 platformFee = (totalCost * PLATFORM_FEE_PERCENTAGE) / 100;
            uint256 creatorFee = (totalCost * CREATOR_FEE_PERCENTAGE) / 100;

            if (platformFee > 0) {
                (bool success, ) = payable(owner()).call{value: platformFee}("");
                if (!success) revert TransferFailed();
            }

            if (creatorFee > 0) {
                (bool success, ) = payable(memeInfo.creator).call{value: creatorFee}("");
                if (!success) revert TransferFailed();
            }

            emit MemeMinted(tokenAddr, msg.sender, memeInfo.perMint, totalCost, platformFee, creatorFee);
        }

        if (msg.value > totalCost) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - totalCost}("");
            if (!success) revert TransferFailed();
        }
    }

    function getMemeInfo(address tokenAddr) external view returns (MemeInfo memory) {
        return memeTokens[tokenAddr];
    }

    function getRemainingSupply(address tokenAddr) external view returns (uint256) {
        MemeInfo storage memeInfo = memeTokens[tokenAddr];
        return memeInfo.totalSupply - memeInfo.totalMinted;
    }

    function getAllMemeTokens() external view returns (address[] memory) {
        return allMemeTokens;
    }

    function getTotalMemeTokens() external view returns (uint256) {
        return allMemeTokens.length;
    }
}