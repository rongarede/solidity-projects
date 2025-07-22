import { useState, useEffect, useCallback } from 'react'
import { useReadContract, usePublicClient } from 'wagmi'
import { CONTRACTS, UNISWAP_V2_PAIR_ABI } from '@/lib/contracts'
import { ERC20_ABI } from '@/lib/tokens'
import { logError } from '@/lib/error-logger'

export interface Pool {
  address: string
  token0: string
  token1: string
  token0Symbol?: string
  token1Symbol?: string
  reserves?: {
    reserve0: bigint
    reserve1: bigint
  }
  totalSupply?: bigint
}

export function useAllPools() {
  const [pools, setPools] = useState<Pool[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  
  const publicClient = usePublicClient()

  // 获取池子总数
  const { data: totalPairs, isLoading: totalLoading } = useReadContract({
    address: CONTRACTS.UniswapV2Factory.address,
    abi: CONTRACTS.UniswapV2Factory.abi,
    functionName: 'allPairsLength',
  })

  const fetchAllPools = useCallback(async () => {
    if (!totalPairs || !publicClient || totalPairs === 0n) {
      setPools([])
      return
    }

    setLoading(true)
    setError(null)

    try {
      const totalPairsNumber = Number(totalPairs)
      const poolPromises: Promise<Pool>[] = []

      // 批量获取所有池子地址
      for (let i = 0; i < totalPairsNumber; i++) {
        const poolPromise = publicClient.readContract({
          address: CONTRACTS.UniswapV2Factory.address,
          abi: CONTRACTS.UniswapV2Factory.abi,
          functionName: 'allPairs',
          args: [BigInt(i)]
        }).then(async (pairAddress: unknown) => {
          const address = pairAddress as string
          
          try {
            // 获取该池子的基本信息
            const [token0, token1, reserves, totalSupply] = await Promise.all([
              publicClient.readContract({
                address: address as `0x${string}`,
                abi: UNISWAP_V2_PAIR_ABI,
                functionName: 'token0'
              }),
              publicClient.readContract({
                address: address as `0x${string}`,
                abi: UNISWAP_V2_PAIR_ABI,
                functionName: 'token1'
              }),
              publicClient.readContract({
                address: address as `0x${string}`,
                abi: UNISWAP_V2_PAIR_ABI,
                functionName: 'getReserves'
              }),
              publicClient.readContract({
                address: address as `0x${string}`,
                abi: UNISWAP_V2_PAIR_ABI,
                functionName: 'totalSupply'
              })
            ])

            // 尝试获取代币符号（可能失败，所以使用单独的try-catch）
            let token0Symbol = 'Unknown'
            let token1Symbol = 'Unknown'
            
            try {
              const [sym0, sym1] = await Promise.all([
                publicClient.readContract({
                  address: token0 as `0x${string}`,
                  abi: ERC20_ABI,
                  functionName: 'symbol'
                }),
                publicClient.readContract({
                  address: token1 as `0x${string}`,
                  abi: ERC20_ABI,
                  functionName: 'symbol'
                })
              ])
              token0Symbol = sym0 as string
              token1Symbol = sym1 as string
            } catch (symbolError) {
              // 符号获取失败，使用默认值
              console.warn(`Failed to get token symbols for pair ${address}:`, symbolError)
            }

            const reservesArray = reserves as [bigint, bigint, number]
            
            return {
              address,
              token0: token0 as string,
              token1: token1 as string,
              token0Symbol,
              token1Symbol,
              reserves: {
                reserve0: reservesArray[0],
                reserve1: reservesArray[1]
              },
              totalSupply: totalSupply as bigint
            }
          } catch (pairError) {
            console.warn(`Failed to get full data for pair ${address}:`, pairError)
            // 如果详细信息获取失败，至少返回基本信息
            const [token0, token1] = await Promise.all([
              publicClient.readContract({
                address: address as `0x${string}`,
                abi: UNISWAP_V2_PAIR_ABI,
                functionName: 'token0'
              }),
              publicClient.readContract({
                address: address as `0x${string}`,
                abi: UNISWAP_V2_PAIR_ABI,
                functionName: 'token1'
              })
            ])

            return {
              address,
              token0: token0 as string,
              token1: token1 as string
            }
          }
        })

        poolPromises.push(poolPromise)
      }

      // 等待所有池子信息加载完成
      const allPools = await Promise.all(poolPromises)
      setPools(allPools)

    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : '获取池子数据失败'
      setError(errorMessage)
      logError({
        errorType: 'network',
        message: `获取所有池子失败: ${errorMessage}`,
        context: {
          totalPairs: totalPairs?.toString(),
          component: 'useAllPools'
        }
      })
      console.error('Error fetching pools:', err)
    } finally {
      setLoading(false)
    }
  }, [totalPairs, publicClient])

  useEffect(() => {
    if (totalPairs !== undefined && !totalLoading) {
      fetchAllPools()
    }
  }, [totalPairs, totalLoading, fetchAllPools])

  return {
    pools,
    loading: loading || totalLoading,
    error,
    refetch: fetchAllPools,
    totalPairs: totalPairs ? Number(totalPairs) : 0
  }
}