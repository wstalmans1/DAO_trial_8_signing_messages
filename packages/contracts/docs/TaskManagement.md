# Solidity API

## TaskManagement

A contract for managing collaborative tasks with payment-for-delivery

_Step 7: Task Management contract owned by multisig

LEARNING POINT: This contract enables structured task management for collaboration
with a payment system. Tasks go through review before payment is released.

Key concepts:
- Tasks: Structured work items with descriptions, assignments, and payment
- State machine: Created → Assigned → InProgress → UnderReview → Accepted/NeedsRevision
- Review system: Completed tasks are reviewed by the assigner
- Payment: Automatic payment upon acceptance via Treasury contract_

### TaskStatus

Enumeration of task statuses

_Represents the lifecycle of a task_

```solidity
enum TaskStatus {
  Created,
  Assigned,
  InProgress,
  UnderReview,
  Accepted,
  NeedsRevision,
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
  address assigner;
  string title;
  string description;
  uint256 paymentAmount;
  enum TaskManagement.TaskStatus status;
  string reviewComment;
  uint256 createdAt;
  uint256 assignedAt;
  uint256 completedAt;
  uint256 acceptedAt;
  bool exists;
}
```

### treasury

```solidity
address treasury
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

### tasksByAssigner

```solidity
mapping(address => uint256[]) tasksByAssigner
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

### TaskSubmittedForReview

```solidity
event TaskSubmittedForReview(uint256 taskId, address submittedBy)
```

### TaskAccepted

```solidity
event TaskAccepted(uint256 taskId, address acceptedBy, uint256 paymentAmount, uint256 acceptedAt)
```

### TaskRevisionRequested

```solidity
event TaskRevisionRequested(uint256 taskId, address requestedBy, string comment)
```

### TaskCancelled

```solidity
event TaskCancelled(uint256 taskId, address cancelledBy)
```

### TreasuryUpdated

```solidity
event TreasuryUpdated(address oldTreasury, address newTreasury)
```

### constructor

```solidity
constructor(address initialOwner, address _treasury) public
```

Constructor sets the initial owner and treasury

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| initialOwner | address | The address that will be the initial owner (multisig) |
| _treasury | address | The address of the Treasury contract for payments LEARNING POINT: The multisig controls task management, ensuring both parties agree on task assignments and status changes. The Treasury contract handles payments. |

### createTask

```solidity
function createTask(string title, string description, uint256 paymentAmount) external returns (uint256 taskId)
```

Create a new task

_Anyone can create a task_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| title | string | Short title for the task |
| description | string | Detailed description of the task |
| paymentAmount | uint256 | Payment amount in wei (can be 0) |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| taskId | uint256 | The ID of the created task LEARNING POINT: Creating a task doesn't assign it. Tasks start in "Created" status and must be explicitly assigned to someone. Payment amount is set at creation. |

### assignTask

```solidity
function assignTask(uint256 taskId, address assignee, uint256 paymentAmount) external
```

Assign a task to someone

_Only owner (multisig) can assign tasks_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| taskId | uint256 | The ID of the task to assign |
| assignee | address | The address to assign the task to |
| paymentAmount | uint256 | Payment amount in wei (can override original amount) LEARNING POINT: Assignment requires multisig approval, ensuring both parties agree on who should work on what. The assigner (msg.sender) becomes the reviewer. Payment amount can be set or updated during assignment. |

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

Mark a task as completed and submit for review

_Only the assignee can complete their task_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| taskId | uint256 | The ID of the task to complete LEARNING POINT: When an assignee completes a task, it goes to "UnderReview" status. The assigner (who assigned the task) must then review and either accept (with payment) or request revision with comments. |

### acceptTask

```solidity
function acceptTask(uint256 taskId) external
```

Accept a completed task and release payment

_Only the assigner (who assigned the task) can accept it_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| taskId | uint256 | The ID of the task to accept LEARNING POINT: When a task is accepted, payment is automatically released from the Treasury contract to the assignee. This ensures payment-for-delivery. TaskManagement must be authorized in Treasury to execute withdrawals. The multisig controls authorization, ensuring both parties approve TaskManagement as an authorized withdrawer before automatic payments can work. |

### requestRevision

```solidity
function requestRevision(uint256 taskId, string comment) external
```

Request revision for a completed task

_Only the assigner (who assigned the task) can request revision_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| taskId | uint256 | The ID of the task to request revision for |
| comment | string | Comment explaining what needs to be adjusted or completed LEARNING POINT: If the work doesn't meet requirements, the assigner can send it back with comments. The task goes back to "NeedsRevision" status, allowing the assignee to make adjustments and resubmit. |

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

### setTreasury

```solidity
function setTreasury(address newTreasury) external
```

Update treasury address (only owner)

_Allows updating the treasury contract address_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newTreasury | address | The new treasury contract address |

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

### getTasksByAssigner

```solidity
function getTasksByAssigner(address assigner) external view returns (uint256[])
```

Get all task IDs assigned by an address (for review)

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| assigner | address | The address to query |

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

