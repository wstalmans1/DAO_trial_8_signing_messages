import type { DeployFunction } from 'hardhat-deploy/types'

/**
 * @notice Deploys the TaskManagement contract
 * @dev Step 7: Creates a task management contract for collaborative work tracking
 *      The multisig will own this contract and can assign tasks
 */
const func: DeployFunction = async ({ deployments, getNamedAccounts, network }) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  
  console.log('Deploying TaskManagement...')
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
  
  const deployment = await deploy('TaskManagement', {
    from: deployer,
    args: [multisigAddress], // Initial owner (multisig)
    log: true,
    waitConfirmations: 1,
  })

  if (deployment.newlyDeployed) {
    console.log('✅ TaskManagement deployed at:', deployment.address)
    console.log('📝 Transaction hash:', deployment.transactionHash)
    console.log('👤 Initial Owner (Multisig):', multisigAddress)
    console.log('\n💡 Next steps:')
    console.log('   1. Create tasks using createTask()')
    console.log('   2. Assign tasks via multisig using assignTask()')
    console.log('   3. Assignees can start and complete their tasks')
    console.log('   4. Track task status and progress')
    console.log('\n📊 View on Blockscout:')
    console.log(`   https://eth-sepolia.blockscout.com/address/${deployment.address}`)
  } else {
    console.log('⚠️  TaskManagement already deployed at:', deployment.address)
  }
}

export default func
func.tags = ['TaskManagement', 'all']
// Note: SimpleMultisig should be deployed first

