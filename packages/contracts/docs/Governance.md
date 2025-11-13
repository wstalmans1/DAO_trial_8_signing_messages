# Solidity API

## Governance

A simple governance contract for collaborative decision-making

_Step 6: Voting/Governance contract owned by multisig

LEARNING POINT: This contract enables on-chain governance where proposals
can be created, voted on, and executed. The multisig controls the contract,
but proposals allow for structured decision-making.

Key concepts:
- Proposals: Structured decisions that can be voted on
- Voting: Each proposal can be voted for/against
- Execution: Approved proposals can execute actions
- Quorum: Minimum votes required for a proposal to pass_

### Proposal

Structure to represent a proposal

_Contains all information about a governance proposal_

```solidity
struct Proposal {
  uint256 id;
  address proposer;
  string description;
  address target;
  bytes data;
  uint256 value;
  uint256 forVotes;
  uint256 againstVotes;
  uint256 startTime;
  uint256 endTime;
  bool executed;
  bool cancelled;
  mapping(address => bool) hasVoted;
  mapping(address => bool) voteChoice;
}
```

### votingPeriod

```solidity
uint256 votingPeriod
```

### quorumThreshold

```solidity
uint256 quorumThreshold
```

### proposalCount

```solidity
uint256 proposalCount
```

### proposals

```solidity
mapping(uint256 => struct Governance.Proposal) proposals
```

### ProposalCreated

```solidity
event ProposalCreated(uint256 proposalId, address proposer, string description, address target, uint256 value, bytes data)
```

### VoteCast

```solidity
event VoteCast(uint256 proposalId, address voter, bool support, uint256 forVotes, uint256 againstVotes)
```

### ProposalExecuted

```solidity
event ProposalExecuted(uint256 proposalId, address target, uint256 value)
```

### ProposalCancelled

```solidity
event ProposalCancelled(uint256 proposalId)
```

### VotingPeriodUpdated

```solidity
event VotingPeriodUpdated(uint256 oldPeriod, uint256 newPeriod)
```

### QuorumThresholdUpdated

```solidity
event QuorumThresholdUpdated(uint256 oldThreshold, uint256 newThreshold)
```

### constructor

```solidity
constructor(address initialOwner, uint256 _votingPeriod, uint256 _quorumThreshold) public
```

Constructor sets the initial owner and governance parameters

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| initialOwner | address | The address that will be the initial owner (multisig) |
| _votingPeriod | uint256 | Voting period in seconds (e.g., 7 days = 604800) |
| _quorumThreshold | uint256 | Minimum number of votes required for a proposal to pass LEARNING POINT: We set reasonable defaults for voting period and quorum. The voting period determines how long people have to vote. The quorum ensures enough participation for decisions to be valid. |

### createProposal

```solidity
function createProposal(string description, address target, uint256 value, bytes data) external returns (uint256 proposalId)
```

Create a new proposal

_Anyone can create a proposal, but only owner can execute_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| description | string | Human-readable description of the proposal |
| target | address | Target contract address (address(0) if no execution needed) |
| value | uint256 | ETH value to send (0 if no ETH transfer) |
| data | bytes | Encoded function call data (empty if no execution) |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | The ID of the created proposal LEARNING POINT: Creating a proposal doesn't execute anything. It just opens voting. After voting ends and quorum is met, the owner (multisig) can execute the proposal. |

### vote

```solidity
function vote(uint256 proposalId, bool support) external
```

Vote on a proposal

_Anyone can vote, but can only vote once per proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | The ID of the proposal to vote on |
| support | bool | true = vote for, false = vote against LEARNING POINT: This implements simple binary voting (for/against). Each address can vote once. More sophisticated systems might use token-weighted voting or delegation. |

### executeProposal

```solidity
function executeProposal(uint256 proposalId) external
```

Execute a proposal

_Only owner (multisig) can execute, and only if proposal passed_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | The ID of the proposal to execute LEARNING POINT: Execution requires: 1. Voting period has ended 2. Quorum threshold is met (enough votes) 3. More for votes than against votes 4. Proposal hasn't been executed or cancelled The multisig must approve this execution, ensuring both parties agree to execute the proposal. |

### cancelProposal

```solidity
function cancelProposal(uint256 proposalId) external
```

Cancel a proposal (only owner)

_Owner can cancel proposals before execution_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | The ID of the proposal to cancel LEARNING POINT: The owner (multisig) can cancel proposals. This provides a safety mechanism if a proposal is problematic. |

### setVotingPeriod

```solidity
function setVotingPeriod(uint256 newVotingPeriod) external
```

Update voting period (only owner)

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newVotingPeriod | uint256 | New voting period in seconds |

### setQuorumThreshold

```solidity
function setQuorumThreshold(uint256 newQuorumThreshold) external
```

Update quorum threshold (only owner)

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newQuorumThreshold | uint256 | New quorum threshold |

### getProposal

```solidity
function getProposal(uint256 proposalId) external view returns (uint256 id, address proposer, string description, address target, uint256 value, uint256 forVotes, uint256 againstVotes, uint256 startTime, uint256 endTime, bool executed, bool cancelled)
```

Get proposal details

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | The ID of the proposal |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| id | uint256 | Proposal ID |
| proposer | address | Address of proposer |
| description | string | Proposal description |
| target | address | Target contract address |
| value | uint256 | ETH value |
| forVotes | uint256 | Number of for votes |
| againstVotes | uint256 | Number of against votes |
| startTime | uint256 | Voting start time |
| endTime | uint256 | Voting end time |
| executed | bool | Whether executed |
| cancelled | bool | Whether cancelled LEARNING POINT: This view function allows anyone to check proposal status. Note: We can't return mappings directly, so we return individual values. |

### getVote

```solidity
function getVote(uint256 proposalId, address voter) external view returns (bool hasVoted, bool voteChoice)
```

Check if an address has voted on a proposal

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | The ID of the proposal |
| voter | address | The address to check |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| hasVoted | bool | Whether the address has voted |
| voteChoice | bool | true if voted for, false if voted against (only valid if hasVoted is true) |

### canExecute

```solidity
function canExecute(uint256 proposalId) external view returns (bool, string)
```

Check if a proposal can be executed

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | The ID of the proposal |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Whether the proposal can be executed |
| [1] | string | reason Reason why it can't be executed (if applicable) |

