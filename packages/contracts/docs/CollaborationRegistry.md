# Solidity API

## CollaborationRegistry

This contract stores mutual acknowledgments between two parties

_Step 2: Now Ownable - can be controlled by a multisig wallet

LEARNING POINT: This contract inherits from OpenZeppelin's Ownable.
The owner (initially deployer, later multisig) can control certain functions.
This allows the multisig to manage the registry settings._

### Acknowledgment

Structure to store an acknowledgment

_Contains all the data needed to verify a signature_

```solidity
struct Acknowledgment {
  address signer;
  address target;
  string message;
  bytes signature;
  uint256 timestamp;
  bool exists;
}
```

### MutualHandshake

Structure to represent a mutual handshake

_Both parties must acknowledge each other for this to be complete_

```solidity
struct MutualHandshake {
  address partyA;
  address partyB;
  bytes32 acknowledgmentAHash;
  bytes32 acknowledgmentBHash;
  uint256 timestamp;
  bool isActive;
}
```

### acknowledgments

```solidity
mapping(bytes32 => struct CollaborationRegistry.Acknowledgment) acknowledgments
```

### acknowledgmentsByAddress

```solidity
mapping(address => bytes32[]) acknowledgmentsByAddress
```

### handshakes 

```solidity
mapping(bytes32 => struct CollaborationRegistry.MutualHandshake) handshakes
```

### handshakesByAddress

```solidity
mapping(address => bytes32[]) handshakesByAddress
```

### AcknowledgmentSubmitted

```solidity
event AcknowledgmentSubmitted(address signer, address target, bytes32 acknowledgmentHash)
```

### MutualHandshakeCreated

```solidity
event MutualHandshakeCreated(address partyA, address partyB, bytes32 handshakeHash)
```

### constructor

```solidity
constructor(address initialOwner) public
```

Constructor sets the initial owner

_The deployer becomes the owner. Later, ownership can be transferred to a multisig._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| initialOwner | address | The address that will be the initial owner LEARNING POINT: Ownable requires an initial owner. We pass it to the Ownable constructor. This owner can later transfer ownership to a multisig wallet. |

### submitAcknowledgment

```solidity
function submitAcknowledgment(address target, string message, bytes signature) external
```

Submit an acknowledgment

_Party A or Party B calls this with their signature_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| target | address | The address of the other party they're acknowledging |
| message | string | The message they signed (must match what was signed off-chain) |
| signature | bytes | Their signature of the message LEARNING POINT: This function stores the acknowledgment. |

### _checkAndCreateHandshake

```solidity
function _checkAndCreateHandshake(address signer, address target, bytes32 newAcknowledgmentHash) internal
```

Internal function to check if both parties have acknowledged each other

_If both have acknowledged, creates a mutual handshake_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| signer | address | The person who just submitted an acknowledgment |
| target | address | The person they acknowledged |
| newAcknowledgmentHash | bytes32 | The hash of the new acknowledgment LEARNING POINT: This checks if there's a reverse acknowledgment. If Party A acknowledges Party B, we check if Party B has acknowledged Party A. If both exist, we create a mutual handshake! |

### getMutualHandshake

```solidity
function getMutualHandshake(address partyA, address partyB) external view returns (bool isActive, struct CollaborationRegistry.MutualHandshake handshake)
```

Check if two parties have mutually acknowledged each other

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| partyA | address | First party's address |
| partyB | address | Second party's address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| isActive | bool | True if both parties have acknowledged each other |
| handshake | struct CollaborationRegistry.MutualHandshake | The handshake data LEARNING POINT: This is a view function (doesn't cost gas to call). Anyone can check if two parties have mutually acknowledged. |

### getAcknowledgmentHashes

```solidity
function getAcknowledgmentHashes(address addr) external view returns (bytes32[] hashes)
```

Get all acknowledgments made by an address

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | The address to query |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| hashes | bytes32[] | Array of acknowledgment hashes LEARNING POINT: This helps you see all acknowledgments someone has made. |

### getAcknowledgment

```solidity
function getAcknowledgment(bytes32 acknowledgmentHash) external view returns (struct CollaborationRegistry.Acknowledgment acknowledgment)
```

Get a specific acknowledgment by its hash

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| acknowledgmentHash | bytes32 | The hash of the acknowledgment |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| acknowledgment | struct CollaborationRegistry.Acknowledgment | The acknowledgment data |

### getHandshakeHashes

```solidity
function getHandshakeHashes(address addr) external view returns (bytes32[] hashes)
```

Get all handshake hashes for an address

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | The address to query |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| hashes | bytes32[] | Array of handshake hashes that this address is part of LEARNING POINT: This function returns all handshake hashes where the address is either partyA or partyB. You can then use getMutualHandshake() to get the full handshake details for each hash. |

### getOwner

```solidity
function getOwner() external view returns (address)
```

Get the current owner of the contract

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The address of the current owner LEARNING POINT: This function comes from Ownable. It's useful to check who controls the contract. After transferring to multisig, this will return the multisig address. NOTE: transferOwnership() is already available from Ownable. The owner can call: transferOwnership(newOwner) to transfer ownership. |

