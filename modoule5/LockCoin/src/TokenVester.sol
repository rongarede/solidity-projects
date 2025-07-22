// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVester is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    struct VestingSchedule {
        address beneficiary;
        uint256 totalAmount;
        uint256 startTime;
        uint256 duration;
        uint256 claimedAmount;
        bool revoked;
    }

    IERC20 public immutable token;
    mapping(address => VestingSchedule) public vestingSchedules;
    mapping(address => bool) public hasVestingSchedule;

    event VestingScheduleCreated(
        address indexed beneficiary,
        uint256 totalAmount,
        uint256 startTime,
        uint256 duration
    );
    
    event TokensClaimed(
        address indexed beneficiary,
        uint256 amount
    );
    
    event VestingRevoked(
        address indexed beneficiary,
        uint256 unvestedAmount
    );

    error NoVestingSchedule();
    error VestingAlreadyExists();
    error VestingAlreadyRevoked();
    error NoTokensToClaim();
    error InvalidDuration();
    error InvalidAmount();
    error InsufficientBalance();

    constructor(IERC20 _token, address _owner) Ownable(_owner) {
        token = _token;
    }

    function createVestingSchedule(
        address beneficiary,
        uint256 totalAmount,
        uint256 startTime,
        uint256 duration
    ) external onlyOwner {
        if (hasVestingSchedule[beneficiary]) revert VestingAlreadyExists();
        if (totalAmount == 0) revert InvalidAmount();
        if (duration == 0) revert InvalidDuration();
        if (token.balanceOf(address(this)) < totalAmount) revert InsufficientBalance();

        vestingSchedules[beneficiary] = VestingSchedule({
            beneficiary: beneficiary,
            totalAmount: totalAmount,
            startTime: startTime,
            duration: duration,
            claimedAmount: 0,
            revoked: false
        });

        hasVestingSchedule[beneficiary] = true;

        emit VestingScheduleCreated(beneficiary, totalAmount, startTime, duration);
    }

    function claim() external nonReentrant {
        address beneficiary = msg.sender;
        
        if (!hasVestingSchedule[beneficiary]) revert NoVestingSchedule();
        
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        
        if (schedule.revoked) revert VestingAlreadyRevoked();

        uint256 claimableAmount = _calculateClaimableAmount(schedule);
        
        if (claimableAmount == 0) revert NoTokensToClaim();

        schedule.claimedAmount += claimableAmount;

        token.safeTransfer(beneficiary, claimableAmount);

        emit TokensClaimed(beneficiary, claimableAmount);
    }

    function _calculateClaimableAmount(VestingSchedule memory schedule) 
        internal 
        view 
        returns (uint256) 
    {
        if (block.timestamp < schedule.startTime) {
            return 0;
        }

        uint256 timeElapsed = block.timestamp - schedule.startTime;
        uint256 vestedAmount;

        if (timeElapsed >= schedule.duration) {
            vestedAmount = schedule.totalAmount;
        } else {
            vestedAmount = (schedule.totalAmount * timeElapsed) / schedule.duration;
        }

        return vestedAmount - schedule.claimedAmount;
    }

    function getClaimableAmount(address beneficiary) external view returns (uint256) {
        if (!hasVestingSchedule[beneficiary]) return 0;
        
        VestingSchedule memory schedule = vestingSchedules[beneficiary];
        
        if (schedule.revoked) return 0;
        
        return _calculateClaimableAmount(schedule);
    }

    function getVestingSchedule(address beneficiary) 
        external 
        view 
        returns (VestingSchedule memory) 
    {
        if (!hasVestingSchedule[beneficiary]) revert NoVestingSchedule();
        return vestingSchedules[beneficiary];
    }

    function revokeVesting(address beneficiary) external onlyOwner {
        if (!hasVestingSchedule[beneficiary]) revert NoVestingSchedule();
        
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        
        if (schedule.revoked) revert VestingAlreadyRevoked();

        uint256 claimableAmount = _calculateClaimableAmount(schedule);
        
        if (claimableAmount > 0) {
            schedule.claimedAmount += claimableAmount;
            token.safeTransfer(beneficiary, claimableAmount);
            emit TokensClaimed(beneficiary, claimableAmount);
        }

        uint256 unvestedAmount = schedule.totalAmount - schedule.claimedAmount;
        schedule.revoked = true;

        if (unvestedAmount > 0) {
            token.safeTransfer(owner(), unvestedAmount);
        }

        emit VestingRevoked(beneficiary, unvestedAmount);
    }

    function withdrawExcessTokens(uint256 amount) external onlyOwner {
        token.safeTransfer(owner(), amount);
    }
}