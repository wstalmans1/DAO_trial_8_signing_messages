import { ethers } from "hardhat";

async function main() {
  // Get the Treasury contract factory
  const Treasury = await ethers.getContractFactory("Treasury");
  
  // Get the interface
  const iface = Treasury.interface;
  
  // Get the function fragment
  const func = iface.getFunction("setAuthorizedWithdrawer");
  
  console.log("Function name:", func.name);
  console.log("Function signature:", func.format());
  console.log("Function selector:", func.selector);
  
  // Encode the function call
  const TASK_MANAGEMENT = "0xa8117Ed52C2A6964818DE66fa71105F548503887";
  const data = iface.encodeFunctionData("setAuthorizedWithdrawer", [TASK_MANAGEMENT, true]);
  
  console.log("\n📋 Correct Transaction Parameters:\n");
  console.log("to:   0xD2f7c1AECDeAd85f764A4584321a4A005DEEe98d");
  console.log("value: 0");
  console.log("data: ", data);
  console.log("\nFunction selector (first 4 bytes):", data.slice(0, 10));
}

main().catch(console.error);

