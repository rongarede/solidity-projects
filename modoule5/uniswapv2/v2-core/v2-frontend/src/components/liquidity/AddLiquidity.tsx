'use client'

import { useState, useEffect } from 'react'
import { useAccount } from 'wagmi'
import { useLiquidityStore } from '@/store/useLiquidityStore'
import { TokenSelect } from '../swap/TokenSelect'
import { useTokenBalance } from '@/hooks/useTokenBalance'
import { useLiquidityEstimate, useAddLiquidity } from '@/hooks/useAddLiquidity'
import { useTokenAllowance, useApproveToken } from '@/hooks/useSwap'
import { parseTokenAmount, formatTokenAmount } from '@/lib/utils'
import { isNativeToken } from '@/lib/tokens'
import { CONTRACTS } from '@/lib/contracts'
import { ClientOnly } from '../ClientOnly'
import { logError } from '@/lib/error-logger'

export function AddLiquidity() {
  const { address, isConnected } = useAccount()
  const [approveACompleted, setApproveACompleted] = useState(false)
  const [approveBCompleted, setApproveBCompleted] = useState(false)
  
  const {
    tokenA,
    tokenB,
    amountA,
    amountB,
    isAdding,
    setTokenA,
    setTokenB,
    setAmountA,
    setAmountB,
    setAmountBFromEstimate,
    setIsAdding,
    resetAmounts
  } = useLiquidityStore()

  const { balance: balanceA, formattedBalance: formattedBalanceA } = useTokenBalance(tokenA)
  const { balance: balanceB, formattedBalance: formattedBalanceB } = useTokenBalance(tokenB)
  
  const estimate = useLiquidityEstimate(tokenA, tokenB, amountA)
  const { 
    addLiquidity, 
    addLiquidityETH, 
    isPending, 
    isConfirming, 
    isSuccess, 
    error 
  } = useAddLiquidity()

  // 代币授权相关
  const { data: allowanceA, refetch: refetchAllowanceA } = useTokenAllowance(tokenA, CONTRACTS.UniswapV2Router02.address)
  const { data: allowanceB, refetch: refetchAllowanceB } = useTokenAllowance(tokenB, CONTRACTS.UniswapV2Router02.address)
  const { approve: approveA, isPending: isApprovingA, isSuccess: approveASuccess } = useApproveToken()
  const { approve: approveB, isPending: isApprovingB, isSuccess: approveBSuccess } = useApproveToken()

  // Auto-calculate tokenB amount when tokenA amount changes
  useEffect(() => {
    if (estimate.amountB !== '0' && amountA && !estimate.isNewPair && estimate.amountB !== amountB) {
      setAmountBFromEstimate(estimate.amountB)
    }
  }, [estimate.amountB, amountA, estimate.isNewPair, setAmountBFromEstimate])

  // Check if amounts are valid and within balance limits
  const isAmountAValid = amountA && parseFloat(amountA) > 0
  const isAmountBValid = amountB && parseFloat(amountB) > 0
  const hasEnoughBalanceA = !tokenA || balanceA === 0n || parseTokenAmount(amountA || '0', tokenA.decimals) <= balanceA
  const hasEnoughBalanceB = !tokenB || balanceB === 0n || parseTokenAmount(amountB || '0', tokenB.decimals) <= balanceB
  
  // 检查授权状态
  const needsApprovalA = tokenA && !isNativeToken(tokenA) && amountA && 
    parseTokenAmount(amountA, tokenA.decimals) > ((allowanceA as bigint) || 0n)
  const needsApprovalB = tokenB && !isNativeToken(tokenB) && amountB && 
    parseTokenAmount(amountB, tokenB.decimals) > ((allowanceB as bigint) || 0n)

  const canAddLiquidity = isConnected && tokenA && tokenB && 
    isAmountAValid && isAmountBValid && 
    hasEnoughBalanceA && hasEnoughBalanceB &&
    !needsApprovalA && !needsApprovalB

  // Handle success/error
  useEffect(() => {
    if (isSuccess) {
      setIsAdding(false)
      resetAmounts()
      console.log('Liquidity added successfully!')
    }
  }, [isSuccess, setIsAdding, resetAmounts])

  useEffect(() => {
    if (error) {
      setIsAdding(false)
      const errorMessage = error instanceof Error ? error.message : 
                          typeof error === 'string' ? error : 
                          'Unknown error occurred'
      
      logError({
        errorType: 'transaction',
        message: `添加流动性失败: ${errorMessage}`,
        context: { 
          tokenA: tokenA?.symbol, 
          tokenB: tokenB?.symbol,
          originalError: error
        }
      })
    }
  }, [error, tokenA, tokenB, setIsAdding])

  // 监听 approve A 成功
  useEffect(() => {
    if (approveASuccess) {
      console.log('Token A approved successfully, refreshing allowance...')
      setApproveACompleted(true)
      // 立即刷新一次
      refetchAllowanceA()
      // 然后在3秒后再次刷新，确保区块确认
      const timeoutId = setTimeout(() => {
        refetchAllowanceA()
      }, 3000)
      
      return () => clearTimeout(timeoutId)
    }
  }, [approveASuccess]) // 移除 refetchAllowanceA 依赖以避免循环

  // 监听 approve B 成功
  useEffect(() => {
    if (approveBSuccess) {
      console.log('Token B approved successfully, refreshing allowance...')
      setApproveBCompleted(true)
      // 立即刷新一次
      refetchAllowanceB()
      // 然后在3秒后再次刷新，确保区块确认
      const timeoutId = setTimeout(() => {
        refetchAllowanceB()
      }, 3000)
      
      return () => clearTimeout(timeoutId)
    }
  }, [approveBSuccess]) // 移除 refetchAllowanceB 依赖以避免循环

  // 重置approve状态当tokens改变时
  useEffect(() => {
    setApproveACompleted(false)
    setApproveBCompleted(false)
  }, [tokenA?.address, tokenB?.address])

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

  const handleApproveA = async () => {
    try {
      if (!tokenA || !amountA) return
      const amount = parseTokenAmount(amountA, tokenA.decimals)
      await approveA(tokenA, CONTRACTS.UniswapV2Router02.address, amount)
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 
                          typeof error === 'string' ? error : 
                          'Unknown error occurred'
      
      logError({
        errorType: 'transaction',
        message: `Token A 授权失败: ${errorMessage}`,
        context: { 
          token: tokenA?.symbol, 
          amount: amountA,
          originalError: error
        }
      })
    }
  }

  const handleApproveB = async () => {
    try {
      if (!tokenB || !amountB) return
      const amount = parseTokenAmount(amountB, tokenB.decimals)
      await approveB(tokenB, CONTRACTS.UniswapV2Router02.address, amount)
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 
                          typeof error === 'string' ? error : 
                          'Unknown error occurred'
      
      logError({
        errorType: 'transaction',
        message: `Token B 授权失败: ${errorMessage}`,
        context: { 
          token: tokenB?.symbol, 
          amount: amountB,
          originalError: error
        }
      })
    }
  }

  const handleAddLiquidity = async () => {
    try {
      if (!tokenA || !tokenB || !amountA || !amountB || !address) {
        throw new Error('Missing required parameters')
      }

      setIsAdding(true)

      const amountAParsed = parseTokenAmount(amountA, tokenA.decimals)
      const amountBParsed = parseTokenAmount(amountB, tokenB.decimals)
      const slippageTolerance = 0.5 // 0.5% 滑点
      const amountAMin = amountAParsed * BigInt(Math.floor((100 - slippageTolerance) * 100)) / 10000n
      const amountBMin = amountBParsed * BigInt(Math.floor((100 - slippageTolerance) * 100)) / 10000n
      const deadline = BigInt(Math.floor(Date.now() / 1000) + 1800) // 30 minutes

      if (isNativeToken(tokenA)) {
        // ETH + Token
        await addLiquidityETH(
          tokenB,
          amountBParsed,
          amountBMin,
          amountAMin,
          address,
          deadline,
          amountAParsed
        )
      } else if (isNativeToken(tokenB)) {
        // Token + ETH
        await addLiquidityETH(
          tokenA,
          amountAParsed,
          amountAMin,
          amountBMin,
          address,
          deadline,
          amountBParsed
        )
      } else {
        // Token + Token
        await addLiquidity(
          tokenA,
          tokenB,
          amountAParsed,
          amountBParsed,
          amountAMin,
          amountBMin,
          address,
          deadline
        )
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 
                          typeof error === 'string' ? error : 
                          'Unknown error occurred'
      
      logError({
        errorType: 'transaction',
        message: `添加流动性执行失败: ${errorMessage}`,
        context: { 
          tokenA: tokenA?.symbol, 
          tokenB: tokenB?.symbol, 
          amountA,
          amountB,
          originalError: error
        }
      })
      console.error('Add liquidity failed:', error)
      setIsAdding(false)
    }
  }

  const getButtonText = () => {
    if (!isConnected) return 'Connect Wallet'
    if (!tokenA || !tokenB) return 'Select tokens'
    if (!isAmountAValid) return 'Enter amount for ' + (tokenA?.symbol || 'Token A')
    if (!isAmountBValid) return 'Enter amount for ' + (tokenB?.symbol || 'Token B')
    if (!hasEnoughBalanceA && balanceA > 0n) return `Insufficient ${tokenA?.symbol} balance`
    if (!hasEnoughBalanceB && balanceB > 0n) return `Insufficient ${tokenB?.symbol} balance`
    if (needsApprovalA && isApprovingA) return `Approving ${tokenA?.symbol}...`
    if (needsApprovalA && approveACompleted) return `${tokenA?.symbol} Approved ✓ Please wait...`
    if (needsApprovalA) return `Approve ${tokenA?.symbol}`
    if (needsApprovalB && isApprovingB) return `Approving ${tokenB?.symbol}...`
    if (needsApprovalB && approveBCompleted) return `${tokenB?.symbol} Approved ✓ Please wait...`
    if (needsApprovalB) return `Approve ${tokenB?.symbol}`
    if (isAdding || isPending) return 'Confirming...'
    if (isConfirming) return 'Adding Liquidity...'
    return 'Add Liquidity'
  }

  const getButtonAction = () => {
    if (needsApprovalA) return handleApproveA
    if (needsApprovalB) return handleApproveB
    return handleAddLiquidity
  }

  const isButtonDisabled = () => {
    if (!isConnected || !tokenA || !tokenB) return true
    if (!isAmountAValid || !isAmountBValid) return true
    if (!hasEnoughBalanceA || !hasEnoughBalanceB) return true
    if (isAdding || isPending || isConfirming || isApprovingA || isApprovingB) return true
    // 如果刚approve成功但还在等待刷新，也应该禁用
    if (approveACompleted && needsApprovalA) return true
    if (approveBCompleted && needsApprovalB) return true
    return false
  }

  return (
    <div className="bg-white rounded-xl shadow-lg p-6 w-full max-w-md mx-auto">
      <h2 className="text-xl font-bold mb-6">Add Liquidity</h2>

      {/* Token A Input */}
      <div className="mb-4">
        <div className="flex items-center justify-between mb-2">
          <span className="text-sm text-gray-600">Token A</span>
          <ClientOnly fallback={<span className="text-sm text-gray-500">Balance: --</span>}>
            {isConnected && tokenA && (
              <span className="text-sm text-gray-500">
                Balance: {parseFloat(formattedBalanceA).toFixed(4)}
              </span>
            )}
          </ClientOnly>
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
            <ClientOnly>
              {isConnected && tokenA && balanceA > 0n && (
                <button
                  onClick={handleMaxA}
                  className="text-xs text-blue-500 hover:text-blue-600"
                >
                  MAX
                </button>
              )}
            </ClientOnly>
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
          <ClientOnly fallback={<span className="text-sm text-gray-500">Balance: --</span>}>
            {isConnected && tokenB && (
              <span className="text-sm text-gray-500">
                Balance: {parseFloat(formattedBalanceB).toFixed(4)}
              </span>
            )}
          </ClientOnly>
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
            <ClientOnly>
              {isConnected && tokenB && balanceB > 0n && (
                <button
                  onClick={handleMaxB}
                  className="text-xs text-blue-500 hover:text-blue-600"
                >
                  MAX
                </button>
              )}
            </ClientOnly>
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
          <div className="flex justify-between mb-1">
            <span className="text-gray-600">{tokenB.symbol} per {tokenA.symbol}:</span>
            <span>{(parseFloat(amountB) / parseFloat(amountA)).toFixed(6)}</span>
          </div>
          {estimate.liquidityMinted !== '0' && (
            <div className="flex justify-between">
              <span className="text-gray-600">LP tokens to receive:</span>
              <span>{parseFloat(estimate.liquidityMinted).toFixed(6)}</span>
            </div>
          )}
          {estimate.isNewPair && (
            <div className="mt-2 p-2 bg-yellow-100 text-yellow-800 rounded text-xs">
              You are the first liquidity provider for this pair. You can set the initial price.
            </div>
          )}
        </div>
      )}

      {/* Approval Progress */}
      {(needsApprovalA || needsApprovalB || approveACompleted || approveBCompleted) && (
        <div className="mb-4 p-3 bg-blue-50 rounded-lg text-sm">
          <div className="font-medium text-blue-800 mb-2">Token Approval Required</div>
          <div className="space-y-1">
            {tokenA && (
              <div className="flex items-center justify-between">
                <span>{tokenA.symbol}:</span>
                <span className={`text-xs px-2 py-1 rounded ${
                  approveACompleted ? 'bg-green-100 text-green-800' : 
                  !needsApprovalA ? 'bg-green-100 text-green-800' :
                  isApprovingA ? 'bg-yellow-100 text-yellow-800' :
                  'bg-gray-100 text-gray-600'
                }`}>
                  {approveACompleted ? 'Approved ✓' : 
                   !needsApprovalA ? 'Approved ✓' :
                   isApprovingA ? 'Approving...' :
                   'Pending'}
                </span>
              </div>
            )}
            {tokenB && (
              <div className="flex items-center justify-between">
                <span>{tokenB.symbol}:</span>
                <span className={`text-xs px-2 py-1 rounded ${
                  approveBCompleted ? 'bg-green-100 text-green-800' : 
                  !needsApprovalB ? 'bg-green-100 text-green-800' :
                  isApprovingB ? 'bg-yellow-100 text-yellow-800' :
                  'bg-gray-100 text-gray-600'
                }`}>
                  {approveBCompleted ? 'Approved ✓' : 
                   !needsApprovalB ? 'Approved ✓' :
                   isApprovingB ? 'Approving...' :
                   'Pending'}
                </span>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Action Button */}
      <ClientOnly fallback={
        <button
          disabled
          className="w-full py-3 rounded-lg font-medium bg-gray-300 text-gray-500 cursor-not-allowed"
        >
          Loading...
        </button>
      }>
        <button
          onClick={getButtonAction()}
          disabled={isButtonDisabled()}
          className={`w-full py-3 rounded-lg font-medium transition-colors ${
            !isButtonDisabled()
              ? 'bg-blue-500 text-white hover:bg-blue-600'
              : 'bg-gray-300 text-gray-500 cursor-not-allowed'
          }`}
        >
          {getButtonText()}
        </button>
      </ClientOnly>
    </div>
  )
}