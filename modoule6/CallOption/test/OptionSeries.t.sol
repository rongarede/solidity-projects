// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/OptionSeries.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// Mock USDT token for testing
contract MockUSDT is ERC20 {
    constructor() ERC20("Mock USDT", "USDT") {
        _mint(msg.sender, 1000000 * 10**18); // Mint 1M USDT tokens
    }
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract OptionSeriesTest is Test {
    OptionSeries public optionSeries;
    MockUSDT public usdtToken;
    address public owner;
    address public user1;
    address public user2;
    address public user3;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        
        // Deploy contracts
        optionSeries = new OptionSeries();
        usdtToken = new MockUSDT();
        
        // Give users ETH
        vm.deal(user1, 5000 ether);
        vm.deal(user2, 5000 ether);
        vm.deal(user3, 5000 ether);
        
        // Give users USDT tokens
        usdtToken.mint(user1, 100000 * 10**18); // 100k USDT
        usdtToken.mint(user2, 100000 * 10**18); // 100k USDT
        usdtToken.mint(user3, 100000 * 10**18); // 100k USDT
        usdtToken.mint(owner, 100000 * 10**18);  // 100k USDT for owner
    }

    // ========================================
    // ORIGINAL OPTION FUNCTIONALITY TESTS
    // ========================================

    function test_mint_success() public {
        vm.startPrank(user1);
        
        uint256 mintAmount = 1 ether;
        optionSeries.mint{value: mintAmount}();
        
        assertEq(optionSeries.balanceOf(user1), mintAmount);
        assertEq(optionSeries.totalCollateral(), mintAmount);
        assertEq(address(optionSeries).balance, mintAmount);
        
        vm.stopPrank();
    }

    function test_exercise_success() public {
        vm.startPrank(user1);
        
        uint256 mintAmount = 1 ether;
        optionSeries.mint{value: mintAmount}();
        
        uint256 strikePrice = optionSeries.strikePrice();
        uint256 exerciseAmount = 0.5 ether;
        uint256 exerciseCost = exerciseAmount * strikePrice / 1 ether;
        
        uint256 balanceBefore = user1.balance;
        optionSeries.exercise{value: exerciseCost}(exerciseAmount);
        
        assertEq(optionSeries.balanceOf(user1), mintAmount - exerciseAmount);
        assertEq(optionSeries.totalCollateral(), mintAmount - exerciseAmount);
        assertEq(user1.balance, balanceBefore - exerciseCost + exerciseAmount);
        
        vm.stopPrank();
    }

    function test_collectExpired_success() public {
        vm.startPrank(user1);
        optionSeries.mint{value: 1 ether}();
        vm.stopPrank();
        
        vm.warp(block.timestamp + 8 days);
        
        uint256 ownerBalanceBefore = owner.balance;
        uint256 contractBalance = address(optionSeries).balance;
        
        optionSeries.collectExpired();
        
        assertEq(optionSeries.totalCollateral(), 0);
        assertEq(address(optionSeries).balance, 0);
        assertEq(owner.balance, ownerBalanceBefore + contractBalance);
    }

    function test_mint_zero_eth() public {
        vm.startPrank(user1);
        
        vm.expectRevert("Must send ETH as collateral");
        optionSeries.mint{value: 0}();
        
        vm.stopPrank();
    }

    function test_exercise_after_expiry() public {
        vm.startPrank(user1);
        optionSeries.mint{value: 1 ether}();
        vm.stopPrank();
        
        vm.warp(block.timestamp + 8 days);
        
        vm.startPrank(user1);
        vm.expectRevert("Option has expired");
        optionSeries.exercise{value: 2000 ether}(1 ether);
        vm.stopPrank();
    }

    function test_exercise_insufficient_options() public {
        vm.startPrank(user1);
        optionSeries.mint{value: 1 ether}();
        
        uint256 strikePrice = optionSeries.strikePrice();
        uint256 exerciseAmount = 2 ether; // Try to exercise more than owned
        uint256 exerciseCost = exerciseAmount * strikePrice / 1 ether;
        
        vm.expectRevert("Insufficient option tokens");
        optionSeries.exercise{value: exerciseCost}(exerciseAmount);
        vm.stopPrank();
    }

    function test_exercise_incorrect_payment() public {
        vm.startPrank(user1);
        optionSeries.mint{value: 1 ether}();
        
        uint256 strikePrice = optionSeries.strikePrice();
        uint256 exerciseAmount = 0.5 ether;
        uint256 correctPayment = exerciseAmount * strikePrice / 1 ether;
        uint256 wrongPayment = correctPayment + 1 ether; // Wrong payment amount
        
        vm.expectRevert("Incorrect exercise payment");
        optionSeries.exercise{value: wrongPayment}(exerciseAmount);
        vm.stopPrank();
    }

    function test_collectExpired_before_expiry() public {
        vm.startPrank(user1);
        optionSeries.mint{value: 1 ether}();
        vm.stopPrank();
        
        vm.expectRevert("Option not yet expired");
        optionSeries.collectExpired();
    }

    function test_collectExpired_not_owner() public {
        vm.startPrank(user1);
        optionSeries.mint{value: 1 ether}();
        vm.stopPrank();
        
        vm.warp(block.timestamp + 8 days);
        
        vm.startPrank(user2);
        vm.expectRevert();
        optionSeries.collectExpired();
        vm.stopPrank();
    }

    receive() external payable {}
    
    // ========================================
    // NEW TRADING FUNCTIONALITY TESTS
    // ========================================
    
    // Test createPair success
    function test_createPair_success() public {
        // Owner mints some option tokens first
        optionSeries.mint{value: 10 ether}();
        
        uint256 optionAmount = 5 ether;
        uint256 usdtAmount = 500 * 10**18; // 500 USDT
        
        // Approve USDT transfer
        usdtToken.approve(address(optionSeries), usdtAmount);
        
        // Create pair
        optionSeries.createPair(address(usdtToken), optionAmount, usdtAmount);
        
        // Verify pair creation
        assertTrue(optionSeries.pairCreated());
        assertEq(address(optionSeries.usdtToken()), address(usdtToken));
        
        (uint256 optionReserve, uint256 usdtReserve) = optionSeries.getReserves();
        assertEq(optionReserve, optionAmount);
        assertEq(usdtReserve, usdtAmount);
        
        // Verify tokens were transferred
        assertEq(optionSeries.balanceOf(address(optionSeries)), optionAmount);
        assertEq(usdtToken.balanceOf(address(optionSeries)), usdtAmount);
    }
    
    // Test createPair failure - already created
    function test_createPair_already_created() public {
        // Create pair first time
        optionSeries.mint{value: 10 ether}();
        usdtToken.approve(address(optionSeries), 500 * 10**18);
        optionSeries.createPair(address(usdtToken), 5 ether, 500 * 10**18);
        
        // Try to create again
        vm.expectRevert("Pair already created");
        optionSeries.createPair(address(usdtToken), 1 ether, 100 * 10**18);
    }
    
    // Test createPair failure - invalid USDT address
    function test_createPair_invalid_usdt_address() public {
        optionSeries.mint{value: 10 ether}();
        
        vm.expectRevert("Invalid USDT address");
        optionSeries.createPair(address(0), 5 ether, 500 * 10**18);
    }
    
    // Test createPair failure - zero amounts
    function test_createPair_zero_option_amount() public {
        optionSeries.mint{value: 10 ether}();
        usdtToken.approve(address(optionSeries), 500 * 10**18);
        
        vm.expectRevert("Invalid amounts");
        optionSeries.createPair(address(usdtToken), 0, 500 * 10**18);
    }
    
    function test_createPair_zero_usdt_amount() public {
        optionSeries.mint{value: 10 ether}();
        
        vm.expectRevert("Invalid amounts");
        optionSeries.createPair(address(usdtToken), 5 ether, 0);
    }
    
    // Test createPair failure - insufficient option tokens
    function test_createPair_insufficient_option_tokens() public {
        optionSeries.mint{value: 1 ether}(); // Only mint 1 ether worth
        usdtToken.approve(address(optionSeries), 500 * 10**18);
        
        vm.expectRevert("Insufficient option tokens");
        optionSeries.createPair(address(usdtToken), 5 ether, 500 * 10**18); // Try to use 5 ether
    }
    
    // Test createPair failure - USDT transfer fails
    function test_createPair_usdt_transfer_fails() public {
        optionSeries.mint{value: 10 ether}();
        // Don't approve USDT transfer
        
        vm.expectRevert();
        optionSeries.createPair(address(usdtToken), 5 ether, 500 * 10**18);
    }
    
    // Test createPair failure - not owner
    function test_createPair_not_owner() public {
        vm.startPrank(user1);
        optionSeries.mint{value: 10 ether}();
        
        vm.expectRevert();
        optionSeries.createPair(address(usdtToken), 5 ether, 500 * 10**18);
        vm.stopPrank();
    }
    
    // Helper function to create pair for testing
    function _createPair() internal {
        optionSeries.mint{value: 10 ether}();
        usdtToken.approve(address(optionSeries), 1000 * 10**18);
        optionSeries.createPair(address(usdtToken), 10 ether, 1000 * 10**18);
    }
    
    // Test buyOption success
    function test_buyOption_success() public {
        _createPair();
        
        vm.startPrank(user1);
        uint256 usdtAmount = 200 * 10**18; // 200 USDT
        uint256 expectedOptionAmount = 2 ether; // 200 USDT / 100 = 2 options
        
        // Approve USDT transfer
        usdtToken.approve(address(optionSeries), usdtAmount);
        
        uint256 userOptionBalanceBefore = optionSeries.balanceOf(user1);
        uint256 userUsdtBalanceBefore = usdtToken.balanceOf(user1);
        
        // Buy options
        optionSeries.buyOption(usdtAmount);
        
        // Verify option tokens received
        assertEq(optionSeries.balanceOf(user1), userOptionBalanceBefore + expectedOptionAmount);
        
        // Verify USDT paid
        assertEq(usdtToken.balanceOf(user1), userUsdtBalanceBefore - usdtAmount);
        
        // Verify reserves updated
        (uint256 optionReserve, uint256 usdtReserve) = optionSeries.getReserves();
        assertEq(optionReserve, 10 ether - expectedOptionAmount);
        assertEq(usdtReserve, 1000 * 10**18 + usdtAmount);
        
        vm.stopPrank();
    }
    
    // Test buyOption failure - pair not created
    function test_buyOption_pair_not_created() public {
        vm.startPrank(user1);
        
        vm.expectRevert("Trading pair not created");
        optionSeries.buyOption(100 * 10**18);
        
        vm.stopPrank();
    }
    
    // Test buyOption failure - zero USDT amount
    function test_buyOption_zero_usdt_amount() public {
        _createPair();
        
        vm.startPrank(user1);
        
        vm.expectRevert("Invalid USDT amount");
        optionSeries.buyOption(0);
        
        vm.stopPrank();
    }
    
    // Test buyOption failure - after expiry
    function test_buyOption_after_expiry() public {
        _createPair();
        
        vm.warp(block.timestamp + 8 days); // Move past expiry
        
        vm.startPrank(user1);
        usdtToken.approve(address(optionSeries), 100 * 10**18);
        
        vm.expectRevert("Option has expired");
        optionSeries.buyOption(100 * 10**18);
        
        vm.stopPrank();
    }
    
    // Test buyOption failure - USDT amount too small
    function test_buyOption_usdt_amount_too_small() public {
        _createPair();
        
        vm.startPrank(user1);
        uint256 smallAmount = 50; // 50 wei USDT -> 0 options due to integer division
        usdtToken.approve(address(optionSeries), smallAmount);
        
        vm.expectRevert("USDT amount too small");
        optionSeries.buyOption(smallAmount);
        
        vm.stopPrank();
    }
    
    // Test buyOption failure - insufficient option liquidity
    function test_buyOption_insufficient_option_liquidity() public {
        _createPair();
        
        vm.startPrank(user1);
        uint256 largeAmount = 1500 * 10**18; // 1500 USDT -> 15 options, but only 10 available
        usdtToken.approve(address(optionSeries), largeAmount);
        
        vm.expectRevert("Insufficient option liquidity");
        optionSeries.buyOption(largeAmount);
        
        vm.stopPrank();
    }
    
    // Test buyOption failure - USDT transfer fails
    function test_buyOption_usdt_transfer_fails() public {
        _createPair();
        
        vm.startPrank(user1);
        // Don't approve USDT transfer
        
        vm.expectRevert();
        optionSeries.buyOption(100 * 10**18);
        
        vm.stopPrank();
    }
    
    // Test getReserves function
    function test_getReserves() public {
        // Before pair creation
        (uint256 optionReserve, uint256 usdtReserve) = optionSeries.getReserves();
        assertEq(optionReserve, 0);
        assertEq(usdtReserve, 0);
        
        // After pair creation
        _createPair();
        (optionReserve, usdtReserve) = optionSeries.getReserves();
        assertEq(optionReserve, 10 ether);
        assertEq(usdtReserve, 1000 * 10**18);
        
        // After a purchase
        vm.startPrank(user1);
        usdtToken.approve(address(optionSeries), 200 * 10**18);
        optionSeries.buyOption(200 * 10**18);
        vm.stopPrank();
        
        (optionReserve, usdtReserve) = optionSeries.getReserves();
        assertEq(optionReserve, 8 ether); // 10 - 2
        assertEq(usdtReserve, 1200 * 10**18); // 1000 + 200
    }
    
    // Test getOptionAmountOut function
    function test_getOptionAmountOut() public {
        assertEq(optionSeries.getOptionAmountOut(100 * 10**18), 1 ether);
        assertEq(optionSeries.getOptionAmountOut(250 * 10**18), 2.5 ether);
        assertEq(optionSeries.getOptionAmountOut(50 * 10**18), 0.5 ether);
        assertEq(optionSeries.getOptionAmountOut(0), 0);
    }
    
    // ========================================
    // INTEGRATION TESTS
    // ========================================
    
    // Test full workflow: mint -> create pair -> buy -> exercise
    function test_full_workflow_mint_create_buy_exercise() public {
        // 1. Owner mints options
        optionSeries.mint{value: 20 ether}();
        
        // 2. Owner creates trading pair
        usdtToken.approve(address(optionSeries), 1000 * 10**18);
        optionSeries.createPair(address(usdtToken), 10 ether, 1000 * 10**18);
        
        // 3. User buys options with USDT
        vm.startPrank(user1);
        usdtToken.approve(address(optionSeries), 300 * 10**18);
        optionSeries.buyOption(300 * 10**18); // Gets 3 options
        
        // 4. User exercises purchased options
        uint256 strikePrice = optionSeries.strikePrice();
        uint256 exerciseAmount = 2 ether;
        uint256 exerciseCost = exerciseAmount * strikePrice / 1 ether;
        
        uint256 balanceBefore = user1.balance;
        optionSeries.exercise{value: exerciseCost}(exerciseAmount);
        
        // Verify exercise worked
        assertEq(optionSeries.balanceOf(user1), 1 ether); // Had 3, exercised 2
        assertEq(user1.balance, balanceBefore - exerciseCost + exerciseAmount);
        
        vm.stopPrank();
    }
    
    // Test buying options then collecting expired collateral
    function test_buy_options_then_collect_expired() public {
        _createPair();
        
        // User buys some options
        vm.startPrank(user1);
        usdtToken.approve(address(optionSeries), 500 * 10**18);
        optionSeries.buyOption(500 * 10**18); // Gets 5 options
        vm.stopPrank();
        
        // Move past expiry
        vm.warp(block.timestamp + 8 days);
        
        // Owner collects expired collateral (should collect the original 10 ether collateral)
        uint256 ownerBalanceBefore = owner.balance;
        uint256 expectedCollateral = 10 ether; // Original collateral from _createPair
        optionSeries.collectExpired();
        
        // Should collect all remaining collateral
        assertEq(owner.balance, ownerBalanceBefore + expectedCollateral);
    }
    
    // Test edge case: buy exact remaining liquidity
    function test_buy_exact_remaining_liquidity() public {
        _createPair(); // Creates 10 ether options, 1000 USDT
        
        vm.startPrank(user1);
        uint256 exactAmount = 1000 * 10**18; // Should buy exactly 10 options
        usdtToken.approve(address(optionSeries), exactAmount);
        
        optionSeries.buyOption(exactAmount);
        
        // Verify all options were purchased
        assertEq(optionSeries.balanceOf(user1), 10 ether);
        
        (uint256 optionReserve,) = optionSeries.getReserves();
        assertEq(optionReserve, 0); // No options left
        
        vm.stopPrank();
    }
    
    // Test multiple users buying options
    function test_multiple_users_buying_options() public {
        _createPair();
        
        // User1 buys options
        vm.startPrank(user1);
        usdtToken.approve(address(optionSeries), 300 * 10**18);
        optionSeries.buyOption(300 * 10**18);
        vm.stopPrank();
        
        // User2 buys options
        vm.startPrank(user2);
        usdtToken.approve(address(optionSeries), 400 * 10**18);
        optionSeries.buyOption(400 * 10**18);
        vm.stopPrank();
        
        // User3 buys remaining options
        vm.startPrank(user3);
        usdtToken.approve(address(optionSeries), 300 * 10**18);
        optionSeries.buyOption(300 * 10**18);
        vm.stopPrank();
        
        // Verify balances
        assertEq(optionSeries.balanceOf(user1), 3 ether);
        assertEq(optionSeries.balanceOf(user2), 4 ether);
        assertEq(optionSeries.balanceOf(user3), 3 ether);
        
        // Verify no options left
        (uint256 optionReserve,) = optionSeries.getReserves();
        assertEq(optionReserve, 0);
    }

    // Test events are properly emitted
    function test_createPair_event() public {
        optionSeries.mint{value: 10 ether}();
        usdtToken.approve(address(optionSeries), 500 * 10**18);
        
        vm.expectEmit(true, false, false, true);
        emit OptionSeries.PairCreated(address(usdtToken), 5 ether, 500 * 10**18);
        
        optionSeries.createPair(address(usdtToken), 5 ether, 500 * 10**18);
    }
    
    function test_buyOption_event() public {
        _createPair();
        
        vm.startPrank(user1);
        usdtToken.approve(address(optionSeries), 200 * 10**18);
        
        vm.expectEmit(true, false, false, true);
        emit OptionSeries.OptionPurchased(user1, 200 * 10**18, 2 ether);
        
        optionSeries.buyOption(200 * 10**18);
        vm.stopPrank();
    }
}