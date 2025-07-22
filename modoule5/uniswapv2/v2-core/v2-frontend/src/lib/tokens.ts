import { Token } from '@/types/tokens'
import { parseAbi } from 'viem'

export const NATIVE_TOKEN: Token = {
  address: '0x0000000000000000000000000000000000000000',
  symbol: 'MATIC',
  name: 'Polygon',
  decimals: 18,
  isNative: true
}

export const MOCKWETH_TOKEN: Token = {
  address: '0xaEC13518815Fb88ad241dC945e00dAe350c426Db',
  symbol: 'WETH',
  name: 'Wrapped Ether (Mock)',
  decimals: 18,
  isMockWETH: true
}

// Backward compatibility alias
export const WETH_TOKEN = MOCKWETH_TOKEN

export const DEFAULT_TOKENS: Token[] = [
  NATIVE_TOKEN,
  MOCKWETH_TOKEN,
  {
    address: '0xcB76bF429B49397363c36123DF9c2F93627e4f92',
    symbol: 'TTA',
    name: 'Test Token A',
    decimals: 18
  },
  {
    address: '0x7822811bF7b966611aD456F285298f9b4cda053b',
    symbol: 'TTB',
    name: 'Test Token B', 
    decimals: 18
  }
]

export const ERC20_ABI = parseAbi([
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
])

export function getTokenByAddress(address: string): Token | undefined {
  return DEFAULT_TOKENS.find(token => 
    token.address.toLowerCase() === address.toLowerCase()
  )
}

export function isNativeToken(token: Token): boolean {
  return token.isNative === true || token.address === '0x0000000000000000000000000000000000000000'
}

export function isMockWETH(token: Token): boolean {
  return token.isMockWETH === true || token.address.toLowerCase() === MOCKWETH_TOKEN.address.toLowerCase()
}

export function isValidAddress(address: string): boolean {
  if (!address || typeof address !== 'string') return false
  
  // Basic Ethereum address validation
  const addressRegex = /^0x[a-fA-F0-9]{40}$/
  return addressRegex.test(address)
}