import type { DeployFunction } from 'hardhat-deploy/types'

/**
 * @notice Deploys the Governance contract
 * @dev Step 6: Creates a governance contract for collaborative decision-making
 *      The multisig will own this contract and can execute approved proposals
 */
const func: DeployFunction = async ({ deployments, getNamedAccounts, network }) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  
  console.log('Deploying Governance...')
  console.log('Network:', network.name)
  console.log('Deployer:', deployer)
  
  // Get the multisig address
  let multisigAddress: string
  
  try {
    const multisigDeployment = await deployments.get('SimpleMultisig')
    multisigAddress = multisigDeployment.address
    console.log('✅ Found SimpleMultisig deployment at:', multisigAddress)
  } catch (error) {
    if (process.env.MULTISIG_ADDRESS) {
      multisigAddress = process.env.MULTISIG_ADDRESS
      console.log('📝 Using MULTISIG_ADDRESS from env:', multisigAddress)
    } else {
      multisigAddress = '0xc453cBAA518EDBa7955b97a8DE49FA6926A2a2C7'
      console.log('📝 Using known SimpleMultisig address:', multisigAddress)
    }
  }
  
  // Governance parameters
  // 7 days = 604800 seconds (reasonable voting period)
  const votingPeriod = 7 * 24 * 60 * 60 // 7 days in seconds
  // Quorum threshold: minimum 2 votes (since we have 2 parties in multisig)
  const quorumThreshold = 2
  
  console.log('📊 Governance Parameters:')
  console.log('   Voting Period:', votingPeriod, 'seconds (7 days)')
  console.log('   Quorum Threshold:', quorumThreshold, 'votes')
  
  const deployment = await deploy('Governance', {
    from: deployer,
    args: [multisigAddress, votingPeriod, quorumThreshold],
    log: true,
    waitConfirmations: 1,
  })

  if (deployment.newlyDeployed) {
    console.log('✅ Governance deployed at:', deployment.address)
    console.log('📝 Transaction hash:', deployment.transactionHash)
    console.log('👤 Initial Owner (Multisig):', multisigAddress)
    console.log('\n💡 Next steps:')
    console.log('   1. Create proposals using createProposal()')
    console.log('   2. Vote on proposals using vote()')
    console.log('   3. Execute approved proposals via multisig')
    console.log('\n📊 View on Blockscout:')
    console.log(`   https://eth-sepolia.blockscout.com/address/${deployment.address}`)
  } else {
    console.log('⚠️  Governance already deployed at:', deployment.address)
  }
}

export default func
func.tags = ['Governance', 'all']
// Note: SimpleMultisig should be deployed first

