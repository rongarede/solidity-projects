// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/RebaseToken.sol";

contract RebaseTokenCoreTest is Test {
    RebaseToken public token;
    address public owner = address(this);
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    uint256 constant INITIAL_SUPPLY = 100_000_000 * 10**18;
    uint256 constant BLOCKS_PER_YEAR = 15_768_000;
    uint256 constant INDEX_PRECISION = 1e18;
    uint256 constant DEFLATION_RATE = 99 * 10**16;

    event Rebase(uint256 indexed yearsElapsed, uint256 newIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function setUp() public {
        token = new RebaseToken("Rebase Token", "RBT", 18);
    }

    // ===== Core Rebase Functionality Tests =====

    function test_Rebase_ShouldApplyDeflationAfterMultipleYears() public {
        // Given: 5 years have passed
        uint256 yearsElapsed = 5;
        vm.roll(block.number + (BLOCKS_PER_YEAR * yearsElapsed));

        // When: We trigger rebase
        vm.expectEmit(true, true, true, true);
        emit Rebase(yearsElapsed, 950990049899999989);
        
        token.rebase();

        // Then: Index should reflect 5 years of deflation
        assertApproxEqAbs(token.index(), 950990049899999989, 1000, "Index should reflect 5 years of 1% deflation");
    }

    function test_Rebase_ShouldHandleLargeNumberOfYears() public {
        // Given: 100 years have passed
        uint256 yearsElapsed = 100;
        vm.roll(block.number + (BLOCKS_PER_YEAR * yearsElapsed));

        // When: We trigger rebase
        vm.expectEmit(true, true, true, true);
        emit Rebase(yearsElapsed, 366032341273013345);
        
        token.rebase();

        // Then: Index should reflect 100 years of deflation (0.99^100)
        assertApproxEqAbs(token.index(), 366032341273013345, 1000, "Index should reflect 100 years of deflation");
    }

    function test_Rebase_ShouldMaintainShareProportions() public {
        // Given: Alice and Bob have different balances
        token.transfer(alice, 1000 * 10**18);
        token.transfer(bob, 2000 * 10**18);

        uint256 aliceSharesBefore = token.sharesOf(alice);
        uint256 bobSharesBefore = token.sharesOf(bob);
        uint256 totalSharesBefore = token.totalShares();

        // When: We advance 1 year and rebase
        vm.roll(block.number + BLOCKS_PER_YEAR);
        token.rebase();

        // Then: Share proportions should remain exactly the same
        assertEq(token.sharesOf(alice), aliceSharesBefore, "Alice's shares should not change");
        assertEq(token.sharesOf(bob), bobSharesBefore, "Bob's shares should not change");
        assertEq(token.totalShares(), totalSharesBefore, "Total shares should not change");
    }

    // ===== Transfer and Balance Consistency Tests =====

    function test_Transfer_ShouldMaintainConsistentBalanceCalculations() public {
        // Given: Alice has a balance
        uint256 transferAmount = 1000 * 10**18;
        token.transfer(alice, transferAmount);

        // When: Multiple transfers occur
        vm.prank(alice);
        token.transfer(bob, 300 * 10**18);

        vm.prank(bob);
        token.transfer(charlie, 100 * 10**18);

        // Then: All balances should be calculated consistently
        uint256 aliceExpected = 700 * 10**18;
        uint256 bobExpected = 200 * 10**18;
        uint256 charlieExpected = 100 * 10**18;

        assertEq(token.balanceOf(alice), aliceExpected, "Alice balance should be correct");
        assertEq(token.balanceOf(bob), bobExpected, "Bob balance should be correct");
        assertEq(token.balanceOf(charlie), charlieExpected, "Charlie balance should be correct");
    }

    function test_Transfer_ShouldWorkAfterRebase() public {
        // Given: Initial balances
        token.transfer(alice, 1000 * 10**18);
        
        // Advance 1 year and rebase
        vm.roll(block.number + BLOCKS_PER_YEAR);
        token.rebase();

        // When: Alice transfers to Bob after rebase
        uint256 aliceBalanceBefore = token.balanceOf(alice);
        vm.prank(alice);
        bool success = token.transfer(bob, 500 * 10**18);

        // Then: Transfer should succeed with updated balances
        assertTrue(success, "Transfer should succeed after rebase");
        assertEq(token.balanceOf(alice), aliceBalanceBefore - 500 * 10**18, "Alice balance should decrease");
        assertEq(token.balanceOf(bob), 500 * 10**18, "Bob should receive correct amount");
    }

    // ===== Approval and Allowance Tests =====

    function test_Approve_ShouldAllowPreciseAllowanceManagement() public {
        // Given: Alice wants to approve Bob for specific amounts
        uint256 approveAmount = 1000 * 10**18;
        uint256 transferAmount = 500 * 10**18;

        // When: Alice approves Bob and Bob transfers
        vm.prank(alice);
        token.approve(bob, approveAmount);

        vm.prank(bob);
        token.transferFrom(alice, charlie, transferAmount);

        // Then: Allowance should be correctly reduced
        assertEq(token.allowance(alice, bob), approveAmount - transferAmount, "Allowance should be reduced by transfer amount");
    }

    function test_Approve_ShouldHandleInfiniteAllowanceCorrectly() public {
        // Given: Alice approves Bob for infinite allowance
        vm.prank(alice);
        token.approve(bob, type(uint256).max);

        // When: Bob makes multiple transfers
        vm.prank(bob);
        token.transferFrom(alice, charlie, 1000 * 10**18);

        vm.prank(bob);
        token.transferFrom(alice, charlie, 2000 * 10**18);

        // Then: Allowance should remain at max
        assertEq(token.allowance(alice, bob), type(uint256).max, "Infinite allowance should not be reduced");
    }

    // ===== Share/Amount Conversion Tests =====

    function test_ShareConversion_ShouldBeAccurate() public {
        // Given: Various test amounts
        uint256[] memory testAmounts = new uint256[](5);
        testAmounts[0] = 1;
        testAmounts[1] = 1000;
        testAmounts[2] = 10**18;
        testAmounts[3] = 1000 * 10**18;
        testAmounts[4] = 1000000 * 10**18;

        for (uint i = 0; i < testAmounts.length; i++) {
            uint256 amount = testAmounts[i];
            
            // When: We convert amount to shares and back
            uint256 shares = token.getSharesByAmount(amount);
            uint256 convertedBack = token.getAmountByShares(shares);

            // Then: Conversion should be exact
            assertEq(convertedBack, amount, "Conversion should be exact for all amounts");
        }
    }

    function test_ShareConversion_ShouldUpdateAfterRebase() public {
        // Given: Initial conversion
        uint256 amount = 1000 * 10**18;
        uint256 sharesBefore = token.getSharesByAmount(amount);

        // When: We rebase after 1 year
        vm.roll(block.number + BLOCKS_PER_YEAR);
        token.rebase();

        // Then: Conversion should use new index
        uint256 sharesAfter = token.getSharesByAmount(amount);
        assertGt(sharesAfter, sharesBefore, "Should need more shares for same amount after deflation");
    }

    // ===== Information Functions Tests =====

    function test_GetRebaseInfo_ShouldProvideAccurateTiming() public {
        // Given: Various time scenarios
        
        // Initially
        (uint256 currentIndex, uint256 blocksUntilNext, uint256 expectedIndex) = token.getRebaseInfo();
        assertEq(currentIndex, INDEX_PRECISION, "Initial index should be 1e18");
        assertEq(blocksUntilNext, BLOCKS_PER_YEAR, "Should show full year remaining");
        assertEq(expectedIndex, INDEX_PRECISION * DEFLATION_RATE / 1e18, "Expected index should be 0.99");

        // After half year
        vm.roll(block.number + BLOCKS_PER_YEAR / 2);
        (, blocksUntilNext, ) = token.getRebaseInfo();
        assertEq(blocksUntilNext, BLOCKS_PER_YEAR / 2, "Should show half year remaining");

        // After full year
        vm.roll(block.number + BLOCKS_PER_YEAR);
        (, blocksUntilNext, ) = token.getRebaseInfo();
        assertEq(blocksUntilNext, 0, "Should show rebase is eligible");
    }

    function test_GetRebaseStats_ShouldProvideCompleteState() public {
        // Given: Initial state
        uint256[6] memory stats = token.getRebaseStats();

        // Then: Should provide complete system state
        assertEq(stats[0], INDEX_PRECISION, "Current index");
        assertEq(stats[1], BLOCKS_PER_YEAR, "Blocks until next rebase");
        assertEq(stats[2], INDEX_PRECISION * DEFLATION_RATE / 1e18, "Expected next index");
        assertEq(stats[3], INITIAL_SUPPLY, "Total supply");
        assertEq(stats[4], INITIAL_SUPPLY, "Total shares");
        assertEq(stats[5], 0, "Years elapsed");
    }
}