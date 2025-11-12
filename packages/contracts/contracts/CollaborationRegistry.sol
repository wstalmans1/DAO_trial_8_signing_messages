// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CollaborationRegistry
 * @notice This contract stores mutual acknowledgments between two parties
 * @dev Step 2: Now Ownable - can be controlled by a multisig wallet
 * 
 * LEARNING POINT: This contract inherits from OpenZeppelin's Ownable.
 * The owner (initially deployer, later multisig) can control certain functions.
 * This allows the multisig to manage the registry settings.
 */
contract CollaborationRegistry is Ownable {
    /**
     * @notice Structure to store an acknowledgment
     * @dev Contains all the data needed to verify a signature
     */
    struct Acknowledgment {
        address signer;        // Who signed (Party A or Party B)
        address target;        // Who they're acknowledging (the other party)
        string message;        // The message they signed
        bytes signature;       // Their signature
        uint256 timestamp;     // When it was submitted
        bool exists;           // Whether this acknowledgment exists
    }

    /**
     * @notice Structure to represent a mutual handshake
     * @dev Both parties must acknowledge each other for this to be complete
     */
    struct MutualHandshake {
        address partyA;              // First party's address
        address partyB;              // Second party's address
        bytes32 acknowledgmentAHash; // Hash of Party A's acknowledgment
        bytes32 acknowledgmentBHash; // Hash of Party B's acknowledgment
        uint256 timestamp;          // When handshake was completed
        bool isActive;               // True when both parties have acknowledged
    }

    // Mapping: acknowledgment hash => Acknowledgment data
    mapping(bytes32 => Acknowledgment) public acknowledgments;
    
    // Mapping: address => array of acknowledgment hashes they've made
    mapping(address => bytes32[]) public acknowledgmentsByAddress;
    
    // Mapping: hash(partyA, partyB) => MutualHandshake
    // We use a hash to ensure consistent ordering (smaller address first)
    mapping(bytes32 => MutualHandshake) public handshakes;
    
    // Mapping: address => array of handshake hashes they're part of
    // LEARNING POINT: This allows us to quickly find all handshakes for an address
    mapping(address => bytes32[]) public handshakesByAddress;

    // Events for tracking what happens
    event AcknowledgmentSubmitted(
        address indexed signer,
        address indexed target,
        bytes32 indexed acknowledgmentHash
    );

    event MutualHandshakeCreated(
        address indexed partyA,
        address indexed partyB,
        bytes32 indexed handshakeHash
    );

    /**
     * @notice Constructor sets the initial owner
     * @dev The deployer becomes the owner. Later, ownership can be transferred to a multisig.
     * @param initialOwner The address that will be the initial owner
     * 
     * LEARNING POINT: Ownable requires an initial owner. We pass it to the Ownable constructor.
     * This owner can later transfer ownership to a multisig wallet.
     */
    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @notice Submit an acknowledgment
     * @dev Party A or Party B calls this with their signature
     * @param target The address of the other party they're acknowledging
     * @param message The message they signed (must match what was signed off-chain)
     * @param signature Their signature of the message
     * 
     * LEARNING POINT: This function stores the acknowledgment.
     */
    function submitAcknowledgment(
        address target,
        string memory message,
        bytes memory signature
    ) external {
        require(target != address(0), "CollaborationRegistry: target cannot be zero address");
        require(target != msg.sender, "CollaborationRegistry: cannot acknowledge yourself");
        require(bytes(message).length > 0, "CollaborationRegistry: message cannot be empty");
        require(signature.length > 0, "CollaborationRegistry: signature cannot be empty");

        // Create a unique hash for this acknowledgment
        bytes32 acknowledgmentHash = keccak256(
            abi.encodePacked(msg.sender, target, message, signature, block.timestamp)
        );

        // Check if this acknowledgment already exists
        require(
            !acknowledgments[acknowledgmentHash].exists,
            "CollaborationRegistry: acknowledgment already exists"
        );

        // Store the acknowledgment
        acknowledgments[acknowledgmentHash] = Acknowledgment({
            signer: msg.sender,
            target: target,
            message: message,
            signature: signature,
            timestamp: block.timestamp,
            exists: true
        });

        // Track this acknowledgment by the signer's address
        acknowledgmentsByAddress[msg.sender].push(acknowledgmentHash);

        emit AcknowledgmentSubmitted(msg.sender, target, acknowledgmentHash);

        // Check if we can create a mutual handshake
        _checkAndCreateHandshake(msg.sender, target, acknowledgmentHash);
    }

    /**
     * @notice Internal function to check if both parties have acknowledged each other
     * @dev If both have acknowledged, creates a mutual handshake
     * @param signer The person who just submitted an acknowledgment
     * @param target The person they acknowledged
     * @param newAcknowledgmentHash The hash of the new acknowledgment
     * 
     * LEARNING POINT: This checks if there's a reverse acknowledgment.
     * If Party A acknowledges Party B, we check if Party B has acknowledged Party A.
     * If both exist, we create a mutual handshake!
     */
    function _checkAndCreateHandshake(
        address signer,
        address target,
        bytes32 newAcknowledgmentHash
    ) internal {
        // Create a consistent key for the handshake (always smaller address first)
        (address partyA, address partyB) = signer < target 
            ? (signer, target) 
            : (target, signer);

        bytes32 handshakeKey = keccak256(abi.encodePacked(partyA, partyB));

        // Get existing handshake or create new one
        MutualHandshake storage handshake = handshakes[handshakeKey];

        // If this is the first acknowledgment, initialize the handshake
        if (handshake.partyA == address(0)) {
            handshake.partyA = partyA;
            handshake.partyB = partyB;
        }

        // Determine which acknowledgment this is (A or B)
        if (signer == partyA) {
            handshake.acknowledgmentAHash = newAcknowledgmentHash;
        } else {
            handshake.acknowledgmentBHash = newAcknowledgmentHash;
        }

        // Check if both acknowledgments exist
        if (
            handshake.acknowledgmentAHash != bytes32(0) &&
            handshake.acknowledgmentBHash != bytes32(0) &&
            !handshake.isActive
        ) {
            // Both parties have acknowledged! Activate the handshake
            handshake.timestamp = block.timestamp;
            handshake.isActive = true;

            // Track this handshake for both parties
            // LEARNING POINT: We add the handshake hash to both parties' arrays
            // so we can quickly query all handshakes for any address
            handshakesByAddress[partyA].push(handshakeKey);
            handshakesByAddress[partyB].push(handshakeKey);

            emit MutualHandshakeCreated(partyA, partyB, handshakeKey);
        }
    }

    /**
     * @notice Check if two parties have mutually acknowledged each other
     * @param partyA First party's address
     * @param partyB Second party's address
     * @return isActive True if both parties have acknowledged each other
     * @return handshake The handshake data
     * 
     * LEARNING POINT: This is a view function (doesn't cost gas to call).
     * Anyone can check if two parties have mutually acknowledged.
     */
    function getMutualHandshake(address partyA, address partyB)
        external
        view
        returns (bool isActive, MutualHandshake memory handshake)
    {
        // Ensure consistent ordering
        (address a, address b) = partyA < partyB 
            ? (partyA, partyB) 
            : (partyB, partyA);

        bytes32 handshakeKey = keccak256(abi.encodePacked(a, b));
        handshake = handshakes[handshakeKey];
        isActive = handshake.isActive;
    }

    /**
     * @notice Get all acknowledgments made by an address
     * @param addr The address to query
     * @return hashes Array of acknowledgment hashes
     * 
     * LEARNING POINT: This helps you see all acknowledgments someone has made.
     */
    function getAcknowledgmentHashes(address addr)
        external
        view
        returns (bytes32[] memory hashes)
    {
        return acknowledgmentsByAddress[addr];
    }

    /**
     * @notice Get a specific acknowledgment by its hash
     * @param acknowledgmentHash The hash of the acknowledgment
     * @return acknowledgment The acknowledgment data
     */
    function getAcknowledgment(bytes32 acknowledgmentHash)
        external
        view
        returns (Acknowledgment memory acknowledgment)
    {
        require(
            acknowledgments[acknowledgmentHash].exists,
            "CollaborationRegistry: acknowledgment does not exist"
        );
        return acknowledgments[acknowledgmentHash];
    }

    /**
     * @notice Get all handshake hashes for an address
     * @param addr The address to query
     * @return hashes Array of handshake hashes that this address is part of
     * 
     * LEARNING POINT: This function returns all handshake hashes where the address
     * is either partyA or partyB. You can then use getMutualHandshake() to get
     * the full handshake details for each hash.
     */
    function getHandshakeHashes(address addr)
        external
        view
        returns (bytes32[] memory hashes)
    {
        return handshakesByAddress[addr];
    }

    // ============ OWNER-ONLY FUNCTIONS ============
    // LEARNING POINT: The Ownable contract provides transferOwnership() function.
    // Only the owner can call it. We don't need to implement it ourselves.

    /**
     * @notice Get the current owner of the contract
     * @return The address of the current owner
     * 
     * LEARNING POINT: This function comes from Ownable. It's useful to check
     * who controls the contract. After transferring to multisig, this will
     * return the multisig address.
     * 
     * NOTE: transferOwnership() is already available from Ownable.
     * The owner can call: transferOwnership(newOwner) to transfer ownership.
     */
    function getOwner() external view returns (address) {
        return owner();
    }
}

