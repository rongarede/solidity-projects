import { http, createConfig } from 'wagmi'
import { polygon } from 'wagmi/chains'
import { metaMask, coinbaseWallet } from 'wagmi/connectors'

export const config = createConfig({
  chains: [polygon],
  connectors: [
    metaMask(),
    coinbaseWallet({ 
      appName: 'Uniswap V2 DApp - Polygon',
      preference: 'smartWalletOnly'
    }),
  ],
  transports: {
    [polygon.id]: http('https://polygon-rpc.com'),
  },
})