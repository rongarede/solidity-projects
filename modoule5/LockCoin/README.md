# LockCoin - ERC20 Linear Vesting Contract

## 🔍 项目概述

LockCoin 是一个基于以太坊的 ERC20 代币线性锁仓实验项目，实现了安全可靠的代币线性释放机制。项目由自定义代币 MyToken 和线性释放合约 TokenVester 组成，用户可随时调用 `claim()` 函数领取当前时刻可得的代币。

### 核心特点
- 🔒 **线性释放**: 基于时间的线性代币释放机制
- 🛡️ **安全可靠**: 防重入攻击、溢出保护、权限控制
- 👥 **多用户支持**: 支持为多个受益人创建独立的锁仓计划
- ⚡ **Gas 优化**: 高效的合约设计，降低交易成本
- 🎛️ **管理功能**: 管理员可撤销锁仓、提取多余代币

## ✨ 主要特性

- ✅ **线性释放机制**: 按时间比例线性释放代币
- ✅ **防重入攻击**: 使用 OpenZeppelin ReentrancyGuard
- ✅ **多用户支持**: 每个用户独立的锁仓计划和状态
- ✅ **管理员权限控制**: 基于 Ownable 的访问控制
- ✅ **安全转账**: 使用 SafeERC20 防止转账失败
- ✅ **事件日志**: 完整的事件记录便于追踪
- ✅ **错误处理**: 自定义错误类型，Gas 效率更高

## 🏗️ 合约架构

```
MyToken (ERC20)
├── 标准 ERC20 功能
├── 铸造功能 (仅 Owner)
└── 所有权转移

TokenVester (线性释放)
├── 创建锁仓计划 (createVestingSchedule)
├── 领取代币 (claim)
├── 撤销锁仓 (revokeVesting)
├── 查询可领取数量 (getClaimableAmount)
└── 提取多余代币 (withdrawExcessTokens)
```

### 依赖关系
- OpenZeppelin Contracts v5.x
- Foundry 开发框架

## 🚀 快速开始

### 环境要求
- Node.js >= 16
- Foundry
- Git

### 安装依赖

```bash
# 克隆项目
git clone <repository-url>
cd LockCoin

# 安装 Foundry 依赖
forge install

# 安装 OpenZeppelin 合约 (如果网络允许)
forge install OpenZeppelin/openzeppelin-contracts
```

### 编译和测试

```bash
# 编译合约
forge build

# 运行测试
forge test

# 运行带详细输出的测试
forge test -vvv

# 运行特定测试
forge test --match-test testLinearVestingCalculation

# 查看测试覆盖率
forge coverage
```

### 部署

```bash
# 部署到本地网络
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast

# 部署到测试网 (需要配置私钥)
forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

## 📖 使用指南

### 管理员操作

#### 1. 部署合约
```solidity
// 部署 MyToken
MyToken token = new MyToken("LockCoin", "LOCK", 1000000 * 10**18, owner);

// 部署 TokenVester
TokenVester vester = new TokenVester(token, owner);

// 转移代币到 vester 合约
token.transfer(address(vester), totalVestingAmount);
```

#### 2. 创建锁仓计划
```solidity
// 为用户创建 1 年期线性锁仓
vester.createVestingSchedule(
    beneficiary,      // 受益人地址
    1000000 * 10**18, // 锁仓总量
    block.timestamp,  // 开始时间
    365 days         // 锁仓期限
);
```

#### 3. 撤销锁仓
```solidity
// 撤销用户的锁仓计划
vester.revokeVesting(beneficiary);
```

### 用户操作

#### 1. 查询可领取数量
```solidity
uint256 claimable = vester.getClaimableAmount(userAddress);
```

#### 2. 领取代币
```solidity
// 用户调用领取函数
vester.claim();
```

#### 3. 查看锁仓信息
```solidity
TokenVester.VestingSchedule memory schedule = vester.getVestingSchedule(userAddress);
```

### 代码示例

```solidity
pragma solidity ^0.8.13;

import "./src/MyToken.sol";
import "./src/TokenVester.sol";

contract Example {
    MyToken public token;
    TokenVester public vester;
    
    function setupVesting() external {
        // 1. 部署代币
        token = new MyToken("LockCoin", "LOCK", 1000000 * 10**18, msg.sender);
        
        // 2. 部署锁仓合约
        vester = new TokenVester(token, msg.sender);
        
        // 3. 转移代币到锁仓合约
        token.transfer(address(vester), 500000 * 10**18);
        
        // 4. 为用户创建锁仓计划
        vester.createVestingSchedule(
            0x123..., // 用户地址
            100000 * 10**18, // 10万代币
            block.timestamp + 30 days, // 30天后开始
            365 days // 1年线性释放
        );
    }
}
```

## 🔒 安全考虑

### 已实现的保护机制

1. **重入攻击防护**
   - 使用 OpenZeppelin ReentrancyGuard
   - 状态更新优先于外部调用

2. **整数溢出保护**
   - Solidity 0.8+ 内置溢出检查
   - SafeERC20 安全转账

3. **访问控制**
   - 基于 Ownable 的权限管理
   - 关键函数仅限 owner 调用

4. **输入验证**
   - 自定义错误处理
   - 参数有效性检查

### 审计要点

| 风险类别 | 风险等级 | 缓解措施 |
|---------|---------|---------|
| 重入攻击 | 🟢 低 | ReentrancyGuard + 状态优先更新 |
| 整数溢出 | 🟢 低 | Solidity 0.8+ + SafeERC20 |
| 权限滥用 | 🟡 中 | 建议引入 TimelockController |
| 精度损失 | 🟡 中 | 整数除法可能导致少量精度损失 |
| 时间操控 | 🟡 中 | 依赖 block.timestamp |

### 风险提示

⚠️ **管理员权限**: Owner 拥有撤销任意用户锁仓的权限，建议在生产环境中使用多签钱包或 TimelockController

⚠️ **精度损失**: 整数除法可能导致少量代币无法提取，对于大额锁仓影响微乎其微

⚠️ **时间依赖**: 合约依赖 `block.timestamp`，矿工具有有限的时间操控能力（约15秒）

## 🧪 测试

### 测试覆盖率

项目包含 **35个测试用例**，覆盖以下场景：

- ✅ **MyToken 测试** (7个): ERC20 功能、铸造、权限控制
- ✅ **TokenVester 测试** (22个): 锁仓逻辑、安全机制、边界条件
- ✅ **集成测试** (6个): 完整流程、多用户场景、精度测试

### 运行测试命令

```bash
# 运行所有测试
forge test

# 运行特定合约测试
forge test --match-contract TokenVesterTest

# 运行特定测试函数
forge test --match-test testLinearVestingCalculation

# 运行模糊测试
forge test --match-test testFuzz

# 查看测试覆盖率
forge coverage
```

### 测试场景说明

#### 核心功能测试
- 线性释放计算准确性
- 多次领取的正确性
- 边界条件处理

#### 安全性测试
- 重入攻击防护
- 权限控制机制
- 错误条件处理

#### 集成测试
- 完整的锁仓生命周期
- 多用户独立操作
- 精度损失分析

#### 模糊测试
- 随机参数组合验证
- 边界值测试
- 算法正确性验证

## 📊 Gas 分析

| 操作 | Gas 消耗 | 说明 |
|-----|---------|------|
| 创建锁仓计划 | ~155,000 | 包含存储和事件发射 |
| 首次 claim | ~59,000 | 包含状态更新和转账 |
| 后续 claim | ~54,000 | 状态更新开销较小 |
| 撤销锁仓 | ~264,000 | 包含转账和状态清理 |
| 查询可领取数量 | ~2,500 | 纯计算，gas 消耗低 |

### Gas 优化建议

1. **批量操作**: 为多用户创建锁仓时考虑批量处理
2. **状态压缩**: 对于简单状态可考虑位图存储
3. **事件优化**: 减少不必要的事件参数

## 🔮 未来扩展

### TimelockController 集成

建议在生产环境中集成 TimelockController 来限制管理员权限：

```solidity
// 设置 TimelockController 为 owner
TimelockController timelock = new TimelockController(
    48 hours,    // 最小延迟
    proposers,   // 提案者列表
    executors    // 执行者列表
);

vester.transferOwnership(address(timelock));
```

### 建议的延迟设置
- `revokeVesting()`: 24小时延迟
- `withdrawExcessTokens()`: 48小时延迟  
- 所有权转移: 72小时延迟

### 功能扩展可能性

1. **批量操作**: 添加 `batchCreateVesting()` 和 `batchClaim()`
2. **线性解锁变体**: 支持悬崖期(cliff)的锁仓模式
3. **可升级代理**: 使用代理模式支持合约升级
4. **治理集成**: 集成 Governor 合约实现社区治理

## 🤝 贡献指南

### 开发流程

1. Fork 项目仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交变更 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

### 代码规范

- 遵循 Solidity 官方样式指南
- 添加充分的代码注释
- 为新功能编写测试用例
- 确保所有测试通过

### 报告问题

请通过 GitHub Issues 报告：
- 🐛 Bug 报告
- 💡 功能建议  
- 📚 文档改进
- 🔒 安全问题

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

---

## ⚡ 快速链接

- 📖 [合约文档](./docs/)
- 🧪 [测试报告](./test/)
- 🔧 [部署脚本](./script/)
- 💾 [合约地址](./deployments/)

---

**⚠️ 免责声明**: 本项目仅用于学习和实验目的。在生产环境使用前，请进行充分的安全审计和测试。

**🔒 安全提醒**: 智能合约一旦部署无法修改，请在主网部署前进行充分测试。

---

*Built with ❤️ using Foundry and OpenZeppelin*