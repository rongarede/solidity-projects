'use client'

import { useState, useMemo, useCallback } from 'react'
import { Token, TokenWithSource, TokenSource } from '@/types/tokens'
import { DEFAULT_TOKENS, isValidAddress, isMockWETH } from '@/lib/tokens'
import { useTokenBalance } from '@/hooks/useTokenBalance'
import { useUserTokens } from '@/hooks/useUserTokens'
import { useErrorLogger } from '@/hooks/useErrorLogger'
import { shortenAddress } from '@/lib/utils'
import { usePublicClient } from 'wagmi'
import { getContract, parseAbi } from 'viem'

interface TokenSelectProps {
  selectedToken?: Token
  onTokenSelect: (token: Token) => void
  excludeToken?: Token
}

type TabType = 'my_tokens' | 'common' | 'custom'

const ERC20_ABI = parseAbi([
  'function symbol() view returns (string)',
  'function name() view returns (string)',
  'function decimals() view returns (uint8)',
])

export function TokenSelect({ selectedToken, onTokenSelect, excludeToken }: TokenSelectProps) {
  const [isOpen, setIsOpen] = useState(false)
  const [activeTab, setActiveTab] = useState<TabType>('my_tokens')
  const [searchQuery, setSearchQuery] = useState('')
  const [customTokenAddress, setCustomTokenAddress] = useState('')
  const [customTokenLoading, setCustomTokenLoading] = useState(false)
  
  const { userTokens, allTokens, loading: userTokensLoading, error: userTokensError } = useUserTokens()
  const { logError } = useErrorLogger()
  const publicClient = usePublicClient()
  const { formattedBalance } = useTokenBalance(selectedToken)

  // Filter tokens based on active tab and search query
  const filteredTokens = useMemo(() => {
    let tokensToFilter: TokenWithSource[] = []

    switch (activeTab) {
      case 'my_tokens':
        tokensToFilter = userTokens
        break
      case 'common':
        tokensToFilter = DEFAULT_TOKENS.map(token => ({
          ...token,
          source: TokenSource.DEFAULT
        }))
        break
      case 'custom':
        return []
    }

    return tokensToFilter.filter(token => {
      if (excludeToken && token.address === excludeToken.address) return false
      if (!searchQuery) return true
      
      const query = searchQuery.toLowerCase()
      return (
        token.symbol.toLowerCase().includes(query) ||
        token.name.toLowerCase().includes(query) ||
        token.address.toLowerCase().includes(query)
      )
    })
  }, [activeTab, userTokens, searchQuery, excludeToken])

  // Handle custom token addition
  const handleAddCustomToken = useCallback(async () => {
    if (!customTokenAddress || !publicClient || !isValidAddress(customTokenAddress)) {
      logError('ui', 'Invalid token address', {
        component: 'TokenSelect',
        address: customTokenAddress,
        type: 'invalid_custom_token_address'
      })
      return
    }

    setCustomTokenLoading(true)

    try {
      const contract = getContract({
        address: customTokenAddress as `0x${string}`,
        abi: ERC20_ABI,
        client: publicClient,
      })

      const [symbol, name, decimals] = await Promise.all([
        contract.read.symbol(),
        contract.read.name(),
        contract.read.decimals(),
      ])

      const customToken: Token = {
        address: customTokenAddress,
        symbol,
        name,
        decimals,
        isNative: false,
      }

      onTokenSelect(customToken)
      setIsOpen(false)
      setCustomTokenAddress('')
      setSearchQuery('')
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error'
      logError('network', `Custom token fetch failed: ${errorMessage}`, {
        component: 'TokenSelect',
        address: customTokenAddress,
        type: 'custom_token_fetch_failed'
      })
    } finally {
      setCustomTokenLoading(false)
    }
  }, [customTokenAddress, publicClient, logError, onTokenSelect])

  // Log token selection errors
  const handleTokenSelect = useCallback((token: Token) => {
    try {
      onTokenSelect(token)
      setIsOpen(false)
      setSearchQuery('')
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error'
      logError('ui', `Token selection failed: ${errorMessage}`, {
        component: 'TokenSelect',
        tokenSymbol: token.symbol,
        tokenAddress: token.address,
        type: 'token_selection_failed'
      })
    }
  }, [onTokenSelect, logError])

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
        <div className="absolute top-full left-0 right-0 mt-1 bg-white border border-gray-200 rounded-lg shadow-lg z-50 max-h-96 overflow-hidden w-80">
          {/* Tab Navigation */}
          <div className="flex border-b">
            <button
              onClick={() => setActiveTab('my_tokens')}
              className={`flex-1 px-4 py-3 text-sm font-medium ${
                activeTab === 'my_tokens'
                  ? 'text-blue-600 border-b-2 border-blue-600'
                  : 'text-gray-500 hover:text-gray-700'
              }`}
            >
              我的代币 ({userTokens.length})
            </button>
            <button
              onClick={() => setActiveTab('common')}
              className={`flex-1 px-4 py-3 text-sm font-medium ${
                activeTab === 'common'
                  ? 'text-blue-600 border-b-2 border-blue-600'
                  : 'text-gray-500 hover:text-gray-700'
              }`}
            >
              常用代币
            </button>
            <button
              onClick={() => setActiveTab('custom')}
              className={`flex-1 px-4 py-3 text-sm font-medium ${
                activeTab === 'custom'
                  ? 'text-blue-600 border-b-2 border-blue-600'
                  : 'text-gray-500 hover:text-gray-700'
              }`}
            >
              自定义
            </button>
          </div>

          {/* Search Input */}
          {activeTab !== 'custom' && (
            <div className="p-3 border-b">
              <input
                type="text"
                placeholder="搜索名称、符号或地址"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          )}

          {/* Custom Token Input */}
          {activeTab === 'custom' && (
            <div className="p-3 border-b">
              <input
                type="text"
                placeholder="输入代币合约地址"
                value={customTokenAddress}
                onChange={(e) => setCustomTokenAddress(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 mb-2"
              />
              <button
                onClick={handleAddCustomToken}
                disabled={!customTokenAddress || customTokenLoading || !isValidAddress(customTokenAddress)}
                className="w-full px-3 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed"
              >
                {customTokenLoading ? '添加中...' : '添加代币'}
              </button>
            </div>
          )}
          
          {/* Token List */}
          <div className="max-h-60 overflow-y-auto">
            {/* Loading State */}
            {activeTab === 'my_tokens' && userTokensLoading && (
              <div className="p-4 text-center text-gray-500">
                <div className="animate-spin w-5 h-5 border-2 border-blue-600 border-t-transparent rounded-full mx-auto mb-2"></div>
                扫描用户代币中...
              </div>
            )}

            {/* Error State */}
            {activeTab === 'my_tokens' && userTokensError && (
              <div className="p-4 text-center text-red-500">
                <div className="text-sm">加载代币失败</div>
                <div className="text-xs text-gray-400 mt-1">{userTokensError}</div>
              </div>
            )}

            {/* Token List */}
            {!userTokensLoading && filteredTokens.map((token) => (
              <TokenOption
                key={token.address}
                token={token}
                onClick={() => handleTokenSelect(token)}
                showSource={activeTab === 'my_tokens'}
              />
            ))}
            
            {/* Empty State */}
            {!userTokensLoading && filteredTokens.length === 0 && (
              <div className="p-4 text-center text-gray-500">
                {activeTab === 'my_tokens' ? '暂无代币' : '未找到匹配的代币'}
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

function TokenOption({ 
  token, 
  onClick, 
  showSource = false 
}: { 
  token: TokenWithSource | Token; 
  onClick: () => void; 
  showSource?: boolean;
}) {
  const { formattedBalance, loading } = useTokenBalance(token)

  const getSourceBadge = (source: TokenSource) => {
    switch (source) {
      case TokenSource.USER_OWNED:
        return <span className="text-xs bg-green-100 text-green-600 px-2 py-1 rounded">持有</span>
      case TokenSource.DEFAULT:
        return <span className="text-xs bg-blue-100 text-blue-600 px-2 py-1 rounded">常用</span>
      case TokenSource.CUSTOM:
        return <span className="text-xs bg-purple-100 text-purple-600 px-2 py-1 rounded">自定义</span>
      default:
        return null
    }
  }

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
          <div className="flex items-center gap-2">
            <span className="font-medium">{token.symbol}</span>
            {isMockWETH(token) && (
              <span className="text-xs bg-orange-100 text-orange-600 px-2 py-1 rounded">ETH包装</span>
            )}
            {showSource && 'source' in token && getSourceBadge(token.source)}
          </div>
          <div className="text-sm text-gray-500">
            {isMockWETH(token) ? 'Wrapped Ether (Mock)' : token.name}
          </div>
          {!token.isNative && (
            <div className="text-xs text-gray-400">{shortenAddress(token.address)}</div>
          )}
        </div>
      </div>
      
      <div className="text-right">
        {loading ? (
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