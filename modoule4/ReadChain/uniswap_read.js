// uniswap_read.js
require('dotenv').config();
const { ethers } = require('ethers');

const INFURA_URL = process.env.INFURA_URL;
// 添加超时设置和备用 RPC 端点
const providerOptions = {
  timeout: 30000, // 30秒超时
  retryDelay: 1000,
  maxRetries: 3
};

// 备用 RPC 端点列表
const rpcUrls = [
  INFURA_URL,
  'https://eth-mainnet.public.blastapi.io',
  'https://ethereum.publicnode.com',
  'https://rpc.ankr.com/eth'
];

let provider;
// 尝试连接到可用的 RPC 端点
async function initProvider() {
  for (const url of rpcUrls) {
    try {
      console.log(`尝试连接到: ${url}`);
      const testProvider = new ethers.JsonRpcProvider(url, null, providerOptions);
      await testProvider.getBlockNumber(); // 测试连接
      provider = testProvider;
      console.log(`成功连接到: ${url}`);
      return;
    } catch (error) {
      console.log(`连接失败: ${url} - ${error.message}`);
    }
  }
  throw new Error('无法连接到任何 RPC 端点');
}

// Uniswap V2 Pair 合约地址（USDC-ETH）主网地址
const pairAddress = "0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc";

// Uniswap V2 Pair ABI（只保留需要的片段）
const pairABI = [
  "function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast)",
  "function token0() external view returns (address)",
  "function token1() external view returns (address)"
];

async function main() {
  try {
    // 首先初始化 provider
    await initProvider();
    
    const pair = new ethers.Contract(pairAddress, pairABI, provider);

    console.log('正在获取 Uniswap V2 Pair 数据...');
    const [reserve0, reserve1] = await pair.getReserves();
    const token0 = await pair.token0();
    const token1 = await pair.token1();

    console.log('\n=== Uniswap V2 Pair 信息 ===');
    console.log(`Token0 (USDC): ${token0}`);
    console.log(`Token1 (WETH): ${token1}`);
    console.log(`Reserve0 (USDC): ${reserve0.toString()}`);
    console.log(`Reserve1 (WETH): ${reserve1.toString()}`);
    
    // 计算价格比率
    // USDC 有 6 位小数，WETH 有 18 位小数
    const reserve0Formatted = Number(reserve0) / (10**6); // USDC
    const reserve1Formatted = Number(reserve1) / (10**18); // WETH
    
    const ethPriceInUsdc = reserve0Formatted / reserve1Formatted;
    
    console.log(`\n=== 格式化储备量 ===`);
    console.log(`USDC 储备: ${reserve0Formatted.toLocaleString()} USDC`);
    console.log(`WETH 储备: ${reserve1Formatted.toLocaleString()} WETH`);
    console.log(`ETH 价格: $${ethPriceInUsdc.toFixed(2)} USDC`);
    
    process.exit(0); // 成功后退出程序
    
  } catch (error) {
    console.error('执行失败:', error.message);
  }
}

main();
