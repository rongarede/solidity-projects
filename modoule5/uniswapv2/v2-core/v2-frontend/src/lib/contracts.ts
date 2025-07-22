import { parseAbi } from 'viem'

export const CONTRACTS = {
  UniswapV2Factory: {
    address: '0xAd359064D6315e30045D24dCBd41A078Fc8DfacC' as const,
    abi: parseAbi([
      'function createPair(address tokenA, address tokenB) external returns (address pair)',
      'function getPair(address tokenA, address tokenB) external view returns (address pair)',
      'function allPairs(uint) external view returns (address pair)',
      'function allPairsLength() external view returns (uint)',
      'function feeTo() external view returns (address)',
      'function feeToSetter() external view returns (address)',
      'function setFeeTo(address) external',
      'function setFeeToSetter(address) external',
      'event PairCreated(address indexed token0, address indexed token1, address pair, uint)'
    ])
  },
  UniswapV2Router02: {
    address: '0x3ebaF23B04ee529EA55f67ea934699185Dd91D25' as const,
    abi: parseAbi([
      'function factory() external view returns (address)',
      'function WETH() external view returns (address)',
      'function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity)',
      'function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity)',
      'function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB)',
      'function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountToken, uint amountETH)',
      'function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts)',
      'function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts)',
      'function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts)',
      'function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts)',
      'function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts)',
      'function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts)',
      'function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts)',
      'function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts)'
    ])
  },
  MockWETH: {
    address: '0xaEC13518815Fb88ad241dC945e00dAe350c426Db' as const,
    abi: parseAbi([
      'function name() external view returns (string memory)',
      'function symbol() external view returns (string memory)',
      'function decimals() external view returns (uint8)',
      'function totalSupply() external view returns (uint256)',
      'function balanceOf(address account) external view returns (uint256)',
      'function transfer(address to, uint256 amount) external returns (bool)',
      'function allowance(address owner, address spender) external view returns (uint256)',
      'function approve(address spender, uint256 amount) external returns (bool)',
      'function transferFrom(address from, address to, uint256 amount) external returns (bool)',
      'function deposit() external payable',
      'function withdraw(uint256 wad) external',
      'event Transfer(address indexed from, address indexed to, uint256 value)',
      'event Approval(address indexed owner, address indexed spender, uint256 value)',
      'event Deposit(address indexed dst, uint256 wad)',
      'event Withdrawal(address indexed src, uint256 wad)'
    ])
  }
} as const

// Backward compatibility alias - WETH points to MockWETH
export const WETH_CONTRACT = CONTRACTS.MockWETH

export const UNISWAP_V2_PAIR_ABI = parseAbi([
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
])

export const POLYGON_CHAIN_ID = 137