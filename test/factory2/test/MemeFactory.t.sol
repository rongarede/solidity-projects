// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/MemeFactory.sol";
import "../src/MemeToken.sol";

contract MemeFactoryTest is Test {
    MemeFactory factory;
    address owner = address(0x1);
    address creator = address(0x2);
    address buyer = address(0x3);
    address buyer2 = address(0x4);

    uint256 constant TOTAL_SUPPLY = 1000000 * 10**18;
    uint256 constant PER_MINT = 1000 * 10**18;
    uint256 constant PRICE = 0.001 ether;

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

    function setUp() public {
        vm.prank(owner);
        factory = new MemeFactory();
    }

    function testDeployMeme() public {
        vm.prank(creator);
        
        address memeToken = factory.deployMeme("PEPE", TOTAL_SUPPLY, PER_MINT, PRICE);
        
        assertTrue(memeToken != address(0));
        
        MemeToken token = MemeToken(memeToken);
        assertEq(token.symbol(), "PEPE");
        assertEq(token.name(), "MemeToken");
        assertEq(token.totalSupplyLimit(), TOTAL_SUPPLY);
        assertEq(token.owner(), creator);
        assertTrue(token.isInitialized());
        
        MemeFactory.MemeInfo memory info = factory.getMemeInfo(memeToken);
        assertEq(info.creator, creator);
        assertEq(info.totalSupply, TOTAL_SUPPLY);
        assertEq(info.perMint, PER_MINT);
        assertEq(info.price, PRICE);
        assertEq(info.totalMinted, 0);
        
        assertEq(factory.getTotalMemeTokens(), 1);
        address[] memory allTokens = factory.getAllMemeTokens();
        assertEq(allTokens[0], memeToken);
    }

    function testMintMeme() public {
        vm.prank(creator);
        address memeToken = factory.deployMeme("PEPE", TOTAL_SUPPLY, PER_MINT, PRICE);
        
        uint256 totalCost = PER_MINT * PRICE;
        vm.deal(buyer, totalCost);
        
        uint256 ownerBalanceBefore = owner.balance;
        uint256 creatorBalanceBefore = creator.balance;
        
        vm.prank(buyer);
        vm.expectEmit(true, true, false, true);
        emit MemeMinted(memeToken, buyer, PER_MINT, totalCost, totalCost / 100, (totalCost * 99) / 100);
        
        factory.mintMeme{value: totalCost}(memeToken);
        
        MemeToken token = MemeToken(memeToken);
        assertEq(token.balanceOf(buyer), PER_MINT);
        assertEq(token.totalSupply(), PER_MINT);
        
        uint256 platformFee = totalCost / 100;
        uint256 creatorFee = (totalCost * 99) / 100;
        
        assertEq(owner.balance, ownerBalanceBefore + platformFee);
        assertEq(creator.balance, creatorBalanceBefore + creatorFee);
        
        MemeFactory.MemeInfo memory info = factory.getMemeInfo(memeToken);
        assertEq(info.totalMinted, PER_MINT);
        
        assertEq(factory.getRemainingSupply(memeToken), TOTAL_SUPPLY - PER_MINT);
    }

    function testMintMemeWithExcessPayment() public {
        vm.prank(creator);
        address memeToken = factory.deployMeme("PEPE", TOTAL_SUPPLY, PER_MINT, PRICE);
        
        uint256 totalCost = PER_MINT * PRICE;
        uint256 excessPayment = 0.001 ether;
        uint256 totalPayment = totalCost + excessPayment;
        
        vm.deal(buyer, totalPayment);
        
        uint256 buyerBalanceBefore = buyer.balance;
        
        vm.prank(buyer);
        factory.mintMeme{value: totalPayment}(memeToken);
        
        assertEq(buyer.balance, buyerBalanceBefore - totalCost);
        
        MemeToken token = MemeToken(memeToken);
        assertEq(token.balanceOf(buyer), PER_MINT);
    }

    function testMultipleMints() public {
        vm.prank(creator);
        address memeToken = factory.deployMeme("PEPE", TOTAL_SUPPLY, PER_MINT, PRICE);
        
        uint256 totalCost = PER_MINT * PRICE;
        vm.deal(buyer, totalCost);
        vm.deal(buyer2, totalCost);
        
        vm.prank(buyer);
        factory.mintMeme{value: totalCost}(memeToken);
        
        vm.prank(buyer2);
        factory.mintMeme{value: totalCost}(memeToken);
        
        MemeToken token = MemeToken(memeToken);
        assertEq(token.balanceOf(buyer), PER_MINT);
        assertEq(token.balanceOf(buyer2), PER_MINT);
        assertEq(token.totalSupply(), PER_MINT * 2);
        
        MemeFactory.MemeInfo memory info = factory.getMemeInfo(memeToken);
        assertEq(info.totalMinted, PER_MINT * 2);
    }

    function testRevertMintInsufficientPayment() public {
        vm.prank(creator);
        address memeToken = factory.deployMeme("PEPE", TOTAL_SUPPLY, PER_MINT, PRICE);
        
        uint256 insufficientPayment = (PER_MINT * PRICE) - 1;
        vm.deal(buyer, insufficientPayment);
        
        vm.prank(buyer);
        vm.expectRevert(MemeFactory.InsufficientPayment.selector);
        factory.mintMeme{value: insufficientPayment}(memeToken);
    }

    function testRevertMintExceedsRemainingSupply() public {
        uint256 smallSupply = PER_MINT;
        
        vm.prank(creator);
        address memeToken = factory.deployMeme("PEPE", smallSupply, PER_MINT, PRICE);
        
        uint256 totalCost = PER_MINT * PRICE;
        vm.deal(buyer, totalCost);
        vm.deal(buyer2, totalCost);
        
        vm.prank(buyer);
        factory.mintMeme{value: totalCost}(memeToken);
        
        vm.prank(buyer2);
        vm.expectRevert(MemeFactory.ExceedsRemainingSupply.selector);
        factory.mintMeme{value: totalCost}(memeToken);
    }

    function testRevertMintInvalidMemeToken() public {
        address invalidToken = address(0x999);
        uint256 totalCost = PER_MINT * PRICE;
        vm.deal(buyer, totalCost);
        
        vm.prank(buyer);
        vm.expectRevert(MemeFactory.InvalidMemeToken.selector);
        factory.mintMeme{value: totalCost}(invalidToken);
    }

    function testRevertDeployMemeZeroTotalSupply() public {
        vm.prank(creator);
        vm.expectRevert(MemeFactory.ZeroAmount.selector);
        factory.deployMeme("PEPE", 0, PER_MINT, PRICE);
    }

    function testRevertDeployMemeZeroPerMint() public {
        vm.prank(creator);
        vm.expectRevert(MemeFactory.ZeroAmount.selector);
        factory.deployMeme("PEPE", TOTAL_SUPPLY, 0, PRICE);
    }

    function testRevertDeployMemePerMintExceedsTotalSupply() public {
        vm.prank(creator);
        vm.expectRevert(MemeFactory.ExceedsRemainingSupply.selector);
        factory.deployMeme("PEPE", PER_MINT, TOTAL_SUPPLY, PRICE);
    }

    function testFreeMemeToken() public {
        vm.prank(creator);
        address memeToken = factory.deployMeme("FREE", TOTAL_SUPPLY, PER_MINT, 0);
        
        vm.prank(buyer);
        factory.mintMeme{value: 0}(memeToken);
        
        MemeToken token = MemeToken(memeToken);
        assertEq(token.balanceOf(buyer), PER_MINT);
        assertEq(owner.balance, 0);
        assertEq(creator.balance, 0);
    }

    function testGetRemainingSupply() public {
        vm.prank(creator);
        address memeToken = factory.deployMeme("PEPE", TOTAL_SUPPLY, PER_MINT, PRICE);
        
        assertEq(factory.getRemainingSupply(memeToken), TOTAL_SUPPLY);
        
        uint256 totalCost = PER_MINT * PRICE;
        vm.deal(buyer, totalCost);
        
        vm.prank(buyer);
        factory.mintMeme{value: totalCost}(memeToken);
        
        assertEq(factory.getRemainingSupply(memeToken), TOTAL_SUPPLY - PER_MINT);
    }

    function testMemeTokenCannotBeInitializedTwice() public {
        vm.prank(creator);
        address memeToken = factory.deployMeme("PEPE", TOTAL_SUPPLY, PER_MINT, PRICE);
        
        MemeToken token = MemeToken(memeToken);
        
        vm.expectRevert(MemeToken.AlreadyInitialized.selector);
        token.initialize("DOGE", TOTAL_SUPPLY, creator);
    }

    function testOnlyFactoryCanMintTokens() public {
        vm.prank(creator);
        address memeToken = factory.deployMeme("PEPE", TOTAL_SUPPLY, PER_MINT, PRICE);
        
        MemeToken token = MemeToken(memeToken);
        
        vm.prank(creator);
        vm.expectRevert(MemeToken.OnlyFactory.selector);
        token.mint(creator, PER_MINT);
    }
}