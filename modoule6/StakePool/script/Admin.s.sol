// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {MockWETH} from "../src/MockWETH.sol";
import {KKToken} from "../src/KKToken.sol";
import {StakingPool} from "../src/StakingPool.sol";

/**
 * @title Admin
 * @dev Administrative utility script for StakingPool system
 * Provides common admin operations and emergency functions
 */
contract Admin is Script {
    // Contract instances
    MockWETH public weth;
    KKToken public kkToken;
    StakingPool public stakingPool;
    
    // Admin address
    address public admin;
    
    function setUp() public {
        // Load contract addresses
        _loadContractAddresses();
        
        // Load admin address
        admin = vm.envAddress("ADMIN_ADDRESS");
        
        // Verify admin permissions
        _verifyAdminPermissions();
        
        console2.log("=== ADMIN UTILITY INITIALIZED ===");
        console2.log("Admin address:", admin);
        console2.log("MockWETH:     ", address(weth));
        console2.log("KKToken:      ", address(kkToken));
        console2.log("StakingPool:  ", address(stakingPool));
    }
    
    function _loadContractAddresses() internal {
        address wethAddress = vm.envAddress("MOCKWETH_ADDRESS");
        address kkTokenAddress = vm.envAddress("KKTOKEN_ADDRESS");
        address stakingPoolAddress = vm.envAddress("STAKINGPOOL_ADDRESS");
        
        weth = MockWETH(payable(wethAddress));
        kkToken = KKToken(kkTokenAddress);
        stakingPool = StakingPool(payable(stakingPoolAddress));
    }
    
    function _verifyAdminPermissions() internal view {
        require(kkToken.hasRole(kkToken.DEFAULT_ADMIN_ROLE(), admin), "Admin lacks KKToken admin role");
        require(stakingPool.hasRole(stakingPool.ADMIN_ROLE(), admin), "Admin lacks StakingPool admin role");
        console2.log("Admin permissions verified");
    }
    
    function run() public {
        console2.log("\n=== ADMIN DASHBOARD ===");
        
        showCurrentStatus();
        showAvailableCommands();
        
        console2.log("\nUse specific functions like updateRewardRate(), pausePool(), etc.");
    }
    
    function showCurrentStatus() internal view {
        console2.log("\n📊 CURRENT STATUS");
        console2.log("================");
        
        uint256 rewardPerBlock = stakingPool.rewardPerBlock();
        uint256 totalStaked = stakingPool.totalStaked();
        bool isPaused = false;
        
        try stakingPool.paused() returns (bool paused) {
            isPaused = paused;
        } catch {}
        
        console2.log("Reward Per Block:   ", rewardPerBlock / 1e18, "KK");
        console2.log("Total Staked:       ", totalStaked / 1e18, "ETH");
        console2.log("Pool Status:        ", isPaused ? "PAUSED" : "ACTIVE");
        console2.log("KK Total Supply:    ", kkToken.totalSupply() / 1e18, "KK");
        console2.log("Active Minters:     ", kkToken.getMinterCount());
    }
    
    function showAvailableCommands() internal pure {
        console2.log("\n⚙️  AVAILABLE ADMIN COMMANDS");
        console2.log("============================");
        console2.log("updateRewardRate(uint256)    - Update reward per block");
        console2.log("pausePool()                  - Pause all pool operations");
        console2.log("unpausePool()                - Resume pool operations");
        console2.log("grantMinterRole(address)     - Grant KK minting rights");
        console2.log("revokeMinterRole(address)    - Revoke KK minting rights");
        console2.log("emergencyUpdatePool()        - Force pool reward update");
        console2.log("transferAdminRole(address)   - Transfer admin rights");
        console2.log("checkSystemHealth()          - Run comprehensive health check");
    }
    
    // Admin function: Update reward rate
    function updateRewardRate(uint256 newRewardPerBlock) external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        require(vm.addr(privateKey) == admin, "Only admin can update reward rate");
        
        uint256 oldRate = stakingPool.rewardPerBlock();
        
        console2.log("Updating reward rate from", oldRate / 1e18, "to", newRewardPerBlock / 1e18, "KK per block");
        
        vm.startBroadcast(privateKey);
        stakingPool.updateRewardPerBlock(newRewardPerBlock);
        vm.stopBroadcast();
        
        console2.log("✅ Reward rate updated successfully");
        console2.log("New rate:", stakingPool.rewardPerBlock() / 1e18, "KK per block");
    }
    
    // Admin function: Pause pool
    function pausePool() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        require(vm.addr(privateKey) == admin, "Only admin can pause pool");
        
        console2.log("Pausing StakingPool...");
        
        vm.startBroadcast(privateKey);
        stakingPool.pause();
        vm.stopBroadcast();
        
        console2.log("✅ Pool paused successfully");
        console2.log("All staking operations are now disabled");
    }
    
    // Admin function: Unpause pool
    function unpausePool() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        require(vm.addr(privateKey) == admin, "Only admin can unpause pool");
        
        console2.log("Unpausing StakingPool...");
        
        vm.startBroadcast(privateKey);
        stakingPool.unpause();
        vm.stopBroadcast();
        
        console2.log("✅ Pool unpaused successfully");
        console2.log("Staking operations are now enabled");
    }
    
    // Admin function: Grant minter role
    function grantMinterRole(address newMinter) external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        require(vm.addr(privateKey) == admin, "Only admin can grant minter role");
        require(newMinter != address(0), "Cannot grant role to zero address");
        
        console2.log("Granting minter role to:", newMinter);
        
        vm.startBroadcast(privateKey);
        kkToken.grantMinterRole(newMinter);
        vm.stopBroadcast();
        
        console2.log("✅ Minter role granted successfully");
        console2.log("New minter count:", kkToken.getMinterCount());
    }
    
    // Admin function: Revoke minter role
    function revokeMinterRole(address minter) external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        require(vm.addr(privateKey) == admin, "Only admin can revoke minter role");
        require(minter != address(0), "Cannot revoke role from zero address");
        
        console2.log("Revoking minter role from:", minter);
        
        vm.startBroadcast(privateKey);
        kkToken.revokeMinterRole(minter);
        vm.stopBroadcast();
        
        console2.log("✅ Minter role revoked successfully");
        console2.log("Remaining minter count:", kkToken.getMinterCount());
    }
    
    // Admin function: Force pool update
    function emergencyUpdatePool() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        
        console2.log("Performing emergency pool update...");
        
        uint256 beforeBlock = stakingPool.lastRewardBlock();
        
        vm.startBroadcast(privateKey);
        stakingPool.updatePool();
        vm.stopBroadcast();
        
        uint256 afterBlock = stakingPool.lastRewardBlock();
        
        console2.log("✅ Pool updated successfully");
        console2.log("Updated from block", beforeBlock, "to", afterBlock);
        console2.log("Blocks processed:", afterBlock - beforeBlock);
    }
    
    // Admin function: Transfer admin role
    function transferAdminRole(address newAdmin) external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        require(vm.addr(privateKey) == admin, "Only current admin can transfer role");
        require(newAdmin != address(0), "Cannot transfer to zero address");
        require(newAdmin != admin, "Cannot transfer to same address");
        
        console2.log("⚠️  WARNING: Transferring admin role from", admin, "to", newAdmin);
        console2.log("This will transfer ALL admin privileges!");
        console2.log("Press Ctrl+C to cancel if unsure.");
        
        vm.startBroadcast(privateKey);
        
        // Transfer StakingPool admin role
        stakingPool.grantRole(stakingPool.ADMIN_ROLE(), newAdmin);
        stakingPool.revokeRole(stakingPool.ADMIN_ROLE(), admin);
        
        // Transfer KKToken admin role
        kkToken.grantRole(kkToken.DEFAULT_ADMIN_ROLE(), newAdmin);
        kkToken.revokeRole(kkToken.DEFAULT_ADMIN_ROLE(), admin);
        
        vm.stopBroadcast();
        
        console2.log("✅ Admin role transferred successfully");
        console2.log("New admin:", newAdmin);
        console2.log("⚠️  Update your .env file with the new admin address!");
    }
    
    // System health check
    function checkSystemHealth() external view {
        console2.log("\n🏥 COMPREHENSIVE SYSTEM HEALTH CHECK");
        console2.log("====================================");
        
        bool overallHealthy = true;
        
        // Check 1: Contract connectivity
        console2.log("\n1. Contract Connectivity:");
        bool connectivityOK = true;
        try stakingPool.stakingToken() returns (address stakingToken) {
            if (stakingToken != address(weth)) {
                console2.log("❌ StakingPool -> WETH reference incorrect");
                connectivityOK = false;
            }
        } catch {
            console2.log("❌ Cannot read StakingPool.stakingToken()");
            connectivityOK = false;
        }
        
        try stakingPool.rewardToken() returns (address rewardToken) {
            if (rewardToken != address(kkToken)) {
                console2.log("❌ StakingPool -> KKToken reference incorrect");
                connectivityOK = false;
            }
        } catch {
            console2.log("❌ Cannot read StakingPool.rewardToken()");
            connectivityOK = false;
        }
        
        if (connectivityOK) {
            console2.log("✅ Contract connectivity OK");
        } else {
            overallHealthy = false;
        }
        
        // Check 2: Permissions
        console2.log("\n2. Permission System:");
        bool permissionsOK = true;
        
        if (!kkToken.hasRole(kkToken.DEFAULT_ADMIN_ROLE(), admin)) {
            console2.log("❌ Admin missing KKToken admin role");
            permissionsOK = false;
        }
        
        if (!stakingPool.hasRole(stakingPool.ADMIN_ROLE(), admin)) {
            console2.log("❌ Admin missing StakingPool admin role");
            permissionsOK = false;
        }
        
        if (!kkToken.hasRole(kkToken.MINTER_ROLE(), address(stakingPool))) {
            console2.log("❌ StakingPool missing KK minter role");
            permissionsOK = false;
        }
        
        if (permissionsOK) {
            console2.log("✅ Permission system OK");
        } else {
            overallHealthy = false;
        }
        
        // Check 3: Accounting
        console2.log("\n3. Accounting Integrity:");
        uint256 totalStaked = stakingPool.totalStaked();
        uint256 poolWETHBalance = weth.balanceOf(address(stakingPool));
        
        if (totalStaked != poolWETHBalance) {
            console2.log("❌ Accounting mismatch:");
            console2.log("   Total staked:", totalStaked / 1e18, "ETH");
            console2.log("   Pool WETH:   ", poolWETHBalance / 1e18, "WETH");
            overallHealthy = false;
        } else {
            console2.log("✅ Accounting integrity OK");
        }
        
        // Check 4: Pool Activity
        console2.log("\n4. Pool Activity:");
        uint256 lastRewardBlock = stakingPool.lastRewardBlock();
        uint256 blocksSinceUpdate = block.number - lastRewardBlock;
        
        if (blocksSinceUpdate > 1000) {
            console2.log("⚠️  Pool hasn't been updated in", blocksSinceUpdate, "blocks");
            console2.log("   Consider calling emergencyUpdatePool()");
        } else {
            console2.log("✅ Pool activity normal");
        }
        
        // Check 5: Token Supply
        console2.log("\n5. Token Economics:");
        uint256 totalKKSupply = kkToken.totalSupply();
        uint256 expectedMaxSupply = stakingPool.rewardPerBlock() * block.number;
        
        if (totalKKSupply > expectedMaxSupply * 2) {
            console2.log("⚠️  KK supply seems unusually high");
            console2.log("   Current supply:", totalKKSupply / 1e18, "KK");
            console2.log("   Consider reviewing minting activity");
        } else {
            console2.log("✅ Token economics normal");
        }
        
        // Overall result
        console2.log("\n" + "=".repeat(40));
        if (overallHealthy) {
            console2.log("✅ SYSTEM HEALTH: EXCELLENT");
            console2.log("All systems operating normally");
        } else {
            console2.log("⚠️  SYSTEM HEALTH: NEEDS ATTENTION");
            console2.log("Please address the issues above");
        }
    }
    
    // Emergency drain function (if needed)
    function emergencyInfo() external pure {
        console2.log("\n🚨 EMERGENCY PROCEDURES");
        console2.log("=======================");
        console2.log("If the system needs to be shut down:");
        console2.log("");
        console2.log("1. Pause the pool:");
        console2.log("   forge script script/Admin.s.sol --sig 'pausePool()' --broadcast");
        console2.log("");
        console2.log("2. Users can still use emergencyWithdraw() to get their funds");
        console2.log("   This function bypasses most checks and just returns staked amounts");
        console2.log("");
        console2.log("3. Admin can update reward rate to 0 to stop new rewards:");
        console2.log("   forge script script/Admin.s.sol --sig 'updateRewardRate(uint256)' 0 --broadcast");
        console2.log("");
        console2.log("⚠️  Only use emergency procedures if absolutely necessary!");
    }
    
    // Utility function to show gas estimates for admin operations
    function showGasEstimates() external pure {
        console2.log("\n⛽ ADMIN OPERATION GAS ESTIMATES");
        console2.log("===============================");
        console2.log("updateRewardPerBlock(): ~50,000 gas");
        console2.log("pause():               ~30,000 gas");
        console2.log("unpause():             ~30,000 gas");
        console2.log("grantMinterRole():     ~80,000 gas");
        console2.log("revokeMinterRole():    ~50,000 gas");
        console2.log("updatePool():          ~70,000 gas");
        console2.log("");
        console2.log("Note: Actual costs depend on network congestion");
    }
}