import type { DeployFunction } from 'hardhat-deploy/types'

/**
 * @notice Deploys the SimpleMultisig contract
 * @dev Step 3: Creates a 2-of-2 multisig wallet
 *      Requires two owner addresses - both must approve transactions
 */
const func: DeployFunction = async ({ deployments, getNamedAccounts, network }) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  
  console.log('Deploying SimpleMultisig...')
  console.log('Network:', network.name)
  console.log('Deployer:', deployer)
  
  // For testing/learning, you can use the deployer as both owners
  // In production, you would use two different addresses
  // You can also set these via environment variables or named accounts
  
  // Option 1: Use deployer as owner1, and a second address as owner2
  // For now, we'll use deployer for both (you can change this)
  // In a real scenario, you'd have two different addresses
  
  // Get owner addresses - MUST be two different addresses
  const owner1 = deployer
  const owner2 = process.env.MULTISIG_OWNER2
  
  if (!owner2) {
    throw new Error(
      'MULTISIG_OWNER2 environment variable is required!\n' +
      'Set it to a different address than the deployer.\n' +
      'Example: MULTISIG_OWNER2=0x1234... npx hardhat deploy --network sepolia --tags SimpleMultisig'
    )
  }
  
  if (owner1.toLowerCase() === owner2.toLowerCase()) {
    throw new Error(
      'Owner1 and Owner2 must be different addresses!\n' +
      'Current owner1: ' + owner1 + '\n' +
      'Current owner2: ' + owner2 + '\n' +
      'Set MULTISIG_OWNER2 to a different address.'
    )
  }
  
  console.log('Owner 1:', owner1)
  console.log('Owner 2:', owner2)
  
  const deployment = await deploy('SimpleMultisig', {
    from: deployer,
    args: [owner1, owner2], // Two owners for 2-of-2 multisig
    log: true,
    waitConfirmations: 1,
  })

  if (deployment.newlyDeployed) {
    console.log('✅ SimpleMultisig deployed at:', deployment.address)
    console.log('📝 Transaction hash:', deployment.transactionHash)
    console.log('\n💡 Next steps:')
    console.log('   1. Both owners can create transactions')
    console.log('   2. Both owners must approve before execution')
    console.log('   3. Use this multisig address to own other contracts')
  } else {
    console.log('⚠️  SimpleMultisig already deployed at:', deployment.address)
  }
}

export default func
func.tags = ['SimpleMultisig', 'all']

