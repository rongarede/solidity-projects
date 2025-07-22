# Uniswap V2 Polygon 链迁移任务清单

## 项目概览
将现有的 Base 链 Uniswap V2 DApp 迁移到 Polygon 链，实现 **99% Gas 费用降低**（从 $3 降至 $0.03）

## 阶段一：环境准备

### 1.1 Polygon 网络配置
- [ ] 配置 Polygon 主网连接
  - [ ] 网络名称：Polygon Mainnet
  - [ ] RPC URL：https://polygon-rpc.com
  - [ ] Chain ID：137
  - [ ] 货币符号：MATIC
  - [ ] 区块浏览器：https://polygonscan.com


## 阶段二：使用现有合约部署到 Polygon

### 2.1 Foundry 配置更新
- [ ] 更新 `foundry.toml` 配置
  - [ ] 添加 Polygon 网络配置
  - [ ] 设置 RPC 端点：https://polygon-rpc.com
  - [ ] 配置 gas 价格：30 gwei（Polygon 典型值）
- [ ] 验证配置
  - [ ] 运行 `forge build` 确认编译正常
  - [ ] 测试网络连接

### 2.2 使用现有部署脚本
- [ ] 直接使用现有的部署脚本（无需修改合约代码）
  - [ ] 使用 `script/DeployFactory.s.sol` 
  - [ ] 使用 `script/DeployRouter.s.sol`
- [ ] 部署自定义测试代币到 Polygon
  - [ ] 部署 MockWETH 到 Polygon（保持与 Base 版本功能一致）
  - [ ] 记录 MockWETH 在 Polygon 上的新地址
- [ ] 调整部署参数
  - [ ] 使用我们部署的 MockWETH 地址（而非 Polygon 官方 WMATIC）
  - [ ] 调整网络参数为 Polygon

### 2.3 合约部署执行
- [ ] 首先部署 Factory 合约
  - [ ] 执行：`forge script script/DeployFactory.s.sol --rpc-url https://polygon-rpc.com --broadcast --verify`
  - [ ] 记录 Factory 合约地址
- [ ] 部署自定义测试代币
  - [ ] 部署 MockWETH 到 Polygon（保持与 Base 版本一致的功能）
  - [ ] 部署 TestTokenA 和 TestTokenB（使用现有代币合约）
  - [ ] 记录所有代币合约地址
- [ ] 最后部署 Router 合约
  - [ ] 使用 Factory 地址和我们部署的 MockWETH 地址
  - [ ] 执行：`forge script script/DeployRouter.s.sol --rpc-url https://polygon-rpc.com --broadcast --verify`
  - [ ] 记录 Router 合约地址

### 2.4 合约地址配置
- [ ] 创建 `contracts-addresses-polygon.json`
  - [ ] 记录所有部署的合约地址
  - [ ] 包含部署交易哈希和区块号
  - [ ] 记录 gas 使用量对比
- [ ] 验证合约在 PolygonScan 上可见
  - [ ] 确认合约源码验证成功
  - [ ] 检查合约功能正常

## 阶段三：前端适配 Polygon

### 3.1 网络配置修改
- [ ] 更新 `v2-frontend/src/lib/wagmi.ts`
  - [ ] 将 `base` 替换为 `polygon`
  - [ ] 导入：`import { polygon } from 'wagmi/chains'`
  - [ ] 更新 RPC URL：https://polygon-rpc.com
- [ ] 更新 `v2-frontend/src/lib/viem.ts`（如存在）
  - [ ] 配置 Polygon 网络客户端

### 3.2 合约地址配置更新
- [ ] 更新 `v2-frontend/src/lib/contracts.ts`
  - [ ] 将 Base 合约地址替换为 Polygon 地址
  - [ ] 使用 `contracts-addresses-polygon.json` 中的地址
  - [ ] 保持 ABI 不变（已使用 parseAbi）
- [ ] 验证合约地址格式正确
  - [ ] 确认所有地址为有效的以太坊地址格式

### 3.3 代币配置适配
- [ ] 创建和部署自定义测试代币（而非使用 WMATIC）
  - [ ] 部署自定义 MockWETH 到 Polygon（保持与 Base 版本一致）
  - [ ] 或创建新的测试代币（如 TestWETH、MockToken）
  - [ ] 确保代币具有 deposit/withdraw 功能（模拟 WETH 行为）
- [ ] 更新 `v2-frontend/src/lib/tokens.ts`
  - [ ] 使用我们部署的自定义代币地址
  - [ ] 保持代币符号和名称的一致性
  - [ ] 更新代币地址为 Polygon 上的部署地址
- [ ] 更新默认代币列表
  - [ ] 添加我们部署的测试代币（TestTokenA、TestTokenB、自定义WETH）
  - [ ] 移除 Base 特定代币，但保持代币类型一致

### 3.4 UI 文本更新
- [ ] 更新网络显示名称
  - [ ] 页面标题显示 "Polygon" 而非 "Base"
  - [ ] 钱包连接提示更新为 Polygon 网络
- [ ] 更新代币单位显示
  - [ ] Gas 费用显示为 MATIC 而非 ETH
  - [ ] 原生代币显示为 MATIC

## 阶段四：测试验证

### 4.1 基础功能测试
- [ ] 钱包连接测试
  - [ ] 验证 MetaMask 可以连接 Polygon 网络
  - [ ] 确认地址和余额正确显示
- [ ] 代币余额查询测试
  - [ ] 验证 MATIC 余额显示
  - [ ] 测试 ERC20 代币余额查询

### 4.2 交易功能测试
- [ ] 代币授权（Approve）测试
  - [ ] 测试 ERC20 代币授权 Router
  - [ ] 验证授权交易费用（应该 < $0.01）
- [ ] 添加流动性测试
  - [ ] 测试 addLiquidity 功能
  - [ ] 测试 addLiquidityETH 功能（使用 WMATIC）
  - [ ] 记录 gas 费用
- [ ] 代币交换测试
  - [ ] 测试各种交换组合
  - [ ] 验证价格计算准确性
  - [ ] 记录交易费用

### 4.3 Gas 费用对比分析
- [ ] 记录 Polygon 交易费用
  - [ ] 代币授权费用
  - [ ] 添加流动性费用
  - [ ] 代币交换费用
- [ ] 对比 Base 链费用
  - [ ] 制作费用对比表格
  - [ ] 计算节省百分比
  - [ ] 记录到文档中

### 4.4 性能基准测试
- [ ] 交易确认时间测试
  - [ ] 记录交易提交到确认的时间
  - [ ] 对比网络拥堵情况下的表现
- [ ] 批量操作测试
  - [ ] 测试多笔交易的处理能力
  - [ ] 验证网络稳定性

## 阶段五：文档和部署优化

### 5.1 README 文档更新
- [ ] 更新 `v2-core/README.md`
  - [ ] 添加 Polygon 部署说明
  - [ ] 包含合约地址和验证链接
  - [ ] 添加 gas 费用对比数据
- [ ] 更新 `v2-frontend/README.md`
  - [ ] 更新网络配置说明
  - [ ] 添加 Polygon 特定设置步骤

### 5.2 部署脚本优化
- [ ] 创建一键部署脚本
  - [ ] 组合所有部署步骤
  - [ ] 包含错误处理和重试机制
- [ ] 创建验证脚本
  - [ ] 自动验证所有合约功能
  - [ ] 生成部署报告

### 5.3 迁移指南编写
- [ ] 创建 `MIGRATION_TO_POLYGON.md`
  - [ ] 详细的迁移步骤
  - [ ] 常见问题和解决方案
  - [ ] Base 到 Polygon 的对比分析

## 阶段六：生产环境准备

### 6.1 安全检查
- [ ] 合约安全审计
  - [ ] 验证合约代码与 Base 版本一致
  - [ ] 检查配置参数正确性
- [ ] 私钥安全
  - [ ] 确认部署私钥安全存储
  - [ ] 生产环境使用独立私钥

### 6.2 监控和日志
- [ ] 设置交易监控
  - [ ] 监控合约交互
  - [ ] 设置错误报警
- [ ] 更新前端错误日志
  - [ ] 适配 Polygon 特定错误
  - [ ] 记录网络相关问题

## 完成标准

### 功能完整性
- ✅ 所有 Base 版本功能在 Polygon 上正常工作
- ✅ 用户界面完全适配 Polygon 网络
- ✅ 交易费用显著降低（目标：99% 降幅）

### 性能指标
- ✅ 交易确认时间 < 5 秒
- ✅ 添加流动性费用 < $0.05
- ✅ 代币交换费用 < $0.03
- ✅ 代币授权费用 < $0.01

### 文档完备性
- ✅ 部署文档完整且可执行
- ✅ 用户迁移指南清晰明了
- ✅ 费用对比数据准确记录

## 预估时间和成本

### 开发时间
- **阶段一：环境准备** - 0.5 天
- **阶段二：合约部署** - 1 天
- **阶段三：前端适配** - 1 天
- **阶段四：测试验证** - 1 天
- **阶段五-六：文档优化** - 0.5 天

**总预估时间：4 天**

### 成本预估
- **合约部署费用**：约 10-20 MATIC（$5-10）
- **测试交易费用**：约 5-10 MATIC（$2-5）
- **总成本**：约 15-30 MATIC（$7-15）

## 风险评估

### 技术风险
- **低风险**：Solidity 代码完全兼容
- **低风险**：viem/wagmi 支持 Polygon
- **中风险**：WMATIC 集成需要测试验证

### 业务风险
- **低风险**：用户需要少量 MATIC 作为 gas
- **机会**：显著降低使用门槛，吸引更多用户

## 成功指标

1. **费用降低**：交易费用从 $3 降至 $0.03
2. **功能保持**：所有功能无损迁移
3. **用户体验**：更低门槛，更快确认
4. **可维护性**：清晰的文档和部署流程