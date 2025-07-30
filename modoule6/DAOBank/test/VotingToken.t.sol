// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {VotingToken} from "../src/contracts/VotingToken.sol";

contract VotingTokenTest is Test {
    VotingToken public token;
    address public owner;
    address public alice;
    address public bob;
    address public charlie;

    function setUp() public {
        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        vm.prank(owner);
        token = new VotingToken("DAO Token", "DAO", owner);
    }

    function test_InitialState() public view {
        assertEq(token.name(), "DAO Token");
        assertEq(token.symbol(), "DAO");
        assertEq(token.totalSupply(), 1_000_000 * 10**18);
        assertEq(token.balanceOf(owner), 1_000_000 * 10**18);
        assertEq(token.owner(), owner);
    }

    function test_Transfer() public {
        uint256 amount = 1000 * 10**18;
        
        vm.prank(owner);
        token.transfer(alice, amount);
        
        assertEq(token.balanceOf(alice), amount);
        assertEq(token.balanceOf(owner), 1_000_000 * 10**18 - amount);
    }

    function test_Delegation() public {
        uint256 amount = 1000 * 10**18;
        
        // Transfer tokens to Alice
        vm.prank(owner);
        token.transfer(alice, amount);
        
        assertEq(token.getVotes(alice), 0); // No votes initially (no delegation)
        
        // Alice delegates to herself
        vm.prank(alice);
        token.delegate(alice);
        
        assertEq(token.getVotes(alice), amount);
        assertEq(token.getCurrentVotes(alice), amount);
    }

    function test_DelegationToOther() public {
        uint256 amount = 1000 * 10**18;
        
        // Transfer tokens to Alice
        vm.prank(owner);
        token.transfer(alice, amount);
        
        // Alice delegates to Bob
        vm.prank(alice);
        token.delegate(bob);
        
        assertEq(token.getVotes(alice), 0);
        assertEq(token.getVotes(bob), amount);
        assertEq(token.getCurrentVotes(bob), amount);
    }

    function test_HistoricalVotes() public {
        uint256 amount = 1000 * 10**18;
        
        // Transfer and delegate at block N
        vm.prank(owner);
        token.transfer(alice, amount);
        
        vm.prank(alice);
        token.delegate(alice);
        
        uint256 blockNumber = block.number;
        
        // Roll forward and check historical votes (need to go at least 1 block ahead)
        vm.roll(block.number + 100);
        
        assertEq(token.getPastVotes(alice, blockNumber - 1), amount);
        assertEq(token.getPriorVotes(alice, blockNumber - 1), amount);
    }

    function test_Mint() public {
        uint256 amount = 500 * 10**18;
        uint256 initialSupply = token.totalSupply();
        
        vm.prank(owner);
        token.mint(alice, amount);
        
        assertEq(token.balanceOf(alice), amount);
        assertEq(token.totalSupply(), initialSupply + amount);
    }

    function test_MintOnlyOwner() public {
        uint256 amount = 500 * 10**18;
        
        vm.prank(alice);
        vm.expectRevert();
        token.mint(alice, amount);
    }

    function test_Burn() public {
        uint256 amount = 500 * 10**18;
        uint256 initialSupply = token.totalSupply();
        
        // First transfer some tokens to alice
        vm.prank(owner);
        token.transfer(alice, amount);
        
        // Then burn them
        vm.prank(owner);
        token.burn(alice, amount);
        
        assertEq(token.balanceOf(alice), 0);
        assertEq(token.totalSupply(), initialSupply - amount);
    }

    function test_BurnOnlyOwner() public {
        uint256 amount = 500 * 10**18;
        
        vm.prank(owner);
        token.transfer(alice, amount);
        
        vm.prank(alice);
        vm.expectRevert();
        token.burn(alice, amount);
    }

    function test_VotingPowerAfterTransfer() public {
        uint256 amount = 1000 * 10**18;
        
        // Alice gets tokens and delegates to herself
        vm.prank(owner);
        token.transfer(alice, amount);
        
        vm.prank(alice);
        token.delegate(alice);
        
        assertEq(token.getVotes(alice), amount);
        
        // Alice transfers half to Bob
        vm.prank(alice);
        token.transfer(bob, amount / 2);
        
        // Alice should have half the voting power now
        assertEq(token.getVotes(alice), amount / 2);
        assertEq(token.getVotes(bob), 0); // Bob hasn't delegated
        
        // Bob delegates to himself
        vm.prank(bob);
        token.delegate(bob);
        
        assertEq(token.getVotes(bob), amount / 2);
    }

    function test_MultipleDelegations() public {
        uint256 amount = 1000 * 10**18;
        
        // Distribute tokens
        vm.startPrank(owner);
        token.transfer(alice, amount);
        token.transfer(bob, amount);
        token.transfer(charlie, amount);
        vm.stopPrank();
        
        // Everyone delegates to Alice
        vm.prank(alice);
        token.delegate(alice);
        
        vm.prank(bob);
        token.delegate(alice);
        
        vm.prank(charlie);
        token.delegate(alice);
        
        // Alice should have 3x the voting power
        assertEq(token.getVotes(alice), amount * 3);
    }

    function test_Redelegation() public {
        uint256 amount = 1000 * 10**18;
        
        vm.prank(owner);
        token.transfer(alice, amount);
        
        // Alice delegates to Bob
        vm.prank(alice);
        token.delegate(bob);
        
        assertEq(token.getVotes(bob), amount);
        assertEq(token.getVotes(charlie), 0);
        
        // Alice redelegates to Charlie
        vm.prank(alice);
        token.delegate(charlie);
        
        assertEq(token.getVotes(bob), 0);
        assertEq(token.getVotes(charlie), amount);
    }
}