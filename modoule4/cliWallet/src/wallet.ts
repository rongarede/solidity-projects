import { generatePrivateKey, privateKeyToAccount } from 'viem/accounts';
import { readFileSync, writeFileSync, existsSync } from 'fs';
import { join } from 'path';

/**
 * 钱包信息接口
 */
export interface WalletInfo {
  address: string;
  privateKey: string;
}

/**
 * 钱包文件路径
 */
const WALLET_FILE_PATH = './wallet.json';

/**
 * 生成新的钱包（私钥和地址）
 * @returns 包含地址和私钥的钱包信息
 */
export function generateWallet(): WalletInfo {
  console.log('🔑 正在生成新钱包...');
  
  // 生成随机私钥
  const privateKey = generatePrivateKey();
  
  // 从私钥生成账户
  const account = privateKeyToAccount(privateKey);
  
  const walletInfo: WalletInfo = {
    address: account.address,
    privateKey
  };
  
  console.log('✅ 钱包生成成功！');
  console.log(`地址: ${walletInfo.address}`);
  console.log(`私钥: ${walletInfo.privateKey}`);
  
  return walletInfo;
}

/**
 * 保存钱包信息到本地文件
 * @param walletInfo 钱包信息
 * @param filePath 可选的文件路径，默认为 ./wallet.json
 */
export function saveWallet(walletInfo: WalletInfo, filePath: string = WALLET_FILE_PATH): void {
  try {
    console.log(`💾 正在保存钱包到 ${filePath}...`);
    
    writeFileSync(filePath, JSON.stringify(walletInfo, null, 2), 'utf-8');
    
    console.log('✅ 钱包已保存到本地文件');
    console.log('⚠️  请妥善保管私钥，不要泄露给他人！');
  } catch (error) {
    console.error('❌ 保存钱包失败:', error);
    throw error;
  }
}

/**
 * 从本地文件加载钱包信息
 * @param filePath 可选的文件路径，默认为 ./wallet.json
 * @returns 钱包信息，如果文件不存在则返回 null
 */
export function loadWallet(filePath: string = WALLET_FILE_PATH): WalletInfo | null {
  try {
    if (!existsSync(filePath)) {
      console.log(`📁 钱包文件 ${filePath} 不存在`);
      return null;
    }
    
    console.log(`📁 正在从 ${filePath} 加载钱包...`);
    
    const fileContent = readFileSync(filePath, 'utf-8');
    const walletInfo: WalletInfo = JSON.parse(fileContent);
    
    // 验证钱包信息格式
    if (!walletInfo.address || !walletInfo.privateKey) {
      throw new Error('钱包文件格式不正确');
    }
    
    // 验证私钥格式
    if (!walletInfo.privateKey.startsWith('0x') || walletInfo.privateKey.length !== 66) {
      throw new Error('私钥格式不正确');
    }
    
    console.log('✅ 钱包加载成功');
    console.log(`地址: ${walletInfo.address}`);
    
    return walletInfo;
  } catch (error) {
    console.error('❌ 加载钱包失败:', error);
    return null;
  }
}

/**
 * 从私钥字符串创建钱包信息
 * @param privateKey 私钥字符串
 * @returns 钱包信息
 */
export function createWalletFromPrivateKey(privateKey: string): WalletInfo {
  try {
    console.log('🔑 正在从私钥创建钱包...');
    
    // 确保私钥格式正确
    if (!privateKey.startsWith('0x')) {
      privateKey = '0x' + privateKey;
    }
    
    // 从私钥生成账户
    const account = privateKeyToAccount(privateKey as `0x${string}`);
    
    const walletInfo: WalletInfo = {
      address: account.address,
      privateKey
    };
    
    console.log('✅ 钱包创建成功！');
    console.log(`地址: ${walletInfo.address}`);
    
    return walletInfo;
  } catch (error) {
    console.error('❌ 从私钥创建钱包失败:', error);
    throw error;
  }
}

/**
 * 检查钱包文件是否存在
 * @param filePath 可选的文件路径，默认为 ./wallet.json
 * @returns 文件是否存在
 */
export function walletExists(filePath: string = WALLET_FILE_PATH): boolean {
  return existsSync(filePath);
}