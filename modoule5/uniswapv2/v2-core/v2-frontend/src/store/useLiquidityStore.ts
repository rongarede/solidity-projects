import { create } from 'zustand'
import { Token } from '@/types/tokens'
import { DEFAULT_TOKENS } from '@/lib/tokens'
import { logError } from '@/lib/error-logger'

interface LiquidityState {
  tokenA?: Token
  tokenB?: Token
  amountA: string
  amountB: string
  isAdding: boolean
  txHash?: string
  error?: string
  
  setTokenA: (token: Token) => void
  setTokenB: (token: Token) => void
  setAmountA: (amount: string) => void
  setAmountB: (amount: string) => void
  setAmountBFromEstimate: (amount: string) => void
  setIsAdding: (isAdding: boolean) => void
  setTxHash: (txHash?: string) => void
  setError: (error?: string) => void
  resetAmounts: () => void
  resetTransaction: () => void
}

export const useLiquidityStore = create<LiquidityState>((set, get) => ({
  tokenA: DEFAULT_TOKENS[1], // TTA
  tokenB: DEFAULT_TOKENS[2], // TTB
  amountA: '',
  amountB: '',
  isAdding: false,
  txHash: undefined,
  error: undefined,

  setTokenA: (token) => {
    try {
      const { tokenB } = get()
      if (tokenB && token.address === tokenB.address) {
        set({ tokenA: token, tokenB: undefined })
      } else {
        set({ tokenA: token })
      }
    } catch (error) {
      logError({
        errorType: 'ui',
        message: `设置 tokenA 失败: ${error}`,
        context: { token: token.symbol }
      })
    }
  },

  setTokenB: (token) => {
    try {
      const { tokenA } = get()
      if (tokenA && token.address === tokenA.address) {
        set({ tokenB: token, tokenA: undefined })
      } else {
        set({ tokenB: token })
      }
    } catch (error) {
      logError({
        errorType: 'ui',
        message: `设置 tokenB 失败: ${error}`,
        context: { token: token.symbol }
      })
    }
  },

  setAmountA: (amount) => {
    try {
      set({ amountA: amount })
    } catch (error) {
      logError({
        errorType: 'ui',
        message: `设置 amountA 失败: ${error}`,
        context: { amount }
      })
    }
  },

  setAmountB: (amount) => {
    try {
      set({ amountB: amount })
    } catch (error) {
      logError({
        errorType: 'ui',
        message: `设置 amountB 失败: ${error}`,
        context: { amount }
      })
    }
  },

  setAmountBFromEstimate: (amount) => {
    try {
      set({ amountB: amount })
    } catch (error) {
      logError({
        errorType: 'ui',
        message: `从估算设置 amountB 失败: ${error}`,
        context: { amount }
      })
    }
  },

  setIsAdding: (isAdding) => set({ isAdding }),
  
  setTxHash: (txHash) => set({ txHash }),
  
  setError: (error) => {
    set({ error })
    if (error) {
      logError({
        errorType: 'ui',
        message: `流动性错误: ${error}`
      })
    }
  },

  resetAmounts: () => set({ amountA: '', amountB: '' }),
  
  resetTransaction: () => set({ 
    isAdding: false, 
    txHash: undefined, 
    error: undefined 
  })
}))