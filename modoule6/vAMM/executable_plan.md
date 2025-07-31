# vAMM 杠杆 DEX 简化实现计划

## 项目概述
基于虚拟自动做市商（vAMM）的杠杆去中心化交易所智能合约系统。核心功能：openPosition(), closePosition(), liquidatePosition()。使用虚拟资产池（vBase/vQuote）和 x*y=k 定价模型。

---

## Phase 1: 核心功能实现

### Step 1.1: 初始化项目环境

**Why**: 建立基础开发环境
**How**: 
- 运行 `forge init` 初始化项目
- 安装必要依赖：PRBMath（精度计算）、OpenZeppelin（安全组件）
- 配置 Solidity 0.8.19 编译器

**Done When**: `forge build` 成功编译

### Step 1.2: 定义核心数据结构

**Why**: 建立头寸、池状态的数据模型
**How**: 
- 创建 Position 结构体：size（多空方向）、margin（保证金）、entryPrice（开仓价）
- 创建 PoolState 结构体：vBase、vQuote、k常数
- 定义必要的错误类型和事件

**Done When**: 数据结构编译通过，字段类型正确

### Step 1.3: 实现 vAMM 价格计算

**Why**: 核心定价逻辑，基于 x*y=k 公式
**How**: 
- 实现 getCurrentPrice() 函数：P = vQuote / vBase
- 实现 updateReserves() 函数：根据交易更新虚拟储备量
- 使用 PRBMath 确保计算精度

**Done When**: 价格计算正确，测试通过 vBase=1000, vQuote=2000 → 价格=2

### Step 1.4: 创建主合约基础框架

**Why**: 建立主合约和状态变量
**How**: 
- 创建 vAMM.sol 主合约
- 添加池状态变量：vBase、vQuote、k
- 添加用户头寸映射
- 设置基本配置：最大杠杆、最小保证金、清算阈值
- 定义核心事件：PositionOpened、PositionClosed、PositionLiquidated

**Done When**: 合约编译通过，状态变量可读取

### Step 1.5: 实现池初始化功能

**Why**: 设置初始虚拟储备量和价格
**How**: 
- 实现 initializePool() 函数
- 设置初始 vBase 和 vQuote 数值
- 计算并存储 k 常数
- 添加初始化状态检查
- 发出 PoolStateUpdated 事件

**Done When**: 初始化后 getCurrentPrice() 返回正确价格值

### Step 1.6: 实现 openPosition 核心逻辑

**Why**: 用户开仓的主要功能
**How**: 
- 校验保证金和杠杆参数
- 计算头寸大小：positionSize = margin * leverage
- 根据多空方向计算 vBase 变化量
- 更新虚拟池状态（保持 k 不变）
- 记录用户头寸数据
- 发出 PositionOpened 事件

**Done When**: 用户能成功开仓，事件正确发出，池状态正确更新

### Step 1.7: 实现 PnL 计算函数

**Why**: 计算头寸盈亏，用于平仓和清算
**How**: 
- 实现 calculateUnrealizedPnL()：PnL = size * (currentPrice - entryPrice)
- 实现 getPositionValue()：计算头寸当前价值
- 实现 getMarginRatio()：计算保证金比率
- 正确处理多空方向：多头价格上涨盈利，空头价格下跌盈利

**Done When**: PnL 计算测试通过：多头价格上涨盈利，空头价格下跌盈利

### Step 1.8: 实现 closePosition 功能

**Why**: 用户主动平仓
**How**: 
- 计算已实现盈亏
- 反向更新虚拟池（撤销开仓时的影响）
- 更新用户账户状态
- 清除头寸数据
- 发出 PositionClosed 事件

**Done When**: 用户能成功平仓，PnL 正确计算，池状态恢复

### Step 1.9: 实现 liquidatePosition 基础功能

**Why**: 当保证金不足时强制平仓
**How**: 
- 检查清算条件：保证金比率 < 80%
- 计算清算罚金（简化版本：固定比例）
- 反向更新池状态
- 分配清算奖励给清算者
- 清理头寸和账户数据
- 发出 PositionLiquidated 事件

**Done When**: 在保证金不足时能成功清算，清算者获得奖励

---

## Phase 2: 安全性和测试

### Step 2.1: 创建基础单元测试

**Why**: 确保核心功能正确性
**How**: 
- 测试池初始化和价格计算
- 测试开仓功能：多头/空头，不同杠杆
- 测试平仓功能：正确的 PnL 计算
- 测试清算功能：触发条件和执行

**Done When**: 所有基础功能测试通过

### Step 2.2: 添加边界条件测试

**Why**: 测试错误处理和边界情况
**How**: 
- 测试参数验证：保证金不足、杠杆过高、重复开仓
- 测试极端价格变动
- 测试零值和溢出保护
- 测试池未初始化状态

**Done When**: 所有边界条件正确触发错误

### Step 2.3: PnL 计算准确性验证

**Why**: 验证盈亏计算的数学正确性
**How**: 
- 多种价格场景下的 PnL 计算
- 多头/空头在不同价格变动下的表现
- 高杠杆情况下的计算准确性
- 清算阈值计算验证

**Done When**: PnL 计算在所有场景下都数学正确

### Step 2.4: 安全性测试

**Why**: 确保合约安全性
**How**: 
- 重入攻击防护测试
- 访问控制测试
- 整数溢出/下溢保护测试
- Gas 限制和DoS 攻击防护

**Done When**: 所有安全测试通过，没有已知漏洞

---

## Phase 3: 优化和部署准备

### Step 3.1: Gas 优化

**Why**: 降低交易成本
**How**: 
- 优化存储布局，减少 SSTORE 操作
- 合并相关状态更新
- 使用更高效的数据类型
- 优化循环和计算逻辑

**Done When**: Gas 使用量相比初版减少 15%+

### Step 3.2: 事件优化

**Why**: 提高查询效率和用户体验
**How**: 
- 添加适当的索引字段
- 优化事件参数顺序
- 确保重要信息都有事件记录
- 添加调试和监控事件

**Done When**: 事件可以高效查询和过滤

### Step 3.3: 创建部署脚本

**Why**: 自动化部署流程
**How**: 
- 创建 Foundry 部署脚本
- 配置初始化参数
- 设置初始池状态
- 验证部署后状态

**Done When**: 一键部署成功，合约状态正确

### Step 3.4: 交互和测试脚本

**Why**: 便于演示和手动测试
**How**: 
- 创建开仓/平仓交互脚本
- 创建价格查询脚本
- 创建清算触发脚本
- 添加状态检查工具

**Done When**: 能够通过脚本完整演示所有功能

---

## Phase 4: 高级功能

### Step 4.1: 资金费率机制

**Why**: 平衡多空头寸，更接近真实交易
**How**: 
- 实现基础资金费率计算
- 定期更新费率（简化为固定周期）
- 在开仓/平仓时收取资金费用
- 记录费率历史数据

**Done When**: 资金费率能够定期计算和收取

### Step 4.2: 止损止盈订单

**Why**: 自动风险管理功能
**How**: 
- 创建订单数据结构
- 实现 createStopLoss/createTakeProfit 函数
- 实现订单触发检查逻辑  
- 自动执行触发的订单

**Done When**: 止损订单在价格触达时自动执行

### Step 4.3: 多交易对支持

**Why**: 支持更多资产交易
**How**: 
- 重构为多池架构
- 每个交易对独立的 vAMM 池
- 统一的用户界面和头寸管理
- 跨市场的风险管理

**Done When**: 能够创建和交易多个独立市场

### Step 4.4: 完整系统测试

**Why**: 验证所有功能协同工作
**How**: 
- 多用户多轮交易场景测试
- 极端市场条件下的系统稳定性
- 高频交易压力测试
- 长期运行稳定性测试

**Done When**: 系统在复杂场景下保持稳定运行

---

## 完成验收标准

**Phase 1**: 核心交易功能完整，用户能开仓/平仓/被清算
**Phase 2**: 95%+ 测试覆盖率，无安全漏洞
**Phase 3**: 优化完成，可以正式部署使用  
**Phase 4**: 高级功能齐全，达到生产级别

每个阶段必须完全完成后才能进入下一阶段。