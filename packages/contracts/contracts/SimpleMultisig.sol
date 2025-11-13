// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title SimpleMultisig
 * @notice A simple 2-of-2 multisig wallet for collaboration
 * @dev Step 3: Learning how multisig wallets work
 * 
 * LEARNING POINT: This is a simple multisig wallet that requires both parties
 * to approve any transaction before it can be executed. This ensures shared control.
 */
contract SimpleMultisig {
    /**
     * @notice Structure to represent a pending transaction
     * @dev Stores transaction details until both parties approve
     */
    struct Transaction {
        address to;           // Destination address
        uint256 value;        // Amount of ETH to send (in wei)
        bytes data;           // Call data (function call + parameters)
        bool executed;        // Whether transaction has been executed
        uint256 approvals;    // Number of approvals (0, 1, or 2)
    }

    // The two owners of this multisig wallet
    address public owner1;
    address public owner2;

    // Mapping: transaction ID => Transaction details
    mapping(uint256 => Transaction) public transactions;

    // Mapping: transaction ID => owner address => has approved
    mapping(uint256 => mapping(address => bool)) public approvals;

    // Counter for transaction IDs
    uint256 public transactionCount;

    // Events
    event TransactionCreated(
        uint256 indexed transactionId,
        address indexed to,
        uint256 value,
        bytes data
    );

    event TransactionApproved(
        uint256 indexed transactionId,
        address indexed approver
    );

    event TransactionExecuted(
        uint256 indexed transactionId,
        address indexed to,
        uint256 value
    );

    /**
     * @notice Constructor sets the two owners
     * @param _owner1 First owner address
     * @param _owner2 Second owner address
     * 
     * LEARNING POINT: Both owners must be different addresses.
     * This creates a 2-of-2 multisig where both must approve transactions.
     */
    constructor(address _owner1, address _owner2) {
        require(_owner1 != address(0), "SimpleMultisig: owner1 cannot be zero address");
        require(_owner2 != address(0), "SimpleMultisig: owner2 cannot be zero address");
        require(_owner1 != _owner2, "SimpleMultisig: owners must be different");

        owner1 = _owner1;
        owner2 = _owner2;
    }

    /**
     * @notice Modifier to check if caller is one of the owners
     * @dev Only owner1 or owner2 can call functions with this modifier
     */
    modifier onlyOwner() {
        require(
            msg.sender == owner1 || msg.sender == owner2,
            "SimpleMultisig: caller is not an owner"
        );
        _;
    }

    /**
     * @notice Create a new transaction
     * @dev Either owner can create a transaction, but both must approve to execute
     * @param to Destination address for the transaction
     * @param value Amount of ETH to send (in wei)
     * @param data Call data (encoded function call)
     * @return transactionId The ID of the created transaction
     * 
     * LEARNING POINT: Creating a transaction doesn't execute it.
     * Both owners must approve before it can be executed.
     */
    function createTransaction(
        address to,
        uint256 value,
        bytes memory data
    ) external onlyOwner returns (uint256 transactionId) {
        require(to != address(0), "SimpleMultisig: destination cannot be zero address");

        transactionId = transactionCount;
        transactionCount++;

        transactions[transactionId] = Transaction({
            to: to,
            value: value,
            data: data,
            executed: false,
            approvals: 0
        });

        emit TransactionCreated(transactionId, to, value, data);
    }

    /**
     * @notice Approve a transaction
     * @dev Each owner can approve once. When both approve, transaction can be executed.
     * @param transactionId The ID of the transaction to approve
     * 
     * LEARNING POINT: This is the core of multisig - both parties must approve.
     * If you approve, you can't un-approve (for simplicity in this learning version).
     */
    function approveTransaction(uint256 transactionId) external onlyOwner {
        Transaction storage transaction = transactions[transactionId];
        require(transaction.to != address(0), "SimpleMultisig: transaction does not exist");
        require(!transaction.executed, "SimpleMultisig: transaction already executed");
        require(!approvals[transactionId][msg.sender], "SimpleMultisig: already approved");

        // Mark this owner as having approved
        approvals[transactionId][msg.sender] = true;
        transaction.approvals++;

        emit TransactionApproved(transactionId, msg.sender);
    }

    /**
     * @notice Execute a transaction
     * @dev Can only execute if both owners have approved (2-of-2 requirement)
     * @param transactionId The ID of the transaction to execute
     * 
     * LEARNING POINT: This is where the 2-of-2 requirement is enforced.
     * Both owners must have approved before execution is possible.
     */
    function executeTransaction(uint256 transactionId) external onlyOwner {
        Transaction storage transaction = transactions[transactionId];
        require(transaction.to != address(0), "SimpleMultisig: transaction does not exist");
        require(!transaction.executed, "SimpleMultisig: transaction already executed");
        require(transaction.approvals == 2, "SimpleMultisig: both owners must approve");

        // Mark as executed before external call (reentrancy protection)
        transaction.executed = true;

        // Execute the transaction
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "SimpleMultisig: transaction execution failed");

        emit TransactionExecuted(transactionId, transaction.to, transaction.value);
    }

    /**
     * @notice Get transaction details
     * @param transactionId The ID of the transaction
     * @return transaction The transaction details
     * 
     * LEARNING POINT: This is a view function - anyone can check transaction status.
     */
    function getTransaction(uint256 transactionId)
        external
        view
        returns (Transaction memory transaction)
    {
        require(transactions[transactionId].to != address(0), "SimpleMultisig: transaction does not exist");
        return transactions[transactionId];
    }

    /**
     * @notice Check if an owner has approved a transaction
     * @param transactionId The ID of the transaction
     * @param owner The owner address to check
     * @return True if the owner has approved
     */
    function hasApproved(uint256 transactionId, address owner)
        external
        view
        returns (bool)
    {
        return approvals[transactionId][owner];
    }

    /**
     * @notice Receive ETH
     * @dev Allows the multisig wallet to receive ETH
     */
    receive() external payable {}

    /**
     * @notice Get the balance of this multisig wallet
     * @return The balance in wei
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

