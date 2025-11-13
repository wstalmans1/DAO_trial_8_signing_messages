import type { DeployFunction } from 'hardhat-deploy/types'

/**
 * @notice Deploys the Treasury contract
 * @dev Step 5: Creates a treasury contract owned by the multisig
 *      The multisig will control all withdrawals from this treasury
 */
const func: DeployFunction = async ({ deployments, getNamedAccounts, network }) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  
  console.log('Deploying Treasury...')
  console.log('Network:', network.name)
  console.log('Deployer:', deployer)
  
  // Get the multisig address
  // Priority: 1) Existing deployment, 2) Environment variable, 3) Known deployed address, 4) Deployer
  let multisigAddress: string
  
  try {
    const multisigDeployment = await deployments.get('SimpleMultisig')
    multisigAddress = multisigDeployment.address
    console.log('✅ Found SimpleMultisig deployment at:', multisigAddress)
  } catch (error) {
    // Try environment variable first
    if (process.env.MULTISIG_ADDRESS) {
      multisigAddress = process.env.MULTISIG_ADDRESS
      console.log('📝 Using MULTISIG_ADDRESS from env:', multisigAddress)
    } else {
      // Use the known deployed address on Sepolia
      multisigAddress = '0xc453cBAA518EDBa7955b97a8DE49FA6926A2a2C7'
      console.log('📝 Using known SimpleMultisig address:', multisigAddress)
      console.log('   (If this is wrong, set MULTISIG_ADDRESS env var)')
    }
  }
  
  const deployment = await deploy('Treasury', {
    from: deployer,
    args: [multisigAddress], // Initial owner (multisig)
    log: true,
    waitConfirmations: 1,
  })

  if (deployment.newlyDeployed) {
    console.log('✅ Treasury deployed at:', deployment.address)
    console.log('📝 Transaction hash:', deployment.transactionHash)
    console.log('👤 Initial Owner (Multisig):', multisigAddress)
    console.log('\n💡 Next steps:')
    console.log('   1. Send ETH to the treasury address to deposit funds')
    console.log('   2. Use multisig to approve withdrawals')
    console.log('   3. Execute withdrawal transactions via multisig')
    console.log('\n📊 View on Blockscout:')
    console.log(`   https://eth-sepolia.blockscout.com/address/${deployment.address}`)
  } else {
    console.log('⚠️  Treasury already deployed at:', deployment.address)
  }
}

export default func
func.tags = ['Treasury', 'all']
// Note: SimpleMultisig should be deployed first, but we handle the case where it's already deployed

