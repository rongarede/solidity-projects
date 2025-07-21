import { http, createConfig } from 'wagmi'
import { base } from 'wagmi/chains'
import { metaMask, coinbaseWallet } from 'wagmi/connectors'

export const config = createConfig({
  chains: [base],
  connectors: [
    metaMask(),
    coinbaseWallet({ appName: 'Uniswap V2 DApp' }),
  ],
  transports: {
    [base.id]: http(),
  },
})