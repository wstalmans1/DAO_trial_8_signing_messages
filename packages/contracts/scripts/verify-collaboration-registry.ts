import hre from "hardhat";

async function main() {
  const contractAddress = process.argv[2];
  
  if (!contractAddress) {
    throw new Error("Usage: npx hardhat run scripts/verify-collaboration-registry.ts --network sepolia-blockscout <contract-address>");
  }

  console.log(`🔍 Verifying CollaborationRegistry at ${contractAddress} on Blockscout...\n`);

  try {
    await hre.run("verify:verify", {
      address: contractAddress,
      contract: "contracts/CollaborationRegistry.sol:CollaborationRegistry",
      constructorArguments: [], // No constructor arguments
      network: "sepolia-blockscout",
    });
    
    console.log("\n✅ Contract verified successfully on Blockscout!");
    console.log(`🔗 View verified contract: https://eth-sepolia.blockscout.com/address/${contractAddress}#code`);
  } catch (error: any) {
    if (error.message.includes("Already Verified")) {
      console.log("✅ Contract is already verified!");
    } else {
      console.error("❌ Verification failed:", error.message);
      console.log("\n💡 You can also verify manually:");
      console.log(`   1. Visit: https://eth-sepolia.blockscout.com/address/${contractAddress}#code`);
      console.log("   2. Click 'Verify & Publish'");
      console.log("   3. Select 'Via Standard JSON Input'");
      console.log("   4. Upload the contract source code");
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

