import { ethers } from "ethers";

/**
 * Helper script to encode the assignTask function call
 * for use in multisig createTransaction
 */

const TASK_MANAGEMENT = "0x3e383e0a8dDcc003D5B2E586B96f520003d3EAe5";

async function main() {
  // Function signature: assignTask(uint256,address,uint256)
  const iface = new ethers.Interface([
    "function assignTask(uint256 taskId, address assignee, uint256 paymentAmount) external"
  ]);
  
  // ⚠️ REPLACE THESE VALUES WITH YOUR ACTUAL VALUES:
  const TASK_ID = 0; // Replace with actual task ID
  const ASSIGNEE = "0x0000000000000000000000000000000000000000"; // Replace with assignee address
  const PAYMENT_AMOUNT = "1000000000000000000"; // 1 ETH in wei (replace with actual amount)
  
  // Encode the function call
  const data = iface.encodeFunctionData("assignTask", [
    TASK_ID,
    ASSIGNEE,
    PAYMENT_AMOUNT
  ]);
  
  console.log('\n📋 Transaction Parameters for Multisig createTransaction:\n');
  console.log('to:   ', TASK_MANAGEMENT);
  console.log('value:', '0');
  console.log('data: ', data);
  console.log('\n📝 Function: assignTask(uint256 taskId, address assignee, uint256 paymentAmount)');
  console.log('\n⚠️  Replace these values in the script:');
  console.log('  - TASK_ID:', TASK_ID, '(replace with actual task ID)');
  console.log('  - ASSIGNEE:', ASSIGNEE, '(replace with assignee address)');
  console.log('  - PAYMENT_AMOUNT:', PAYMENT_AMOUNT, 'wei (replace with actual payment amount)');
  console.log('\n💡 Example:');
  console.log('  Task ID: 0');
  console.log('  Assignee: 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb');
  console.log('  Payment: 0.5 ETH = 500000000000000000 wei');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

