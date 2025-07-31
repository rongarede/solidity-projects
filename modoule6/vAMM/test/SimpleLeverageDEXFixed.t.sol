// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {SimpleLeverageDEXFixed} from "../src/SimpleLeverageDEXFixed.sol";
import {MockUSDC} from "../src/MockUSDC.sol";

contract SimpleLeverageDEXFixedTest is Test {
    SimpleLeverageDEXFixed public dex;
    MockUSDC public usdc;
    
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");
    
    uint256 public constant INITIAL_VETH = 1000 * 1e18;  // 1000 vETH with 18 decimals
    uint256 public constant INITIAL_VUSDC = 2000000 * 1e6;  // 2,000,000 USDC with 6 decimals
    uint256 public constant INITIAL_USDC_BALANCE = 10000 * 1e6;

    function setUp() public {
        usdc = new MockUSDC();
        dex = new SimpleLeverageDEXFixed(INITIAL_VETH, INITIAL_VUSDC, address(usdc));
        
        usdc.mint(alice, INITIAL_USDC_BALANCE);
        usdc.mint(bob, INITIAL_USDC_BALANCE);
        usdc.mint(charlie, INITIAL_USDC_BALANCE);
        
        vm.prank(alice);
        usdc.approve(address(dex), type(uint256).max);
        
        vm.prank(bob);
        usdc.approve(address(dex), type(uint256).max);
        
        vm.prank(charlie);
        usdc.approve(address(dex), type(uint256).max);
        
        // Add some USDC to the DEX contract for payouts (like the working reference)
        usdc.mint(address(dex), 10000000 * 1e6);  // 10M USDC for protocol operations
    }

    function testBasicFunctionality() public {
        // Test initialization
        (uint256 ethAmount, uint256 usdcAmount, uint256 k, uint256 price) = dex.getPoolState();
        assertEq(ethAmount, INITIAL_VETH);
        assertEq(usdcAmount, INITIAL_VUSDC);
        assertEq(k, INITIAL_VETH * INITIAL_VUSDC);
        assertEq(price, 2000 * 1e6); // 2000 USDC per ETH (scaled to USDC decimals)
        
        console.log("Initial price:", price);
        
        // Test opening long position
        vm.prank(alice);
        dex.openPosition(1000 * 1e6, 2, true);
        
        (uint256 margin, uint256 borrowed, int256 position, uint256 entryPrice) = dex.positions(alice);
        assertEq(margin, 1000 * 1e6);
        assertEq(borrowed, 1000 * 1e6);
        assertTrue(position > 0);
        assertEq(entryPrice, 2000 * 1e6);
        
        console.log("Alice position:", uint256(position));
        console.log("Alice entry price:", entryPrice);
        
        // Verify constant product (allow for small precision loss due to integer division)
        (ethAmount, usdcAmount, k,) = dex.getPoolState();
        uint256 newK = ethAmount * usdcAmount;
        uint256 initialK = INITIAL_VETH * INITIAL_VUSDC;
        uint256 precision_tolerance = initialK / 1e12; // Allow 0.0001% precision loss
        assertTrue(newK >= initialK - precision_tolerance && newK <= initialK + precision_tolerance, "Constant product violated beyond acceptable precision");
        
        // Test PnL calculation
        int256 pnl = dex.calculatePnL(alice);
        console.log("Alice PnL:", pnl);
        
        // Test closing position
        vm.prank(alice);
        dex.closePosition();
        
        // Verify position is closed
        (margin, borrowed, position,) = dex.positions(alice);
        assertEq(margin, 0);
        assertEq(borrowed, 0);
        assertEq(position, 0);
    }

    function testShortPosition() public {
        vm.prank(bob);
        dex.openPosition(1000 * 1e6, 2, false);
        
        (, , int256 position,) = dex.positions(bob);
        assertTrue(position < 0, "Short position should be negative");
        
        int256 pnl = dex.calculatePnL(bob);
        console.log("Bob short PnL:", pnl);
        
        vm.prank(bob);
        dex.closePosition();
        
        (, , position,) = dex.positions(bob);
        assertEq(position, 0);
    }

    function testMultipleUsers() public {
        // Alice long
        vm.prank(alice);
        dex.openPosition(1000 * 1e6, 2, true);
        
        // Bob short
        vm.prank(bob);
        dex.openPosition(800 * 1e6, 3, false);
        
        // Check both positions exist
        (, , int256 alicePos,) = dex.positions(alice);
        (, , int256 bobPos,) = dex.positions(bob);
        
        assertTrue(alicePos > 0);
        assertTrue(bobPos < 0);
        
        // Check PnL
        console.log("Alice PnL:", dex.calculatePnL(alice));
        console.log("Bob PnL:", dex.calculatePnL(bob));
        
        // Close positions
        vm.prank(alice);
        dex.closePosition();
        
        vm.prank(bob);
        dex.closePosition();
    }

    function testErrorHandling() public {
        // Cannot open multiple positions
        vm.prank(alice);
        dex.openPosition(1000 * 1e6, 2, true);
        
        vm.prank(alice);
        vm.expectRevert("Position already open");
        dex.openPosition(500 * 1e6, 2, false);
        
        // Cannot close non-existent position
        vm.prank(bob);
        vm.expectRevert("No open position");
        dex.closePosition();
        
        // Cannot calculate PnL without position
        vm.expectRevert("No open position");
        dex.calculatePnL(bob);
    }
}