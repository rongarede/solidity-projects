// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TokenVester.sol";
import "../src/MyToken.sol";

contract IntegrationTest is Test {
    TokenVester public vester;
    MyToken public token;
    address public owner;
    address public alice;
    address public bob;
    address public charlie;
    
    uint256 public constant TOTAL_SUPPLY = 10_000_000 * 10**18;
    uint256 public constant ALICE_VESTING = 1_000_000 * 10**18;
    uint256 public constant BOB_VESTING = 500_000 * 10**18;
    uint256 public constant CHARLIE_VESTING = 2_000_000 * 10**18;

    function setUp() public {
        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        vm.startPrank(owner);
        token = new MyToken("LockCoin", "LOCK", TOTAL_SUPPLY, owner);
        vester = new TokenVester(token, owner);
        
        // Transfer tokens to vester for distribution
        token.transfer(address(vester), ALICE_VESTING + BOB_VESTING + CHARLIE_VESTING);
        vm.stopPrank();
    }

    function testCompleteVestingLifecycle() public {
        uint256 startTime = block.timestamp;
        uint256 aliceDuration = 365 days;
        uint256 bobDuration = 730 days; // 2 years
        uint256 charlieDuration = 180 days; // 6 months

        // Owner creates vesting schedules for all users
        vm.startPrank(owner);
        vester.createVestingSchedule(alice, ALICE_VESTING, startTime, aliceDuration);
        vester.createVestingSchedule(bob, BOB_VESTING, startTime, bobDuration);
        vester.createVestingSchedule(charlie, CHARLIE_VESTING, startTime, charlieDuration);
        vm.stopPrank();

        // Verify initial state
        assertEq(vester.getClaimableAmount(alice), 0);
        assertEq(vester.getClaimableAmount(bob), 0);
        assertEq(vester.getClaimableAmount(charlie), 0);

        // Simulate 90 days passing
        vm.warp(startTime + 90 days);

        // Calculate expected amounts
        uint256 aliceExpected = (ALICE_VESTING * 90 days) / aliceDuration;
        uint256 bobExpected = (BOB_VESTING * 90 days) / bobDuration;
        uint256 charlieExpected = (CHARLIE_VESTING * 90 days) / charlieDuration;

        assertEq(vester.getClaimableAmount(alice), aliceExpected);
        assertEq(vester.getClaimableAmount(bob), bobExpected);
        assertEq(vester.getClaimableAmount(charlie), charlieExpected);

        // Users claim their tokens
        vm.prank(alice);
        vester.claim();
        assertEq(token.balanceOf(alice), aliceExpected);

        vm.prank(bob);
        vester.claim();
        assertEq(token.balanceOf(bob), bobExpected);

        vm.prank(charlie);
        vester.claim();
        assertEq(token.balanceOf(charlie), charlieExpected);

        // Simulate Charlie's vesting period completion (180 days)
        vm.warp(startTime + 180 days);

        // Charlie should be able to claim all remaining tokens
        uint256 charlieRemaining = CHARLIE_VESTING - charlieExpected;
        assertEq(vester.getClaimableAmount(charlie), charlieRemaining);

        vm.prank(charlie);
        vester.claim();
        assertEq(token.balanceOf(charlie), CHARLIE_VESTING);

        // Alice and Bob should have more tokens available
        uint256 aliceExpected180 = (ALICE_VESTING * 180 days) / aliceDuration - aliceExpected;
        uint256 bobExpected180 = (BOB_VESTING * 180 days) / bobDuration - bobExpected;

        assertEq(vester.getClaimableAmount(alice), aliceExpected180);
        assertEq(vester.getClaimableAmount(bob), bobExpected180);

        // Simulate Alice's vesting completion (365 days)
        vm.warp(startTime + 365 days);

        vm.prank(alice);
        vester.claim();
        assertEq(token.balanceOf(alice), ALICE_VESTING);

        // Bob still has tokens vesting
        uint256 bobExpected365 = (BOB_VESTING * 365 days) / bobDuration - bobExpected;
        assertEq(vester.getClaimableAmount(bob), bobExpected365);

        // Simulate Bob's vesting completion (730 days)
        vm.warp(startTime + 730 days);

        vm.prank(bob);
        vester.claim();
        assertEq(token.balanceOf(bob), BOB_VESTING);

        // Verify all tokens have been distributed correctly
        assertEq(token.balanceOf(alice), ALICE_VESTING);
        assertEq(token.balanceOf(bob), BOB_VESTING);
        assertEq(token.balanceOf(charlie), CHARLIE_VESTING);
    }

    function testPartialRevocationScenario() public {
        uint256 startTime = block.timestamp;
        uint256 duration = 365 days;

        vm.startPrank(owner);
        vester.createVestingSchedule(alice, ALICE_VESTING, startTime, duration);
        vester.createVestingSchedule(bob, BOB_VESTING, startTime, duration);
        vm.stopPrank();

        // Simulate 6 months
        vm.warp(startTime + 182 days);

        // Alice claims her tokens
        uint256 aliceClaimable = vester.getClaimableAmount(alice);
        vm.prank(alice);
        vester.claim();
        assertEq(token.balanceOf(alice), aliceClaimable);

        // Owner revokes Bob's vesting
        uint256 ownerBalanceBefore = token.balanceOf(owner);
        uint256 bobClaimable = vester.getClaimableAmount(bob);
        uint256 bobUnvested = BOB_VESTING - bobClaimable;

        vm.prank(owner);
        vester.revokeVesting(bob);

        // Verify Bob received his vested tokens
        assertEq(token.balanceOf(bob), bobClaimable);
        
        // Verify owner received the unvested tokens
        assertEq(token.balanceOf(owner), ownerBalanceBefore + bobUnvested);

        // Verify Bob can't claim anymore
        vm.prank(bob);
        vm.expectRevert(TokenVester.VestingAlreadyRevoked.selector);
        vester.claim();

        // Alice should still be able to claim
        vm.warp(startTime + 365 days);
        uint256 aliceRemaining = ALICE_VESTING - aliceClaimable;
        assertEq(vester.getClaimableAmount(alice), aliceRemaining);

        vm.prank(alice);
        vester.claim();
        assertEq(token.balanceOf(alice), ALICE_VESTING);
    }

    function testGasOptimizationScenario() public {
        uint256 startTime = block.timestamp;
        uint256 duration = 365 days;

        // Create vesting schedules
        vm.startPrank(owner);
        vester.createVestingSchedule(alice, ALICE_VESTING, startTime, duration);
        vester.createVestingSchedule(bob, BOB_VESTING, startTime, duration);
        vester.createVestingSchedule(charlie, CHARLIE_VESTING, startTime, duration);
        vm.stopPrank();

        vm.warp(startTime + 100 days);

        // Measure gas for individual claims
        vm.prank(alice);
        uint256 gasBefore = gasleft();
        vester.claim();
        uint256 gasUsedAlice = gasBefore - gasleft();

        vm.prank(bob);
        gasBefore = gasleft();
        vester.claim();
        uint256 gasUsedBob = gasBefore - gasleft();

        vm.prank(charlie);
        gasBefore = gasleft();
        vester.claim();
        uint256 gasUsedCharlie = gasBefore - gasleft();

        // Gas usage should be relatively consistent
        assertTrue(gasUsedAlice > 0);
        assertTrue(gasUsedBob > 0);
        assertTrue(gasUsedCharlie > 0);

        // Log gas usage for analysis
        emit log_named_uint("Alice claim gas", gasUsedAlice);
        emit log_named_uint("Bob claim gas", gasUsedBob);
        emit log_named_uint("Charlie claim gas", gasUsedCharlie);
    }

    function testPrecisionAndRoundingEdgeCases() public {
        uint256 startTime = block.timestamp;
        uint256 duration = 7 days;
        uint256 vestingAmount = 1000; // Small amount to test precision

        vm.prank(owner);
        token.mint(address(vester), vestingAmount);

        vm.prank(owner);
        vester.createVestingSchedule(alice, vestingAmount, startTime, duration);

        // Test daily claims for precision loss
        uint256 totalClaimed = 0;
        for (uint256 day = 1; day <= 7; day++) {
            vm.warp(startTime + day * 1 days);
            
            uint256 claimable = vester.getClaimableAmount(alice);
            if (claimable > 0) {
                vm.prank(alice);
                vester.claim();
                totalClaimed += claimable;
            }
        }

        // Should claim close to the total amount (allowing for minor precision loss)
        assertGe(totalClaimed, vestingAmount - 7); // Allow up to 7 wei loss
        assertLe(totalClaimed, vestingAmount);

        emit log_named_uint("Total vesting amount", vestingAmount);
        emit log_named_uint("Total claimed", totalClaimed);
        emit log_named_uint("Precision loss", vestingAmount - totalClaimed);
    }

    function testExcessTokenWithdrawal() public {
        uint256 startTime = block.timestamp;
        uint256 duration = 365 days;

        // Add extra tokens to test withdrawal
        uint256 excessAmount = 1_000_000 * 10**18;
        vm.prank(owner);
        token.mint(address(vester), excessAmount);

        vm.prank(owner);
        vester.createVestingSchedule(alice, ALICE_VESTING, startTime, duration);

        uint256 vesterBalanceBefore = token.balanceOf(address(vester));
        uint256 ownerBalanceBefore = token.balanceOf(owner);

        // Owner withdraws excess tokens
        vm.prank(owner);
        vester.withdrawExcessTokens(excessAmount);

        assertEq(token.balanceOf(address(vester)), vesterBalanceBefore - excessAmount);
        assertEq(token.balanceOf(owner), ownerBalanceBefore + excessAmount);

        // Alice should still be able to claim normally
        vm.warp(startTime + 182 days);
        uint256 aliceClaimable = vester.getClaimableAmount(alice);

        vm.prank(alice);
        vester.claim();
        assertEq(token.balanceOf(alice), aliceClaimable);
    }

    function testOwnershipTransferScenario() public {
        address newOwner = makeAddr("newOwner");
        uint256 startTime = block.timestamp;
        uint256 duration = 365 days;

        // Create vesting schedule
        vm.prank(owner);
        vester.createVestingSchedule(alice, ALICE_VESTING, startTime, duration);

        // Transfer ownership
        vm.prank(owner);
        vester.transferOwnership(newOwner);

        assertEq(vester.owner(), newOwner);

        // New owner should be able to create vesting schedules
        vm.prank(newOwner);
        vester.createVestingSchedule(bob, BOB_VESTING, startTime, duration);

        // Old owner should not be able to create vesting schedules
        vm.prank(owner);
        vm.expectRevert();
        vester.createVestingSchedule(charlie, CHARLIE_VESTING, startTime, duration);

        // Existing vesting should continue to work
        vm.warp(startTime + 182 days);
        
        vm.prank(alice);
        vester.claim();
        
        vm.prank(bob);
        vester.claim();
        
        assertTrue(token.balanceOf(alice) > 0);
        assertTrue(token.balanceOf(bob) > 0);
    }
}