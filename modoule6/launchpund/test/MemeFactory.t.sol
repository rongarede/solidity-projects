// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Test.sol";
import "../src/MemeToken.sol";
import "../src/MemeFactory.sol";
import "../src/interfaces/IUniswapV2Router02.sol";
import "../src/interfaces/IUniswapV2Factory.sol";
import "../src/interfaces/IUniswapV2Pair.sol";

contract MemeFactoryTest is Test {
    MemeToken public template;
    MemeFactory public factory;
    
    // Test addresses
    address public constant QUICKSWAP_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address public constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    
    address public owner = address(this);
    address public platformWallet = makeAddr("platformWallet");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public creator = makeAddr("creator");
    
    // Test constants
    uint256 public constant INITIAL_ETH = 100 ether;
    uint256 public constant PLATFORM_FEE_RATE = 500; // 5%
    uint256 public constant LIQUIDITY_THRESHOLD = 0.1 ether;
    
    event MemeTokenDeployed(
        address indexed tokenAddress,
        address indexed creator,
        string name,
        string symbol,
        uint256 totalSupply,
        uint256 pricePerToken
    );
    
    event MemeTokenMinted(
        address indexed tokenAddress,
        address indexed buyer,
        uint256 amount,
        uint256 cost,
        uint256 platformFee
    );
    
    event LiquidityAdded(
        address indexed tokenAddress,
        uint256 tokenAmount,
        uint256 ethAmount,
        address pair
    );

    function setUp() public {
        // Deploy template
        template = new MemeToken();
        
        // Deploy factory
        factory = new MemeFactory(
            address(template),
            QUICKSWAP_ROUTER,
            WMATIC,
            platformWallet
        );
        
        // Fund test accounts
        vm.deal(user1, INITIAL_ETH);
        vm.deal(user2, INITIAL_ETH);
        vm.deal(creator, INITIAL_ETH);
        vm.deal(owner, INITIAL_ETH);
        
        // Label addresses for better debugging
        vm.label(address(template), "MemeTokenTemplate");
        vm.label(address(factory), "MemeFactory");
        vm.label(user1, "User1");
        vm.label(user2, "User2");
        vm.label(creator, "Creator");
        vm.label(platformWallet, "PlatformWallet");
    }

    function test_SetUp() public view {
        // Verify deployment
        assertEq(factory.TEMPLATE(), address(template));
        assertEq(address(factory.ROUTER()), QUICKSWAP_ROUTER);
        assertEq(factory.WETH(), WMATIC);
        assertEq(factory.platformWallet(), platformWallet);
        assertEq(factory.PLATFORM_FEE_RATE(), PLATFORM_FEE_RATE);
        assertEq(factory.LIQUIDITY_THRESHOLD(), LIQUIDITY_THRESHOLD);
        
        // Verify initial state
        assertEq(factory.getTokensCount(), 0);
        assertEq(factory.getAllTokens().length, 0);
    }

    // ============= DEPLOY MEME TESTS =============

    function test_DeployMeme_Success() public {
        vm.startPrank(creator);
        
        // Note: We can't predict the exact address, so we'll check the event after deployment
        
        address memeToken = factory.deployMeme(
            "Test Meme",
            "TMEME", 
            1000000 * 1e18,
            0.001 ether
        );
        
        vm.stopPrank();
        
        // Verify token was deployed
        assertTrue(memeToken != address(0));
        
        // Verify token data
        MemeFactory.TokenData memory tokenData = factory.getTokenData(memeToken);
        assertEq(tokenData.tokenAddress, memeToken);
        assertEq(tokenData.creator, creator);
        assertEq(tokenData.totalSupply, 1000000 * 1e18);
        assertEq(tokenData.pricePerToken, 0.001 ether);
        assertEq(tokenData.soldAmount, 0);
        assertEq(tokenData.raisedETH, 0);
        assertFalse(tokenData.liquidityAdded);
        assertEq(tokenData.name, "Test Meme");
        assertEq(tokenData.symbol, "TMEME");
        
        // Verify mapping updates
        assertEq(factory.symbolToToken("TMEME"), memeToken);
        assertEq(factory.getTokensCount(), 1);
        
        address[] memory allTokens = factory.getAllTokens();
        assertEq(allTokens.length, 1);
        assertEq(allTokens[0], memeToken);
        
        // Verify token contract properties
        MemeToken token = MemeToken(memeToken);
        assertEq(token.name(), "Test Meme");
        assertEq(token.symbol(), "TMEME");
        assertEq(token.totalSupply(), 0); // No tokens minted yet
        assertEq(token.factory(), address(factory));
        
        IMemeToken.TokenConfig memory config = token.getTokenInfo();
        assertEq(config.name, "Test Meme");
        assertEq(config.symbol, "TMEME");
        assertEq(config.totalSupply, 1000000 * 1e18);
        assertEq(config.pricePerToken, 0.001 ether);
        assertEq(config.creator, creator);
    }
    
    function test_DeployMeme_InvalidName() public {
        vm.startPrank(creator);
        
        // Empty name
        vm.expectRevert("Invalid name length");
        factory.deployMeme("", "TMEME", 1000000 * 1e18, 0.001 ether);
        
        // Name too long (over 50 chars)
        vm.expectRevert("Invalid name length");
        factory.deployMeme(
            "This is a very long name that exceeds the maximum allowed length of fifty characters",
            "TMEME",
            1000000 * 1e18,
            0.001 ether
        );
        
        vm.stopPrank();
    }
    
    function test_DeployMeme_InvalidSymbol() public {
        vm.startPrank(creator);
        
        // Empty symbol
        vm.expectRevert("Invalid symbol length");
        factory.deployMeme("Test Meme", "", 1000000 * 1e18, 0.001 ether);
        
        // Symbol too long (over 10 chars)
        vm.expectRevert("Invalid symbol length");
        factory.deployMeme("Test Meme", "VERYLONGSYMBOL", 1000000 * 1e18, 0.001 ether);
        
        vm.stopPrank();
    }
    
    function test_DeployMeme_InvalidSupply() public {
        vm.startPrank(creator);
        
        // Zero supply
        vm.expectRevert("Invalid total supply");
        factory.deployMeme("Test Meme", "TMEME", 0, 0.001 ether);
        
        // Supply too large (over 1T tokens)
        vm.expectRevert("Invalid total supply");
        factory.deployMeme("Test Meme", "TMEME", 1e12 * 1e18 + 1, 0.001 ether);
        
        vm.stopPrank();
    }
    
    function test_DeployMeme_InvalidPrice() public {
        vm.startPrank(creator);
        
        // Zero price
        vm.expectRevert("Invalid price per token");
        factory.deployMeme("Test Meme", "TMEME", 1000000 * 1e18, 0);
        
        vm.stopPrank();
    }
    
    function test_DeployMeme_DuplicateSymbol() public {
        vm.startPrank(creator);
        
        // Deploy first token
        factory.deployMeme("Test Meme", "TMEME", 1000000 * 1e18, 0.001 ether);
        
        // Try to deploy with same symbol
        vm.expectRevert("Symbol already exists");
        factory.deployMeme("Another Meme", "TMEME", 2000000 * 1e18, 0.002 ether);
        
        vm.stopPrank();
    }
    
    function test_DeployMeme_MultipleTokens() public {
        // Deploy multiple tokens with different creators
        vm.prank(creator);
        address token1 = factory.deployMeme("Meme 1", "MEME1", 1000000 * 1e18, 0.001 ether);
        
        vm.prank(user1);
        address token2 = factory.deployMeme("Meme 2", "MEME2", 2000000 * 1e18, 0.002 ether);
        
        vm.prank(user2);
        address token3 = factory.deployMeme("Meme 3", "MEME3", 3000000 * 1e18, 0.003 ether);
        
        // Verify count and array
        assertEq(factory.getTokensCount(), 3);
        
        address[] memory allTokens = factory.getAllTokens();
        assertEq(allTokens.length, 3);
        assertEq(allTokens[0], token1);
        assertEq(allTokens[1], token2);
        assertEq(allTokens[2], token3);
        
        // Verify mappings
        assertEq(factory.symbolToToken("MEME1"), token1);
        assertEq(factory.symbolToToken("MEME2"), token2);
        assertEq(factory.symbolToToken("MEME3"), token3);
        
        // Verify each token data
        MemeFactory.TokenData memory data1 = factory.getTokenData(token1);
        assertEq(data1.creator, creator);
        assertEq(data1.symbol, "MEME1");
        
        MemeFactory.TokenData memory data2 = factory.getTokenData(token2);
        assertEq(data2.creator, user1);
        assertEq(data2.symbol, "MEME2");
        
        MemeFactory.TokenData memory data3 = factory.getTokenData(token3);
        assertEq(data3.creator, user2);
        assertEq(data3.symbol, "MEME3");
    }

    // ============= MINT MEME TESTS =============

    function test_MintMeme_Success() public {
        // Deploy a token first
        vm.prank(creator);
        address memeToken = factory.deployMeme("Test Meme", "TMEME", 1000000 * 1e18, 0.001 ether);
        
        uint256 mintAmount = 100 * 1e18; // 100 tokens
        uint256 cost = mintAmount * 0.001 ether / 1e18; // 0.1 ETH
        uint256 expectedPlatformFee = cost * PLATFORM_FEE_RATE / 10000; // 5% fee
        uint256 expectedRaised = cost - expectedPlatformFee; // 95% raised
        
        uint256 platformBalanceBefore = platformWallet.balance;
        uint256 userBalanceBefore = user1.balance;
        
        vm.expectEmit(true, true, false, true);
        emit MemeTokenMinted(memeToken, user1, mintAmount, cost, expectedPlatformFee);
        
        vm.prank(user1);
        factory.mintMeme{value: cost}(memeToken, mintAmount);
        
        // Verify user received tokens
        assertEq(IMemeToken(memeToken).balanceOf(user1), mintAmount);
        
        // Verify user ETH balance decreased by exact cost
        assertEq(user1.balance, userBalanceBefore - cost);
        
        // Verify platform wallet received fee
        assertEq(platformWallet.balance, platformBalanceBefore + expectedPlatformFee);
        
        // Verify token data updated
        MemeFactory.TokenData memory tokenData = factory.getTokenData(memeToken);
        assertEq(tokenData.soldAmount, mintAmount);
        assertEq(tokenData.raisedETH, expectedRaised);
        assertFalse(tokenData.liquidityAdded); // Should not trigger liquidity yet
        
        // Verify token total supply increased
        assertEq(IMemeToken(memeToken).totalSupply(), mintAmount);
    }
    
    function test_MintMeme_ExactPayment() public {
        vm.prank(creator);
        address memeToken = factory.deployMeme("Test Meme", "TMEME", 1000000 * 1e18, 0.001 ether);
        
        uint256 mintAmount = 50 * 1e18;
        uint256 exactCost = mintAmount * 0.001 ether / 1e18;
        
        vm.prank(user1);
        factory.mintMeme{value: exactCost}(memeToken, mintAmount);
        
        // Should succeed with exact payment
        assertEq(IMemeToken(memeToken).balanceOf(user1), mintAmount);
    }
    
    function test_MintMeme_Overpayment() public {
        vm.prank(creator);
        address memeToken = factory.deployMeme("Test Meme", "TMEME", 1000000 * 1e18, 0.001 ether);
        
        uint256 mintAmount = 50 * 1e18;
        uint256 cost = mintAmount * 0.001 ether / 1e18;
        uint256 overpayment = 0.01 ether; // Extra payment
        uint256 totalSent = cost + overpayment;
        
        uint256 userBalanceBefore = user1.balance;
        
        vm.prank(user1);
        factory.mintMeme{value: totalSent}(memeToken, mintAmount);
        
        // Verify user received correct tokens
        assertEq(IMemeToken(memeToken).balanceOf(user1), mintAmount);
        
        // Verify user only charged exact cost (overpayment refunded)
        assertEq(user1.balance, userBalanceBefore - cost);
    }
    
    function test_MintMeme_MultipleUsers() public {
        vm.prank(creator);
        address memeToken = factory.deployMeme("Test Meme", "TMEME", 1000000 * 1e18, 0.001 ether);
        
        uint256 mintAmount1 = 30 * 1e18;
        uint256 mintAmount2 = 70 * 1e18;
        uint256 cost1 = mintAmount1 * 0.001 ether / 1e18;
        uint256 cost2 = mintAmount2 * 0.001 ether / 1e18;
        
        // User1 mints first
        vm.prank(user1);
        factory.mintMeme{value: cost1}(memeToken, mintAmount1);
        
        // User2 mints second
        vm.prank(user2);
        factory.mintMeme{value: cost2}(memeToken, mintAmount2);
        
        // Verify balances
        assertEq(IMemeToken(memeToken).balanceOf(user1), mintAmount1);
        assertEq(IMemeToken(memeToken).balanceOf(user2), mintAmount2);
        assertEq(IMemeToken(memeToken).totalSupply(), mintAmount1 + mintAmount2);
        
        // Verify token data
        MemeFactory.TokenData memory tokenData = factory.getTokenData(memeToken);
        assertEq(tokenData.soldAmount, mintAmount1 + mintAmount2);
        
        uint256 expectedTotalRaised = (cost1 + cost2) * 9500 / 10000; // 95% of total cost
        assertEq(tokenData.raisedETH, expectedTotalRaised);
    }
    
    function test_MintMeme_LiquidityTrigger() public {
        vm.prank(creator);
        address memeToken = factory.deployMeme("Test Meme", "TMEME", 1000000 * 1e18, 0.001 ether);
        
        // Calculate amount needed to reach liquidity threshold
        // Need 0.1 ETH raised (95% of cost) = 0.1 / 0.95 ≈ 0.10526 ETH cost
        uint256 costNeeded = (LIQUIDITY_THRESHOLD * 10000) / 9500; // Inverse of 95%
        uint256 mintAmount = costNeeded * 1e18 / 0.001 ether; // Amount of tokens for this cost
        
        // Note: We'll verify liquidity was added through state changes rather than events
        
        vm.prank(user1);
        factory.mintMeme{value: costNeeded}(memeToken, mintAmount);
        
        // Verify liquidity was added
        MemeFactory.TokenData memory tokenData = factory.getTokenData(memeToken);
        assertTrue(tokenData.liquidityAdded);
        
        // Verify user received tokens
        assertEq(IMemeToken(memeToken).balanceOf(user1), mintAmount);
    }
    
    function test_MintMeme_InvalidTokenAddress() public {
        vm.prank(user1);
        vm.expectRevert("Invalid token address");
        factory.mintMeme{value: 0.1 ether}(address(0), 100 * 1e18);
    }
    
    function test_MintMeme_TokenNotFound() public {
        address fakeToken = makeAddr("fakeToken");
        
        vm.prank(user1);
        vm.expectRevert("Token not found");
        factory.mintMeme{value: 0.1 ether}(fakeToken, 100 * 1e18);
    }
    
    function test_MintMeme_ZeroAmount() public {
        vm.prank(creator);
        address memeToken = factory.deployMeme("Test Meme", "TMEME", 1000000 * 1e18, 0.001 ether);
        
        vm.prank(user1);
        vm.expectRevert("Amount must be greater than zero");
        factory.mintMeme{value: 0.1 ether}(memeToken, 0);
    }
    
    function test_MintMeme_InsufficientPayment() public {
        vm.prank(creator);
        address memeToken = factory.deployMeme("Test Meme", "TMEME", 1000000 * 1e18, 0.001 ether);
        
        uint256 mintAmount = 100 * 1e18;
        uint256 requiredCost = mintAmount * 0.001 ether / 1e18;
        uint256 insufficientPayment = requiredCost - 1; // 1 wei less
        
        vm.prank(user1);
        vm.expectRevert("Insufficient payment");
        factory.mintMeme{value: insufficientPayment}(memeToken, mintAmount);
    }
    
    function test_MintMeme_ExceedTotalSupply() public {
        uint256 smallSupply = 1000 * 1e18;
        vm.prank(creator);
        address memeToken = factory.deployMeme("Test Meme", "TMEME", smallSupply, 0.001 ether);
        
        uint256 excessiveAmount = smallSupply + 1;
        uint256 cost = excessiveAmount * 0.001 ether / 1e18;
        
        vm.prank(user1);
        vm.expectRevert("Cannot exceed total supply");
        factory.mintMeme{value: cost}(memeToken, excessiveAmount);
    }
    
    function test_MintMeme_AfterLiquidityAdded() public {
        vm.prank(creator);
        address memeToken = factory.deployMeme("Test Meme", "TMEME", 1000000 * 1e18, 0.001 ether);
        
        // First, trigger liquidity
        uint256 costNeeded = (LIQUIDITY_THRESHOLD * 10000) / 9500;
        uint256 mintAmount1 = costNeeded * 1e18 / 0.001 ether;
        
        vm.prank(user1);
        factory.mintMeme{value: costNeeded}(memeToken, mintAmount1);
        
        // Verify liquidity was added
        MemeFactory.TokenData memory tokenData = factory.getTokenData(memeToken);
        assertTrue(tokenData.liquidityAdded);
        
        // Now try to mint more - should fail
        uint256 mintAmount2 = 100 * 1e18;
        uint256 cost2 = mintAmount2 * 0.001 ether / 1e18;
        
        vm.prank(user2);
        vm.expectRevert("Liquidity already added");
        factory.mintMeme{value: cost2}(memeToken, mintAmount2);
    }
}