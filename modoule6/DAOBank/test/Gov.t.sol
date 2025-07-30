// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {VotingToken} from "../src/contracts/VotingToken.sol";
import {Bank} from "../src/contracts/Bank.sol";
import {Gov} from "../src/contracts/Gov.sol";

contract GovTest is Test {
    VotingToken public token;
    Bank public bank;
    Gov public gov;
    
    address public owner;
    address public alice;
    address public bob;
    address public charlie;
    address public recipient;

    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        address target,
        uint256 value,
        string description,
        uint256 startBlock,
        uint256 endBlock
    );
    event VoteCast(
        address indexed voter,
        uint256 indexed proposalId,
        Gov.VoteType support,
        uint256 votes,
        string reason
    );
    event ProposalQueued(uint256 indexed proposalId, uint256 queueTime);
    event ProposalExecuted(uint256 indexed proposalId);

    function setUp() public {
        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");
        recipient = makeAddr("recipient");

        // Deploy contracts
        vm.prank(owner);
        token = new VotingToken("DAO Token", "DAO", owner);
        
        vm.prank(owner);
        bank = new Bank(owner);
        
        vm.prank(owner);
        gov = new Gov(address(token), payable(address(bank)));
        
        // Set Gov as bank admin
        vm.prank(owner);
        bank.changeAdmin(address(gov));
        
        // Distribute tokens and delegate voting power
        vm.startPrank(owner);
        token.transfer(alice, 150_000 * 10**18);   // 15% - Above proposal threshold
        token.transfer(bob, 100_000 * 10**18);     // 10%
        token.transfer(charlie, 50_000 * 10**18);  // 5%
        vm.stopPrank();
        
        // Delegate voting power
        vm.prank(alice);
        token.delegate(alice);
        
        vm.prank(bob);
        token.delegate(bob);
        
        vm.prank(charlie);
        token.delegate(charlie);
        
        // Fund the bank
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        bank.deposit{value: 5 ether}();
    }

    function test_InitialState() public view {
        assertEq(address(gov.votingToken()), address(token));
        assertEq(address(gov.bank()), address(bank));
        assertEq(gov.proposalCount(), 0);
        assertEq(gov.getProposalThreshold(), 10_000 * 10**18); // 1% of 1M tokens
        assertEq(gov.getQuorum(), 40_000 * 10**18); // 4% of 1M tokens
    }

    function test_CreateProposal() public {
        bytes memory data = abi.encodeWithSignature("withdraw(address,uint256)", recipient, 1 ether);
        
        vm.expectEmit(true, true, false, false);
        emit ProposalCreated(1, alice, address(bank), 0, "Withdraw 1 ETH", 0, 0);
        
        vm.prank(alice);
        uint256 proposalId = gov.propose(address(bank), 0, data, "Withdraw 1 ETH");
        
        assertEq(proposalId, 1);
        assertEq(gov.proposalCount(), 1);
        
        Gov.Proposal memory proposal = gov.getProposal(proposalId);
        assertEq(proposal.proposer, alice);
        assertEq(proposal.target, address(bank));
        assertEq(proposal.value, 0);
        assertEq(proposal.description, "Withdraw 1 ETH");
        assertEq(uint(gov.state(proposalId)), uint(Gov.ProposalState.Pending));
    }

    function test_CreateProposalBelowThreshold() public {
        // Create a user with insufficient tokens
        address lowTokenUser = makeAddr("lowTokenUser");
        vm.prank(owner);
        token.transfer(lowTokenUser, 5_000 * 10**18); // Only 0.5%
        
        vm.prank(lowTokenUser);
        token.delegate(lowTokenUser);
        
        bytes memory data = abi.encodeWithSignature("withdraw(address,uint256)", recipient, 1 ether);
        
        vm.prank(lowTokenUser);
        vm.expectRevert("Gov: Proposer votes below proposal threshold");
        gov.propose(address(bank), 0, data, "Withdraw 1 ETH");
    }

    function test_CreateProposalInvalidTarget() public {
        bytes memory data = abi.encodeWithSignature("withdraw(address,uint256)", recipient, 1 ether);
        
        vm.prank(alice);
        vm.expectRevert("Gov: Target cannot be zero address");
        gov.propose(address(0), 0, data, "Withdraw 1 ETH");
    }

    function test_CreateProposalEmptyDescription() public {
        bytes memory data = abi.encodeWithSignature("withdraw(address,uint256)", recipient, 1 ether);
        
        vm.prank(alice);
        vm.expectRevert("Gov: Description cannot be empty");
        gov.propose(address(bank), 0, data, "");
    }

    function test_VotingFlow() public {
        bytes memory data = abi.encodeWithSignature("withdraw(address,uint256)", recipient, 1 ether);
        
        vm.prank(alice);
        uint256 proposalId = gov.propose(address(bank), 0, data, "Withdraw 1 ETH");
        
        // Fast forward to voting period
        vm.roll(block.number + 7201); // ~1 day in blocks
        assertEq(uint(gov.state(proposalId)), uint(Gov.ProposalState.Active));
        
        // Cast votes
        vm.expectEmit(true, true, false, false);
        emit VoteCast(alice, proposalId, Gov.VoteType.For, 150_000 * 10**18, "Supporting the proposal");
        
        vm.prank(alice);
        gov.castVote(proposalId, Gov.VoteType.For, "Supporting the proposal");
        
        vm.prank(bob);
        gov.castVote(proposalId, Gov.VoteType.For, "I agree");
        
        vm.prank(charlie);
        gov.castVote(proposalId, Gov.VoteType.Against, "Not convinced");
        
        // Check vote receipts
        Gov.Receipt memory aliceReceipt = gov.getReceipt(proposalId, alice);
        assertEq(aliceReceipt.hasVoted, true);
        assertEq(uint(aliceReceipt.support), uint(Gov.VoteType.For));
        assertEq(aliceReceipt.votes, 150_000 * 10**18);
        
        // Check proposal votes
        Gov.Proposal memory proposal = gov.getProposal(proposalId);
        assertEq(proposal.forVotes, 250_000 * 10**18); // Alice + Bob
        assertEq(proposal.againstVotes, 50_000 * 10**18); // Charlie
    }

    function test_DoubleVoting() public {
        bytes memory data = abi.encodeWithSignature("withdraw(address,uint256)", recipient, 1 ether);
        
        vm.prank(alice);
        uint256 proposalId = gov.propose(address(bank), 0, data, "Withdraw 1 ETH");
        
        vm.roll(block.number + 7201);
        
        vm.prank(alice);
        gov.castVote(proposalId, Gov.VoteType.For, "First vote");
        
        vm.prank(alice);
        vm.expectRevert("Gov: Voter has already voted");
        gov.castVote(proposalId, Gov.VoteType.Against, "Second vote");
    }

    function test_VoteWithoutVotingPower() public {
        address noTokens = makeAddr("noTokens");
        
        bytes memory data = abi.encodeWithSignature("withdraw(address,uint256)", recipient, 1 ether);
        
        vm.prank(alice);
        uint256 proposalId = gov.propose(address(bank), 0, data, "Withdraw 1 ETH");
        
        vm.roll(block.number + 7201);
        
        vm.prank(noTokens);
        vm.expectRevert("Gov: Voter has no voting power");
        gov.castVote(proposalId, Gov.VoteType.For, "No power");
    }

    function test_ProposalSucceeded() public {
        bytes memory data = abi.encodeWithSignature("withdraw(address,uint256)", recipient, 1 ether);
        
        vm.prank(alice);
        uint256 proposalId = gov.propose(address(bank), 0, data, "Withdraw 1 ETH");
        
        vm.roll(block.number + 7201);
        
        // Vote with enough support to meet quorum and majority
        vm.prank(alice);
        gov.castVote(proposalId, Gov.VoteType.For, "");
        
        vm.prank(bob);
        gov.castVote(proposalId, Gov.VoteType.For, "");
        
        // Fast forward past voting period
        vm.roll(block.number + 21601); // ~3 days
        
        assertEq(uint(gov.state(proposalId)), uint(Gov.ProposalState.Succeeded));
    }

    function test_ProposalDefeatedByQuorum() public {
        // Create a small voter first and give them tokens
        address smallVoter = makeAddr("smallVoter");
        vm.prank(owner);
        token.transfer(smallVoter, 30_000 * 10**18); // 3% - below 4% quorum
        
        vm.prank(smallVoter);
        token.delegate(smallVoter);
        
        // Wait for delegation to take effect before creating proposal
        vm.roll(block.number + 1);
        
        bytes memory data = abi.encodeWithSignature("withdraw(address,uint256)", recipient, 1 ether);
        
        vm.prank(alice);
        uint256 proposalId = gov.propose(address(bank), 0, data, "Withdraw 1 ETH");
        
        vm.roll(block.number + 7201);
        
        // Only small voter votes - not enough for quorum
        vm.prank(smallVoter);
        gov.castVote(proposalId, Gov.VoteType.For, "");
        
        vm.roll(block.number + 21600); // End voting period
        
        assertEq(uint(gov.state(proposalId)), uint(Gov.ProposalState.Defeated));
    }

    function test_ProposalDefeatedByMajority() public {
        bytes memory data = abi.encodeWithSignature("withdraw(address,uint256)", recipient, 1 ether);
        
        vm.prank(alice);
        uint256 proposalId = gov.propose(address(bank), 0, data, "Withdraw 1 ETH");
        
        vm.roll(block.number + 7201);
        
        // Majority votes against
        vm.prank(alice);
        gov.castVote(proposalId, Gov.VoteType.Against, "");
        
        vm.prank(bob);
        gov.castVote(proposalId, Gov.VoteType.Against, "");
        
        vm.prank(charlie);
        gov.castVote(proposalId, Gov.VoteType.For, "");
        
        vm.roll(block.number + 21601);
        
        assertEq(uint(gov.state(proposalId)), uint(Gov.ProposalState.Defeated));
    }

    function test_QueueProposal() public {
        bytes memory data = abi.encodeWithSignature("withdraw(address,uint256)", recipient, 1 ether);
        
        vm.prank(alice);
        uint256 proposalId = gov.propose(address(bank), 0, data, "Withdraw 1 ETH");
        
        vm.roll(block.number + 7201);
        
        vm.prank(alice);
        gov.castVote(proposalId, Gov.VoteType.For, "");
        
        vm.prank(bob);
        gov.castVote(proposalId, Gov.VoteType.For, "");
        
        vm.roll(block.number + 21601);
        
        vm.expectEmit(true, false, false, false);
        emit ProposalQueued(proposalId, block.timestamp);
        
        gov.queue(proposalId);
        
        assertEq(uint(gov.state(proposalId)), uint(Gov.ProposalState.Queued));
    }

    function test_ExecuteProposal() public {
        bytes memory data = abi.encodeWithSignature("withdraw(address,uint256)", recipient, 1 ether);
        
        vm.prank(alice);
        uint256 proposalId = gov.propose(address(bank), 0, data, "Withdraw 1 ETH");
        
        vm.roll(block.number + 7201);
        
        vm.prank(alice);
        gov.castVote(proposalId, Gov.VoteType.For, "");
        
        vm.prank(bob);
        gov.castVote(proposalId, Gov.VoteType.For, "");
        
        vm.roll(block.number + 21601);
        
        gov.queue(proposalId);
        
        // Fast forward past execution delay
        vm.warp(block.timestamp + 2 days + 1);
        
        uint256 recipientBalanceBefore = recipient.balance;
        uint256 bankBalanceBefore = bank.getBalance();
        
        vm.expectEmit(true, false, false, false);
        emit ProposalExecuted(proposalId);
        
        gov.execute(proposalId);
        
        assertEq(uint(gov.state(proposalId)), uint(Gov.ProposalState.Executed));
        assertEq(recipient.balance, recipientBalanceBefore + 1 ether);
        assertEq(bank.getBalance(), bankBalanceBefore - 1 ether);
    }

    function test_ExecuteProposalBeforeDelay() public {
        bytes memory data = abi.encodeWithSignature("withdraw(address,uint256)", recipient, 1 ether);
        
        vm.prank(alice);
        uint256 proposalId = gov.propose(address(bank), 0, data, "Withdraw 1 ETH");
        
        vm.roll(block.number + 7201);
        
        vm.prank(alice);
        gov.castVote(proposalId, Gov.VoteType.For, "");
        
        vm.prank(bob);
        gov.castVote(proposalId, Gov.VoteType.For, "");
        
        vm.roll(block.number + 21601);
        
        gov.queue(proposalId);
        
        // Try to execute before delay
        vm.expectRevert("Gov: Execution delay not met");
        gov.execute(proposalId);
    }

    function test_CancelProposal() public {
        bytes memory data = abi.encodeWithSignature("withdraw(address,uint256)", recipient, 1 ether);
        
        vm.prank(alice);
        uint256 proposalId = gov.propose(address(bank), 0, data, "Withdraw 1 ETH");
        
        vm.expectEmit(true, false, false, false);
        emit Gov.ProposalCanceled(proposalId);
        
        vm.prank(alice);
        gov.cancel(proposalId);
        
        assertEq(uint(gov.state(proposalId)), uint(Gov.ProposalState.Canceled));
    }

    function test_CancelProposalOnlyProposer() public {
        bytes memory data = abi.encodeWithSignature("withdraw(address,uint256)", recipient, 1 ether);
        
        vm.prank(alice);
        uint256 proposalId = gov.propose(address(bank), 0, data, "Withdraw 1 ETH");
        
        vm.prank(bob);
        vm.expectRevert("Gov: Only proposer can cancel");
        gov.cancel(proposalId);
    }

    function test_InvalidProposalId() public {
        vm.expectRevert("Gov: Invalid proposal ID");
        gov.state(999);
    }

    // Fix the threshold test - Charlie actually has enough tokens
    function test_CreateProposalBelowThresholdFixed() public {
        // Create a user with insufficient tokens
        address lowTokenUser = makeAddr("lowTokenUser");
        vm.prank(owner);
        token.transfer(lowTokenUser, 5_000 * 10**18); // Only 0.5%
        
        vm.prank(lowTokenUser);
        token.delegate(lowTokenUser);
        
        bytes memory data = abi.encodeWithSignature("withdraw(address,uint256)", recipient, 1 ether);
        
        vm.prank(lowTokenUser);
        vm.expectRevert("Gov: Proposer votes below proposal threshold");
        gov.propose(address(bank), 0, data, "Withdraw 1 ETH");
    }
}