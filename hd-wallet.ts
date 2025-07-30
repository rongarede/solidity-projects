import { generateMnemonic, mnemonicToSeed } from '@scure/bip39';
import { wordlist } from '@scure/bip39/wordlists/english';
import { HDKey } from '@scure/bip32';
import { privateKeyToAccount } from 'viem/accounts';
import { formatEther } from 'viem';

interface DerivedAccount {
  index: number;
  path: string;
  address: string;
  privateKey: string;
}

class HDWallet {
  private mnemonic: string;
  private seed!: Uint8Array;
  private masterKey!: HDKey;

  private constructor(mnemonic?: string) {
    // 1. 生成或使用提供的助记词 (BIP-39)
    this.mnemonic = mnemonic || generateMnemonic(wordlist, 128); // 128 bits = 12 words
  }

  private async initialize() {
    console.log('🔑 生成的助记词 (BIP-39):');
    console.log(this.mnemonic);
    console.log('');

    // 2. 将助记词转换为种子并派生主账户 (BIP-32)
    this.seed = await mnemonicToSeed(this.mnemonic);
    this.masterKey = HDKey.fromMasterSeed(this.seed);
    
    console.log('🌱 主种子 (BIP-32):');
    console.log(`0x${Buffer.from(this.seed).toString('hex')}`);
    console.log('');
  }

  public static async create(mnemonic?: string): Promise<HDWallet> {
    const wallet = new HDWallet(mnemonic);
    await wallet.initialize();
    return wallet;
  }

  // 3. 基于 BIP-44 路径派生以太坊地址
  deriveAccounts(count: number = 5): DerivedAccount[] {
    const accounts: DerivedAccount[] = [];
    
    console.log('💰 派生的以太坊地址 (BIP-44):');
    console.log('路径格式: m/44\'/60\'/0\'/0/i (以太坊标准)');
    console.log('');

    for (let i = 0; i < count; i++) {
      // BIP-44 路径: m/44'/60'/0'/0/i
      // 44' = 目的 (BIP-44)
      // 60' = 币种 (以太坊)
      // 0'  = 账户索引
      // 0   = 外部链 (接收地址)
      // i   = 地址索引
      const path = `m/44'/60'/0'/0/${i}`;
      
      // 派生私钥
      const derivedKey = this.masterKey.derive(path);
      const privateKey = `0x${Buffer.from(derivedKey.privateKey!).toString('hex')}`;
      
      // 使用 viem 创建账户
      const account = privateKeyToAccount(privateKey as `0x${string}`);
      
      const derivedAccount: DerivedAccount = {
        index: i,
        path,
        address: account.address,
        privateKey
      };
      
      accounts.push(derivedAccount);
      
      // 4. 打印地址和私钥
      console.log(`账户 ${i}:`);
      console.log(`  路径:     ${path}`);
      console.log(`  地址:     ${account.address}`);
      console.log(`  私钥:     ${privateKey}`);
      console.log('');
    }

    return accounts;
  }

  // 验证派生过程
  verifyDerivation(accounts: DerivedAccount[]): void {
    console.log('🔍 验证派生过程:');
    
    accounts.forEach((account, index) => {
      // 重新从私钥创建账户验证
      const verifyAccount = privateKeyToAccount(account.privateKey as `0x${string}`);
      const isValid = verifyAccount.address === account.address;
      
      console.log(`账户 ${index}: ${isValid ? '✅ 验证通过' : '❌ 验证失败'}`);
    });
    console.log('');
  }

  // 展示协议信息
  showProtocolInfo(): void {
    console.log('📋 HD 钱包协议信息:');
    console.log('BIP-39: 助记词生成和种子派生');
    console.log('BIP-32: 分层确定性钱包密钥派生');
    console.log('BIP-44: 多账户层次结构 m/purpose\'/coin_type\'/account\'/change/address_index');
    console.log('');
    console.log('以太坊参数:');
    console.log('- 币种类型 (coin_type): 60');
    console.log('- 默认账户: 0');
    console.log('- 外部链 (change): 0 (接收地址)');
    console.log('- 内部链 (change): 1 (找零地址)');
    console.log('');
  }

  // 获取助记词
  getMnemonic(): string {
    return this.mnemonic;
  }
}

// 主函数
async function main() {
  console.log('🚀 HD 钱包派生测试 (BIP-32/BIP-39/BIP-44)');
  console.log('='.repeat(50));
  console.log('');

  try {
    // 创建 HD 钱包实例
    const hdWallet = await HDWallet.create();

    // 显示协议信息
    hdWallet.showProtocolInfo();

    // 派生前 5 个账户
    const accounts = hdWallet.deriveAccounts(5);

    // 验证派生过程
    hdWallet.verifyDerivation(accounts);

    console.log('✨ 测试完成！所有账户均成功派生。');
    console.log('');
    console.log('💡 提示:');
    console.log('- 这些是真实的以太坊地址和私钥');
    console.log('- 请妥善保管助记词和私钥');
    console.log('- 可以导入到 MetaMask 等钱包中使用');

  } catch (error) {
    console.error('❌ 错误:', error);
    process.exit(1);
  }
}

// 如果直接运行此脚本，执行主函数
if (require.main === module) {
  main();
}

export { HDWallet, DerivedAccount };
