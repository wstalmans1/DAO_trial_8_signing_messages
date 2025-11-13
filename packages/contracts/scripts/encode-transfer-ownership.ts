import { ethers } from "ethers";

/**
 * Helper script to encode transferOwnership transaction for multisig
 * 
 * Usage: ts-node scripts/encode-transfer-ownership.ts <newOwnerAddress>
 */

async function main() {
  const newOwnerAddress = process.argv[2];
  
  if (!newOwnerAddress) {
    console.error("Usage: ts-node scripts/encode-transfer-ownership.ts <newOwnerAddress>");
    console.error("Example: ts-node scripts/encode-transfer-ownership.ts 0x1234567890123456789012345678901234567890");
    process.exit(1);
  }

  // Validate address format
  if (!ethers.isAddress(newOwnerAddress)) {
    console.error("Error: Invalid address format");
    process.exit(1);
  }

  // CollaborationRegistry contract address (from deployment)
  const COLLABORATION_REGISTRY_ADDRESS = "0xaf8458DF6678e544E14c9777BAB40749E8225D1E";
  
  // The function signature: transferOwnership(address)
  // We need to encode this function call with the newOwner address as parameter
  const iface = new ethers.Interface([
    "function transferOwnership(address newOwner) external"
  ]);

  // Encode the function call
  const data = iface.encodeFunctionData("transferOwnership", [newOwnerAddress]);

  console.log("\n📋 Transaction Parameters for Multisig:\n");
  console.log("to:", COLLABORATION_REGISTRY_ADDRESS);
  console.log("value:", "0"); // No ETH being sent
  console.log("data:", data);
  
  console.log("\n💡 To use in multisig.createTransaction():");
  console.log(`multisig.createTransaction(`);
  console.log(`  "${COLLABORATION_REGISTRY_ADDRESS}", // CollaborationRegistry address`);
  console.log(`  0, // value (no ETH)`);
  console.log(`  "${data}" // encoded transferOwnership call`);
  console.log(`)`);
  
  console.log("\n✅ After both owners approve, execute the transaction to transfer ownership!");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});


