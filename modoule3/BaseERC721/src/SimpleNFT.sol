// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Counters.sol";

/**
 * @title SimpleNFT
 * @dev 简化的 ERC721 合约，用于测试和学习
 */
contract SimpleNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    
    // ============ State Variables ============
    
    Counters.Counter private _tokenIdCounter;
    
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public mintPrice = 0.01 ether;
    
    string private _baseTokenURI;
    
    // ============ Events ============
    
    event Minted(address indexed to, uint256 indexed tokenId);
    event PriceUpdated(uint256 newPrice);
    
    // ============ Errors ============
    
    error MaxSupplyExceeded();
    error InsufficientPayment();
    error ZeroAddress();
    error WithdrawFailed();
    
    // ============ Constructor ============
    
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
    }
    
    // ============ Minting Functions ============
    
    /**
     * @notice 公共铸造函数
     * @param to 接收地址
     */
    function mint(address to) external payable {
        if (to == address(0)) revert ZeroAddress();
        if (totalSupply() >= MAX_SUPPLY) revert MaxSupplyExceeded();
        if (msg.value < mintPrice) revert InsufficientPayment();
        
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        
        _safeMint(to, tokenId);
        
        emit Minted(to, tokenId);
    }
    
    /**
     * @notice 管理员免费铸造
     * @param to 接收地址
     * @param quantity 铸造数量
     */
    function adminMint(address to, uint256 quantity) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();
        if (totalSupply() + quantity > MAX_SUPPLY) revert MaxSupplyExceeded();
        
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
            emit Minted(to, tokenId);
        }
    }
    
    // ============ Admin Functions ============
    
    /**
     * @notice 设置铸造价格
     * @param newPrice 新价格
     */
    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
        emit PriceUpdated(newPrice);
    }
    
    /**
     * @notice 设置基础 URI
     * @param baseTokenURI 新的基础 URI
     */
    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }
    
    /**
     * @notice 提取合约余额
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(owner()).call{value: balance}("");
        if (!success) revert WithdrawFailed();
    }
    
    // ============ View Functions ============
    
    /**
     * @notice 获取当前总供应量
     */
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }
    
    /**
     * @notice 获取基础 URI
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    
    /**
     * @notice 获取合约余额
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @notice 检查是否售罄
     */
    function isSoldOut() external view returns (bool) {
        return totalSupply() >= MAX_SUPPLY;
    }
}
