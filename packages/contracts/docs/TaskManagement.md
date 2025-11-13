# Solidity API

## TaskManagement

A contract for managing collaborative tasks between parties

_Step 7: Task Management contract owned by multisig

LEARNING POINT: This contract enables structured task management for collaboration.
Tasks can be created, assigned, tracked, and marked as complete. The multisig
controls the contract, ensuring both parties agree on task management.

Key concepts:
- Tasks: Structured work items with descriptions, assignments, and status
- State machine: Tasks move through states (Created → Assigned → InProgress → Completed)
- Assignment: Tasks can be assigned to specific addresses
- Completion: Tasks can be marked complete with verification_

### TaskStatus

Enumeration of task statuses

_Represents the lifecycle of a task_

```solidity
enum TaskStatus {
  Created,
  Assigned,
  InProgress,
  Completed,
  Cancelled
}
```

### Task

Structure to represent a task

_Contains all information about a task_

```solidity
struct Task {
  uint256 id;
  address creator;
  address assignee;
  string title;
  string description;
  enum TaskManagement.TaskStatus status;
  uint256 createdAt;
  uint256 assignedAt;
  uint256 completedAt;
  bool exists;
}
```

### taskCount

```solidity
uint256 taskCount
```

### tasks

```solidity
mapping(uint256 => struct TaskManagement.Task) tasks
```

### tasksByCreator

```solidity
mapping(address => uint256[]) tasksByCreator
```

### tasksByAssignee

```solidity
mapping(address => uint256[]) tasksByAssignee
```

### tasksByParticipant

```solidity
mapping(address => uint256[]) tasksByParticipant
```

### TaskCreated

```solidity
event TaskCreated(uint256 taskId, address creator, string title)
```

### TaskAssigned

```solidity
event TaskAssigned(uint256 taskId, address assignee, address assignedBy)
```

### TaskStatusUpdated

```solidity
event TaskStatusUpdated(uint256 taskId, enum TaskManagement.TaskStatus oldStatus, enum TaskManagement.TaskStatus newStatus, address updatedBy)
```

### TaskCompleted

```solidity
event TaskCompleted(uint256 taskId, address completedBy, uint256 completedAt)
```

### TaskCancelled

```solidity
event TaskCancelled(uint256 taskId, address cancelledBy)
```

### constructor

```solidity
constructor(address initialOwner) public
```

Constructor sets the initial owner

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| initialOwner | address | The address that will be the initial owner (multisig) LEARNING POINT: The multisig controls task management, ensuring both parties agree on task assignments and status changes. |

### createTask

```solidity
function createTask(string title, string description) external returns (uint256 taskId)
```

Create a new task

_Anyone can create a task_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| title | string | Short title for the task |
| description | string | Detailed description of the task |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| taskId | uint256 | The ID of the created task LEARNING POINT: Creating a task doesn't assign it. Tasks start in "Created" status and must be explicitly assigned to someone. |

### assignTask

```solidity
function assignTask(uint256 taskId, address assignee) external
```

Assign a task to someone

_Only owner (multisig) can assign tasks_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| taskId | uint256 | The ID of the task to assign |
| assignee | address | The address to assign the task to LEARNING POINT: Assignment requires multisig approval, ensuring both parties agree on who should work on what. This prevents unilateral task assignment. |

### startTask

```solidity
function startTask(uint256 taskId) external
```

Update task status to InProgress

_Only the assignee can mark their task as in progress_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| taskId | uint256 | The ID of the task LEARNING POINT: The assignee can update their own task status to show progress. This allows for self-management while still requiring assignment approval. |

### completeTask

```solidity
function completeTask(uint256 taskId) external
```

Mark a task as completed

_Only the assignee can complete their task_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| taskId | uint256 | The ID of the task to complete LEARNING POINT: The assignee marks their own work as complete. In a more sophisticated system, completion might require verification or approval. |

### cancelTask

```solidity
function cancelTask(uint256 taskId) external
```

Cancel a task

_Only owner (multisig) can cancel tasks_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| taskId | uint256 | The ID of the task to cancel LEARNING POINT: Cancellation requires multisig approval, ensuring both parties agree to cancel a task. This prevents unilateral cancellation. |

### getTask

```solidity
function getTask(uint256 taskId) external view returns (struct TaskManagement.Task task)
```

Get task details

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| taskId | uint256 | The ID of the task |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| task | struct TaskManagement.Task | The task data |

### getTasksByCreator

```solidity
function getTasksByCreator(address creator) external view returns (uint256[])
```

Get all task IDs created by an address

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| creator | address | The address to query |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256[] | Array of task IDs |

### getTasksByAssignee

```solidity
function getTasksByAssignee(address assignee) external view returns (uint256[])
```

Get all task IDs assigned to an address

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| assignee | address | The address to query |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256[] | Array of task IDs |

### getTasksByParticipant

```solidity
function getTasksByParticipant(address participant) external view returns (uint256[])
```

Get all task IDs an address is involved in (created or assigned)

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| participant | address | The address to query |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256[] | Array of task IDs |

### getTaskCount

```solidity
function getTaskCount() external view returns (uint256)
```

Get task count

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The total number of tasks |

### getTaskCountByStatus

```solidity
function getTaskCountByStatus(enum TaskManagement.TaskStatus status) external view returns (uint256 count)
```

Get tasks by status

_This is a helper function that would need to be implemented with off-chain indexing
For now, we provide the building blocks and clients can filter_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| status | enum TaskManagement.TaskStatus | The status to filter by |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| count | uint256 | Number of tasks with this status LEARNING POINT: On-chain filtering can be expensive. In production, you might use events and off-chain indexing (like The Graph) for efficient querying. |

