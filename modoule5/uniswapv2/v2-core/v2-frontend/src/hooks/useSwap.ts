import { useAccount, useWriteContract, useWaitForTransactionReceipt, useReadContract } from 'wagmi'
import { Token } from '@/types/tokens'
import { ERC20_ABI, isNativeToken, WETH_TOKEN, MOCKWETH_TOKEN } from '@/lib/tokens'
import { parseTokenAmount, formatTokenAmount } from '@/lib/utils'
import { CONTRACTS } from '@/lib/contracts'
import { logError } from '@/lib/error-logger'

export function useTokenAllowance(token?: Token, spender?: string) {
  const { address } = useAccount()

  return useReadContract({
    address: token?.address as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'allowance',
    args: address && spender ? [address, spender as `0x${string}`] : undefined,
    query: {
      enabled: !!address && !!spender && !!token && !isNativeToken(token),
      refetchInterval: 5000, // 每5秒自动刷新
      staleTime: 1000, // 数据1秒后就认为过期
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

    try {
      writeContract({
        address: token.address as `0x${string}`,
        abi: ERC20_ABI,
        functionName: 'approve',
        args: [spender as `0x${string}`, amount]
      })
    } catch (approveError) {
      logError({
        errorType: 'transaction',
        message: `Token approve failed: ${approveError}`,
        context: { 
          tokenAddress: token.address,
          tokenSymbol: token.symbol,
          spender,
          amount: amount.toString()
        }
      })
      throw approveError
    }
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
  // 构建交换路径 - 使用 MockWETH 替代真实 WETH
  const getSwapPath = (tokenFrom: Token, tokenTo: Token): string[] => {
    if (isNativeToken(tokenFrom) || isNativeToken(tokenTo)) {
      // ETH 交换需要通过 MockWETH (替代真实 WETH)
      if (isNativeToken(tokenFrom)) {
        return [MOCKWETH_TOKEN.address, tokenTo.address]
      } else {
        return [tokenFrom.address, MOCKWETH_TOKEN.address]
      }
    }
    return [tokenFrom.address, tokenTo.address]
  }

  const path = tokenA && tokenB ? getSwapPath(tokenA, tokenB) : []
  const amountInParsed = tokenA && amountIn ? parseTokenAmount(amountIn, tokenA.decimals) : 0n

  // 使用 Router 合约获取真实价格
  const { data: amountsOut } = useReadContract({
    address: CONTRACTS.UniswapV2Router02.address,
    abi: CONTRACTS.UniswapV2Router02.abi,
    functionName: 'getAmountsOut',
    args: [amountInParsed, path],
    query: {
      enabled: !!tokenA && !!tokenB && !!amountIn && amountIn !== '' && amountIn !== '0' && path.length > 0,
      refetchInterval: 10000, // 每10秒刷新一次价格
    }
  })

  if (!tokenA || !tokenB || !amountIn || amountIn === '' || amountIn === '0' || !amountsOut) {
    return {
      amountOut: '0',
      minimumAmountOut: '0',
      priceImpact: 0,
      fee: '0',
      path: []
    }
  }

  try {
    const amounts = amountsOut as bigint[]
    const outputAmount = amounts[amounts.length - 1]
    const amountOutFormatted = formatTokenAmount(outputAmount, tokenB.decimals)
    
    // 计算滑点保护 (默认 0.5%)
    const minimumAmount = outputAmount * 995n / 1000n
    const minimumAmountFormatted = formatTokenAmount(minimumAmount, tokenB.decimals)
    
    // 计算手续费 (0.3%)
    const feeAmount = amountInParsed * 3n / 1000n
    const feeFormatted = formatTokenAmount(feeAmount, tokenA.decimals)
    
    // 计算价格影响 (简化计算)
    const inputAmountNum = Number(amountIn)
    const outputAmountNum = Number(amountOutFormatted)
    const expectedRate = 1.0 // 假设 1:1 比例
    const actualRate = outputAmountNum / inputAmountNum
    const priceImpact = Math.abs((expectedRate - actualRate) / expectedRate) * 100
    
    return {
      amountOut: amountOutFormatted,
      minimumAmountOut: minimumAmountFormatted,
      priceImpact: Math.min(priceImpact, 100), // 限制最大值为100%
      fee: feeFormatted,
      path
    }
  } catch (error) {
    logError({
      errorType: 'calculation',
      message: `价格计算失败: ${error}`,
      context: { tokenA: tokenA.symbol, tokenB: tokenB.symbol, amountIn }
    })
    return {
      amountOut: '0',
      minimumAmountOut: '0',
      priceImpact: 0,
      fee: '0',
      path: []
    }
  }
}

export function useSwap() {
  const { writeContract, data: hash, isPending, error } = useWriteContract()
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  })

  // 构建交换路径 - 使用 MockWETH 替代真实 WETH
  const getSwapPath = (tokenFrom: Token, tokenTo: Token): string[] => {
    if (isNativeToken(tokenFrom) || isNativeToken(tokenTo)) {
      // ETH 交换需要通过 MockWETH (替代真实 WETH)
      if (isNativeToken(tokenFrom)) {
        return [MOCKWETH_TOKEN.address, tokenTo.address]
      } else {
        return [tokenFrom.address, MOCKWETH_TOKEN.address]
      }
    }
    return [tokenFrom.address, tokenTo.address]
  }

  const swapExactTokensForTokens = async (
    amountIn: bigint,
    amountOutMin: bigint,
    tokenA: Token,
    tokenB: Token,
    to: string,
    deadline: bigint
  ) => {
    try {
      const path = getSwapPath(tokenA, tokenB)
      
      writeContract({
        address: CONTRACTS.UniswapV2Router02.address,
        abi: CONTRACTS.UniswapV2Router02.abi,
        functionName: 'swapExactTokensForTokens',
        args: [amountIn, amountOutMin, path, to as `0x${string}`, deadline]
      })
    } catch (error) {
      logError({
        errorType: 'transaction',
        message: `swapExactTokensForTokens 失败: ${error}`,
        context: { 
          tokenA: tokenA.symbol, 
          tokenB: tokenB.symbol, 
          amountIn: amountIn.toString() 
        }
      })
      throw error
    }
  }

  const swapTokensForExactTokens = async (
    amountOut: bigint,
    amountInMax: bigint,
    tokenA: Token,
    tokenB: Token,
    to: string,
    deadline: bigint
  ) => {
    try {
      const path = getSwapPath(tokenA, tokenB)
      
      writeContract({
        address: CONTRACTS.UniswapV2Router02.address,
        abi: CONTRACTS.UniswapV2Router02.abi,
        functionName: 'swapTokensForExactTokens',
        args: [amountOut, amountInMax, path, to as `0x${string}`, deadline]
      })
    } catch (error) {
      logError({
        errorType: 'transaction',
        message: `swapTokensForExactTokens 失败: ${error}`,
        context: { 
          tokenA: tokenA.symbol, 
          tokenB: tokenB.symbol, 
          amountOut: amountOut.toString() 
        }
      })
      throw error
    }
  }

  const swapExactETHForTokens = async (
    amountOutMin: bigint,
    tokenOut: Token,
    to: string,
    deadline: bigint,
    value: bigint
  ) => {
    try {
      // 使用 MockWETH 替代真实 WETH
      const path = [MOCKWETH_TOKEN.address, tokenOut.address]
      
      writeContract({
        address: CONTRACTS.UniswapV2Router02.address,
        abi: CONTRACTS.UniswapV2Router02.abi,
        functionName: 'swapExactETHForTokens',
        args: [amountOutMin, path, to as `0x${string}`, deadline],
        value
      })
    } catch (error) {
      logError({
        errorType: 'transaction',
        message: `swapExactETHForTokens 失败: ${error}`,
        context: { 
          tokenOut: tokenOut.symbol, 
          value: value.toString() 
        }
      })
      throw error
    }
  }

  const swapTokensForExactETH = async (
    amountOut: bigint,
    amountInMax: bigint,
    tokenIn: Token,
    to: string,
    deadline: bigint
  ) => {
    try {
      // 使用 MockWETH 替代真实 WETH
      const path = [tokenIn.address, MOCKWETH_TOKEN.address]
      
      writeContract({
        address: CONTRACTS.UniswapV2Router02.address,
        abi: CONTRACTS.UniswapV2Router02.abi,
        functionName: 'swapTokensForExactETH',
        args: [amountOut, amountInMax, path, to as `0x${string}`, deadline]
      })
    } catch (error) {
      logError({
        errorType: 'transaction',
        message: `swapTokensForExactETH 失败: ${error}`,
        context: { 
          tokenIn: tokenIn.symbol, 
          amountOut: amountOut.toString() 
        }
      })
      throw error
    }
  }

  const swapExactTokensForETH = async (
    amountIn: bigint,
    amountOutMin: bigint,
    tokenIn: Token,
    to: string,
    deadline: bigint
  ) => {
    try {
      // 使用 MockWETH 替代真实 WETH
      const path = [tokenIn.address, MOCKWETH_TOKEN.address]
      
      writeContract({
        address: CONTRACTS.UniswapV2Router02.address,
        abi: CONTRACTS.UniswapV2Router02.abi,
        functionName: 'swapExactTokensForETH',
        args: [amountIn, amountOutMin, path, to as `0x${string}`, deadline]
      })
    } catch (error) {
      logError({
        errorType: 'transaction',
        message: `swapExactTokensForETH 失败: ${error}`,
        context: { 
          tokenIn: tokenIn.symbol, 
          amountIn: amountIn.toString() 
        }
      })
      throw error
    }
  }

  return {
    swapExactTokensForTokens,
    swapTokensForExactTokens,
    swapExactETHForTokens,
    swapTokensForExactETH,
    swapExactTokensForETH,
    hash,
    isPending,
    isConfirming,
    isSuccess,
    error
  }
}