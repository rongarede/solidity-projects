# ETH CLI 钱包

一个基于 Viem.js 和 TypeScript 构建的以太坊命令行钱包，支持 Base 网络上的 ETH 和 ERC20 代币操作。

## 功能特性

- 🔑 **钱包管理**: 生成新钱包、导入现有钱包、本地安全存储
- 💰 **余额查询**: 查询 ETH 和 ERC20 代币余额
- 💸 **代币转账**: 支持 ERC20 代币的 EIP-1559 转账
- ⛽ **Gas 优化**: 智能 Gas 费用估算和优化
- 🌐 **Base 网络**: 专为 Base 主网优化
- 🔒 **安全设计**: 私钥本地存储，不上传网络

## 技术栈

- **Viem.js**: 现代以太坊 TypeScript 库
- **TypeScript**: 类型安全的开发体验
- **Commander.js**: 强大的命令行界面框架
- **Inquirer.js**: 交互式命令行界面
- **dotenv**: 环境变量管理

## 安装依赖

```bash
npm install
```

## 环境配置

1. 复制环境变量模板：
```bash
cp .env.example .env
```

2. 编辑 `.env` 文件，设置 RPC URL：
```env
# Base Network RPC URL
RPC_URL=https://mainnet.base.org

# 可选配置
# GAS_PRICE=1
# GAS_LIMIT=21000
```

### 推荐的 RPC 提供商

- **Base 官方**: `https://mainnet.base.org`
- **Alchemy**: `https://base-mainnet.g.alchemy.com/v2/YOUR_API_KEY`
- **Infura**: `https://base-mainnet.infura.io/v3/YOUR_PROJECT_ID`
- **LlamaRPC**: `https://base.llamarpc.com`

## 编译项目

```bash
npm run build
```

## 使用方式

### 1. 交互式模式（推荐）

启动交互式命令行界面：

```bash
npm run dev
# 或者编译后运行
npm run cli
```

交互式菜单包含以下选项：
- 🔑 创建新钱包
- 📥 导入钱包
- 💰 查询余额  
- 💸 转账
- 🌐 网络信息
- ❌ 退出

### 2. 命令行模式

#### 创建新钱包
```bash
# 生成新钱包（仅显示）
npm run dev create

# 生成并保存到本地
npm run dev create --save
```

#### 导入钱包
```bash
# 从私钥导入钱包
npm run dev import 0x1234567890abcdef...

# 导入并保存到本地
npm run dev import 0x1234567890abcdef... --save
```

#### 查询余额
```bash
# 查询 ETH 余额
npm run dev balance 0x742d35Cc6039C4532CE81EB4DeCDD06D7b18C4Ce

# 查询 ERC20 代币余额
npm run dev token-balance 0x742d35Cc6039C4532CE81EB4DeCDD06D7b18C4Ce 0xA0b86a33E6441c8CAc783faec98c8B2De07B3e6C
```

#### 执行转账
```bash
# 基本转账
npm run dev transfer 0x742d35Cc6039C4532CE81EB4DeCDD06D7b18C4Ce 0xA0b86a33E6441c8CAc783faec98c8B2De07B3e6C 10.5

# 指定 Gas 参数
npm run dev transfer 0x742d35Cc6039C4532CE81EB4DeCDD06D7b18C4Ce 0xA0b86a33E6441c8CAc783faec98c8B2De07B3e6C 10.5 --gas-price 2 --gas-limit 100000
```

#### 查看网络信息
```bash
npm run dev network
```

## 项目结构

```
cliWallet/
├── src/
│   ├── wallet.ts      # 钱包生成、导入、存储
│   ├── balance.ts     # 余额查询功能
│   ├── transfer.ts    # 转账功能
│   └── cli.ts         # 命令行界面入口
├── dist/              # 编译输出目录
├── package.json       # 项目配置
├── tsconfig.json      # TypeScript 配置
├── .env.example       # 环境变量模板
├── .env               # 环境变量（需要创建）
└── README.md          # 项目说明
```

## 使用示例

### 完整操作流程

1. **创建钱包**：
```bash
$ npm run dev

🚀 ETH CLI 钱包
=================
? 请选择操作: 🔑 创建新钱包

🔑 正在生成新钱包...
✅ 钱包生成成功！
地址: 0x742d35Cc6039C4532CE81EB4DeCDD06D7b18C4Ce
私钥: 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef

? 是否将钱包保存到本地文件 (wallet.json)? Yes
💾 正在保存钱包到 ./wallet.json...
✅ 钱包已保存到本地文件
⚠️  请妥善保管私钥，不要泄露给他人！
```

2. **查询余额**：
```bash
? 请选择操作: 💰 查询余额
? 选择地址来源: 使用本地钱包文件
? 选择查询类型: 查询 ERC20 代币余额

📁 正在从 ./wallet.json 加载钱包...
✅ 钱包加载成功
地址: 0x742d35Cc6039C4532CE81EB4DeCDD06D7b18C4Ce

? 请输入 ERC20 代币合约地址: 0xA0b86a33E6441c8CAc783faec98c8B2De07B3e6C

🪙 正在查询地址 0x742d35Cc6039C4532CE81EB4DeCDD06D7b18C4Ce 的代币余额...
代币合约: 0xA0b86a33E6441c8CAc783faec98c8B2De07B3e6C

✅ 代币信息:
   名称: MyToken
   符号: MTK
   精度: 18
   余额: 100.5 MTK
```

3. **执行转账**：
```bash
? 请选择操作: 💸 转账

💸 ERC20 代币转账

📁 正在从 ./wallet.json 加载钱包...
✅ 钱包加载成功

? 请输入 ERC20 代币合约地址: 0xA0b86a33E6441c8CAc783faec98c8B2De07B3e6C
? 请输入接收地址: 0x8ba1f109551bD432803012645Hac136c82C52E4A
? 请输入转账数量: 10.5
? 是否先估算 gas 费用? Yes

⛽ 正在估算 gas 费用...
⛽ Gas 估算结果:
   Gas Limit: 65000
   Gas Price: 1.2 gwei
   预估费用: 0.000078 ETH

? 预估手续费: 0.000078 ETH，是否继续转账? Yes
? 确认执行转账? Yes

🚀 开始执行 ERC20 转账...
从: 0x742d35Cc6039C4532CE81EB4DeCDD06D7b18C4Ce
到: 0x8ba1f109551bD432803012645Hac136c82C52E4A
代币合约: 0xA0b86a33E6441c8CAc783faec98c8B2De07B3e6C
数量: 10.5

✅ 交易已提交！交易哈希: 0xabc123...
⏳ 等待交易确认...
🎉 交易成功确认！

🎉 转账成功完成！
```

## 安全注意事项

1. **私钥安全**：
   - 私钥存储在本地 `wallet.json` 文件中
   - 请妥善备份私钥，丢失无法恢复
   - 不要将私钥分享给任何人
   - 不要将包含私钥的文件上传到公共代码仓库

2. **网络安全**：
   - 使用可信的 RPC 提供商
   - 在主网操作前，建议先在测试网测试

3. **交易安全**：
   - 转账前务必核对接收地址
   - 小额测试后再进行大额转账
   - 注意 Gas 费用设置

## 常见问题

### Q: 如何更换 RPC 节点？
A: 编辑 `.env` 文件中的 `RPC_URL` 值，重启程序即可。

### Q: 支持哪些网络？
A: 目前专为 Base 主网设计，可以通过修改代码支持其他 EVM 兼容网络。

### Q: 如何备份钱包？
A: 备份 `wallet.json` 文件或记录私钥。建议同时备份两者。

### Q: 忘记了钱包密码怎么办？
A: 本钱包不使用密码，只使用私钥。如果丢失私钥，钱包无法恢复。

### Q: 转账失败怎么办？
A: 检查以下几点：
- 余额是否充足
- 网络连接是否正常
- Gas 费用是否足够
- 接收地址是否正确

## 开发

### 开发模式
```bash
npm run dev
```

### 编译
```bash
npm run build
```

### 运行编译后的版本
```bash
npm start
```

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

---

⚠️ **免责声明**: 本项目仅供学习和开发使用。使用本钱包进行实际交易时，请务必做好安全防护和测试。开发者不对因使用本软件造成的任何损失承担责任。