export const CONTRACTS = {
  UniswapV2Factory: {
    address: '0x2E2812638232c64eeC81B4a2DFd4ca975887d571' as const,
    abi: [
      'function createPair(address tokenA, address tokenB) external returns (address pair)',
      'function getPair(address tokenA, address tokenB) external view returns (address pair)',
      'function allPairs(uint) external view returns (address pair)',
      'function allPairsLength() external view returns (uint)',
      'function feeTo() external view returns (address)',
      'function feeToSetter() external view returns (address)',
      'function setFeeTo(address) external',
      'function setFeeToSetter(address) external',
      'event PairCreated(address indexed token0, address indexed token1, address pair, uint)'
    ]
  }
} as const

export const UNISWAP_V2_PAIR_ABI = [
  'function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast)',
  'function token0() external view returns (address)',
  'function token1() external view returns (address)',
  'function totalSupply() external view returns (uint256)',
  'function balanceOf(address owner) external view returns (uint256)',
  'function mint(address to) external returns (uint256 liquidity)',
  'function burn(address to) external returns (uint256 amount0, uint256 amount1)',
  'function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external',
  'event Mint(address indexed sender, uint256 amount0, uint256 amount1)',
  'event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to)',
  'event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to)'
] as const

export const BASE_CHAIN_ID = 8453