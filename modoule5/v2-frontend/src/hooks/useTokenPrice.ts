import { useReadContract } from 'wagmi'
import { Token } from '@/types/tokens'
import { CONTRACTS, UNISWAP_V2_PAIR_ABI } from '@/lib/contracts'
import { parseTokenAmount } from '@/lib/utils'

export function usePairAddress(tokenA?: Token, tokenB?: Token) {
  return useReadContract({
    address: CONTRACTS.UniswapV2Factory.address,
    abi: CONTRACTS.UniswapV2Factory.abi,
    functionName: 'getPair',
    args: tokenA && tokenB ? [tokenA.address as `0x${string}`, tokenB.address as `0x${string}`] : undefined,
    query: {
      enabled: !!tokenA && !!tokenB && tokenA.address !== tokenB.address
    }
  })
}

export function usePairReserves(pairAddress?: string) {
  return useReadContract({
    address: pairAddress as `0x${string}`,
    abi: UNISWAP_V2_PAIR_ABI,
    functionName: 'getReserves',
    query: {
      enabled: !!pairAddress && pairAddress !== '0x0000000000000000000000000000000000000000'
    }
  })
}

export function useTokenPrice(tokenA?: Token, tokenB?: Token) {
  const { data: pairAddress } = usePairAddress(tokenA, tokenB)
  const { data: reserves, isLoading: reservesLoading } = usePairReserves(pairAddress as string)
  const { data: token0Address } = useReadContract({
    address: pairAddress as `0x${string}`,
    abi: UNISWAP_V2_PAIR_ABI,
    functionName: 'token0',
    query: {
      enabled: !!pairAddress && pairAddress !== '0x0000000000000000000000000000000000000000'
    }
  })

  if (!tokenA || !tokenB || !pairAddress || !reserves || !token0Address || reservesLoading) {
    return {
      price: null,
      isLoading: reservesLoading,
      pairExists: !!pairAddress && pairAddress !== '0x0000000000000000000000000000000000000000'
    }
  }

  const [reserve0, reserve1] = reserves as [bigint, bigint, number]
  const isToken0 = tokenA.address.toLowerCase() === (token0Address as string).toLowerCase()
  
  let price: number | null = null
  
  if (reserve0 > 0n && reserve1 > 0n) {
    if (isToken0) {
      price = Number(reserve1 * BigInt(10 ** tokenA.decimals)) / Number(reserve0 * BigInt(10 ** tokenB.decimals))
    } else {
      price = Number(reserve0 * BigInt(10 ** tokenA.decimals)) / Number(reserve1 * BigInt(10 ** tokenB.decimals))
    }
  }

  return {
    price,
    isLoading: false,
    pairExists: true,
    reserves: { reserve0, reserve1 },
    isToken0
  }
}

export function calculateAmountOut(
  amountIn: bigint,
  reserveIn: bigint,
  reserveOut: bigint
): bigint {
  if (amountIn === 0n || reserveIn === 0n || reserveOut === 0n) {
    return 0n
  }

  const amountInWithFee = amountIn * 997n
  const numerator = amountInWithFee * reserveOut
  const denominator = reserveIn * 1000n + amountInWithFee
  
  return numerator / denominator
}

export function calculateAmountIn(
  amountOut: bigint,
  reserveIn: bigint,
  reserveOut: bigint
): bigint {
  if (amountOut === 0n || reserveIn === 0n || reserveOut === 0n || amountOut >= reserveOut) {
    return 0n
  }

  const numerator = reserveIn * amountOut * 1000n
  const denominator = (reserveOut - amountOut) * 997n
  
  return numerator / denominator + 1n
}

export function calculatePriceImpact(
  amountIn: bigint,
  reserveIn: bigint,
  reserveOut: bigint
): number {
  if (amountIn === 0n || reserveIn === 0n || reserveOut === 0n) {
    return 0
  }

  const amountOut = calculateAmountOut(amountIn, reserveIn, reserveOut)
  const priceBefore = Number(reserveOut) / Number(reserveIn)
  const priceAfter = Number(reserveOut - amountOut) / Number(reserveIn + amountIn)
  
  return ((priceBefore - priceAfter) / priceBefore) * 100
}