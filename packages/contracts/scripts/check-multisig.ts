import hre from "hardhat";

async function main() {
  const multisigAddress = "0xc453cBAA518EDBa7955b97a8DE49FA6926A2a2C7";
  const multisig = await hre.ethers.getContractAt("SimpleMultisig", multisigAddress);
  
  console.log("🔍 Checking SimpleMultisig state...\n");
  
  const owner1 = await multisig.owner1();
  const owner2 = await multisig.owner2();
  console.log("Owner 1:", owner1);
  console.log("Owner 2:", owner2);
  
  const txCount = await multisig.transactionCount();
  console.log("\nTransaction count:", txCount.toString());
  
  if (txCount === 0n) {
    console.log("\n⚠️  No transactions created yet!");
    console.log("You need to create a transaction first using createTransaction()");
    console.log("Transaction IDs start at 0, so if count is 0, transaction 0 doesn't exist.");
  } else {
    console.log("\nChecking transactions...");
    for (let i = 0; i < Number(txCount); i++) {
      try {
        const tx = await multisig.getTransaction(i);
        const owner1Approved = await multisig.hasApproved(i, owner1);
        const owner2Approved = await multisig.hasApproved(i, owner2);
        
        console.log(`\nTransaction ${i}:`);
        console.log("  To:", tx.to);
        console.log("  Value:", hre.ethers.formatEther(tx.value), "ETH");
        console.log("  Executed:", tx.executed);
        console.log("  Approvals:", tx.approvals.toString(), "/ 2");
        console.log("  Owner1 approved:", owner1Approved);
        console.log("  Owner2 approved:", owner2Approved);
      } catch (e: any) {
        console.log(`Transaction ${i}: Error - ${e.message}`);
      }
    }
  }
}

main().catch(console.error);


