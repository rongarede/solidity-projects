# FlashSwap 套利项目

## 项目概述

这是一个基于 Uniswap V2 闪电交换（FlashSwap）的三角套利项目，实现了创新的 **A→C→B→A** 套利策略来避免重入锁定问题。

## 核心创新

### 🎯 重入锁定解决方案

传统的套利策略 A→B→C→A 会遇到 UniswapV2 的重入锁定问题，因为需要在同一个交易中从 PairAB 借入资金并再次与 PairAB 交互。

我们的解决方案采用 **A→C→B→A** 路径：
1. 从 PairAB 闪电借入 TokenA
2. 通过 PairAC 将 A→C（避免重入）
3. 通过 PairBC 将 C→B（利用价格差异）
4. 通过 B→C→A 替代路径还款（避免重入）

## 技术架构

### 合约结构

```
src/
├── PerfectArbitrage.sol      # 主套利合约
├── tokens/
│   ├── TokenA.sol           # 测试代币A
│   ├── TokenB.sol           # 测试代币B
│   └── TokenC.sol           # 测试代币C
└── interfaces/              # 接口定义
```

### 核心合约: PerfectArbitrage

```solidity
contract PerfectArbitrage is IUniswapV2Callee, Ownable {
    // 套利策略：A→C→B→A 避免重入锁定
    function executePerfectArbitrage(uint256 amountToBorrow) external onlyOwner;
    
    // Uniswap V2 闪电交换回调
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override;
    
    // 核心交换函数
    function swapAtoC(uint256 amountA) internal returns (uint256);
    function swapCtoB(uint256 amountC) internal returns (uint256);
    function swapBtoAViaC(uint256 targetAmountA) internal returns (uint256);
}
```

## 部署配置

### 池子配置
- **PairAB**: 1000 TokenA : 1000 TokenB (1:1 比率)
- **PairBC**: 1000 TokenB : 500 TokenC (2:1 比率) - 价格差异源
- **PairAC**: 1000 TokenA : 1000 TokenC (1:1 比率)

### 已部署合约地址 (Polygon)

| 合约 | 地址 |
|------|------|
| TokenA | `0x9c48491738431BB48E2680b9Da81f2567387901F` |
| TokenB | `0x86C65A1893654aB6d6365Cc2c6fC9089b8CDB6bA` |
| TokenC | `0xE226E1912E35C2b0d0E1EF45fF92fe7993C2410D` |
| PairAB | `0x9F2593628a4041E2C43f1fa83206a52C13338c6E` |
| PairBC | `0x08C81b703E8121d31d7Dc5e7B784268bd986Da5B` |
| PairAC | `0x707CBC25D0f383DD540A45fbF4361B3e7883096f` |
| PerfectArbitrage | `0x70Fd6Df65EC7b502215100AD89e78d354682B7D0` |

## 套利流程详解

### 1. 闪电借贷阶段
```solidity
// 从 PairAB 借入 TokenA，触发 uniswapV2Call 回调
pair.swap(amount0Out, amount1Out, address(this), data);
```

### 2. 套利执行阶段

#### 步骤1: A→C 转换
- 使用 PairAC 直接交换
- 避免与借贷池 PairAB 的重入冲突
- 应用 Uniswap V2 恒定乘积公式

#### 步骤2: C→B 转换
- 利用 PairBC 中的价格差异（2:1比率）
- 获得约2倍的 TokenB

#### 步骤3: B→C→A 还款路径
- 通过 PairBC 将部分 B 换回 C
- 通过 PairAC 将 C 换回 A
- 避免直接使用 PairAB 进行还款

### 3. 利润计算
```solidity
uint256 fee = (amountBorrowed * 3) / 997 + 1; // 0.3% Uniswap 手续费
uint256 amountToRepay = amountBorrowed + fee;
// 剩余代币即为利润
```

## 测试结果

### ✅ 技术验证成功
- **重入问题已解决**: 成功避免 "UniswapV2: LOCKED" 错误
- **交换逻辑正确**: 所有交换步骤正常执行
- **数学计算准确**: 手续费和滑点计算正确

### 📊 实际测试数据

以 1 TokenA 为例：
1. **借入**: 1.000 TokenA
2. **A→C**: 获得 0.996 TokenC  
3. **C→B**: 获得 1.982 TokenB
4. **还款需求**: 1.003 TokenA (含手续费)
5. **B→C→A**: 需要 2.012 TokenB

**结果**: 当前池子配置下，由于交易费用和滑点影响，无法盈利。

## 环境配置

### 1. 安装依赖
```bash
# 安装 Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# 安装项目依赖
forge install
```

### 2. 环境变量设置
创建 `.env` 文件：
```bash
POLYGON_RPC_URL=https://polygon-rpc.com
PRIVATE_KEY=your_private_key_here
POLYGONSCAN_API_KEY=your_api_key_here

# 代币地址
TOKEN_A_ADDRESS=0x9c48491738431BB48E2680b9Da81f2567387901F
TOKEN_B_ADDRESS=0x86C65A1893654aB6d6365Cc2c6fC9089b8CDB6bA
TOKEN_C_ADDRESS=0xE226E1912E35C2b0d0E1EF45fF92fe7993C2410D

# 交易对地址
PAIR_AB_ADDRESS=0x9F2593628a4041E2C43f1fa83206a52C13338c6E
PAIR_BC_ADDRESS=0x08C81b703E8121d31d7Dc5e7B784268bd986Da5B
PAIR_AC_ADDRESS=0x707CBC25D0f383DD540A45fbF4361B3e7883096f
```

### 3. 编译和测试
```bash
# 编译合约
forge build

# 运行测试
forge test

# 部署验证
forge script script/10_TestPerfectArbitrage.s.sol --fork-url https://polygon-rpc.com
```

## 部署脚本

项目包含完整的部署脚本序列：

```bash
# 1. 部署代币
forge script script/01_DeployTokens.s.sol --broadcast --fork-url https://polygon-rpc.com

# 2. 创建交易对
forge script script/02_CreatePairAB.s.sol --broadcast --fork-url https://polygon-rpc.com
forge script script/03_CreatePairBC.s.sol --broadcast --fork-url https://polygon-rpc.com

# 3. 添加流动性
forge script script/04_AddLiquidityAB.s.sol --broadcast --fork-url https://polygon-rpc.com
forge script script/05_AddLiquidityBC.s.sol --broadcast --fork-url https://polygon-rpc.com

# 4. 创建第三池
forge script script/06_CreatePairAC.s.sol --broadcast --fork-url https://polygon-rpc.com
forge script script/07_AddLiquidityAC.s.sol --broadcast --fork-url https://polygon-rpc.com

# 5. 部署套利合约
forge script script/09_DeployPerfectArbitrage.s.sol --broadcast --fork-url https://polygon-rpc.com

# 6. 执行套利测试
forge script script/10_TestPerfectArbitrage.s.sol --broadcast --fork-url https://polygon-rpc.com
```

## 关键技术特性

### 🔒 安全特性
- **重入保护**: 创新的路径设计避免重入锁定
- **所有者控制**: 只有合约所有者可以执行套利
- **紧急提取**: 应急情况下的资金安全机制

### ⚡ 性能优化
- **直接交换**: 绕过路由器，减少 gas 消耗
- **精确计算**: 使用 Uniswap V2 精确公式
- **最小滑点**: 优化的交换顺序

### 🛠 开发友好
- **详细日志**: 完整的执行过程记录
- **中文注释**: 全面的代码文档
- **模块化设计**: 清晰的合约架构

## 开发团队的创新贡献

### 问题识别
准确识别了传统套利策略中的重入锁定问题，这是 Uniswap V2 协议的固有限制。

### 创新解决方案
提出了 A→C→B→A 的创新路径，通过引入第三个交易池（PairAC）巧妙地避开了重入限制。

### 技术实现
- 实现了复杂的多池交换逻辑
- 精确的数学计算和手续费处理
- 完整的错误处理和安全检查

## 未来优化方向

1. **动态价格发现**: 实现实时价格监控和最优套利时机判断
2. **多池支持**: 扩展到支持更多交易对的复杂套利策略
3. **Gas优化**: 进一步优化交易成本
4. **自动化执行**: 集成 MEV 检测和自动执行机制

## 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 联系方式

如有技术问题或合作意向，请通过 GitHub Issues 联系。

---

**⚠️ 免责声明**: 本项目仅用于教育和研究目的。在主网部署前请进行充分的安全审计和测试。套利交易存在风险，请谨慎操作。
