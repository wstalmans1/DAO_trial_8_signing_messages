import type { DeployFunction } from 'hardhat-deploy/types'

/**
 * @notice Deploys the CollaborationRegistry contract
 * @dev This contract stores mutual acknowledgments between two parties
 *      Step 2: Now requires initialOwner parameter for Ownable
 */
const func: DeployFunction = async ({ deployments, getNamedAccounts }) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  
  console.log('Deploying CollaborationRegistry...')
  console.log('Deployer:', deployer)
  console.log('Initial Owner:', deployer)
  
  // Deploy CollaborationRegistry
  // Step 2: Pass deployer as initial owner (can be transferred to multisig later)
  const deployment = await deploy('CollaborationRegistry', {
    from: deployer,
    args: [deployer], // Initial owner (deployer, can be transferred to multisig)
    log: true,
    waitConfirmations: 1, // Wait for 1 confirmation on testnets
  })

  if (deployment.newlyDeployed) {
    console.log('✅ CollaborationRegistry deployed at:', deployment.address)
    console.log('📝 Transaction hash:', deployment.transactionHash)
  } else {
    console.log('⚠️  CollaborationRegistry already deployed at:', deployment.address)
  }
}

export default func
func.tags = ['CollaborationRegistry', 'all']

