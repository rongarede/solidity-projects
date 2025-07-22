'use client'

import { useAccount, useBalance } from 'wagmi'
import { formatEther } from 'viem'
import { shortenAddress } from '@/lib/utils'

export function WalletInfo() {
  const { address } = useAccount()
  const { data: balance } = useBalance({
    address,
  })

  if (!address) return null

  return (
    <div className="flex items-center gap-3 bg-gray-50 px-3 py-2 rounded-md">
      <div className="text-sm">
        <div className="font-medium">{shortenAddress(address)}</div>
        {balance && (
          <div className="text-gray-600">
            {parseFloat(formatEther(balance.value)).toFixed(4)} MATIC
          </div>
        )}
      </div>
    </div>
  )
}