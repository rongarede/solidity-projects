import { createPublicClient, createWalletClient, http } from 'viem'
import { polygon } from 'viem/chains'

export const publicClient = createPublicClient({
  chain: polygon,
  transport: http('https://polygon-rpc.com')
})

export const walletClient = createWalletClient({
  chain: polygon,
  transport: http('https://polygon-rpc.com')
})