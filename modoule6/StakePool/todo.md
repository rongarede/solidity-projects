# StakingPool 项目开发任务清单

## 项目概述
实现一个基于 Solidity 的 StakingPool 系统，允许用户质押 ETH（内部转换为 MockWETH）以获取 KK Token 奖励。采用 MasterChef 分配模型，每个区块产出 10 个 KK Token，按质押数量和持续时间公平分配。

## 1. 核心合约开发
**预计时间：8-10 小时**

### 1.1 MockWETH 合约实现
- [ ] **高优先级** 实现 MockWETH.sol 基础功能
  - 继承 ERC20，实现最小可用 WETH Mock
  - 实现 `deposit()` 函数：接收 ETH 并铸造等量 WETH
  - 实现 `withdraw(uint256 amount)` 函数：销毁 WETH 并返回 ETH
  - 实现 `receive()` 和 `fallback()` 函数支持直接发送 ETH
  - 添加适当的事件日志：`Deposit(address indexed, uint256)`、`Withdrawal(address indexed, uint256)`

- [ ] **中优先级** MockWETH 安全性增强
  - 添加重入攻击保护
  - 实现余额检查和溢出保护
  - 添加错误处理和自定义错误类型

### 1.2 KKToken 合约实现
- [ ] **高优先级** 实现 KKToken.sol 基础功能
  - 继承 ERC20 和 AccessControl，18 位精度
  - 定义 `MINTER_ROLE` 常量
  - 实现 `mint(address to, uint256 amount)` 函数，仅 MINTER_ROLE 可调用
  - 在构造函数中设置初始管理员角色
  - 添加铸币事件日志

- [ ] **中优先级** KKToken 权限管理优化
  - 完善角色管理功能
  - 添加角色转移机制
  - 实现紧急停止功能（可选）

### 1.3 StakingPool 核心合约开发
- [ ] **高优先级** StakingPool.sol 基础架构
  - 继承 ReentrancyGuard、AccessControl
  - 定义状态变量：
    - `MockWETH public immutable stakingToken`
    - `KKToken public immutable rewardToken`
    - `uint256 public rewardPerBlock = 10 * 1e18`
    - `uint256 public constant ACC_PRECISION = 1e12`
    - `uint256 public lastRewardBlock`
    - `uint256 public accRewardPerShare`
    - `uint256 public totalStaked`
  - 定义用户信息结构体：
    ```solidity
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }
    mapping(address => UserInfo) public userInfo;
    ```

- [ ] **高优先级** 实现核心质押逻辑
  - 实现 `updatePool()` 函数：更新池子奖励分配
  - 实现 `pendingKK(address user)` 函数：计算用户待领取奖励
  - 实现 `stakeETH() payable` 函数：接收 ETH 并转换为质押
  - 实现 `stake(uint256 amount)` 函数：使用已有 WETH 进行质押
  - 实现 `harvest()` 函数：领取奖励但不解除质押
  - 实现 `unstake(uint256 amount, bool withdrawAsETH)` 函数：解除质押并选择提取方式

- [ ] **高优先级** 实现紧急功能
  - 实现 `emergencyWithdraw()` 函数：紧急提取本金，放弃奖励
  - 实现管理员功能：`updateRewardPerBlock(uint256 newReward)`

- [ ] **中优先级** 事件和错误处理
  - 定义所有必要事件：
    - `Staked(address indexed user, uint256 amount)`
    - `Unstaked(address indexed user, uint256 amount, bool asETH)`
    - `RewardHarvested(address indexed user, uint256 amount)`
    - `EmergencyWithdraw(address indexed user, uint256 amount)`
    - `RewardPerBlockUpdated(uint256 oldReward, uint256 newReward)`
  - 定义自定义错误类型：
    - `InsufficientBalance()`
    - `InvalidAmount()`
    - `TransferFailed()`

## 2. 综合测试开发
**预计时间：6-8 小时**

### 2.1 单元测试实现
- [ ] **高优先级** MockWETH 测试 (`test/MockWETH.t.sol`)
  - 测试 deposit 功能：发送 ETH 接收 WETH
  - 测试 withdraw 功能：销毁 WETH 接收 ETH
  - 测试边界条件：0 金额、余额不足
  - 测试 receive/fallback 函数

- [ ] **高优先级** KKToken 测试 (`test/KKToken.t.sol`)
  - 测试铸币权限：仅 MINTER_ROLE 可铸币
  - 测试权限管理：角色授予和撤销
  - 测试非授权调用失败场景

- [ ] **高优先级** StakingPool 核心功能测试 (`test/StakingPool.t.sol`)
  - 测试单用户质押流程：
    - stakeETH → 检查质押余额
    - 前进若干区块 → 检查 pendingKK 计算正确性
    - harvest → 验证实际获得 KK Token 数量
    - unstake → 验证本金和奖励提取
  
- [ ] **高优先级** 多用户复杂场景测试
  - 测试多用户同时质押的奖励分配正确性
  - 测试质押/解质押交错场景：
    - 用户 A 质押 → 用户 B 质押 → 用户 A 部分解质押 → 检查奖励分配
  - 测试 emergencyWithdraw 功能：验证放弃奖励仅提取本金

### 2.2 高级测试场景
- [ ] **中优先级** 管理功能测试
  - 测试 `updateRewardPerBlock` 权限控制
  - 测试修改奖励率后的正确性：旧奖励计算 + 新奖励计算
  - 测试非管理员调用失败

- [ ] **中优先级** 安全性测试
  - 测试重入攻击模拟：创建恶意合约尝试重入攻击，应该失败
  - 测试整数溢出场景
  - 测试边界条件：最大质押量、0 金额操作

- [ ] **中优先级** Gas 优化测试
  - 基准测试各函数 Gas 消耗
  - 测试批量操作的 Gas 效率

### 2.3 集成测试
- [ ] **中优先级** 端到端测试场景
  - 完整生命周期测试：部署 → 配置权限 → 多轮质押/解质押 → 验证最终状态
  - 长期运行模拟：模拟数百个区块的运行，验证累积奖励准确性

## 3. 部署脚本开发
**预计时间：3-4 小时**

### 3.1 基础部署脚本
- [ ] **高优先级** 创建 `script/Deploy.s.sol`
  - 按依赖顺序部署合约：MockWETH → KKToken → StakingPool
  - 配置 KKToken 的 MINTER_ROLE 给 StakingPool
  - 输出所有合约地址用于验证

- [ ] **中优先级** 部署配置管理
  - 支持不同网络配置（本地、测试网、主网）
  - 实现部署参数外部化配置
  - 添加部署后验证脚本

### 3.2 交互演示脚本
- [ ] **高优先级** 创建 `script/Demo.s.sol`
  - 演示完整使用流程：
    - 用户质押 1 ETH
    - 前进 100 个区块
    - 查看待领取奖励
    - 执行 harvest 操作
    - 部分解质押（0.5 ETH 作为 ETH 提取）
    - 验证最终余额状态

- [ ] **中优先级** 监控和查询脚本
  - 实现质押池状态查询脚本
  - 实现用户奖励计算工具
  - 创建池子统计信息展示

## 4. 安全分析与文档
**预计时间：4-5 小时**

### 4.1 安全风险分析文档
- [ ] **高优先级** 创建 `SECURITY_ANALYSIS.md`
  - **通胀风险分析**：
    - KK Token 无上限铸币的通胀影响
    - 建议：实现最大供应量限制或衰减机制
  - **区块操纵风险**：
    - 矿工可能的 block.number 操纵
    - 建议：使用 block.timestamp 或混合机制
  - **闪电贷套利风险**：
    - 同区块内质押-harvest-解质押套利可能性
    - 建议：实现最小质押时间限制
  - **中心化风险**：
    - 管理员权限过大的风险
    - 建议：多签治理或时间锁机制

- [ ] **中优先级** 缓解方案实现
  - 实现质押时间锁定机制（可选）
  - 添加奖励率变更延时生效
  - 实现紧急暂停功能

### 4.2 技术文档编写
- [ ] **中优先级** API 文档 (`API.md`)
  - 详细说明所有公开函数的参数、返回值、使用场景
  - 提供调用示例和最佳实践
  - 说明事件日志格式和监听方法

- [ ] **中优先级** 架构设计文档 (`ARCHITECTURE.md`)
  - 系统整体架构图
  - 合约间交互流程图
  - 奖励计算机制详细说明
  - Gas 优化策略说明

## 5. 前瞻性扩展设计
**预计时间：3-4 小时**

### 5.1 多池架构设计
- [ ] **低优先级** 设计文档 `FUTURE_EXTENSIONS.md`
  - **多池支持**：
    - MasterChef 风格的多池管理合约设计
    - 不同 LP Token 的质押池
    - 池权重和奖励分配机制
  - **多奖励代币**：
    - 支持多种奖励代币的架构
    - 奖励代币配比和分发策略
    - 跨链奖励分发考虑

### 5.2 治理和升级机制
- [ ] **低优先级** 高级功能设计
  - **veToken 机制**：
    - 投票托管 Token 设计
    - 基于锁定时间的权重计算
    - 治理投票和奖励加成机制
  - **可升级性方案**：
    - 代理合约升级模式
    - 数据迁移策略
    - 向后兼容性保证

### 5.3 Merkle 空投替代方案
- [ ] **低优先级** 替代分发机制
  - Merkle Tree 批量空投设计
  - Gas 效率对比分析
  - 用户体验优化方案

## 6. 最终验收和优化
**预计时间：2-3 小时**

### 6.1 代码质量检查
- [ ] **中优先级** 代码审查清单
  - 检查所有函数的访问控制
  - 验证数学计算的精度和溢出保护
  - 确认事件日志的完整性
  - 检查错误处理的全面性

- [ ] **中优先级** 性能优化
  - 分析和优化 Gas 消耗
  - 检查存储布局优化机会
  - 评估批量操作的可行性

### 6.2 文档完善和交付准备
- [ ] **中优先级** 最终文档整理
  - 确保所有文档的准确性和完整性
  - 创建快速开始指南
  - 准备演示和培训材料

- [ ] **低优先级** 社区和生态
  - 准备开源发布清单
  - 考虑审计准备工作
  - 规划社区参与策略

## 开发里程碑

### 第一阶段（2-3 天）：核心功能实现
- 完成所有合约开发（第1部分）
- 实现基础测试覆盖

### 第二阶段（1-2 天）：测试和部署
- 完成综合测试（第2部分）
- 实现部署脚本（第3部分）

### 第三阶段（1 天）：文档和安全
- 完成安全分析和文档（第4部分）
- 代码质量最终检查（第6部分）

### 可选阶段：扩展功能
- 前瞻性设计实现（第5部分）

## 注意事项

1. **精度处理**：所有奖励计算使用 `ACC_PRECISION = 1e12` 避免精度损失
2. **安全优先**：每个功能都要考虑重入攻击、整数溢出等安全问题
3. **Gas 优化**：合理使用 `memory` vs `storage`，避免不必要的 SSTORE 操作
4. **测试驱动**：先写测试用例，确保覆盖所有边界条件
5. **文档同步**：代码修改时同步更新相关文档

## 预计总开发时间：26-34 小时
- 核心功能：16-18 小时  
- 测试和文档：10-16 小时