import { createPublicClient, http, formatEther, formatUnits, getContract } from 'viem';
import { base } from 'viem/chains';
import dotenv from 'dotenv';

// 加载环境变量
dotenv.config();

/**
 * ERC20 代币标准 ABI（仅包含余额查询所需的函数）
 */
const ERC20_ABI = [
  {
    inputs: [{ name: 'account', type: 'address' }],
    name: 'balanceOf',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function'
  },
  {
    inputs: [],
    name: 'decimals',
    outputs: [{ name: '', type: 'uint8' }],
    stateMutability: 'view',
    type: 'function'
  },
  {
    inputs: [],
    name: 'symbol',
    outputs: [{ name: '', type: 'string' }],
    stateMutability: 'view',
    type: 'function'
  },
  {
    inputs: [],
    name: 'name',
    outputs: [{ name: '', type: 'string' }],
    stateMutability: 'view',
    type: 'function'
  }
] as const;

/**
 * 创建公共客户端用于查询区块链数据
 */
function createClient() {
  const rpcUrl = process.env.RPC_URL;
  if (!rpcUrl) {
    throw new Error('请在 .env 文件中设置 RPC_URL');
  }

  return createPublicClient({
    chain: base,
    transport: http(rpcUrl)
  });
}

/**
 * 查询ETH余额
 * @param address 钱包地址
 * @returns ETH余额（以 ETH 为单位的字符串）
 */
export async function getETHBalance(address: string): Promise<string> {
  try {
    console.log(`💰 正在查询地址 ${address} 的 ETH 余额...`);
    
    const client = createClient();
    
    // 查询余额（返回 wei 单位）
    const balance = await client.getBalance({
      address: address as `0x${string}`
    });
    
    // 将 wei 转换为 ETH
    const ethBalance = formatEther(balance);
    
    console.log(`✅ ETH 余额: ${ethBalance} ETH`);
    
    return ethBalance;
  } catch (error) {
    console.error('❌ 查询 ETH 余额失败:', error);
    throw error;
  }
}

/**
 * ERC20 代币信息接口
 */
export interface TokenInfo {
  name: string;
  symbol: string;
  decimals: number;
  balance: string;
  balanceFormatted: string;
}

/**
 * 查询ERC20代币余额
 * @param address 钱包地址
 * @param tokenAddress ERC20代币合约地址
 * @returns 代币信息和余额
 */
export async function getERC20Balance(address: string, tokenAddress: string): Promise<TokenInfo> {
  try {
    console.log(`🪙 正在查询地址 ${address} 的代币余额...`);
    console.log(`代币合约: ${tokenAddress}`);
    
    const client = createClient();
    
    // 创建代币合约实例
    const tokenContract = getContract({
      address: tokenAddress as `0x${string}`,
      abi: ERC20_ABI,
      client
    });
    
    // 并行查询代币信息和余额
    const [name, symbol, decimals, balance] = await Promise.all([
      tokenContract.read.name(),
      tokenContract.read.symbol(),
      tokenContract.read.decimals(),
      tokenContract.read.balanceOf([address as `0x${string}`])
    ]);
    
    // 格式化余额
    const balanceFormatted = formatUnits(balance, decimals);
    
    const tokenInfo: TokenInfo = {
      name: name as string,
      symbol: symbol as string,
      decimals: decimals as number,
      balance: balance.toString(),
      balanceFormatted
    };
    
    console.log(`✅ 代币信息:`);
    console.log(`   名称: ${tokenInfo.name}`);
    console.log(`   符号: ${tokenInfo.symbol}`);
    console.log(`   精度: ${tokenInfo.decimals}`);
    console.log(`   余额: ${tokenInfo.balanceFormatted} ${tokenInfo.symbol}`);
    
    return tokenInfo;
  } catch (error) {
    console.error('❌ 查询 ERC20 代币余额失败:', error);
    throw error;
  }
}

/**
 * 查询钱包的完整余额信息（ETH + 指定的ERC20代币）
 * @param address 钱包地址
 * @param tokenAddresses 可选的ERC20代币合约地址数组
 */
export async function getWalletBalance(address: string, tokenAddresses?: string[]): Promise<void> {
  try {
    console.log(`\n📊 正在查询钱包 ${address} 的完整余额信息...\n`);
    
    // 查询 ETH 余额
    const ethBalance = await getETHBalance(address);
    
    console.log(`\n🔸 ETH: ${ethBalance} ETH\n`);
    
    // 如果提供了代币地址，查询代币余额
    if (tokenAddresses && tokenAddresses.length > 0) {
      console.log('🔸 ERC20 代币余额:');
      
      for (const tokenAddress of tokenAddresses) {
        try {
          const tokenInfo = await getERC20Balance(address, tokenAddress);
          console.log(`   ${tokenInfo.symbol}: ${tokenInfo.balanceFormatted}`);
        } catch (error) {
          console.error(`   ❌ 查询代币 ${tokenAddress} 失败:`, error);
        }
      }
    }
    
    console.log('\n✅ 余额查询完成');
  } catch (error) {
    console.error('❌ 查询钱包余额失败:', error);
    throw error;
  }
}

/**
 * 检查地址格式是否正确
 * @param address 地址字符串
 * @returns 是否为有效的以太坊地址
 */
export function isValidAddress(address: string): boolean {
  return /^0x[a-fA-F0-9]{40}$/.test(address);
}

/**
 * 获取网络信息
 */
export async function getNetworkInfo(): Promise<void> {
  try {
    const client = createClient();
    
    const chainId = await client.getChainId();
    const blockNumber = await client.getBlockNumber();
    
    console.log(`🌐 网络信息:`);
    console.log(`   链 ID: ${chainId}`);
    console.log(`   当前区块: ${blockNumber}`);
    console.log(`   网络: ${base.name}`);
  } catch (error) {
    console.error('❌ 获取网络信息失败:', error);
    throw error;
  }
}