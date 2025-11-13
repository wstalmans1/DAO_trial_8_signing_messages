// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TaskManagement
 * @notice A contract for managing collaborative tasks with payment-for-delivery
 * @dev Step 7: Task Management contract owned by multisig
 * 
 * LEARNING POINT: This contract enables structured task management for collaboration
 * with a payment system. Tasks go through review before payment is released.
 * 
 * Key concepts:
 * - Tasks: Structured work items with descriptions, assignments, and payment
 * - State machine: Created → Assigned → InProgress → UnderReview → Accepted/NeedsRevision
 * - Review system: Completed tasks are reviewed by the assigner
 * - Payment: Automatic payment upon acceptance via Treasury contract
 */
contract TaskManagement is Ownable {
    /**
     * @notice Enumeration of task statuses
     * @dev Represents the lifecycle of a task
     */
    enum TaskStatus {
        Created,        // Task created but not yet assigned
        Assigned,       // Task assigned to someone
        InProgress,     // Task is being worked on
        UnderReview,    // Task completed, submitted for review
        Accepted,       // Task accepted and payment released
        NeedsRevision,  // Task sent back for revision
        Cancelled       // Task was cancelled
    }

    /**
     * @notice Structure to represent a task
     * @dev Contains all information about a task
     */
    struct Task {
        uint256 id;                    // Unique task ID
        address creator;               // Who created the task
        address assignee;              // Who the task is assigned to (address(0) if unassigned)
        address assigner;              // Who assigned the task (the reviewer)
        string title;                  // Task title
        string description;            // Detailed description
        uint256 paymentAmount;         // Payment amount in wei (0 if no payment)
        TaskStatus status;             // Current status
        string reviewComment;         // Comment from reviewer (if sent back for revision)
        uint256 createdAt;             // When task was created
        uint256 assignedAt;            // When task was assigned (0 if not assigned)
        uint256 completedAt;           // When task was completed/submitted (0 if not completed)
        uint256 acceptedAt;             // When task was accepted (0 if not accepted)
        bool exists;                   // Whether this task exists
    }

    // Treasury contract address for payments
    address public treasury;
    
    // Task tracking
    uint256 public taskCount;          // Total number of tasks
    mapping(uint256 => Task) public tasks; // task ID => Task
    
    // Mapping: address => array of task IDs they created
    mapping(address => uint256[]) public tasksByCreator;
    
    // Mapping: address => array of task IDs assigned to them
    mapping(address => uint256[]) public tasksByAssignee;
    
    // Mapping: address => array of task IDs (all tasks they're involved in)
    mapping(address => uint256[]) public tasksByParticipant;
    
    // Mapping: address => array of task IDs they assigned (for review)
    mapping(address => uint256[]) public tasksByAssigner;

    // Events
    event TaskCreated(
        uint256 indexed taskId,
        address indexed creator,
        string title
    );
    
    event TaskAssigned(
        uint256 indexed taskId,
        address indexed assignee,
        address indexed assignedBy
    );
    
    event TaskStatusUpdated(
        uint256 indexed taskId,
        TaskStatus oldStatus,
        TaskStatus newStatus,
        address indexed updatedBy
    );
    
    event TaskCompleted(
        uint256 indexed taskId,
        address indexed completedBy,
        uint256 completedAt
    );
    
    event TaskSubmittedForReview(
        uint256 indexed taskId,
        address indexed submittedBy
    );
    
    event TaskAccepted(
        uint256 indexed taskId,
        address indexed acceptedBy,
        uint256 paymentAmount,
        uint256 acceptedAt
    );
    
    event TaskRevisionRequested(
        uint256 indexed taskId,
        address indexed requestedBy,
        string comment
    );
    
    event TaskCancelled(
        uint256 indexed taskId,
        address indexed cancelledBy
    );
    
    event TreasuryUpdated(address oldTreasury, address newTreasury);

    /**
     * @notice Constructor sets the initial owner and treasury
     * @param initialOwner The address that will be the initial owner (multisig)
     * @param _treasury The address of the Treasury contract for payments
     * 
     * LEARNING POINT: The multisig controls task management, ensuring both parties
     * agree on task assignments and status changes. The Treasury contract handles payments.
     */
    constructor(address initialOwner, address _treasury) Ownable(initialOwner) {
        require(_treasury != address(0), "TaskManagement: treasury cannot be zero address");
        treasury = _treasury;
    }

    /**
     * @notice Create a new task
     * @dev Anyone can create a task
     * @param title Short title for the task
     * @param description Detailed description of the task
     * @param paymentAmount Payment amount in wei (can be 0)
     * @return taskId The ID of the created task
     * 
     * LEARNING POINT: Creating a task doesn't assign it. Tasks start in "Created" status
     * and must be explicitly assigned to someone. Payment amount is set at creation.
     */
    function createTask(
        string memory title,
        string memory description,
        uint256 paymentAmount
    ) external returns (uint256 taskId) {
        require(bytes(title).length > 0, "TaskManagement: title cannot be empty");
        require(bytes(description).length > 0, "TaskManagement: description cannot be empty");
        
        taskId = taskCount;
        taskCount++;
        
        tasks[taskId] = Task({
            id: taskId,
            creator: msg.sender,
            assignee: address(0),
            assigner: address(0),
            title: title,
            description: description,
            paymentAmount: paymentAmount,
            status: TaskStatus.Created,
            reviewComment: "",
            createdAt: block.timestamp,
            assignedAt: 0,
            completedAt: 0,
            acceptedAt: 0,
            exists: true
        });
        
        // Track tasks by creator
        tasksByCreator[msg.sender].push(taskId);
        tasksByParticipant[msg.sender].push(taskId);
        
        emit TaskCreated(taskId, msg.sender, title);
    }

    /**
     * @notice Assign a task to someone
     * @dev Only owner (multisig) can assign tasks
     * @param taskId The ID of the task to assign
     * @param assignee The address to assign the task to
     * @param paymentAmount Payment amount in wei (can override original amount)
     * 
     * LEARNING POINT: Assignment requires multisig approval, ensuring both parties
     * agree on who should work on what. The assigner (msg.sender) becomes the reviewer.
     * Payment amount can be set or updated during assignment.
     */
    function assignTask(
        uint256 taskId,
        address assignee,
        uint256 paymentAmount
    ) external onlyOwner {
        Task storage task = tasks[taskId];
        
        require(task.exists, "TaskManagement: task does not exist");
        require(assignee != address(0), "TaskManagement: assignee cannot be zero address");
        require(
            task.status == TaskStatus.Created || 
            task.status == TaskStatus.Assigned || 
            task.status == TaskStatus.NeedsRevision,
            "TaskManagement: task cannot be assigned in current status"
        );
        
        // Update task
        task.assignee = assignee;
        task.assigner = msg.sender; // The assigner becomes the reviewer
        task.paymentAmount = paymentAmount; // Update payment amount
        task.status = TaskStatus.Assigned;
        task.assignedAt = block.timestamp;
        task.reviewComment = ""; // Clear any previous review comments
        
        // Track tasks by assignee and assigner
        tasksByAssignee[assignee].push(taskId);
        tasksByParticipant[assignee].push(taskId);
        tasksByAssigner[msg.sender].push(taskId);
        tasksByParticipant[msg.sender].push(taskId);
        
        emit TaskAssigned(taskId, assignee, msg.sender);
        emit TaskStatusUpdated(taskId, task.status, TaskStatus.Assigned, msg.sender);
    }

    /**
     * @notice Update task status to InProgress
     * @dev Only the assignee can mark their task as in progress
     * @param taskId The ID of the task
     * 
     * LEARNING POINT: The assignee can update their own task status to show progress.
     * This allows for self-management while still requiring assignment approval.
     * Tasks that need revision can also be restarted.
     */
    function startTask(uint256 taskId) external {
        Task storage task = tasks[taskId];
        
        require(task.exists, "TaskManagement: task does not exist");
        require(task.assignee == msg.sender, "TaskManagement: only assignee can start task");
        require(
            task.status == TaskStatus.Assigned || task.status == TaskStatus.NeedsRevision,
            "TaskManagement: task must be assigned or need revision to start"
        );
        
        TaskStatus oldStatus = task.status;
        task.status = TaskStatus.InProgress;
        
        emit TaskStatusUpdated(taskId, oldStatus, TaskStatus.InProgress, msg.sender);
    }

    /**
     * @notice Mark a task as completed and submit for review
     * @dev Only the assignee can complete their task
     * @param taskId The ID of the task to complete
     * 
     * LEARNING POINT: When an assignee completes a task, it goes to "UnderReview" status.
     * The assigner (who assigned the task) must then review and either accept (with payment)
     * or request revision with comments.
     */
    function completeTask(uint256 taskId) external {
        Task storage task = tasks[taskId];
        
        require(task.exists, "TaskManagement: task does not exist");
        require(task.assignee == msg.sender, "TaskManagement: only assignee can complete task");
        require(
            task.status == TaskStatus.InProgress || 
            task.status == TaskStatus.Assigned || 
            task.status == TaskStatus.NeedsRevision,
            "TaskManagement: task must be in progress, assigned, or needs revision to complete"
        );
        require(task.assigner != address(0), "TaskManagement: task must be assigned before completion");
        
        TaskStatus oldStatus = task.status;
        task.status = TaskStatus.UnderReview;
        task.completedAt = block.timestamp;
        task.reviewComment = ""; // Clear any previous review comments
        
        emit TaskStatusUpdated(taskId, oldStatus, TaskStatus.UnderReview, msg.sender);
        emit TaskCompleted(taskId, msg.sender, block.timestamp);
        emit TaskSubmittedForReview(taskId, msg.sender);
    }

    /**
     * @notice Accept a completed task and release payment
     * @dev Only the assigner (who assigned the task) can accept it
     * @param taskId The ID of the task to accept
     * 
     * LEARNING POINT: When a task is accepted, payment is automatically released
     * from the Treasury contract to the assignee. This ensures payment-for-delivery.
     * TaskManagement must be authorized in Treasury to execute withdrawals.
     * The multisig controls authorization, ensuring both parties approve TaskManagement
     * as an authorized withdrawer before automatic payments can work.
     */
    function acceptTask(uint256 taskId) external {
        Task storage task = tasks[taskId];
        
        require(task.exists, "TaskManagement: task does not exist");
        require(task.assigner == msg.sender, "TaskManagement: only assigner can accept task");
        require(task.status == TaskStatus.UnderReview, "TaskManagement: task must be under review");
        require(task.paymentAmount > 0, "TaskManagement: task has no payment amount");
        require(task.assignee != address(0), "TaskManagement: task must have an assignee");
        
        // Update task status first
        TaskStatus oldStatus = task.status;
        task.status = TaskStatus.Accepted;
        task.acceptedAt = block.timestamp;
        
        // Execute payment via Treasury
        // TaskManagement must be authorized in Treasury to call withdraw()
        (bool success, ) = treasury.call(
            abi.encodeWithSignature(
                "withdraw(address,uint256)",
                task.assignee,
                task.paymentAmount
            )
        );
        
        require(success, "TaskManagement: payment execution failed. Ensure TaskManagement is authorized in Treasury.");
        
        emit TaskStatusUpdated(taskId, oldStatus, TaskStatus.Accepted, msg.sender);
        emit TaskAccepted(taskId, msg.sender, task.paymentAmount, block.timestamp);
    }
    
    /**
     * @notice Request revision for a completed task
     * @dev Only the assigner (who assigned the task) can request revision
     * @param taskId The ID of the task to request revision for
     * @param comment Comment explaining what needs to be adjusted or completed
     * 
     * LEARNING POINT: If the work doesn't meet requirements, the assigner can send it back
     * with comments. The task goes back to "NeedsRevision" status, allowing the assignee
     * to make adjustments and resubmit.
     */
    function requestRevision(uint256 taskId, string memory comment) external {
        Task storage task = tasks[taskId];
        
        require(task.exists, "TaskManagement: task does not exist");
        require(task.assigner == msg.sender, "TaskManagement: only assigner can request revision");
        require(task.status == TaskStatus.UnderReview, "TaskManagement: task must be under review");
        require(bytes(comment).length > 0, "TaskManagement: comment cannot be empty");
        
        TaskStatus oldStatus = task.status;
        task.status = TaskStatus.NeedsRevision;
        task.reviewComment = comment;
        
        emit TaskStatusUpdated(taskId, oldStatus, TaskStatus.NeedsRevision, msg.sender);
        emit TaskRevisionRequested(taskId, msg.sender, comment);
    }
    
    /**
     * @notice Cancel a task
     * @dev Only owner (multisig) can cancel tasks
     * @param taskId The ID of the task to cancel
     * 
     * LEARNING POINT: Cancellation requires multisig approval, ensuring both parties
     * agree to cancel a task. This prevents unilateral cancellation.
     */
    function cancelTask(uint256 taskId) external onlyOwner {
        Task storage task = tasks[taskId];
        
        require(task.exists, "TaskManagement: task does not exist");
        require(
            task.status != TaskStatus.Accepted && task.status != TaskStatus.Cancelled,
            "TaskManagement: cannot cancel accepted or already cancelled task"
        );
        
        TaskStatus oldStatus = task.status;
        task.status = TaskStatus.Cancelled;
        
        emit TaskStatusUpdated(taskId, oldStatus, TaskStatus.Cancelled, msg.sender);
        emit TaskCancelled(taskId, msg.sender);
    }
    
    /**
     * @notice Update treasury address (only owner)
     * @dev Allows updating the treasury contract address
     * @param newTreasury The new treasury contract address
     */
    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "TaskManagement: treasury cannot be zero address");
        
        address oldTreasury = treasury;
        treasury = newTreasury;
        
        emit TreasuryUpdated(oldTreasury, newTreasury);
    }

    /**
     * @notice Get task details
     * @param taskId The ID of the task
     * @return task The task data
     */
    function getTask(uint256 taskId) external view returns (Task memory task) {
        require(tasks[taskId].exists, "TaskManagement: task does not exist");
        return tasks[taskId];
    }

    /**
     * @notice Get all task IDs created by an address
     * @param creator The address to query
     * @return Array of task IDs
     */
    function getTasksByCreator(address creator) external view returns (uint256[] memory) {
        return tasksByCreator[creator];
    }

    /**
     * @notice Get all task IDs assigned to an address
     * @param assignee The address to query
     * @return Array of task IDs
     */
    function getTasksByAssignee(address assignee) external view returns (uint256[] memory) {
        return tasksByAssignee[assignee];
    }

    /**
     * @notice Get all task IDs an address is involved in (created or assigned)
     * @param participant The address to query
     * @return Array of task IDs
     */
    function getTasksByParticipant(address participant) external view returns (uint256[] memory) {
        return tasksByParticipant[participant];
    }
    
    /**
     * @notice Get all task IDs assigned by an address (for review)
     * @param assigner The address to query
     * @return Array of task IDs
     */
    function getTasksByAssigner(address assigner) external view returns (uint256[] memory) {
        return tasksByAssigner[assigner];
    }

    /**
     * @notice Get task count
     * @return The total number of tasks
     */
    function getTaskCount() external view returns (uint256) {
        return taskCount;
    }

    /**
     * @notice Get tasks by status
     * @dev This is a helper function that would need to be implemented with off-chain indexing
     * For now, we provide the building blocks and clients can filter
     * @param status The status to filter by
     * @return count Number of tasks with this status
     * 
     * LEARNING POINT: On-chain filtering can be expensive. In production, you might
     * use events and off-chain indexing (like The Graph) for efficient querying.
     */
    function getTaskCountByStatus(TaskStatus status) external view returns (uint256 count) {
        for (uint256 i = 0; i < taskCount; i++) {
            if (tasks[i].status == status) {
                count++;
            }
        }
    }
}

