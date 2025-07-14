// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TokenVester.sol";
import "../src/MyToken.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MaliciousToken is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    string public name = "MaliciousToken";
    string public symbol = "MAL";
    uint8 public decimals = 18;
    uint256 private _totalSupply;
    
    address public attacker;
    bool public shouldReenter = false;

    constructor(uint256 _totalSupply) {
        _totalSupply = _totalSupply;
        _balances[msg.sender] = _totalSupply;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function setAttacker(address _attacker) external {
        attacker = _attacker;
    }

    function enableReentrancy() external {
        shouldReenter = true;
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        
        // Attempt reentrancy attack
        if (shouldReenter && to == attacker) {
            shouldReenter = false; // Prevent infinite loop
            ReentrancyAttacker(attacker).reenterClaim();
        }
        
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        require(_balances[from] >= amount, "Insufficient balance");
        require(_allowances[from][msg.sender] >= amount, "Insufficient allowance");
        
        _balances[from] -= amount;
        _balances[to] += amount;
        _allowances[from][msg.sender] -= amount;
        
        emit Transfer(from, to, amount);
        
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}

contract ReentrancyAttacker {
    TokenVester public vester;
    bool public attacked = false;

    constructor(TokenVester _vester) {
        vester = _vester;
    }

    function attack() external {
        vester.claim();
    }

    function reenterClaim() external {
        if (!attacked) {
            attacked = true;
            vester.claim(); // This should fail due to reentrancy guard
        }
    }
}

contract TokenVesterTest is Test {
    TokenVester public vester;
    MyToken public token;
    address public owner;
    address public beneficiary1;
    address public beneficiary2;
    
    uint256 public constant TOTAL_SUPPLY = 1_000_000 * 10**18;
    uint256 public constant VESTING_AMOUNT = 100_000 * 10**18;
    uint256 public constant VESTING_DURATION = 365 days;

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

    function setUp() public {
        owner = makeAddr("owner");
        beneficiary1 = makeAddr("beneficiary1");
        beneficiary2 = makeAddr("beneficiary2");

        vm.startPrank(owner);
        token = new MyToken("MyToken", "MTK", TOTAL_SUPPLY, owner);
        vester = new TokenVester(token, owner);
        
        // Transfer tokens to vester contract
        token.transfer(address(vester), TOTAL_SUPPLY);
        vm.stopPrank();
    }

    function testInitialState() public {
        assertEq(address(vester.token()), address(token));
        assertEq(vester.owner(), owner);
        assertEq(token.balanceOf(address(vester)), TOTAL_SUPPLY);
    }

    function testCreateVestingSchedule() public {
        uint256 startTime = block.timestamp + 1 days;
        
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit VestingScheduleCreated(beneficiary1, VESTING_AMOUNT, startTime, VESTING_DURATION);
        
        vester.createVestingSchedule(beneficiary1, VESTING_AMOUNT, startTime, VESTING_DURATION);

        assertTrue(vester.hasVestingSchedule(beneficiary1));
        
        TokenVester.VestingSchedule memory schedule = vester.getVestingSchedule(beneficiary1);
        assertEq(schedule.beneficiary, beneficiary1);
        assertEq(schedule.totalAmount, VESTING_AMOUNT);
        assertEq(schedule.startTime, startTime);
        assertEq(schedule.duration, VESTING_DURATION);
        assertEq(schedule.claimedAmount, 0);
        assertFalse(schedule.revoked);
    }

    function testCreateVestingScheduleOnlyOwner() public {
        uint256 startTime = block.timestamp + 1 days;
        
        vm.prank(beneficiary1);
        vm.expectRevert();
        vester.createVestingSchedule(beneficiary1, VESTING_AMOUNT, startTime, VESTING_DURATION);
    }

    function testCreateVestingScheduleInvalidInputs() public {
        uint256 startTime = block.timestamp + 1 days;
        
        vm.startPrank(owner);
        
        // Test zero amount
        vm.expectRevert(TokenVester.InvalidAmount.selector);
        vester.createVestingSchedule(beneficiary1, 0, startTime, VESTING_DURATION);
        
        // Test zero duration
        vm.expectRevert(TokenVester.InvalidDuration.selector);
        vester.createVestingSchedule(beneficiary1, VESTING_AMOUNT, startTime, 0);
        
        vm.stopPrank();
    }

    function testCreateVestingScheduleAlreadyExists() public {
        uint256 startTime = block.timestamp + 1 days;
        
        vm.startPrank(owner);
        vester.createVestingSchedule(beneficiary1, VESTING_AMOUNT, startTime, VESTING_DURATION);
        
        vm.expectRevert(TokenVester.VestingAlreadyExists.selector);
        vester.createVestingSchedule(beneficiary1, VESTING_AMOUNT, startTime, VESTING_DURATION);
        vm.stopPrank();
    }

    function testClaimBeforeStart() public {
        uint256 startTime = block.timestamp + 1 days;
        
        vm.prank(owner);
        vester.createVestingSchedule(beneficiary1, VESTING_AMOUNT, startTime, VESTING_DURATION);
        
        vm.prank(beneficiary1);
        vm.expectRevert(TokenVester.NoTokensToClaim.selector);
        vester.claim();
    }

    function testLinearVestingCalculation() public {
        uint256 startTime = block.timestamp;
        
        vm.prank(owner);
        vester.createVestingSchedule(beneficiary1, VESTING_AMOUNT, startTime, VESTING_DURATION);
        
        // After 25% of duration
        vm.warp(startTime + VESTING_DURATION / 4);
        uint256 expectedAmount = VESTING_AMOUNT / 4;
        assertEq(vester.getClaimableAmount(beneficiary1), expectedAmount);
        
        // After 50% of duration
        vm.warp(startTime + VESTING_DURATION / 2);
        expectedAmount = VESTING_AMOUNT / 2;
        assertEq(vester.getClaimableAmount(beneficiary1), expectedAmount);
        
        // After 100% of duration
        vm.warp(startTime + VESTING_DURATION);
        assertEq(vester.getClaimableAmount(beneficiary1), VESTING_AMOUNT);
        
        // After vesting period ends
        vm.warp(startTime + VESTING_DURATION + 1 days);
        assertEq(vester.getClaimableAmount(beneficiary1), VESTING_AMOUNT);
    }

    function testClaimPartialVesting() public {
        uint256 startTime = block.timestamp;
        
        vm.prank(owner);
        vester.createVestingSchedule(beneficiary1, VESTING_AMOUNT, startTime, VESTING_DURATION);
        
        // Claim after 25% of duration
        vm.warp(startTime + VESTING_DURATION / 4);
        uint256 expectedAmount = VESTING_AMOUNT / 4;
        
        vm.prank(beneficiary1);
        vm.expectEmit(true, false, false, true);
        emit TokensClaimed(beneficiary1, expectedAmount);
        vester.claim();
        
        assertEq(token.balanceOf(beneficiary1), expectedAmount);
        assertEq(vester.getClaimableAmount(beneficiary1), 0);
        
        TokenVester.VestingSchedule memory schedule = vester.getVestingSchedule(beneficiary1);
        assertEq(schedule.claimedAmount, expectedAmount);
    }

    function testClaimFullVesting() public {
        uint256 startTime = block.timestamp;
        
        vm.prank(owner);
        vester.createVestingSchedule(beneficiary1, VESTING_AMOUNT, startTime, VESTING_DURATION);
        
        // Claim after full duration
        vm.warp(startTime + VESTING_DURATION);
        
        vm.prank(beneficiary1);
        vester.claim();
        
        assertEq(token.balanceOf(beneficiary1), VESTING_AMOUNT);
        assertEq(vester.getClaimableAmount(beneficiary1), 0);
        
        TokenVester.VestingSchedule memory schedule = vester.getVestingSchedule(beneficiary1);
        assertEq(schedule.claimedAmount, VESTING_AMOUNT);
    }

    function testMultipleClaims() public {
        uint256 startTime = block.timestamp;
        
        vm.prank(owner);
        vester.createVestingSchedule(beneficiary1, VESTING_AMOUNT, startTime, VESTING_DURATION);
        
        // First claim after 25%
        vm.warp(startTime + VESTING_DURATION / 4);
        uint256 firstClaim = VESTING_AMOUNT / 4;
        
        vm.prank(beneficiary1);
        vester.claim();
        assertEq(token.balanceOf(beneficiary1), firstClaim);
        
        // Second claim after 50%
        vm.warp(startTime + VESTING_DURATION / 2);
        uint256 secondClaim = VESTING_AMOUNT / 4; // Additional 25%
        
        vm.prank(beneficiary1);
        vester.claim();
        assertEq(token.balanceOf(beneficiary1), firstClaim + secondClaim);
        
        // Third claim after 100%
        vm.warp(startTime + VESTING_DURATION);
        uint256 thirdClaim = VESTING_AMOUNT / 2; // Remaining 50%
        
        vm.prank(beneficiary1);
        vester.claim();
        assertEq(token.balanceOf(beneficiary1), VESTING_AMOUNT);
    }

    function testClaimNoVestingSchedule() public {
        vm.prank(beneficiary1);
        vm.expectRevert(TokenVester.NoVestingSchedule.selector);
        vester.claim();
    }

    function testClaimAfterRevocation() public {
        uint256 startTime = block.timestamp;
        
        vm.prank(owner);
        vester.createVestingSchedule(beneficiary1, VESTING_AMOUNT, startTime, VESTING_DURATION);
        
        vm.warp(startTime + VESTING_DURATION / 2);
        
        vm.prank(owner);
        vester.revokeVesting(beneficiary1);
        
        vm.prank(beneficiary1);
        vm.expectRevert(TokenVester.VestingAlreadyRevoked.selector);
        vester.claim();
    }

    function testRevokeVesting() public {
        uint256 startTime = block.timestamp;
        
        vm.prank(owner);
        vester.createVestingSchedule(beneficiary1, VESTING_AMOUNT, startTime, VESTING_DURATION);
        
        // Revoke after 50% of duration
        vm.warp(startTime + VESTING_DURATION / 2);
        uint256 vestedAmount = VESTING_AMOUNT / 2;
        uint256 unvestedAmount = VESTING_AMOUNT - vestedAmount;
        
        uint256 ownerBalanceBefore = token.balanceOf(owner);
        
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit VestingRevoked(beneficiary1, unvestedAmount);
        vester.revokeVesting(beneficiary1);
        
        // Check beneficiary received vested tokens
        assertEq(token.balanceOf(beneficiary1), vestedAmount);
        
        // Check owner received unvested tokens
        assertEq(token.balanceOf(owner), ownerBalanceBefore + unvestedAmount);
        
        // Check schedule is marked as revoked
        TokenVester.VestingSchedule memory schedule = vester.getVestingSchedule(beneficiary1);
        assertTrue(schedule.revoked);
        assertEq(schedule.claimedAmount, vestedAmount);
    }

    function testRevokeVestingOnlyOwner() public {
        uint256 startTime = block.timestamp;
        
        vm.prank(owner);
        vester.createVestingSchedule(beneficiary1, VESTING_AMOUNT, startTime, VESTING_DURATION);
        
        vm.prank(beneficiary1);
        vm.expectRevert();
        vester.revokeVesting(beneficiary1);
    }

    function testRevokeNonExistentVesting() public {
        vm.prank(owner);
        vm.expectRevert(TokenVester.NoVestingSchedule.selector);
        vester.revokeVesting(beneficiary1);
    }

    function testMultipleBeneficiaries() public {
        uint256 startTime = block.timestamp;
        
        vm.startPrank(owner);
        vester.createVestingSchedule(beneficiary1, VESTING_AMOUNT, startTime, VESTING_DURATION);
        vester.createVestingSchedule(beneficiary2, VESTING_AMOUNT / 2, startTime, VESTING_DURATION / 2);
        vm.stopPrank();
        
        // Test independent vesting
        vm.warp(startTime + VESTING_DURATION / 4);
        
        // Beneficiary1: 25% of VESTING_AMOUNT
        assertEq(vester.getClaimableAmount(beneficiary1), VESTING_AMOUNT / 4);
        
        // Beneficiary2: 50% of (VESTING_AMOUNT / 2) since duration is half
        assertEq(vester.getClaimableAmount(beneficiary2), VESTING_AMOUNT / 4);
        
        // Claim for beneficiary1
        vm.prank(beneficiary1);
        vester.claim();
        assertEq(token.balanceOf(beneficiary1), VESTING_AMOUNT / 4);
        
        // Beneficiary2's claimable amount should remain unchanged
        assertEq(vester.getClaimableAmount(beneficiary2), VESTING_AMOUNT / 4);
    }

    function testWithdrawExcessTokens() public {
        uint256 excessAmount = 1000 * 10**18;
        uint256 ownerBalanceBefore = token.balanceOf(owner);
        
        vm.prank(owner);
        vester.withdrawExcessTokens(excessAmount);
        
        assertEq(token.balanceOf(owner), ownerBalanceBefore + excessAmount);
        assertEq(token.balanceOf(address(vester)), TOTAL_SUPPLY - excessAmount);
    }

    function testWithdrawExcessTokensOnlyOwner() public {
        vm.prank(beneficiary1);
        vm.expectRevert();
        vester.withdrawExcessTokens(1000 * 10**18);
    }

    function testGetClaimableAmountNoVesting() public {
        assertEq(vester.getClaimableAmount(beneficiary1), 0);
    }

    function testGetClaimableAmountRevokedVesting() public {
        uint256 startTime = block.timestamp;
        
        vm.prank(owner);
        vester.createVestingSchedule(beneficiary1, VESTING_AMOUNT, startTime, VESTING_DURATION);
        
        vm.prank(owner);
        vester.revokeVesting(beneficiary1);
        
        assertEq(vester.getClaimableAmount(beneficiary1), 0);
    }

    function testReentrancyProtection() public {
        // Create separate test with malicious token
        vm.startPrank(owner);
        MaliciousToken maliciousToken = new MaliciousToken(TOTAL_SUPPLY);
        TokenVester maliciousVester = new TokenVester(maliciousToken, owner);
        
        // Transfer tokens to vester
        maliciousToken.transfer(address(maliciousVester), TOTAL_SUPPLY);
        
        uint256 startTime = block.timestamp;
        
        // Deploy attacker contract
        ReentrancyAttacker attacker = new ReentrancyAttacker(maliciousVester);
        
        // Setup malicious token
        maliciousToken.setAttacker(address(attacker));
        maliciousToken.enableReentrancy();
        
        maliciousVester.createVestingSchedule(address(attacker), VESTING_AMOUNT, startTime, VESTING_DURATION);
        vm.stopPrank();
        
        vm.warp(startTime + VESTING_DURATION / 2);
        
        // Attempt reentrancy attack - should fail due to ReentrancyGuard
        vm.expectRevert();
        attacker.attack();
    }

    function testFuzzVestingCalculation(uint256 totalAmount, uint256 duration, uint256 timeElapsed) public {
        totalAmount = bound(totalAmount, 1e18, 1e27); // 1 to 1B tokens
        duration = bound(duration, 1 days, 10 * 365 days); // 1 day to 10 years
        timeElapsed = bound(timeElapsed, 0, duration * 2); // 0 to 2x duration
        
        uint256 startTime = block.timestamp;
        
        // Mint enough tokens for the test
        vm.prank(owner);
        token.mint(address(vester), totalAmount);
        
        vm.prank(owner);
        vester.createVestingSchedule(beneficiary1, totalAmount, startTime, duration);
        
        vm.warp(startTime + timeElapsed);
        
        uint256 claimableAmount = vester.getClaimableAmount(beneficiary1);
        
        if (timeElapsed >= duration) {
            assertEq(claimableAmount, totalAmount);
        } else {
            uint256 expectedAmount = (totalAmount * timeElapsed) / duration;
            assertEq(claimableAmount, expectedAmount);
        }
        
        // Test that claimable amount is never more than total amount
        assertLe(claimableAmount, totalAmount);
    }
}