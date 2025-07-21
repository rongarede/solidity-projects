'use client'

import { useSwitchChain, useChainId } from 'wagmi'
import { base } from 'wagmi/chains'

export function NetworkSwitcher() {
  const chainId = useChainId()
  const { switchChain, isPending } = useSwitchChain()

  const handleSwitchChain = async () => {
    try {
      await switchChain({ chainId: base.id })
    } catch (error) {
      console.error('Failed to switch network:', error)
    }
  }

  if (chainId === base.id) {
    return (
      <div className="flex items-center gap-2 px-3 py-1 bg-green-100 text-green-800 text-sm rounded-full">
        <div className="w-2 h-2 bg-green-500 rounded-full"></div>
        Base Network
      </div>
    )
  }

  return (
    <button
      onClick={() => handleSwitchChain()}
      disabled={isPending}
      className="px-4 py-2 bg-orange-500 text-white rounded-md hover:bg-orange-600 disabled:opacity-50 transition-colors"
    >
      {isPending ? 'Switching...' : 'Switch to Base'}
    </button>
  )
}