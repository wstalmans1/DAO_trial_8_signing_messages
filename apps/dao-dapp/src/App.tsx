import { useState, useEffect } from 'react'
import { ConnectButton } from '@rainbow-me/rainbowkit'
import { useAccount, useSignMessage, useWriteContract, useWaitForTransactionReceipt } from 'wagmi'
import { verifyMessage as verifyMessageViem } from 'viem'
import { sepolia } from 'wagmi/chains'
import CollaborationRegistryABI from './contracts/contracts/CollaborationRegistry.sol/CollaborationRegistry.json'

// Contract address on Sepolia
const COLLABORATION_REGISTRY_ADDRESS = '0x3160C2494Be65947F4a47fAF0ad0Dc3e2857DE25' as `0x${string}`

export default function App() {
  const { address, isConnected } = useAccount()
  const [message, setMessage] = useState('')
  const [signature, setSignature] = useState<string | null>(null)
  
  // Verification inputs (independent from signing)
  const [verifyMessage, setVerifyMessage] = useState('')
  const [verifyAddress, setVerifyAddress] = useState('')
  const [verifySignature, setVerifySignature] = useState('')
  const [verificationResult, setVerificationResult] = useState<boolean | null>(null)
  const [verificationError, setVerificationError] = useState<string | null>(null)

  // Acknowledgment submission state
  const [targetAddress, setTargetAddress] = useState('')
  const [acknowledgmentMessage, setAcknowledgmentMessage] = useState('')
  const [acknowledgmentSignature, setAcknowledgmentSignature] = useState<string | null>(null)
  const [submissionTxHash, setSubmissionTxHash] = useState<string | null>(null)
  const [submissionError, setSubmissionError] = useState<string | null>(null)

  // Hook for signing acknowledgment message
  const { 
    signMessage: signAcknowledgmentMessage, 
    isPending: isSigningAcknowledgment,
    error: signAcknowledgmentError 
  } = useSignMessage({
    mutation: {
      onSuccess: (data) => {
        setAcknowledgmentSignature(data)
      },
    },
  })

  // Hook for writing to contract
  const { 
    writeContract, 
    data: writeData, 
    isPending: isSubmitting,
    error: writeError 
  } = useWriteContract()

  // Wait for transaction receipt
  const { isLoading: isConfirming, isSuccess: isSubmitted } = useWaitForTransactionReceipt({
    hash: writeData,
  })
  
  const { signMessage, isPending, error } = useSignMessage({
    mutation: {
      onSuccess: (data) => {
        setSignature(data)
      },
    },
  })

  const handleSign = async () => {
    if (!message.trim()) {
      alert('Please enter a message to sign')
      return
    }
    setSignature(null)
    signMessage({ message })
  }

  const handleVerify = async () => {
    if (!verifySignature.trim() || !verifyMessage.trim() || !verifyAddress.trim()) {
      setVerificationError('Please fill in all fields')
      return
    }
    
    setVerificationError(null)
    setVerificationResult(null)
    
    try {
      // Validate address format
      if (!verifyAddress.startsWith('0x') || verifyAddress.length !== 42) {
        throw new Error('Invalid address format')
      }
      
      // Validate signature format
      if (!verifySignature.startsWith('0x') || verifySignature.length < 130) {
        throw new Error('Invalid signature format')
      }
      
      const isValid = await verifyMessageViem({
        address: verifyAddress as `0x${string}`,
        message: verifyMessage,
        signature: verifySignature as `0x${string}`,
      })
      setVerificationResult(isValid)
    } catch (err: any) {
      setVerificationResult(false)
      setVerificationError(err.message || 'Verification failed')
    }
  }

  const handleFillFromSigned = () => {
    if (message && address && signature) {
      setVerifyMessage(message)
      setVerifyAddress(address)
      setVerifySignature(signature)
    }
  }

  const handleCopyAll = () => {
    if (!signature || !message || !address) return
    const data = {
      message,
      address,
      signature,
      timestamp: new Date().toISOString(),
    }
    navigator.clipboard.writeText(JSON.stringify(data, null, 2))
    alert('Copied message, address, and signature to clipboard!')
  }

  // Generate acknowledgment message automatically
  const generateAcknowledgmentMessage = () => {
    if (!targetAddress.trim()) {
      alert('Please enter target address first')
      return
    }
    const message = `I acknowledge collaboration with ${targetAddress}`
    setAcknowledgmentMessage(message)
  }

  // Sign the acknowledgment message
  const handleSignAcknowledgment = async () => {
    if (!acknowledgmentMessage.trim()) {
      alert('Please enter or generate an acknowledgment message')
      return
    }
    if (!targetAddress.trim()) {
      alert('Please enter target address')
      return
    }
    setAcknowledgmentSignature(null)
    setSubmissionError(null)
    signAcknowledgmentMessage({ message: acknowledgmentMessage })
  }

  // Submit acknowledgment to contract
  const handleSubmitAcknowledgment = async () => {
    if (!targetAddress.trim() || !acknowledgmentMessage.trim() || !acknowledgmentSignature) {
      alert('Please complete all steps: enter target address, sign message, then submit')
      return
    }

    // Validate address format
    if (!targetAddress.startsWith('0x') || targetAddress.length !== 42) {
      setSubmissionError('Invalid target address format')
      return
    }

    if (targetAddress.toLowerCase() === address?.toLowerCase()) {
      setSubmissionError('Cannot acknowledge yourself')
      return
    }

    setSubmissionError(null)

    try {
      writeContract({
        address: COLLABORATION_REGISTRY_ADDRESS,
        abi: CollaborationRegistryABI.abi,
        functionName: 'submitAcknowledgment',
        args: [
          targetAddress as `0x${string}`,
          acknowledgmentMessage,
          acknowledgmentSignature as `0x${string}`,
        ],
        chainId: sepolia.id,
      })
    } catch (err: any) {
      setSubmissionError(err.message || 'Failed to submit acknowledgment')
    }
  }

  // Reset form when transaction succeeds
  useEffect(() => {
    if (isSubmitted && writeData && !submissionTxHash) {
      setSubmissionTxHash(writeData)
      // Optionally reset form after success
      setTimeout(() => {
        setTargetAddress('')
        setAcknowledgmentMessage('')
        setAcknowledgmentSignature(null)
      }, 5000)
    }
  }, [isSubmitted, writeData, submissionTxHash])

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 p-6">
      <header className="flex items-center justify-between mb-8">
        <h1 className="text-3xl font-bold text-gray-800">DAO dApp</h1>
        <ConnectButton />
      </header>

      <main className="max-w-4xl mx-auto space-y-6">
        {/* Signing Section */}
        <div className="bg-white rounded-lg shadow-lg p-8">
          <h2 className="text-2xl font-semibold text-gray-800 mb-6">
            Sign Message with MetaMask
          </h2>

          {!isConnected ? (
            <div className="text-center py-8">
              <p className="text-gray-600 mb-4">
                Please connect your wallet to sign messages
              </p>
              <ConnectButton />
            </div>
          ) : (
            <div className="space-y-6">
              <div>
                <label 
                  htmlFor="message" 
                  className="block text-sm font-medium text-gray-700 mb-2"
                >
                  Message to Sign
                </label>
                <textarea
                  id="message"
                  value={message}
                  onChange={(e) => setMessage(e.target.value)}
                  placeholder="Enter your message here..."
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
                  rows={4}
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Connected Address
                </label>
                <div className="px-4 py-2 bg-gray-50 rounded-lg font-mono text-sm text-gray-700 break-all">
                  {address}
                </div>
              </div>

              <button
                onClick={handleSign}
                disabled={isPending || !message.trim()}
                className="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed text-white font-semibold py-3 px-6 rounded-lg transition-colors duration-200"
              >
                {isPending ? 'Signing...' : 'Sign Message'}
              </button>

              {error && (
                <div className="p-4 bg-red-50 border border-red-200 rounded-lg">
                  <p className="text-red-800 text-sm">
                    Error: {error.message}
                  </p>
                </div>
              )}

              {signature && (
                <>
                  <div className="p-4 bg-green-50 border border-green-200 rounded-lg">
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Signature
                    </label>
                    <div className="font-mono text-sm text-gray-800 break-all mb-3">
                      {signature}
                    </div>
                    <div className="flex gap-2 flex-wrap">
                      <button
                        onClick={() => navigator.clipboard.writeText(signature)}
                        className="text-sm text-blue-600 hover:text-blue-800 underline"
                      >
                        Copy signature
                      </button>
                      <span className="text-gray-400">|</span>
                      <button
                        onClick={handleCopyAll}
                        className="text-sm text-blue-600 hover:text-blue-800 underline"
                      >
                        Copy all (message + address + signature)
                      </button>
                      <span className="text-gray-400">|</span>
                      <button
                        onClick={handleFillFromSigned}
                        className="text-sm text-purple-600 hover:text-purple-800 underline"
                      >
                        Use for verification below
                      </button>
                    </div>
                  </div>

                  <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                    <h3 className="font-semibold text-gray-800 mb-2">
                      What to do with this data?
                    </h3>
                    <ul className="text-sm text-gray-700 space-y-2 list-disc list-inside">
                      <li><strong>Store it:</strong> Save the message, address, and signature together (use "Copy all" button above)</li>
                      <li><strong>Verify later:</strong> Use the verification section below to verify any signature</li>
                      <li><strong>Use for authentication:</strong> Send signature to your backend to prove wallet ownership</li>
                      <li><strong>DAO voting:</strong> Sign proposals/decisions off-chain, verify on-chain later</li>
                      <li><strong>Document signing:</strong> Create tamper-proof records of agreements</li>
                    </ul>
                    <p className="text-xs text-gray-600 mt-3">
                      💡 <strong>Tip:</strong> The signature proves that the owner of the address approved this exact message. Store all three pieces together!
                    </p>
                  </div>
                </>
              )}
            </div>
          )}
        </div>

        {/* Submit Acknowledgment Section */}
        <div className="bg-white rounded-lg shadow-lg p-8">
          <h2 className="text-2xl font-semibold text-gray-800 mb-2">
            Submit Acknowledgment to Contract
          </h2>
          <p className="text-sm text-gray-600 mb-6">
            Create and submit a mutual acknowledgment to the CollaborationRegistry contract
          </p>

          {!isConnected ? (
            <div className="text-center py-8">
              <p className="text-gray-600 mb-4">
                Please connect your wallet to submit acknowledgments
              </p>
              <ConnectButton />
            </div>
          ) : (
            <div className="space-y-6">
              {/* Step 1: Target Address */}
              <div>
                <label 
                  htmlFor="target-address" 
                  className="block text-sm font-medium text-gray-700 mb-2"
                >
                  Step 1: Target Address (The party you're acknowledging)
                </label>
                <input
                  id="target-address"
                  type="text"
                  value={targetAddress}
                  onChange={(e) => setTargetAddress(e.target.value)}
                  placeholder="0x..."
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent font-mono text-sm"
                />
                <p className="text-xs text-gray-500 mt-1">
                  Enter the Ethereum address of the party you want to acknowledge
                </p>
              </div>

              {/* Step 2: Message */}
              <div>
                <div className="flex items-center justify-between mb-2">
                  <label 
                    htmlFor="acknowledgment-message" 
                    className="block text-sm font-medium text-gray-700"
                  >
                    Step 2: Acknowledgment Message
                  </label>
                  <button
                    onClick={generateAcknowledgmentMessage}
                    className="text-xs text-green-600 hover:text-green-800 underline"
                  >
                    Auto-generate message
                  </button>
                </div>
                <textarea
                  id="acknowledgment-message"
                  value={acknowledgmentMessage}
                  onChange={(e) => setAcknowledgmentMessage(e.target.value)}
                  placeholder="I acknowledge collaboration with 0x..."
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent resize-none"
                  rows={3}
                />
                <p className="text-xs text-gray-500 mt-1">
                  This is the message you'll sign. It should acknowledge the target address.
                </p>
              </div>

              {/* Step 3: Sign Message */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Step 3: Sign the Message
                </label>
                <button
                  onClick={handleSignAcknowledgment}
                  disabled={isSigningAcknowledgment || !acknowledgmentMessage.trim() || !targetAddress.trim()}
                  className="w-full bg-green-600 hover:bg-green-700 disabled:bg-gray-400 disabled:cursor-not-allowed text-white font-semibold py-3 px-6 rounded-lg transition-colors duration-200"
                >
                  {isSigningAcknowledgment ? 'Signing...' : 'Sign Acknowledgment Message'}
                </button>
                
                {signAcknowledgmentError && (
                  <div className="mt-2 p-3 bg-red-50 border border-red-200 rounded-lg">
                    <p className="text-red-800 text-sm">
                      Error: {signAcknowledgmentError.message}
                    </p>
                  </div>
                )}

                {acknowledgmentSignature && (
                  <div className="mt-3 p-3 bg-green-50 border border-green-200 rounded-lg">
                    <p className="text-green-800 text-sm font-medium mb-1">✓ Message signed successfully!</p>
                    <p className="text-xs text-green-700 font-mono break-all">
                      {acknowledgmentSignature}
                    </p>
                  </div>
                )}
              </div>

              {/* Step 4: Submit to Contract */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Step 4: Submit to Contract
                </label>
                <button
                  onClick={handleSubmitAcknowledgment}
                  disabled={isSubmitting || isConfirming || !acknowledgmentSignature || !targetAddress.trim() || !acknowledgmentMessage.trim()}
                  className="w-full bg-indigo-600 hover:bg-indigo-700 disabled:bg-gray-400 disabled:cursor-not-allowed text-white font-semibold py-3 px-6 rounded-lg transition-colors duration-200"
                >
                  {isSubmitting ? 'Submitting...' : isConfirming ? 'Confirming...' : 'Submit to Contract'}
                </button>

                {(writeError || submissionError) && (
                  <div className="mt-2 p-3 bg-red-50 border border-red-200 rounded-lg">
                    <p className="text-red-800 text-sm">
                      Error: {(writeError as any)?.message || submissionError}
                    </p>
                  </div>
                )}

                {isSubmitted && submissionTxHash && (
                  <div className="mt-3 p-4 bg-green-50 border border-green-200 rounded-lg">
                    <p className="text-green-800 font-medium mb-2">✅ Acknowledgment submitted successfully!</p>
                    <p className="text-xs text-green-700 mb-2">
                      Transaction Hash: <span className="font-mono break-all">{submissionTxHash}</span>
                    </p>
                    <a
                      href={`https://eth-sepolia.blockscout.com/tx/${submissionTxHash}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-sm text-indigo-600 hover:text-indigo-800 underline"
                    >
                      View on Blockscout →
                    </a>
                  </div>
                )}
              </div>

              {/* Info Box */}
              <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                <h3 className="font-semibold text-gray-800 mb-2">
                  How it works:
                </h3>
                <ol className="text-sm text-gray-700 space-y-1 list-decimal list-inside">
                  <li>Enter the address of the party you want to acknowledge</li>
                  <li>Generate or write an acknowledgment message</li>
                  <li>Sign the message with your wallet</li>
                  <li>Submit the signed message to the contract</li>
                </ol>
                <p className="text-xs text-gray-600 mt-3">
                  💡 <strong>Tip:</strong> When both parties submit acknowledgments, a mutual handshake is automatically created on-chain!
                </p>
              </div>
            </div>
          )}
        </div>

        {/* Verification Section */}
        <div className="bg-white rounded-lg shadow-lg p-8">
          <h2 className="text-2xl font-semibold text-gray-800 mb-6">
            Verify Any Signature
          </h2>
          <p className="text-sm text-gray-600 mb-6">
            Paste any message, address, and signature to verify if they match
          </p>

          <div className="space-y-6">
            <div>
              <label 
                htmlFor="verify-message" 
                className="block text-sm font-medium text-gray-700 mb-2"
              >
                Message
              </label>
              <textarea
                id="verify-message"
                value={verifyMessage}
                onChange={(e) => setVerifyMessage(e.target.value)}
                placeholder="Paste the original message that was signed..."
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent resize-none"
                rows={3}
              />
            </div>

            <div>
              <label 
                htmlFor="verify-address" 
                className="block text-sm font-medium text-gray-700 mb-2"
              >
                Address
              </label>
              <input
                id="verify-address"
                type="text"
                value={verifyAddress}
                onChange={(e) => setVerifyAddress(e.target.value)}
                placeholder="0x..."
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent font-mono text-sm"
              />
            </div>

            <div>
              <label 
                htmlFor="verify-signature" 
                className="block text-sm font-medium text-gray-700 mb-2"
              >
                Signature
              </label>
              <input
                id="verify-signature"
                type="text"
                value={verifySignature}
                onChange={(e) => setVerifySignature(e.target.value)}
                placeholder="0x..."
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent font-mono text-sm"
              />
            </div>

            <button
              onClick={handleVerify}
              disabled={!verifyMessage.trim() || !verifyAddress.trim() || !verifySignature.trim()}
              className="w-full bg-purple-600 hover:bg-purple-700 disabled:bg-gray-400 disabled:cursor-not-allowed text-white font-semibold py-3 px-6 rounded-lg transition-colors duration-200"
            >
              Verify Signature
            </button>

            {verificationError && (
              <div className="p-4 bg-red-50 border border-red-200 rounded-lg">
                <p className="text-red-800 text-sm font-medium">
                  Error: {verificationError}
                </p>
              </div>
            )}

            {verificationResult !== null && (
              <div className={`p-4 border rounded-lg ${
                verificationResult 
                  ? 'bg-green-50 border-green-200' 
                  : 'bg-red-50 border-red-200'
              }`}>
                <p className={`font-medium text-lg ${
                  verificationResult ? 'text-green-800' : 'text-red-800'
                }`}>
                  {verificationResult 
                    ? '✓ Signature is VALID'
                    : '✗ Signature is INVALID'}
                </p>
                <p className={`text-sm mt-1 ${
                  verificationResult ? 'text-green-700' : 'text-red-700'
                }`}>
                  {verificationResult 
                    ? 'The signature matches the message and address.'
                    : 'The signature does not match the provided message and address.'}
                </p>
              </div>
            )}
          </div>
        </div>
      </main>
    </div>
  )
}
