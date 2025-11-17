// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DisputeResolution
 * @notice A contract for resolving disputes in collaborative work
 * @dev Step 8: Dispute Resolution contract owned by multisig
 * 
 * LEARNING POINT: This contract provides a structured way to handle disputes
 * that may arise during collaboration. It allows parties to submit disputes,
 * provide evidence, and have them resolved by the multisig (or governance).
 * 
 * Key concepts:
 * - Disputes: Structured disagreements that need resolution
 * - Evidence: IPFS CIDs or other proof submitted by parties
 * - Resolution: Decision made by authorized resolver (multisig/governance)
 * - Dispute types: Can be related to tasks, payments, or general collaboration
 */
contract DisputeResolution is Ownable {
    /**
     * @notice Enumeration of dispute statuses
     * @dev Represents the lifecycle of a dispute
     */
    enum DisputeStatus {
        Created,        // Dispute created, awaiting evidence
        EvidenceSubmitted, // Evidence has been submitted
        UnderReview,    // Dispute is being reviewed by resolver
        Resolved,       // Dispute has been resolved
        Cancelled       // Dispute was cancelled
    }

    /**
     * @notice Enumeration of dispute types
     * @dev Categorizes what the dispute is about
     */
    enum DisputeType {
        Task,           // Related to a task
        Payment,        // Related to payment
        General         // General collaboration dispute
    }

    /**
     * @notice Structure to represent a dispute
     * @dev Contains all information about a dispute
     */
    struct Dispute {
        uint256 id;                    // Unique dispute ID
        address initiator;             // Who created the dispute
        address counterparty;         // The other party in the dispute
        DisputeType disputeType;      // Type of dispute
        uint256 relatedId;            // Related task ID or other identifier (0 if none)
        string description;           // Description of the dispute
        string initiatorEvidence;    // IPFS CID or evidence from initiator
        string counterpartyEvidence; // IPFS CID or evidence from counterparty
        DisputeStatus status;         // Current status
        address resolver;             // Who resolved the dispute (address(0) if unresolved)
        string resolution;           // Resolution description/outcome
        uint256 createdAt;            // When dispute was created
        uint256 resolvedAt;           // When dispute was resolved (0 if unresolved)
        bool exists;                  // Whether this dispute exists
    }

    // Dispute tracking
    uint256 public disputeCount;     // Total number of disputes
    
    // Mapping: dispute ID => Dispute
    mapping(uint256 => Dispute) public disputes;
    
    // Mapping: address => array of dispute IDs they initiated
    mapping(address => uint256[]) public disputesByInitiator;
    
    // Mapping: address => array of dispute IDs they're involved in
    mapping(address => uint256[]) public disputesByParty;
    
    // Mapping: address => array of dispute IDs they resolved
    mapping(address => uint256[]) public disputesByResolver;

    // Events
    event DisputeCreated(
        uint256 indexed disputeId,
        address indexed initiator,
        address indexed counterparty,
        DisputeType disputeType,
        uint256 relatedId
    );
    
    event EvidenceSubmitted(
        uint256 indexed disputeId,
        address indexed submitter,
        string evidence
    );
    
    event DisputeResolved(
        uint256 indexed disputeId,
        address indexed resolver,
        string resolution
    );
    
    event DisputeCancelled(
        uint256 indexed disputeId,
        address indexed cancelledBy
    );

    /**
     * @notice Constructor sets the initial owner
     * @param initialOwner The address that will own this contract (multisig)
     */
    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @notice Create a new dispute
     * @dev Anyone can create a dispute, but they must specify a counterparty
     * @param counterparty The other party in the dispute
     * @param disputeType The type of dispute
     * @param relatedId Related task ID or other identifier (0 if none)
     * @param description Description of the dispute
     * @param evidence IPFS CID or initial evidence
     * @return disputeId The ID of the newly created dispute
     * 
     * LEARNING POINT: Disputes can be created by anyone, allowing for
     * transparent conflict resolution. The counterparty can then submit
     * their own evidence. The multisig (or governance) acts as the resolver.
     */
    function createDispute(
        address counterparty,
        DisputeType disputeType,
        uint256 relatedId,
        string memory description,
        string memory evidence
    ) external returns (uint256 disputeId) {
        require(counterparty != address(0), "DisputeResolution: counterparty cannot be zero address");
        require(counterparty != msg.sender, "DisputeResolution: cannot dispute yourself");
        require(bytes(description).length > 0, "DisputeResolution: description cannot be empty");
        
        disputeId = disputeCount;
        disputeCount++;
        
        disputes[disputeId] = Dispute({
            id: disputeId,
            initiator: msg.sender,
            counterparty: counterparty,
            disputeType: disputeType,
            relatedId: relatedId,
            description: description,
            initiatorEvidence: evidence,
            counterpartyEvidence: "",
            status: DisputeStatus.Created,
            resolver: address(0),
            resolution: "",
            createdAt: block.timestamp,
            resolvedAt: 0,
            exists: true
        });
        
        // Track disputes by parties
        disputesByInitiator[msg.sender].push(disputeId);
        disputesByParty[msg.sender].push(disputeId);
        disputesByParty[counterparty].push(disputeId);
        
        emit DisputeCreated(disputeId, msg.sender, counterparty, disputeType, relatedId);
        
        // If evidence was provided, emit event
        if (bytes(evidence).length > 0) {
            emit EvidenceSubmitted(disputeId, msg.sender, evidence);
            disputes[disputeId].status = DisputeStatus.EvidenceSubmitted;
        }
    }

    /**
     * @notice Submit evidence for a dispute
     * @dev Can be called by initiator or counterparty
     * @param disputeId The ID of the dispute
     * @param evidence IPFS CID or evidence to submit
     * 
     * LEARNING POINT: Both parties can submit evidence to support their case.
     * Evidence is stored as strings (typically IPFS CIDs) allowing for
     * off-chain document storage with on-chain references.
     */
    function submitEvidence(uint256 disputeId, string memory evidence) external {
        Dispute storage dispute = disputes[disputeId];
        
        require(dispute.exists, "DisputeResolution: dispute does not exist");
        require(
            msg.sender == dispute.initiator || msg.sender == dispute.counterparty,
            "DisputeResolution: only parties can submit evidence"
        );
        require(
            dispute.status == DisputeStatus.Created || 
            dispute.status == DisputeStatus.EvidenceSubmitted,
            "DisputeResolution: dispute is not accepting evidence"
        );
        require(bytes(evidence).length > 0, "DisputeResolution: evidence cannot be empty");
        
        // Update evidence based on who is submitting
        if (msg.sender == dispute.initiator) {
            dispute.initiatorEvidence = evidence;
        } else {
            dispute.counterpartyEvidence = evidence;
        }
        
        dispute.status = DisputeStatus.EvidenceSubmitted;
        
        emit EvidenceSubmitted(disputeId, msg.sender, evidence);
    }

    /**
     * @notice Resolve a dispute
     * @dev Only owner (multisig) can resolve disputes
     * @param disputeId The ID of the dispute to resolve
     * @param resolution Description of the resolution/outcome
     * 
     * LEARNING POINT: The multisig acts as the resolver, ensuring both
     * parties must agree on dispute resolution. In a more advanced system,
     * this could be delegated to governance or a jury system.
     */
    function resolveDispute(uint256 disputeId, string memory resolution) external onlyOwner {
        Dispute storage dispute = disputes[disputeId];
        
        require(dispute.exists, "DisputeResolution: dispute does not exist");
        require(
            dispute.status == DisputeStatus.EvidenceSubmitted || 
            dispute.status == DisputeStatus.UnderReview,
            "DisputeResolution: dispute cannot be resolved in current status"
        );
        require(bytes(resolution).length > 0, "DisputeResolution: resolution cannot be empty");
        
        dispute.status = DisputeStatus.Resolved;
        dispute.resolver = msg.sender;
        dispute.resolution = resolution;
        dispute.resolvedAt = block.timestamp;
        
        disputesByResolver[msg.sender].push(disputeId);
        
        emit DisputeResolved(disputeId, msg.sender, resolution);
    }

    /**
     * @notice Mark a dispute as under review
     * @dev Only owner (multisig) can mark disputes as under review
     * @param disputeId The ID of the dispute
     * 
     * LEARNING POINT: This allows the resolver to indicate they're actively
     * reviewing the dispute, providing transparency in the resolution process.
     */
    function markUnderReview(uint256 disputeId) external onlyOwner {
        Dispute storage dispute = disputes[disputeId];
        
        require(dispute.exists, "DisputeResolution: dispute does not exist");
        require(
            dispute.status == DisputeStatus.EvidenceSubmitted,
            "DisputeResolution: dispute must have evidence submitted"
        );
        
        dispute.status = DisputeStatus.UnderReview;
    }

    /**
     * @notice Cancel a dispute
     * @dev Can be called by initiator or owner
     * @param disputeId The ID of the dispute to cancel
     * 
     * LEARNING POINT: Allows parties to withdraw disputes if they reach
     * an agreement outside the system, or the owner can cancel invalid disputes.
     */
    function cancelDispute(uint256 disputeId) external {
        Dispute storage dispute = disputes[disputeId];
        
        require(dispute.exists, "DisputeResolution: dispute does not exist");
        require(
            msg.sender == dispute.initiator || msg.sender == owner(),
            "DisputeResolution: only initiator or owner can cancel"
        );
        require(
            dispute.status != DisputeStatus.Resolved,
            "DisputeResolution: cannot cancel resolved dispute"
        );
        
        dispute.status = DisputeStatus.Cancelled;
        
        emit DisputeCancelled(disputeId, msg.sender);
    }

    /**
     * @notice Get a dispute by ID
     * @param disputeId The ID of the dispute
     * @return The dispute struct
     */
    function getDispute(uint256 disputeId) external view returns (Dispute memory) {
        require(disputes[disputeId].exists, "DisputeResolution: dispute does not exist");
        return disputes[disputeId];
    }

    /**
     * @notice Get total number of disputes
     * @return The total dispute count
     */
    function getDisputeCount() external view returns (uint256) {
        return disputeCount;
    }
}

