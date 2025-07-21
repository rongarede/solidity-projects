import Link from 'next/link'
import { ConnectButton } from '@/components/wallet/ConnectButton'

export default function Home() {
  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <Link href="/" className="text-xl font-bold">Uniswap V2 DApp</Link>
            <nav className="flex items-center gap-6">
              <Link href="/swap" className="text-gray-600 hover:text-gray-900">Swap</Link>
              <Link href="/liquidity" className="text-gray-600 hover:text-gray-900">Liquidity</Link>
              <ConnectButton />
            </nav>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="text-center">
          <h2 className="text-3xl font-bold text-gray-900 mb-4">
            Welcome to Uniswap V2 DApp
          </h2>
          <p className="text-lg text-gray-600 mb-8">
            A decentralized exchange built on Base network
          </p>
          
          <div className="grid md:grid-cols-2 gap-6 max-w-2xl mx-auto mb-8">
            <Link href="/swap" className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
              <div className="text-2xl mb-3">🔄</div>
              <h3 className="text-lg font-semibold mb-2">Swap Tokens</h3>
              <p className="text-gray-600">Exchange tokens instantly with minimal slippage</p>
            </Link>
            
            <Link href="/liquidity" className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
              <div className="text-2xl mb-3">💧</div>
              <h3 className="text-lg font-semibold mb-2">Add Liquidity</h3>
              <p className="text-gray-600">Provide liquidity and earn trading fees</p>
            </Link>
          </div>
          
          <div className="bg-white rounded-lg shadow p-6 max-w-md mx-auto">
            <h3 className="text-lg font-semibold mb-4">Features</h3>
            <ul className="text-left space-y-2">
              <li>• Token Swapping</li>
              <li>• Liquidity Provision</li>
              <li>• Base Network Support</li>
              <li>• MetaMask & Coinbase Wallet</li>
            </ul>
          </div>
        </div>
      </main>
    </div>
  )
}