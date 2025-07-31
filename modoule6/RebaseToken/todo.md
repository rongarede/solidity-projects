# 按年通缩1%的ERC20 Rebase代币实现计划

## 项目概述
实现一个每年通缩1%的ERC20重基代币，使用份额/指数机制实现全局余额缩放。

## 任务清单

### 1. 核心合约开发
- [ ] 创建RebaseToken.sol主合约文件
- [ ] 实现份额(shares)和指数(index)存储机制
- [ ] 设计数学工具库用于分数幂计算
- [ ] 实现通缩计算逻辑 (99/100)^yearsElapsed

### 2. ERC20标准实现
- [ ] 实现IERC20接口的所有必需函数
- [ ] 重写balanceOf()以实时计算通缩后余额
- [ ] 实现transfer/transferFrom支持份额转换
- [ ] 添加name, symbol, decimals等基础属性

### 3. 重基机制
- [ ] 添加rebase()函数实现年度通缩
- [ ] 实现多年累计通缩计算 (支持一次调用处理多年)
- [ ] 添加时间检查防止重复通缩
- [ ] 发出Rebase事件记录通缩信息

### 4. 数学计算优化
- [ ] 实现高效的powFraction函数
- [ ] 使用定点数运算(1e18精度)
- [ ] 优化gas消耗的数学计算
- [ ] 处理边界情况和精度损失

### 5. 访问控制
- [ ] 实现onlyOwner修饰符控制rebase权限
- [ ] 添加可选的任何人调用rebase并获奖励机制
- [ ] 设置合约部署者作为初始owner

### 6. 测试用例开发
- [ ] testRebaseOnceAfterOneYear() - 单年通缩测试
- [ ] testMultiYearsInOneCall() - 多年累计通缩测试
- [ ] testBalanceScaling() - 份额比例保持不变测试
- [ ] testTransferBeforeAfterRebase() - 转账前后重基测试
- [ ] testNoRebaseIfNotOneYear() - 时间不足不触发通缩测试
- [ ] 边界条件测试(最大年份、最小余额等)

### 7. 部署脚本
- [ ] 创建Deploy.s.sol部署脚本
- [ ] 设置初始供应量1e8枚代币
- [ ] 配置初始参数(owner地址等)
- [ ] 添加部署验证步骤

### 8. 文档和说明
- [ ] 编写合约代码注释说明份额/指数模型
- [ ] 创建README.md说明部署和使用方法
- [ ] 添加数学公式解释复利通缩计算
- [ ] 比较重基通缩与销毁通缩的差异

## 技术规范

### 常量定义
- YEAR = 365 days
- INITIAL_SUPPLY = 100,000,000 * 10^18
- DEFLATION_RATE = 99/100 (每年1%)
- INDEX_PRECISION = 1e18

### 存储变量
- _totalShares: 总份额
- _shares: 用户地址到份额的映射
- index: 当前通缩指数
- lastRebaseTs: 上次重基时间戳

### 关键函数
- rebase(): 触发年度通缩
- balanceOf(): 根据份额计算当前余额
- _amountToShares(): 金额转份额
- _sharesToAmount(): 份额转金额
- powFraction(): 分数幂计算

## 完成标准
- [ ] 所有测试用例通过
- [ ] 合约部署成功
- [ ] 文档完整可读
- [ ] 代码安全审计通过