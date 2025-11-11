import { useState } from 'react'
import { ConnectButton } from '@rainbow-me/rainbowkit'
import { useAccount, useSignMessage } from 'wagmi'
import { verifyMessage as verifyMessageViem } from 'viem'

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
