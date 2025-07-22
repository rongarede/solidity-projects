'use client'

import { PoolsList } from '@/components/pools/PoolsList'
import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'

export default function PoolsPage() {
  const handleRefresh = () => {
    window.location.reload()
  }

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      <Header />
      
      <main className="flex-1 py-8">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-8">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">流动性池</h1>
              <p className="text-gray-600 mt-2">查看所有可用的交易对池子</p>
            </div>
            <div className="mt-4 sm:mt-0">
              <button
                onClick={handleRefresh}
                className="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 transition-colors"
              >
                <svg className="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
                刷新数据
              </button>
            </div>
          </div>
          
          <div className="bg-white rounded-xl shadow-lg">
            <PoolsList />
          </div>
        </div>
      </main>

      <Footer />
    </div>
  )
}