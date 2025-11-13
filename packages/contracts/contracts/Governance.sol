// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Governance
 * @notice A simple governance contract for collaborative decision-making
 * @dev Step 6: Voting/Governance contract owned by multisig
 * 
 * LEARNING POINT: This contract enables on-chain governance where proposals
 * can be created, voted on, and executed. The multisig controls the contract,
 * but proposals allow for structured decision-making.
 * 
 * Key concepts:
 * - Proposals: Structured decisions that can be voted on
 * - Voting: Each proposal can be voted for/against
 * - Execution: Approved proposals can execute actions
 * - Quorum: Minimum votes required for a proposal to pass
 */
contract Governance is Ownable {
    /**
     * @notice Structure to represent a proposal
     * @dev Contains all information about a governance proposal
     */
    struct Proposal {
        uint256 id;                    // Unique proposal ID
        address proposer;              // Who created the proposal
        string description;            // Human-readable description
        address target;                // Target contract for execution (if any)
        bytes data;                   // Call data for execution (if any)
        uint256 value;                // ETH value to send (if any)
        uint256 forVotes;             // Number of votes in favor
        uint256 againstVotes;          // Number of votes against
        uint256 startTime;             // When voting starts
        uint256 endTime;              // When voting ends
        bool executed;                 // Whether proposal has been executed
        bool cancelled;                // Whether proposal was cancelled
        mapping(address => bool) hasVoted; // Track who has voted
        mapping(address => bool) voteChoice; // true = for, false = against
    }

    // Proposal settings
    uint256 public votingPeriod;      // How long voting lasts (in seconds)
    uint256 public quorumThreshold;   // Minimum votes required (absolute number)
    
    // Proposal tracking
    uint256 public proposalCount;     // Total number of proposals
    mapping(uint256 => Proposal) public proposals; // proposal ID => Proposal
    
    // Events
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string description,
        address target,
        uint256 value,
        bytes data
    );
    
    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        bool support,  // true = for, false = against
        uint256 forVotes,
        uint256 againstVotes
    );
    
    event ProposalExecuted(
        uint256 indexed proposalId,
        address indexed target,
        uint256 value
    );
    
    event ProposalCancelled(uint256 indexed proposalId);
    event VotingPeriodUpdated(uint256 oldPeriod, uint256 newPeriod);
    event QuorumThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);

    /**
     * @notice Constructor sets the initial owner and governance parameters
     * @param initialOwner The address that will be the initial owner (multisig)
     * @param _votingPeriod Voting period in seconds (e.g., 7 days = 604800)
     * @param _quorumThreshold Minimum number of votes required for a proposal to pass
     * 
     * LEARNING POINT: We set reasonable defaults for voting period and quorum.
     * The voting period determines how long people have to vote.
     * The quorum ensures enough participation for decisions to be valid.
     */
    constructor(
        address initialOwner,
        uint256 _votingPeriod,
        uint256 _quorumThreshold
    ) Ownable(initialOwner) {
        require(_votingPeriod > 0, "Governance: voting period must be greater than 0");
        require(_quorumThreshold > 0, "Governance: quorum threshold must be greater than 0");
        
        votingPeriod = _votingPeriod;
        quorumThreshold = _quorumThreshold;
    }

    /**
     * @notice Create a new proposal
     * @dev Anyone can create a proposal, but only owner can execute
     * @param description Human-readable description of the proposal
     * @param target Target contract address (address(0) if no execution needed)
     * @param value ETH value to send (0 if no ETH transfer)
     * @param data Encoded function call data (empty if no execution)
     * @return proposalId The ID of the created proposal
     * 
     * LEARNING POINT: Creating a proposal doesn't execute anything.
     * It just opens voting. After voting ends and quorum is met,
     * the owner (multisig) can execute the proposal.
     */
    function createProposal(
        string memory description,
        address target,
        uint256 value,
        bytes memory data
    ) external returns (uint256 proposalId) {
        require(bytes(description).length > 0, "Governance: description cannot be empty");
        
        proposalId = proposalCount;
        proposalCount++;
        
        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.target = target;
        proposal.value = value;
        proposal.data = data;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + votingPeriod;
        proposal.executed = false;
        proposal.cancelled = false;
        
        emit ProposalCreated(proposalId, msg.sender, description, target, value, data);
    }

    /**
     * @notice Vote on a proposal
     * @dev Anyone can vote, but can only vote once per proposal
     * @param proposalId The ID of the proposal to vote on
     * @param support true = vote for, false = vote against
     * 
     * LEARNING POINT: This implements simple binary voting (for/against).
     * Each address can vote once. More sophisticated systems might use
     * token-weighted voting or delegation.
     */
    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        
        require(proposal.proposer != address(0), "Governance: proposal does not exist");
        require(!proposal.cancelled, "Governance: proposal has been cancelled");
        require(!proposal.executed, "Governance: proposal has already been executed");
        require(block.timestamp >= proposal.startTime, "Governance: voting has not started");
        require(block.timestamp <= proposal.endTime, "Governance: voting has ended");
        require(!proposal.hasVoted[msg.sender], "Governance: already voted");
        
        proposal.hasVoted[msg.sender] = true;
        proposal.voteChoice[msg.sender] = support;
        
        if (support) {
            proposal.forVotes++;
        } else {
            proposal.againstVotes++;
        }
        
        emit VoteCast(proposalId, msg.sender, support, proposal.forVotes, proposal.againstVotes);
    }

    /**
     * @notice Execute a proposal
     * @dev Only owner (multisig) can execute, and only if proposal passed
     * @param proposalId The ID of the proposal to execute
     * 
     * LEARNING POINT: Execution requires:
     * 1. Voting period has ended
     * 2. Quorum threshold is met (enough votes)
     * 3. More for votes than against votes
     * 4. Proposal hasn't been executed or cancelled
     * 
     * The multisig must approve this execution, ensuring both parties
     * agree to execute the proposal.
     */
    function executeProposal(uint256 proposalId) external onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        
        require(proposal.proposer != address(0), "Governance: proposal does not exist");
        require(!proposal.cancelled, "Governance: proposal has been cancelled");
        require(!proposal.executed, "Governance: proposal has already been executed");
        require(block.timestamp > proposal.endTime, "Governance: voting period has not ended");
        
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        require(totalVotes >= quorumThreshold, "Governance: quorum not met");
        require(proposal.forVotes > proposal.againstVotes, "Governance: proposal did not pass");
        
        proposal.executed = true;
        
        // Execute the proposal if it has a target
        if (proposal.target != address(0)) {
            (bool success, ) = proposal.target.call{value: proposal.value}(proposal.data);
            require(success, "Governance: proposal execution failed");
        }
        
        emit ProposalExecuted(proposalId, proposal.target, proposal.value);
    }

    /**
     * @notice Cancel a proposal (only owner)
     * @dev Owner can cancel proposals before execution
     * @param proposalId The ID of the proposal to cancel
     * 
     * LEARNING POINT: The owner (multisig) can cancel proposals.
     * This provides a safety mechanism if a proposal is problematic.
     */
    function cancelProposal(uint256 proposalId) external onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        
        require(proposal.proposer != address(0), "Governance: proposal does not exist");
        require(!proposal.executed, "Governance: proposal has already been executed");
        require(!proposal.cancelled, "Governance: proposal has already been cancelled");
        
        proposal.cancelled = true;
        
        emit ProposalCancelled(proposalId);
    }

    /**
     * @notice Update voting period (only owner)
     * @param newVotingPeriod New voting period in seconds
     */
    function setVotingPeriod(uint256 newVotingPeriod) external onlyOwner {
        require(newVotingPeriod > 0, "Governance: voting period must be greater than 0");
        
        uint256 oldPeriod = votingPeriod;
        votingPeriod = newVotingPeriod;
        
        emit VotingPeriodUpdated(oldPeriod, newVotingPeriod);
    }

    /**
     * @notice Update quorum threshold (only owner)
     * @param newQuorumThreshold New quorum threshold
     */
    function setQuorumThreshold(uint256 newQuorumThreshold) external onlyOwner {
        require(newQuorumThreshold > 0, "Governance: quorum threshold must be greater than 0");
        
        uint256 oldThreshold = quorumThreshold;
        quorumThreshold = newQuorumThreshold;
        
        emit QuorumThresholdUpdated(oldThreshold, newQuorumThreshold);
    }

    /**
     * @notice Get proposal details
     * @param proposalId The ID of the proposal
     * @return id Proposal ID
     * @return proposer Address of proposer
     * @return description Proposal description
     * @return target Target contract address
     * @return value ETH value
     * @return forVotes Number of for votes
     * @return againstVotes Number of against votes
     * @return startTime Voting start time
     * @return endTime Voting end time
     * @return executed Whether executed
     * @return cancelled Whether cancelled
     * 
     * LEARNING POINT: This view function allows anyone to check proposal status.
     * Note: We can't return mappings directly, so we return individual values.
     */
    function getProposal(uint256 proposalId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            string memory description,
            address target,
            uint256 value,
            uint256 forVotes,
            uint256 againstVotes,
            uint256 startTime,
            uint256 endTime,
            bool executed,
            bool cancelled
        )
    {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "Governance: proposal does not exist");
        
        return (
            proposal.id,
            proposal.proposer,
            proposal.description,
            proposal.target,
            proposal.value,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.startTime,
            proposal.endTime,
            proposal.executed,
            proposal.cancelled
        );
    }

    /**
     * @notice Check if an address has voted on a proposal
     * @param proposalId The ID of the proposal
     * @param voter The address to check
     * @return hasVoted Whether the address has voted
     * @return voteChoice true if voted for, false if voted against (only valid if hasVoted is true)
     */
    function getVote(uint256 proposalId, address voter)
        external
        view
        returns (bool hasVoted, bool voteChoice)
    {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "Governance: proposal does not exist");
        
        hasVoted = proposal.hasVoted[voter];
        if (hasVoted) {
            voteChoice = proposal.voteChoice[voter];
        }
    }

    /**
     * @notice Check if a proposal can be executed
     * @param proposalId The ID of the proposal
     * @return canExecute Whether the proposal can be executed
     * @return reason Reason why it can't be executed (if applicable)
     */
    function canExecute(uint256 proposalId)
        external
        view
        returns (bool canExecute, string memory reason)
    {
        Proposal storage proposal = proposals[proposalId];
        
        if (proposal.proposer == address(0)) {
            return (false, "Proposal does not exist");
        }
        
        if (proposal.cancelled) {
            return (false, "Proposal has been cancelled");
        }
        
        if (proposal.executed) {
            return (false, "Proposal has already been executed");
        }
        
        if (block.timestamp <= proposal.endTime) {
            return (false, "Voting period has not ended");
        }
        
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        if (totalVotes < quorumThreshold) {
            return (false, "Quorum not met");
        }
        
        if (proposal.forVotes <= proposal.againstVotes) {
            return (false, "Proposal did not pass");
        }
        
        return (true, "");
    }
}

