# 🚀 Meme Launchpad 主网部署指南

## 📋 前置准备

### 1. 环境配置
1. 填写 `.env` 文件中的必要信息：
   ```bash
   PRIVATE_KEY=你的私钥
   PLATFORM_WALLET=平台钱包地址（用于接收手续费）
   ```

2. 确保钱包有足够的资金：
   - **Polygon 部署**: 约需 0.5-1 MATIC
   - **测试**: 约需 0.2 MATIC

### 2. 安全提醒
- ⚠️ **永远不要将真实私钥提交到 git**
- ⚠️ **建议使用测试钱包，不要使用主钱包**
- ⚠️ **部署前请在测试网验证**

## 🛠️ 部署步骤

### Polygon 主网部署

```bash
# 1. 部署合约到 Polygon 主网
forge script script/PolygonDeploy.s.sol --rpc-url polygon --broadcast --verify

# 2. 将输出的地址添加到 .env 文件
# FACTORY_ADDRESS=0x...
# TEMPLATE_ADDRESS=0x...
```

### 其他网络部署

```bash
# Ethereum 主网
forge script script/MainnetDeploy.s.sol --rpc-url ethereum --broadcast --verify

# Sepolia 测试网
forge script script/MainnetDeploy.s.sol --rpc-url sepolia --broadcast --verify
```

## 🧪 测试步骤

### 基础功能测试

```bash
# 测试代币部署和铸造功能
forge script script/PolygonTest.s.sol --rpc-url polygon --broadcast

# 测试完整流程（包括流动性和购买）
forge script script/PolygonTest.s.sol --sig "testFullFlow()" --rpc-url polygon --broadcast
```

### 主网测试

```bash
# 通用主网测试
forge script script/MainnetTest.s.sol --rpc-url <network> --broadcast

# 流动性触发测试
forge script script/MainnetTest.s.sol --sig "testLiquidityTrigger()" --rpc-url <network> --broadcast
```

## 📊 测试用例

### 测试用例 1: 基础功能
- ✅ 部署 Meme 代币
- ✅ 铸造代币
- ✅ 检查费用分配
- ✅ 验证状态更新

### 测试用例 2: 流动性触发
- ✅ 达到 0.1 ETH 阈值
- ✅ 自动添加流动性到 QuickSwap
- ✅ LP Token 锁定
- ✅ 流动性状态更新

### 测试用例 3: 完整交易流程
- ✅ 部署 → 铸造 → 流动性 → 购买
- ✅ QuickSwap 交换功能
- ✅ 价格保护机制

## 🔍 验证和监控

### 合约验证
```bash
# 自动验证（如果部署时使用了 --verify）
forge verify-contract <合约地址> <合约路径> --etherscan-api-key <API_KEY>

# 手动验证示例
forge verify-contract 0x... src/MemeFactory.sol:MemeFactory --etherscan-api-key <API_KEY>
```

### 监控要点
1. **Gas 消耗**: 确保在合理范围内
2. **交易状态**: 监控所有交易是否成功
3. **事件日志**: 验证事件正确发出
4. **余额变化**: 确认资金流转正确

## 📈 性能指标

### 预期 Gas 消耗
- **部署 MemeToken**: ~1,125,000 gas
- **部署 MemeFactory**: ~1,986,000 gas
- **deployMeme()**: ~286,000 gas
- **mintMeme()**: ~123,000 gas (不触发流动性)
- **mintMeme()**: ~650,000 gas (触发流动性)

### 网络费用估算 (Polygon)
- **部署成本**: ~0.5-1 MATIC
- **单次交易**: ~0.001-0.01 MATIC

## ⚠️ 风险提示

### 技术风险
- 智能合约漏洞
- QuickSwap 依赖风险
- 网络拥堵影响

### 经济风险
- 代币价值波动
- 流动性风险
- MEV 攻击

### 缓解措施
- 充分测试
- 代码审计
- 分阶段部署
- 监控系统

## 🆘 故障排除

### 常见问题

1. **部署失败**
   ```
   Error: Insufficient funds
   ```
   解决：确保钱包有足够的 MATIC

2. **交易失败**
   ```
   Error: execution reverted
   ```
   解决：检查参数和合约状态

3. **验证失败**
   ```
   Error: Contract verification failed
   ```
   解决：检查 API 密钥和构造函数参数

### 调试命令
```bash
# 详细日志
forge script <script> --rpc-url <url> --broadcast -vvvv

# 模拟运行（不广播）
forge script <script> --rpc-url <url>

# 检查交易状态
cast tx <transaction_hash> --rpc-url <url>
```

## 📞 支持

如遇问题，请检查：
1. 网络连接和 RPC 节点状态
2. 私钥和地址配置
3. 合约代码和参数
4. Gas 价格和限制

---

**祝您部署成功！** 🎉