# UUPS Meme Token Factory

一个基于 UUPS (Universal Upgradeable Proxy Standard) 代理模式的 Meme 代币工厂合约项目。

## 项目概述

本项目实现了一个可升级的 Meme 代币工厂，允许用户部署和管理自定义的 Meme 代币。工厂合约使用 UUPS 代理模式确保合约的可升级性，同时提供完整的代币生命周期管理功能。

## 核心功能

### MemeFactory (工厂合约)
- 📦 **代币部署**: 创建新的 Meme 代币实例
- 💰 **付费铸造**: 用户通过支付 ETH 铸造代币
- 🏦 **平台分成**: 自动收取 1% 平台费用
- 📊 **代币追踪**: 跟踪所有已部署的代币
- 💸 **收益提取**: 平台 owner 可提取累计收益

### MemeToken (代币合约)
- 🔄 **UUPS 可升级**: 支持合约逻辑升级
- ⚡ **ERC20 兼容**: 完全兼容 ERC20 标准
- 🎯 **供应量控制**: 设置最大总供应量和单次铸造限制
- 💎 **动态定价**: 发行者可更新代币价格
- 🔒 **权限管理**: 基于角色的访问控制

## 合约架构

```
MemeFactory (工厂合约)
├── 部署 MemeToken 代理实例
├── 管理铸造流程
├── 处理支付和分成
└── 跟踪代币列表

MemeToken (UUPS 可升级代币)
├── ERC20 标准实现
├── 可升级代理模式
├── 供应量管理
└── 价格控制
```

## 技术特性

### UUPS 代理模式
- **可升级性**: 合约逻辑可以升级而不改变地址
- **Gas 优化**: 相比透明代理更节省 Gas
- **安全性**: 升级权限由合约本身控制

### 经济模型
- **平台费率**: 1% (可在合约中调整)
- **收益分配**: 99% 给发行者，1% 给平台
- **动态定价**: 发行者可实时调整代币价格

## 部署参数

部署新 Meme 代币时需要提供以下参数：

| 参数 | 类型 | 描述 |
|------|------|------|
| `symbol` | string | 代币符号 (如 "MEME") |
| `totalSupply` | uint256 | 最大总供应量 |
| `perMint` | uint256 | 单次最大铸造数量 |
| `price` | uint256 | 每个 wei 的价格 (以 wei 计) |

## 使用示例

### 部署新代币
```solidity
address tokenAddress = factory.deployMeme(
    "DOGE",           // 符号
    1000 * 10**18,    // 总供应量: 1000 代币
    10 * 10**18,      // 单次铸造限制: 10 代币
    10                // 价格: 每 wei 10 wei
);
```

### 铸造代币
```solidity
uint256 amount = 5 * 10**18;  // 铸造 5 个代币
uint256 cost = amount * 10;   // 计算费用
factory.mintMeme{value: cost}(tokenAddress, amount);
```

### 更新价格
```solidity
// 仅发行者可调用
token.updatePrice(20);  // 更新为每 wei 20 wei
```

## 测试覆盖

项目包含 13 个全面的测试用例：

### 核心功能测试
- ✅ 代币部署功能
- ✅ 代币铸造机制
- ✅ 价格更新功能
- ✅ 平台收益提取

### 安全性测试
- ✅ 权限控制验证
- ✅ 支付验证
- ✅ 供应量限制
- ✅ 单次铸造限制

### 边界条件测试
- ✅ 空符号部署失败
- ✅ 零供应量部署失败
- ✅ 最大供应量达到限制
- ✅ 代币转账功能

## 目录结构

```
UUPS/
├── src/
│   ├── MemeFactory.sol      # 工厂合约
│   └── MemeToken.sol        # 可升级代币合约
├── test/
│   └── MemeTokenTest.t.sol  # 测试文件
├── script/
│   └── Deploy.s.sol         # 部署脚本
├── lib/                     # 依赖库
│   └── openzeppelin-contracts/
└── foundry.toml            # Foundry 配置
```

## 安装和运行

### 前置要求
- [Foundry](https://getfoundry.sh/)
- Git

### 安装依赖
```bash
git clone <repository-url>
cd UUPS
forge install
```

### 编译合约
```bash
forge build
```

### 运行测试
```bash
forge test -vvv
```

### 部署合约
```bash
forge script script/Deploy.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

## 安全考虑

### 已实现的安全措施
- ✅ 重入攻击防护 (`ReentrancyGuard`)
- ✅ 权限访问控制 (`Ownable`)
- ✅ 输入参数验证
- ✅ 溢出保护 (Solidity 0.8+)
- ✅ 支付验证和退款机制

### 升级安全
- 仅发行者可升级代币合约
- 工厂合约由 owner 控制
- 初始化保护防止重复初始化

## Gas 优化

- 使用 UUPS 代理模式减少部署成本
- 批量操作支持
- 优化的存储布局
- 事件日志用于链下查询

## 合约地址

部署后的合约地址将显示在这里：

```
MemeFactory: 0x...
MemeToken Implementation: 0x...
```

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

---

*注意: 本项目仅用于教育和演示目的，请在生产环境中使用前进行充分的安全审计。*