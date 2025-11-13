// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Treasury
 * @notice A treasury contract for managing collaboration funds
 * @dev Step 5: Payment/Treasury contract owned by multisig
 * 
 * LEARNING POINT: This contract holds ETH for the collaboration.
 * The multisig wallet (as owner) controls withdrawals, ensuring both parties
 * must approve any fund movement. Anyone can deposit ETH.
 * 
 * Key concepts:
 * - receive() function: Allows contract to receive ETH
 * - onlyOwner modifier: Restricts withdrawals to owner (multisig)
 * - Events: Track all deposits and withdrawals for transparency
 * - Balance tracking: Monitor total deposits vs withdrawals
 */
contract Treasury is Ownable {
    /**
     * @notice Structure to track a deposit transaction
     * @dev Stores information about each deposit
     */
    struct Deposit {
        address depositor;    // Who deposited
        uint256 amount;       // Amount deposited (in wei)
        uint256 timestamp;    // When deposit was made
    }

    /**
     * @notice Structure to track a withdrawal transaction
     * @dev Stores information about each withdrawal
     */
    struct Withdrawal {
        address recipient;   // Who received the funds
        uint256 amount;      // Amount withdrawn (in wei)
        uint256 timestamp;   // When withdrawal was made
        bool executed;       // Whether withdrawal was executed
    }

    // Authorized contracts that can withdraw (e.g., TaskManagement)
    mapping(address => bool) public authorizedWithdrawers;
    
    // Total amount of ETH deposited (cumulative)
    uint256 public totalDeposits;
    
    // Total amount of ETH withdrawn (cumulative)
    uint256 public totalWithdrawals;
    
    // Array of all deposits
    Deposit[] public deposits;
    
    // Array of all withdrawals
    Withdrawal[] public withdrawals;
    
    // Mapping: depositor address => array of deposit indices
    mapping(address => uint256[]) public depositsByAddress;
    
    // Mapping: recipient address => array of withdrawal indices
    mapping(address => uint256[]) public withdrawalsByAddress;

    // Events
    event DepositReceived(address indexed depositor, uint256 amount, uint256 timestamp);
    event WithdrawalExecuted(address indexed recipient, uint256 amount, uint256 timestamp);
    event EmergencyWithdrawal(address indexed recipient, uint256 amount, uint256 timestamp);
    event AuthorizedWithdrawerUpdated(address indexed withdrawer, bool authorized);

    /**
     * @notice Constructor sets the initial owner
     * @param initialOwner The address that will be the initial owner (multisig)
     * 
     * LEARNING POINT: We pass the multisig address as initialOwner.
     * This way, the multisig controls the treasury from the start.
     * Alternatively, we could deploy with deployer as owner, then transfer to multisig.
     */
    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @notice Receive ETH deposits
     * @dev This function is called when ETH is sent to the contract
     * 
     * LEARNING POINT: The `receive()` function is a special Solidity function
     * that gets called when ETH is sent directly to the contract address.
     * It must be external and payable. Anyone can deposit ETH this way.
     */
    receive() external payable {
        require(msg.value > 0, "Treasury: deposit amount must be greater than 0");
        
        // Record the deposit
        deposits.push(Deposit({
            depositor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        }));
        
        // Track deposits by address
        depositsByAddress[msg.sender].push(deposits.length - 1);
        
        // Update total deposits
        totalDeposits += msg.value;
        
        emit DepositReceived(msg.sender, msg.value, block.timestamp);
    }

    /**
     * @notice Fallback function for ETH deposits
     * @dev Called when ETH is sent but no function matches
     * 
     * LEARNING POINT: Fallback functions handle calls that don't match
     * any function signature. We redirect to receive().
     */
    fallback() external payable {
        require(msg.value > 0, "Treasury: deposit amount must be greater than 0");
        
        deposits.push(Deposit({
            depositor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        }));
        
        depositsByAddress[msg.sender].push(deposits.length - 1);
        totalDeposits += msg.value;
        
        emit DepositReceived(msg.sender, msg.value, block.timestamp);
    }

    /**
     * @notice Withdraw ETH from treasury
     * @dev Only the owner (multisig) or authorized withdrawers can call this function
     * @param recipient The address to send ETH to
     * @param amount The amount of ETH to withdraw (in wei)
     * 
     * LEARNING POINT: The `onlyOwner` modifier ensures only the multisig
     * can withdraw. Since the multisig requires 2-of-2 approval, both parties
     * must approve any withdrawal transaction. Authorized contracts (like TaskManagement)
     * can also withdraw for specific use cases.
     */
    function withdraw(address recipient, uint256 amount) external {
        require(
            msg.sender == owner() || authorizedWithdrawers[msg.sender],
            "Treasury: caller is not authorized to withdraw"
        );
        require(recipient != address(0), "Treasury: recipient cannot be zero address");
        require(amount > 0, "Treasury: withdrawal amount must be greater than 0");
        require(address(this).balance >= amount, "Treasury: insufficient balance");
        
        // Record the withdrawal
        withdrawals.push(Withdrawal({
            recipient: recipient,
            amount: amount,
            timestamp: block.timestamp,
            executed: true
        }));
        
        // Track withdrawals by address
        withdrawalsByAddress[recipient].push(withdrawals.length - 1);
        
        // Update total withdrawals
        totalWithdrawals += amount;
        
        // Transfer ETH to recipient
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Treasury: withdrawal transfer failed");
        
        emit WithdrawalExecuted(recipient, amount, block.timestamp);
    }

    /**
     * @notice Get the current balance of the treasury
     * @return The current balance in wei
     * 
     * LEARNING POINT: This is a view function (free to call).
     * It returns the contract's current ETH balance.
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Get total number of deposits
     * @return The number of deposits made
     */
    function getDepositCount() external view returns (uint256) {
        return deposits.length;
    }

    /**
     * @notice Get total number of withdrawals
     * @return The number of withdrawals made
     */
    function getWithdrawalCount() external view returns (uint256) {
        return withdrawals.length;
    }

    /**
     * @notice Get all deposit indices for an address
     * @param depositor The address to query
     * @return Array of deposit indices
     */
    function getDepositIndices(address depositor) external view returns (uint256[] memory) {
        return depositsByAddress[depositor];
    }

    /**
     * @notice Get all withdrawal indices for an address
     * @param recipient The address to query
     * @return Array of withdrawal indices
     */
    function getWithdrawalIndices(address recipient) external view returns (uint256[] memory) {
        return withdrawalsByAddress[recipient];
    }

    /**
     * @notice Get a specific deposit by index
     * @param index The deposit index
     * @return The deposit data
     */
    function getDeposit(uint256 index) external view returns (Deposit memory) {
        require(index < deposits.length, "Treasury: deposit index out of bounds");
        return deposits[index];
    }

    /**
     * @notice Get a specific withdrawal by index
     * @param index The withdrawal index
     * @return The withdrawal data
     */
    function getWithdrawal(uint256 index) external view returns (Withdrawal memory) {
        require(index < withdrawals.length, "Treasury: withdrawal index out of bounds");
        return withdrawals[index];
    }

    /**
     * @notice Get the net balance (deposits - withdrawals)
     * @return The net balance in wei
     * 
     * LEARNING POINT: This calculates the difference between
     * total deposits and total withdrawals. Should match getBalance()
     * if no ETH was sent via other means.
     */
    function getNetBalance() external view returns (uint256) {
        return totalDeposits - totalWithdrawals;
    }
    
    /**
     * @notice Authorize or revoke authorization for a contract to withdraw
     * @dev Only owner (multisig) can authorize withdrawers
     * @param withdrawer The address to authorize/revoke
     * @param authorized Whether to authorize (true) or revoke (false)
     * 
     * LEARNING POINT: This allows the multisig to authorize other contracts
     * (like TaskManagement) to withdraw funds for specific purposes. This enables
     * automatic payments while maintaining multisig control over authorization.
     */
    function setAuthorizedWithdrawer(address withdrawer, bool authorized) external onlyOwner {
        require(withdrawer != address(0), "Treasury: withdrawer cannot be zero address");
        authorizedWithdrawers[withdrawer] = authorized;
        emit AuthorizedWithdrawerUpdated(withdrawer, authorized);
    }
}

