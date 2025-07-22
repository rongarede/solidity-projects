# TokenBank

一个极简而安全的ERC20代币银行智能合约，支持任意ERC20代币的存取操作。基于OpenZeppelin框架构建，已部署在Base主网。

## 🚀 项目概览

TokenBank是一个去中心化的代币存储解决方案，允许用户安全地存入和提取ERC20代币。合约设计简洁，专注于核心功能，同时保持企业级的安全标准。

### 主要特性

- 🔒 **安全可靠**: 基于OpenZeppelin标准，内置重入攻击防护
- 🪙 **多代币支持**: 支持任意符合ERC20标准的代币
- 💰 **余额隔离**: 每个用户的不同代币余额完全隔离
- ⚡ **Gas优化**: 简洁的合约设计，降低交易成本
- 🌐 **生产就绪**: 已在Base主网部署并通过完整测试

## 📋 合约信息

### 部署地址 (Base主网)

- **TokenBank合约**: [`0xcB76bF429B49397363c36123DF9c2F93627e4f92`](https://basescan.org/address/0xcB76bF429B49397363c36123DF9c2F93627e4f92)
- **TEST代币**: [`0x134bd50D5347eE1aD950Dc79B10d17bD1048c7A1`](https://basescan.org/address/0x134bd50D5347eE1aD950Dc79B10d17bD1048c7A1)

### 技术栈

- **Solidity**: ^0.8.13
- **框架**: Foundry + OpenZeppelin
- **网络**: Base主网 (Chain ID: 8453)
- **前端**: React + TypeScript + Viem + Wagmi

## 🏗️ 合约架构

### 核心合约

#### TokenBank.sol
```solidity
contract TokenBank is ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    mapping(address => mapping(address => uint256)) public balances;
    
    function deposit(address token, uint256 amount) external nonReentrant;
    function withdraw(address token, uint256 amount) external nonReentrant;
    function getBalance(address user, address token) external view returns (uint256);
}
```

### 安全特性

- **ReentrancyGuard**: 防止重入攻击
- **SafeERC20**: 安全的ERC20代币转账
- **输入验证**: 完整的参数验证和错误处理

### 事件

```solidity
event Deposit(address indexed user, address indexed token, uint256 amount);
event Withdraw(address indexed user, address indexed token, uint256 amount);
```

## 🛠️ 开发环境

### 系统要求

- Node.js >= 16
- Foundry
- Git

### 安装依赖

```bash
# 克隆仓库
git clone <repository-url>
cd TokenBank

# 安装Foundry依赖
forge install

# 安装前端依赖
cd frontend
npm install
```

## 🧪 测试

### 运行合约测试

```bash
# 编译合约
forge build

# 运行测试套件
forge test -vv

# 生成测试覆盖率报告
forge coverage
```

### 测试用例

项目包含10个全面的测试用例：

- ✅ 基础存取款功能
- ✅ 多代币支持测试
- ✅ 多用户隔离测试
- ✅ 错误边界测试（零金额、无效地址、余额不足等）
- ✅ 重入攻击防护测试

## 🚀 部署指南

### 本地部署

```bash
# 启动本地节点
anvil

# 部署到本地网络
forge script script/DeployTokenBank.s.sol --rpc-url http://localhost:8545 --private-key <PRIVATE_KEY> --broadcast
```

### Base主网部署

```bash
# 部署TokenBank合约
forge script script/DeployTokenBank.s.sol --rpc-url base --private-key <PRIVATE_KEY> --broadcast

# 部署测试代币（可选）
forge script script/DeployTestToken.s.sol --rpc-url base --private-key <PRIVATE_KEY> --broadcast
```

### 链上测试

```bash
# 运行链上功能测试
forge script script/TestTokenBank.s.sol --rpc-url base --private-key <PRIVATE_KEY> --broadcast
```

## 🖥️ 前端应用

### 功能特性

- 🔗 **钱包连接**: 支持MetaMask等主流钱包
- 💰 **余额显示**: 实时显示代币和银行余额
- 📥 **存款功能**: 智能授权处理 + 一键存款
- 📤 **取款功能**: 安全的资金提取
- 🔄 **余额刷新**: 一键刷新最新余额
- 📊 **交易状态**: 实时交易确认反馈

### 启动前端

```bash
cd frontend

# 开发模式
npm run dev

# 生产构建
npm run build
```

### 前端配置

前端应用已预配置连接Base主网和部署的合约地址。确保：

1. 钱包连接到Base主网
2. 账户有足够的ETH支付Gas费
3. 拥有TEST代币进行测试

## 📚 使用示例

### 合约交互

```javascript
// 存款示例
await testToken.approve(tokenBankAddress, amount);
await tokenBank.deposit(testTokenAddress, amount);

// 取款示例
await tokenBank.withdraw(testTokenAddress, amount);

// 查询余额
const balance = await tokenBank.getBalance(userAddress, testTokenAddress);
```

### 前端使用

1. 访问前端应用
2. 点击"Connect Wallet"连接钱包
3. 确保钱包切换到Base主网
4. 在存款区域输入金额并存款（首次需授权）
5. 在取款区域输入金额并取款
6. 使用刷新按钮更新余额

## 🔧 项目结构

```
TokenBank/
├── src/
│   ├── TokenBank.sol          # 主合约
│   └── TestToken.sol          # 测试代币
├── test/
│   └── TokenBank.t.sol        # 测试套件
├── script/
│   ├── DeployTokenBank.s.sol  # 部署脚本
│   ├── DeployTestToken.s.sol  # 测试代币部署
│   └── TestTokenBank.s.sol    # 链上测试脚本
├── frontend/                  # React前端应用
│   ├── src/
│   │   ├── App.tsx           # 主应用组件
│   │   ├── config.ts         # 配置和ABI
│   │   └── App.css           # 样式文件
│   └── README.md             # 前端文档
└── README.md                 # 项目文档
```

## 🛡️ 安全考虑

### 已实施的安全措施

- **重入攻击防护**: 使用OpenZeppelin的ReentrancyGuard
- **安全代币转账**: 使用SafeERC20库处理代币转账
- **输入验证**: 完整的参数验证和边界检查
- **事件日志**: 完整的操作记录便于审计

### 最佳实践

- 合约代码经过完整测试覆盖
- 基于经过审计的OpenZeppelin库
- 简洁的架构设计降低攻击面
- 完整的错误处理和回滚机制

## 🔗 相关链接

- [Base网络官网](https://base.org/)
- [OpenZeppelin文档](https://docs.openzeppelin.com/)
- [Foundry文档](https://book.getfoundry.sh/)
- [Wagmi文档](https://wagmi.sh/)

## 📄 许可证

MIT License - 详见 LICENSE 文件

## 🤝 贡献

欢迎提交Issue和Pull Request！

---

**⚠️ 免责声明**: 本项目仅供学习和测试目的。在生产环境使用前请进行充分的安全审计。