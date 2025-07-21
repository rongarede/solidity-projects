'use client'

import { useState, useEffect } from 'react'
import { useAccount } from 'wagmi'
import { useLiquidityStore } from '@/store/useLiquidityStore'
import { TokenSelect } from '../swap/TokenSelect'
import { useTokenBalance } from '@/hooks/useTokenBalance'
import { useLiquidityEstimate, useAddLiquidity } from '@/hooks/useAddLiquidity'
import { parseTokenAmount, formatTokenAmount } from '@/lib/utils'

export function AddLiquidity() {
  const { address, isConnected } = useAccount()
  
  const {
    tokenA,
    tokenB,
    amountA,
    amountB,
    setTokenA,
    setTokenB,
    setAmountA,
    setAmountB,
    resetAmounts
  } = useLiquidityStore()

  const { balance: balanceA, formattedBalance: formattedBalanceA } = useTokenBalance(tokenA)
  const { balance: balanceB, formattedBalance: formattedBalanceB } = useTokenBalance(tokenB)
  
  const estimate = useLiquidityEstimate(tokenA, tokenB, amountA)
  const { addLiquidity, isPending } = useAddLiquidity()

  // Auto-calculate tokenB amount when tokenA amount changes
  useEffect(() => {
    if (estimate.amountB !== '0' && amountA) {
      setAmountB(estimate.amountB)
    }
  }, [estimate.amountB, amountA, setAmountB])

  const canAddLiquidity = isConnected && tokenA && tokenB && amountA && amountB &&
    parseFloat(amountA) > 0 && parseFloat(amountB) > 0 &&
    parseTokenAmount(amountA, tokenA.decimals) <= balanceA &&
    parseTokenAmount(amountB, tokenB.decimals) <= balanceB

  const handleMaxA = () => {
    if (tokenA && balanceA > 0n) {
      const maxAmount = formatTokenAmount(balanceA, tokenA.decimals)
      setAmountA(maxAmount)
    }
  }

  const handleMaxB = () => {
    if (tokenB && balanceB > 0n) {
      const maxAmount = formatTokenAmount(balanceB, tokenB.decimals)
      setAmountB(maxAmount)
    }
  }

  const handleAddLiquidity = async () => {
    console.log('Add liquidity not implemented yet - would call router contract')
  }

  return (
    <div className="bg-white rounded-xl shadow-lg p-6 w-full max-w-md mx-auto">
      <h2 className="text-xl font-bold mb-6">Add Liquidity</h2>

      {/* Token A Input */}
      <div className="mb-4">
        <div className="flex items-center justify-between mb-2">
          <span className="text-sm text-gray-600">Token A</span>
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
          </div>
          
          <div className="flex flex-col items-end gap-2">
            <TokenSelect
              selectedToken={tokenA}
              onTokenSelect={setTokenA}
              excludeToken={tokenB}
            />
            {isConnected && tokenA && balanceA > 0n && (
              <button
                onClick={handleMaxA}
                className="text-xs text-blue-500 hover:text-blue-600"
              >
                MAX
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Plus Icon */}
      <div className="flex justify-center my-4">
        <div className="p-2 border-2 border-gray-200 rounded-lg">
          <svg className="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
          </svg>
        </div>
      </div>

      {/* Token B Input */}
      <div className="mb-6">
        <div className="flex items-center justify-between mb-2">
          <span className="text-sm text-gray-600">Token B</span>
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
          </div>
          
          <div className="flex flex-col items-end gap-2">
            <TokenSelect
              selectedToken={tokenB}
              onTokenSelect={setTokenB}
              excludeToken={tokenA}
            />
            {isConnected && tokenB && balanceB > 0n && (
              <button
                onClick={handleMaxB}
                className="text-xs text-blue-500 hover:text-blue-600"
              >
                MAX
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Liquidity Info */}
      {tokenA && tokenB && amountA && amountB && (
        <div className="mb-4 p-3 bg-gray-50 rounded-lg text-sm">
          <div className="flex justify-between mb-1">
            <span className="text-gray-600">Share of pool:</span>
            <span>{estimate.shareOfPool.toFixed(2)}%</span>
          </div>
          <div className="flex justify-between mb-1">
            <span className="text-gray-600">{tokenA.symbol} per {tokenB.symbol}:</span>
            <span>{(parseFloat(amountA) / parseFloat(amountB)).toFixed(6)}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-gray-600">{tokenB.symbol} per {tokenA.symbol}:</span>
            <span>{(parseFloat(amountB) / parseFloat(amountA)).toFixed(6)}</span>
          </div>
          {estimate.isNewPair && (
            <div className="mt-2 p-2 bg-yellow-100 text-yellow-800 rounded text-xs">
              You are the first liquidity provider for this pair. You can set the initial price.
            </div>
          )}
        </div>
      )}

      {/* Action Button */}
      {!isConnected ? (
        <div className="text-center text-gray-500">
          Connect wallet to add liquidity
        </div>
      ) : !tokenA || !tokenB ? (
        <button
          disabled
          className="w-full py-3 bg-gray-300 text-gray-500 rounded-lg font-medium"
        >
          Select tokens
        </button>
      ) : (
        <button
          onClick={handleAddLiquidity}
          disabled={!canAddLiquidity || isPending}
          className="w-full py-3 bg-blue-500 text-white rounded-lg font-medium hover:bg-blue-600 disabled:opacity-50 disabled:bg-gray-300"
        >
          {isPending ? 'Adding Liquidity...' :
           !amountA || !amountB ? 'Enter amounts' :
           parseTokenAmount(amountA, tokenA.decimals) > balanceA ? `Insufficient ${tokenA.symbol} balance` :
           parseTokenAmount(amountB, tokenB.decimals) > balanceB ? `Insufficient ${tokenB.symbol} balance` :
           'Add Liquidity (Demo)'}
        </button>
      )}
    </div>
  )
}