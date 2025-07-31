// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/RebaseToken.sol";

contract RebaseTokenEdgeCasesTest is Test {
    RebaseToken public token;
    address public owner = address(this);
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    uint256 constant INITIAL_SUPPLY = 100_000_000 * 10**18;
    uint256 constant BLOCKS_PER_YEAR = 15_768_000;
    uint256 constant INDEX_PRECISION = 1e18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        token = new RebaseToken("Rebase Token", "RBT", 18);
    }

    // ===== Extreme Values Tests =====

    function test_Extreme_TinyAmountsShouldWorkCorrectly() public {
        // Given: Extremely small amounts
        uint256 tinyAmount = 1; // 1 wei
        
        // When: We transfer tiny amounts
        token.transfer(alice, tinyAmount);
        
        // Then: Should handle tiny amounts correctly
        assertEq(token.balanceOf(alice), tinyAmount, "Should handle 1 wei correctly");
        
        // After rebase, tiny amount should still be correct
        vm.roll(block.number + BLOCKS_PER_YEAR);
        token.rebase();
        
        uint256 expectedAfterRebase = tinyAmount * 99 / 100;
        assertApproxEqAbs(token.balanceOf(alice), expectedAfterRebase, 1, "Tiny amount should scale correctly");
    }

    function test_Extreme_MaxUint256Handling() public {
        // Given: Maximum possible values
        uint256 maxUint = type(uint256).max;
        
        // When: We attempt to get shares for max amount
        uint256 shares = token.getSharesByAmount(maxUint);
        
        // Then: Should not overflow in calculations
        assertGt(shares, 0, "Should produce valid shares for any uint256 amount");
        
        // Should be able to convert back
        uint256 convertedBack = token.getAmountByShares(shares);
        assertLe(convertedBack, maxUint, "Converted back should be <= original");
    }

    function test_Extreme_VeryLargeYearsElapsed() public {
        // Given: Extremely long time period (1000 years)
        uint256 yearsElapsed = 1000;
        vm.roll(block.number + (BLOCKS_PER_YEAR * yearsElapsed));
        
        // When: We trigger rebase
        vm.recordLogs();
        token.rebase();
        
        // Then: Should handle without overflow
        uint256 finalIndex = token.index();
        assertGt(finalIndex, 0, "Index should never become zero");
        assertLt(finalIndex, INDEX_PRECISION, "Index should decrease over time");
        
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 1, "Should emit exactly one Rebase event");
        assertEq(entries[0].topics[0], keccak256("Rebase(uint256,uint256)"), "Should emit Rebase event");
    }

    // ===== Boundary Conditions Tests =====

    function test_Boundary_ExactlyOneYear() public {
        // Given: Exactly one year has passed
        vm.roll(block.number + BLOCKS_PER_YEAR);
        
        // When: We trigger rebase
        uint256 balanceBefore = token.balanceOf(owner);
        token.rebase();
        
        // Then: Should apply exactly 1 year of deflation
        uint256 expectedBalance = balanceBefore * 99 / 100;
        assertEq(token.balanceOf(owner), expectedBalance, "Should apply exactly 1% deflation");
    }

    function test_Boundary_JustUnderOneYear() public {
        // Given: Just under one year has passed
        uint256 blocksElapsed = BLOCKS_PER_YEAR - 1;
        vm.roll(block.number + blocksElapsed);
        
        // When: We attempt rebase
        vm.recordLogs();
        token.rebase();
        
        // Then: Should not apply any deflation
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0, "Should not emit Rebase event");
        assertEq(token.index(), INDEX_PRECISION, "Index should remain unchanged");
    }

    function test_Boundary_JustOverOneYear() public {
        // Given: Just over one year has passed
        uint256 blocksElapsed = BLOCKS_PER_YEAR + 1;
        vm.roll(block.number + blocksElapsed);
        
        // When: We trigger rebase
        uint256 balanceBefore = token.balanceOf(owner);
        token.rebase();
        
        // Then: Should apply exactly 1 year of deflation (not 2)
        uint256 expectedBalance = balanceBefore * 99 / 100;
        assertEq(token.balanceOf(owner), expectedBalance, "Should apply exactly 1% deflation");
    }

    function test_Boundary_FractionalYearRounding() public {
        // Given: Various fractional year amounts
        uint256[] memory testYears = new uint256[](5);
        testYears[0] = 0;
        testYears[1] = 1;
        testYears[2] = 1 * BLOCKS_PER_YEAR + (BLOCKS_PER_YEAR / 2); // 1.5 years
        testYears[3] = 2 * BLOCKS_PER_YEAR - 1; // Just under 2 years
        testYears[4] = 2 * BLOCKS_PER_YEAR; // Exactly 2 years

        for (uint i = 0; i < testYears.length; i++) {
            // Reset state for each test
            RebaseToken freshToken = new RebaseToken("Test", "TST", 18);
            vm.roll(block.number + testYears[i]);
            
            uint256 balanceBefore = freshToken.balanceOf(address(this));
            freshToken.rebase();
            
            uint256 expectedYears = testYears[i] / BLOCKS_PER_YEAR;
            uint256 expectedBalance;
            
            if (expectedYears == 0) {
                expectedBalance = balanceBefore;
            } else {
                expectedBalance = balanceBefore;
                for (uint j = 0; j < expectedYears; j++) {
                    expectedBalance = expectedBalance * 99 / 100;
                }
            }
            
            assertEq(freshToken.balanceOf(address(this)), expectedBalance, 
                string(abi.encodePacked("Year ", vm.toString(expectedYears), " calculation should be correct")));
        }
    }

    // ===== Zero and Edge Amount Tests =====

    function test_Zero_AmountTransferShouldSucceed() public {
        // Given: Zero amount
        uint256 zeroAmount = 0;
        
        // When: We transfer zero amount
        vm.expectEmit(true, true, true, true);
        emit Transfer(owner, alice, zeroAmount);
        
        bool success = token.transfer(alice, zeroAmount);
        
        // Then: Should succeed without changing balances
        assertTrue(success, "Zero transfer should succeed");
        assertEq(token.balanceOf(alice), 0, "Alice balance should remain zero");
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY, "Owner balance should not change");
    }

    function test_Zero_ShareConversionShouldBeExact() public {
        // Given: Zero amounts
        uint256 zeroAmount = 0;
        uint256 zeroShares = 0;
        
        // When: We convert zero amounts
        uint256 sharesFromAmount = token.getSharesByAmount(zeroAmount);
        uint256 amountFromShares = token.getAmountByShares(zeroShares);
        
        // Then: Should be exact
        assertEq(sharesFromAmount, 0, "Zero amount should convert to zero shares");
        assertEq(amountFromShares, 0, "Zero shares should convert to zero amount");
    }

    function test_Edge_SingleWeiPrecision() public {
        // Given: Single wei amounts
        uint256 singleWei = 1;
        
        // When: We test precision at wei level
        uint256 shares = token.getSharesByAmount(singleWei);
        uint256 convertedBack = token.getAmountByShares(shares);
        
        // Then: Should maintain precision
        assertEq(convertedBack, singleWei, "Single wei precision should be maintained");
        
        // After rebase, should still maintain relative precision
        vm.roll(block.number + BLOCKS_PER_YEAR);
        token.rebase();
        
        uint256 newShares = token.getSharesByAmount(singleWei);
        uint256 newAmount = token.getAmountByShares(newShares);
        assertEq(newAmount, singleWei, "Precision should be maintained after rebase");
    }

    // ===== Owner and Access Control Edge Cases =====

    function test_Owner_RebaseShouldFailForNonOwner() public {
        // Given: Non-owner address
        address attacker = makeAddr("attacker");
        
        // When: Attacker tries to rebase
        vm.roll(block.number + BLOCKS_PER_YEAR);
        
        vm.expectRevert();
        vm.prank(attacker);
        token.rebase();
        
        // Then: Index should remain unchanged
        assertEq(token.index(), INDEX_PRECISION, "Index should not change");
    }

    function test_Owner_OwnerCanRebaseMultipleTimes() public {
        // Given: Owner wants to rebase multiple times
        
        // First rebase
        vm.roll(block.number + BLOCKS_PER_YEAR);
        token.rebase();
        uint256 indexAfterFirst = token.index();
        
        // Second rebase (no time passed)
        token.rebase();
        assertEq(token.index(), indexAfterFirst, "Second immediate rebase should not change index");
        
        // Third rebase (after another year)
        vm.roll(block.number + BLOCKS_PER_YEAR);
        token.rebase();
        
        uint256 expectedIndex = INDEX_PRECISION * 99 / 100 * 99 / 100;
        assertEq(token.index(), expectedIndex, "Third rebase should apply second year deflation");
    }

    // ===== Arithmetic Edge Cases =====

    function test_Arithmetic_ShouldNotOverflowWithLargeTransfers() public {
        // Given: Large transfer amounts
        uint256 largeTransfer = INITIAL_SUPPLY - 1; // Just under full supply
        
        // When: We transfer large amount
        bool success = token.transfer(alice, largeTransfer);
        
        // Then: Should succeed without overflow
        assertTrue(success, "Large transfer should succeed");
        assertEq(token.balanceOf(alice), largeTransfer, "Large transfer should set correct balance");
        assertEq(token.balanceOf(owner), 1, "Owner should have remaining 1 wei");
    }

    function test_Arithmetic_ShouldHandleRoundingConsistency() public {
        // Given: Various amounts that might cause rounding issues
        uint256[] memory trickyAmounts = new uint256[](10);
        trickyAmounts[0] = 999;
        trickyAmounts[1] = 1001;
        trickyAmounts[2] = 123456789;
        trickyAmounts[3] = 10**18 + 1;
        trickyAmounts[4] = 10**18 - 1;
        trickyAmounts[5] = 2**128 - 1;
        trickyAmounts[6] = 2**128 + 1;
        trickyAmounts[7] = 2**192 - 1;
        trickyAmounts[8] = 2**192 + 1;
        trickyAmounts[9] = 2**255 - 1;

        for (uint i = 0; i < trickyAmounts.length; i++) {
            uint256 amount = trickyAmounts[i];
            uint256 shares = token.getSharesByAmount(amount);
            uint256 convertedBack = token.getAmountByShares(shares);
            
            // Allow small rounding errors for very large numbers
            if (amount > 10**30) {
                assertApproxEqAbs(convertedBack, amount, 1000, "Large amount conversion should be within tolerance");
            } else {
                assertEq(convertedBack, amount, "Conversion should be exact for reasonable amounts");
            }
        }
    }

    // ===== State Consistency Tests =====

    function test_State_TotalSupplyShouldAlwaysEqualSumOfBalances() public {
        // Given: Multiple accounts with balances
        token.transfer(alice, 1000 * 10**18);
        token.transfer(bob, 2000 * 10**18);
        token.transfer(charlie, 3000 * 10**18);

        // Calculate expected total
        uint256 expectedTotal = token.balanceOf(owner) + token.balanceOf(alice) + 
                               token.balanceOf(bob) + token.balanceOf(charlie);

        // Then: Total supply should match sum of all balances
        assertEq(token.totalSupply(), expectedTotal, "Total supply should equal sum of all balances");

        // After rebase, should still match
        vm.roll(block.number + BLOCKS_PER_YEAR);
        token.rebase();

        expectedTotal = token.balanceOf(owner) + token.balanceOf(alice) + 
                       token.balanceOf(bob) + token.balanceOf(charlie);
        assertEq(token.totalSupply(), expectedTotal, "Total supply should equal sum after rebase");
    }

    function test_State_ShareProportionsShouldNeverChange() public {
        // Given: Multiple accounts with different balances
        token.transfer(alice, 1000 * 10**18);
        token.transfer(bob, 2000 * 10**18);
        token.transfer(charlie, 3000 * 10**18);

        uint256 aliceShareRatio = (token.sharesOf(alice) * 1e18) / token.totalShares();
        uint256 bobShareRatio = (token.sharesOf(bob) * 1e18) / token.totalShares();
        uint256 charlieShareRatio = (token.sharesOf(charlie) * 1e18) / token.totalShares();

        // After various rebases and transfers
        for (uint i = 1; i <= 5; i++) {
            vm.roll(block.number + (BLOCKS_PER_YEAR * i));
            token.rebase();

            uint256 newAliceRatio = (token.sharesOf(alice) * 1e18) / token.totalShares();
            uint256 newBobRatio = (token.sharesOf(bob) * 1e18) / token.totalShares();
            uint256 newCharlieRatio = (token.sharesOf(charlie) * 1e18) / token.totalShares();

            assertEq(newAliceRatio, aliceShareRatio, "Alice's share ratio should never change");
            assertEq(newBobRatio, bobShareRatio, "Bob's share ratio should never change");
            assertEq(newCharlieRatio, charlieShareRatio, "Charlie's share ratio should never change");
        }
    }
}