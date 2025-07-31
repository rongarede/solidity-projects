// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {MockWETH} from "../src/MockWETH.sol";
import {KKToken} from "../src/KKToken.sol";
import {StakingPool} from "../src/StakingPool.sol";

/**
 * @title Demo
 * @dev Demonstration script showing complete user interaction flow
 * Simulates real user behavior with the StakingPool system
 */
contract Demo is Script {
    // Contract instances (will be loaded from deployment)
    MockWETH public weth;
    KKToken public kkToken;
    StakingPool public stakingPool;
    
    // Demo users
    address public user1;
    address public user2;
    address public admin;
    
    function setUp() public {
        // Load contract addresses from environment variables or deployments.txt
        address wethAddress = vm.envOr("WETH_ADDRESS", address(0));
        address kkTokenAddress = vm.envOr("KKTOKEN_ADDRESS", address(0));
        address payable stakingPoolAddress = payable(vm.envOr("STAKINGPOOL_ADDRESS", address(0)));
        
        // If not provided via env, try to read from file or use default local addresses
        if (wethAddress == address(0)) {
            // For demo purposes, we'll deploy locally if addresses not provided
            console2.log("Deploying contracts locally for demo...");
            deployLocally();
        } else {
            weth = MockWETH(payable(wethAddress));
            kkToken = KKToken(kkTokenAddress);
            stakingPool = StakingPool(stakingPoolAddress);
        }
        
        // Set up demo users
        user1 = makeAddr("DemoUser1");
        user2 = makeAddr("DemoUser2");
        admin = vm.envOr("ADMIN_ADDRESS", makeAddr("admin"));
        
        // Give demo users some ETH
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        
        console2.log("Demo setup complete");
        console2.log("User1:", user1, "Balance:", user1.balance);
        console2.log("User2:", user2, "Balance:", user2.balance);
    }
    
    function deployLocally() internal {
        weth = new MockWETH();
        address adminAddr = makeAddr("admin");
        kkToken = new KKToken(adminAddr);
        stakingPool = new StakingPool(payable(address(weth)), address(kkToken), adminAddr);
        
        // Setup permissions
        vm.prank(adminAddr);
        kkToken.grantMinterRole(address(stakingPool));
        
        // Update admin reference for demo
        admin = adminAddr;
    }

    function run() public {
        console2.log("\n=== STAKINGPOOL DEMO STARTING ===");
        console2.log("Contract Addresses:");
        console2.log("MockWETH:    ", address(weth));
        console2.log("KKToken:     ", address(kkToken));
        console2.log("StakingPool: ", address(stakingPool));
        
        // Run the complete demo flow
        demoStep1_InitialStaking();
        demoStep2_CheckRewards();
        demoStep3_SecondUserJoins();
        demoStep4_HarvestRewards();
        demoStep5_PartialUnstake();
        demoStep6_EmergencyScenario();
        demoStep7_AdminFunctions();
        demoStep8_FinalStatus();
        
        console2.log("\n=== DEMO COMPLETED SUCCESSFULLY ===");
    }
    
    function demoStep1_InitialStaking() internal {
        console2.log("\nStep 1: Initial Staking");
        console2.log("User1 stakes 2 ETH via stakeETH()");
        
        vm.prank(user1);
        stakingPool.stakeETH{value: 2 ether}();
        
        // Check staking status
        (uint256 amount, uint256 rewardDebt) = stakingPool.userInfo(user1);
        console2.log("User1 staked amount:", amount / 1e18, "ETH");
        console2.log("Total staked in pool:", stakingPool.totalStaked() / 1e18, "ETH");
        console2.log("WETH in pool:", weth.balanceOf(address(stakingPool)) / 1e18, "WETH");
    }
    
    function demoStep2_CheckRewards() internal {
        console2.log("\nStep 2: Simulating Time Passage (10 blocks)");
        
        uint256 initialBlock = block.number;
        vm.roll(block.number + 10);
        
        uint256 pendingRewards = stakingPool.pendingKK(user1);
        console2.log("Blocks passed:", block.number - initialBlock);
        console2.log("User1 pending rewards:", pendingRewards / 1e18, "KK tokens");
        console2.log("Expected rewards (10 blocks * 10 KK):", 100, "KK tokens");
    }
    
    function demoStep3_SecondUserJoins() internal {
        console2.log("\nStep 3: Second User Joins");
        console2.log("User2 stakes 3 ETH using WETH method");
        
        // User2 first converts ETH to WETH
        vm.prank(user2);
        weth.deposit{value: 3 ether}();
        console2.log("User2 deposited 3 ETH to get WETH");
        
        // User2 approves and stakes WETH
        vm.prank(user2);
        weth.approve(address(stakingPool), 3 ether);
        
        vm.prank(user2);
        stakingPool.stake(3 ether);
        
        (uint256 amount1,) = stakingPool.userInfo(user1);
        (uint256 amount2,) = stakingPool.userInfo(user2);
        
        console2.log("User1 staked:", amount1 / 1e18, "ETH");
        console2.log("User2 staked:", amount2 / 1e18, "ETH");
        console2.log("Total staked:", stakingPool.totalStaked() / 1e18, "ETH");
    }
    
    function demoStep4_HarvestRewards() internal {
        console2.log("\nStep 4: Harvesting Rewards");
        
        // Move forward 15 more blocks
        vm.roll(block.number + 15);
        
        uint256 user1Pending = stakingPool.pendingKK(user1);
        uint256 user2Pending = stakingPool.pendingKK(user2);
        
        console2.log("After 15 additional blocks:");
        console2.log("User1 pending:", user1Pending / 1e18, "KK tokens");
        console2.log("User2 pending:", user2Pending / 1e18, "KK tokens");
        
        // User1 harvests
        vm.prank(user1);
        stakingPool.harvest();
        
        uint256 user1Balance = kkToken.balanceOf(user1);
        console2.log("User1 harvested and received:", user1Balance / 1e18, "KK tokens");
        
        // User2 also harvests
        vm.prank(user2);
        stakingPool.harvest();
        
        uint256 user2Balance = kkToken.balanceOf(user2);
        console2.log("User2 harvested and received:", user2Balance / 1e18, "KK tokens");
    }
    
    function demoStep5_PartialUnstake() internal {
        console2.log("\nStep 5: Partial Unstaking");
        
        // Move forward a few more blocks
        vm.roll(block.number + 5);
        
        // User1 unstakes 1 ETH as ETH
        uint256 user1InitialETH = user1.balance;
        console2.log("User1 balance before unstake:", user1InitialETH / 1e18, "ETH");
        
        vm.prank(user1);
        stakingPool.unstake(1 ether, true); // withdrawAsETH = true
        
        uint256 user1FinalETH = user1.balance;
        console2.log("User1 unstaked 1 ETH, received ETH:", (user1FinalETH - user1InitialETH) / 1e18, "ETH");
        
        // User2 unstakes 1 ETH as WETH
        uint256 user2InitialWETH = weth.balanceOf(user2);
        
        vm.prank(user2);
        stakingPool.unstake(1 ether, false); // withdrawAsETH = false
        
        uint256 user2FinalWETH = weth.balanceOf(user2);
        console2.log("User2 unstaked 1 ETH, received WETH:", (user2FinalWETH - user2InitialWETH) / 1e18, "WETH");
        
        // Check remaining stakes
        (uint256 amount1,) = stakingPool.userInfo(user1);
        (uint256 amount2,) = stakingPool.userInfo(user2);
        console2.log("User1 remaining stake:", amount1 / 1e18, "ETH");
        console2.log("User2 remaining stake:", amount2 / 1e18, "ETH");
    }
    
    function demoStep6_EmergencyScenario() internal {
        console2.log("\nStep 6: Emergency Withdrawal Demo");
        
        // Create a third user for emergency demo
        address emergencyUser = makeAddr("EmergencyUser");
        vm.deal(emergencyUser, 5 ether);
        
        // Emergency user stakes
        vm.prank(emergencyUser);
        stakingPool.stakeETH{value: 1 ether}();
        
        // Wait some blocks (accumulate rewards)
        vm.roll(block.number + 8);
        
        uint256 pendingBeforeEmergency = stakingPool.pendingKK(emergencyUser);
        uint256 wethBeforeEmergency = weth.balanceOf(emergencyUser);
        
        console2.log("Emergency user pending rewards before withdrawal:", pendingBeforeEmergency / 1e18, "KK");
        
        // Emergency withdraw (forfeits rewards)
        vm.prank(emergencyUser);
        stakingPool.emergencyWithdraw();
        
        uint256 wethAfterEmergency = weth.balanceOf(emergencyUser);
        uint256 kkAfterEmergency = kkToken.balanceOf(emergencyUser);
        
        console2.log("Emergency user received WETH:", (wethAfterEmergency - wethBeforeEmergency) / 1e18);
        console2.log("Emergency user KK rewards (should be 0):", kkAfterEmergency / 1e18);
    }
    
    function demoStep7_AdminFunctions() internal {
        console2.log("\nStep 7: Admin Functions Demo");
        
        // Current reward rate
        uint256 currentRate = stakingPool.rewardPerBlock();
        console2.log("Current reward per block:", currentRate / 1e18, "KK tokens");
        
        // Admin updates reward rate
        uint256 newRate = 15 * 1e18; // Increase to 15 KK per block
        vm.prank(admin);
        stakingPool.updateRewardPerBlock(newRate);
        
        console2.log("Admin updated reward per block to:", newRate / 1e18, "KK tokens");
        
        // Test the new rate
        uint256 user1PendingBefore = stakingPool.pendingKK(user1);
        vm.roll(block.number + 4); // 4 blocks at new rate
        uint256 user1PendingAfter = stakingPool.pendingKK(user1);
        
        console2.log("User1 rewards growth over 4 blocks with new rate:", (user1PendingAfter - user1PendingBefore) / 1e18, "KK");
        
        // Demo pause/unpause functionality
        console2.log("\nTesting pause functionality");
        vm.prank(admin);
        stakingPool.pause();
        console2.log("Pool paused by admin");
        
        // Try staking while paused (should fail)
        vm.prank(user1);
        vm.expectRevert();
        stakingPool.stakeETH{value: 0.1 ether}();
        console2.log("Staking correctly blocked while paused");
        
        // Unpause
        vm.prank(admin);
        stakingPool.unpause();
        console2.log("Pool unpaused by admin");
    }
    
    function demoStep8_FinalStatus() internal {
        console2.log("\nStep 8: Final Status Report");
        
        // Pool information
        (uint256 totalStaked, uint256 rewardPerBlock, uint256 lastRewardBlock, uint256 accRewardPerShare) = stakingPool.getPoolInfo();
        
        console2.log("=== POOL STATUS ===");
        console2.log("Total Staked:", totalStaked / 1e18, "ETH");
        console2.log("Reward Per Block:", rewardPerBlock / 1e18, "KK tokens");
        console2.log("Last Reward Block:", lastRewardBlock);
        console2.log("Current Block:", block.number);
        
        // User information
        console2.log("\n=== USER STATUS ===");
        
        (uint256 amount1, uint256 debt1, uint256 pending1) = stakingPool.getUserInfo(user1);
        console2.log("User1 - Staked:", amount1 / 1e18, "ETH");
        console2.log("User1 - Pending:", pending1 / 1e18, "KK");
        console2.log("User1 - Balance:", kkToken.balanceOf(user1) / 1e18, "KK");
        
        (uint256 amount2, uint256 debt2, uint256 pending2) = stakingPool.getUserInfo(user2);
        console2.log("User2 - Staked:", amount2 / 1e18, "ETH");
        console2.log("User2 - Pending:", pending2 / 1e18, "KK");
        console2.log("User2 - Balance:", kkToken.balanceOf(user2) / 1e18, "KK");
        
        // Token supplies
        console2.log("\n=== TOKEN STATUS ===");
        console2.log("Total KK Token Supply:", kkToken.totalSupply() / 1e18, "KK");
        console2.log("Total WETH in Pool:", weth.balanceOf(address(stakingPool)) / 1e18, "WETH");
        console2.log("Pool ETH Balance:", address(stakingPool).balance / 1e18, "ETH");
        
        // Verify accounting
        uint256 totalUserStakes = amount1 + amount2;
        uint256 totalPoolWETH = weth.balanceOf(address(stakingPool));
        console2.log("\n=== ACCOUNTING VERIFICATION ===");
        console2.log("Sum of user stakes:", totalUserStakes / 1e18, "ETH");
        console2.log("Pool WETH balance:", totalPoolWETH / 1e18, "WETH");
        console2.log("Accounting match:", totalUserStakes == totalPoolWETH ? "PASS" : "FAIL");
    }
}