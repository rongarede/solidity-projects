// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/RebaseToken.sol";

contract RebaseTokenIntegrationTest is Test {
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

    // ===== DeFi Integration Scenarios =====

    function test_Integration_LiquidityPoolBehavior() public {
        // Given: A simple liquidity pool setup
        address liquidityPool = makeAddr("liquidityPool");
        
        // Simulate adding liquidity
        uint256 liquidityAmount = 10000 * 10**18;
        token.transfer(liquidityPool, liquidityAmount);
        
        uint256 poolBalanceBefore = token.balanceOf(liquidityPool);
        uint256 aliceBalanceBefore = token.balanceOf(alice);
        
        // When: Year passes and rebase occurs
        vm.roll(block.number + BLOCKS_PER_YEAR);
        token.rebase();
        
        // Then: Pool and user balances should scale proportionally
        uint256 poolBalanceAfter = token.balanceOf(liquidityPool);
        uint256 aliceBalanceAfter = token.balanceOf(alice);
        
        assertApproxEqRel(poolBalanceAfter, poolBalanceBefore * 99 / 100, 0.001e18, "Pool balance should scale correctly");
        assertEq(aliceBalanceAfter, aliceBalanceBefore, "Alice's balance should remain 0");
        
        // Users can still interact with the pool
        token.transfer(alice, 1000 * 10**18);
        vm.prank(alice);
        token.transfer(liquidityPool, 100 * 10**18);
        
        assertEq(token.balanceOf(liquidityPool), poolBalanceAfter + 100 * 10**18, "Pool interaction should work normally");
    }

    function test_Integration_YieldFarmingScenario() public {
        // Given: A yield farming contract
        address yieldFarm = makeAddr("yieldFarm");
        
        // Simulate yield farming deposits
        token.transfer(alice, 5000 * 10**18);
        token.transfer(bob, 3000 * 10**18);
        
        vm.prank(alice);
        token.transfer(yieldFarm, 5000 * 10**18);
        
        vm.prank(bob);
        token.transfer(yieldFarm, 3000 * 10**18);
        
        uint256 farmBalanceBefore = token.balanceOf(yieldFarm);
        uint256 aliceShareBefore = 5000 * 10**18;
        uint256 bobShareBefore = 3000 * 10**18;
        
        // When: Time passes and rebase occurs
        vm.roll(block.number + (BLOCKS_PER_YEAR * 2)); // 2 years
        token.rebase();
        
        // Then: All balances should scale proportionally
        uint256 farmBalanceAfter = token.balanceOf(yieldFarm);
        
        assertApproxEqRel(farmBalanceAfter, farmBalanceBefore * 9801 / 10000, 0.001e18, "Farm balance should scale correctly");
        
        // Users can withdraw their proportional shares
        uint256 aliceWithdraw = (farmBalanceAfter * 5) / 8; // Alice had 5/8 of deposits
        uint256 bobWithdraw = (farmBalanceAfter * 3) / 8;   // Bob had 3/8 of deposits
        
        assertApproxEqRel(aliceWithdraw + bobWithdraw, farmBalanceAfter, 0.001e18, "Withdrawals should sum to total");
    }

    function test_Integration_StakingContractInteraction() public {
        // Given: A staking contract
        address stakingContract = makeAddr("stakingContract");
        
        // Simulate staking
        uint256 stakeAmount = 10000 * 10**18;
        token.transfer(stakingContract, stakeAmount);
        
        // Track initial state
        uint256 stakingBalanceBefore = token.balanceOf(stakingContract);
        uint256 totalSupplyBefore = token.totalSupply();
        
        // When: Multiple rebases occur over time
        for (uint year = 1; year <= 5; year++) {
            vm.roll(block.number + BLOCKS_PER_YEAR);
            token.rebase();
            
            uint256 expectedBalance = stakeAmount * (99**year) / (100**year);
            assertApproxEqRel(token.balanceOf(stakingContract), expectedBalance, 0.001e18, 
                string(abi.encodePacked("Year ", vm.toString(year), " staking balance incorrect")));
        }
        
        // Staking rewards should be calculated based on shares
        uint256 shares = token.sharesOf(stakingContract);
        assertEq(shares, stakeAmount, "Shares should remain constant");
    }

    // ===== Multi-User Complex Scenarios =====

    function test_Integration_ExchangeOrderBookBehavior() public {
        // Given: Exchange-like behavior with multiple users
        address[] memory users = new address[](10);
        uint256[] memory balances = new uint256[](10);
        
        // Create users with different balances
        for (uint i = 0; i < users.length; i++) {
            users[i] = makeAddr(string(abi.encodePacked("user", vm.toString(i))));
            balances[i] = (i + 1) * 1000 * 10**18;
            token.transfer(users[i], balances[i]);
        }
        
        // When: Market operations and rebase occur
        // Simulate trading activity
        vm.prank(users[0]);
        token.transfer(users[1], 100 * 10**18);
        
        vm.prank(users[2]);
        token.transfer(users[3], 200 * 10**18);
        
        // Rebase occurs
        vm.roll(block.number + BLOCKS_PER_YEAR);
        token.rebase();
        
        // Then: All user balances should scale correctly
        uint256 totalBefore = 0;
        uint256 totalAfter = 0;
        
        for (uint i = 0; i < users.length; i++) {
            uint256 expectedBalance = balances[i] * 99 / 100;
            if (i == 0) expectedBalance -= 100 * 10**18 * 99 / 100;
            if (i == 1) expectedBalance += 100 * 10**18 * 99 / 100;
            if (i == 2) expectedBalance -= 200 * 10**18 * 99 / 100;
            if (i == 3) expectedBalance += 200 * 10**18 * 99 / 100;
            
            assertApproxEqRel(token.balanceOf(users[i]), expectedBalance, 0.001e18, 
                string(abi.encodePacked("User ", vm.toString(i), " balance incorrect")));
            
            totalBefore += balances[i];
            totalAfter += token.balanceOf(users[i]);
        }
        
        assertEq(token.totalSupply(), totalAfter, "Total supply should match sum");
        assertApproxEqRel(totalAfter, totalBefore * 99 / 100, 0.001e18, "Total should scale correctly");
    }

    function test_Integration_DAOGovernanceScenario() public {
        // Given: DAO governance with voting power based on token balance
        address[] memory members = new address[](5);
        uint256[] memory votingPower = new uint256[](5);
        
        // Initialize DAO members
        for (uint i = 0; i < members.length; i++) {
            members[i] = makeAddr(string(abi.encodePacked("member", vm.toString(i))));
            votingPower[i] = (i + 1) * 10000 * 10**18;
            token.transfer(members[i], votingPower[i]);
        }
        
        // When: Governance decisions over time
        uint256[] memory initialVotingPower = new uint256[](5);
        for (uint i = 0; i < members.length; i++) {
            initialVotingPower[i] = token.balanceOf(members[i]);
        }
        
        // Simulate 3 years of governance
        for (uint year = 1; year <= 3; year++) {
            vm.roll(block.number + BLOCKS_PER_YEAR);
            token.rebase();
            
            // Verify voting power scales proportionally
            for (uint i = 0; i < members.length; i++) {
                uint256 expectedPower = initialVotingPower[i] * (99**year) / (100**year);
                assertApproxEqRel(token.balanceOf(members[i]), expectedPower, 0.001e18, 
                    string(abi.encodePacked("Member ", vm.toString(i), " voting power year ", vm.toString(year))));
            }
        }
    }

    // ===== DeFi Protocol Interactions =====

    function test_Integration_AirdropDistribution() public {
        // Given: Airdrop to many addresses
        address[] memory recipients = new address[](100);
        uint256 airdropAmount = 100 * 10**18;
        
        // Setup recipients
        for (uint i = 0; i < recipients.length; i++) {
            recipients[i] = makeAddr(string(abi.encodePacked("airdrop", vm.toString(i))));
        }
        
        // Perform airdrop
        for (uint i = 0; i < recipients.length; i++) {
            token.transfer(recipients[i], airdropAmount);
            assertEq(token.balanceOf(recipients[i]), airdropAmount, "Airdrop should work correctly");
        }
        
        // When: Rebase occurs
        vm.roll(block.number + BLOCKS_PER_YEAR);
        token.rebase();
        
        // Then: All airdrops should scale correctly
        uint256 expectedAmount = airdropAmount * 99 / 100;
        for (uint i = 0; i < recipients.length; i++) {
            assertEq(token.balanceOf(recipients[i]), expectedAmount, "Airdrop amounts should scale");
        }
    }

    function test_Integration_MerchantPaymentSystem() public {
        // Given: E-commerce payment scenario
        address merchant = makeAddr("merchant");
        address customer = makeAddr("customer");
        address paymentProcessor = makeAddr("paymentProcessor");
        
        // Customer gets tokens
        uint256 purchaseAmount = 500 * 10**18;
        token.transfer(customer, 1000 * 10**18);
        
        // Payment flow
        vm.prank(customer);
        token.approve(paymentProcessor, purchaseAmount);
        
        vm.prank(paymentProcessor);
        token.transferFrom(customer, merchant, purchaseAmount);
        
        // Verify initial state
        assertEq(token.balanceOf(customer), 500 * 10**18, "Customer should have remaining balance");
        assertEq(token.balanceOf(merchant), 500 * 10**18, "Merchant should receive payment");
        
        // When: Time passes and rebase occurs
        vm.roll(block.number + BLOCKS_PER_YEAR);
        token.rebase();
        
        // Then: Both balances should scale correctly
        assertEq(token.balanceOf(customer), 500 * 10**18 * 99 / 100, "Customer balance should scale");
        assertEq(token.balanceOf(merchant), 500 * 10**18 * 99 / 100, "Merchant balance should scale");
    }

    // ===== Multi-Year Portfolio Tracking =====

    function test_Integration_PortfolioTracking() public {
        // Given: Investment portfolio scenario
        address investor = makeAddr("investor");
        address[] memory assets = new address[](3);
        uint256[] memory amounts = new uint256[](3);
        
        // Setup portfolio
        amounts[0] = 5000 * 10**18; // Large holding
        amounts[1] = 3000 * 10**18; // Medium holding
        amounts[2] = 2000 * 10**18; // Small holding
        
        for (uint i = 0; i < 3; i++) {
            assets[i] = makeAddr(string(abi.encodePacked("asset", vm.toString(i))));
            token.transfer(assets[i], amounts[i]);
        }
        
        // Track portfolio over 10 years
        uint256[] memory initialAmounts = new uint256[](3);
        for (uint i = 0; i < 3; i++) {
            initialAmounts[i] = token.balanceOf(assets[i]);
        }
        
        for (uint year = 1; year <= 10; year++) {
            vm.roll(block.number + BLOCKS_PER_YEAR);
            token.rebase();
            
            // Verify portfolio value
            uint256 totalValue = 0;
            for (uint i = 0; i < 3; i++) {
                uint256 expectedValue = initialAmounts[i] * (99**year) / (100**year);
                assertApproxEqRel(token.balanceOf(assets[i]), expectedValue, 0.001e18);
                totalValue += token.balanceOf(assets[i]);
            }
            
            uint256 expectedTotal = (amounts[0] + amounts[1] + amounts[2]) * (99**year) / (100**year);
            assertApproxEqRel(totalValue, expectedTotal, 0.001e18, "Total portfolio value should scale correctly");
        }
    }

    // ===== Cross-Contract Interactions =====

    function test_Integration_TreasuryManagement() public {
        // Given: Treasury with multiple allocations
        address treasury = makeAddr("treasury");
        address operationalFund = makeAddr("operationalFund");
        address developmentFund = makeAddr("developmentFund");
        address reserveFund = makeAddr("reserveFund");
        
        uint256 treasuryAmount = 50000 * 10**18;
        token.transfer(treasury, treasuryAmount);
        
        // Treasury allocates funds
        vm.prank(treasury);
        token.transfer(operationalFund, treasuryAmount * 40 / 100);
        
        vm.prank(treasury);
        token.transfer(developmentFund, treasuryAmount * 30 / 100);
        
        vm.prank(treasury);
        token.transfer(reserveFund, treasuryAmount * 30 / 100);
        
        // Track allocations over time
        uint256[] memory fundAmounts = new uint256[](4);
        fundAmounts[0] = token.balanceOf(treasury);
        fundAmounts[1] = token.balanceOf(operationalFund);
        fundAmounts[2] = token.balanceOf(developmentFund);
        fundAmounts[3] = token.balanceOf(reserveFund);
        
        // Simulate 5 years of treasury management
        for (uint year = 1; year <= 5; year++) {
            vm.roll(block.number + BLOCKS_PER_YEAR);
            token.rebase();
            
            uint256 totalFunds = 0;
            for (uint i = 0; i < 4; i++) {
                uint256 expectedAmount = fundAmounts[i] * (99**year) / (100**year);
                address[] memory addresses = new address[](4);
                addresses[0] = treasury;
                addresses[1] = operationalFund;
                addresses[2] = developmentFund;
                addresses[3] = reserveFund;
                
                assertApproxEqRel(token.balanceOf(addresses[i]), expectedAmount, 0.001e18);
                totalFunds += token.balanceOf(addresses[i]);
            }
            
            assertEq(totalFunds, token.totalSupply() - token.balanceOf(owner), "All funds should be accounted for");
        }
    }

    // ===== Stress Testing =====

    function test_Integration_MassiveUserBase() public {
        // Given: Large number of users (simulate 1000 users)
        address[] memory users = new address[](50); // Reduced for testing efficiency
        uint256 baseAmount = 1000 * 10**18;
        
        // Create diverse user base
        for (uint i = 0; i < users.length; i++) {
            users[i] = makeAddr(string(abi.encodePacked("user", vm.toString(i))));
            uint256 amount = baseAmount * (i + 1) / 10; // Different amounts
            token.transfer(users[i], amount);
        }
        
        // Verify initial state
        uint256 totalDistributed = 0;
        for (uint i = 0; i < users.length; i++) {
            totalDistributed += token.balanceOf(users[i]);
        }
        
        // When: Rebase occurs
        vm.roll(block.number + BLOCKS_PER_YEAR);
        token.rebase();
        
        // Then: All users should scale correctly
        uint256 totalAfter = 0;
        for (uint i = 0; i < users.length; i++) {
            uint256 expectedAmount = baseAmount * (i + 1) * 99 / 1000;
            assertApproxEqRel(token.balanceOf(users[i]), expectedAmount, 0.001e18);
            totalAfter += token.balanceOf(users[i]);
        }
        
        assertApproxEqRel(totalAfter, totalDistributed * 99 / 100, 0.001e18, "Total should scale correctly");
    }
}