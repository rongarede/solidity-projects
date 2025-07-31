// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {MockWETH} from "../src/MockWETH.sol";
import {KKToken} from "../src/KKToken.sol";
import {StakingPool} from "../src/StakingPool.sol";

/**
 * @title Monitor
 * @dev Monitoring and query script for StakingPool system
 * Provides real-time analytics and pool statistics
 */
contract Monitor is Script {
    // Contract instances
    MockWETH public weth;
    KKToken public kkToken;
    StakingPool public stakingPool;
    
    // Analytics data structures
    struct PoolAnalytics {
        uint256 totalStaked;
        uint256 totalUsers;
        uint256 rewardPerBlock;
        uint256 lastRewardBlock;
        uint256 currentBlock;
        uint256 accRewardPerShare;
        uint256 totalKKMinted;
        uint256 poolWETHBalance;
        uint256 estimatedAPR;
    }
    
    struct UserAnalytics {
        address user;
        uint256 stakedAmount;
        uint256 pendingRewards;
        uint256 kkTokenBalance;
        uint256 rewardDebt;
        uint256 sharePercentage;
        uint256 estimatedDailyRewards;
    }
    
    function setUp() public {
        // Load contract addresses from environment or deployment files
        _loadContractAddresses();
        
        console2.log("=== STAKINGPOOL MONITOR INITIALIZED ===");
        console2.log("MockWETH:    ", address(weth));
        console2.log("KKToken:     ", address(kkToken));
        console2.log("StakingPool: ", address(stakingPool));
    }
    
    function _loadContractAddresses() internal {
        address wethAddress = vm.envOr("MOCKWETH_ADDRESS", address(0));
        address kkTokenAddress = vm.envOr("KKTOKEN_ADDRESS", address(0));
        address stakingPoolAddress = vm.envOr("STAKINGPOOL_ADDRESS", address(0));
        
        if (wethAddress == address(0) || kkTokenAddress == address(0) || stakingPoolAddress == address(0)) {
            // Try to read from deployments.txt file
            console2.log("Environment variables not set, checking deployment files...");
            // In a real implementation, you could read the deployment file here
            revert("Contract addresses not found. Set MOCKWETH_ADDRESS, KKTOKEN_ADDRESS, STAKINGPOOL_ADDRESS in .env");
        }
        
        weth = MockWETH(payable(wethAddress));
        kkToken = KKToken(kkTokenAddress);
        stakingPool = StakingPool(payable(stakingPoolAddress));
    }
    
    function run() public {
        console2.log("\n=== STAKINGPOOL MONITORING DASHBOARD ===\n");
        
        // Generate comprehensive analytics
        showPoolOverview();
        showPoolAnalytics();
        showRewardMetrics();
        showSecurityStatus();
        showRecentActivity();
        
        console2.log("\n=== MONITORING COMPLETE ===");
        console2.log("Run this script periodically to monitor pool health");
    }
    
    function showPoolOverview() internal view {
        console2.log("📊 POOL OVERVIEW");
        console2.log("================");
        
        (uint256 totalStaked, uint256 rewardPerBlock, uint256 lastRewardBlock, uint256 accRewardPerShare) = stakingPool.getPoolInfo();
        
        console2.log("Total Staked:      ", totalStaked / 1e18, "ETH");
        console2.log("Reward Per Block:  ", rewardPerBlock / 1e18, "KK tokens");
        console2.log("Current Block:     ", block.number);
        console2.log("Last Reward Block: ", lastRewardBlock);
        console2.log("Blocks Behind:     ", block.number - lastRewardBlock);
        
        // Calculate total value
        uint256 totalWETHInPool = weth.balanceOf(address(stakingPool));
        uint256 totalKKSupply = kkToken.totalSupply();
        
        console2.log("Pool WETH Balance: ", totalWETHInPool / 1e18, "WETH");
        console2.log("Total KK Minted:  ", totalKKSupply / 1e18, "KK");
        
        // Health check
        bool isHealthy = (totalStaked == totalWETHInPool) && (lastRewardBlock <= block.number);
        console2.log("Pool Health:       ", isHealthy ? "HEALTHY" : "NEEDS ATTENTION");
        
        console2.log("");
    }
    
    function showPoolAnalytics() internal view {
        console2.log("📈 ANALYTICS");
        console2.log("============");
        
        uint256 totalStaked = stakingPool.totalStaked();
        uint256 rewardPerBlock = stakingPool.rewardPerBlock();
        
        if (totalStaked > 0) {
            // Estimate daily rewards (assuming 2 second blocks, 43200 blocks per day)
            uint256 dailyRewards = rewardPerBlock * 43200; // Polygon ~2 sec blocks
            uint256 annualRewards = dailyRewards * 365;
            
            // Simple APR calculation (rewards value / staked value * 100)
            // This assumes 1 KK = 1 ETH for simplicity
            uint256 estimatedAPR = (annualRewards * 100) / totalStaked;
            
            console2.log("Daily Pool Rewards:", dailyRewards / 1e18, "KK tokens");
            console2.log("Annual Pool Rewards:", annualRewards / 1e18, "KK tokens");
            console2.log("Estimated APR:     ", estimatedAPR, "%");
            
            // Reward per ETH staked
            uint256 rewardPerETHPerBlock = (rewardPerBlock * 1e18) / totalStaked;
            console2.log("Reward per ETH/block:", rewardPerETHPerBlock / 1e18, "KK");
        } else {
            console2.log("No stakers yet - pool is empty");
        }
        
        console2.log("");
    }
    
    function showRewardMetrics() internal view {
        console2.log("🎁 REWARD METRICS");
        console2.log("=================");
        
        uint256 totalSupply = kkToken.totalSupply();
        uint256 rewardPerBlock = stakingPool.rewardPerBlock();
        uint256 blocksElapsed = block.number - stakingPool.getPoolInfo().2; // lastRewardBlock
        
        console2.log("Total KK Minted:     ", totalSupply / 1e18, "KK");
        console2.log("Current Reward Rate: ", rewardPerBlock / 1e18, "KK/block");
        console2.log("Pending Pool Update: ", blocksElapsed, "blocks");
        
        if (blocksElapsed > 0) {
            uint256 pendingMint = rewardPerBlock * blocksElapsed;
            console2.log("Pending KK to Mint:  ", pendingMint / 1e18, "KK");
        }
        
        // Check minter permissions
        bool poolCanMint = kkToken.hasRole(kkToken.MINTER_ROLE(), address(stakingPool));
        console2.log("Pool Minter Status:  ", poolCanMint ? "ACTIVE" : "INACTIVE");
        
        console2.log("");
    }
    
    function showSecurityStatus() internal view {
        console2.log("🔐 SECURITY STATUS");
        console2.log("==================");
        
        // Check if pool is paused
        try stakingPool.paused() returns (bool isPaused) {
            console2.log("Pool Status:         ", isPaused ? "PAUSED" : "ACTIVE");
        } catch {
            console2.log("Pool Status:         ", "ACTIVE (no pause function)");
        }
        
        // Check admin roles
        bytes32 adminRole = stakingPool.ADMIN_ROLE();
        uint256 adminCount = stakingPool.getRoleMemberCount(adminRole);
        console2.log("Admin Count:         ", adminCount);
        
        // Check KK token admin status
        bytes32 kkAdminRole = kkToken.DEFAULT_ADMIN_ROLE();
        uint256 kkAdminCount = kkToken.getRoleMemberCount(kkAdminRole);
        console2.log("KK Token Admin Count:", kkAdminCount);
        
        // Check minter count
        uint256 minterCount = kkToken.getMinterCount();
        console2.log("KK Token Minters:    ", minterCount);
        
        console2.log("");
    }
    
    function showRecentActivity() internal view {
        console2.log("⏰ RECENT ACTIVITY");
        console2.log("==================");
        
        uint256 currentBlock = block.number;
        uint256 lastRewardBlock = stakingPool.lastRewardBlock();
        uint256 blocksSinceUpdate = currentBlock - lastRewardBlock;
        
        console2.log("Current Block:       ", currentBlock);
        console2.log("Last Pool Update:    ", lastRewardBlock);
        console2.log("Blocks Since Update: ", blocksSinceUpdate);
        
        if (blocksSinceUpdate > 100) {
            console2.log("⚠️  WARNING: Pool hasn't been updated in", blocksSinceUpdate, "blocks");
            console2.log("Consider calling updatePool() or having a user interact with pool");
        } else if (blocksSinceUpdate > 10) {
            console2.log("ℹ️  Pool last updated", blocksSinceUpdate, "blocks ago");
        } else {
            console2.log("✅ Pool is recently updated");
        }
        
        console2.log("");
    }
    
    // Specific user monitoring functions
    function monitorUser(address user) external view {
        console2.log("👤 USER ANALYTICS:", user);
        console2.log("=======================================");
        
        (uint256 stakedAmount, uint256 rewardDebt, uint256 pendingRewards) = stakingPool.getUserInfo(user);
        uint256 kkBalance = kkToken.balanceOf(user);
        uint256 totalStaked = stakingPool.totalStaked();
        
        console2.log("Staked Amount:       ", stakedAmount / 1e18, "ETH");
        console2.log("Pending Rewards:     ", pendingRewards / 1e18, "KK");
        console2.log("KK Token Balance:    ", kkBalance / 1e18, "KK");
        console2.log("Reward Debt:         ", rewardDebt / 1e12, "(internal)");
        
        if (totalStaked > 0) {
            uint256 sharePercentage = (stakedAmount * 10000) / totalStaked; // Basis points
            console2.log("Pool Share:          ", sharePercentage / 100, ".", sharePercentage % 100, "%");
            
            // Estimate daily rewards
            uint256 rewardPerBlock = stakingPool.rewardPerBlock();
            uint256 userDailyRewards = (rewardPerBlock * 43200 * stakedAmount) / totalStaked;
            console2.log("Est. Daily Rewards:  ", userDailyRewards / 1e18, "KK");
        }
        
        console2.log("");
    }
    
    // Pool health check function
    function healthCheck() external view returns (bool isHealthy) {
        uint256 totalStaked = stakingPool.totalStaked();
        uint256 poolWETHBalance = weth.balanceOf(address(stakingPool));
        uint256 lastRewardBlock = stakingPool.lastRewardBlock();
        bool poolCanMint = kkToken.hasRole(kkToken.MINTER_ROLE(), address(stakingPool));
        
        // Check accounting
        bool accountingCorrect = (totalStaked == poolWETHBalance);
        
        // Check pool is up to date (within 100 blocks)
        bool poolUpToDate = (block.number - lastRewardBlock) <= 100;
        
        // Check permissions
        bool permissionsCorrect = poolCanMint;
        
        isHealthy = accountingCorrect && poolUpToDate && permissionsCorrect;
        
        console2.log("🏥 HEALTH CHECK RESULTS");
        console2.log("=======================");
        console2.log("Accounting Correct:  ", accountingCorrect ? "PASS" : "FAIL");
        console2.log("Pool Up to Date:     ", poolUpToDate ? "PASS" : "FAIL");
        console2.log("Permissions Correct: ", permissionsCorrect ? "PASS" : "FAIL");
        console2.log("Overall Health:      ", isHealthy ? "HEALTHY" : "UNHEALTHY");
        
        if (!isHealthy) {
            console2.log("");
            console2.log("🚨 ISSUES DETECTED:");
            if (!accountingCorrect) {
                console2.log("- Staked amount doesn't match WETH balance");
            }
            if (!poolUpToDate) {
                console2.log("- Pool rewards haven't been updated recently");
            }
            if (!permissionsCorrect) {
                console2.log("- StakingPool doesn't have minter permissions");
            }
        }
    }
    
    // Export data to JSON format
    function exportData() external view {
        console2.log("📄 EXPORTING POOL DATA");
        console2.log("======================");
        
        (uint256 totalStaked, uint256 rewardPerBlock, uint256 lastRewardBlock, uint256 accRewardPerShare) = stakingPool.getPoolInfo();
        
        // This would typically write to a file, but for demo we'll just log
        console2.log("{");
        console2.log('  "timestamp":', block.timestamp, ",");
        console2.log('  "blockNumber":', block.number, ",");
        console2.log('  "totalStaked":', totalStaked, ",");
        console2.log('  "rewardPerBlock":', rewardPerBlock, ",");
        console2.log('  "lastRewardBlock":', lastRewardBlock, ",");
        console2.log('  "totalKKSupply":', kkToken.totalSupply(), ",");
        console2.log('  "poolWETHBalance":', weth.balanceOf(address(stakingPool)));
        console2.log("}");
    }
    
    // Utility function to estimate gas costs
    function estimateGasCosts() external view {
        console2.log("⛽ GAS COST ESTIMATES");
        console2.log("====================");
        console2.log("These are rough estimates - actual costs may vary");
        console2.log("");
        console2.log("stakeETH():        ~150,000 gas");
        console2.log("stake():           ~120,000 gas");
        console2.log("harvest():         ~100,000 gas");
        console2.log("unstake():         ~180,000 gas");
        console2.log("emergencyWithdraw(): ~80,000 gas");
        console2.log("");
        console2.log("Current network gas price info:");
        console2.log("Block gas limit:   ", block.gaslimit);
        console2.log("Base fee:          Check network explorer");
    }
}