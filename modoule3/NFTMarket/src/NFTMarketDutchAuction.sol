pragma solidity ^0.8.13;

import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Receiver.sol";
import "./security/ReentrancyGuard.sol";

/**
 * @title NFTMarketDutchAuction
 * @dev NFT荷兰拍卖市场合约
 * @notice 实现NFT的荷兰拍卖模式，价格随时间线性递减
 */
contract NFTMarketDutchAuction is ReentrancyGuard, IERC721Receiver {
    
    // ============ 状态变量 ============
    
    /// @dev 拍卖计数器，用于生成唯一的拍卖ID
    uint256 private _auctionIdCounter;
    
    /// @dev 拍卖状态枚举
    enum AuctionStatus {
        ACTIVE,     // 进行中
        SOLD,       // 已售出
        CANCELLED   // 已取消
    }
    
    /// @dev 拍卖信息结构体
    struct Auction {
        address seller;           // 卖家地址
        address nftContract;      // NFT合约地址
        uint256 tokenId;          // NFT TokenId
        uint256 startPrice;       // 起始价格 (wei)
        uint256 endPrice;         // 最低价格 (wei)
        uint256 duration;         // 拍卖时长 (秒)
        uint256 startTime;        // 开始时间戳
        AuctionStatus status;     // 拍卖状态
    }
    
    /// @dev 拍卖ID映射到拍卖信息
    mapping(uint256 => Auction) public auctions;
    
    // ============ 事件定义 ============
    
    /**
     * @dev 拍卖创建事件
     * @param auctionId 拍卖ID
     * @param seller 卖家地址
     * @param nftContract NFT合约地址
     * @param tokenId NFT TokenId
     * @param startPrice 起始价格
     * @param endPrice 最低价格
     * @param duration 拍卖时长
     */
    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 startPrice,
        uint256 endPrice,
        uint256 duration
    );
    
    /**
     * @dev NFT购买成功事件
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
    
    // ============ 修饰器 ============
    
    /**
     * @dev 检查拍卖是否存在且处于活跃状态
     * @param auctionId 拍卖ID
     */
    modifier auctionExists(uint256 auctionId) {
        require(_auctionIdCounter > auctionId, "Auction does not exist");
        require(auctions[auctionId].status == AuctionStatus.ACTIVE, "Auction is not active");
        _;
    }
    
    /**
     * @dev 检查是否为拍卖的卖家
     * @param auctionId 拍卖ID
     */
    modifier onlySeller(uint256 auctionId) {
        require(auctions[auctionId].seller == msg.sender, "Only seller can perform this action");
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
        uint256 duration
    ) external returns (uint256 auctionId) {
        // 参数验证
        require(nftContract != address(0), "Invalid NFT contract address");
        require(startPrice > endPrice, "Start price must be greater than end price");
        require(endPrice > 0, "End price must be greater than 0");
        require(duration > 0, "Duration must be greater than 0");
        
        // 验证NFT所有权
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender, "You don't own this NFT");
        
        // 验证授权
        require(
            nft.getApproved(tokenId) == address(this) || 
            nft.isApprovedForAll(msg.sender, address(this)),
            "Contract not approved to transfer NFT"
        );
        
        // 生成拍卖ID
        auctionId = _auctionIdCounter;
        _auctionIdCounter++;
        
        // 创建拍卖信息
        auctions[auctionId] = Auction({
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            startPrice: startPrice,
            endPrice: endPrice,
            duration: duration,
            startTime: block.timestamp,
            status: AuctionStatus.ACTIVE
        });
        
        // 将NFT转入合约
        nft.safeTransferFrom(msg.sender, address(this), tokenId);
        
        // 发出事件
        emit AuctionCreated(
            auctionId,
            msg.sender,
            nftContract,
            tokenId,
            startPrice,
            endPrice,
            duration
        );
    }
    
    /**
     * @dev 购买NFT
     * @param auctionId 拍卖ID
     */
    function buy(uint256 auctionId) 
        external 
        payable 
        nonReentrant 
        auctionExists(auctionId) 
    {
        Auction storage auction = auctions[auctionId];
        
        // 检查拍卖是否已结束
        require(!_isAuctionExpired(auction), "Auction has expired");
        
        // 获取当前价格
        uint256 currentPrice = getCurrentPrice(auctionId);
        require(msg.value >= currentPrice, "Insufficient payment");
        
        // 更新拍卖状态
        auction.status = AuctionStatus.SOLD;
        
        // 转移NFT给买家
        IERC721(auction.nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            auction.tokenId
        );
        
        // 支付给卖家
        (bool success, ) = payable(auction.seller).call{value: currentPrice}("");
        require(success, "Payment to seller failed");
        
        // 退还多余的ETH给买家
        if (msg.value > currentPrice) {
            (bool refundSuccess, ) = payable(msg.sender).call{value: msg.value - currentPrice}("");
            require(refundSuccess, "Refund to buyer failed");
        }
        
        // 发出事件
        emit AuctionSuccessful(auctionId, msg.sender, auction.seller, currentPrice);
    }
    
    /**
     * @dev 取消拍卖
     * @param auctionId 拍卖ID
     */
    function cancelAuction(uint256 auctionId) 
        external 
        auctionExists(auctionId) 
        onlySeller(auctionId) 
    {
        Auction storage auction = auctions[auctionId];
        
        // 更新状态
        auction.status = AuctionStatus.CANCELLED;
        
        // 将NFT退还给卖家
        IERC721(auction.nftContract).safeTransferFrom(
            address(this),
            auction.seller,
            auction.tokenId
        );
        
        // 发出事件
        emit AuctionCancelled(auctionId, auction.seller);
    }
    
    // ============ 查询函数 ============
    
    /**
     * @dev 获取当前拍卖价格
     * @param auctionId 拍卖ID
     * @return 当前价格 (wei)
     */
    function getCurrentPrice(uint256 auctionId) public view returns (uint256) {
        require(_auctionIdCounter > auctionId, "Auction does not exist");
        
        Auction memory auction = auctions[auctionId];
        
        // 如果拍卖未激活，返回0
        if (auction.status != AuctionStatus.ACTIVE) {
            return 0;
        }
        
        // 如果拍卖已过期，返回最低价
        if (_isAuctionExpired(auction)) {
            return auction.endPrice;
        }
        
        // 计算已经过的时间
        uint256 elapsed = block.timestamp - auction.startTime;
        
        // 线性价格递减计算
        // 当前价格 = 起始价格 - (起始价格 - 最低价格) * 已过时间 / 总时长
        uint256 priceReduction = ((auction.startPrice - auction.endPrice) * elapsed) / auction.duration;
        
        return auction.startPrice - priceReduction;
    }
    
    /**
     * @dev 获取拍卖信息
     * @param auctionId 拍卖ID
     * @return auction 拍卖信息
     */
    function getAuction(uint256 auctionId) external view returns (Auction memory auction) {
        require(_auctionIdCounter > auctionId, "Auction does not exist");
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
    function isAuctionExpired(uint256 auctionId) external view returns (bool) {
        require(_auctionIdCounter > auctionId, "Auction does not exist");
        return _isAuctionExpired(auctions[auctionId]);
    }
    
    // ============ 内部函数 ============
    
    /**
     * @dev 内部函数：检查拍卖是否已过期
     * @param auction 拍卖信息
     * @return 是否已过期
     */
    function _isAuctionExpired(Auction memory auction) internal view returns (bool) {
        return block.timestamp >= auction.startTime + auction.duration;
    }
    
    // ============ ERC721Receiver 实现 ============
    
    /**
     * @dev 实现IERC721Receiver接口，允许合约接收NFT
     * @param operator 操作者地址
     * @param from 来源地址
     * @param tokenId NFT TokenId
     * @param data 附加数据
     * @return 返回函数选择器以确认接收
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        // 避免未使用变量警告
        operator;
        from;
        tokenId;
        data;
        
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
