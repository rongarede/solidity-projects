import { AddLiquidity } from '@/components/liquidity/AddLiquidity'

export default function LiquidityPage() {
  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Add Liquidity</h1>
          <p className="text-gray-600 mt-2">Provide liquidity to earn fees</p>
        </div>
        
        <AddLiquidity />
      </div>
    </div>
  )
}