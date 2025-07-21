'use client'

import { useState } from 'react'
import { Token } from '@/types/tokens'
import { DEFAULT_TOKENS } from '@/lib/tokens'
import { useTokenBalance } from '@/hooks/useTokenBalance'
import { shortenAddress } from '@/lib/utils'

interface TokenSelectProps {
  selectedToken?: Token
  onTokenSelect: (token: Token) => void
  excludeToken?: Token
}

export function TokenSelect({ selectedToken, onTokenSelect, excludeToken }: TokenSelectProps) {
  const [isOpen, setIsOpen] = useState(false)
  const [searchQuery, setSearchQuery] = useState('')
  
  const { formattedBalance } = useTokenBalance(selectedToken)

  const filteredTokens = DEFAULT_TOKENS.filter(token => {
    if (excludeToken && token.address === excludeToken.address) return false
    if (!searchQuery) return true
    
    const query = searchQuery.toLowerCase()
    return (
      token.symbol.toLowerCase().includes(query) ||
      token.name.toLowerCase().includes(query) ||
      token.address.toLowerCase().includes(query)
    )
  })

  return (
    <div className="relative">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 px-4 py-2 bg-white border border-gray-300 rounded-lg hover:border-gray-400 transition-colors min-w-[140px]"
      >
        {selectedToken ? (
          <>
            <div className="w-6 h-6 bg-gray-200 rounded-full flex items-center justify-center text-xs font-medium">
              {selectedToken.symbol.slice(0, 2)}
            </div>
            <span className="font-medium">{selectedToken.symbol}</span>
          </>
        ) : (
          <span className="text-gray-500">Select Token</span>
        )}
        <svg className="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>

      {isOpen && (
        <div className="absolute top-full left-0 right-0 mt-1 bg-white border border-gray-200 rounded-lg shadow-lg z-50 max-h-80 overflow-hidden">
          <div className="p-3 border-b">
            <input
              type="text"
              placeholder="Search name or paste address"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          
          <div className="max-h-60 overflow-y-auto">
            {filteredTokens.map((token) => (
              <TokenOption
                key={token.address}
                token={token}
                onClick={() => {
                  onTokenSelect(token)
                  setIsOpen(false)
                  setSearchQuery('')
                }}
              />
            ))}
            
            {filteredTokens.length === 0 && (
              <div className="p-4 text-center text-gray-500">
                No tokens found
              </div>
            )}
          </div>
        </div>
      )}

      {isOpen && (
        <div 
          className="fixed inset-0 z-40" 
          onClick={() => setIsOpen(false)}
        />
      )}
    </div>
  )
}

function TokenOption({ token, onClick }: { token: Token; onClick: () => void }) {
  const { formattedBalance, isLoading } = useTokenBalance(token)

  return (
    <button
      onClick={onClick}
      className="w-full flex items-center justify-between p-3 hover:bg-gray-50 transition-colors"
    >
      <div className="flex items-center gap-3">
        <div className="w-8 h-8 bg-gray-200 rounded-full flex items-center justify-center text-sm font-medium">
          {token.symbol.slice(0, 2)}
        </div>
        <div className="text-left">
          <div className="font-medium">{token.symbol}</div>
          <div className="text-sm text-gray-500">{token.name}</div>
          {!token.isNative && (
            <div className="text-xs text-gray-400">{shortenAddress(token.address)}</div>
          )}
        </div>
      </div>
      
      <div className="text-right">
        {isLoading ? (
          <div className="text-sm text-gray-400">Loading...</div>
        ) : (
          <div className="text-sm font-medium">
            {parseFloat(formattedBalance).toFixed(4)}
          </div>
        )}
      </div>
    </button>
  )
}