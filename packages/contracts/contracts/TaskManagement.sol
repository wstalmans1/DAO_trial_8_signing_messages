// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TaskManagement
 * @notice A contract for managing collaborative tasks between parties
 * @dev Step 7: Task Management contract owned by multisig
 * 
 * LEARNING POINT: This contract enables structured task management for collaboration.
 * Tasks can be created, assigned, tracked, and marked as complete. The multisig
 * controls the contract, ensuring both parties agree on task management.
 * 
 * Key concepts:
 * - Tasks: Structured work items with descriptions, assignments, and status
 * - State machine: Tasks move through states (Created → Assigned → InProgress → Completed)
 * - Assignment: Tasks can be assigned to specific addresses
 * - Completion: Tasks can be marked complete with verification
 */
contract TaskManagement is Ownable {
    /**
     * @notice Enumeration of task statuses
     * @dev Represents the lifecycle of a task
     */
    enum TaskStatus {
        Created,      // Task created but not yet assigned
        Assigned,     // Task assigned to someone
        InProgress,   // Task is being worked on
        Completed,    // Task is completed
        Cancelled     // Task was cancelled
    }

    /**
     * @notice Structure to represent a task
     * @dev Contains all information about a task
     */
    struct Task {
        uint256 id;                    // Unique task ID
        address creator;                // Who created the task
        address assignee;               // Who the task is assigned to (address(0) if unassigned)
        string title;                  // Task title
        string description;            // Detailed description
        TaskStatus status;             // Current status
        uint256 createdAt;             // When task was created
        uint256 assignedAt;            // When task was assigned (0 if not assigned)
        uint256 completedAt;           // When task was completed (0 if not completed)
        bool exists;                   // Whether this task exists
    }

    // Task tracking
    uint256 public taskCount;          // Total number of tasks
    mapping(uint256 => Task) public tasks; // task ID => Task
    
    // Mapping: address => array of task IDs they created
    mapping(address => uint256[]) public tasksByCreator;
    
    // Mapping: address => array of task IDs assigned to them
    mapping(address => uint256[]) public tasksByAssignee;
    
    // Mapping: address => array of task IDs (all tasks they're involved in)
    mapping(address => uint256[]) public tasksByParticipant;

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
    
    event TaskCancelled(
        uint256 indexed taskId,
        address indexed cancelledBy
    );

    /**
     * @notice Constructor sets the initial owner
     * @param initialOwner The address that will be the initial owner (multisig)
     * 
     * LEARNING POINT: The multisig controls task management, ensuring both parties
     * agree on task assignments and status changes.
     */
    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @notice Create a new task
     * @dev Anyone can create a task
     * @param title Short title for the task
     * @param description Detailed description of the task
     * @return taskId The ID of the created task
     * 
     * LEARNING POINT: Creating a task doesn't assign it. Tasks start in "Created" status
     * and must be explicitly assigned to someone.
     */
    function createTask(string memory title, string memory description)
        external
        returns (uint256 taskId)
    {
        require(bytes(title).length > 0, "TaskManagement: title cannot be empty");
        require(bytes(description).length > 0, "TaskManagement: description cannot be empty");
        
        taskId = taskCount;
        taskCount++;
        
        tasks[taskId] = Task({
            id: taskId,
            creator: msg.sender,
            assignee: address(0),
            title: title,
            description: description,
            status: TaskStatus.Created,
            createdAt: block.timestamp,
            assignedAt: 0,
            completedAt: 0,
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
     * 
     * LEARNING POINT: Assignment requires multisig approval, ensuring both parties
     * agree on who should work on what. This prevents unilateral task assignment.
     */
    function assignTask(uint256 taskId, address assignee) external onlyOwner {
        Task storage task = tasks[taskId];
        
        require(task.exists, "TaskManagement: task does not exist");
        require(assignee != address(0), "TaskManagement: assignee cannot be zero address");
        require(
            task.status == TaskStatus.Created || task.status == TaskStatus.Assigned,
            "TaskManagement: task cannot be assigned in current status"
        );
        
        // Update task
        task.assignee = assignee;
        task.status = TaskStatus.Assigned;
        task.assignedAt = block.timestamp;
        
        // Track tasks by assignee
        tasksByAssignee[assignee].push(taskId);
        tasksByParticipant[assignee].push(taskId);
        
        emit TaskAssigned(taskId, assignee, msg.sender);
        emit TaskStatusUpdated(taskId, TaskStatus.Created, TaskStatus.Assigned, msg.sender);
    }

    /**
     * @notice Update task status to InProgress
     * @dev Only the assignee can mark their task as in progress
     * @param taskId The ID of the task
     * 
     * LEARNING POINT: The assignee can update their own task status to show progress.
     * This allows for self-management while still requiring assignment approval.
     */
    function startTask(uint256 taskId) external {
        Task storage task = tasks[taskId];
        
        require(task.exists, "TaskManagement: task does not exist");
        require(task.assignee == msg.sender, "TaskManagement: only assignee can start task");
        require(
            task.status == TaskStatus.Assigned,
            "TaskManagement: task must be assigned to start"
        );
        
        TaskStatus oldStatus = task.status;
        task.status = TaskStatus.InProgress;
        
        emit TaskStatusUpdated(taskId, oldStatus, TaskStatus.InProgress, msg.sender);
    }

    /**
     * @notice Mark a task as completed
     * @dev Only the assignee can complete their task
     * @param taskId The ID of the task to complete
     * 
     * LEARNING POINT: The assignee marks their own work as complete. In a more
     * sophisticated system, completion might require verification or approval.
     */
    function completeTask(uint256 taskId) external {
        Task storage task = tasks[taskId];
        
        require(task.exists, "TaskManagement: task does not exist");
        require(task.assignee == msg.sender, "TaskManagement: only assignee can complete task");
        require(
            task.status == TaskStatus.InProgress || task.status == TaskStatus.Assigned,
            "TaskManagement: task must be in progress or assigned to complete"
        );
        
        TaskStatus oldStatus = task.status;
        task.status = TaskStatus.Completed;
        task.completedAt = block.timestamp;
        
        emit TaskStatusUpdated(taskId, oldStatus, TaskStatus.Completed, msg.sender);
        emit TaskCompleted(taskId, msg.sender, block.timestamp);
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
            task.status != TaskStatus.Completed && task.status != TaskStatus.Cancelled,
            "TaskManagement: cannot cancel completed or already cancelled task"
        );
        
        TaskStatus oldStatus = task.status;
        task.status = TaskStatus.Cancelled;
        
        emit TaskStatusUpdated(taskId, oldStatus, TaskStatus.Cancelled, msg.sender);
        emit TaskCancelled(taskId, msg.sender);
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

