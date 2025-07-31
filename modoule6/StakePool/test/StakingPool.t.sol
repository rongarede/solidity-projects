// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {StakingPool} from "../src/StakingPool.sol";
import {MockWETH} from "../src/MockWETH.sol";
import {KKToken} from "../src/KKToken.sol";

contract StakingPoolTest is Test {
    StakingPool public stakingPool;
    MockWETH public weth;
    KKToken public kkToken;
    
    address public admin;
    address public user1;
    address public user2;
    address public user3;
    
    // Events from StakingPool
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount, bool asETH);
    event RewardHarvested(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event RewardPerBlockUpdated(uint256 oldReward, uint256 newReward);
    event PoolUpdated(uint256 lastRewardBlock, uint256 accRewardPerShare);

    function setUp() public {
        admin = makeAddr("admin");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        
        // Give users ETH
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(user3, 100 ether);
        
        // Deploy contracts
        weth = new MockWETH();
        
        vm.prank(admin);
        kkToken = new KKToken(admin);
        
        vm.prank(admin);
        stakingPool = new StakingPool(payable(address(weth)), address(kkToken), admin);
        
        // Grant minter role to staking pool
        vm.prank(admin);
        kkToken.grantMinterRole(address(stakingPool));
    }

    function testInitialSetup() public {
        assertEq(address(stakingPool.stakingToken()), address(weth));
        assertEq(address(stakingPool.rewardToken()), address(kkToken));
        assertEq(stakingPool.rewardPerBlock(), 10 * 1e18);
        assertEq(stakingPool.totalStaked(), 0);
        assertTrue(stakingPool.hasRole(stakingPool.ADMIN_ROLE(), admin));
        assertEq(stakingPool.lastRewardBlock(), block.number);
    }

    function testStakeETH() public {
        uint256 stakeAmount = 1 ether;
        
        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit Staked(user1, stakeAmount);
        
        stakingPool.stakeETH{value: stakeAmount}();
        
        (uint256 amount, ) = stakingPool.userInfo(user1);
        assertEq(amount, stakeAmount);
        assertEq(stakingPool.totalStaked(), stakeAmount);
        
        // Check WETH was properly deposited
        assertEq(weth.balanceOf(address(stakingPool)), stakeAmount);
    }

    function testStakeWETH() public {
        uint256 stakeAmount = 2 ether;
        
        // First user gets WETH
        vm.prank(user1);
        weth.deposit{value: stakeAmount}();
        
        // Approve staking pool to spend WETH
        vm.prank(user1);
        weth.approve(address(stakingPool), stakeAmount);
        
        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit Staked(user1, stakeAmount);
        
        stakingPool.stake(stakeAmount);
        
        (uint256 amount, ) = stakingPool.userInfo(user1);
        assertEq(amount, stakeAmount);
        assertEq(stakingPool.totalStaked(), stakeAmount);
    }

    function testStakeZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert(StakingPool.InvalidAmount.selector);
        stakingPool.stakeETH{value: 0}();
    }

    function testStakeWETHWithoutApproval() public {
        uint256 stakeAmount = 1 ether;
        
        vm.prank(user1);
        weth.deposit{value: stakeAmount}();
        
        vm.prank(user1);
        vm.expectRevert();
        stakingPool.stake(stakeAmount);
    }

    function testSingleUserRewardCalculation() public {
        uint256 stakeAmount = 1 ether;
        
        // User stakes
        vm.prank(user1);
        stakingPool.stakeETH{value: stakeAmount}();
        
        // Move forward 10 blocks
        vm.roll(block.number + 10);
        
        // Check pending rewards (should be 10 blocks * 10 KK per block = 100 KK)
        uint256 pendingRewards = stakingPool.pendingKK(user1);
        assertEq(pendingRewards, 100 * 1e18);
    }

    function testHarvest() public {
        uint256 stakeAmount = 1 ether;
        
        // User stakes
        vm.prank(user1);
        stakingPool.stakeETH{value: stakeAmount}();
        
        // Move forward 5 blocks
        vm.roll(block.number + 5);
        
        uint256 expectedReward = 50 * 1e18; // 5 blocks * 10 KK
        
        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit RewardHarvested(user1, expectedReward);
        
        stakingPool.harvest();
        
        assertEq(kkToken.balanceOf(user1), expectedReward);
    }

    function testUnstakeAsWETH() public {
        uint256 stakeAmount = 2 ether;
        uint256 unstakeAmount = 1 ether;
        
        // User stakes
        vm.prank(user1);
        stakingPool.stakeETH{value: stakeAmount}();
        
        // Move forward some blocks
        vm.roll(block.number + 3);
        
        uint256 initialWETHBalance = weth.balanceOf(user1);
        
        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit Unstaked(user1, unstakeAmount, false);
        
        stakingPool.unstake(unstakeAmount, false);
        
        // Check staking state
        (uint256 amount, ) = stakingPool.userInfo(user1);
        assertEq(amount, stakeAmount - unstakeAmount);
        assertEq(stakingPool.totalStaked(), stakeAmount - unstakeAmount);
        
        // Check user received WETH
        assertEq(weth.balanceOf(user1), initialWETHBalance + unstakeAmount);
        
        // Check user received rewards
        uint256 expectedReward = 30 * 1e18; // 3 blocks * 10 KK
        assertEq(kkToken.balanceOf(user1), expectedReward);
    }

    function testUnstakeAsETH() public {
        uint256 stakeAmount = 2 ether;
        uint256 unstakeAmount = 1 ether;
        
        // User stakes
        vm.prank(user1);
        stakingPool.stakeETH{value: stakeAmount}();
        
        // Move forward some blocks
        vm.roll(block.number + 2);
        
        uint256 initialETHBalance = user1.balance;
        
        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit Unstaked(user1, unstakeAmount, true);
        
        stakingPool.unstake(unstakeAmount, true);
        
        // Check user received ETH
        assertEq(user1.balance, initialETHBalance + unstakeAmount);
        
        // Check user received rewards
        uint256 expectedReward = 20 * 1e18; // 2 blocks * 10 KK
        assertEq(kkToken.balanceOf(user1), expectedReward);
    }

    function testUnstakeMoreThanStaked() public {
        uint256 stakeAmount = 1 ether;
        uint256 unstakeAmount = 2 ether;
        
        vm.prank(user1);
        stakingPool.stakeETH{value: stakeAmount}();
        
        vm.prank(user1);
        vm.expectRevert(StakingPool.InsufficientBalance.selector);
        stakingPool.unstake(unstakeAmount, false);
    }

    function testEmergencyWithdraw() public {
        uint256 stakeAmount = 3 ether;
        
        // User stakes
        vm.prank(user1);
        stakingPool.stakeETH{value: stakeAmount}();
        
        // Move forward blocks (should have pending rewards)
        vm.roll(block.number + 5);
        
        uint256 initialWETHBalance = weth.balanceOf(user1);
        
        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit EmergencyWithdraw(user1, stakeAmount);
        
        stakingPool.emergencyWithdraw();
        
        // Check user gets back staked amount but no rewards
        (uint256 amount, uint256 rewardDebt) = stakingPool.userInfo(user1);
        assertEq(amount, 0);
        assertEq(rewardDebt, 0);
        assertEq(weth.balanceOf(user1), initialWETHBalance + stakeAmount);
        assertEq(kkToken.balanceOf(user1), 0); // No rewards
        assertEq(stakingPool.totalStaked(), 0);
    }

    function testMultipleUsersRewardDistribution() public {
        uint256 stake1 = 1 ether;
        uint256 stake2 = 2 ether;
        
        // User1 stakes 1 ETH
        vm.prank(user1);
        stakingPool.stakeETH{value: stake1}();
        
        // Move forward 10 blocks (user1 gets all rewards)
        vm.roll(block.number + 10);
        
        // User2 stakes 2 ETH
        vm.prank(user2);
        stakingPool.stakeETH{value: stake2}();
        
        // Move forward 9 more blocks (rewards split proportionally)
        vm.roll(block.number + 9);
        
        // Check pending rewards
        uint256 pending1 = stakingPool.pendingKK(user1);
        uint256 pending2 = stakingPool.pendingKK(user2);
        
        // User1: 10 blocks alone (100 KK) + 9 blocks with 1/3 share (30 KK) = 130 KK
        assertEq(pending1, 130 * 1e18);
        
        // User2: 9 blocks with 2/3 share (60 KK) = 60 KK
        assertEq(pending2, 60 * 1e18);
    }

    function testRewardPerBlockUpdate() public {
        uint256 newRewardPerBlock = 20 * 1e18;
        
        vm.prank(admin);
        vm.expectEmit(false, false, false, true);
        emit RewardPerBlockUpdated(10 * 1e18, newRewardPerBlock);
        
        stakingPool.updateRewardPerBlock(newRewardPerBlock);
        
        assertEq(stakingPool.rewardPerBlock(), newRewardPerBlock);
    }

    function testNonAdminCannotUpdateRewardPerBlock() public {
        vm.prank(user1);
        vm.expectRevert(StakingPool.UnauthorizedAccess.selector);
        stakingPool.updateRewardPerBlock(20 * 1e18);
    }

    function testPauseAndUnpause() public {
        // Admin pauses
        vm.prank(admin);
        stakingPool.pause();
        
        // Staking should fail when paused
        vm.prank(user1);
        vm.expectRevert();
        stakingPool.stakeETH{value: 1 ether}();
        
        // Admin unpauses
        vm.prank(admin);
        stakingPool.unpause();
        
        // Staking should work again
        vm.prank(user1);
        stakingPool.stakeETH{value: 1 ether}();
        
        (uint256 amount, ) = stakingPool.userInfo(user1);
        assertEq(amount, 1 ether);
    }

    function testNonAdminCannotPause() public {
        vm.prank(user1);
        vm.expectRevert(StakingPool.UnauthorizedAccess.selector);
        stakingPool.pause();
    }

    function testGetUserInfo() public {
        uint256 stakeAmount = 1 ether;
        
        vm.prank(user1);
        stakingPool.stakeETH{value: stakeAmount}();
        
        vm.roll(block.number + 5);
        
        (uint256 amount, uint256 rewardDebt, uint256 pendingRewards) = stakingPool.getUserInfo(user1);
        
        assertEq(amount, stakeAmount);
        assertEq(pendingRewards, 50 * 1e18); // 5 blocks * 10 KK
    }

    function testGetPoolInfo() public {
        uint256 stakeAmount = 2 ether;
        
        vm.prank(user1);
        stakingPool.stakeETH{value: stakeAmount}();
        
        (uint256 totalStaked, uint256 rewardPerBlock, uint256 lastRewardBlock, uint256 accRewardPerShare) = stakingPool.getPoolInfo();
        
        assertEq(totalStaked, stakeAmount);
        assertEq(rewardPerBlock, 10 * 1e18);
        assertTrue(lastRewardBlock > 0);
    }

    function testComplexMultiUserScenario() public {
        // User1 stakes 1 ETH
        vm.prank(user1);
        stakingPool.stakeETH{value: 1 ether}();
        
        // 5 blocks pass
        vm.roll(block.number + 5);
        
        // User2 stakes 2 ETH
        vm.prank(user2);
        stakingPool.stakeETH{value: 2 ether}();
        
        // 6 blocks pass
        vm.roll(block.number + 6);
        
        // User1 harvests
        vm.prank(user1);
        stakingPool.harvest();
        
        // User3 stakes 3 ETH
        vm.prank(user3);
        stakingPool.stakeETH{value: 3 ether}();
        
        // 4 blocks pass
        vm.roll(block.number + 4);
        
        // Check final rewards
        uint256 user1Rewards = kkToken.balanceOf(user1) + stakingPool.pendingKK(user1);
        uint256 user2Rewards = stakingPool.pendingKK(user2);
        uint256 user3Rewards = stakingPool.pendingKK(user3);
        
        // User1: 5 blocks alone (50 KK) + 6 blocks with 1/3 share (20 KK) + 4 blocks with 1/6 share (~6.67 KK)
        assertApproxEqAbs(user1Rewards, 76666666666666666666, 1e15); // ~76.67 KK
        
        // User2: 6 blocks with 2/3 share (40 KK) + 4 blocks with 2/6 share (~13.33 KK)
        assertApproxEqAbs(user2Rewards, 53333333333333333333, 1e15); // ~53.33 KK
        
        // User3: 4 blocks with 3/6 share (20 KK)
        assertApproxEqAbs(user3Rewards, 20 * 1e18, 1e15);
    }

    function testStakeAfterHarvest() public {
        uint256 initialStake = 1 ether;
        uint256 additionalStake = 0.5 ether;
        
        // Initial stake
        vm.prank(user1);
        stakingPool.stakeETH{value: initialStake}();
        
        // Wait and harvest
        vm.roll(block.number + 10);
        vm.prank(user1);
        stakingPool.harvest();
        
        uint256 rewardsAfterHarvest = kkToken.balanceOf(user1);
        assertEq(rewardsAfterHarvest, 100 * 1e18);
        
        // Additional stake should trigger another harvest
        vm.roll(block.number + 5);
        vm.prank(user1);
        stakingPool.stakeETH{value: additionalStake}();
        
        // Should have additional rewards from the 5 blocks
        uint256 totalRewards = kkToken.balanceOf(user1);
        assertEq(totalRewards, 150 * 1e18);
        
        (uint256 amount, ) = stakingPool.userInfo(user1);
        assertEq(amount, initialStake + additionalStake);
    }

    // Fuzz testing
    function testFuzzStakeAmount(uint256 stakeAmount) public {
        stakeAmount = bound(stakeAmount, 0.01 ether, 50 ether);
        
        vm.deal(user1, stakeAmount);
        vm.prank(user1);
        stakingPool.stakeETH{value: stakeAmount}();
        
        (uint256 amount, ) = stakingPool.userInfo(user1);
        assertEq(amount, stakeAmount);
        assertEq(stakingPool.totalStaked(), stakeAmount);
    }

    function testFuzzRewardCalculation(uint256 stakeAmount, uint256 blocks) public {
        stakeAmount = bound(stakeAmount, 0.01 ether, 10 ether);
        blocks = bound(blocks, 1, 1000);
        
        vm.deal(user1, stakeAmount);
        vm.prank(user1);
        stakingPool.stakeETH{value: stakeAmount}();
        
        vm.roll(block.number + blocks);
        
        uint256 expectedReward = blocks * 10 * 1e18;
        uint256 pendingReward = stakingPool.pendingKK(user1);
        
        // Allow for small precision errors in reward calculations
        assertApproxEqAbs(pendingReward, expectedReward, 1e15);
    }

    // Edge cases
    function testUpdatePoolWithZeroStaked() public {
        // Should not revert even with no stakers
        stakingPool.updatePool();
        assertEq(stakingPool.totalStaked(), 0);
    }

    function testRewardsWithVerySmallStake() public {
        uint256 tinyStake = 1 wei;
        
        vm.deal(user1, tinyStake);
        vm.prank(user1);
        stakingPool.stakeETH{value: tinyStake}();
        
        vm.roll(block.number + 1);
        
        uint256 pending = stakingPool.pendingKK(user1);
        assertEq(pending, 10 * 1e18); // Should still get full block reward
    }

    function testConstructorWithInvalidAddresses() public {
        vm.expectRevert("Invalid staking token");
        new StakingPool(payable(address(0)), address(kkToken), admin);
        
        vm.expectRevert("Invalid reward token");
        new StakingPool(payable(address(weth)), address(0), admin);
        
        vm.expectRevert("Invalid admin address");
        new StakingPool(payable(address(weth)), address(kkToken), address(0));
    }
}