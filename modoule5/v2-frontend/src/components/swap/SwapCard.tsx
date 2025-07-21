'use client'

import { useState, useEffect } from 'react'
import { useAccount } from 'wagmi'
import { useSwapStore } from '@/store/useSwapStore'
import { TokenSelect } from './TokenSelect'
import { useTokenBalance } from '@/hooks/useTokenBalance'
import { useSwapEstimate, useTokenAllowance, useApproveToken } from '@/hooks/useSwap'
import { useTokenPrice } from '@/hooks/useTokenPrice'
import { parseTokenAmount, formatTokenAmount } from '@/lib/utils'
import { isNativeToken } from '@/lib/tokens'

export function SwapCard() {
  const { address, isConnected } = useAccount()
  const [slippageInput, setSlippageInput] = useState('0.5')
  
  const {
    tokenA,
    tokenB,
    amountA,
    amountB,
    slippage,
    isExactIn,
    setTokenA,
    setTokenB,
    setAmountA,
    setAmountB,
    setSlippage,
    swapTokens,
    resetAmounts
  } = useSwapStore()

  const { balance: balanceA, formattedBalance: formattedBalanceA } = useTokenBalance(tokenA)
  const { balance: balanceB, formattedBalance: formattedBalanceB } = useTokenBalance(tokenB)
  const { price, pairExists } = useTokenPrice(tokenA, tokenB)
  
  const estimate = useSwapEstimate(tokenA, tokenB, isExactIn ? amountA : amountB, isExactIn)
  
  const { data: allowance } = useTokenAllowance(tokenA, 'ROUTER_ADDRESS') // Would use actual router address
  const { approve, isPending: isApproving } = useApproveToken()

  // Update opposite amount when input changes
  useEffect(() => {
    if (isExactIn && amountA && estimate.amountOut !== '0') {
      setAmountB(estimate.amountOut)
    } else if (!isExactIn && amountB && estimate.amountOut !== '0') {
      setAmountA(estimate.amountOut)
    }
  }, [amountA, amountB, isExactIn, estimate.amountOut, setAmountA, setAmountB])

  const needsApproval = tokenA && !isNativeToken(tokenA) && amountA && 
    parseTokenAmount(amountA, tokenA.decimals) > ((allowance as bigint) || 0n)

  const canSwap = isConnected && tokenA && tokenB && amountA && 
    parseFloat(amountA) > 0 && pairExists &&
    parseTokenAmount(amountA, tokenA.decimals) <= balanceA

  const handleMaxClick = () => {
    try {
      if (tokenA && balanceA > 0n) {
        const maxAmount = formatTokenAmount(balanceA, tokenA.decimals)
        setAmountA(maxAmount)
      }
    } catch (error) {
      console.error('Failed to calculate max amount:', error)
    }
  }

  const handleApprove = async () => {
    try {
      if (!tokenA || !amountA) {
        throw new Error('Token or amount not specified for approval')
      }
      
      const amount = parseTokenAmount(amountA, tokenA.decimals)
      await approve(tokenA, 'ROUTER_ADDRESS', amount) // Would use actual router address
    } catch (error) {
      console.error('Approve failed:', error)
    }
  }

  const handleSwap = async () => {
    try {
      if (!tokenA || !tokenB || !amountA) {
        throw new Error('Missing required swap parameters')
      }
      // This would implement the actual swap logic
      throw new Error('Swap not implemented yet - would call router contract')
    } catch (error) {
      console.error('Swap failed:', error)
    }
  }

  return (
    <div className="bg-white rounded-xl shadow-lg p-6 w-full max-w-md mx-auto">
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-xl font-bold">Swap</h2>
        <div className="flex items-center gap-2">
          <label className="text-sm text-gray-600">Slippage:</label>
          <input
            type="number"
            value={slippageInput}
            onChange={(e) => {
              setSlippageInput(e.target.value)
              const value = parseFloat(e.target.value)
              if (!isNaN(value) && value >= 0 && value <= 50) {
                setSlippage(value)
              }
            }}
            className="w-16 px-2 py-1 border border-gray-300 rounded text-sm"
            step="0.1"
            min="0"
            max="50"
          />
          <span className="text-sm text-gray-600">%</span>
        </div>
      </div>

      {/* Token A Input */}
      <div className="mb-4">
        <div className="flex items-center justify-between mb-2">
          <span className="text-sm text-gray-600">From</span>
          {isConnected && tokenA && (
            <span className="text-sm text-gray-500">
              Balance: {parseFloat(formattedBalanceA).toFixed(4)}
            </span>
          )}
        </div>
        
        <div className="flex items-center gap-3 p-4 bg-gray-50 rounded-lg">
          <div className="flex-1">
            <input
              type="number"
              value={amountA}
              onChange={(e) => setAmountA(e.target.value)}
              placeholder="0.0"
              className="w-full bg-transparent text-xl font-medium outline-none"
            />
            {tokenA && price && (
              <div className="text-sm text-gray-500 mt-1">
                ≈ ${(parseFloat(amountA || '0') * price).toFixed(2)}
              </div>
            )}
          </div>
          
          <div className="flex flex-col items-end gap-2">
            <TokenSelect
              selectedToken={tokenA}
              onTokenSelect={setTokenA}
              excludeToken={tokenB}
            />
            {isConnected && tokenA && balanceA > 0n && (
              <button
                onClick={handleMaxClick}
                className="text-xs text-blue-500 hover:text-blue-600"
              >
                MAX
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Swap Button */}
      <div className="flex justify-center my-4">
        <button
          onClick={swapTokens}
          className="p-2 border-2 border-gray-200 rounded-lg hover:border-gray-300 transition-colors"
        >
          <svg className="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16V4m0 0L3 8m4-4l4 4m6 0v12m0 0l4-4m-4 4l-4-4" />
          </svg>
        </button>
      </div>

      {/* Token B Input */}
      <div className="mb-6">
        <div className="flex items-center justify-between mb-2">
          <span className="text-sm text-gray-600">To</span>
          {isConnected && tokenB && (
            <span className="text-sm text-gray-500">
              Balance: {parseFloat(formattedBalanceB).toFixed(4)}
            </span>
          )}
        </div>
        
        <div className="flex items-center gap-3 p-4 bg-gray-50 rounded-lg">
          <div className="flex-1">
            <input
              type="number"
              value={amountB}
              onChange={(e) => setAmountB(e.target.value)}
              placeholder="0.0"
              className="w-full bg-transparent text-xl font-medium outline-none"
            />
            {tokenB && price && (
              <div className="text-sm text-gray-500 mt-1">
                ≈ ${(parseFloat(amountB || '0') / price).toFixed(2)}
              </div>
            )}
          </div>
          
          <TokenSelect
            selectedToken={tokenB}
            onTokenSelect={setTokenB}
            excludeToken={tokenA}
          />
        </div>
      </div>

      {/* Trade Info */}
      {tokenA && tokenB && amountA && pairExists && (
        <div className="mb-4 p-3 bg-gray-50 rounded-lg text-sm">
          <div className="flex justify-between mb-1">
            <span className="text-gray-600">Minimum received:</span>
            <span>{parseFloat(estimate.minimumAmountOut).toFixed(6)} {tokenB.symbol}</span>
          </div>
          <div className="flex justify-between mb-1">
            <span className="text-gray-600">Price impact:</span>
            <span className={estimate.priceImpact > 5 ? 'text-red-500' : 'text-gray-900'}>
              {estimate.priceImpact.toFixed(2)}%
            </span>
          </div>
          <div className="flex justify-between">
            <span className="text-gray-600">Fee:</span>
            <span>{parseFloat(estimate.fee).toFixed(6)} {tokenA.symbol}</span>
          </div>
        </div>
      )}

      {/* Action Button */}
      {!isConnected ? (
        <div className="text-center text-gray-500">
          Connect wallet to swap
        </div>
      ) : !tokenA || !tokenB ? (
        <button
          disabled
          className="w-full py-3 bg-gray-300 text-gray-500 rounded-lg font-medium"
        >
          Select tokens
        </button>
      ) : !pairExists ? (
        <button
          disabled
          className="w-full py-3 bg-gray-300 text-gray-500 rounded-lg font-medium"
        >
          Pair doesn't exist
        </button>
      ) : needsApproval ? (
        <button
          onClick={handleApprove}
          disabled={isApproving}
          className="w-full py-3 bg-blue-500 text-white rounded-lg font-medium hover:bg-blue-600 disabled:opacity-50"
        >
          {isApproving ? 'Approving...' : `Approve ${tokenA.symbol}`}
        </button>
      ) : (
        <button
          onClick={() => handleSwap()}
          disabled={!canSwap}
          className="w-full py-3 bg-blue-500 text-white rounded-lg font-medium hover:bg-blue-600 disabled:opacity-50 disabled:bg-gray-300"
        >
          {!amountA ? 'Enter amount' : 
           parseTokenAmount(amountA, tokenA.decimals) > balanceA ? 'Insufficient balance' :
           'Swap (Demo)'}
        </button>
      )}
    </div>
  )
}