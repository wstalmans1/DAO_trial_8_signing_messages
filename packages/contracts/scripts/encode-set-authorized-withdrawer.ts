import { ethers } from "ethers";

/**
 * Helper script to encode the setAuthorizedWithdrawer function call
 * for use in multisig createTransaction
 */

const TREASURY_ADDRESS = '0xD2f7c1AECDeAd85f764A4584321a4A005DEEe98d'
const TASK_MANAGEMENT_ADDRESS = '0xa8117Ed52C2A6964818DE66fa71105F548503887'

async function main() {
  // The function signature: setAuthorizedWithdrawer(address, bool)
  // We need to encode this function call with the TaskManagement address and true
  const iface = new ethers.Interface([
    "function setAuthorizedWithdrawer(address withdrawer, bool authorized) external"
  ]);

  // Encode the function call
  const data = iface.encodeFunctionData("setAuthorizedWithdrawer", [
    TASK_MANAGEMENT_ADDRESS,
    true
  ]);

  console.log("\n📋 Transaction Parameters for Multisig:\n");
  console.log("to:", TREASURY_ADDRESS);
  console.log("value:", "0"); // No ETH being sent
  console.log("data:", data);
  
  console.log("\n💡 To use in multisig.createTransaction():");
  console.log(`multisig.createTransaction(`);
  console.log(`  "${TREASURY_ADDRESS}", // Treasury address`);
  console.log(`  0, // value (no ETH)`);
  console.log(`  "${data}" // encoded setAuthorizedWithdrawer call`);
  console.log(`)`);
  
  console.log("\n✅ After both owners approve, execute the transaction to authorize TaskManagement!");
  console.log("   This will allow TaskManagement to automatically withdraw payments when tasks are accepted.");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })

