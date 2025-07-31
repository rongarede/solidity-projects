// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/RebaseToken.sol";

contract RebaseTokenTest is Test {
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

    // Helper function to advance blocks
    function advanceBlocks(uint256 blocks) public {
        vm.roll(block.number + blocks);
    }

    // Helper function to calculate expected index after rebase
    function calculateExpectedIndex(uint256 yearsElapsed) public pure returns (uint256) {
        return INDEX_PRECISION * (DEFLATION_RATE ** yearsElapsed) / (1e18 ** yearsElapsed);
    }

    // Helper function to check precision
    function assertApproxEqRelCustom(uint256 a, uint256 b, uint256 maxRelError, string memory err) internal {
        if (a == 0 && b == 0) return;
        if (a == 0 || b == 0) {
            assertEq(a, b, err);
            return;
        }
        
        uint256 diff = a > b ? a - b : b - a;
        uint256 relError = diff * 1e18 / (a > b ? a : b);
        
        assertLe(relError, maxRelError, err);
    }

    // Test ERC20 metadata
    function testMetadata() public {
        assertEq(token.name(), "Rebase Token");
        assertEq(token.symbol(), "RBT");
        assertEq(token.decimals(), 18);
    }

    function testInitialSupply() public {
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
    }

    function testInitialShares() public {
        assertEq(token.sharesOf(owner), INITIAL_SUPPLY);
        assertEq(token.totalShares(), INITIAL_SUPPLY);
    }

    function testInitialIndex() public {
        assertEq(token.index(), INDEX_PRECISION);
    }

    // Test shares/amount conversion functions
    function testConversionFunctionsWithInitialIndex() public {
        uint256 amount = 1000 * 10**18;
        uint256 shares = token.getSharesByAmount(amount);
        
        assertEq(shares, amount);
        assertEq(token.getAmountByShares(shares), amount);
    }

    function testConversionAfterRebase() public {
        // Advance 1 year
        advanceBlocks(BLOCKS_PER_YEAR);
        
        // Perform rebase
        vm.prank(owner);
        token.rebase();
        
        uint256 expectedIndex = calculateExpectedIndex(1);
        assertApproxEqRelCustom(token.index(), expectedIndex, 1e15, "Index should be ~0.99");
        
        uint256 amount = 1000 * 10**18;
        uint256 shares = token.getSharesByAmount(amount);
        uint256 expectedShares = amount * INDEX_PRECISION / expectedIndex;
        
        assertApproxEqRelCustom(shares, expectedShares, 1e15, "Shares conversion should be accurate");
        assertEq(token.getAmountByShares(shares), amount);
    }

    function testConversionConsistency() public {
        uint256[] memory testAmounts = new uint256[](4);
        testAmounts[0] = 1 * 10**18;
        testAmounts[1] = 100 * 10**18;
        testAmounts[2] = 10000 * 10**18;
        testAmounts[3] = 1000000 * 10**18;

        for (uint i = 0; i < testAmounts.length; i++) {
            uint256 amount = testAmounts[i];
            uint256 shares = token.getSharesByAmount(amount);
            uint256 convertedBack = token.getAmountByShares(shares);
            assertEq(convertedBack, amount, "Conversion should be consistent");
        }
    }

    function testZeroAmountConversion() public {
        assertEq(token.getSharesByAmount(0), 0);
        assertEq(token.getAmountByShares(0), 0);
    }

    // Test rebase mechanism
    function testRebaseOnceAfterOneYear() public {
        uint256 initialBalance = token.balanceOf(owner);
        uint256 initialShares = token.sharesOf(owner);
        
        // Advance exactly 1 year
        advanceBlocks(BLOCKS_PER_YEAR);
        
        // Perform rebase
        vm.expectEmit(true, true, true, true);
        emit Rebase(1, calculateExpectedIndex(1));
        
        token.rebase();
        
        // Verify rebase results
        assertEq(token.index(), calculateExpectedIndex(1));
        assertEq(token.sharesOf(owner), initialShares); // Shares should remain the same
        
        // Balance should decrease by 1%
        uint256 expectedBalance = initialBalance * 99 / 100;
        assertApproxEqRelCustom(token.balanceOf(owner), expectedBalance, 1e15, "Balance should decrease by 1%");
        
        // Total supply should decrease by 1%
        uint256 expectedTotalSupply = INITIAL_SUPPLY * 99 / 100;
        assertApproxEqRelCustom(token.totalSupply(), expectedTotalSupply, 1e15, "Total supply should decrease by 1%");
    }

    function testMultiYearsInOneCall() public {
        uint256 initialBalance = token.balanceOf(owner);
        uint256 yearsToAdvance = 3;
        
        // Advance 3 years
        advanceBlocks(BLOCKS_PER_YEAR * yearsToAdvance);
        
        // Perform rebase
        vm.expectEmit(true, true, true, true);
        emit Rebase(3, calculateExpectedIndex(3));
        
        token.rebase();
        
        // Verify rebase results
        assertEq(token.index(), calculateExpectedIndex(3));
        
        // Balance should decrease by ~2.97% (0.99^3 = 0.970299)
        uint256 expectedBalance = initialBalance * 970299 / 1000000;
        assertApproxEqRelCustom(token.balanceOf(owner), expectedBalance, 1e15, "Balance should decrease by ~2.97%");
    }

    function testNoRebaseIfNotOneYear() public {
        uint256 initialIndex = token.index();
        
        // Advance less than 1 year
        advanceBlocks(BLOCKS_PER_YEAR - 1);
        
        // Attempt rebase - should not emit event
        vm.recordLogs();
        token.rebase();
        
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0, "No rebase should occur");
        assertEq(token.index(), initialIndex, "Index should remain unchanged");
    }

    function testRebaseOnlyOwner() public {
        advanceBlocks(BLOCKS_PER_YEAR);
        
        // Try to rebase from non-owner address
        vm.prank(alice);
        vm.expectRevert();
        token.rebase();
    }

    function testGetRebaseInfo() public {
        // Initially
        (uint256 currentIndex, uint256 blocksUntilNextRebase, uint256 expectedNextRebaseImpact) = token.getRebaseInfo();
        assertEq(currentIndex, INDEX_PRECISION);
        assertEq(blocksUntilNextRebase, BLOCKS_PER_YEAR);
        assertEq(expectedNextRebaseImpact, INDEX_PRECISION * DEFLATION_RATE / 1e18);
        
        // After advancing half a year
        advanceBlocks(BLOCKS_PER_YEAR / 2);
        (, blocksUntilNextRebase, ) = token.getRebaseInfo();
        assertEq(blocksUntilNextRebase, BLOCKS_PER_YEAR / 2);
        
        // After advancing exactly 1 year
        advanceBlocks(BLOCKS_PER_YEAR);
        (, blocksUntilNextRebase, ) = token.getRebaseInfo();
        assertEq(blocksUntilNextRebase, 0);
    }

    // Test transfer and approval functionality
    function testSimpleTransfer() public {
        uint256 transferAmount = 1000 * 10**18;
        
        vm.expectEmit(true, true, true, true);
        emit Transfer(owner, alice, transferAmount);
        
        bool success = token.transfer(alice, transferAmount);
        assertTrue(success);
        
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
        assertEq(token.balanceOf(alice), transferAmount);
        
        // Shares should be correctly allocated
        assertEq(token.sharesOf(owner), INITIAL_SUPPLY - transferAmount);
        assertEq(token.sharesOf(alice), transferAmount);
    }

    function testTransferBeforeAndAfterRebase() public {
        uint256 transferAmount = 1000 * 10**18;
        
        // Transfer before rebase
        token.transfer(alice, transferAmount);
        assertEq(token.balanceOf(alice), transferAmount);
        
        // Advance 1 year and rebase
        advanceBlocks(BLOCKS_PER_YEAR);
        token.rebase();
        
        // Verify both balances decreased proportionally
        uint256 expectedAliceBalance = transferAmount * 99 / 100;
        assertApproxEqRelCustom(token.balanceOf(alice), expectedAliceBalance, 1e15, "Alice's balance should decrease proportionally");
        
        uint256 expectedOwnerBalance = (INITIAL_SUPPLY - transferAmount) * 99 / 100;
        assertApproxEqRelCustom(token.balanceOf(owner), expectedOwnerBalance, 1e15, "Owner's balance should decrease proportionally");
    }

    function testApproveAndTransferFrom() public {
        uint256 approveAmount = 1000 * 10**18;
        uint256 transferAmount = 500 * 10**18;
        
        vm.expectEmit(true, true, true, true);
        emit Approval(owner, alice, approveAmount);
        
        bool success = token.approve(alice, approveAmount);
        assertTrue(success);
        assertEq(token.allowance(owner, alice), approveAmount);
        
        // TransferFrom by alice
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit Transfer(owner, bob, transferAmount);
        
        success = token.transferFrom(owner, bob, transferAmount);
        assertTrue(success);
        
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
        assertEq(token.balanceOf(bob), transferAmount);
        assertEq(token.allowance(owner, alice), approveAmount - transferAmount);
    }

    function testTransferFromInsufficientAllowance() public {
        uint256 approveAmount = 500 * 10**18;
        uint256 transferAmount = 1000 * 10**18;
        
        token.approve(alice, approveAmount);
        
        vm.prank(alice);
        vm.expectRevert("ERC20: insufficient allowance");
        token.transferFrom(owner, bob, transferAmount);
    }

    function testTransferInsufficientBalance() public {
        uint256 transferAmount = INITIAL_SUPPLY + 1;
        
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        token.transfer(alice, transferAmount);
    }

    function testTransferFromInsufficientBalance() public {
        uint256 approveAmount = type(uint256).max;
        
        token.approve(alice, approveAmount);
        
        vm.prank(alice);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        token.transferFrom(owner, bob, INITIAL_SUPPLY + 1);
    }

    function testApproveMaxAllowance() public {
        token.approve(alice, type(uint256).max);
        
        uint256 transferAmount = INITIAL_SUPPLY;
        vm.prank(alice);
        token.transferFrom(owner, bob, transferAmount);
        
        // Allowance should remain max
        assertEq(token.allowance(owner, alice), type(uint256).max);
    }

    // Test edge cases and boundary conditions
    function testZeroAddressTransfer() public {
        vm.expectRevert("ERC20: transfer to the zero address");
        token.transfer(address(0), 1000 * 10**18);
    }

    function testZeroAddressApprove() public {
        vm.expectRevert("ERC20: approve to the zero address");
        token.approve(address(0), 1000 * 10**18);
    }

    function testZeroAddressTransferFrom() public {
        token.approve(alice, 1000 * 10**18);
        
        vm.prank(alice);
        vm.expectRevert();
        token.transferFrom(address(0), bob, 1000 * 10**18);
    }

    function testZeroTransfer() public {
        bool success = token.transfer(alice, 0);
        assertTrue(success);
        assertEq(token.balanceOf(alice), 0);
        
        vm.expectEmit(true, true, true, true);
        emit Transfer(owner, alice, 0);
        token.transfer(alice, 0);
    }

    function testLargeAmountTransfer() public {
        uint256 largeAmount = INITIAL_SUPPLY / 2;
        
        bool success = token.transfer(alice, largeAmount);
        assertTrue(success);
        assertEq(token.balanceOf(alice), largeAmount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - largeAmount);
    }

    function testMultipleRebases() public {
        uint256 initialBalance = token.balanceOf(owner);
        
        // First rebase after 1 year
        advanceBlocks(BLOCKS_PER_YEAR);
        token.rebase();
        
        uint256 balanceAfterFirst = token.balanceOf(owner);
        assertApproxEqRelCustom(balanceAfterFirst, initialBalance * 99 / 100, 1e15, "First rebase");
        
        // Second rebase after another year
        advanceBlocks(BLOCKS_PER_YEAR);
        token.rebase();
        
        uint256 balanceAfterSecond = token.balanceOf(owner);
        assertApproxEqRelCustom(balanceAfterSecond, initialBalance * 9801 / 10000, 1e15, "Second rebase");
        
        // Verify index progression
        assertEq(token.index(), calculateExpectedIndex(2));
    }

    function testGetRebaseStats() public {
        // Test initial state
        uint256[6] memory stats = token.getRebaseStats();
        assertEq(stats[0], INDEX_PRECISION); // currentIndex
        assertEq(stats[1], BLOCKS_PER_YEAR); // nextRebaseBlocks
        assertEq(stats[2], INDEX_PRECISION * DEFLATION_RATE / 1e18); // nextRebaseIndex
        assertEq(stats[3], INITIAL_SUPPLY); // totalSupply
        assertEq(stats[4], INITIAL_SUPPLY); // totalShares
        assertEq(stats[5], 0); // yearsElapsed

        // Test after advancing half a year
        advanceBlocks(BLOCKS_PER_YEAR / 2);
        stats = token.getRebaseStats();
        assertEq(stats[1], BLOCKS_PER_YEAR / 2); // Should show remaining blocks
        assertEq(stats[5], 0); // Still 0 years elapsed

        // Test after advancing full year
        advanceBlocks(BLOCKS_PER_YEAR);
        stats = token.getRebaseStats();
        assertEq(stats[1], 0); // Rebase is eligible
        assertEq(stats[5], 1); // 1 year elapsed
    }

    function testFractionalYears() public {
        // Advance 1.5 years
        advanceBlocks(BLOCKS_PER_YEAR * 3 / 2);
        
        vm.expectEmit(true, true, true, true);
        emit Rebase(1, calculateExpectedIndex(1));
        
        token.rebase();
        
        // Should only rebase for 1 full year
        assertEq(token.index(), calculateExpectedIndex(1));
    }
}