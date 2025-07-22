import { useAccount, useBalance, useReadContract } from 'wagmi'
import { Token, TokenBalance } from '@/types/tokens'
import { ERC20_ABI, isNativeToken } from '@/lib/tokens'
import { formatTokenAmount } from '@/lib/utils'
import { logError } from '@/lib/error-logger'
import { useEffect } from 'react'

export function useTokenBalance(token?: Token): TokenBalance {
  const { address } = useAccount()

  const nativeBalance = useBalance({
    address,
    query: { 
      enabled: !!address && !!token && isNativeToken(token) 
    }
  })

  const erc20Balance = useReadContract({
    address: token?.address as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
    query: { 
      enabled: !!address && !!token && !isNativeToken(token) 
    }
  })

  // Log errors when they occur
  useEffect(() => {
    if (nativeBalance.error) {
      logError({
        errorType: 'network',
        message: `Native balance query failed: ${nativeBalance.error.message}`,
        context: {
          component: 'useTokenBalance',
          tokenAddress: token?.address,
          tokenSymbol: token?.symbol,
          type: 'native_balance_query_failed'
        }
      })
    }
  }, [nativeBalance.error, token?.address, token?.symbol])

  useEffect(() => {
    if (erc20Balance.error) {
      logError({
        errorType: 'network',
        message: `ERC20 balance query failed: ${erc20Balance.error.message}`,
        context: {
          component: 'useTokenBalance',
          tokenAddress: token?.address,
          tokenSymbol: token?.symbol,
          type: 'erc20_balance_query_failed'
        }
      })
    }
  }, [erc20Balance.error, token?.address, token?.symbol])

  if (!token || !address) {
    return {
      token: token || {
        address: '',
        symbol: '',
        name: '',
        decimals: 18
      },
      balance: 0n,
      formattedBalance: '0',
      loading: false,
      error: null
    }
  }

  if (isNativeToken(token)) {
    return {
      token,
      balance: nativeBalance.data?.value || 0n,
      formattedBalance: nativeBalance.data?.value 
        ? formatTokenAmount(nativeBalance.data.value, token.decimals)
        : '0',
      loading: nativeBalance.isLoading,
      error: nativeBalance.error?.message || null
    }
  }

  return {
    token,
    balance: (erc20Balance.data as bigint) || 0n,
    formattedBalance: erc20Balance.data 
      ? formatTokenAmount(erc20Balance.data as bigint, token.decimals)
      : '0',
    loading: erc20Balance.isLoading,
    error: erc20Balance.error?.message || null
  }
}

export function useMultipleTokenBalances(tokens: Token[]) {
  const { address } = useAccount()

  const balances = tokens.map(token => useTokenBalance(token))

  // Log batch query errors
  useEffect(() => {
    const errors = balances.filter(b => b.error)
    if (errors.length > 0) {
      logError({
        errorType: 'network',
        message: `Failed to fetch ${errors.length} token balances`,
        context: {
          component: 'useMultipleTokenBalances',
          failedTokens: errors.map(e => e.token.symbol).join(', '),
          type: 'batch_balance_query_failed'
        }
      })
    }
  }, [balances])

  return {
    balances,
    isLoading: balances.some(b => b.loading),
    hasError: balances.some(b => b.error),
    totalTokens: tokens.length,
    loadedTokens: balances.filter(b => !b.loading && !b.error).length
  }
}