import { Token } from '@/types/tokens'

export const NATIVE_TOKEN: Token = {
  address: '0x0000000000000000000000000000000000000000',
  symbol: 'ETH',
  name: 'Ethereum',
  decimals: 18,
  isNative: true
}

export const DEFAULT_TOKENS: Token[] = [
  NATIVE_TOKEN,
  {
    address: '0xd94b67a5e56696B57908c571eD1E5A40Ce3f64F3',
    symbol: 'TTA',
    name: 'Test Token A',
    decimals: 18
  },
  {
    address: '0x731495EAb495076B86CA562eDa51244F20A25CF5',
    symbol: 'TTB',
    name: 'Test Token B', 
    decimals: 18
  }
]

export const ERC20_ABI = [
  'function name() view returns (string)',
  'function symbol() view returns (string)',
  'function decimals() view returns (uint8)',
  'function totalSupply() view returns (uint256)',
  'function balanceOf(address owner) view returns (uint256)',
  'function allowance(address owner, address spender) view returns (uint256)',
  'function transfer(address to, uint256 amount) returns (bool)',
  'function approve(address spender, uint256 amount) returns (bool)',
  'function transferFrom(address from, address to, uint256 amount) returns (bool)',
  'event Transfer(address indexed from, address indexed to, uint256 value)',
  'event Approval(address indexed owner, address indexed spender, uint256 value)'
] as const

export function getTokenByAddress(address: string): Token | undefined {
  return DEFAULT_TOKENS.find(token => 
    token.address.toLowerCase() === address.toLowerCase()
  )
}

export function isNativeToken(token: Token): boolean {
  return token.isNative === true || token.address === '0x0000000000000000000000000000000000000000'
}