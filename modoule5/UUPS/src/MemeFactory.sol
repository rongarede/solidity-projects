// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "./MemeToken.sol";

/**
 * @title MemeFactory
 * @dev Meme 代币工厂合约，负责部署和管理 Meme 代币
 */
contract MemeFactory is Ownable, ReentrancyGuard {
    /// @dev MemeToken 实现合约地址
    address public immutable implementation;
    
    /// @dev 平台费率 (1% = 100)
    uint256 public constant PLATFORM_FEE_RATE = 100;
    uint256 public constant FEE_DENOMINATOR = 10000;
    
    /// @dev 平台累计收益
    uint256 public platformRevenue;
    
    /// @dev 已部署的代币地址列表
    address[] public deployedTokens;
    
    /// @dev 代币地址到索引的映射
    mapping(address => uint256) public tokenIndex;
    
    /// @dev 代币地址到发行者的映射
    mapping(address => address) public tokenToIssuer;

    /// @dev 事件定义
    event MemeTokenDeployed(
        address indexed tokenAddress,
        address indexed issuer,
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
        uint256 issuerRevenue
    );
    
    event PlatformRevenueWithdrawn(address indexed owner, uint256 amount);

    constructor() Ownable(msg.sender) {
        // 部署 MemeToken 实现合约
        implementation = address(new MemeToken());
    }

    /**
     * @dev 部署新的 Meme 代币
     * @param symbol 代币符号
     * @param totalSupply 总供应量
     * @param perMint 每次最大铸造数量
     * @param price 每个代币价格
     * @return tokenAddress 新部署的代币地址
     */
    function deployMeme(
        string memory symbol,
        uint256 totalSupply,
        uint256 perMint,
        uint256 price
    ) external returns (address tokenAddress) {
        require(bytes(symbol).length > 0, "MemeFactory: symbol cannot be empty");
        require(totalSupply > 0, "MemeFactory: totalSupply must be greater than 0");
        require(perMint > 0, "MemeFactory: perMint must be greater than 0");
        require(price > 0, "MemeFactory: price must be greater than 0");
        require(perMint <= totalSupply, "MemeFactory: perMint cannot exceed totalSupply");

        // 准备初始化数据
        bytes memory initData = abi.encodeWithSelector(
            MemeToken.initialize.selector,
            symbol,
            totalSupply,
            perMint,
            price,
            msg.sender // 调用者作为发行者
        );

        // 使用 ERC1967Proxy 部署代理合约
        ERC1967Proxy proxy = new ERC1967Proxy(implementation, initData);
        tokenAddress = address(proxy);

        // 记录部署信息
        tokenIndex[tokenAddress] = deployedTokens.length;
        deployedTokens.push(tokenAddress);
        tokenToIssuer[tokenAddress] = msg.sender;

        emit MemeTokenDeployed(
            tokenAddress,
            msg.sender,
            symbol,
            totalSupply,
            perMint,
            price
        );
    }

    /**
     * @dev 铸造 Meme 代币（付费铸造）
     * @param tokenAddr 代币合约地址
     * @param amount 铸造数量
     */
    function mintMeme(address tokenAddr, uint256 amount) 
        external 
        payable 
        nonReentrant 
    {
        require(tokenAddr != address(0), "MemeFactory: invalid token address");
        require(amount > 0, "MemeFactory: amount must be greater than 0");
        require(tokenToIssuer[tokenAddr] != address(0), "MemeFactory: token not deployed by factory");

        MemeToken token = MemeToken(tokenAddr);
        
        // 检查铸造限制
        require(amount <= token.perMint(), "MemeFactory: amount exceeds perMint limit");
        require(!token.isMaxSupplyReached(), "MemeFactory: max supply reached");
        require(
            token.totalMinted() + amount <= token.maxTotalSupply(),
            "MemeFactory: would exceed max supply"
        );

        // 计算费用
        uint256 unitPrice = token.price();
        uint256 totalCost = unitPrice * amount;
        require(msg.value >= totalCost, "MemeFactory: insufficient payment");

        // 计算分账
        uint256 platformFee = (totalCost * PLATFORM_FEE_RATE) / FEE_DENOMINATOR;
        uint256 issuerRevenue = totalCost - platformFee;

        // 更新平台收益
        platformRevenue += platformFee;

        // 铸造代币
        token.mint(msg.sender, amount);

        // 转账给发行者
        address issuer = tokenToIssuer[tokenAddr];
        if (issuerRevenue > 0) {
            (bool success, ) = payable(issuer).call{value: issuerRevenue}("");
            require(success, "MemeFactory: transfer to issuer failed");
        }

        // 退还多余的ETH
        if (msg.value > totalCost) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - totalCost}("");
            require(success, "MemeFactory: refund failed");
        }

        emit MemeMinted(
            tokenAddr,
            msg.sender,
            amount,
            totalCost,
            platformFee,
            issuerRevenue
        );
    }

    /**
     * @dev 提取平台收益（仅owner）
     */
    function withdrawPlatformRevenue() external onlyOwner {
        uint256 amount = platformRevenue;
        require(amount > 0, "MemeFactory: no revenue to withdraw");
        
        platformRevenue = 0;
        
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "MemeFactory: withdrawal failed");
        
        emit PlatformRevenueWithdrawn(owner(), amount);
    }

    /**
     * @dev 获取已部署的代币数量
     */
    function getDeployedTokensCount() external view returns (uint256) {
        return deployedTokens.length;
    }

    /**
     * @dev 获取指定范围的已部署代币地址
     * @param start 起始索引
     * @param end 结束索引
     */
    function getDeployedTokens(uint256 start, uint256 end) 
        external 
        view 
        returns (address[] memory) 
    {
        require(start <= end, "MemeFactory: invalid range");
        require(end < deployedTokens.length, "MemeFactory: end index out of bounds");
        
        address[] memory result = new address[](end - start + 1);
        for (uint256 i = start; i <= end; i++) {
            result[i - start] = deployedTokens[i];
        }
        return result;
    }

    /**
     * @dev 获取代币的详细信息
     * @param tokenAddr 代币地址
     */
    function getTokenInfo(address tokenAddr) 
        external 
        view 
        returns (
            string memory name,
            string memory symbol,
            uint256 totalSupply,
            uint256 maxTotalSupply,
            uint256 perMint,
            uint256 price,
            address issuer,
            bool isMaxSupplyReached
        ) 
    {
        require(tokenToIssuer[tokenAddr] != address(0), "MemeFactory: token not found");
        
        MemeToken token = MemeToken(tokenAddr);
        name = token.name();
        symbol = token.symbol();
        totalSupply = token.totalMinted();
        maxTotalSupply = token.maxTotalSupply();
        perMint = token.perMint();
        price = token.price();
        issuer = tokenToIssuer[tokenAddr];
        isMaxSupplyReached = token.isMaxSupplyReached();
    }
}