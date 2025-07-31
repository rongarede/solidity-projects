# StakePool - ETH质押挖矿系统

一个基于Solidity构建的去中心化ETH质押挖矿系统，用户可以质押ETH获得KK代币奖励。

## 🎯 项目概述

StakePool是一个MasterChef风格的质押挖矿系统，允许用户质押ETH并按区块获得KK代币奖励。系统设计简洁高效，具备完整的权限管理和安全保护机制。

### 核心功能
- ✅ ETH质押和解质押
- ✅ 按区块自动分发KK代币奖励
- ✅ 奖励实时累积和领取
- ✅ 基于角色的权限管理
- ✅ 重入攻击防护
- ✅ 完整的事件日志记录

## 📋 合约架构

### 核心合约

| 合约 | 地址 | 描述 |
|------|------|------|
| MockWETH | `0xeC71AC24A7ca460dd8bb031CA84Cd69BEA1D79A1` | 模拟WETH代币合约 |
| KKToken | `0x94F7d01a053b4Cc7d961FA7cCad489171BEf0f02` | 奖励代币合约 |
| StakingPool | `0xFe4cB79734236F748e53d7Bb7f5130747c7909d6` | 主质押池合约 |

### 系统参数
- **奖励速率**: 10 KK tokens / 区块
- **支持代币**: ETH (通过WETH包装)
- **网络**: Polygon Mainnet (Chain ID: 137)
- **精度**: 18位小数

## 🚀 快速开始

### 环境要求
- Node.js >= 16
- Foundry >= 0.2.0
- Git

### 安装依赖
```bash
# 克隆项目
git clone <repository-url>
cd StakePool

# 安装Foundry依赖
forge install

# 编译合约
forge build
```

### 配置环境
1. 复制环境配置文件：
```bash
cp .env.example .env
```

2. 编辑`.env`文件，填入必要信息：
```bash
# 部署私钥（无0x前缀）
PRIVATE_KEY=your_private_key_here

# RPC节点
RPC_URL_POLYGON=wss://polygon.drpc.org

# PolygonScan API密钥（用于合约验证）
POLYGONSCAN_API_KEY=your_api_key_here
```

### 运行测试
```bash
# 运行所有测试
forge test

# 运行详细测试报告
forge test -vvv

# 生成覆盖率报告
forge coverage
```

## 📖 使用指南

### 用户操作

#### 1. 质押ETH
```solidity
// 直接发送ETH到合约地址进行质押
stakingPool.stakeETH{value: 1 ether}();
```

#### 2. 查看奖励
```solidity
// 查看待领取奖励
uint256 pending = stakingPool.pendingReward(userAddress);
```

#### 3. 领取奖励
```solidity
// 领取累积奖励
stakingPool.harvest();
```

#### 4. 解质押
```solidity
// 解质押指定数量的ETH
stakingPool.unstake(0.5 ether);
```

### 管理员操作

#### 更新奖励速率
```solidity
// 需要ADMIN_ROLE权限
stakingPool.updateRewardPerBlock(20 * 10**18); // 改为每区块20个KK
```

#### 紧急暂停
```solidity
// 暂停质押功能
stakingPool.pause();

// 恢复质押功能
stakingPool.unpause();
```

## 🧪 测试和部署

### 本地测试
```bash
# 启动本地节点
anvil

# 部署到本地网络
forge script script/MinimalDeploy.s.sol --rpc-url http://127.0.0.1:8545 --broadcast
```

### 部署到Polygon
```bash
# 部署到Polygon主网
forge script script/MinimalDeploy.s.sol --rpc-url $RPC_URL_POLYGON --broadcast --verify

# 验证部署
forge script script/QuickTest.s.sol --rpc-url $RPC_URL_POLYGON
```

### 演示脚本
```bash
# 运行完整功能演示
forge script script/Demo.s.sol --rpc-url $RPC_URL_POLYGON --broadcast
```

## 📊 系统监控

### 重要指标
- **总质押量**: 所有用户质押的ETH总量
- **奖励速率**: 每区块分发的KK代币数量
- **参与用户数**: 当前有质押的用户数量
- **池子年化收益率**: 基于当前奖励速率和ETH价格的APR

### 查看系统状态
```bash
# 使用监控脚本查看池子状态
forge script script/Monitor.s.sol --rpc-url $RPC_URL_POLYGON
```

## 🔒 安全考虑

### 已实现的安全措施
- ✅ **重入攻击防护**: 使用OpenZeppelin的ReentrancyGuard
- ✅ **权限控制**: 基于角色的访问控制(RBAC)
- ✅ **整数溢出保护**: 使用Solidity 0.8+的内置检查
- ✅ **状态一致性**: 严格的状态更新顺序
- ✅ **事件日志**: 完整的操作记录

### 潜在风险
- ⚠️ **通胀风险**: KK代币无供应上限，长期可能面临通胀压力
- ⚠️ **中心化风险**: 管理员具有较大权限（奖励速率、暂停等）
- ⚠️ **区块操纵**: 理论上矿工可能操纵区块号影响奖励计算
- ⚠️ **智能合约风险**: 代码可能存在未发现的漏洞

### 风险缓解建议
1. **多签治理**: 使用多签钱包管理关键权限
2. **时间锁**: 重要参数变更实施延时生效
3. **供应上限**: 考虑为KK代币设置最大供应量
4. **定期审计**: 定期进行第三方安全审计

## 📈 Gas优化

### 已实现的优化
- 合理使用`memory`vs`storage`
- 批量状态更新减少SSTORE操作
- 精确的奖励计算避免不必要的循环
- 事件参数indexed优化查询效率

### Gas成本估算
| 操作 | 预估Gas消耗 |
|------|-----------|
| 首次质押 | ~150,000 |
| 追加质押 | ~80,000 |
| 领取奖励 | ~70,000 |
| 解质押 | ~90,000 |
| 更新奖励速率 | ~50,000 |

## 🛠 开发工具

### 脚本说明
- `Deploy.s.sol`: 完整部署脚本
- `MinimalDeploy.s.sol`: 最小化部署脚本
- `QuickTest.s.sol`: 部署验证脚本
- `Demo.s.sol`: 功能演示脚本
- `Monitor.s.sol`: 系统监控脚本
- `Admin.s.sol`: 管理操作脚本

### 开发命令
```bash
# 编译
forge build

# 测试
forge test

# 格式化代码
forge fmt

# 生成文档
forge doc --build
```

## 📚 技术文档

- [API文档](./API.md) - 详细的函数接口说明
- [架构文档](./ARCHITECTURE.md) - 系统架构和设计说明
- [安全分析](./SECURITY_ANALYSIS.md) - 安全风险分析和缓解方案

## 🔗 相关链接

### 区块链浏览器
- [MockWETH合约](https://polygonscan.com/address/0xeC71AC24A7ca460dd8bb031CA84Cd69BEA1D79A1)
- [KKToken合约](https://polygonscan.com/address/0x94F7d01a053b4Cc7d961FA7cCad489171BEf0f02)
- [StakingPool合约](https://polygonscan.com/address/0xFe4cB79734236F748e53d7Bb7f5130747c7909d6)

### 开发资源
- [Foundry文档](https://book.getfoundry.sh/)
- [OpenZeppelin合约](https://docs.openzeppelin.com/contracts/)
- [Polygon网络](https://polygon.technology/)

## 🤝 贡献指南

1. Fork本项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启Pull Request

### 贡献规范
- 遵循现有代码风格
- 为新功能添加测试
- 更新相关文档
- 确保所有测试通过

## 📄 许可证

本项目采用MIT许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## ❓ 常见问题

### Q: 如何查看我的质押余额？
A: 调用`stakingPool.userInfo(your_address)`查看质押信息。

### Q: 奖励什么时候开始计算？
A: 从质押交易所在区块的下一个区块开始计算奖励。

### Q: 可以部分解质押吗？
A: 可以，调用`unstake(amount)`指定解质押数量。

### Q: 合约升级会影响我的资金吗？
A: 当前合约不可升级，资金安全由合约代码保证。

## 📞 联系方式

- 项目维护者: [Your Name]
- 邮箱: your.email@example.com
- 电报群: [Telegram Group]
- Discord: [Discord Server]

---

**⚡ 免责声明**: 本项目仅用于学习和研究目的。在主网使用前请充分了解风险并考虑进行专业审计。使用本合约造成的任何损失，开发团队不承担责任。