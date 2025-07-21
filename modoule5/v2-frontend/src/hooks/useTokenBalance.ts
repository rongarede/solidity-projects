import { useAccount, useBalance, useReadContract } from 'wagmi'
import { Token } from '@/types/tokens'
import { ERC20_ABI, isNativeToken } from '@/lib/tokens'
import { formatTokenAmount } from '@/lib/utils'

export function useTokenBalance(token?: Token) {
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

  if (!token || !address) {
    return {
      data: undefined,
      balance: 0n,
      formattedBalance: '0',
      isLoading: false,
      error: null
    }
  }

  if (isNativeToken(token)) {
    return {
      data: nativeBalance.data,
      balance: nativeBalance.data?.value || 0n,
      formattedBalance: nativeBalance.data?.value 
        ? formatTokenAmount(nativeBalance.data.value, token.decimals)
        : '0',
      isLoading: nativeBalance.isLoading,
      error: nativeBalance.error
    }
  }

  return {
    data: erc20Balance.data,
    balance: (erc20Balance.data as bigint) || 0n,
    formattedBalance: erc20Balance.data 
      ? formatTokenAmount(erc20Balance.data as bigint, token.decimals)
      : '0',
    isLoading: erc20Balance.isLoading,
    error: erc20Balance.error
  }
}

export function useMultipleTokenBalances(tokens: Token[]) {
  const { address } = useAccount()

  const balances = tokens.map(token => ({
    token,
    ...useTokenBalance(token)
  }))

  return {
    balances,
    isLoading: balances.some(b => b.isLoading),
    hasError: balances.some(b => b.error)
  }
}