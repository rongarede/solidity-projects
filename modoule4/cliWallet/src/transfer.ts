import { 
  createPublicClient, 
  createWalletClient, 
  http, 
  parseUnits, 
  formatUnits,
  getContract,
  parseGwei
} from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { base } from 'viem/chains';
import dotenv from 'dotenv';
import { getERC20Balance, isValidAddress } from './balance.js';

// 加载环境变量
dotenv.config();

/**
 * ERC20 代币转账相关的 ABI
 */
const ERC20_TRANSFER_ABI = [
  {
    inputs: [
      { name: 'to', type: 'address' },
      { name: 'amount', type: 'uint256' }
    ],
    name: 'transfer',
    outputs: [{ name: '', type: 'bool' }],
    stateMutability: 'nonpayable',
    type: 'function'
  },
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
  }
] as const;

/**
 * 转账参数接口
 */
export interface TransferParams {
  privateKey: string;
  to: string;
  tokenAddress: string;
  amount: string;
  gasPrice?: string; // 可选的 gas 价格 (gwei)
  gasLimit?: string; // 可选的 gas 限制
}

/**
 * 转账结果接口
 */
export interface TransferResult {
  success: boolean;
  txHash?: string;
  error?: string;
  gasUsed?: bigint;
  effectiveGasPrice?: bigint;
}

/**
 * 创建客户端
 */
function createClients(privateKey: string) {
  const rpcUrl = process.env.RPC_URL;
  if (!rpcUrl) {
    throw new Error('请在 .env 文件中设置 RPC_URL');
  }

  const account = privateKeyToAccount(privateKey as `0x${string}`);

  const publicClient = createPublicClient({
    chain: base,
    transport: http(rpcUrl)
  });

  const walletClient = createWalletClient({
    account,
    chain: base,
    transport: http(rpcUrl)
  });

  return { publicClient, walletClient, account };
}

/**
 * 验证转账参数
 * @param params 转账参数
 */
async function validateTransferParams(params: TransferParams): Promise<void> {
  const { privateKey, to, tokenAddress, amount } = params;

  // 验证私钥格式
  if (!privateKey.startsWith('0x') || privateKey.length !== 66) {
    throw new Error('私钥格式不正确');
  }

  // 验证接收地址
  if (!isValidAddress(to)) {
    throw new Error('接收地址格式不正确');
  }

  // 验证代币合约地址
  if (!isValidAddress(tokenAddress)) {
    throw new Error('代币合约地址格式不正确');
  }

  // 验证金额
  const amountNum = parseFloat(amount);
  if (isNaN(amountNum) || amountNum <= 0) {
    throw new Error('转账金额必须大于 0');
  }
}

/**
 * 检查余额是否足够
 * @param senderAddress 发送者地址
 * @param tokenAddress 代币合约地址
 * @param amount 转账数量
 * @param decimals 代币精度
 */
async function checkBalance(
  senderAddress: string, 
  tokenAddress: string, 
  amount: string, 
  decimals: number
): Promise<void> {
  try {
    const tokenInfo = await getERC20Balance(senderAddress, tokenAddress);
    const transferAmount = parseFloat(amount);
    const currentBalance = parseFloat(tokenInfo.balanceFormatted);

    if (transferAmount > currentBalance) {
      throw new Error(
        `余额不足！当前余额: ${tokenInfo.balanceFormatted} ${tokenInfo.symbol}, 尝试转账: ${amount} ${tokenInfo.symbol}`
      );
    }

    console.log(`✅ 余额检查通过: ${tokenInfo.balanceFormatted} ${tokenInfo.symbol} >= ${amount} ${tokenInfo.symbol}`);
  } catch (error) {
    console.error('❌ 余额检查失败:', error);
    throw error;
  }
}

/**
 * 估算交易的 gas 费用
 * @param params 转账参数
 * @returns 估算的 gas 信息
 */
export async function estimateTransferGas(params: TransferParams): Promise<{
  gasLimit: bigint;
  gasPrice: bigint;
  estimatedFee: string;
}> {
  try {
    console.log('⛽ 正在估算 gas 费用...');

    const { publicClient, walletClient, account } = createClients(params.privateKey);

    // 获取代币合约信息
    const tokenContract = getContract({
      address: params.tokenAddress as `0x${string}`,
      abi: ERC20_TRANSFER_ABI,
      client: publicClient
    });

    const decimals = await tokenContract.read.decimals();
    const amountInWei = parseUnits(params.amount, decimals);

    // 估算 gas limit
    const gasLimit = await publicClient.estimateContractGas({
      address: params.tokenAddress as `0x${string}`,
      abi: ERC20_TRANSFER_ABI,
      functionName: 'transfer',
      args: [params.to as `0x${string}`, amountInWei],
      account: walletClient.account
    });

    // 获取当前 gas price
    let gasPrice: bigint;
    if (params.gasPrice) {
      gasPrice = parseGwei(params.gasPrice);
    } else {
      gasPrice = await publicClient.getGasPrice();
    }

    // 计算预估费用
    const estimatedFee = formatUnits(gasLimit * gasPrice, 18);

    console.log(`⛽ Gas 估算结果:`);
    console.log(`   Gas Limit: ${gasLimit.toString()}`);
    console.log(`   Gas Price: ${formatUnits(gasPrice, 9)} gwei`);
    console.log(`   预估费用: ${estimatedFee} ETH`);

    return { gasLimit, gasPrice, estimatedFee };
  } catch (error) {
    console.error('❌ 估算 gas 失败:', error);
    throw error;
  }
}

/**
 * 执行ERC20代币转账
 * @param params 转账参数
 * @returns 转账结果
 */
export async function transferERC20(params: TransferParams): Promise<TransferResult> {
  try {
    console.log('\n🚀 开始执行 ERC20 转账...');
    console.log(`从: ${privateKeyToAccount(params.privateKey as `0x${string}`).address}`);
    console.log(`到: ${params.to}`);
    console.log(`代币合约: ${params.tokenAddress}`);
    console.log(`数量: ${params.amount}`);

    // 验证参数
    await validateTransferParams(params);

    const { publicClient, walletClient, account } = createClients(params.privateKey);

    // 获取代币信息
    const tokenContract = getContract({
      address: params.tokenAddress as `0x${string}`,
      abi: ERC20_TRANSFER_ABI,
      client: publicClient
    });

    const [decimals, symbol] = await Promise.all([
      tokenContract.read.decimals(),
      tokenContract.read.symbol()
    ]);

    console.log(`📋 代币信息: ${symbol}, 精度: ${decimals}`);

    // 检查余额
    await checkBalance(account.address, params.tokenAddress, params.amount, decimals);

    // 转换金额为最小单位
    const amountInWei = parseUnits(params.amount, decimals);
    console.log(`💰 转账金额 (最小单位): ${amountInWei.toString()}`);

    // 估算 gas
    const gasEstimate = await estimateTransferGas(params);

    // 构建交易
    const txConfig: any = {
      address: params.tokenAddress as `0x${string}`,
      abi: ERC20_TRANSFER_ABI,
      functionName: 'transfer',
      args: [params.to as `0x${string}`, amountInWei],
      gasPrice: gasEstimate.gasPrice
    };

    // 如果指定了 gas limit，使用指定值
    if (params.gasLimit) {
      txConfig.gas = BigInt(params.gasLimit);
    } else {
      // 增加 20% 的 gas buffer
      txConfig.gas = (gasEstimate.gasLimit * 120n) / 100n;
    }

    console.log('📝 正在签名并发送交易...');

    // 发送交易
    const txHash = await walletClient.writeContract(txConfig);

    console.log(`✅ 交易已提交！交易哈希: ${txHash}`);
    console.log('⏳ 等待交易确认...');

    // 等待交易确认
    const receipt = await publicClient.waitForTransactionReceipt({
      hash: txHash,
      confirmations: 1
    });

    if (receipt.status === 'success') {
      console.log('🎉 交易成功确认！');
      console.log(`📊 交易详情:`);
      console.log(`   区块号: ${receipt.blockNumber}`);
      console.log(`   Gas 使用: ${receipt.gasUsed.toString()}`);
      console.log(`   实际 Gas 价格: ${formatUnits(receipt.effectiveGasPrice, 9)} gwei`);
      console.log(`   实际费用: ${formatUnits(receipt.gasUsed * receipt.effectiveGasPrice, 18)} ETH`);

      return {
        success: true,
        txHash,
        gasUsed: receipt.gasUsed,
        effectiveGasPrice: receipt.effectiveGasPrice
      };
    } else {
      throw new Error('交易执行失败');
    }

  } catch (error) {
    console.error('❌ 转账失败:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : '未知错误'
    };
  }
}

/**
 * 批量转账（转账给多个地址）
 * @param params 基础转账参数
 * @param recipients 接收者列表 {address: string, amount: string}[]
 */
export async function batchTransfer(
  params: Omit<TransferParams, 'to' | 'amount'>,
  recipients: Array<{ address: string; amount: string }>
): Promise<TransferResult[]> {
  console.log(`\n📦 开始批量转账，共 ${recipients.length} 个接收者...`);

  const results: TransferResult[] = [];

  for (let i = 0; i < recipients.length; i++) {
    const recipient = recipients[i];
    console.log(`\n[${i + 1}/${recipients.length}] 转账给 ${recipient.address}`);

    try {
      const transferParams: TransferParams = {
        ...params,
        to: recipient.address,
        amount: recipient.amount
      };

      const result = await transferERC20(transferParams);
      results.push(result);

      if (result.success) {
        console.log(`✅ [${i + 1}] 转账成功`);
      } else {
        console.log(`❌ [${i + 1}] 转账失败: ${result.error}`);
      }

      // 在批量转账之间添加延迟，避免 nonce 冲突
      if (i < recipients.length - 1) {
        console.log('⏳ 等待 3 秒后继续下一笔转账...');
        await new Promise(resolve => setTimeout(resolve, 3000));
      }

    } catch (error) {
      const errorResult: TransferResult = {
        success: false,
        error: error instanceof Error ? error.message : '未知错误'
      };
      results.push(errorResult);
      console.log(`❌ [${i + 1}] 转账异常: ${errorResult.error}`);
    }
  }

  // 统计结果
  const successCount = results.filter(r => r.success).length;
  const failCount = results.length - successCount;

  console.log(`\n📊 批量转账完成统计:`);
  console.log(`   成功: ${successCount}`);
  console.log(`   失败: ${failCount}`);
  console.log(`   总计: ${results.length}`);

  return results;
}