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
  
  // Get the Treasury address
  let treasuryAddress: string
  
  try {
    const treasuryDeployment = await deployments.get('Treasury')
    treasuryAddress = treasuryDeployment.address
    console.log('✅ Found Treasury deployment at:', treasuryAddress)
  } catch (error) {
    if (process.env.TREASURY_ADDRESS) {
      treasuryAddress = process.env.TREASURY_ADDRESS
      console.log('📝 Using TREASURY_ADDRESS from env:', treasuryAddress)
    } else {
      treasuryAddress = '0xf3586c20a469E5E5335f9263a25aD83Af480288F'
      console.log('📝 Using known Treasury address:', treasuryAddress)
    }
  }
  
  const deployment = await deploy('TaskManagement', {
    from: deployer,
    args: [multisigAddress, treasuryAddress], // Initial owner (multisig) and Treasury address
    log: true,
    waitConfirmations: 1,
  })

  if (deployment.newlyDeployed) {
    console.log('✅ TaskManagement deployed at:', deployment.address)
    console.log('📝 Transaction hash:', deployment.transactionHash)
    console.log('👤 Initial Owner (Multisig):', multisigAddress)
    console.log('💰 Treasury Address:', treasuryAddress)
    console.log('\n💡 Next steps:')
    console.log('   1. Authorize TaskManagement in Treasury:')
    console.log(`      Treasury.setAuthorizedWithdrawer(${deployment.address}, true)`)
    console.log('   2. Create tasks using createTask(title, description, paymentAmount)')
    console.log('   3. Assign tasks via multisig using assignTask(taskId, assignee, paymentAmount)')
    console.log('   4. Assignees can start and complete their tasks')
    console.log('   5. Assigner reviews and accepts (payment) or requests revision')
    console.log('   6. Track task status and progress')
    console.log('\n📊 View on Blockscout:')
    console.log(`   https://eth-sepolia.blockscout.com/address/${deployment.address}`)
  } else {
    console.log('⚠️  TaskManagement already deployed at:', deployment.address)
  }
}

export default func
func.tags = ['TaskManagement', 'all']
func.dependencies = ['Treasury'] // Deploy after Treasury
// Note: SimpleMultisig and Treasury should be deployed first

