# MultiSigWallet 多签钱包

基于 OpenZeppelin 开发的安全、简洁的多签钱包合约，支持多个签名者共同管理资金。

## 🎯 项目概述

MultiSigWallet 是一个使用 Solidity 和 Foundry 构建的多重签名钱包智能合约。它集成了 OpenZeppelin 的安全模块，提供了防重入攻击、安全地址处理和所有者管理等功能。

## 🔧 技术栈

- **Solidity** ^0.8.20
- **Foundry** - 开发和测试框架
- **OpenZeppelin Contracts** - 安全模块库
  - `ReentrancyGuard` - 防重入攻击
  - `Address` - 安全地址处理
  - `Ownable` - 所有者管理

## 🚀 核心功能

### 多签管理
- 支持初始化时设定多签持有人地址数组
- 可配置的签名门槛（threshold）
- 合约 owner 可动态添加/移除多签所有者
- 支持更新签名门槛

### 交易管理
- 多签人可提交交易提案（包含 `to`、`value`、`data`）
- 多签人可对提案进行确认或撤销确认
- 达到签名门槛后任何人都可执行交易
- 提案只能执行一次，防止重复执行

### 安全特性
- 使用 OpenZeppelin `ReentrancyGuard` 防止重入攻击
- 使用 `Address` 工具确保安全的 call 操作
- 完整的权限检查和状态验证
- 自定义错误节省 gas 费用

## 📁 项目结构

```
MultiSigWallet/
├── src/
│   └── MultiSigWallet.sol          # 核心合约
├── test/
│   └── MultiSigWallet.t.sol        # 测试套件
├── script/
│   └── Deploy.s.sol                # 部署脚本
├── lib/
│   ├── forge-std/                  # Foundry 标准库
│   └── openzeppelin-contracts/     # OpenZeppelin 依赖
├── foundry.toml                    # Foundry 配置
└── README.md                       # 项目文档
```

## 🔒 合约接口

### 主要函数

#### 多签交易管理
```solidity
// 提交交易提案
function submitTransaction(address _to, uint256 _value, bytes memory _data) public

// 确认交易
function confirmTransaction(uint256 _txIndex) public

// 撤销确认
function revokeConfirmation(uint256 _txIndex) public

// 执行交易
function executeTransaction(uint256 _txIndex) public
```

#### 所有者管理（仅合约 owner）
```solidity
// 添加多签所有者
function addOwner(address _owner) external onlyOwner

// 移除多签所有者
function removeOwner(address _owner) external onlyOwner

// 更新签名门槛
function updateThreshold(uint256 _threshold) external onlyOwner
```

#### 查询函数
```solidity
// 获取所有者列表
function getOwners() public view returns (address[] memory)

// 获取交易数量
function getTransactionCount() public view returns (uint256)

// 获取交易详情
function getTransaction(uint256 _txIndex) public view returns (...)

// 检查交易确认状态
function isTransactionConfirmed(uint256 _txIndex, address _owner) public view returns (bool)

// 获取合约余额
function getBalance() public view returns (uint256)
```

### 事件
```solidity
event Submit(address indexed owner, uint256 indexed txIndex, address indexed to, uint256 value, bytes data);
event Confirm(address indexed owner, uint256 indexed txIndex);
event Revoke(address indexed owner, uint256 indexed txIndex);
event Execute(address indexed owner, uint256 indexed txIndex);
```

## 🧪 测试

项目包含 21 个全面的测试用例，覆盖所有功能：

### 基础功能测试
- ✅ 构造函数验证
- ✅ 提交交易
- ✅ 确认交易
- ✅ 执行交易
- ✅ 撤销确认
- ✅ 事件验证

### 权限和错误处理测试
- ✅ 非所有者操作权限检查
- ✅ 重复确认防护
- ✅ 未达门槛执行防护
- ✅ 重复执行防护

### 管理功能测试
- ✅ 添加/移除多签所有者
- ✅ 更新签名门槛
- ✅ 权限验证

### 运行测试
```bash
# 运行所有测试
forge test

# 运行特定测试
forge test --match-test test_ExecuteTransaction

# 查看详细输出
forge test -vv
```

## 🚀 部署

### 1. 环境准备
```bash
# 克隆项目
git clone <repository-url>
cd MultiSigWallet

# 安装依赖
forge install

# 编译合约
forge build
```

### 2. 配置部署参数
编辑 `script/Deploy.s.sol` 文件，设置：
- 多签所有者地址数组
- 签名门槛值
- 部署者私钥环境变量

### 3. 部署合约
```bash
# 本地测试网部署
forge script script/Deploy.s.sol:DeployScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

# 主网部署（谨慎操作）
forge script script/Deploy.s.sol:DeployScript --rpc-url $MAINNET_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
```

## 📊 使用示例

### 1. 初始化多签钱包
```solidity
address[] memory owners = [0x123..., 0x456..., 0x789...];
uint256 threshold = 2;
MultiSigWallet wallet = new MultiSigWallet(owners, threshold);
```

### 2. 提交交易提案
```solidity
// 向 recipient 转账 1 ETH
wallet.submitTransaction(recipient, 1 ether, "");

// 调用其他合约
bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", recipient, amount);
wallet.submitTransaction(tokenContract, 0, data);
```

### 3. 确认并执行交易
```solidity
// 所有者确认交易
wallet.confirmTransaction(0);

// 达到门槛后执行
wallet.executeTransaction(0);
```

## 🔐 安全考虑

1. **重入攻击防护**: 使用 OpenZeppelin `ReentrancyGuard`
2. **权限控制**: 严格的多签所有者权限检查
3. **状态验证**: 完整的交易状态和执行条件验证
4. **Gas 优化**: 使用自定义错误减少 gas 消耗
5. **地址验证**: 使用 `Address` 工具确保安全调用

## 📋 限制条件

- 多签所有者不能重复确认同一交易
- 不能撤销未确认的交易
- 仅多签所有者可提交和确认交易
- 交易只能执行一次
- 合约 owner 可管理多签所有者和门槛

## 🛠️ Foundry 命令参考

### 构建
```shell
forge build
```

### 测试
```shell
forge test
```

### 格式化
```shell
forge fmt
```

### Gas 快照
```shell
forge snapshot
```

### 启动本地节点
```shell
anvil
```

### 部署
```shell
forge script script/Deploy.s.sol:DeployScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast 工具
```shell
cast <subcommand>
```

### 帮助
```shell
forge --help
anvil --help
cast --help
```

## 🤝 贡献指南

1. Fork 项目
2. 创建特性分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

## 📄 许可证

MIT License

## 📞 联系方式

如有问题或建议，请创建 Issue 或联系开发团队。

---

**注意**: 这是一个教育和演示项目。在生产环境中使用前，请进行充分的安全审计。