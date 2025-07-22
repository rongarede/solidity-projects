'use client'

import { useState } from 'react'
import Link from 'next/link'
import { ConnectButton } from '../wallet/ConnectButton'
import { useErrorLogger } from '../../hooks/useErrorLogger'
import { useSafePathname } from '../../hooks/useSafePathname'
import { ClientOnly } from '../ClientOnly'

export function Header() {
  const pathname = useSafePathname()
  const { logUIError } = useErrorLogger()

  const navigation = [
    { name: '交换', href: '/swap', current: pathname === '/swap' },
    { name: '添加流动性', href: '/add-liquidity', current: pathname === '/add-liquidity' },
    { name: '池子', href: '/pools', current: pathname === '/pools' },
  ]

  const handleNavClick = async (navName: string, href: string) => {
    try {
      // 可以在这里添加导航分析或其他逻辑
    } catch (error) {
      await logUIError(`导航到${navName}失败`, {
        targetHref: href,
        currentPath: pathname,
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    }
  }

  return (
    <header className="bg-white shadow-sm border-b border-gray-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          {/* Logo 和品牌标识 */}
          <div className="flex items-center">
            <Link 
              href="/" 
              className="flex items-center space-x-2 hover:opacity-80 transition-opacity"
              onClick={() => handleNavClick('首页', '/')}
            >
              <div className="w-8 h-8 bg-gradient-to-r from-blue-500 to-purple-600 rounded-lg flex items-center justify-center">
                <span className="text-white font-bold text-lg">U</span>
              </div>
              <span className="text-xl font-bold text-gray-900">Uniswap V2</span>
            </Link>
          </div>

          {/* 主导航菜单 */}
          <nav className="hidden md:flex space-x-8">
            {navigation.map((item) => (
              <Link
                key={item.name}
                href={item.href}
                onClick={() => handleNavClick(item.name, item.href)}
                className={`${
                  item.current
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700'
                } inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium transition-colors duration-200`}
              >
                {item.name}
              </Link>
            ))}
          </nav>

          {/* 移动端菜单按钮 */}
          <div className="md:hidden">
            <MobileMenu navigation={navigation} onNavClick={handleNavClick} />
          </div>

          {/* 钱包连接按钮 */}
          <div className="flex items-center space-x-4">
            <ClientOnly fallback={
              <button disabled className="px-4 py-2 bg-gray-300 text-gray-500 rounded-md">
                Loading...
              </button>
            }>
              <ConnectButton />
            </ClientOnly>
          </div>
        </div>
      </div>
    </header>
  )
}

// 移动端菜单组件
function MobileMenu({ 
  navigation, 
  onNavClick 
}: { 
  navigation: Array<{name: string, href: string, current: boolean}>,
  onNavClick: (name: string, href: string) => void
}) {
  const [isOpen, setIsOpen] = useState(false)

  return (
    <div className="relative">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="p-2 rounded-md text-gray-500 hover:text-gray-700 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
      >
        <svg
          className="h-6 w-6"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          {isOpen ? (
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M6 18L18 6M6 6l12 12"
            />
          ) : (
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M4 6h16M4 12h16M4 18h16"
            />
          )}
        </svg>
      </button>

      {isOpen && (
        <div className="absolute right-0 top-full mt-1 w-48 bg-white rounded-md shadow-lg py-1 z-50 border border-gray-200">
          {navigation.map((item) => (
            <Link
              key={item.name}
              href={item.href}
              onClick={() => {
                onNavClick(item.name, item.href)
                setIsOpen(false)
              }}
              className={`${
                item.current
                  ? 'bg-blue-50 text-blue-600'
                  : 'text-gray-700 hover:bg-gray-50'
              } block px-4 py-2 text-sm transition-colors duration-200`}
            >
              {item.name}
            </Link>
          ))}
        </div>
      )}
    </div>
  )
}

