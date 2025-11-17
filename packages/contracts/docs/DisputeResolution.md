# Solidity API

## DisputeResolution

A contract for resolving disputes in collaborative work

_Step 8: Dispute Resolution contract owned by multisig

LEARNING POINT: This contract provides a structured way to handle disputes
that may arise during collaboration. It allows parties to submit disputes,
provide evidence, and have them resolved by the multisig (or governance).

Key concepts:
- Disputes: Structured disagreements that need resolution
- Evidence: IPFS CIDs or other proof submitted by parties
- Resolution: Decision made by authorized resolver (multisig/governance)
- Dispute types: Can be related to tasks, payments, or general collaboration_

### DisputeStatus

Enumeration of dispute statuses

_Represents the lifecycle of a dispute_

```solidity
enum DisputeStatus {
  Created,
  EvidenceSubmitted,
  UnderReview,
  Resolved,
  Cancelled
}
```

### DisputeType

Enumeration of dispute types

_Categorizes what the dispute is about_

```solidity
enum DisputeType {
  Task,
  Payment,
  General
}
```

### Dispute

Structure to represent a dispute

_Contains all information about a dispute_

```solidity
struct Dispute {
  uint256 id;
  address initiator;
  address counterparty;
  enum DisputeResolution.DisputeType disputeType;
  uint256 relatedId;
  string description;
  string initiatorEvidence;
  string counterpartyEvidence;
  enum DisputeResolution.DisputeStatus status;
  address resolver;
  string resolution;
  uint256 createdAt;
  uint256 resolvedAt;
  bool exists;
}
```

### disputeCount

```solidity
uint256 disputeCount
```

### disputes

```solidity
mapping(uint256 => struct DisputeResolution.Dispute) disputes
```

### disputesByInitiator

```solidity
mapping(address => uint256[]) disputesByInitiator
```

### disputesByParty

```solidity
mapping(address => uint256[]) disputesByParty
```

### disputesByResolver

```solidity
mapping(address => uint256[]) disputesByResolver
```

### DisputeCreated

```solidity
event DisputeCreated(uint256 disputeId, address initiator, address counterparty, enum DisputeResolution.DisputeType disputeType, uint256 relatedId)
```

### EvidenceSubmitted

```solidity
event EvidenceSubmitted(uint256 disputeId, address submitter, string evidence)
```

### DisputeResolved

```solidity
event DisputeResolved(uint256 disputeId, address resolver, string resolution)
```

### DisputeCancelled

```solidity
event DisputeCancelled(uint256 disputeId, address cancelledBy)
```

### constructor

```solidity
constructor(address initialOwner) public
```

Constructor sets the initial owner

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| initialOwner | address | The address that will own this contract (multisig) |

### createDispute

```solidity
function createDispute(address counterparty, enum DisputeResolution.DisputeType disputeType, uint256 relatedId, string description, string evidence) external returns (uint256 disputeId)
```

Create a new dispute

_Anyone can create a dispute, but they must specify a counterparty_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| counterparty | address | The other party in the dispute |
| disputeType | enum DisputeResolution.DisputeType | The type of dispute |
| relatedId | uint256 | Related task ID or other identifier (0 if none) |
| description | string | Description of the dispute |
| evidence | string | IPFS CID or initial evidence |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| disputeId | uint256 | The ID of the newly created dispute LEARNING POINT: Disputes can be created by anyone, allowing for transparent conflict resolution. The counterparty can then submit their own evidence. The multisig (or governance) acts as the resolver. |

### submitEvidence

```solidity
function submitEvidence(uint256 disputeId, string evidence) external
```

Submit evidence for a dispute

_Can be called by initiator or counterparty_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| disputeId | uint256 | The ID of the dispute |
| evidence | string | IPFS CID or evidence to submit LEARNING POINT: Both parties can submit evidence to support their case. Evidence is stored as strings (typically IPFS CIDs) allowing for off-chain document storage with on-chain references. |

### resolveDispute

```solidity
function resolveDispute(uint256 disputeId, string resolution) external
```

Resolve a dispute

_Only owner (multisig) can resolve disputes_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| disputeId | uint256 | The ID of the dispute to resolve |
| resolution | string | Description of the resolution/outcome LEARNING POINT: The multisig acts as the resolver, ensuring both parties must agree on dispute resolution. In a more advanced system, this could be delegated to governance or a jury system. |

### markUnderReview

```solidity
function markUnderReview(uint256 disputeId) external
```

Mark a dispute as under review

_Only owner (multisig) can mark disputes as under review_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| disputeId | uint256 | The ID of the dispute LEARNING POINT: This allows the resolver to indicate they're actively reviewing the dispute, providing transparency in the resolution process. |

### cancelDispute

```solidity
function cancelDispute(uint256 disputeId) external
```

Cancel a dispute

_Can be called by initiator or owner_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| disputeId | uint256 | The ID of the dispute to cancel LEARNING POINT: Allows parties to withdraw disputes if they reach an agreement outside the system, or the owner can cancel invalid disputes. |

### getDispute

```solidity
function getDispute(uint256 disputeId) external view returns (struct DisputeResolution.Dispute)
```

Get a dispute by ID

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| disputeId | uint256 | The ID of the dispute |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct DisputeResolution.Dispute | The dispute struct |

### getDisputeCount

```solidity
function getDisputeCount() external view returns (uint256)
```

Get total number of disputes

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The total dispute count |

