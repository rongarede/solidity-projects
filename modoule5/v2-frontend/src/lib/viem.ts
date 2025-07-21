import { createPublicClient, createWalletClient, http } from 'viem'
import { base } from 'viem/chains'

export const publicClient = createPublicClient({
  chain: base,
  transport: http()
})

export const walletClient = createWalletClient({
  chain: base,
  transport: http()
})