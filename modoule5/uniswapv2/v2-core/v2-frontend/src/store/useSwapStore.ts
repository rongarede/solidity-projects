import { create } from 'zustand'
import { Token } from '@/types/tokens'
import { DEFAULT_TOKENS } from '@/lib/tokens'

interface SwapState {
  tokenA?: Token
  tokenB?: Token
  amountA: string
  amountB: string
  slippage: number
  isExactIn: boolean
  isSwapping: boolean
  txHash?: string
  priceImpact?: number
  minimumReceived?: string
  
  setTokenA: (token: Token) => void
  setTokenB: (token: Token) => void
  setAmountA: (amount: string) => void
  setAmountB: (amount: string) => void
  setAmountAFromEstimate: (amount: string) => void
  setAmountBFromEstimate: (amount: string) => void
  setSlippage: (slippage: number) => void
  setIsExactIn: (isExactIn: boolean) => void
  setIsSwapping: (isSwapping: boolean) => void
  setTxHash: (txHash?: string) => void
  setPriceImpact: (priceImpact?: number) => void
  setMinimumReceived: (minimumReceived?: string) => void
  swapTokens: () => void
  resetAmounts: () => void
  resetTransaction: () => void
}

export const useSwapStore = create<SwapState>((set, get) => ({
  tokenA: DEFAULT_TOKENS[1], // TTA
  tokenB: DEFAULT_TOKENS[2], // TTB
  amountA: '',
  amountB: '',
  slippage: 0.5,
  isExactIn: true,
  isSwapping: false,
  txHash: undefined,
  priceImpact: undefined,
  minimumReceived: undefined,

  setTokenA: (token) => {
    const { tokenB } = get()
    if (tokenB && token.address === tokenB.address) {
      set({ tokenA: token, tokenB: undefined })
    } else {
      set({ tokenA: token })
    }
  },

  setTokenB: (token) => {
    const { tokenA } = get()
    if (tokenA && token.address === tokenA.address) {
      set({ tokenB: token, tokenA: undefined })
    } else {
      set({ tokenB: token })
    }
  },

  setAmountA: (amount) => set({ amountA: amount, isExactIn: true }),
  
  setAmountB: (amount) => set({ amountB: amount, isExactIn: false }),

  // 专用于自动计算的方法，不改变 isExactIn 状态
  setAmountAFromEstimate: (amount) => set({ amountA: amount }),
  
  setAmountBFromEstimate: (amount) => set({ amountB: amount }),
  
  setSlippage: (slippage) => set({ slippage }),
  
  setIsExactIn: (isExactIn) => set({ isExactIn }),
  
  setIsSwapping: (isSwapping) => set({ isSwapping }),
  
  setTxHash: (txHash) => set({ txHash }),
  
  setPriceImpact: (priceImpact) => set({ priceImpact }),
  
  setMinimumReceived: (minimumReceived) => set({ minimumReceived }),

  swapTokens: () => {
    const { tokenA, tokenB, amountA, amountB } = get()
    set({
      tokenA: tokenB,
      tokenB: tokenA,
      amountA: amountB,
      amountB: amountA,
      isExactIn: !get().isExactIn
    })
  },

  resetAmounts: () => set({ amountA: '', amountB: '' }),
  
  resetTransaction: () => set({ 
    isSwapping: false, 
    txHash: undefined, 
    priceImpact: undefined, 
    minimumReceived: undefined 
  })
}))