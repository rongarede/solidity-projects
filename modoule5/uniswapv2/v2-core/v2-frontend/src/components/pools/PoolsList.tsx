'use client'

import { useAllPools } from '@/hooks/useAllPools'
import { shortenAddress, formatTokenAmount } from '@/lib/utils'
import { ClientOnly } from '../ClientOnly'

export function PoolsList() {
  const { pools, loading, error, totalPairs, refetch } = useAllPools()

  // 计算统计信息
  const poolsWithReserves = pools.filter(pool => pool.reserves)
  const totalReservePools = poolsWithReserves.length
  const totalLPPools = pools.filter(pool => pool.totalSupply && pool.totalSupply > 0n).length

  if (loading) {
    return (
      <div className="p-8 text-center">
        <div className="animate-spin w-8 h-8 border-2 border-blue-600 border-t-transparent rounded-full mx-auto mb-4"></div>
        <p className="text-gray-600">加载池子数据中...</p>
      </div>
    )
  }

  if (error) {
    return (
      <div className="p-8 text-center">
        <div className="text-red-500 mb-4">❌ 加载失败</div>
        <p className="text-gray-600">{error}</p>
      </div>
    )
  }

  if (pools.length === 0) {
    return (
      <div className="p-8 text-center">
        <div className="text-gray-400 mb-4">🏊‍♂️</div>
        <p className="text-gray-600">暂无流动性池</p>
      </div>
    )
  }

  return (
    <ClientOnly>
      {/* 统计信息卡片 */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 p-6 bg-gray-50 border-b">
        <div className="text-center">
          <div className="text-2xl font-bold text-blue-600">{totalPairs}</div>
          <div className="text-sm text-gray-600">总池子数</div>
        </div>
        <div className="text-center">
          <div className="text-2xl font-bold text-green-600">{pools.length}</div>
          <div className="text-sm text-gray-600">已加载</div>
        </div>
        <div className="text-center">
          <div className="text-2xl font-bold text-purple-600">{totalReservePools}</div>
          <div className="text-sm text-gray-600">有储备量</div>
        </div>
        <div className="text-center">
          <div className="text-2xl font-bold text-orange-600">{totalLPPools}</div>
          <div className="text-sm text-gray-600">有流动性</div>
        </div>
      </div>

      {/* 桌面端表格视图 */}
      <div className="hidden lg:block overflow-x-auto">
        <table className="w-full">
          <thead className="bg-gray-50 border-b">
            <tr>
              <th className="text-left py-4 px-6 font-semibold text-gray-900">#</th>
              <th className="text-left py-4 px-6 font-semibold text-gray-900">交易对</th>
              <th className="text-left py-4 px-6 font-semibold text-gray-900">池子地址</th>
              <th className="text-left py-4 px-6 font-semibold text-gray-900">储备量</th>
              <th className="text-left py-4 px-6 font-semibold text-gray-900">LP总量</th>
              <th className="text-left py-4 px-6 font-semibold text-gray-900">状态</th>
            </tr>
          </thead>
          <tbody>
            {pools.map((pool, index) => (
              <tr key={pool.address} className="border-b hover:bg-gray-50 transition-colors">
                <td className="py-4 px-6 text-gray-900 font-medium">
                  {index + 1}
                </td>
                <td className="py-4 px-6">
                  <div className="flex items-center space-x-2">
                    <span className="font-semibold text-gray-900">
                      {pool.token0Symbol || 'Token0'}
                    </span>
                    <span className="text-gray-400">/</span>
                    <span className="font-semibold text-gray-900">
                      {pool.token1Symbol || 'Token1'}
                    </span>
                  </div>
                  <div className="text-xs text-gray-500 mt-1">
                    {shortenAddress(pool.token0)} / {shortenAddress(pool.token1)}
                  </div>
                </td>
                <td className="py-4 px-6">
                  <div className="font-mono text-sm">
                    <a 
                      href={`https://basescan.org/address/${pool.address}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-blue-600 hover:text-blue-800 hover:underline"
                    >
                      {shortenAddress(pool.address)}
                    </a>
                  </div>
                </td>
                <td className="py-4 px-6">
                  {pool.reserves ? (
                    <div className="text-sm">
                      <div className="text-gray-900">
                        {formatTokenAmount(pool.reserves.reserve0, 18).slice(0, 8)} {pool.token0Symbol}
                      </div>
                      <div className="text-gray-500">
                        {formatTokenAmount(pool.reserves.reserve1, 18).slice(0, 8)} {pool.token1Symbol}
                      </div>
                    </div>
                  ) : (
                    <span className="text-gray-400">-</span>
                  )}
                </td>
                <td className="py-4 px-6">
                  {pool.totalSupply ? (
                    <div className="text-sm text-gray-900">
                      {formatTokenAmount(pool.totalSupply, 18).slice(0, 8)} LP
                    </div>
                  ) : (
                    <span className="text-gray-400">-</span>
                  )}
                </td>
                <td className="py-4 px-6">
                  <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                    活跃
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* 移动端卡片视图 */}
      <div className="lg:hidden">
        {pools.map((pool, index) => (
          <div key={pool.address} className="border-b last:border-b-0 p-4 hover:bg-gray-50 transition-colors">
            <div className="flex items-start justify-between mb-3">
              <div className="flex-1">
                <div className="flex items-center space-x-2 mb-1">
                  <span className="text-sm font-medium text-gray-500">#{index + 1}</span>
                  <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                    活跃
                  </span>
                </div>
                <div className="flex items-center space-x-2">
                  <span className="font-semibold text-gray-900">
                    {pool.token0Symbol || 'Token0'}
                  </span>
                  <span className="text-gray-400">/</span>
                  <span className="font-semibold text-gray-900">
                    {pool.token1Symbol || 'Token1'}
                  </span>
                </div>
              </div>
            </div>
            
            <div className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-gray-500">池子地址:</span>
                <a 
                  href={`https://basescan.org/address/${pool.address}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="font-mono text-blue-600 hover:text-blue-800 hover:underline"
                >
                  {shortenAddress(pool.address)}
                </a>
              </div>
              
              {pool.reserves && (
                <div className="flex justify-between">
                  <span className="text-gray-500">储备量:</span>
                  <div className="text-right">
                    <div className="text-gray-900">
                      {formatTokenAmount(pool.reserves.reserve0, 18).slice(0, 8)} {pool.token0Symbol}
                    </div>
                    <div className="text-gray-500">
                      {formatTokenAmount(pool.reserves.reserve1, 18).slice(0, 8)} {pool.token1Symbol}
                    </div>
                  </div>
                </div>
              )}
              
              {pool.totalSupply && (
                <div className="flex justify-between">
                  <span className="text-gray-500">LP总量:</span>
                  <span className="text-gray-900">
                    {formatTokenAmount(pool.totalSupply, 18).slice(0, 8)} LP
                  </span>
                </div>
              )}
              
              <div className="flex justify-between">
                <span className="text-gray-500">代币地址:</span>
                <div className="text-right font-mono text-xs">
                  <div className="text-gray-600">{shortenAddress(pool.token0)}</div>
                  <div className="text-gray-600">{shortenAddress(pool.token1)}</div>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
      
      <div className="p-6 border-t bg-gray-50 text-center">
        <p className="text-sm text-gray-600">
          共找到 <span className="font-semibold">{pools.length}</span> 个流动性池
        </p>
      </div>
    </ClientOnly>
  )
}