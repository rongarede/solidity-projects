// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./VotingToken.sol";
import "./Bank.sol";

/**
 * @title Gov
 * @dev DAO governance contract for managing proposals and voting
 * Features:
 * - Proposal creation with threshold requirements
 * - Token-weighted voting system
 * - Timelock mechanism for execution delay
 * - Quorum requirements
 * - Full proposal lifecycle management
 */
contract Gov is ReentrancyGuard {
    
    // Proposal states
    enum ProposalState {
        Pending,    // 0: Waiting for voting delay to pass
        Active,     // 1: Currently accepting votes
        Canceled,   // 2: Proposal was canceled
        Defeated,   // 3: Proposal failed (didn't meet quorum or majority voted against)
        Succeeded,  // 4: Proposal passed and ready to be queued
        Queued,     // 5: Proposal is queued for execution (timelock)
        Executed    // 6: Proposal has been executed
    }

    // Proposal structure
    struct Proposal {
        uint256 id;
        address proposer;
        address target;         // Address to call (Bank contract)
        uint256 value;          // ETH value to send
        bytes data;             // Function call data
        string description;     // Proposal description
        uint256 startBlock;     // Block when voting starts
        uint256 endBlock;       // Block when voting ends
        uint256 forVotes;       // Votes in favor
        uint256 againstVotes;   // Votes against
        uint256 abstainVotes;   // Abstain votes
        bool canceled;          // Whether proposal is canceled
        bool executed;          // Whether proposal is executed
        uint256 queueTime;      // Time when proposal was queued
    }

    // Vote choice
    enum VoteType {
        Against,    // 0
        For,        // 1
        Abstain     // 2
    }

    // Vote receipt
    struct Receipt {
        bool hasVoted;
        VoteType support;
        uint256 votes;
    }

    // State variables
    VotingToken public immutable votingToken;
    Bank public immutable bank;
    
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => Receipt)) public receipts;
    
    // Governance parameters (as specified in claude.md)
    uint256 public constant VOTING_DELAY = 1 days;         // 1 day
    uint256 public constant VOTING_PERIOD = 3 days;        // 3 days
    uint256 public constant EXECUTION_DELAY = 2 days;      // 2 days
    uint256 public constant PROPOSAL_THRESHOLD = 100;      // 1% of total supply (10,000 tokens)
    uint256 public constant QUORUM_PERCENTAGE = 4;         // 4% of total supply

    // Events
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
        VoteType support,
        uint256 votes,
        string reason
    );
    event ProposalCanceled(uint256 indexed proposalId);
    event ProposalQueued(uint256 indexed proposalId, uint256 queueTime);
    event ProposalExecuted(uint256 indexed proposalId);

    /**
     * @dev Contract constructor
     * @param _votingToken Address of the voting token contract
     * @param _bank Address of the bank contract
     */
    constructor(address _votingToken, address payable _bank) {
        require(_votingToken != address(0), "Gov: VotingToken cannot be zero address");
        require(_bank != address(0), "Gov: Bank cannot be zero address");
        
        votingToken = VotingToken(_votingToken);
        bank = Bank(_bank);
    }

    /**
     * @dev Create a new proposal
     * @param target Address to call (typically the Bank contract)
     * @param value ETH value to send with the call
     * @param data Encoded function call data
     * @param description Human readable description of the proposal
     * @return proposalId The ID of the created proposal
     */
    function propose(
        address target,
        uint256 value,
        bytes memory data,
        string memory description
    ) external returns (uint256 proposalId) {
        // Check proposal threshold
        uint256 proposerVotes = votingToken.getCurrentVotes(msg.sender);
        require(
            proposerVotes >= getProposalThreshold(),
            "Gov: Proposer votes below proposal threshold"
        );

        // Validate parameters
        require(target != address(0), "Gov: Target cannot be zero address");
        require(bytes(description).length > 0, "Gov: Description cannot be empty");

        proposalId = ++proposalCount;
        
        uint256 startBlock = block.number + (VOTING_DELAY / 12); // Approximate blocks (12 sec per block)
        uint256 endBlock = startBlock + (VOTING_PERIOD / 12);

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            target: target,
            value: value,
            data: data,
            description: description,
            startBlock: startBlock,
            endBlock: endBlock,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            canceled: false,
            executed: false,
            queueTime: 0
        });

        emit ProposalCreated(
            proposalId,
            msg.sender,
            target,
            value,
            description,
            startBlock,
            endBlock
        );
    }

    /**
     * @dev Cast a vote on a proposal
     * @param proposalId ID of the proposal to vote on
     * @param support Vote type (0=Against, 1=For, 2=Abstain)
     * @param reason Optional reason for the vote
     */
    function castVote(
        uint256 proposalId,
        VoteType support,
        string memory reason
    ) external {
        require(state(proposalId) == ProposalState.Active, "Gov: Voting is not active");
        
        Receipt storage receipt = receipts[proposalId][msg.sender];
        require(!receipt.hasVoted, "Gov: Voter has already voted");

        uint256 votes = votingToken.getPriorVotes(msg.sender, proposals[proposalId].startBlock - 1);
        require(votes > 0, "Gov: Voter has no voting power");

        if (support == VoteType.Against) {
            proposals[proposalId].againstVotes += votes;
        } else if (support == VoteType.For) {
            proposals[proposalId].forVotes += votes;
        } else {
            proposals[proposalId].abstainVotes += votes;
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        emit VoteCast(msg.sender, proposalId, support, votes, reason);
    }

    /**
     * @dev Queue a successful proposal for execution
     * @param proposalId ID of the proposal to queue
     */
    function queue(uint256 proposalId) external {
        require(state(proposalId) == ProposalState.Succeeded, "Gov: Proposal cannot be queued");
        
        proposals[proposalId].queueTime = block.timestamp;
        
        emit ProposalQueued(proposalId, block.timestamp);
    }

    /**
     * @dev Execute a queued proposal
     * @param proposalId ID of the proposal to execute
     */
    function execute(uint256 proposalId) external payable nonReentrant {
        require(state(proposalId) == ProposalState.Queued, "Gov: Proposal cannot be executed");
        require(
            block.timestamp >= proposals[proposalId].queueTime + EXECUTION_DELAY,
            "Gov: Execution delay not met"
        );

        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;

        // Execute the proposal
        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.data);
        require(success, "Gov: Proposal execution failed");

        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev Cancel a proposal (only proposer can cancel)
     * @param proposalId ID of the proposal to cancel
     */
    function cancel(uint256 proposalId) external {
        require(proposalId > 0 && proposalId <= proposalCount, "Gov: Invalid proposal ID");
        
        Proposal storage proposal = proposals[proposalId];
        require(msg.sender == proposal.proposer, "Gov: Only proposer can cancel");
        require(state(proposalId) != ProposalState.Executed, "Gov: Cannot cancel executed proposal");
        
        proposal.canceled = true;
        
        emit ProposalCanceled(proposalId);
    }

    /**
     * @dev Get the current state of a proposal
     * @param proposalId ID of the proposal
     * @return Current proposal state
     */
    function state(uint256 proposalId) public view returns (ProposalState) {
        require(proposalId > 0 && proposalId <= proposalCount, "Gov: Invalid proposal ID");
        
        Proposal storage proposal = proposals[proposalId];
        
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (proposal.queueTime > 0) {
            return ProposalState.Queued;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else {
            // Voting has ended, determine outcome
            uint256 totalVotes = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;
            
            if (totalVotes < getQuorum()) {
                return ProposalState.Defeated; // Didn't meet quorum
            } else if (proposal.forVotes > proposal.againstVotes) {
                return ProposalState.Succeeded; // Majority voted for
            } else {
                return ProposalState.Defeated; // Majority voted against or tie
            }
        }
    }

    /**
     * @dev Get the proposal threshold (minimum votes needed to create proposal)
     * @return Proposal threshold in token units
     */
    function getProposalThreshold() public view returns (uint256) {
        return (votingToken.totalSupply() * PROPOSAL_THRESHOLD) / 10000; // 1% of total supply
    }

    /**
     * @dev Get the quorum requirement (minimum votes needed for proposal to pass)
     * @return Quorum in token units
     */
    function getQuorum() public view returns (uint256) {
        return (votingToken.totalSupply() * QUORUM_PERCENTAGE * 100) / 10000; // 4% of total supply
    }

    /**
     * @dev Get proposal details
     * @param proposalId ID of the proposal
     * @return Full proposal struct
     */
    function getProposal(uint256 proposalId) external view returns (Proposal memory) {
        require(proposalId > 0 && proposalId <= proposalCount, "Gov: Invalid proposal ID");
        return proposals[proposalId];
    }

    /**
     * @dev Get vote receipt for a voter on a specific proposal
     * @param proposalId ID of the proposal
     * @param voter Address of the voter
     * @return Vote receipt
     */
    function getReceipt(uint256 proposalId, address voter) external view returns (Receipt memory) {
        return receipts[proposalId][voter];
    }
}