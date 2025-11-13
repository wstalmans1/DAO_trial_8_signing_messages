# Solidity API

## SimpleMultisig

A simple 2-of-2 multisig wallet for collaboration

_Step 3: Learning how multisig wallets work

LEARNING POINT: This is a simple multisig wallet that requires both parties
to approve any transaction before it can be executed. This ensures shared control._

### Transaction

Structure to represent a pending transaction

_Stores transaction details until both parties approve_

```solidity
struct Transaction {
  address to;
  uint256 value;
  bytes data;
  bool executed;
  uint256 approvals;
}
```

### owner1

```solidity
address owner1
```

### owner2

```solidity
address owner2
```

### transactions

```solidity
mapping(uint256 => struct SimpleMultisig.Transaction) transactions
```

### approvals

```solidity
mapping(uint256 => mapping(address => bool)) approvals
```

### transactionCount

```solidity
uint256 transactionCount
```

### TransactionCreated

```solidity
event TransactionCreated(uint256 transactionId, address to, uint256 value, bytes data)
```

### TransactionApproved

```solidity
event TransactionApproved(uint256 transactionId, address approver)
```

### TransactionExecuted

```solidity
event TransactionExecuted(uint256 transactionId, address to, uint256 value)
```

### constructor

```solidity
constructor(address _owner1, address _owner2) public
```

Constructor sets the two owners

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _owner1 | address | First owner address |
| _owner2 | address | Second owner address LEARNING POINT: Both owners must be different addresses. This creates a 2-of-2 multisig where both must approve transactions. |

### onlyOwner

```solidity
modifier onlyOwner()
```

Modifier to check if caller is one of the owners

_Only owner1 or owner2 can call functions with this modifier_

### createTransaction

```solidity
function createTransaction(address to, uint256 value, bytes data) external returns (uint256 transactionId)
```

Create a new transaction

_Either owner can create a transaction, but both must approve to execute_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | Destination address for the transaction |
| value | uint256 | Amount of ETH to send (in wei) |
| data | bytes | Call data (encoded function call) |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| transactionId | uint256 | The ID of the created transaction LEARNING POINT: Creating a transaction doesn't execute it. Both owners must approve before it can be executed. |

### approveTransaction

```solidity
function approveTransaction(uint256 transactionId) external
```

Approve a transaction

_Each owner can approve once. When both approve, transaction can be executed._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| transactionId | uint256 | The ID of the transaction to approve LEARNING POINT: This is the core of multisig - both parties must approve. If you approve, you can't un-approve (for simplicity in this learning version). |

### executeTransaction

```solidity
function executeTransaction(uint256 transactionId) external
```

Execute a transaction

_Can only execute if both owners have approved (2-of-2 requirement)_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| transactionId | uint256 | The ID of the transaction to execute LEARNING POINT: This is where the 2-of-2 requirement is enforced. Both owners must have approved before execution is possible. |

### getTransaction

```solidity
function getTransaction(uint256 transactionId) external view returns (struct SimpleMultisig.Transaction transaction)
```

Get transaction details

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| transactionId | uint256 | The ID of the transaction |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| transaction | struct SimpleMultisig.Transaction | The transaction details LEARNING POINT: This is a view function - anyone can check transaction status. |

### hasApproved

```solidity
function hasApproved(uint256 transactionId, address owner) external view returns (bool)
```

Check if an owner has approved a transaction

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| transactionId | uint256 | The ID of the transaction |
| owner | address | The owner address to check |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | True if the owner has approved |

### receive

```solidity
receive() external payable
```

Receive ETH

_Allows the multisig wallet to receive ETH_

### getBalance

```solidity
function getBalance() external view returns (uint256)
```

Get the balance of this multisig wallet

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The balance in wei |

