import { create } from 'zustand'
import { Token } from '@/types/tokens'
import { DEFAULT_TOKENS } from '@/lib/tokens'

interface LiquidityState {
  tokenA?: Token
  tokenB?: Token
  amountA: string
  amountB: string
  
  setTokenA: (token: Token) => void
  setTokenB: (token: Token) => void
  setAmountA: (amount: string) => void
  setAmountB: (amount: string) => void
  resetAmounts: () => void
}

export const useLiquidityStore = create<LiquidityState>((set, get) => ({
  tokenA: DEFAULT_TOKENS[1], // TTA
  tokenB: DEFAULT_TOKENS[2], // TTB
  amountA: '',
  amountB: '',

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

  setAmountA: (amount) => set({ amountA: amount }),
  setAmountB: (amount) => set({ amountB: amount }),
  resetAmounts: () => set({ amountA: '', amountB: '' })
}))