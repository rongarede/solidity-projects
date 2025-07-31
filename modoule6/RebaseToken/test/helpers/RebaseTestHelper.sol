// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/RebaseToken.sol";

contract RebaseTestHelper is Test {
    // 测试常量
    uint256 constant BLOCKS_PER_YEAR = 15_768_000;
    uint256 constant INITIAL_SUPPLY = 100_000_000 * 10**18;
    uint256 constant INDEX_PRECISION = 1e18;
    uint256 constant DEFLATION_RATE = 99 * 10**16;

    // 测试地址
    address public owner = address(this);
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    // 时间模拟辅助函数
    function advanceBlocks(uint256 blocks) public {
        vm.roll(block.number + blocks);
    }

    function advanceYears(uint256 yearsElapsed) public {
        advanceBlocks(yearsElapsed * BLOCKS_PER_YEAR);
    }

    function advanceHalfYear() public {
        advanceBlocks(BLOCKS_PER_YEAR / 2);
    }

    function advanceQuarterYear() public {
        advanceBlocks(BLOCKS_PER_YEAR / 4);
    }

    // 数学计算辅助函数
    function calculateExpectedIndex(uint256 yearsElapsed) public pure returns (uint256) {
        uint256 result = INDEX_PRECISION;
        for (uint i = 0; i < yearsElapsed; i++) {
            result = result * DEFLATION_RATE / 1e18;
        }
        return result;
    }

    function calculateExpectedBalance(uint256 initialBalance, uint256 yearsElapsed) public pure returns (uint256) {
        uint256 expectedIndex = calculateExpectedIndex(yearsElapsed);
        return initialBalance * expectedIndex / INDEX_PRECISION;
    }

    // 精度验证函数
    function assertApproxEq(uint256 actual, uint256 expected, string memory message) public {
        if (expected == 0) {
            assertEq(actual, expected, message);
            return;
        }
        
        uint256 diff = actual > expected ? actual - expected : expected - actual;
        uint256 tolerance = expected * 1e15 / 1e18; // 0.1% tolerance
        
        assertLe(diff, tolerance, message);
    }

    // 部署辅助函数
    function deployRebaseToken() public returns (RebaseToken) {
        return new RebaseToken("Rebase Token", "RBT", 18);
    }

    // 状态获取辅助函数
    function getTokenState(RebaseToken token) public view returns (
        uint256 currentIndex,
        uint256 lastRebaseBlock,
        uint256 totalSupply,
        uint256 totalShares,
        uint256 blocksUntilNextRebase
    ) {
        currentIndex = token.index();
        lastRebaseBlock = token.lastRebaseBlock();
        totalSupply = token.totalSupply();
        totalShares = token.totalShares();
        
        (,, blocksUntilNextRebase) = token.getRebaseInfo();
    }

    // 批量转账辅助函数
    function setupMultiUserScenario(RebaseToken token) public {
        // 给多个用户分配初始余额
        uint256 aliceAmount = INITIAL_SUPPLY / 4;
        uint256 bobAmount = INITIAL_SUPPLY / 3;
        uint256 charlieAmount = INITIAL_SUPPLY / 5;
        
        token.transfer(alice, aliceAmount);
        token.transfer(bob, bobAmount);
        token.transfer(charlie, charlieAmount);
    }

    // 批量授权辅助函数
    function setupAllowanceScenario(RebaseToken token) public {
        token.approve(alice, type(uint256).max / 2);
        token.approve(bob, 1000 * 10**18);
        token.approve(charlie, 500 * 10**18);
    }
}