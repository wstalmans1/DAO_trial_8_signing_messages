/**
 * Helper script to encode the setAuthorizedWithdrawer function call
 * for use in multisig createTransaction
 * 
 * Run with: node scripts/encode-set-authorized-withdrawer.js
 */

const { keccak256, toUtf8Bytes, AbiCoder } = require('ethers');

const TREASURY_ADDRESS = '0xD2f7c1AECDeAd85f764A4584321a4A005DEEe98d';
const TASK_MANAGEMENT_ADDRESS = '0xa8117Ed52C2A6964818DE66fa71105F548503887';

// Function signature: setAuthorizedWithdrawer(address,bool)
const functionSignature = 'setAuthorizedWithdrawer(address,bool)';

// Calculate function selector (first 4 bytes of keccak256 hash)
const functionSelector = keccak256(toUtf8Bytes(functionSignature)).slice(0, 10); // 0x + 8 hex chars

// Encode parameters
const abiCoder = AbiCoder.defaultAbiCoder();
const encodedParams = abiCoder.encode(
  ['address', 'bool'],
  [TASK_MANAGEMENT_ADDRESS, true]
);

// Combine selector + encoded parameters
const data = functionSelector + encodedParams.slice(2); // Remove 0x from encoded params

console.log('\n📋 Transaction Parameters for Multisig:\n');
console.log('to:   ', TREASURY_ADDRESS);
console.log('value:', '0');
console.log('data: ', data);
console.log('\n💡 To use in multisig.createTransaction():');
console.log('multisig.createTransaction(');
console.log(`  "${TREASURY_ADDRESS}", // Treasury address`);
console.log('  0, // value (no ETH)');
console.log(`  "${data}" // encoded setAuthorizedWithdrawer call`);
console.log(')');
console.log('\n✅ This will authorize TaskManagement to withdraw from Treasury');
console.log('   After both owners approve, execute the transaction.');

