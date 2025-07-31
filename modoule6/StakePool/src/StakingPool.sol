// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./MockWETH.sol";
import "./KKToken.sol";

/**
 * @title StakingPool
 * @dev A MasterChef-style staking pool where users stake ETH/WETH to earn KK tokens
 * Implements fair reward distribution based on stake amount and duration
 */
contract StakingPool is ReentrancyGuard, AccessControl, Pausable {
    // Role for admin functions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Precision factor for reward calculations to avoid rounding errors
    uint256 public constant ACC_PRECISION = 1e12;

    // Contract addresses
    MockWETH public immutable stakingToken;  // WETH token users stake
    KKToken public immutable rewardToken;    // KK token users earn

    // Pool configuration
    uint256 public rewardPerBlock = 10 * 1e18;  // 10 KK tokens per block
    uint256 public lastRewardBlock;              // Last block where rewards were calculated
    uint256 public accRewardPerShare;            // Accumulated rewards per share
    uint256 public totalStaked;                  // Total amount of WETH staked

    // User information
    struct UserInfo {
        uint256 amount;      // Amount of WETH staked by user
        uint256 rewardDebt;  // Reward debt for reward calculation
    }
    mapping(address => UserInfo) public userInfo;

    // Custom errors
    error InsufficientBalance();
    error InvalidAmount();
    error TransferFailed();
    error UnauthorizedAccess();

    // Events
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount, bool asETH);
    event RewardHarvested(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event RewardPerBlockUpdated(uint256 oldReward, uint256 newReward);
    event PoolUpdated(uint256 lastRewardBlock, uint256 accRewardPerShare);

    /**
     * @dev Constructor initializes the staking pool
     * @param _stakingToken Address of the MockWETH token
     * @param _rewardToken Address of the KK token
     * @param _admin Address that will have admin privileges
     */
    constructor(
        address payable _stakingToken,
        address _rewardToken,
        address _admin
    ) {
        require(_stakingToken != address(0), "Invalid staking token");
        require(_rewardToken != address(0), "Invalid reward token");
        require(_admin != address(0), "Invalid admin address");

        stakingToken = MockWETH(_stakingToken);
        rewardToken = KKToken(_rewardToken);
        
        // Set the starting block for rewards
        lastRewardBlock = block.number;
        
        // Grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(ADMIN_ROLE, _admin);
    }

    /**
     * @dev Stake ETH by converting it to WETH and staking
     * User sends ETH directly to this function
     */
    function stakeETH() external payable nonReentrant whenNotPaused {
        if (msg.value == 0) revert InvalidAmount();
        
        // Convert ETH to WETH via deposit
        stakingToken.deposit{value: msg.value}();
        
        // Stake the WETH
        _stake(msg.sender, msg.value);
    }

    /**
     * @dev Stake WETH tokens (user must approve first)
     * @param amount Amount of WETH to stake
     */
    function stake(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) revert InvalidAmount();
        
        // Transfer WETH from user to this contract
        bool success = stakingToken.transferFrom(msg.sender, address(this), amount);
        if (!success) revert TransferFailed();
        
        _stake(msg.sender, amount);
    }

    /**
     * @dev Internal function to handle staking logic
     * @param user Address of the user staking
     * @param amount Amount being staked
     */
    function _stake(address user, uint256 amount) internal {
        updatePool();
        
        UserInfo storage userStake = userInfo[user];
        
        // If user already has stake, harvest pending rewards
        if (userStake.amount > 0) {
            uint256 pending = (userStake.amount * accRewardPerShare / ACC_PRECISION) - userStake.rewardDebt;
            if (pending > 0) {
                _safeRewardTransfer(user, pending);
                emit RewardHarvested(user, pending);
            }
        }
        
        // Update user stake info
        userStake.amount += amount;
        userStake.rewardDebt = userStake.amount * accRewardPerShare / ACC_PRECISION;
        
        // Update total staked
        totalStaked += amount;
        
        emit Staked(user, amount);
    }

    /**
     * @dev Harvest rewards without unstaking
     */
    function harvest() external nonReentrant whenNotPaused {
        updatePool();
        
        UserInfo storage userStake = userInfo[msg.sender];
        uint256 pending = (userStake.amount * accRewardPerShare / ACC_PRECISION) - userStake.rewardDebt;
        
        if (pending > 0) {
            userStake.rewardDebt = userStake.amount * accRewardPerShare / ACC_PRECISION;
            _safeRewardTransfer(msg.sender, pending);
            emit RewardHarvested(msg.sender, pending);
        }
    }

    /**
     * @dev Unstake tokens and optionally convert WETH back to ETH
     * @param amount Amount to unstake
     * @param withdrawAsETH If true, converts WETH to ETH before sending
     */
    function unstake(uint256 amount, bool withdrawAsETH) external nonReentrant whenNotPaused {
        UserInfo storage userStake = userInfo[msg.sender];
        if (userStake.amount < amount) revert InsufficientBalance();
        if (amount == 0) revert InvalidAmount();
        
        updatePool();
        
        // Calculate and transfer pending rewards
        uint256 pending = (userStake.amount * accRewardPerShare / ACC_PRECISION) - userStake.rewardDebt;
        if (pending > 0) {
            _safeRewardTransfer(msg.sender, pending);
            emit RewardHarvested(msg.sender, pending);
        }
        
        // Update user stake info
        userStake.amount -= amount;
        userStake.rewardDebt = userStake.amount * accRewardPerShare / ACC_PRECISION;
        
        // Update total staked
        totalStaked -= amount;
        
        // Transfer tokens back to user
        if (withdrawAsETH) {
            // Convert WETH to ETH and send to user
            stakingToken.withdraw(amount);
            (bool success, ) = payable(msg.sender).call{value: amount}("");
            if (!success) revert TransferFailed();
        } else {
            // Send WETH directly to user
            bool success = stakingToken.transfer(msg.sender, amount);
            if (!success) revert TransferFailed();
        }
        
        emit Unstaked(msg.sender, amount, withdrawAsETH);
    }

    /**
     * @dev Emergency withdraw - get back staked tokens without rewards
     * Used in emergency situations or if reward distribution fails
     */
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage userStake = userInfo[msg.sender];
        uint256 amount = userStake.amount;
        
        if (amount == 0) revert InvalidAmount();
        
        // Reset user stake info
        userStake.amount = 0;
        userStake.rewardDebt = 0;
        
        // Update total staked
        totalStaked -= amount;
        
        // Transfer WETH back to user
        bool success = stakingToken.transfer(msg.sender, amount);
        if (!success) revert TransferFailed();
        
        emit EmergencyWithdraw(msg.sender, amount);
    }

    /**
     * @dev Update reward variables of the pool
     * Should be called before any stake/unstake operation
     */
    function updatePool() public {
        if (block.number <= lastRewardBlock) {
            return;
        }
        
        if (totalStaked == 0) {
            lastRewardBlock = block.number;
            return;
        }
        
        uint256 blocksSinceLastReward = block.number - lastRewardBlock;
        uint256 reward = blocksSinceLastReward * rewardPerBlock;
        
        // Mint rewards to this contract
        rewardToken.mint(address(this), reward);
        
        // Update accumulated reward per share
        accRewardPerShare += (reward * ACC_PRECISION) / totalStaked;
        lastRewardBlock = block.number;
        
        emit PoolUpdated(lastRewardBlock, accRewardPerShare);
    }

    /**
     * @dev Calculate pending rewards for a user
     * @param user Address of the user
     * @return pending Pending reward amount
     */
    function pendingKK(address user) external view returns (uint256 pending) {
        UserInfo memory userStake = userInfo[user];
        uint256 _accRewardPerShare = accRewardPerShare;
        
        if (block.number > lastRewardBlock && totalStaked != 0) {
            uint256 blocksSinceLastReward = block.number - lastRewardBlock;
            uint256 reward = blocksSinceLastReward * rewardPerBlock;
            _accRewardPerShare += (reward * ACC_PRECISION) / totalStaked;
        }
        
        pending = (userStake.amount * _accRewardPerShare / ACC_PRECISION) - userStake.rewardDebt;
    }

    /**
     * @dev Safe reward transfer function - handles cases where contract has insufficient balance
     * @param to Address to transfer rewards to
     * @param amount Amount to transfer
     */
    function _safeRewardTransfer(address to, uint256 amount) internal {
        uint256 rewardBalance = rewardToken.balanceOf(address(this));
        if (amount > rewardBalance) {
            bool success = rewardToken.transfer(to, rewardBalance);
            if (!success) revert TransferFailed();
        } else {
            bool success = rewardToken.transfer(to, amount);
            if (!success) revert TransferFailed();
        }
    }

    /**
     * @dev Update reward per block - only admin
     * @param newRewardPerBlock New reward amount per block
     */
    function updateRewardPerBlock(uint256 newRewardPerBlock) external {
        if (!hasRole(ADMIN_ROLE, msg.sender)) revert UnauthorizedAccess();
        
        updatePool(); // Update pool with current reward rate first
        
        uint256 oldReward = rewardPerBlock;
        rewardPerBlock = newRewardPerBlock;
        
        emit RewardPerBlockUpdated(oldReward, newRewardPerBlock);
    }

    /**
     * @dev Pause the contract - only admin
     */
    function pause() external {
        if (!hasRole(ADMIN_ROLE, msg.sender)) revert UnauthorizedAccess();
        _pause();
    }

    /**
     * @dev Unpause the contract - only admin
     */
    function unpause() external {
        if (!hasRole(ADMIN_ROLE, msg.sender)) revert UnauthorizedAccess();
        _unpause();
    }

    /**
     * @dev Get user stake information
     * @param user Address of the user
     * @return amount Amount staked by user
     * @return rewardDebt Current reward debt
     * @return pendingRewards Pending rewards to be claimed
     */
    function getUserInfo(address user) external view returns (
        uint256 amount,
        uint256 rewardDebt,
        uint256 pendingRewards
    ) {
        UserInfo memory userStake = userInfo[user];
        amount = userStake.amount;
        rewardDebt = userStake.rewardDebt;
        
        // Calculate pending rewards
        uint256 _accRewardPerShare = accRewardPerShare;
        if (block.number > lastRewardBlock && totalStaked != 0) {
            uint256 blocksSinceLastReward = block.number - lastRewardBlock;
            uint256 reward = blocksSinceLastReward * rewardPerBlock;
            _accRewardPerShare += (reward * ACC_PRECISION) / totalStaked;
        }
        pendingRewards = (userStake.amount * _accRewardPerShare / ACC_PRECISION) - userStake.rewardDebt;
    }

    /**
     * @dev Get pool information
     */
    function getPoolInfo() external view returns (
        uint256 _totalStaked,
        uint256 _rewardPerBlock,
        uint256 _lastRewardBlock,
        uint256 _accRewardPerShare
    ) {
        _totalStaked = totalStaked;
        _rewardPerBlock = rewardPerBlock;
        _lastRewardBlock = lastRewardBlock;
        _accRewardPerShare = accRewardPerShare;
    }

    /**
     * @dev Receive ETH for emergency purposes
     */
    receive() external payable {}
}