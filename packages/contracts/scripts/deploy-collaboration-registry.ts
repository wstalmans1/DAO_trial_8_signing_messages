import hre from "hardhat";

async function main() {
  console.log("🚀 Deploying CollaborationRegistry to Sepolia...\n");

  // Get the deployer account
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  
  // Check balance
  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", hre.ethers.formatEther(balance), "ETH\n");

  if (balance === 0n) {
    throw new Error("❌ Insufficient balance. Please fund your account with Sepolia ETH.");
  }

  // Get the contract factory
  const CollaborationRegistry = await hre.ethers.getContractFactory("CollaborationRegistry");
  
  console.log("📝 Deploying contract...");
  
  // Deploy the contract (no constructor arguments)
  const registry = await CollaborationRegistry.deploy();
  
  console.log("⏳ Waiting for deployment transaction...");
  await registry.waitForDeployment();

  const address = await registry.getAddress();
  console.log("\n✅ CollaborationRegistry deployed successfully!");
  console.log("📍 Contract address:", address);
  console.log("🔗 View on Blockscout: https://eth-sepolia.blockscout.com/address/" + address);
  console.log("\n📋 Next steps:");
  console.log("1. Copy the contract address above");
  console.log("2. Run verification script:");
  console.log(`   npx hardhat run scripts/verify-collaboration-registry.ts --network sepolia-blockscout ${address}`);
  console.log("\n💡 To verify manually on Blockscout:");
  console.log(`   Visit: https://eth-sepolia.blockscout.com/address/${address}#code`);
  console.log("   Click 'Verify & Publish' and upload the contract source code");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

