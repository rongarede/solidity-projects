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
  
  setTokenA: (token: Token) => void
  setTokenB: (token: Token) => void
  setAmountA: (amount: string) => void
  setAmountB: (amount: string) => void
  setSlippage: (slippage: number) => void
  setIsExactIn: (isExactIn: boolean) => void
  swapTokens: () => void
  resetAmounts: () => void
}

export const useSwapStore = create<SwapState>((set, get) => ({
  tokenA: DEFAULT_TOKENS[1], // TTA
  tokenB: DEFAULT_TOKENS[2], // TTB
  amountA: '',
  amountB: '',
  slippage: 0.5,
  isExactIn: true,

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
  
  setSlippage: (slippage) => set({ slippage }),
  
  setIsExactIn: (isExactIn) => set({ isExactIn }),

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

  resetAmounts: () => set({ amountA: '', amountB: '' })
}))