# ERC20 Faucet Project

一个基于 Solidity 的 ERC20 代币水龙头系统，包含测试代币合约和水龙头发放合约。

## 项目概述

本项目实现了一个完整的代币水龙头系统，允许用户定期领取测试代币。系统包含两个主要合约：
- **TestToken**: 标准的 ERC20 测试代币
- **TokenFaucet**: 代币水龙头，控制代币的定期发放

## 项目结构

```
ERC20Faucet/
├── src/
│   ├── TestToken.sol      # ERC20 测试代币合约
│   └── TokenFaucet.sol    # 代币水龙头合约
├── test/
│   └── TokenFaucet.t.sol  # 完整的测试套件
├── script/
│   └── Deploy.s.sol       # 部署脚本
├── foundry.toml           # Foundry 配置文件
└── README.md              # 项目说明文档
```

## 合约详情

### TestToken.sol
- **代币名称**: "TestToken"
- **代币符号**: "TST"
- **小数位数**: 18
- **总供应量**: 1,000,000 TST
- **特性**: 基于 OpenZeppelin ERC20 标准实现，部署时所有代币分配给部署者

### TokenFaucet.sol
- **核心功能**: 控制代币的定期发放
- **安全特性**: 
  - 24小时冷却机制
  - 重入攻击防护（手动实现）
  - 权限控制（仅 owner 可管理）
- **管理功能**:
  - 设置发放数量
  - 设置冷却时间
  - 提取未使用代币

## 主要功能

### 用户操作
```solidity
// 领取代币（默认 100 TST）
faucet.requestTokens();

// 查询距离下次领取的剩余时间
uint256 remaining = faucet.getRemainingCooldown(userAddress);

// 检查是否可以领取代币
bool canRequest = faucet.canRequestTokens(userAddress);
```

### 管理员操作
```solidity
// 设置每次发放的代币数量
faucet.setAmount(200); // 设置为 200 TST

// 设置冷却时间
faucet.setCooldown(12 * 60 * 60); // 设置为 12 小时

// 提取未使用的代币
faucet.withdraw(1000 * 10**18); // 提取指定数量
faucet.withdraw(0); // 提取全部余额
```

### 查询功能
```solidity
// 查询水龙头余额
uint256 balance = faucet.getFaucetBalance();

// 查询用户上次领取时间
uint256 lastTime = faucet.lastRequestTime(userAddress);

// 查询当前设置
uint256 amount = faucet.faucetAmount();
uint256 cooldown = faucet.cooldownTime();
```

## 安全机制

1. **冷却时间控制**: 防止用户频繁领取代币
2. **重入攻击防护**: 使用自实现的重入锁机制
3. **权限控制**: 关键管理功能仅 owner 可调用
4. **余额检查**: 确保水龙头有足够代币再发放
5. **输入验证**: 对所有参数进行有效性检查

## 快速开始

### 环境要求
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

### 安装依赖
```bash
# 克隆项目（如果适用）
cd /Users/youshuncheng/solidity/modoule3/ERC20Faucet

# 安装 OpenZeppelin 库
forge install OpenZeppelin/openzeppelin-contracts

# 编译合约
forge build
```

### 运行测试
```bash
# 运行所有测试
forge test

# 详细输出
forge test -vv

# 运行特定测试
forge test --match-test testRequestTokens

# 查看覆盖率
forge coverage
```

### 部署合约
```bash
# 启动本地节点
anvil

# 部署到本地网络
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --private-key <your_private_key> --broadcast
```

## 使用流程

### 1. 系统部署
```bash
# 1. 部署 TestToken 合约
# 2. 部署 TokenFaucet 合约
# 3. 向水龙头转入代币
forge script script/Deploy.s.sol --broadcast
```

### 2. 用户领取流程
1. 用户调用 `requestTokens()` 领取代币
2. 系统检查冷却时间和余额
3. 发放代币并记录时间戳
4. 用户需等待 24 小时后才能再次领取

### 3. 管理员维护
1. 监控水龙头余额
2. 根据需要调整发放数量和冷却时间
3. 定期补充水龙头代币余额

## 测试覆盖

### 已实现测试
- ✅ 合约初始状态验证
- ✅ 代币领取功能测试
- ✅ 冷却时间机制测试
- ✅ 多用户并发测试
- ✅ 管理员权限控制测试
- ✅ 参数设置功能测试
- ✅ 代币提取功能测试
- ✅ 余额不足处理测试
- ✅ 查询功能测试

### 测试统计
```bash
# 运行测试查看具体结果
forge test --gas-report
```

## 配置说明

### 默认配置
- **发放数量**: 100 TST per request
- **冷却时间**: 24 hours (86400 seconds)
- **初始资金**: 10,000 TST (转入水龙头)

### 自定义配置
可以通过构造函数参数或管理员函数调整：
```solidity
// 部署时自定义
TokenFaucet faucet = new TokenFaucet(
    tokenAddress,
    50,  // 50 TST per request
    12 * 60 * 60  // 12 hours cooldown
);

// 部署后调整
faucet.setAmount(75);
faucet.setCooldown(6 * 60 * 60);
```

## Gas 使用估算

| 函数 | Gas 消耗 (大约) |
|------|----------------|
| requestTokens() | ~50,000 |
| setAmount() | ~30,000 |
| setCooldown() | ~30,000 |
| withdraw() | ~40,000 |

## 注意事项

1. **代币余额**: 确保水龙头有足够的代币余额
2. **冷却时间**: 用户必须等待完整的冷却时间
3. **权限管理**: 只有合约 owner 可以执行管理操作
4. **Gas 费用**: 在主网部署时注意 gas 费用设置

## 故障排除

### 常见问题
1. **"Cooldown not expired"**: 用户需要等待冷却时间结束
2. **"Insufficient faucet balance"**: 水龙头代币余额不足
3. **"Ownable: caller is not the owner"**: 非 owner 尝试执行管理操作

### 解决方案
- 使用 `getRemainingCooldown()` 查询剩余冷却时间
- 使用 `getFaucetBalance()` 检查水龙头余额
- 确保使用正确的 owner 地址执行管理操作

## 开发工具

### Foundry 命令参考
```bash
# 构建
forge build

# 测试
forge test

# 部署
forge script <script> --broadcast

# 验证合约
forge verify-contract <address> <contract> --chain <chain>
```

### 合约交互
```bash
# 使用 cast 与合约交互
cast call <faucet_address> "getFaucetBalance()" 
cast send <faucet_address> "requestTokens()" --private-key <key>
```

## 文档链接

- [Foundry Book](https://book.getfoundry.sh/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Solidity Documentation](https://docs.soliditylang.org/)

## 许可证

MIT License
