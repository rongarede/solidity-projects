// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/NFTMarketDutchAuction.sol";
import "../src/MyCollectible.sol";

/**
 * @title NFT荷兰拍卖合约测试 (优化前版本)
 * @dev 测试NFTMarketDutchAuction合约的所有功能
 */
contract NFTMarketDutchAuctionTest is Test {
    NFTMarketDutchAuction public auction;
    MyCollectible public nft;
    
    address public seller = address(0x1);
    address public buyer = address(0x2);
    address public buyer2 = address(0x3);
    
    uint256 public constant TOKEN_ID = 1;
    uint256 public constant START_PRICE = 10 ether;
    uint256 public constant END_PRICE = 1 ether;
    uint256 public constant DURATION = 7 days;
    
    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 startPrice,
        uint256 endPrice,
        uint256 duration
    );
    
    event AuctionSuccessful(
        uint256 indexed auctionId,
        address indexed buyer,
        address indexed seller,
        uint256 price
    );
    
    event AuctionCancelled(
        uint256 indexed auctionId,
        address indexed seller
    );
    
    function setUp() public {
        // 部署合约
        auction = new NFTMarketDutchAuction();
        nft = new MyCollectible("My Collectible", "MC", "https://api.mycollectible.io/metadata/");
        
        // 给账户分配ETH
        vm.deal(buyer, 100 ether);
        vm.deal(buyer2, 100 ether);
        vm.deal(seller, 10 ether);
        
        // 给seller铸造NFT
        uint256 tokenId = nft.mint(seller, "https://api.mycollectible.io/metadata/1.json");
        assertEq(tokenId, TOKEN_ID);
    }
    
    // ============ 创建拍卖测试 ============
    
    function testCreateAuction() public {
        vm.startPrank(seller);
        
        // 授权合约转移NFT
        nft.approve(address(auction), TOKEN_ID);
        
        // 期望发出事件
        vm.expectEmit(true, true, true, true);
        emit AuctionCreated(0, seller, address(nft), TOKEN_ID, START_PRICE, END_PRICE, DURATION);
        
        // 创建拍卖
        uint256 auctionId = auction.createAuction(
            address(nft),
            TOKEN_ID,
            START_PRICE,
            END_PRICE,
            DURATION
        );
        
        vm.stopPrank();
        
        // 验证拍卖创建成功
        assertEq(auctionId, 0);
        assertEq(nft.ownerOf(TOKEN_ID), address(auction));
        
        // 验证拍卖信息
        NFTMarketDutchAuction.Auction memory auctionInfo = auction.getAuction(auctionId);
        assertEq(auctionInfo.seller, seller);
        assertEq(auctionInfo.nftContract, address(nft));
        assertEq(auctionInfo.tokenId, TOKEN_ID);
        assertEq(auctionInfo.startPrice, START_PRICE);
        assertEq(auctionInfo.endPrice, END_PRICE);
        assertEq(auctionInfo.duration, DURATION);
        assertEq(uint256(auctionInfo.status), 0); // ACTIVE
    }
    
    function testCreateAuctionFailsWithInvalidParams() public {
        vm.startPrank(seller);
        nft.approve(address(auction), TOKEN_ID);
        
        // 测试起始价格小于等于结束价格
        vm.expectRevert("Start price must be greater than end price");
        auction.createAuction(address(nft), TOKEN_ID, 1 ether, 2 ether, DURATION);
        
        // 测试结束价格为0
        vm.expectRevert("End price must be greater than 0");
        auction.createAuction(address(nft), TOKEN_ID, START_PRICE, 0, DURATION);
        
        // 测试持续时间为0
        vm.expectRevert("Duration must be greater than 0");
        auction.createAuction(address(nft), TOKEN_ID, START_PRICE, END_PRICE, 0);
        
        vm.stopPrank();
    }
    
    function testCreateAuctionFailsWithoutNFTOwnership() public {
        vm.startPrank(buyer); // buyer不拥有NFT
        
        vm.expectRevert("You don't own this NFT");
        auction.createAuction(address(nft), TOKEN_ID, START_PRICE, END_PRICE, DURATION);
        
        vm.stopPrank();
    }
    
    function testCreateAuctionFailsWithoutApproval() public {
        vm.startPrank(seller);
        // 不授权直接创建拍卖
        vm.expectRevert("Contract not approved to transfer NFT");
        auction.createAuction(address(nft), TOKEN_ID, START_PRICE, END_PRICE, DURATION);
        
        vm.stopPrank();
    }
    
    // ============ 价格计算测试 ============
    
    function testGetCurrentPriceAtStart() public {
        uint256 auctionId = _createValidAuction();
        
        // 在拍卖开始时，价格应该等于起始价格
        uint256 currentPrice = auction.getCurrentPrice(auctionId);
        assertEq(currentPrice, START_PRICE);
    }
    
    function testGetCurrentPriceAtMiddle() public {
        uint256 auctionId = _createValidAuction();
        
        // 跳到拍卖中间时间点
        vm.warp(block.timestamp + DURATION / 2);
        
        uint256 currentPrice = auction.getCurrentPrice(auctionId);
        uint256 expectedPrice = START_PRICE - (START_PRICE - END_PRICE) / 2;
        assertEq(currentPrice, expectedPrice);
    }
    
    function testGetCurrentPriceAtEnd() public {
        uint256 auctionId = _createValidAuction();
        
        // 跳到拍卖结束时间
        vm.warp(block.timestamp + DURATION);
        
        uint256 currentPrice = auction.getCurrentPrice(auctionId);
        assertEq(currentPrice, END_PRICE);
    }
    
    function testGetCurrentPriceAfterExpiry() public {
        uint256 auctionId = _createValidAuction();
        
        // 跳到拍卖结束后
        vm.warp(block.timestamp + DURATION + 1);
        
        uint256 currentPrice = auction.getCurrentPrice(auctionId);
        assertEq(currentPrice, END_PRICE);
    }
    
    // ============ 购买测试 ============
    
    function testBuyNFT() public {
        uint256 auctionId = _createValidAuction();
        
        // 跳到拍卖中间时间点
        vm.warp(block.timestamp + DURATION / 2);
        uint256 currentPrice = auction.getCurrentPrice(auctionId);
        
        vm.startPrank(buyer);
        
        uint256 sellerBalanceBefore = seller.balance;
        uint256 buyerBalanceBefore = buyer.balance;
        
        // 期望发出事件
        vm.expectEmit(true, true, true, true);
        emit AuctionSuccessful(auctionId, buyer, seller, currentPrice);
        
        // 购买NFT
        auction.buy{value: currentPrice}(auctionId);
        
        vm.stopPrank();
        
        // 验证NFT转移
        assertEq(nft.ownerOf(TOKEN_ID), buyer);
        
        // 验证资金转移
        assertEq(seller.balance, sellerBalanceBefore + currentPrice);
        assertEq(buyer.balance, buyerBalanceBefore - currentPrice);
        
        // 验证拍卖状态
        NFTMarketDutchAuction.Auction memory auctionInfo = auction.getAuction(auctionId);
        assertEq(uint256(auctionInfo.status), 1); // SOLD
    }
    
    function testBuyNFTWithExtraPayment() public {
        uint256 auctionId = _createValidAuction();
        uint256 currentPrice = auction.getCurrentPrice(auctionId);
        uint256 extraPayment = 2 ether;
        
        vm.startPrank(buyer);
        
        uint256 buyerBalanceBefore = buyer.balance;
        
        // 支付超过当前价格的金额
        auction.buy{value: currentPrice + extraPayment}(auctionId);
        
        vm.stopPrank();
        
        // 验证多余的ETH被退还
        assertEq(buyer.balance, buyerBalanceBefore - currentPrice);
    }
    
    function testBuyFailsWithInsufficientPayment() public {
        uint256 auctionId = _createValidAuction();
        uint256 currentPrice = auction.getCurrentPrice(auctionId);
        
        vm.startPrank(buyer);
        
        vm.expectRevert("Insufficient payment");
        auction.buy{value: currentPrice - 1}(auctionId);
        
        vm.stopPrank();
    }
    
    function testBuyFailsAfterExpiry() public {
        uint256 auctionId = _createValidAuction();
        
        // 跳到拍卖结束后
        vm.warp(block.timestamp + DURATION + 1);
        
        vm.startPrank(buyer);
        
        vm.expectRevert("Auction has expired");
        auction.buy{value: END_PRICE}(auctionId);
        
        vm.stopPrank();
    }
    
    function testBuyFailsForNonexistentAuction() public {
        vm.startPrank(buyer);
        
        vm.expectRevert("Auction does not exist");
        auction.buy{value: 1 ether}(999);
        
        vm.stopPrank();
    }
    
    // ============ 取消拍卖测试 ============
    
    function testCancelAuction() public {
        uint256 auctionId = _createValidAuction();
        
        vm.startPrank(seller);
        
        // 期望发出事件
        vm.expectEmit(true, true, false, false);
        emit AuctionCancelled(auctionId, seller);
        
        auction.cancelAuction(auctionId);
        
        vm.stopPrank();
        
        // 验证NFT退还给卖家
        assertEq(nft.ownerOf(TOKEN_ID), seller);
        
        // 验证拍卖状态
        NFTMarketDutchAuction.Auction memory auctionInfo = auction.getAuction(auctionId);
        assertEq(uint256(auctionInfo.status), 2); // CANCELLED
    }
    
    function testCancelAuctionFailsForNonSeller() public {
        uint256 auctionId = _createValidAuction();
        
        vm.startPrank(buyer);
        
        vm.expectRevert("Only seller can perform this action");
        auction.cancelAuction(auctionId);
        
        vm.stopPrank();
    }
    
    function testCancelAuctionFailsAfterSale() public {
        uint256 auctionId = _createValidAuction();
        
        // 先购买NFT
        vm.prank(buyer);
        auction.buy{value: START_PRICE}(auctionId);
        
        // 尝试取消已售出的拍卖
        vm.startPrank(seller);
        
        vm.expectRevert("Auction is not active");
        auction.cancelAuction(auctionId);
        
        vm.stopPrank();
    }
    
    // ============ 查询函数测试 ============
    
    function testGetAuctionCount() public {
        assertEq(auction.getAuctionCount(), 0);
        
        _createValidAuction();
        assertEq(auction.getAuctionCount(), 1);
        
        // Create a new token for the second auction
        uint256 tokenId2 = 2;
        nft.mint(seller, "https://api.mycollectible.io/metadata/2.json");
        vm.startPrank(seller);
        nft.approve(address(auction), tokenId2);
        auction.createAuction(
            address(nft),
            tokenId2,
            START_PRICE,
            END_PRICE,
            DURATION
        );
        vm.stopPrank();
        assertEq(auction.getAuctionCount(), 2);
    }
    
    function testIsAuctionExpired() public {
        uint256 auctionId = _createValidAuction();
        
        // 拍卖刚开始时未过期
        assertFalse(auction.isAuctionExpired(auctionId));
        
        // 跳到拍卖结束时间
        vm.warp(block.timestamp + DURATION);
        assertTrue(auction.isAuctionExpired(auctionId));
    }
    
    function testGetCurrentPriceForInactiveAuction() public {
        uint256 auctionId = _createValidAuction();
        
        // 取消拍卖
        vm.prank(seller);
        auction.cancelAuction(auctionId);
        
        // 非活跃拍卖的价格应该为0
        assertEq(auction.getCurrentPrice(auctionId), 0);
    }
    
    // ============ 多个拍卖测试 ============
    
    function testMultipleAuctions() public {
        // 创建第二个NFT
        uint256 tokenId2;
        tokenId2 = nft.mint(seller, "https://api.mycollectible.io/metadata/2.json");
        
        vm.startPrank(seller);
        
        // 创建两个拍卖
        nft.approve(address(auction), TOKEN_ID);
        uint256 auctionId1 = auction.createAuction(
            address(nft), TOKEN_ID, START_PRICE, END_PRICE, DURATION
        );
        
        nft.approve(address(auction), tokenId2);
        uint256 auctionId2 = auction.createAuction(
            address(nft), tokenId2, START_PRICE * 2, END_PRICE * 2, DURATION * 2
        );
        
        vm.stopPrank();
        
        // 验证两个拍卖独立工作
        assertEq(auctionId1, 0);
        assertEq(auctionId2, 1);
        
        // 买家1购买第一个拍卖
        vm.prank(buyer);
        auction.buy{value: START_PRICE}(auctionId1);
        
        // 买家2购买第二个拍卖
        vm.prank(buyer2);
        auction.buy{value: START_PRICE * 2}(auctionId2);
        
        // 验证NFT分别转移给对应买家
        assertEq(nft.ownerOf(TOKEN_ID), buyer);
        assertEq(nft.ownerOf(tokenId2), buyer2);
    }
    
    // ============ NFT功能测试 ============
    
    function testNFTBasicFunctions() public {
        // 测试NFT基本信息
        assertEq(nft.name(), "My Collectible");
        assertEq(nft.symbol(), "MC");
        assertEq(nft.totalSupply(), 1);
        assertEq(nft.balanceOf(seller), 1);
        assertEq(nft.ownerOf(TOKEN_ID), seller);
        
        // 测试tokenURI
        string memory expectedURI = "https://api.mycollectible.io/metadata/1.json";
        assertEq(nft.tokenURI(TOKEN_ID), expectedURI);
    }
    
    function testNFTBatchMint() public {
        nft.batchMint(seller, 3, "https://api.mycollectible.io/metadata/batch_");
        
        // 验证批量铸造
        assertEq(nft.totalSupply(), 4); // 原来1个 + 新铸造3个
        assertEq(nft.balanceOf(seller), 4);
        
        // 验证新NFT的URI
        assertEq(nft.tokenURI(2), "https://api.mycollectible.io/metadata/batch_2");
        assertEq(nft.tokenURI(3), "https://api.mycollectible.io/metadata/batch_3");
        assertEq(nft.tokenURI(4), "https://api.mycollectible.io/metadata/batch_4");
    }
    
    // ============ 重入攻击测试 ============
    
    function testReentrancyProtection() public {
        uint256 auctionId = _createValidAuction();
        
        ReentrancyAttacker attacker = new ReentrancyAttacker(auction);
        vm.deal(address(attacker), 20 ether);
        
        vm.expectRevert("ReentrancyGuard: reentrant call");
        attacker.attack{value: START_PRICE + 1 ether}(auctionId);
    }
    
    // ============ 辅助函数 ============
    
    function _createValidAuction() internal returns (uint256) {
        vm.startPrank(seller);
        nft.approve(address(auction), TOKEN_ID);
        uint256 auctionId = auction.createAuction(
            address(nft),
            TOKEN_ID,
            START_PRICE,
            END_PRICE,
            DURATION
        );
        vm.stopPrank();
        return auctionId;
    }
}

// 用于测试重入攻击的恶意合约
contract ReentrancyAttacker is IERC721Receiver {
    NFTMarketDutchAuction private auction;
    uint256 private auctionIdToAttack;
    
    constructor(NFTMarketDutchAuction _auction) {
        auction = _auction;
    }
    
    function attack(uint256 auctionId) external payable {
        auctionIdToAttack = auctionId;
        auction.buy{value: msg.value}(auctionId);
    }
    
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        // 尝试重入攻击
        // 在收到NFT后，立即尝试用少量ETH再次购买，测试重入保护
        if (address(auction).balance >= 1 ether) {
            auction.buy{value: 1 ether}(auctionIdToAttack);
        }
        return this.onERC721Received.selector;
    }

    // 在接收ETH时尝试重入
    receive() external payable {
        // receive函数留空，避免在退款时因gas不足而失败
    }
}
