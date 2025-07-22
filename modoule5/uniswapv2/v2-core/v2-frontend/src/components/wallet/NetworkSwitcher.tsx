'use client'

import { useSwitchChain, useChainId } from 'wagmi'
import { polygon } from 'wagmi/chains'

export function NetworkSwitcher() {
  const chainId = useChainId()
  const { switchChain, isPending } = useSwitchChain()

  const handleSwitchChain = async () => {
    try {
      await switchChain({ chainId: polygon.id })
    } catch (error) {
      console.error('Failed to switch network:', error)
    }
  }

  if (chainId === polygon.id) {
    return (
      <div className="flex items-center gap-2 px-3 py-1 bg-purple-100 text-purple-800 text-sm rounded-full">
        <div className="w-2 h-2 bg-purple-500 rounded-full"></div>
        Polygon Network
      </div>
    )
  }

  return (
    <button
      onClick={() => handleSwitchChain()}
      disabled={isPending}
      className="px-4 py-2 bg-purple-500 text-white rounded-md hover:bg-purple-600 disabled:opacity-50 transition-colors"
    >
      {isPending ? 'Switching...' : 'Switch to Polygon'}
    </button>
  )
}