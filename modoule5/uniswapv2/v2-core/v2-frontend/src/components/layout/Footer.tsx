'use client'

import Link from 'next/link'

export function Footer() {
  // 使用固定年份避免水合错误
  const currentYear = 2025

  const footerLinks = {
    protocol: [
      { name: '关于协议', href: '#' },
      { name: '文档', href: '#' },
      { name: '白皮书', href: '#' },
    ],
    community: [
      { name: 'GitHub', href: '#' },
      { name: 'Discord', href: '#' },
      { name: 'Twitter', href: '#' },
    ],
    developers: [
      { name: 'API 文档', href: '#' },
      { name: '智能合约', href: '#' },
      { name: '安全审计', href: '#' },
    ]
  }

  return (
    <footer className="bg-gray-50 border-t border-gray-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {/* 品牌信息 */}
          <div className="col-span-1 md:col-span-1">
            <div className="flex items-center space-x-2 mb-4">
              <div className="w-8 h-8 bg-gradient-to-r from-blue-500 to-purple-600 rounded-lg flex items-center justify-center">
                <span className="text-white font-bold text-lg">U</span>
              </div>
              <span className="text-xl font-bold text-gray-900">Uniswap V2</span>
            </div>
            <p className="text-gray-600 text-sm leading-6">
              基于 Uniswap V2 协议构建的去中心化交易所，为用户提供安全、高效的代币交换和流动性挖矿服务。
            </p>
          </div>

          {/* 协议链接 */}
          <div>
            <h3 className="text-sm font-semibold text-gray-900 tracking-wider uppercase mb-4">
              协议
            </h3>
            <ul className="space-y-2">
              {footerLinks.protocol.map((link) => (
                <li key={link.name}>
                  <Link
                    href={link.href}
                    className="text-gray-600 hover:text-gray-900 text-sm transition-colors duration-200"
                  >
                    {link.name}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* 社区链接 */}
          <div>
            <h3 className="text-sm font-semibold text-gray-900 tracking-wider uppercase mb-4">
              社区
            </h3>
            <ul className="space-y-2">
              {footerLinks.community.map((link) => (
                <li key={link.name}>
                  <Link
                    href={link.href}
                    className="text-gray-600 hover:text-gray-900 text-sm transition-colors duration-200"
                  >
                    {link.name}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* 开发者链接 */}
          <div>
            <h3 className="text-sm font-semibold text-gray-900 tracking-wider uppercase mb-4">
              开发者
            </h3>
            <ul className="space-y-2">
              {footerLinks.developers.map((link) => (
                <li key={link.name}>
                  <Link
                    href={link.href}
                    className="text-gray-600 hover:text-gray-900 text-sm transition-colors duration-200"
                  >
                    {link.name}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        </div>

        {/* 分隔线和版权信息 */}
        <div className="mt-8 pt-8 border-t border-gray-200">
          <div className="flex flex-col md:flex-row justify-between items-center">
            <p className="text-gray-500 text-sm">
              © {currentYear} Uniswap V2 DApp. 保留所有权利。
            </p>
            <div className="flex space-x-6 mt-4 md:mt-0">
              <Link
                href="#"
                className="text-gray-500 hover:text-gray-900 text-sm transition-colors duration-200"
              >
                隐私政策
              </Link>
              <Link
                href="#"
                className="text-gray-500 hover:text-gray-900 text-sm transition-colors duration-200"
              >
                使用条款
              </Link>
              <Link
                href="#"
                className="text-gray-500 hover:text-gray-900 text-sm transition-colors duration-200"
              >
                风险提示
              </Link>
            </div>
          </div>
        </div>

        {/* 风险提示 */}
        <div className="mt-6 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
          <p className="text-yellow-800 text-xs leading-5">
            <span className="font-semibold">风险提示：</span>
            数字资产交易存在极高风险，可能导致部分或全部资金损失。请在充分了解风险的情况下谨慎投资，本平台不承担任何投资损失责任。
          </p>
        </div>
      </div>
    </footer>
  )
}