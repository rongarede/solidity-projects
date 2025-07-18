#!/usr/bin/env node

import { Command } from 'commander';
import inquirer from 'inquirer';
import dotenv from 'dotenv';
import { 
  generateWallet, 
  saveWallet, 
  loadWallet, 
  walletExists, 
  createWalletFromPrivateKey,
  type WalletInfo 
} from './wallet.js';
import { 
  getETHBalance, 
  getERC20Balance, 
  getWalletBalance, 
  getNetworkInfo,
  isValidAddress 
} from './balance.js';
import { 
  transferERC20, 
  estimateTransferGas, 
  batchTransfer,
  type TransferParams 
} from './transfer.js';

// 加载环境变量
dotenv.config();

const program = new Command();

/**
 * 显示欢迎信息
 */
function showWelcome(): void {
  console.log('\n🚀 ETH CLI 钱包');
  console.log('=================');
  console.log('基于 Viem.js 构建的以太坊命令行钱包\n');
}

/**
 * 创建新钱包的交互式流程
 */
async function createWalletInteractive(): Promise<void> {
  try {
    console.log('\n💼 创建新钱包\n');

    // 生成新钱包
    const wallet = generateWallet();

    // 询问是否保存钱包
    const { shouldSave } = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'shouldSave',
        message: '是否将钱包保存到本地文件 (wallet.json)?',
        default: true
      }
    ]);

    if (shouldSave) {
      // 检查文件是否已存在
      if (walletExists()) {
        const { overwrite } = await inquirer.prompt([
          {
            type: 'confirm',
            name: 'overwrite',
            message: '钱包文件已存在，是否覆盖?',
            default: false
          }
        ]);

        if (!overwrite) {
          console.log('⚠️  钱包未保存');
          return;
        }
      }

      saveWallet(wallet);
    }

  } catch (error) {
    console.error('❌ 创建钱包失败:', error);
  }
}

/**
 * 导入钱包的交互式流程
 */
async function importWalletInteractive(): Promise<void> {
  try {
    console.log('\n📥 导入钱包\n');

    const { privateKey } = await inquirer.prompt([
      {
        type: 'password',
        name: 'privateKey',
        message: '请输入私钥:',
        mask: '*',
        validate: (input: string) => {
          if (!input) return '私钥不能为空';
          const key = input.startsWith('0x') ? input : '0x' + input;
          if (key.length !== 66) return '私钥长度不正确';
          return true;
        }
      }
    ]);

    const wallet = createWalletFromPrivateKey(privateKey);

    const { shouldSave } = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'shouldSave',
        message: '是否将钱包保存到本地文件 (wallet.json)?',
        default: true
      }
    ]);

    if (shouldSave) {
      if (walletExists()) {
        const { overwrite } = await inquirer.prompt([
          {
            type: 'confirm',
            name: 'overwrite',
            message: '钱包文件已存在，是否覆盖?',
            default: false
          }
        ]);

        if (!overwrite) {
          console.log('⚠️  钱包未保存');
          return;
        }
      }

      saveWallet(wallet);
    }

  } catch (error) {
    console.error('❌ 导入钱包失败:', error);
  }
}

/**
 * 查询余额的交互式流程
 */
async function checkBalanceInteractive(): Promise<void> {
  try {
    console.log('\n💰 查询余额\n');

    const { addressSource } = await inquirer.prompt([
      {
        type: 'list',
        name: 'addressSource',
        message: '选择地址来源:',
        choices: [
          { name: '使用本地钱包文件', value: 'local' },
          { name: '手动输入地址', value: 'manual' }
        ]
      }
    ]);

    let address: string;

    if (addressSource === 'local') {
      const wallet = loadWallet();
      if (!wallet) {
        console.log('❌ 未找到本地钱包文件，请先创建钱包');
        return;
      }
      address = wallet.address;
    } else {
      const { inputAddress } = await inquirer.prompt([
        {
          type: 'input',
          name: 'inputAddress',
          message: '请输入钱包地址:',
          validate: (input: string) => {
            if (!isValidAddress(input)) {
              return '请输入有效的以太坊地址';
            }
            return true;
          }
        }
      ]);
      address = inputAddress;
    }

    const { queryType } = await inquirer.prompt([
      {
        type: 'list',
        name: 'queryType',
        message: '选择查询类型:',
        choices: [
          { name: '仅查询 ETH 余额', value: 'eth' },
          { name: '查询 ERC20 代币余额', value: 'erc20' },
          { name: '显示网络信息', value: 'network' }
        ]
      }
    ]);

    switch (queryType) {
      case 'eth':
        await getETHBalance(address);
        break;
      
      case 'erc20':
        const { tokenAddress } = await inquirer.prompt([
          {
            type: 'input',
            name: 'tokenAddress',
            message: '请输入 ERC20 代币合约地址:',
            validate: (input: string) => {
              if (!isValidAddress(input)) {
                return '请输入有效的合约地址';
              }
              return true;
            }
          }
        ]);
        await getERC20Balance(address, tokenAddress);
        break;
      
      case 'network':
        await getNetworkInfo();
        break;
    }

  } catch (error) {
    console.error('❌ 查询余额失败:', error);
  }
}

/**
 * 转账的交互式流程
 */
async function transferInteractive(): Promise<void> {
  try {
    console.log('\n💸 ERC20 代币转账\n');

    // 检查本地钱包
    const wallet = loadWallet();
    if (!wallet) {
      console.log('❌ 未找到本地钱包文件，请先创建或导入钱包');
      return;
    }

    const answers = await inquirer.prompt([
      {
        type: 'input',
        name: 'tokenAddress',
        message: '请输入 ERC20 代币合约地址:',
        validate: (input: string) => {
          if (!isValidAddress(input)) {
            return '请输入有效的合约地址';
          }
          return true;
        }
      },
      {
        type: 'input',
        name: 'to',
        message: '请输入接收地址:',
        validate: (input: string) => {
          if (!isValidAddress(input)) {
            return '请输入有效的以太坊地址';
          }
          return true;
        }
      },
      {
        type: 'input',
        name: 'amount',
        message: '请输入转账数量:',
        validate: (input: string) => {
          const num = parseFloat(input);
          if (isNaN(num) || num <= 0) {
            return '请输入有效的转账数量';
          }
          return true;
        }
      },
      {
        type: 'confirm',
        name: 'estimateGas',
        message: '是否先估算 gas 费用?',
        default: true
      }
    ]);

    const transferParams: TransferParams = {
      privateKey: wallet.privateKey,
      to: answers.to,
      tokenAddress: answers.tokenAddress,
      amount: answers.amount
    };

    // 估算 gas 费用
    if (answers.estimateGas) {
      console.log('\n⛽ 估算 gas 费用...');
      try {
        const gasEstimate = await estimateTransferGas(transferParams);
        
        const { proceedWithTransfer } = await inquirer.prompt([
          {
            type: 'confirm',
            name: 'proceedWithTransfer',
            message: `预估手续费: ${gasEstimate.estimatedFee} ETH，是否继续转账?`,
            default: true
          }
        ]);

        if (!proceedWithTransfer) {
          console.log('⚠️  转账已取消');
          return;
        }
      } catch (error) {
        console.error('❌ 估算 gas 失败:', error);
        const { continueAnyway } = await inquirer.prompt([
          {
            type: 'confirm',
            name: 'continueAnyway',
            message: '无法估算 gas 费用，是否仍要继续转账?',
            default: false
          }
        ]);

        if (!continueAnyway) {
          console.log('⚠️  转账已取消');
          return;
        }
      }
    }

    // 最终确认
    const { finalConfirm } = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'finalConfirm',
        message: '确认执行转账?',
        default: false
      }
    ]);

    if (!finalConfirm) {
      console.log('⚠️  转账已取消');
      return;
    }

    // 执行转账
    const result = await transferERC20(transferParams);

    if (result.success) {
      console.log('\n🎉 转账成功完成！');
    } else {
      console.log('\n❌ 转账失败');
    }

  } catch (error) {
    console.error('❌ 转账过程出错:', error);
  }
}

/**
 * 主菜单交互式流程
 */
async function showMainMenu(): Promise<void> {
  showWelcome();

  while (true) {
    try {
      const { action } = await inquirer.prompt([
        {
          type: 'list',
          name: 'action',
          message: '请选择操作:',
          choices: [
            { name: '🔑 创建新钱包', value: 'create' },
            { name: '📥 导入钱包', value: 'import' },
            { name: '💰 查询余额', value: 'balance' },
            { name: '💸 转账', value: 'transfer' },
            { name: '🌐 网络信息', value: 'network' },
            { name: '❌ 退出', value: 'exit' }
          ]
        }
      ]);

      switch (action) {
        case 'create':
          await createWalletInteractive();
          break;
        case 'import':
          await importWalletInteractive();
          break;
        case 'balance':
          await checkBalanceInteractive();
          break;
        case 'transfer':
          await transferInteractive();
          break;
        case 'network':
          await getNetworkInfo();
          break;
        case 'exit':
          console.log('\n👋 再见！');
          process.exit(0);
      }

      // 操作完成后暂停
      await inquirer.prompt([
        {
          type: 'input',
          name: 'continue',
          message: '\n按 Enter 键继续...'
        }
      ]);

    } catch (error) {
      if (error instanceof Error && error.message.includes('ExitPromptError')) {
        console.log('\n👋 再见！');
        process.exit(0);
      }
      console.error('❌ 操作失败:', error);
    }
  }
}

// 命令行程序配置
program
  .name('eth-wallet')
  .description('ETH CLI 钱包 - 基于 Viem.js 的以太坊命令行钱包')
  .version('1.0.0');

// 交互式模式（默认）
program
  .command('interactive', { isDefault: true })
  .description('启动交互式模式')
  .action(showMainMenu);

// 创建钱包命令
program
  .command('create')
  .description('生成新钱包')
  .option('-s, --save', '保存到本地文件')
  .action(async (options) => {
    try {
      const wallet = generateWallet();
      if (options.save) {
        saveWallet(wallet);
      }
    } catch (error) {
      console.error('❌ 创建钱包失败:', error);
    }
  });

// 导入钱包命令
program
  .command('import <privateKey>')
  .description('从私钥导入钱包')
  .option('-s, --save', '保存到本地文件')
  .action(async (privateKey: string, options) => {
    try {
      const wallet = createWalletFromPrivateKey(privateKey);
      if (options.save) {
        saveWallet(wallet);
      }
    } catch (error) {
      console.error('❌ 导入钱包失败:', error);
    }
  });

// 查询 ETH 余额命令
program
  .command('balance <address>')
  .description('查询 ETH 余额')
  .action(async (address: string) => {
    try {
      await getETHBalance(address);
    } catch (error) {
      console.error('❌ 查询余额失败:', error);
    }
  });

// 查询 ERC20 余额命令
program
  .command('token-balance <address> <tokenAddress>')
  .description('查询 ERC20 代币余额')
  .action(async (address: string, tokenAddress: string) => {
    try {
      await getERC20Balance(address, tokenAddress);
    } catch (error) {
      console.error('❌ 查询代币余额失败:', error);
    }
  });

// 转账命令
program
  .command('transfer <to> <tokenAddress> <amount>')
  .description('执行 ERC20 代币转账')
  .option('-g, --gas-price <price>', 'Gas 价格 (gwei)')
  .option('-l, --gas-limit <limit>', 'Gas 限制')
  .action(async (to: string, tokenAddress: string, amount: string, options) => {
    try {
      const wallet = loadWallet();
      if (!wallet) {
        console.error('❌ 未找到本地钱包文件');
        return;
      }

      const transferParams: TransferParams = {
        privateKey: wallet.privateKey,
        to,
        tokenAddress,
        amount,
        gasPrice: options.gasPrice,
        gasLimit: options.gasLimit
      };

      const result = await transferERC20(transferParams);
      
      if (!result.success) {
        process.exit(1);
      }
    } catch (error) {
      console.error('❌ 转账失败:', error);
      process.exit(1);
    }
  });

// 网络信息命令
program
  .command('network')
  .description('显示网络信息')
  .action(async () => {
    try {
      await getNetworkInfo();
    } catch (error) {
      console.error('❌ 获取网络信息失败:', error);
    }
  });

// 处理错误
program.configureOutput({
  writeErr: (str) => process.stderr.write(`[ERR] ${str}`)
});

// 解析命令行参数
program.parse();