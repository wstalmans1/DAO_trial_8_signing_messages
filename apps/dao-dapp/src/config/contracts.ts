// Contract addresses on Sepolia
export const CONTRACTS = {
  CollaborationRegistry: '0x3160C2494Be65947F4a47fAF0ad0Dc3e2857DE25' as `0x${string}`,
  SimpleMultisig: '0xc453cBAA518EDBa7955b97a8DE49FA6926A2a2C7' as `0x${string}`,
  Treasury: '0xD2f7c1AECDeAd85f764A4584321a4A005DEEe98d' as `0x${string}`,
  Governance: '0x21D597603Baf70BEc69F0E4720c3FeeA6904A01b' as `0x${string}`,
  TaskManagement: '0x3e383e0a8dDcc003D5B2E586B96f520003d3EAe5' as `0x${string}`,
  DisputeResolution: '0x7F83aC1BeC256353c7f28321933579b97029adfd' as `0x${string}`,
} as const

// Import ABIs
import CollaborationRegistryABI from '../contracts/contracts/CollaborationRegistry.sol/CollaborationRegistry.json'
import SimpleMultisigABI from '../contracts/contracts/SimpleMultisig.sol/SimpleMultisig.json'
import TreasuryABI from '../contracts/contracts/Treasury.sol/Treasury.json'
import GovernanceABI from '../contracts/contracts/Governance.sol/Governance.json'
import TaskManagementABI from '../contracts/contracts/TaskManagement.sol/TaskManagement.json'
import DisputeResolutionABI from '../contracts/contracts/DisputeResolution.sol/DisputeResolution.json'

export const CONTRACT_ABIS = {
  CollaborationRegistry: CollaborationRegistryABI.abi,
  SimpleMultisig: SimpleMultisigABI.abi,
  Treasury: TreasuryABI.abi,
  Governance: GovernanceABI.abi,
  TaskManagement: TaskManagementABI.abi,
  DisputeResolution: DisputeResolutionABI.abi,
} as const

