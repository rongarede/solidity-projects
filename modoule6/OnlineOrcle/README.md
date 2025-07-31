# SimpleTWAPOracle - DAI/WMATIC TWAP 价格预言机

![Solidity](https://img.shields.io/badge/Solidity-^0.8.19-blue)
![Polygon](https://img.shields.io/badge/Network-Polygon-8B5CF6)
![License](https://img.shields.io/badge/License-MIT-green)

基于 Polygon 网络上的 Uniswap V2 DAI/WMATIC 交易对实现的简化版 TWAP（时间加权平均价格）预言机。

## 🚀 项目特点

- **🎯 简洁高效**: 核心逻辑约 120 行代码，易于理解和审计
- **⚡ 快速响应**: 30秒时间窗口，适合快速测试和实时应用
- **💰 低成本**: 部署在 Polygon 网络，Gas 费用极低（< 0.03 MATIC）
- **🔍 生产就绪**: 使用真实 Uniswap V2 合约，经过完整测试验证
- **🛡️ 安全可靠**: 包含完整的错误处理和边界条件检查

## 📊 实时合约信息

| 网络 | 合约地址 | 交易对 | 时间窗口 |
|------|----------|--------|----------|
| Polygon | `0xA0bAf0717EC63AE47A410eA2cdf7E19EdE636F72` | DAI/WMATIC | 30秒 |

- **交易对地址**: `0x3D93261ae1a157E691c8c1476AE379c5eb8f6E33`
- **部署者**: `0x560471591828eD5FD5c6aeE552744Ecdb6155E1d`
- **验证状态**: ✅ 已部署并测试通过

## 🏗️ 架构设计

### 核心组件

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│  Uniswap V2     │───▶│ SimpleTWAPOracle │───▶│  TWAP Price     │
│  DAI/WMATIC     │    │                  │    │  Output         │
│  Pool           │    │ • 双观察点机制     │    │                 │
└─────────────────┘    │ • 30秒时间窗口     │    └─────────────────┘
                       │ • 自动窗口滑动     │
                       └──────────────────┘
```

### 数据流程

1. **数据获取**: 从 Uniswap V2 池子获取 `price0CumulativeLast`
2. **观察点管理**: 维护两个时间戳不同的观察点
3. **TWAP 计算**: `(累积价格差) / (时间差)` = TWAP 价格
4. **结果缓存**: 自动缓存最新计算的 TWAP 价格

## 🔧 核心功能

### 智能合约接口

```solidity
interface ISimpleTWAP {
    /// @notice 获取当前 TWAP 价格 (DAI per WMATIC)
    function getPrice() external view returns (uint256);
    
    /// @notice 手动更新价格观察数据
    function update() external;
    
    /// @notice 获取最后更新时间戳
    function lastUpdateTime() external view returns (uint256);
    
    /// @notice 检查是否有足够的数据计算 TWAP
    function canComputeTWAP() external view returns (bool);
    
    /// @notice 价格更新事件
    event PriceUpdated(uint256 price, uint256 timestamp);
}
```

### TWAP 计算原理

```
TWAP = (price0CumulativeEnd - price0CumulativeStart) / (timeEnd - timeStart)

其中：
• price0CumulativeEnd: 当前 DAI 累积价格
• price0CumulativeStart: 时间窗口开始时的 DAI 累积价格  
• timeEnd: 当前时间戳
• timeStart: 时间窗口开始时间戳
• 结果: DAI per WMATIC 的 TWAP 价格（18 decimals）
```

## 📋 快速开始

### 环境准备

```bash
# 安装 Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# 克隆项目
git clone <your-repo-url>
cd OnlineOracle
forge install
```

### 配置环境变量

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑 .env 文件，填入以下信息：
# PRIVATE_KEY=0x你的私钥
# POLYGON_RPC_URL=https://polygon-rpc.com
# POLYGONSCAN_API_KEY=你的API密钥
```

### 运行测试

```bash
# 运行所有测试（使用 Polygon fork）
forge test -vv --fork-url $POLYGON_RPC_URL

# 运行特定测试
forge test --match-test testRealPairExists -vv --fork-url $POLYGON_RPC_URL
```

### 部署合约

```bash
# 部署到 Polygon 主网
source .env && forge script script/Deploy.s.sol \
  --rpc-url $POLYGON_RPC_URL \
  --broadcast \
  --verify

# 部署到 Mumbai 测试网
source .env && forge script script/Deploy.s.sol \
  --rpc-url $MUMBAI_RPC_URL \
  --broadcast \
  --verify
```

## 💡 使用示例

### 基础使用流程

```bash
# 1. 第一次初始化（设置第一个观察点）
cast send 0xA0bAf0717EC63AE47A410eA2cdf7E19EdE636F72 \
  "update()" \
  --private-key $PRIVATE_KEY \
  --rpc-url $POLYGON_RPC_URL

# 2. 等待时间窗口（30秒+）
sleep 35

# 3. 第二次更新（建立 TWAP 计算基础）
cast send 0xA0bAf0717EC63AE47A410eA2cdf7E19EdE636F72 \
  "update()" \
  --private-key $PRIVATE_KEY \
  --rpc-url $POLYGON_RPC_URL

# 4. 检查是否可以计算 TWAP
cast call 0xA0bAf0717EC63AE47A410eA2cdf7E19EdE636F72 \
  "canComputeTWAP()" \
  --rpc-url $POLYGON_RPC_URL
# 返回: 0x0000000000000000000000000000000000000000000000000000000000000001 (true)

# 5. 获取 TWAP 价格
cast call 0xA0bAf0717EC63AE47A410eA2cdf7E19EdE636F72 \
  "getPrice()" \
  --rpc-url $POLYGON_RPC_URL
# 返回: 十六进制格式的价格值
```

### Solidity 集成示例

```solidity
pragma solidity ^0.8.19;

import "./ISimpleTWAP.sol";

contract PriceConsumer {
    ISimpleTWAP public immutable oracle;
    
    constructor(address _oracle) {
        oracle = ISimpleTWAP(_oracle);
    }
    
    function getCurrentTWAPPrice() external view returns (uint256) {
        require(oracle.canComputeTWAP(), "TWAP data insufficient");
        return oracle.getPrice();
    }
    
    function updateAndGetPrice() external returns (uint256) {
        oracle.update();
        
        if (oracle.canComputeTWAP()) {
            return oracle.getPrice();
        }
        
        return 0; // 数据不足时返回 0
    }
}
```

## 🧪 测试策略

### 测试覆盖范围

| 测试类型 | 覆盖功能 | 测试文件 |
|----------|----------|----------|
| **单元测试** | 合约状态、观察点管理 | `SimpleTWAP.t.sol` |
| **集成测试** | 真实 Uniswap 数据交互 | `testRealPairExists()` |
| **边界测试** | 错误处理、异常情况 | `testGetPriceWithoutData()` |
| **时间窗口测试** | 滑动窗口机制 | `testTimeWindowBehavior()` |

### 运行完整测试套件

```bash
# Fork 测试（推荐）- 使用真实 Polygon 数据
forge test -vv --fork-url https://polygon-rpc.com

# 本地测试 - 使用模拟数据
forge test -vv

# Gas 优化测试
forge snapshot --match-contract SimpleTWAPTest
```

## 📊 技术规格

### 网络参数

- **区块链**: Polygon (Chain ID: 137)
- **Uniswap V2 Factory**: `0x800b052609c355cA8103E06F022aA30647eAd60a`
- **目标代币对**:
  - DAI: `0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063`
  - WMATIC: `0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270`

### 合约参数

- **时间窗口**: 30 秒（`TIME_WINDOW = 30`）
- **价格精度**: 18 decimals
- **更新方式**: 手动调用 `update()` 函数
- **权限控制**: 任何人都可以调用 `update()`

### Gas 使用情况

| 操作 | 预估 Gas | 实际成本 (Polygon) |
|------|----------|--------------------|
| 部署合约 | ~928,000 | ~0.027 MATIC |
| 首次 `update()` | ~45,000 | ~0.0013 MATIC |
| 后续 `update()` | ~43,000 | ~0.0012 MATIC |
| `getPrice()` | ~2,500 | 免费 (view) |

## 🔍 故障排除

### 常见问题

**Q: 为什么 `getPrice()` 返回 0？**

A: TWAP 价格为 0 是正常现象，表示在观察窗口内价格累积值没有变化。这通常发生在：
- 交易量较低的时间段
- 新部署的合约（市场数据不足）
- 价格相对稳定的情况

**Q: 为什么 `canComputeTWAP()` 返回 false？**

A: 需要满足以下条件才能计算 TWAP：
- 至少调用过 2 次 `update()`
- 两次调用之间有时间间隔
- 第一个观察点的时间戳不为 0

**Q: 如何获得非零的 TWAP 价格？**

A: 等待更长的时间窗口，让市场上发生更多交易：
```bash
# 增加等待时间到几分钟或更长
sleep 600  # 等待 10 分钟
cast send ... "update()" ...
```

### 调试工具

```bash
# 查看观察点数据
cast call <CONTRACT_ADDRESS> "firstObservation()" --rpc-url $POLYGON_RPC_URL
cast call <CONTRACT_ADDRESS> "secondObservation()" --rpc-url $POLYGON_RPC_URL

# 检查交易对是否存在
cast call 0x800b052609c355cA8103E06F022aA30647eAd60a \
  "getPair(address,address)(address)" \
  0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063 \
  0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270 \
  --rpc-url $POLYGON_RPC_URL

# 查看实时池子数据
cast call 0x3D93261ae1a157E691c8c1476AE379c5eb8f6E33 \
  "getReserves()" --rpc-url $POLYGON_RPC_URL
```

## 🔒 安全考虑

### 审计要点

1. **时间戳操作**: 使用 `block.timestamp`，注意矿工操作的潜在影响
2. **溢出保护**: Solidity ^0.8.19 内置溢出检查
3. **除零保护**: `canComputeTWAP()` 确保时间差 > 0
4. **访问控制**: `update()` 函数公开调用，符合预言机设计原则

### 最佳实践

- **定期更新**: 建议每 5-10 分钟调用一次 `update()`
- **数据验证**: 使用前检查 `canComputeTWAP()` 返回值
- **异常处理**: 在 DApp 中妥善处理价格为 0 的情况
- **多源验证**: 结合其他价格来源进行交叉验证

## 🛣️ 未来路线图

### v1.1 (计划中)
- [ ] 支持多个时间窗口（5分钟、15分钟、1小时）
- [ ] 添加价格偏差保护机制
- [ ] 实现自动更新机制（Chainlink Keepers）

### v1.2 (考虑中)
- [ ] 支持多个交易对
- [ ] 集成 Uniswap V3
- [ ] 添加历史价格查询功能

## 🤝 贡献指南

我们欢迎社区贡献！请遵循以下步骤：

1. Fork 项目到您的 GitHub
2. 创建功能分支: `git checkout -b feature/AmazingFeature`
3. 提交更改: `git commit -m 'Add AmazingFeature'`
4. 推送分支: `git push origin feature/AmazingFeature`
5. 提交 Pull Request

### 开发规范

- 所有代码必须通过测试套件
- 遵循 Solidity 最佳实践
- 添加详细的注释和文档
- 保持 Gas 使用效率

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🔗 相关链接

- **Uniswap V2 文档**: https://docs.uniswap.org/protocol/V2/introduction
- **Polygon 文档**: https://docs.polygon.technology/
- **Foundry 工具**: https://book.getfoundry.sh/
- **PolygonScan**: https://polygonscan.com/address/0xA0bAf0717EC63AE47A410eA2cdf7E19EdE636F72

## 📞 支持与联系

如有问题或建议，请：

1. 查看 [FAQ 部分](#故障排除)
2. 提交 [GitHub Issue](../../issues)
3. 参与 [Discussions](../../discussions)

---

**⚡ 由 Foundry 构建 | 🔮 基于 Uniswap V2 | 🚀 部署在 Polygon**

> *让价格预言机更简单、更可靠、更经济实用*