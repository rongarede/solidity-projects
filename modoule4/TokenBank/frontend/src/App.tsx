import { useState } from 'react'
import { useAccount, useConnect, useDisconnect, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi'
import { useQueryClient } from '@tanstack/react-query'
import { parseEther, formatEther } from 'viem'
import { CONTRACTS, TOKEN_BANK_ABI, ERC20_ABI } from './config'
import './App.css'

function App() {
  const [depositAmount, setDepositAmount] = useState('')
  const [withdrawAmount, setWithdrawAmount] = useState('')
  const [isRefreshing, setIsRefreshing] = useState(false)
  
  const { address, isConnected } = useAccount()
  const { connectors, connect } = useConnect()
  const { disconnect } = useDisconnect()
  const { writeContract, data: hash, isPending } = useWriteContract()
  const queryClient = useQueryClient()
  
  // Wait for transaction confirmation
  const { isLoading: isConfirming, isSuccess: isConfirmed } = 
    useWaitForTransactionReceipt({ hash })


  // Read TEST token balance  
  const { data: tokenBalance } = useReadContract({
    address: CONTRACTS.TEST_TOKEN,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
  })

  // Read bank balance
  const { data: bankBalance } = useReadContract({
    address: CONTRACTS.TOKEN_BANK,
    abi: TOKEN_BANK_ABI,
    functionName: 'getBalance',
    args: address ? [address, CONTRACTS.TEST_TOKEN] : undefined,
  })

  // Read allowance
  const { data: allowance } = useReadContract({
    address: CONTRACTS.TEST_TOKEN,
    abi: ERC20_ABI,
    functionName: 'allowance',
    args: address ? [address, CONTRACTS.TOKEN_BANK] : undefined,
  })

  const handleApprove = async () => {
    if (!depositAmount) return
    
    writeContract({
      address: CONTRACTS.TEST_TOKEN,
      abi: ERC20_ABI,
      functionName: 'approve',
      args: [CONTRACTS.TOKEN_BANK, parseEther(depositAmount)],
    })
  }

  const handleDeposit = async () => {
    if (!depositAmount) return
    
    writeContract({
      address: CONTRACTS.TOKEN_BANK,
      abi: TOKEN_BANK_ABI,
      functionName: 'deposit',
      args: [CONTRACTS.TEST_TOKEN, parseEther(depositAmount)],
    })
  }

  const handleWithdraw = async () => {
    if (!withdrawAmount) return
    
    writeContract({
      address: CONTRACTS.TOKEN_BANK,
      abi: TOKEN_BANK_ABI,
      functionName: 'withdraw',
      args: [CONTRACTS.TEST_TOKEN, parseEther(withdrawAmount)],
    })
  }

  const needsApproval = depositAmount && allowance !== undefined && 
    parseEther(depositAmount) > allowance

  const handleRefreshBalances = async () => {
    setIsRefreshing(true)
    try {
      // Invalidate and refetch all balance-related queries
      await queryClient.invalidateQueries({ queryKey: ['readContract'] })
    } finally {
      setIsRefreshing(false)
    }
  }

  if (!isConnected) {
    return (
      <div className="app">
        <h1>TokenBank DApp</h1>
        <div className="wallet-section">
          <h2>Connect Wallet</h2>
          {connectors.map((connector) => (
            <button
              key={connector.uid}
              onClick={() => connect({ connector })}
              className="connect-btn"
            >
              Connect {connector.name}
            </button>
          ))}
        </div>
      </div>
    )
  }

  return (
    <div className="app">
      <h1>TokenBank DApp</h1>
      
      {/* Wallet Info */}
      <div className="wallet-section">
        <h2>Wallet Connected</h2>
        <p>Address: {address?.slice(0, 6)}...{address?.slice(-4)}</p>
        <button onClick={() => disconnect()} className="disconnect-btn">
          Disconnect
        </button>
      </div>

      {/* Balances */}
      <div className="balance-section">
        <div className="balance-header">
          <h2>Balances</h2>
          <button 
            onClick={handleRefreshBalances}
            disabled={isRefreshing}
            className="refresh-btn"
          >
            {isRefreshing ? '🔄 Refreshing...' : '🔄 Refresh'}
          </button>
        </div>
        <p>TEST Token: {tokenBalance ? formatEther(tokenBalance) : '0'}</p>
        <p>Bank Balance: {bankBalance ? formatEther(bankBalance) : '0'}</p>
      </div>

      {/* Deposit */}
      <div className="deposit-section">
        <h2>Deposit</h2>
        <input
          type="number"
          placeholder="Amount to deposit"
          value={depositAmount}
          onChange={(e) => setDepositAmount(e.target.value)}
          className="amount-input"
        />
        
        {needsApproval ? (
          <button 
            onClick={handleApprove}
            disabled={isPending}
            className="action-btn"
          >
            {isPending ? 'Approving...' : 'Approve'}
          </button>
        ) : (
          <button 
            onClick={handleDeposit}
            disabled={isPending || !depositAmount}
            className="action-btn"
          >
            {isPending ? 'Depositing...' : 'Deposit'}
          </button>
        )}
      </div>

      {/* Withdraw */}
      <div className="withdraw-section">
        <h2>Withdraw</h2>
        <input
          type="number"
          placeholder="Amount to withdraw"
          value={withdrawAmount}
          onChange={(e) => setWithdrawAmount(e.target.value)}
          className="amount-input"
        />
        <button 
          onClick={handleWithdraw}
          disabled={isPending || !withdrawAmount}
          className="action-btn"
        >
          {isPending ? 'Withdrawing...' : 'Withdraw'}
        </button>
      </div>

      {/* Transaction Status */}
      {hash && (
        <div className="tx-status">
          <p>Transaction Hash: {hash}</p>
          {isConfirming && <p>Waiting for confirmation...</p>}
          {isConfirmed && <p>Transaction confirmed!</p>}
        </div>
      )}
    </div>
  )
}

export default App