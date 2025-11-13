# Solidity API

## Treasury

A treasury contract for managing collaboration funds

_Step 5: Payment/Treasury contract owned by multisig

LEARNING POINT: This contract holds ETH for the collaboration.
The multisig wallet (as owner) controls withdrawals, ensuring both parties
must approve any fund movement. Anyone can deposit ETH.

Key concepts:
- receive() function: Allows contract to receive ETH
- onlyOwner modifier: Restricts withdrawals to owner (multisig)
- Events: Track all deposits and withdrawals for transparency
- Balance tracking: Monitor total deposits vs withdrawals_

### Deposit

Structure to track a deposit transaction

_Stores information about each deposit_

```solidity
struct Deposit {
  address depositor;
  uint256 amount;
  uint256 timestamp;
}
```

### Withdrawal

Structure to track a withdrawal transaction

_Stores information about each withdrawal_

```solidity
struct Withdrawal {
  address recipient;
  uint256 amount;
  uint256 timestamp;
  bool executed;
}
```

### totalDeposits

```solidity
uint256 totalDeposits
```

### totalWithdrawals

```solidity
uint256 totalWithdrawals
```

### deposits

```solidity
struct Treasury.Deposit[] deposits
```

### withdrawals

```solidity
struct Treasury.Withdrawal[] withdrawals
```

### depositsByAddress

```solidity
mapping(address => uint256[]) depositsByAddress
```

### withdrawalsByAddress

```solidity
mapping(address => uint256[]) withdrawalsByAddress
```

### DepositReceived

```solidity
event DepositReceived(address depositor, uint256 amount, uint256 timestamp)
```

### WithdrawalExecuted

```solidity
event WithdrawalExecuted(address recipient, uint256 amount, uint256 timestamp)
```

### EmergencyWithdrawal

```solidity
event EmergencyWithdrawal(address recipient, uint256 amount, uint256 timestamp)
```

### constructor

```solidity
constructor(address initialOwner) public
```

Constructor sets the initial owner

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| initialOwner | address | The address that will be the initial owner (multisig) LEARNING POINT: We pass the multisig address as initialOwner. This way, the multisig controls the treasury from the start. Alternatively, we could deploy with deployer as owner, then transfer to multisig. |

### receive

```solidity
receive() external payable
```

Receive ETH deposits

_This function is called when ETH is sent to the contract

LEARNING POINT: The `receive()` function is a special Solidity function
that gets called when ETH is sent directly to the contract address.
It must be external and payable. Anyone can deposit ETH this way._

### fallback

```solidity
fallback() external payable
```

Fallback function for ETH deposits

_Called when ETH is sent but no function matches

LEARNING POINT: Fallback functions handle calls that don't match
any function signature. We redirect to receive()._

### withdraw

```solidity
function withdraw(address recipient, uint256 amount) external
```

Withdraw ETH from treasury

_Only the owner (multisig) can call this function_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| recipient | address | The address to send ETH to |
| amount | uint256 | The amount of ETH to withdraw (in wei) LEARNING POINT: The `onlyOwner` modifier ensures only the multisig can withdraw. Since the multisig requires 2-of-2 approval, both parties must approve any withdrawal transaction. |

### getBalance

```solidity
function getBalance() external view returns (uint256)
```

Get the current balance of the treasury

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The current balance in wei LEARNING POINT: This is a view function (free to call). It returns the contract's current ETH balance. |

### getDepositCount

```solidity
function getDepositCount() external view returns (uint256)
```

Get total number of deposits

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The number of deposits made |

### getWithdrawalCount

```solidity
function getWithdrawalCount() external view returns (uint256)
```

Get total number of withdrawals

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The number of withdrawals made |

### getDepositIndices

```solidity
function getDepositIndices(address depositor) external view returns (uint256[])
```

Get all deposit indices for an address

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| depositor | address | The address to query |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256[] | Array of deposit indices |

### getWithdrawalIndices

```solidity
function getWithdrawalIndices(address recipient) external view returns (uint256[])
```

Get all withdrawal indices for an address

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| recipient | address | The address to query |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256[] | Array of withdrawal indices |

### getDeposit

```solidity
function getDeposit(uint256 index) external view returns (struct Treasury.Deposit)
```

Get a specific deposit by index

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | The deposit index |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct Treasury.Deposit | The deposit data |

### getWithdrawal

```solidity
function getWithdrawal(uint256 index) external view returns (struct Treasury.Withdrawal)
```

Get a specific withdrawal by index

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | The withdrawal index |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct Treasury.Withdrawal | The withdrawal data |

### getNetBalance

```solidity
function getNetBalance() external view returns (uint256)
```

Get the net balance (deposits - withdrawals)

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The net balance in wei LEARNING POINT: This calculates the difference between total deposits and total withdrawals. Should match getBalance() if no ETH was sent via other means. |

