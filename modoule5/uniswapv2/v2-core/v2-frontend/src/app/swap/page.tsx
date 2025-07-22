import { SwapCard } from '@/components/swap/SwapCard'
import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'

export default function SwapPage() {
  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      <Header />
      
      <main className="flex-1 py-8">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-8">
            <h1 className="text-3xl font-bold text-gray-900">代币交换</h1>
            <p className="text-gray-600 mt-2">在 Base 网络上交换代币</p>
          </div>
          
          <div className="flex justify-center">
            <SwapCard />
          </div>
        </div>
      </main>

      <Footer />
    </div>
  )
}