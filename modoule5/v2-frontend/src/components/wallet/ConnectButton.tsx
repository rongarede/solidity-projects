'use client'

import { useConnect, useDisconnect, useAccount } from 'wagmi'
import { useState, useEffect } from 'react'
import { WalletInfo } from './WalletInfo'
import { NetworkSwitcher } from './NetworkSwitcher'

export function ConnectButton() {
  const { connect, connectors, isPending } = useConnect()
  const { disconnect } = useDisconnect()
  const { isConnected } = useAccount()
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
  }, [])

  if (!mounted) {
    return (
      <div className="flex gap-2">
        <button
          disabled
          className="px-4 py-2 bg-gray-300 text-gray-500 rounded-md"
        >
          Loading...
        </button>
      </div>
    )
  }

  if (isConnected) {
    return (
      <div className="flex items-center gap-4">
        <WalletInfo />
        <NetworkSwitcher />
        <button
          onClick={() => disconnect()}
          className="px-4 py-2 bg-red-500 text-white rounded-md hover:bg-red-600 transition-colors"
        >
          Disconnect
        </button>
      </div>
    )
  }

  return (
    <div className="flex gap-2">
      {connectors.map((connector) => (
        <button
          key={connector.uid}
          onClick={() => connect({ connector })}
          disabled={isPending}
          className="px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600 disabled:opacity-50 transition-colors"
        >
          {isPending ? 'Connecting...' : `Connect ${connector.name}`}
        </button>
      ))}
    </div>
  )
}