import type { DeployFunction } from 'hardhat-deploy/types'

/**
 * @notice Deploys the DisputeResolution contract
 * @dev Step 8: Creates a dispute resolution contract for handling conflicts
 *      The multisig will own this contract and can resolve disputes
 */
const func: DeployFunction = async ({ deployments, getNamedAccounts, network }) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  
  console.log('Deploying DisputeResolution...')
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
  
  const deployment = await deploy('DisputeResolution', {
    from: deployer,
    args: [multisigAddress], // initialOwner
    log: true,
    waitConfirmations: network.name === 'sepolia' ? 2 : 1,
  })
  
  if (deployment.newlyDeployed) {
    console.log('✅ DisputeResolution deployed at:', deployment.address)
    console.log('📋 Contract is owned by multisig:', multisigAddress)
    console.log('\n💡 Next steps:')
    console.log('   1. Verify the contract on Blockscout')
    console.log('   2. Test creating a dispute')
    console.log('   3. Test resolving a dispute via multisig')
  } else {
    console.log('📝 DisputeResolution already deployed at:', deployment.address)
  }
}

func.tags = ['DisputeResolution']
// No dependencies - we'll use existing SimpleMultisig deployment

export default func

