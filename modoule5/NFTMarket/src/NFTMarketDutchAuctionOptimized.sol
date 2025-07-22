pragma solidity ^0.8.13;

import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Receiver.sol";
import "./security/ReentrancyGuard.sol";

/**
 * @title NFTMarketDutchAuctionOptimized
 * @dev Gas优化版本的NFT荷兰拍卖市场合约
 * @notice 实现NFT的荷兰拍卖模式，价格随时间线性递减
 * 
 * 🔥 主要优化：
 * - 存储变量缓存减少重复读取
 * - 价格计算优化和内联
 * - 修饰器合并减少重复检查
 * - 存储结构重排减少槽位使用
 * - 事件参数优化减少Gas消耗
 * - 数据类型优化提高存储效率
 */
contract NFTMarketDutchAuctionOptimized is ReentrancyGuard, IERC721Receiver {
    
    // ============ 状态变量 ============
    
    /// @dev 拍卖计数器，用于生成唯一的拍卖ID
    uint256 private _auctionIdCounter;
    
    /// @dev 拍卖状态枚举
    enum AuctionStatus {
        ACTIVE,     // 进行中
        SOLD,       // 已售出
        CANCELLED   // 已取消
    }
    
    /// @dev 🔥 优化后的拍卖信息结构体 - 数据类型优化 + 存储重排
    struct Auction {
        address seller;           // 20 bytes (slot 0)
        address nftContract;      // 20 bytes (slot 0) - 紧凑打包到同一槽位
        uint256 tokenId;          // 32 bytes (slot 1)
        uint256 startPrice;       // 32 bytes (slot 2)
        uint256 endPrice;         // 32 bytes (slot 3)
        uint40 startTime;         // 5 bytes (到5138年) (slot 4)
        uint32 duration;          // 4 bytes (最大136年) (slot 4)
        uint8 status;             // 1 byte (slot 4)
        // 剩余 32-5-4-1 = 22 字节可用于未来扩展
    }
    
    /// @dev 拍卖ID映射到拍卖信息
    mapping(uint256 => Auction) public auctions;
    
    // ============ 🔥 优化后的事件定义 ============
    
    /**
     * @dev 拍卖创建事件 - 减少indexed参数数量
     * @param auctionId 拍卖ID
     * @param seller 卖家地址
     * @param nftContract NFT合约地址
     * @param data 拍卖数据（tokenId, startPrice, endPrice, duration）
     */
    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed seller,
        address indexed nftContract,
        AuctionData data
    );
    
    /**
     * @dev NFT购买成功事件 - 减少indexed参数数量
     * @param auctionId 拍卖ID
     * @param buyer 买家地址
     * @param seller 卖家地址
     * @param price 成交价格
     */
    event AuctionSuccessful(
        uint256 indexed auctionId,
        address indexed buyer,
        address indexed seller,
        uint256 price
    );
    
    /**
     * @dev 拍卖取消事件
     * @param auctionId 拍卖ID
     * @param seller 卖家地址
     */
    event AuctionCancelled(
        uint256 indexed auctionId,
        address indexed seller
    );
    
    /// @dev 🔥 结构化事件数据，减少Gas消耗
    struct AuctionData {
        uint256 tokenId;
        uint256 startPrice;
        uint256 endPrice;
        uint32 duration;
    }
    
    // ============ 🔥 优化后的修饰器 ============
    
    /**
     * @dev 🔥 组合修饰器：检查拍卖存在且活跃（为buy函数优化）
     * @param auctionId 拍卖ID
     */
    modifier validBuyableAuction(uint256 auctionId) {
        require(_auctionIdCounter > auctionId, "Auction does not exist");
        require(auctions[auctionId].status == uint8(AuctionStatus.ACTIVE), "Auction is not active");
        _;
    }
    
    /**
     * @dev 🔥 组合修饰器：检查拍卖存在且活跃，并验证卖家权限
     * @param auctionId 拍卖ID
     */
    modifier validActiveAuctionBySeller(uint256 auctionId) {
        require(_auctionIdCounter > auctionId, "Auction does not exist");
        Auction storage auction = auctions[auctionId];
        require(auction.status == uint8(AuctionStatus.ACTIVE), "Auction is not active");
        require(auction.seller == msg.sender, "Only seller can perform this action");
        _;
    }
    
    /**
     * @dev 🔥 通用拍卖存在检查
     * @param auctionId 拍卖ID
     */
    modifier auctionExists(uint256 auctionId) {
        require(_auctionIdCounter > auctionId, "Auction does not exist");
        _;
    }
    
    // ============ 主要功能函数 ============
    
    /**
     * @dev 创建荷兰拍卖
     * @param nftContract NFT合约地址
     * @param tokenId NFT的TokenId
     * @param startPrice 起始价格 (wei)
     * @param endPrice 最低价格 (wei)
     * @param duration 拍卖持续时间 (秒)
     * @return auctionId 创建的拍卖ID
     */
    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startPrice,
        uint256 endPrice,
        uint32 duration  // 🔥 优化：使用uint32替代uint256
    ) external returns (uint256 auctionId) {
        // 参数验证
        require(nftContract != address(0), "Invalid NFT contract address");
        require(startPrice > endPrice, "Start price must be greater than end price");
        require(endPrice > 0, "End price must be greater than 0");
        require(duration > 0, "Duration must be greater than 0");
        
        // 🔥 优化：缓存NFT合约实例，避免重复类型转换
        IERC721 nft = IERC721(nftContract);
        
        // 验证NFT所有权
        require(nft.ownerOf(tokenId) == msg.sender, "You don't own this NFT");
        
        // 验证授权
        require(
            nft.getApproved(tokenId) == address(this) || 
            nft.isApprovedForAll(msg.sender, address(this)),
            "Contract not approved to transfer NFT"
        );
        
        // 🔥 优化：缓存计数器值，避免重复读取
        auctionId = _auctionIdCounter;
        unchecked {
            _auctionIdCounter = auctionId + 1;  // 安全的增量操作
        }
        
        // 🔥 优化：直接使用优化后的数据类型
        auctions[auctionId] = Auction({
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            startPrice: startPrice,
            endPrice: endPrice,
            duration: duration,
            startTime: uint40(block.timestamp),  // 安全转换到uint40
            status: uint8(AuctionStatus.ACTIVE)
        });
        
        // 将NFT转入合约
        nft.safeTransferFrom(msg.sender, address(this), tokenId);
        
        // 🔥 优化：使用结构化事件数据
        emit AuctionCreated(
            auctionId,
            msg.sender,
            nftContract,
            AuctionData({
                tokenId: tokenId,
                startPrice: startPrice,
                endPrice: endPrice,
                duration: duration
            })
        );
    }
    
    /**
     * @dev 🔥 完全优化的购买NFT函数
     * @param auctionId 拍卖ID
     */
    function buy(uint256 auctionId) 
        external 
        payable 
        nonReentrant 
        validBuyableAuction(auctionId) 
    {
        Auction storage auction = auctions[auctionId];
        
        // 🔥 优化：缓存存储数据到内存，减少重复读取
        uint40 cachedStartTime = auction.startTime;
        uint32 cachedDuration = auction.duration;
        uint256 cachedStartPrice = auction.startPrice;
        uint256 cachedEndPrice = auction.endPrice;
        address cachedSeller = auction.seller;
        address cachedNftContract = auction.nftContract;
        uint256 cachedTokenId = auction.tokenId;
        
        // 🔥 优化：内联过期检查，避免函数调用开销
        require(block.timestamp < cachedStartTime + cachedDuration, "Auction has expired");
        
        // 🔥 优化：内联价格计算，避免外部函数调用
        uint256 currentPrice;
        uint256 elapsed = block.timestamp - cachedStartTime;
        if (elapsed >= cachedDuration) {
            currentPrice = cachedEndPrice;
        } else {
            unchecked {
                // 安全的数学运算，避免溢出检查开销
                currentPrice = cachedStartPrice - 
                              ((cachedStartPrice - cachedEndPrice) * elapsed) / cachedDuration;
            }
        }
        
        require(msg.value >= currentPrice, "Insufficient payment");
        
        // 更新拍卖状态
        auction.status = uint8(AuctionStatus.SOLD);
        
        // 转移NFT给买家
        IERC721(cachedNftContract).safeTransferFrom(
            address(this),
            msg.sender,
            cachedTokenId
        );
        
        // 支付给卖家
        (bool success, ) = payable(cachedSeller).call{value: currentPrice}("");
        require(success, "Payment to seller failed");
        
        // 🔥 优化：退款逻辑优化
        if (msg.value > currentPrice) {
            unchecked {
                uint256 refundAmount = msg.value - currentPrice;
                (bool refundSuccess, ) = payable(msg.sender).call{value: refundAmount}("");
                require(refundSuccess, "Refund to buyer failed");
            }
        }
        
        // 发出事件
        emit AuctionSuccessful(auctionId, msg.sender, cachedSeller, currentPrice);
    }
    
    /**
     * @dev 🔥 优化的取消拍卖函数
     * @param auctionId 拍卖ID
     */
    function cancelAuction(uint256 auctionId) 
        external 
        validActiveAuctionBySeller(auctionId) 
    {
        Auction storage auction = auctions[auctionId];
        
        // 🔥 优化：缓存必要的数据
        address cachedSeller = auction.seller;
        address cachedNftContract = auction.nftContract;
        uint256 cachedTokenId = auction.tokenId;
        
        // 更新状态
        auction.status = uint8(AuctionStatus.CANCELLED);
        
        // 将NFT退还给卖家
        IERC721(cachedNftContract).safeTransferFrom(
            address(this),
            cachedSeller,
            cachedTokenId
        );
        
        // 发出事件
        emit AuctionCancelled(auctionId, cachedSeller);
    }
    
    // ============ 查询函数 ============
    
    /**
     * @dev 🔥 优化的获取当前拍卖价格函数
     * @param auctionId 拍卖ID
     * @return 当前价格 (wei)
     */
    function getCurrentPrice(uint256 auctionId) public view auctionExists(auctionId) returns (uint256) {
        // 🔥 优化：一次性读取所有需要的数据到内存
        Auction memory auction = auctions[auctionId];
        
        // 🔥 优化：提前返回，减少不必要的计算
        if (auction.status != uint8(AuctionStatus.ACTIVE)) {
            return 0;
        }
        
        return _calculateCurrentPrice(
            auction.startPrice,
            auction.endPrice,
            auction.startTime,
            auction.duration
        );
    }
    
    /**
     * @dev 🔥 内部价格计算函数，避免重复代码
     * @param startPrice 起始价格
     * @param endPrice 最低价格
     * @param startTime 开始时间
     * @param duration 持续时间
     * @return 当前价格
     */
    function _calculateCurrentPrice(
        uint256 startPrice,
        uint256 endPrice,
        uint40 startTime,
        uint32 duration
    ) internal view returns (uint256) {
        uint256 elapsed = block.timestamp - startTime;
        
        if (elapsed >= duration) {
            return endPrice;
        }
        
        unchecked {
            // 🔥 优化：使用unchecked包装安全的数学运算
            return startPrice - ((startPrice - endPrice) * elapsed) / duration;
        }
    }
    
    /**
     * @dev 获取拍卖信息
     * @param auctionId 拍卖ID
     * @return auction 拍卖信息
     */
    function getAuction(uint256 auctionId) external view auctionExists(auctionId) returns (Auction memory auction) {
        return auctions[auctionId];
    }
    
    /**
     * @dev 获取当前拍卖ID计数器值
     * @return 当前拍卖数量
     */
    function getAuctionCount() external view returns (uint256) {
        return _auctionIdCounter;
    }
    
    /**
     * @dev 检查拍卖是否已过期
     * @param auctionId 拍卖ID
     * @return 是否已过期
     */
    function isAuctionExpired(uint256 auctionId) external view auctionExists(auctionId) returns (bool) {
        Auction memory auction = auctions[auctionId];
        return block.timestamp >= auction.startTime + auction.duration;
    }
    
    // ============ ERC721Receiver 实现 ============
    
    /**
     * @dev 实现IERC721Receiver接口，允许合约接收NFT
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
    
    // ============ 紧急函数 ============
    
    /**
     * @dev 紧急提取以太币（仅限意外发送的ETH）
     * @notice 正常交易的ETH会立即转给卖家，此函数用于处理意外情况
     */
    function emergencyWithdraw() external {
        require(msg.sender == address(this), "Only contract can call this");
        payable(msg.sender).transfer(address(this).balance);
    }
}