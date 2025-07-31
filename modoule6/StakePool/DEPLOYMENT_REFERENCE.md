# StakePool 部署脚本参考指南

## 🚀 快速部署命令

### Polygon Mumbai 测试网部署
```bash
# 基础部署（推荐用于测试）
forge script script/Deploy.s.sol \
  --rpc-url $RPC_URL_MUMBAI \
  --broadcast \
  --verify \
  --verifier-url https://api-testnet.polygonscan.com/api \
  --etherscan-api-key $POLYGONSCAN_API_KEY
```

### Polygon 主网部署
```bash
# 主网部署（生产环境）
forge script script/Deploy.s.sol \
  --rpc-url $RPC_URL_POLYGON \
  --broadcast \
  --verify \
  --verifier-url https://api.polygonscan.com/api \
  --etherscan-api-key $POLYGONSCAN_API_KEY
```

## 📋 部署后脚本

### 1. 运行演示
```bash
# 测试完整功能流程
forge script script/Demo.s.sol --rpc-url $RPC_URL_MUMBAI --broadcast
```

### 2. 监控系统状态
```bash
# 查看池子状态和统计信息
forge script script/Monitor.s.sol --rpc-url $RPC_URL_MUMBAI

# 检查系统健康状况
forge script script/Monitor.s.sol --sig "healthCheck()" --rpc-url $RPC_URL_MUMBAI

# 监控特定用户
forge script script/Monitor.s.sol --sig "monitorUser(address)" <用户地址> --rpc-url $RPC_URL_MUMBAI
```

### 3. 管理员操作
```bash
# 更新奖励率（例如改为15 KK/区块）
forge script script/Admin.s.sol --sig "updateRewardRate(uint256)" 15000000000000000000 --rpc-url $RPC_URL_MUMBAI --broadcast

# 暂停池子
forge script script/Admin.s.sol --sig "pausePool()" --rpc-url $RPC_URL_MUMBAI --broadcast

# 恢复池子
forge script script/Admin.s.sol --sig "unpausePool()" --rpc-url $RPC_URL_MUMBAI --broadcast

# 系统健康检查
forge script script/Admin.s.sol --sig "checkSystemHealth()" --rpc-url $RPC_URL_MUMBAI
```

## 🔧 环境变量设置

确保你的 `.env` 文件包含以下必要配置：

```bash
# 必需配置
PRIVATE_KEY=你的私钥（不包含0x前缀）
POLYGONSCAN_API_KEY=你的polygonscan_api_key

# 部署后自动生成的地址
MOCKWETH_ADDRESS=部署后的WETH合约地址
KKTOKEN_ADDRESS=部署后的KK代币合约地址
STAKINGPOOL_ADDRESS=部署后的质押池合约地址
ADMIN_ADDRESS=管理员地址

# 可选配置
REWARD_PER_BLOCK=10000000000000000000  # 10 KK tokens per block
SKIP_VERIFICATION=false
```

## 📁 部署后生成的文件

部署完成后，系统会自动生成以下文件：

- `deployments.txt` - 简单的合约地址列表
- `deployment_info.json` - 详细的部署信息（JSON格式）
- `.env.deployed` - 环境变量模板（用于前端集成）

## 🎯 常用操作示例

### 用户交互

#### 质押 ETH
```bash
# 质押 1 ETH
cast send $STAKINGPOOL_ADDRESS "stakeETH()" --value 1000000000000000000 --private-key $PRIVATE_KEY --rpc-url $RPC_URL_MUMBAI
```

#### 查看待领取奖励
```bash
# 查看用户待领取的KK代币
cast call $STAKINGPOOL_ADDRESS "pendingKK(address)" <用户地址> --rpc-url $RPC_URL_MUMBAI
```

#### 领取奖励
```bash
# 领取奖励（不解除质押）
cast send $STAKINGPOOL_ADDRESS "harvest()" --private-key $PRIVATE_KEY --rpc-url $RPC_URL_MUMBAI
```

#### 解除质押
```bash
# 解除质押1 ETH并以ETH形式提取
cast send $STAKINGPOOL_ADDRESS "unstake(uint256,bool)" 1000000000000000000 true --private-key $PRIVATE_KEY --rpc-url $RPC_URL_MUMBAI
```

### 管理员操作

#### 更新奖励率
```bash
# 将奖励率改为20 KK tokens per block
cast send $STAKINGPOOL_ADDRESS "updateRewardPerBlock(uint256)" 20000000000000000000 --private-key $PRIVATE_KEY --rpc-url $RPC_URL_MUMBAI
```

#### 授予铸币权限
```bash
# 给新地址授予KK代币铸币权限
cast send $KKTOKEN_ADDRESS "grantMinterRole(address)" <新铸币者地址> --private-key $PRIVATE_KEY --rpc-url $RPC_URL_MUMBAI
```

## 🔍 监控和分析

### 实时监控
```bash
# 每5分钟运行一次监控脚本
watch -n 300 'forge script script/Monitor.s.sol --rpc-url $RPC_URL_MUMBAI'
```

### 导出数据
```bash
# 导出池子数据（JSON格式）
forge script script/Monitor.s.sol --sig "exportData()" --rpc-url $RPC_URL_MUMBAI
```

### Gas 费用估算
```bash
# 查看操作的预估gas费用
forge script script/Monitor.s.sol --sig "estimateGasCosts()" --rpc-url $RPC_URL_MUMBAI
```

## 🚨 紧急操作

### 暂停系统
```bash
# 紧急暂停所有操作
forge script script/Admin.s.sol --sig "pausePool()" --rpc-url $RPC_URL_MUMBAI --broadcast
```

### 强制更新池子
```bash
# 如果池子长时间未更新，强制更新奖励
forge script script/Admin.s.sol --sig "emergencyUpdatePool()" --rpc-url $RPC_URL_MUMBAI --broadcast
```

### 紧急提取
用户可以使用紧急提取功能（会放弃奖励）：
```bash
cast send $STAKINGPOOL_ADDRESS "emergencyWithdraw()" --private-key $PRIVATE_KEY --rpc-url $RPC_URL_MUMBAI
```

## 📊 重要指标监控

定期检查以下指标：

1. **池子健康状况**：`forge script script/Admin.s.sol --sig "checkSystemHealth()"`
2. **总质押量**：应该等于池子中的WETH余额
3. **奖励分发**：确保pending rewards计算正确
4. **权限状态**：确保StakingPool有KK代币的铸币权限
5. **Gas使用情况**：监控transaction成本

## 🛠 故障排除

### 常见问题

1. **部署失败**：检查PRIVATE_KEY和RPC_URL配置
2. **验证失败**：确保POLYGONSCAN_API_KEY正确
3. **权限错误**：确保管理员地址有正确的角色
4. **会计不匹配**：运行健康检查找出问题

### 获取帮助
- 查看部署日志获取错误信息
- 使用Monitor脚本检查系统状态
- 运行健康检查诊断问题

## 🔗 有用的链接

- [Polygon Mumbai 测试网浏览器](https://mumbai.polygonscan.com/)
- [Polygon 主网浏览器](https://polygonscan.com/)
- [Mumbai 测试币水龙头](https://faucet.polygon.technology/)
- [PolygonScan API文档](https://docs.polygonscan.com/)

---

**重要提醒**：
- 始终先在测试网测试
- 保护好你的私钥
- 定期监控系统健康状况
- 备份重要的配置和地址信息