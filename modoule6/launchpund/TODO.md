# 🚀 Meme Launchpad 开发任务清单

## 项目目标
在 EVM 链上搭建一个最小代理 Meme 代币发行平台，集成 Uniswap V2 自动流动性，提供 deploy / mint / buy 三大功能。

> **注**: 架构设计已在 CLAUDE.md 中完成，直接进入实现阶段。

---

## 📂 一、环境搭建与项目结构

### 1.1 项目结构创建
- [ ] 创建 `contracts/` 目录 - 存放 Solidity 源码
- [ ] 创建 `interfaces/` 目录 - 存放 Uniswap 等外部接口
- [ ] 创建 `script/` 目录 - 存放 Foundry 部署脚本 (*.s.sol)
- [ ] 创建 `test/` 目录 - 存放 Foundry 测试脚本 (*.t.sol)

### 1.2 环境验证
- [ ] 验证 Foundry 安装: `forge --version`
- [ ] 验证 Git 初始化: `git status`
- [ ] 运行 `forge build` 确保环境正常

---

## 💻 二、合约开发 (核心实现)

### 2.1 接口文件创建
- [ ] 创建 `interfaces/IUniswapV2Router02.sol`
- [ ] 创建 `interfaces/IUniswapV2Factory.sol`
- [ ] 创建 `interfaces/IUniswapV2Pair.sol`
- [ ] 创建 `interfaces/IMemeToken.sol`

### 2.2 MemeToken 合约实现
- [ ] 创建 `contracts/MemeToken.sol`
- [ ] 导入 OpenZeppelin: ERC20, Ownable
- [ ] 定义 TokenConfig 结构体
- [ ] 实现 initialize() 函数 (支持克隆)
- [ ] 实现 mint() 函数 (仅工厂可调用)
- [ ] 实现 getTokenInfo() 查询函数
- [ ] 添加 onlyFactory 修饰符

### 2.3 MemeFactory 合约实现
- [ ] 创建 `contracts/MemeFactory.sol`
- [ ] 导入 OpenZeppelin: Clones, ReentrancyGuard, Ownable
- [ ] 定义状态变量 (TEMPLATE, ROUTER, WETH, platformWallet)
- [ ] 实现 deployMeme() 函数:
  - [ ] 参数验证
  - [ ] 使用 Clones.cloneDeterministic()
  - [ ] 初始化代币
  - [ ] 更新映射状态
- [ ] 实现 mintMeme() 函数:
  - [ ] 支付验证
  - [ ] 代币铸造
  - [ ] ETH 分配 (95%/5%)
  - [ ] 流动性处理
- [ ] 实现 buyMeme() 函数:
  - [ ] 价格检查
  - [ ] Uniswap 交换
  - [ ] 代币转账

### 2.4 编译验证
- [ ] 运行 `forge build` 确保编译通过
- [ ] 检查编译警告并修复
- [ ] 验证 ABI 生成正确

---

## 🔗 三、Uniswap 集成

### 3.1 Router 配置
- [ ] 在 MemeFactory 构造函数中设置 Router 地址:
  - [ ] 主网: `0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D`
  - [ ] Polygon: `0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff` (QuickSwap)
  - [ ] Sepolia: `0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008`
- [ ] 设置对应的 WETH/WMATIC 地址:
  - [ ] 主网 WETH: `0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2`
  - [ ] Polygon WMATIC: `0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270`
  - [ ] Sepolia WETH: `0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9`
- [ ] 验证地址有效性

### 3.2 流动性管理实现
- [ ] 实现 `_addInitialLiquidity()` 内部函数:
  - [ ] 计算代币数量 (基于初始价格)
  - [ ] 铸造代币给合约
  - [ ] 批准 Router 使用代币
  - [ ] 调用 addLiquidityETH()
  - [ ] LP Token 锁定在合约中
- [ ] 实现流动性触发条件:
  - [ ] 检查是否首次添加
  - [ ] 验证 ETH 数量阈值 (0.1 ETH)
  - [ ] 更新流动性状态

### 3.3 价格查询实现
- [ ] 实现 `_getCurrentPrice()` 函数:
  - [ ] 获取 Pair 地址
  - [ ] 读取 reserves
  - [ ] 计算价格比率
- [ ] 实现价格比较逻辑:
  - [ ] 获取初始价格
  - [ ] 比较当前价格
  - [ ] 验证价格优势

### 3.4 本地验证
- [ ] 启动 Anvil: `anvil`
- [ ] 或配置 Polygon Fork: `anvil --fork-url https://polygon-rpc.com`
- [ ] 手动调用 Router 接口验证:
  - [ ] 测试 addLiquidityETH (Polygon 上为 addLiquidityMATIC)
  - [ ] 测试 swapExactETHForTokens
  - [ ] 验证交易执行成功

---

## 🧪 四、测试编写

### 4.1 配置测试环境
- [ ] 配置 `foundry.toml`:
  - [ ] 设置 Solidity 版本 (0.8.19+)
  - [ ] 配置 optimizer
  - [ ] 设置 gas limit
  - [ ] 配置 RPC URLs (重点配置 Polygon RPC)
- [ ] 安装测试依赖

### 4.2 基础测试脚本
- [ ] 创建 `test/MemeFactory.t.sol`
- [ ] 实现 `setUp()` 函数:
  - [ ] 部署 MemeToken 模板
  - [ ] 部署 MemeFactory
  - [ ] 配置 QuickSwap Router 和 WMATIC (Polygon)
  - [ ] 创建测试用户地址

### 4.3 deployMeme 测试
- [ ] 测试正常部署:
  - [ ] 验证代币地址非零
  - [ ] 检查映射记录正确
  - [ ] 验证事件发出
- [ ] 测试参数验证:
  - [ ] 无效符号长度
  - [ ] 零值参数
  - [ ] 重复符号
- [ ] 测试边界条件:
  - [ ] 最大/最小值
  - [ ] 极端参数组合

### 4.4 mintMeme 测试
- [ ] 测试正常铸造:
  - [ ] 验证用户余额增加
  - [ ] 检查 ETH 分配正确 (95%/5%)
  - [ ] 确认事件发出
- [ ] 测试流动性添加:
  - [ ] 模拟达到阈值 (0.1 ETH)
  - [ ] 验证 LP 创建
  - [ ] 检查流动性状态更新
- [ ] 测试错误情况:
  - [ ] 支付金额错误
  - [ ] 超过总供应量
  - [ ] 无效代币地址

### 4.5 buyMeme 测试
- [ ] 设置 Fork 测试环境:
  - [ ] 配置 Polygon Fork
  - [ ] 准备测试资金 (MATIC)
- [ ] 测试正常购买:
  - [ ] 验证代币到账
  - [ ] 检查 ETH 扣除
  - [ ] 确认交换成功
- [ ] 测试价格保护:
  - [ ] 模拟价格不利情况
  - [ ] 验证交易被拒绝
- [ ] 测试边界条件:
  - [ ] 无流动性情况
  - [ ] 极小金额交换

### 4.6 集成测试
- [ ] 完整流程测试:
  - [ ] 部署 → 铸造 → 添加流动性 → 购买
  - [ ] 多用户并发测试
  - [ ] 长期运行测试

### 4.7 测试执行与分析
- [ ] 本地测试: `forge test -vvv`
- [ ] Fork 测试: `forge test --fork-url https://polygon-rpc.com -vvv`
- [ ] Gas 分析: `forge test --gas-report`
- [ ] 覆盖率测试: `forge coverage`
- [ ] 分析测试结果:
  - [ ] 检查断言通过率
  - [ ] 分析 Gas 消耗
  - [ ] 识别性能瓶颈
  - [ ] 记录测试报告

---

## 📊 五、部署与验证

### 5.1 部署脚本编写
- [ ] 创建 `script/Deploy.s.sol`
- [ ] 实现部署逻辑:
  - [ ] 部署 MemeToken 模板
  - [ ] 部署 MemeFactory
  - [ ] 验证初始化参数
- [ ] 配置网络参数:
  - [ ] 主网配置
  - [ ] Polygon 配置 (主要测试网络)
  - [ ] 测试网配置

### 5.2 本地部署测试
- [ ] 在 Anvil 上部署
- [ ] 测试基本功能
- [ ] 验证合约交互

### 5.3 Polygon 部署
- [ ] 部署到 Polygon 主网
- [ ] 验证合约代码
- [ ] 测试完整流程 (使用 QuickSwap)

### 5.4 文档完善
- [ ] 更新 README.md
- [ ] 完善 API 文档
- [ ] 编写使用指南
- [ ] 记录部署地址

---

## ✅ 验收标准

### 功能验收
- [ ] deployMeme: 成功创建新的 Meme 代币
- [ ] mintMeme: 正确分配 ETH 并铸造代币
- [ ] buyMeme: 通过 Uniswap 成功购买代币
- [ ] 自动流动性: 达到条件时自动添加 LP

### 安全验收
- [ ] 重入攻击防护有效
- [ ] 权限控制正确
- [ ] 价格验证机制工作
- [ ] 无明显安全漏洞

### 性能验收
- [ ] Gas 消耗在合理范围
- [ ] 交易确认时间正常
- [ ] 网络拥堵时仍可正常工作

### 测试验收
- [ ] 测试覆盖率 > 90%
- [ ] 所有关键路径都有测试
- [ ] Fork 测试通过
- [ ] 模糊测试无崩溃

---

## 🚨 风险提示

1. **技术风险**: 智能合约漏洞、Uniswap 依赖风险
2. **经济风险**: 代币价值波动、流动性枯竭
3. **合规风险**: 监管政策变化、法律合规要求

**请在开发过程中持续关注安全性，并在主网部署前进行充分的安全审计。**