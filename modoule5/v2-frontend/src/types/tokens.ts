export interface Token {
  address: string
  symbol: string
  name: string
  decimals: number
  logoURI?: string
  isNative?: boolean
}

export interface TokenBalance {
  token: Token
  balance: bigint
  formattedBalance: string
}

export interface TokenPair {
  token0: Token
  token1: Token
  pairAddress?: string
}

export interface TokenAllowance {
  owner: string
  spender: string
  allowance: bigint
}