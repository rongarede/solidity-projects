// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {VotingToken} from "../src/contracts/VotingToken.sol";
import {Bank} from "../src/contracts/Bank.sol";
import {Gov} from "../src/contracts/Gov.sol";

/**
 * @title Integration Test
 * @dev End-to-end testing of the complete DAO Bank system
 * Tests the full proposal lifecycle from creation to execution
 */
contract IntegrationTest is Test {
    VotingToken public token;
    Bank public bank;
    Gov public gov;
    
    address public deployer;
    address public alice;
    address public bob;
    address public charlie;
    address public dave;
    address public recipient;

    function setUp() public {
        deployer = makeAddr("deployer");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");
        dave = makeAddr("dave");
        recipient = makeAddr("recipient");

        // Deploy the system as deployer
        vm.startPrank(deployer);
        
        // 1. Deploy VotingToken
        token = new VotingToken("DAO Bank Token", "DBT", deployer);
        
        // 2. Deploy Bank with deployer as initial admin
        bank = new Bank(deployer);
        
        // 3. Deploy Gov with token and bank addresses
        gov = new Gov(address(token), payable(address(bank)));
        
        // 4. Set Gov as Bank admin (transfer ownership to DAO)
        bank.changeAdmin(address(gov));
        
        // 5. Distribute initial tokens to create a realistic DAO
        token.transfer(alice, 200_000 * 10**18);    // 20% - Major stakeholder
        token.transfer(bob, 150_000 * 10**18);      // 15% - Major stakeholder  
        token.transfer(charlie, 100_000 * 10**18);  // 10% - Medium stakeholder
        token.transfer(dave, 50_000 * 10**18);      // 5%  - Small stakeholder
        // Deployer keeps 500_000 tokens (50%)
        
        vm.stopPrank();
        
        // All token holders delegate to themselves for voting
        vm.prank(alice);
        token.delegate(alice);
        
        vm.prank(bob);
        token.delegate(bob);
        
        vm.prank(charlie);
        token.delegate(charlie);
        
        vm.prank(dave);
        token.delegate(dave);
        
        vm.prank(deployer);
        token.delegate(deployer);
        
        // Fund accounts with ETH and deposit into bank
        vm.deal(alice, 20 ether);
        vm.deal(bob, 15 ether);
        vm.deal(charlie, 10 ether);
        
        vm.prank(alice);
        bank.deposit{value: 10 ether}();
        
        vm.prank(bob);
        bank.deposit{value: 8 ether}();
        
        vm.prank(charlie);
        bank.deposit{value: 5 ether}();
        
        // Bank should now have 23 ETH total
        assertEq(bank.getBalance(), 23 ether);
    }

    function test_CompleteProposalLifecycle() public {
        // === STEP 1: PROPOSAL CREATION ===
        console.log("=== STEP 1: PROPOSAL CREATION ===");
        
        bytes memory data = abi.encodeWithSignature("withdraw(address,uint256)", recipient, 5 ether);
        
        vm.prank(alice);
        uint256 proposalId = gov.propose(
            address(bank), 
            0, 
            data, 
            "Treasury allocation: 5 ETH for development costs"
        );
        
        console.log("Proposal created with ID:", proposalId);
        assertEq(proposalId, 1);
        assertEq(uint(gov.state(proposalId)), uint(Gov.ProposalState.Pending));
        
        // === STEP 2: WAITING PERIOD ===
        console.log("=== STEP 2: WAITING PERIOD (1 day) ===");
        
        // Fast forward to voting period (1 day delay)
        vm.roll(block.number + 7201); // ~1 day in blocks
        assertEq(uint(gov.state(proposalId)), uint(Gov.ProposalState.Active));
        console.log("Proposal is now active for voting");
        
        // === STEP 3: VOTING PERIOD ===
        console.log("=== STEP 3: VOTING PERIOD ===");
        
        // Check voting power before voting
        uint256 aliceVotes = token.getVotes(alice);
        uint256 bobVotes = token.getVotes(bob);
        uint256 charlieVotes = token.getVotes(charlie);
        uint256 daveVotes = token.getVotes(dave);
        
        console.log("Alice voting power:", aliceVotes / 10**18);
        console.log("Bob voting power:", bobVotes / 10**18);
        console.log("Charlie voting power:", charlieVotes / 10**18);
        console.log("Dave voting power:", daveVotes / 10**18);
        
        // Cast votes - majority in favor
        vm.prank(alice);
        gov.castVote(proposalId, Gov.VoteType.For, "Supporting development funding");
        
        vm.prank(bob);
        gov.castVote(proposalId, Gov.VoteType.For, "Good use of treasury funds");
        
        vm.prank(charlie);
        gov.castVote(proposalId, Gov.VoteType.Against, "Amount too high");
        
        vm.prank(dave);
        gov.castVote(proposalId, Gov.VoteType.Abstain, "Neutral on this proposal");
        
        // Check vote tallies
        Gov.Proposal memory proposal = gov.getProposal(proposalId);
        console.log("For votes:", proposal.forVotes / 10**18);
        console.log("Against votes:", proposal.againstVotes / 10**18);
        console.log("Abstain votes:", proposal.abstainVotes / 10**18);
        
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;
        uint256 quorum = gov.getQuorum();
        console.log("Total votes:", totalVotes / 10**18);
        console.log("Required quorum:", quorum / 10**18);
        
        // === STEP 4: VOTING ENDS - CHECK OUTCOME ===
        console.log("=== STEP 4: VOTING ENDS ===");
        
        // Fast forward past voting period (3 days)
        vm.roll(block.number + 21601);
        
        Gov.ProposalState finalState = gov.state(proposalId);
        console.log("Final proposal state:", uint(finalState));
        assertEq(uint(finalState), uint(Gov.ProposalState.Succeeded));
        console.log("Proposal succeeded!");
        
        // === STEP 5: QUEUE PROPOSAL ===
        console.log("=== STEP 5: QUEUE PROPOSAL ===");
        
        gov.queue(proposalId);
        assertEq(uint(gov.state(proposalId)), uint(Gov.ProposalState.Queued));
        console.log("Proposal queued for execution");
        
        // === STEP 6: EXECUTION DELAY ===
        console.log("=== STEP 6: EXECUTION DELAY (2 days) ===");
        
        // Fast forward past execution delay (2 days)
        vm.warp(block.timestamp + 2 days + 1);
        console.log("Execution delay period passed");
        
        // === STEP 7: EXECUTE PROPOSAL ===
        console.log("=== STEP 7: EXECUTE PROPOSAL ===");
        
        uint256 recipientBalanceBefore = recipient.balance;
        uint256 bankBalanceBefore = bank.getBalance();
        
        console.log("Recipient balance before:", recipientBalanceBefore);
        console.log("Bank balance before:", bankBalanceBefore / 10**18, "ETH");
        
        gov.execute(proposalId);
        
        uint256 recipientBalanceAfter = recipient.balance;
        uint256 bankBalanceAfter = bank.getBalance();
        
        console.log("Recipient balance after:", recipientBalanceAfter / 10**18, "ETH");
        console.log("Bank balance after:", bankBalanceAfter / 10**18, "ETH");
        
        // Verify execution
        assertEq(uint(gov.state(proposalId)), uint(Gov.ProposalState.Executed));
        assertEq(recipientBalanceAfter, recipientBalanceBefore + 5 ether);
        assertEq(bankBalanceAfter, bankBalanceBefore - 5 ether);
        
        console.log("=== PROPOSAL EXECUTION SUCCESSFUL ===");
        console.log("5 ETH successfully transferred from DAO treasury to recipient");
    }

    function test_ProposalRejectedByQuorum() public {
        // Create a user with tokens below quorum threshold
        address tinyVoter = makeAddr("tinyVoter");
        vm.prank(deployer);
        token.transfer(tinyVoter, 20_000 * 10**18); // 2% - below 4% quorum
        
        vm.prank(tinyVoter);
        token.delegate(tinyVoter);
        
        // Wait for delegation
        vm.roll(block.number + 1);
        
        bytes memory data = abi.encodeWithSignature("withdraw(address,uint256)", recipient, 10 ether);
        
        vm.prank(alice);
        uint256 proposalId = gov.propose(address(bank), 0, data, "Large withdrawal - 10 ETH");
        
        vm.roll(block.number + 7201);
        
        // Only tiny voter votes (below quorum threshold)
        vm.prank(tinyVoter);
        gov.castVote(proposalId, Gov.VoteType.For, "Supporting");
        
        vm.roll(block.number + 21601);
        
        assertEq(uint(gov.state(proposalId)), uint(Gov.ProposalState.Defeated));
        console.log("Proposal defeated due to insufficient quorum");
    }

    function test_ProposalRejectedByMajority() public {
        bytes memory data = abi.encodeWithSignature("withdraw(address,uint256)", recipient, 15 ether);
        
        vm.prank(alice);
        uint256 proposalId = gov.propose(address(bank), 0, data, "Excessive withdrawal - 15 ETH");
        
        vm.roll(block.number + 7201);
        
        // Majority votes against
        vm.prank(alice);
        gov.castVote(proposalId, Gov.VoteType.Against, "Too much");
        
        vm.prank(bob);
        gov.castVote(proposalId, Gov.VoteType.Against, "Excessive");
        
        vm.prank(charlie);
        gov.castVote(proposalId, Gov.VoteType.For, "I support it");
        
        vm.prank(dave);
        gov.castVote(proposalId, Gov.VoteType.For, "Good idea");
        
        vm.roll(block.number + 21601);
        
        assertEq(uint(gov.state(proposalId)), uint(Gov.ProposalState.Defeated));
        console.log("Proposal defeated by majority vote");
    }

    function test_MultipleConcurrentProposals() public {
        // Create multiple proposals
        bytes memory data1 = abi.encodeWithSignature("withdraw(address,uint256)", recipient, 2 ether);
        bytes memory data2 = abi.encodeWithSignature("withdraw(address,uint256)", alice, 3 ether);
        
        vm.prank(alice);
        uint256 proposal1 = gov.propose(address(bank), 0, data1, "Proposal 1: 2 ETH to recipient");
        
        vm.prank(bob);
        uint256 proposal2 = gov.propose(address(bank), 0, data2, "Proposal 2: 3 ETH to Alice");
        
        assertEq(proposal1, 1);
        assertEq(proposal2, 2);
        
        vm.roll(block.number + 7201);
        
        // Different voting patterns
        vm.prank(alice);
        gov.castVote(proposal1, Gov.VoteType.For, "");
        vm.prank(alice);
        gov.castVote(proposal2, Gov.VoteType.Against, "");
        
        vm.prank(bob);
        gov.castVote(proposal1, Gov.VoteType.Against, "");
        vm.prank(bob);
        gov.castVote(proposal2, Gov.VoteType.For, "");
        
        vm.prank(charlie);
        gov.castVote(proposal1, Gov.VoteType.For, "");
        vm.prank(charlie);
        gov.castVote(proposal2, Gov.VoteType.Against, "");
        
        vm.roll(block.number + 21601);
        
        // Both proposals should have different outcomes
        Gov.ProposalState state1 = gov.state(proposal1);
        Gov.ProposalState state2 = gov.state(proposal2);
        
        console.log("Proposal 1 state:", uint(state1));
        console.log("Proposal 2 state:", uint(state2));
        
        // At least one should succeed or fail based on voting
        assertTrue(uint(state1) != uint(state2) || uint(state1) == uint(Gov.ProposalState.Defeated));
    }

    function test_TokenTransferAffectsVotingPower() public {
        // Alice transfers some tokens to a new user before proposal
        address newUser = makeAddr("newUser");
        uint256 transferAmount = 50_000 * 10**18;
        
        vm.prank(alice);
        token.transfer(newUser, transferAmount);
        
        vm.prank(newUser);
        token.delegate(newUser);
        
        // Check voting power changed
        assertEq(token.getVotes(alice), 150_000 * 10**18); // 200k - 50k
        assertEq(token.getVotes(newUser), 50_000 * 10**18);
        
        // Create proposal and vote
        bytes memory data = abi.encodeWithSignature("withdraw(address,uint256)", recipient, 1 ether);
        
        vm.prank(alice);
        uint256 proposalId = gov.propose(address(bank), 0, data, "Test voting power");
        
        vm.roll(block.number + 7201);
        
        vm.prank(alice);
        gov.castVote(proposalId, Gov.VoteType.For, "");
        
        vm.prank(newUser);
        gov.castVote(proposalId, Gov.VoteType.Against, "");
        
        Gov.Proposal memory proposal = gov.getProposal(proposalId);
        assertEq(proposal.forVotes, 150_000 * 10**18);
        assertEq(proposal.againstVotes, 50_000 * 10**18);
    }

    function test_BankAdminOnlyAccessible() public {
        // Direct bank withdrawal should fail for non-admin
        vm.prank(alice);
        vm.expectRevert();
        bank.withdraw(alice, 1 ether);
        
        // Only Gov contract (the admin) can withdraw
        bytes memory data = abi.encodeWithSignature("withdraw(address,uint256)", recipient, 1 ether);
        
        vm.prank(alice);
        uint256 proposalId = gov.propose(address(bank), 0, data, "Authorized withdrawal");
        
        vm.roll(block.number + 7201);
        
        vm.prank(alice);
        gov.castVote(proposalId, Gov.VoteType.For, "");
        
        vm.prank(bob);
        gov.castVote(proposalId, Gov.VoteType.For, "");
        
        vm.roll(block.number + 21601);
        gov.queue(proposalId);
        
        vm.warp(block.timestamp + 2 days + 1);
        
        // This should succeed because it's executed through Gov
        uint256 balanceBefore = recipient.balance;
        gov.execute(proposalId);
        assertEq(recipient.balance, balanceBefore + 1 ether);
    }

    function test_ProposalThresholdEnforcement() public {
        // Deploy system requires 1% of tokens to propose
        uint256 threshold = gov.getProposalThreshold();
        assertEq(threshold, 10_000 * 10**18); // 1% of 1M tokens
        
        // Dave has 50k tokens (5%) - should be able to propose
        assertTrue(token.getVotes(dave) > threshold);
        
        // Create user with insufficient tokens
        address smallUser = makeAddr("smallUser");
        vm.prank(alice);
        token.transfer(smallUser, 5_000 * 10**18); // 0.5%
        
        vm.prank(smallUser);
        token.delegate(smallUser);
        
        assertTrue(token.getVotes(smallUser) < threshold);
        
        bytes memory data = abi.encodeWithSignature("withdraw(address,uint256)", recipient, 1 ether);
        
        vm.prank(smallUser);
        vm.expectRevert("Gov: Proposer votes below proposal threshold");
        gov.propose(address(bank), 0, data, "Should fail");
    }

    function test_FullSystemStressTest() public {
        console.log("=== FULL SYSTEM STRESS TEST ===");
        
        // Create multiple users and distribute tokens
        address[] memory users = new address[](5);
        for (uint i = 0; i < 5; i++) {
            users[i] = makeAddr(string(abi.encodePacked("user", i)));
            vm.prank(deployer);
            token.transfer(users[i], 20_000 * 10**18);
            vm.prank(users[i]);
            token.delegate(users[i]);
            
            // Each user deposits some ETH
            vm.deal(users[i], 5 ether);
            vm.prank(users[i]);
            bank.deposit{value: 2 ether}();
        }
        
        console.log("Bank total balance:", bank.getBalance() / 10**18, "ETH");
        
        // Create multiple proposals simultaneously
        uint256[] memory proposals = new uint256[](3);
        
        bytes memory data1 = abi.encodeWithSignature("withdraw(address,uint256)", users[0], 5 ether);
        bytes memory data2 = abi.encodeWithSignature("withdraw(address,uint256)", users[1], 3 ether);
        bytes memory data3 = abi.encodeWithSignature("withdraw(address,uint256)", users[2], 2 ether);
        
        vm.prank(alice);
        proposals[0] = gov.propose(address(bank), 0, data1, "Proposal A: 5 ETH");
        
        vm.prank(bob);
        proposals[1] = gov.propose(address(bank), 0, data2, "Proposal B: 3 ETH");
        
        vm.prank(charlie);
        proposals[2] = gov.propose(address(bank), 0, data3, "Proposal C: 2 ETH");
        
        // Move to voting period
        vm.roll(block.number + 7201);
        
        // Complex voting patterns
        for (uint i = 0; i < proposals.length; i++) {
            // Major stakeholders vote
            vm.prank(alice);
            gov.castVote(proposals[i], i % 2 == 0 ? Gov.VoteType.For : Gov.VoteType.Against, "Alice vote");
            
            vm.prank(bob);
            gov.castVote(proposals[i], i % 3 == 0 ? Gov.VoteType.For : Gov.VoteType.Against, "Bob vote");
            
            vm.prank(charlie);
            gov.castVote(proposals[i], Gov.VoteType.For, "Charlie vote");
            
            // New users vote
            for (uint j = 0; j < 3; j++) {
                vm.prank(users[j]);
                gov.castVote(proposals[i], Gov.VoteType.For, "User vote");
            }
        }
        
        // End voting period
        vm.roll(block.number + 21601);
        
        // Check which proposals succeeded
        uint256 succeededCount = 0;
        for (uint i = 0; i < proposals.length; i++) {
            if (uint(gov.state(proposals[i])) == uint(Gov.ProposalState.Succeeded)) {
                succeededCount++;
                console.log("Proposal", i, "succeeded");
            } else {
                console.log("Proposal", i, "failed");
            }
        }
        
        console.log("Total succeeded proposals:", succeededCount);
        assertTrue(succeededCount > 0); // At least one should succeed given voting patterns
    }
}