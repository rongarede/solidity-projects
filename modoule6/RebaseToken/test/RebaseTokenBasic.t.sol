// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/RebaseToken.sol";

contract RebaseTokenBasicTest is Test {
    RebaseToken public token;
    address public owner = address(this);
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    
    uint256 constant INITIAL_SUPPLY = 100_000_000 * 10**18;
    uint256 constant BLOCKS_PER_YEAR = 15_768_000;
    uint256 constant INDEX_PRECISION = 1e18;

    function setUp() public {
        token = new RebaseToken("Rebase Token", "RBT", 18);
    }

    // Step 24: Basic functionality tests

    // Deployment and initialization test
    function testDeploymentAndInitialization() public {
        // Verify basic metadata
        assertEq(token.name(), "Rebase Token", "Token name should be correct");
        assertEq(token.symbol(), "RBT", "Token symbol should be correct");
        assertEq(token.decimals(), 18, "Decimals should be 18");
        
        // Verify initial supply
        assertEq(token.totalSupply(), INITIAL_SUPPLY, "Initial supply should be 100 million");
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY, "Deployer should hold all tokens");
        assertEq(token.sharesOf(owner), INITIAL_SUPPLY, "Deployer shares should be 100 million");
        assertEq(token.totalShares(), INITIAL_SUPPLY, "Total shares should be 100 million");
        
        // Verify rebase system initialization
        assertEq(token.index(), INDEX_PRECISION, "Initial index should be 1e18");
        assertEq(token.lastRebaseBlock(), block.number, "Initial rebase block should be current block");
    }

    // ERC20 standard functionality test
    function testERC20StandardFunctionality() public {
        // Transfer test
        uint256 transferAmount = 1000 * 10**18;
        assertTrue(token.transfer(alice, transferAmount), "Transfer should succeed");
        assertEq(token.balanceOf(alice), transferAmount, "Recipient balance should be correct");
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - transferAmount, "Sender balance should decrease");
        
        // Approval and transferFrom test
        uint256 approveAmount = 500 * 10**18;
        assertTrue(token.approve(alice, approveAmount), "Approval should succeed");
        assertEq(token.allowance(owner, alice), approveAmount, "Allowance should be correct");
        
        vm.prank(alice);
        assertTrue(token.transferFrom(owner, bob, approveAmount), "TransferFrom should succeed");
        assertEq(token.balanceOf(bob), approveAmount, "Recipient balance should be correct");
        assertEq(token.allowance(owner, alice), 0, "Allowance should be consumed");
    }

    // Shares/Amount conversion test
    function testSharesAndAmountConversion() public {
        // Initial state: 1:1 conversion
        uint256 testAmount = 1000 * 10**18;
        assertEq(token.getSharesByAmount(testAmount), testAmount, "Initial conversion should be 1:1");
        assertEq(token.getAmountByShares(testAmount), testAmount, "Initial conversion should be 1:1");
        
        // Conversion consistency test
        uint256[] memory amounts = new uint256[](5);
        amounts[0] = 1 * 10**18;
        amounts[1] = 100 * 10**18;
        amounts[2] = 10000 * 10**18;
        amounts[3] = 1000000 * 10**18;
        amounts[4] = 100000000 * 10**18;
        
        for (uint i = 0; i < amounts.length; i++) {
            uint256 shares = token.getSharesByAmount(amounts[i]);
            uint256 backToAmount = token.getAmountByShares(shares);
            assertEq(backToAmount, amounts[i], "Conversion should maintain consistency");
        }
    }

    // Zero value handling test
    function testZeroValueHandling() public {
        assertEq(token.getSharesByAmount(0), 0, "Zero amount should convert to zero shares");
        assertEq(token.getAmountByShares(0), 0, "Zero shares should convert to zero amount");
        
        assertTrue(token.transfer(alice, 0), "Zero amount transfer should succeed");
        assertTrue(token.approve(bob, 0), "Zero amount approval should succeed");
    }

    // Large amount handling test
    function testLargeAmountHandling() public {
        uint256 largeAmount = INITIAL_SUPPLY / 2;
        assertTrue(token.transfer(alice, largeAmount), "Large amount transfer should succeed");
        assertEq(token.balanceOf(alice), largeAmount, "Large amount balance should be correct");
        
        uint256 shares = token.getSharesByAmount(largeAmount);
        uint256 backToAmount = token.getAmountByShares(shares);
        assertEq(backToAmount, largeAmount, "Large amount conversion should maintain consistency");
    }
}