import { useAccount, useWriteContract, useWaitForTransactionReceipt, useReadContract } from 'wagmi'
import { Token } from '@/types/tokens'
import { ERC20_ABI, isNativeToken } from '@/lib/tokens'
import { parseTokenAmount } from '@/lib/utils'
import { CONTRACTS } from '@/lib/contracts'
import { calculateAmountOut, calculateAmountIn } from './useTokenPrice'

export function useTokenAllowance(token?: Token, spender?: string) {
  const { address } = useAccount()

  return useReadContract({
    address: token?.address as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'allowance',
    args: address && spender ? [address, spender as `0x${string}`] : undefined,
    query: {
      enabled: !!address && !!spender && !!token && !isNativeToken(token)
    }
  })
}

export function useApproveToken() {
  const { writeContract, data: hash, isPending, error } = useWriteContract()
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  })

  const approve = async (token: Token, spender: string, amount: bigint) => {
    if (isNativeToken(token)) {
      throw new Error('Cannot approve native token')
    }

    writeContract({
      address: token.address as `0x${string}`,
      abi: ERC20_ABI,
      functionName: 'approve',
      args: [spender as `0x${string}`, amount]
    })
  }

  return {
    approve,
    hash,
    isPending,
    isConfirming,
    isSuccess,
    error
  }
}

export function useSwapEstimate(
  tokenA?: Token,
  tokenB?: Token,
  amountIn?: string,
  isExactIn: boolean = true
) {
  // For now, return mock data since we need router contract
  // In a full implementation, this would call the router's getAmountsOut/getAmountsIn
  
  if (!tokenA || !tokenB || !amountIn || amountIn === '' || amountIn === '0') {
    return {
      amountOut: '0',
      minimumAmountOut: '0',
      priceImpact: 0,
      fee: '0'
    }
  }

  // Mock calculation - in real implementation, use router contract
  const inputAmount = parseTokenAmount(amountIn, tokenA.decimals)
  const mockRate = 0.95 // Mock exchange rate
  const outputAmount = inputAmount * BigInt(Math.floor(mockRate * 1000)) / 1000n
  
  return {
    amountOut: (Number(outputAmount) / 10 ** tokenB.decimals).toString(),
    minimumAmountOut: (Number(outputAmount * 995n / 1000n) / 10 ** tokenB.decimals).toString(), // 0.5% slippage
    priceImpact: 0.1, // Mock 0.1% price impact
    fee: (Number(inputAmount) * 0.003 / 10 ** tokenA.decimals).toString() // 0.3% fee
  }
}

export function useSwap() {
  const { writeContract, data: hash, isPending, error } = useWriteContract()
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  })

  const swapExactTokensForTokens = async (
    amountIn: bigint,
    amountOutMin: bigint,
    tokenA: Token,
    tokenB: Token,
    to: string,
    deadline: bigint
  ) => {
    // This would use the Uniswap V2 Router contract
    // For now, we'll just throw an error since we don't have the router deployed
    throw new Error('Router contract not implemented yet. This would call swapExactTokensForTokens on Uniswap V2 Router.')
  }

  const swapTokensForExactTokens = async (
    amountOut: bigint,
    amountInMax: bigint,
    tokenA: Token,
    tokenB: Token,
    to: string,
    deadline: bigint
  ) => {
    throw new Error('Router contract not implemented yet. This would call swapTokensForExactTokens on Uniswap V2 Router.')
  }

  const swapExactETHForTokens = async (
    amountOutMin: bigint,
    tokenOut: Token,
    to: string,
    deadline: bigint,
    value: bigint
  ) => {
    throw new Error('Router contract not implemented yet. This would call swapExactETHForTokens on Uniswap V2 Router.')
  }

  const swapTokensForExactETH = async (
    amountOut: bigint,
    amountInMax: bigint,
    tokenIn: Token,
    to: string,
    deadline: bigint
  ) => {
    throw new Error('Router contract not implemented yet. This would call swapTokensForExactETH on Uniswap V2 Router.')
  }

  return {
    swapExactTokensForTokens,
    swapTokensForExactTokens,
    swapExactETHForTokens,
    swapTokensForExactETH,
    hash,
    isPending,
    isConfirming,
    isSuccess,
    error
  }
}