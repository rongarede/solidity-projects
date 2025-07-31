// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/RebaseToken.sol";

contract RebaseTokenGasTest is Test {
    RebaseToken public token;
    address public owner = address(this);
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    uint256 constant INITIAL_SUPPLY = 100_000_000 * 10**18;
    uint256 constant BLOCKS_PER_YEAR = 15_768_000;

    function setUp() public {
        token = new RebaseToken("Rebase Token", "RBT", 18);
    }

    // ===== Gas Usage Benchmarks =====

    function test_Gas_TransferBasic() public {
        // Given: Basic transfer
        uint256 transferAmount = 1000 * 10**18;

        // Measure gas for basic transfer
        uint256 gasStart = gasleft();
        token.transfer(alice, transferAmount);
        uint256 gasUsed = gasStart - gasleft();

        // Log for reference (these are approximate expectations)
        assertLt(gasUsed, 60000, "Basic transfer should be efficient");
    }

    function test_Gas_TransferAfterRebase() public {
        // Given: Post-rebase transfer
        vm.roll(block.number + BLOCKS_PER_YEAR);
        token.rebase();

        uint256 transferAmount = 1000 * 10**18;

        // Measure gas after rebase
        uint256 gasStart = gasleft();
        token.transfer(alice, transferAmount);
        uint256 gasUsed = gasStart - gasleft();

        assertLt(gasUsed, 60000, "Post-rebase transfer should be efficient");
    }

    function test_Gas_RebaseSingleYear() public {
        // Given: One year has passed
        vm.roll(block.number + BLOCKS_PER_YEAR);

        // Measure gas for single year rebase
        uint256 gasStart = gasleft();
        token.rebase();
        uint256 gasUsed = gasStart - gasleft();

        assertLt(gasUsed, 50000, "Single year rebase should be efficient");
    }

    function test_Gas_RebaseMultipleYears() public {
        // Given: Multiple years have passed
        uint256 numYears = 10;
        vm.roll(block.number + (BLOCKS_PER_YEAR * numYears));

        // Measure gas for multiple years rebase
        uint256 gasStart = gasleft();
        token.rebase();
        uint256 gasUsed = gasStart - gasleft();

        assertLt(gasUsed, 50000, "Multiple year rebase should be efficient");
    }

    function test_Gas_RebaseWithManyHolders() public {
        // Given: Many holders with balances
        address[] memory holders = new address[](100);
        for (uint i = 0; i < holders.length; i++) {
            holders[i] = makeAddr(string(abi.encodePacked("holder", vm.toString(i))));
            token.transfer(holders[i], 1000 * 10**18);
        }

        // When: Rebase with many holders
        vm.roll(block.number + BLOCKS_PER_YEAR);
        
        uint256 gasStart = gasleft();
        token.rebase();
        uint256 gasUsed = gasStart - gasleft();

        assertLt(gasUsed, 50000, "Rebase should be stateless and efficient");
    }

    // ===== Batch Operations Optimization =====

    function test_Gas_BatchTransfers() public {
        // Given: Multiple transfers in sequence
        address[] memory recipients = new address[](10);
        uint256[] memory amounts = new uint256[](10);
        
        for (uint i = 0; i < 10; i++) {
            recipients[i] = makeAddr(string(abi.encodePacked("recipient", vm.toString(i))));
            amounts[i] = 100 * 10**18;
        }

        // Measure total gas for batch transfers
        uint256 totalGas = 0;
        for (uint i = 0; i < 10; i++) {
            uint256 gasStart = gasleft();
            token.transfer(recipients[i], amounts[i]);
            totalGas += (gasStart - gasleft());
        }

        uint256 avgGasPerTransfer = totalGas / 10;
        assertLt(avgGasPerTransfer, 60000, "Average transfer should be efficient");
    }

    function test_Gas_ApprovalAndTransferFrom() public {
        // Given: Approval and transferFrom flow
        uint256 approveAmount = 1000 * 10**18;
        uint256 transferAmount = 500 * 10**18;

        // Measure approval gas
        uint256 gasStart = gasleft();
        token.approve(alice, approveAmount);
        uint256 approvalGas = gasStart - gasleft();

        // Measure transferFrom gas
        vm.prank(alice);
        gasStart = gasleft();
        token.transferFrom(owner, bob, transferAmount);
        uint256 transferFromGas = gasStart - gasleft();

        
        assertLt(approvalGas, 50000, "Approval should be efficient");
        assertLt(transferFromGas, 70000, "TransferFrom should be efficient");
    }

    // ===== Conversion Functions Gas Usage =====

    function test_Gas_ShareConversion() public {
        // Given: Various amount conversions
        uint256 testAmount = 1000 * 10**18;

        // Measure shares by amount conversion
        uint256 gasStart = gasleft();
        uint256 shares = token.getSharesByAmount(testAmount);
        uint256 sharesGas = gasStart - gasleft();

        // Measure amount by shares conversion
        gasStart = gasleft();
        uint256 amount = token.getAmountByShares(shares);
        uint256 amountGas = gasStart - gasleft();

        
        assertLt(sharesGas, 30000, "Share conversion should be efficient");
        assertLt(amountGas, 30000, "Amount conversion should be efficient");
    }

    function test_Gas_ViewFunctions() public {
        // Given: Various view function calls
        
        // Measure balanceOf gas
        uint256 gasStart = gasleft();
        uint256 balance = token.balanceOf(alice);
        uint256 balanceGas = gasStart - gasleft();

        // Measure totalSupply gas
        gasStart = gasleft();
        uint256 total = token.totalSupply();
        uint256 totalGas = gasStart - gasleft();

        // Measure getRebaseInfo gas
        gasStart = gasleft();
        (uint256 index, uint256 blocksLeft, uint256 nextIndex) = token.getRebaseInfo();
        uint256 infoGas = gasStart - gasleft();

        // Measure getRebaseStats gas
        gasStart = gasleft();
        uint256[6] memory stats = token.getRebaseStats();
        uint256 statsGas = gasStart - gasleft();

        
        assertLt(balanceGas, 20000, "BalanceOf should be very efficient");
        assertLt(totalGas, 20000, "TotalSupply should be very efficient");
        assertLt(infoGas, 30000, "GetRebaseInfo should be efficient");
        assertLt(statsGas, 30000, "GetRebaseStats should be efficient");
    }

    // ===== Gas Optimization Scenarios =====

    function test_Gas_ContractDeployment() public {
        // Measure deployment gas
        uint256 gasStart = gasleft();
        RebaseToken newToken = new RebaseToken("Gas Test", "GT", 18);
        uint256 deployGas = gasStart - gasleft();

        assertLt(deployGas, 3_000_000, "Deployment should be reasonably efficient");
    }

    function test_Gas_RebaseWithNoEligibleYears() public {
        // Given: Less than a year has passed
        vm.roll(block.number + BLOCKS_PER_YEAR - 1);

        // Measure gas for no-op rebase
        uint256 gasStart = gasleft();
        token.rebase();
        uint256 noOpGas = gasStart - gasleft();

        assertLt(noOpGas, 50000, "No-op rebase should be very efficient");
    }

    function test_Gas_RepeatedOperations() public {
        // Given: Multiple identical operations
        
        // First operation baseline
        uint256 gasStart = gasleft();
        token.transfer(alice, 100 * 10**18);
        uint256 firstGas = gasStart - gasleft();

        // Second operation (should be similar)
        gasStart = gasleft();
        token.transfer(bob, 100 * 10**18);
        uint256 secondGas = gasStart - gasleft();

        // Third operation (should be similar)
        gasStart = gasleft();
        token.transfer(charlie, 100 * 10**18);
        uint256 thirdGas = gasStart - gasleft();

        
        // Gas should be consistent
        assertApproxEqAbs(firstGas, secondGas, 1000, "Gas should be consistent between similar operations");
        assertApproxEqAbs(secondGas, thirdGas, 1000, "Gas should be consistent between similar operations");
    }

    // ===== Storage Access Patterns =====

    function test_Gas_CacheFriendlyAccess() public {
        // Given: Multiple reads from same storage slot
        
        // Measure multiple reads (should be cached)
        uint256 gasStart = gasleft();
        uint256 val1 = token.balanceOf(alice);
        uint256 val2 = token.balanceOf(alice);
        uint256 val3 = token.balanceOf(alice);
        uint256 cachedReads = gasStart - gasleft();

        // Measure single read for comparison
        gasStart = gasleft();
        uint256 singleRead = token.balanceOf(alice);
        uint256 singleReadGas = gasStart - gasleft();

        
        // Multiple reads should not be significantly more expensive
        assertLt(cachedReads, singleReadGas * 3, "Cached reads should be efficient");
    }

    // ===== Gas Regression Tests =====

    function test_Gas_RegressionBaseline() public {
        // This test establishes baseline gas usage for common operations
        // Add more operations as needed for regression testing
        
        uint256[] memory baselines = new uint256[](5);
        
        // Transfer baseline
        uint256 gasStart = gasleft();
        token.transfer(alice, 1000 * 10**18);
        baselines[0] = gasStart - gasleft();
        
        // Approval baseline
        gasStart = gasleft();
        token.approve(bob, 1000 * 10**18);
        baselines[1] = gasStart - gasleft();
        
        // Rebase baseline
        vm.roll(block.number + BLOCKS_PER_YEAR);
        gasStart = gasleft();
        token.rebase();
        baselines[2] = gasStart - gasleft();
        
        // Balance query baseline
        gasStart = gasleft();
        uint256 balance = token.balanceOf(alice);
        baselines[3] = gasStart - gasleft();
        
        // Share conversion baseline
        gasStart = gasleft();
        uint256 shares = token.getSharesByAmount(1000 * 10**18);
        baselines[4] = gasStart - gasleft();
        
    }
}