import { useAccount, useWriteContract, useWaitForTransactionReceipt, useReadContract } from 'wagmi'
import { Token } from '@/types/tokens'
import { parseTokenAmount, formatTokenAmount } from '@/lib/utils'
import { useTokenPrice } from './useTokenPrice'
import { CONTRACTS, UNISWAP_V2_PAIR_ABI } from '@/lib/contracts'
import { isNativeToken, WETH_TOKEN, MOCKWETH_TOKEN } from '@/lib/tokens'
import { logError } from '@/lib/error-logger'

export function useLiquidityEstimate(tokenA?: Token, tokenB?: Token, amountA?: string) {
  const { pairExists } = useTokenPrice(tokenA, tokenB)

  // 获取交易对地址
  const { data: pairAddress } = useReadContract({
    address: CONTRACTS.UniswapV2Factory.address,
    abi: CONTRACTS.UniswapV2Factory.abi,
    functionName: 'getPair',
    args: tokenA && tokenB ? [
      isNativeToken(tokenA) ? MOCKWETH_TOKEN.address : tokenA.address,
      isNativeToken(tokenB) ? MOCKWETH_TOKEN.address : tokenB.address
    ] : undefined,
    query: {
      enabled: !!tokenA && !!tokenB
    }
  })

  // 获取储备量
  const { data: reserves } = useReadContract({
    address: pairAddress as `0x${string}`,
    abi: UNISWAP_V2_PAIR_ABI,
    functionName: 'getReserves',
    query: {
      enabled: !!pairAddress && pairAddress !== '0x0000000000000000000000000000000000000000'
    }
  })

  // 获取LP代币总供应量
  const { data: totalSupply } = useReadContract({
    address: pairAddress as `0x${string}`,
    abi: UNISWAP_V2_PAIR_ABI,
    functionName: 'totalSupply',
    query: {
      enabled: !!pairAddress && pairAddress !== '0x0000000000000000000000000000000000000000'
    }
  })

  if (!tokenA || !tokenB || !amountA || amountA === '') {
    return {
      amountB: '0',
      shareOfPool: 0,
      isNewPair: !pairExists,
      liquidityMinted: '0'
    }
  }

  try {
    const amountAParsed = parseTokenAmount(amountA, tokenA.decimals)

    if (!pairExists || !reserves) {
      // 新交易对，比例由用户决定
      return {
        amountB: '0',
        shareOfPool: 100,
        isNewPair: true,
        liquidityMinted: '0'
      }
    }

    // 获取token0和token1的顺序 - 使用 MockWETH 替代真实 WETH
    const token0Address = isNativeToken(tokenA) ? MOCKWETH_TOKEN.address : tokenA.address
    const token1Address = isNativeToken(tokenB) ? MOCKWETH_TOKEN.address : tokenB.address
    const isTokenAToken0 = token0Address.toLowerCase() < token1Address.toLowerCase()

    const [reserve0, reserve1] = reserves as [bigint, bigint, number]
    const [reserveA, reserveB] = isTokenAToken0 ? [reserve0, reserve1] : [reserve1, reserve0]

    // 计算所需的tokenB数量
    const amountBRequired = (amountAParsed * reserveB) / reserveA
    const amountBFormatted = formatTokenAmount(amountBRequired, tokenB.decimals)

    // 计算将获得的流动性代币数量
    let liquidityMinted = '0'
    if (totalSupply && typeof totalSupply === 'bigint' && totalSupply > 0n) {
      const liquidity = (amountAParsed * totalSupply) / reserveA
      liquidityMinted = formatTokenAmount(liquidity, 18) // LP代币通常是18位小数
    }

    // 计算池子份额
    const shareOfPool = totalSupply && typeof totalSupply === 'bigint' && totalSupply > 0n 
      ? Number((amountAParsed * 10000n) / (reserveA + amountAParsed)) / 100
      : 100

    return {
      amountB: amountBFormatted,
      shareOfPool: Math.min(shareOfPool, 100),
      isNewPair: false,
      liquidityMinted
    }
  } catch (error) {
    logError({
      errorType: 'calculation',
      message: `流动性估算失败: ${error}`,
      context: { 
        tokenA: tokenA.symbol, 
        tokenB: tokenB.symbol, 
        amountA 
      }
    })
    return {
      amountB: '0',
      shareOfPool: 0,
      isNewPair: !pairExists,
      liquidityMinted: '0'
    }
  }
}

export function useAddLiquidity() {
  const { writeContract, data: hash, isPending, error } = useWriteContract()
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  })

  const addLiquidity = async (
    tokenA: Token,
    tokenB: Token,
    amountA: bigint,
    amountB: bigint,
    amountAMin: bigint,
    amountBMin: bigint,
    to: string,
    deadline: bigint
  ) => {
    try {
      writeContract({
        address: CONTRACTS.UniswapV2Router02.address,
        abi: CONTRACTS.UniswapV2Router02.abi,
        functionName: 'addLiquidity',
        args: [
          tokenA.address as `0x${string}`,
          tokenB.address as `0x${string}`,
          amountA,
          amountB,
          amountAMin,
          amountBMin,
          to as `0x${string}`,
          deadline
        ]
      })
    } catch (error) {
      logError({
        errorType: 'transaction',
        message: `addLiquidity 失败: ${error}`,
        context: { 
          tokenA: tokenA.symbol, 
          tokenB: tokenB.symbol, 
          amountA: amountA.toString(),
          amountB: amountB.toString()
        }
      })
      throw error
    }
  }

  const addLiquidityETH = async (
    token: Token,
    amountToken: bigint,
    amountTokenMin: bigint,
    amountETHMin: bigint,
    to: string,
    deadline: bigint,
    value: bigint
  ) => {
    try {
      // Router 将自动使用 MockWETH 处理 ETH 流动性
      writeContract({
        address: CONTRACTS.UniswapV2Router02.address,
        abi: CONTRACTS.UniswapV2Router02.abi,
        functionName: 'addLiquidityETH',
        args: [
          token.address as `0x${string}`,
          amountToken,
          amountTokenMin,
          amountETHMin,
          to as `0x${string}`,
          deadline
        ],
        value
      })
    } catch (error) {
      logError({
        errorType: 'transaction',
        message: `addLiquidityETH 失败: ${error}`,
        context: { 
          token: token.symbol, 
          amountToken: amountToken.toString(),
          amountETH: value.toString()
        }
      })
      throw error
    }
  }

  return {
    addLiquidity,
    addLiquidityETH,
    hash,
    isPending,
    isConfirming,
    isSuccess,
    error
  }
}