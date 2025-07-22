# Uniswap V2 Base链 + Viem 完整开发任务清单

## 阶段一：项目准备

### 1.1 钱包准备
- [ ] 准备开发钱包
  - [ ] 确认钱包地址和私钥
  - [ ] 确保有足够的 Base 主网 ETH

### 1.2 Git 项目管理
- [ ] 添加新文件到 Git 版本控制
  - [ ] `git add foundry.toml todo.md what.md`
  - [ ] `git add script/ test/` - 添加新创建的目录
- [ ] 配置 `.gitignore` 文件
  - [ ] 添加 `.env` - 环境变量文件
  - [ ] 添加 `broadcast/` - Foundry 部署记录
  - [ ] 添加 `cache/` 和 `out/` - 编译输出
  - [ ] 添加 `logs/` - 前端错误日志

### 1.3 环境变量配置
- [ ] 创建 `.env` 文件
- [ ] 配置以下环境变量：
  - [ ] `PRIVATE_KEY` - 部署钱包私钥
  - [ ] `FEE_TO_SETTER` - 手续费设置者地址

## 阶段二：智能合约部署

### 2.1 Foundry 项目配置
- [ ] 更新 `foundry.toml` 配置文件
  - [ ] 设置 Solidity 版本为 0.8.x（使用本地版本）
  - [ ] 配置 Base 主网 RPC 端点
- [ ] 初始化 Foundry 项目结构
  - [ ] 创建 `script/` 目录

### 2.2 合约代码升级到 Solidity 0.8.x
- [ ] 升级 UniswapV2Factory.sol
  - [ ] 更新 pragma 声明为 ^0.8.0
  - [ ] 移除 SafeMath 依赖（0.8.x 内置溢出检查）
  - [ ] 更新构造函数语法
- [ ] 升级 UniswapV2Pair.sol
  - [ ] 更新 pragma 声明
  - [ ] 移除 SafeMath 导入和使用
  - [ ] 处理字符串拼接语法变化
- [ ] 升级 UniswapV2ERC20.sol
  - [ ] 更新 pragma 声明
  - [ ] 移除 SafeMath 使用
- [ ] 升级接口文件
  - [ ] 更新所有 interface 文件的 pragma 声明
- [ ] 升级库文件
  - [ ] 更新 Math.sol, UQ112x112.sol 等库文件
  - [ ] 移除 SafeMath.sol（不再需要）

### 2.3 部署脚本编写
- [ ] 创建 Factory 合约部署脚本
  - [ ] `script/DeployFactory.s.sol`
  - [ ] 处理构造函数参数（feeToSetter）
- [ ] 创建测试代币部署脚本（可选）
  - [ ] `script/DeployTestTokens.s.sol`
  - [ ] 部署 TokenA 和 TokenB 用于测试

### 2.4 合约编译和基础测试
- [ ] 编译升级后的合约：`forge build`
- [ ] 检查编译警告和错误
- [ ] 创建测试目录和基础测试文件
  - [ ] 确保 `test/` 目录存在
  - [ ] 创建 `test/UniswapV2Factory.t.sol`
    - [ ] 测试 Factory 部署
    - [ ] 测试 feeToSetter 设置
    - [ ] 测试 createPair 基本功能
    - [ ] 测试重复创建 Pair 的错误处理
  - [ ] 创建 `test/UniswapV2Pair.t.sol`
    - [ ] 测试 Pair 合约初始化
    - [ ] 测试 token0 和 token1 设置
    - [ ] 测试基本 ERC20 功能
  - [ ] 创建 `test/UniswapV2ERC20.t.sol`
    - [ ] 测试 ERC20 基本功能（transfer, approve）
    - [ ] 测试 permit 功能
- [ ] 创建测试辅助合约
  - [ ] `test/mocks/MockERC20.sol` - 用于测试的 ERC20 代币
- [ ] 运行测试套件
  - [ ] `forge test -vv` - 运行所有测试
  - [ ] 检查测试覆盖率：`forge coverage`
  - [ ] 确保关键功能测试通过
- [ ] 修复发现的问题
  - [ ] 根据测试结果修复合约 bug
  - [ ] 重新编译和测试直到全部通过

### 2.5 主网部署
- [ ] 部署到 Base 主网
  - [ ] 执行 Factory 部署命令
  - [ ] 记录部署的合约地址
- [ ] 测试基本功能
  - [ ] 调用 `createPair` 方法创建交易对
  - [ ] 验证事件日志输出

### 2.6 合约地址管理
- [ ] 创建 `contracts-addresses.json` 文件
- [ ] 记录主网合约地址

### 2.7 Router 合约集成和部署
- [ ] 从 v2-periphery 复制 Router 相关合约
  - [ ] 复制 `UniswapV2Router02.sol` 到 `contracts/`
  - [ ] 复制 `libraries/UniswapV2Library.sol` 到 `contracts/libraries/`
  - [ ] 复制 `interfaces/IUniswapV2Router02.sol` 到 `contracts/interfaces/`
  - [ ] 复制 `interfaces/IWETH.sol` 到 `contracts/interfaces/`
- [ ] 升级 Router 合约到 Solidity 0.8.19
  - [ ] 更新 pragma 声明为 ^0.8.0
  - [ ] 移除 SafeMath 依赖（使用内置溢出检查）
  - [ ] 修复构造函数语法
  - [ ] 更新导入路径引用本地合约
- [ ] 配置 Router 部署参数
  - [ ] 获取 Base 主网 WETH 地址：`0x4200000000000000000000000000000000000006`
  - [ ] 使用已部署的 Factory 地址
- [ ] 创建 Router 部署脚本
  - [ ] `script/DeployRouter.s.sol`
  - [ ] 处理构造函数参数（Factory, WETH）
- [ ] 部署 Router 到 Base 主网
  - [ ] 执行 Router 部署命令
  - [ ] 记录 Router 合约地址
  - [ ] 验证 Router 合约功能
- [ ] 更新合约地址配置
  - [ ] 在 `contracts-addresses.json` 中添加 Router 地址
  - [ ] 记录 WETH 地址配置

### 2.8 Router 基础功能测试
- [ ] 创建基础测试文件
  - [ ] `test/UniswapV2Router02Basic.t.sol` - Router 基础功能测试
- [ ] Router 部署和初始化测试
  - [ ] 测试 Router 合约部署成功
  - [ ] 验证 Factory 和 WETH 地址设置正确
  - [ ] 测试 Router 与 Factory 连接正常
- [ ] 基础流动性测试
  - [ ] 测试 `addLiquidity` 基本功能
  - [ ] 验证 LP 代币铸造
  - [ ] 测试流动性计算准确性
- [ ] 基础交换测试
  - [ ] 测试 `swapExactTokensForTokens` 基本功能
  - [ ] 验证交换比例计算
  - [ ] 测试价格影响在合理范围内
- [ ] 运行基础测试
  - [ ] `forge test --match-contract RouterBasic -vv`
  - [ ] 验证核心功能正常工作

### 2.9 MockWETH 替代真实WETH
- [ ] 验证MockWETH合约
  - [ ] 检查 `test/mocks/MockWETH.sol` 文件存在且功能完整
  - [ ] 验证MockWETH实现了标准WETH接口（deposit, withdraw, ERC20功能）
- [ ] 修改Router部署脚本使用MockWETH
  - [ ] 更新 `script/DeployRouter.s.sol`
  - [ ] 在部署脚本中先部署MockWETH合约
  - [ ] 使用MockWETH地址替代Base主网WETH地址创建Router
  - [ ] 移除硬编码的Base主网WETH地址引用
- [ ] 更新合约地址配置
  - [ ] 修改 `contracts-addresses.json`
  - [ ] 将WETH地址从 `0x4200000000000000000000000000000000000006` 更新为部署的MockWETH地址
  - [ ] 添加MockWETH合约相关信息（部署交易哈希、部署者等）
- [ ] 测试MockWETH功能
  - [ ] 编译并部署更新后的Router（使用MockWETH）
  - [ ] 测试MockWETH的deposit和withdraw功能
  - [ ] 验证Router的ETH相关功能（addLiquidityETH, swapExactETHForTokens等）
  - [ ] 确保所有ETH/Token交换功能正常工作
- [ ] 验证完整性
  - [ ] 运行 `forge test` 确保所有测试通过
  - [ ] 验证MockWETH与Router集成无问题
  - [ ] 确认不再依赖真实ETH进行测试

## 阶段三：前端项目初始化

### 3.1 项目脚手架搭建
- [ ] 在 `/Users/youshuncheng/solidity/modoule5/` 目录下创建前端项目
  - [ ] `cd /Users/youshuncheng/solidity/modoule5/`
  - [ ] `npx create-next-app@latest v2-frontend --typescript --tailwind --app`
- [ ] 进入前端项目目录并安装依赖
  - [ ] `cd v2-frontend`
  - [ ] `npm install viem wagmi @wagmi/core @wagmi/connectors`
  - [ ] `npm install @tanstack/react-query`
  - [ ] `npm install zustand recharts`
- [ ] 初始化 UI 组件库
  - [ ] `npx shadcn-ui@latest init`
  - [ ] 安装基础 UI 组件

### 3.2 项目结构创建
- [ ] 在 `v2-frontend/` 目录下创建核心目录结构
  - [ ] `mkdir -p src/components/ui src/components/layout src/components/swap src/components/liquidity src/components/wallet`
  - [ ] `mkdir -p src/hooks src/lib src/store src/types src/constants`

### 3.3 基础配置文件
- [ ] 在 `v2-frontend/src/lib/` 目录下创建配置文件
  - [ ] `lib/viem.ts` - Viem 客户端配置
  - [ ] `lib/wagmi.ts` - Wagmi 配置（仅支持 MetaMask 和 Coinbase Wallet）
  - [ ] `lib/contracts.ts` - 合约配置（引用 v2-core 的合约地址，**使用MockWETH地址**）
  - [ ] `lib/tokens.ts` - 代币列表（**包含MockWETH配置**）
  - [ ] `lib/utils.ts` - 工具函数
  - [ ] `lib/error-logger.ts` - 文件日志系统

### 3.4 前端错误监控系统
- [ ] 创建后端错误日志 API
  - [ ] `app/api/log-error/route.ts` - Next.js API 路由
  - [ ] 接收 POST 请求，Content-Type: application/json
  - [ ] 将错误信息追加到 `logs/error-log.txt` 文件
  - [ ] 在控制台输出接收到的错误信息
- [ ] 实现前端错误捕获模块 `lib/error-logger.ts`
  - [ ] 使用 `window.onerror` 捕获 JavaScript 错误
  - [ ] 使用 `window.addEventListener('unhandledrejection')` 捕获 Promise 错误
  - [ ] 创建错误分类（钱包、交易、网络、计算等）
  - [ ] 通过 fetch POST 发送错误到 `/api/log-error`
  - [ ] 添加时间戳和错误上下文信息
- [ ] 创建日志目录和配置
  - [ ] 在前端项目中 `mkdir logs` - 创建日志目录
  - [ ] 在前端项目的 `.gitignore` 中添加 `logs/` 和 `*.txt`
- [ ] 集成错误监控到应用
  - [ ] 在 `app/layout.tsx` 中初始化全局错误监控
  - [ ] 创建 `hooks/useErrorLogger.ts` - 组件内错误记录
  - [ ] 确保 Claude Code 可以读取 `logs/error-log.txt`

## 阶段四：核心功能开发

### 4.1 钱包连接功能
- [ ] 实现钱包连接组件
  - [ ] `components/wallet/ConnectButton.tsx`
  - [ ] 支持 MetaMask, Coinbase Wallet
  - [ ] 集成日志记录：记录钱包连接失败、用户拒绝等错误到日志文件
- [ ] 实现钱包信息显示
  - [ ] `components/wallet/WalletInfo.tsx`
  - [ ] 显示地址、余额、网络状态
  - [ ] 记录网络连接错误到日志
- [ ] 实现网络切换功能
  - [ ] 检测当前网络
  - [ ] 提示切换到 Base 网络
  - [ ] 记录网络切换失败到日志

### 4.2 代币管理系统
- [ ] 创建代币类型定义 `types/tokens.ts`
  - [ ] 定义 Token 接口（address, symbol, name, decimals, balance）
  - [ ] 定义代币来源类型（默认、用户拥有、自定义）
  - [ ] **添加MockWETH代币类型定义**
- [ ] 实现用户代币扫描功能
  - [ ] Hook: `hooks/useUserTokens.ts` - 扫描用户拥有的所有代币
  - [ ] 通过 Transfer 事件日志扫描用户代币历史
  - [ ] 批量查询常见代币合约的用户余额
  - [ ] 过滤余额大于 0 的代币
  - [ ] 记录代币扫描失败和网络错误到日志
- [ ] 实现代币余额查询
  - [ ] Hook: `hooks/useTokenBalance.ts`
  - [ ] 批量余额查询优化
  - [ ] 实时余额更新机制
  - [ ] 记录余额查询失败和网络超时到日志
- [ ] 实现智能代币选择器
  - [ ] `components/swap/TokenSelect.tsx`
  - [ ] "我的代币" 标签页 - 显示用户拥有的代币
  - [ ] "常用代币" 标签页 - 显示默认代币列表（**包含MockWETH**）
  - [ ] "自定义添加" 功能 - 手动输入代币地址
  - [ ] 代币搜索过滤功能（按名称、符号、地址）
  - [ ] 显示代币余额、图标和详细信息
  - [ ] **支持MockWETH的特殊显示（显示为ETH包装代币）**
  - [ ] 记录代币信息获取失败到日志

### 4.3 价格计算功能（基于真实链上数据）
- [ ] 实现真实的价格查询 Hook
  - [ ] `hooks/useTokenPrice.ts`
  - [ ] 移除模拟价格数据
  - [ ] 从 Pair 合约获取 reserves 计算实时价格
  - [ ] 使用 Router 的 getAmountsOut/getAmountsIn 方法
  - [ ] 记录价格获取失败和计算错误到日志
- [ ] 实现真实的兑换率计算
  - [ ] 基于 Uniswap V2 公式从链上数据计算
  - [ ] 考虑滑点和手续费（0.3%）
  - [ ] 使用 Router 合约的价格计算函数
  - [ ] 记录数学计算溢出和除零错误到日志
- [ ] 实现价格影响计算
  - [ ] 基于流动性池储备量计算真实价格影响
  - [ ] 大额交易价格影响提醒
  - [ ] 记录价格影响计算异常到日志

### 4.4 交换功能实现（Router 合约集成）
- [ ] 更新合约配置 `lib/contracts.ts`
  - [ ] 添加 Router 合约地址和 ABI
  - [ ] **添加 MockWETH 合约配置（替代WETH）**
  - [ ] 移除模拟合约配置
- [ ] 创建交换状态管理 `store/useSwapStore.ts`
- [ ] 实现真实的交换 Hook `hooks/useSwap.ts`
  - [ ] 移除 "Router contract not implemented yet" 错误
  - [ ] 实现真实的 `swapExactTokensForTokens` 调用 Router 合约
  - [ ] 实现真实的 `swapTokensForExactTokens` 调用 Router 合约
  - [ ] **实现真实的 `swapExactETHForTokens` 调用 Router 合约（使用MockWETH）**
  - [ ] **实现真实的 `swapTokensForExactETH` 调用 Router 合约（使用MockWETH）**
  - [ ] 添加代币授权检查和 approve 功能
  - [ ] 记录交易失败、Gas 估算失败、滑点过大等错误到日志
- [ ] 实现交换界面组件
  - [ ] `components/swap/SwapCard.tsx`
  - [ ] 代币输入框
  - [ ] 交换按钮和状态
  - [ ] 滑点设置
  - [ ] 记录用户输入验证错误和界面状态错误到日志
- [ ] 实现交易确认功能
  - [ ] 交易详情预览
  - [ ] Gas 费用估算
  - [ ] 交易状态跟踪
  - [ ] 记录交易被拒绝、超时、失败等错误到日志

### 4.5 基础流动性功能（Router 合约集成）
- [ ] 实现真实的添加流动性 Hook `hooks/useAddLiquidity.ts`
  - [ ] 移除 "Router contract not implemented yet" 错误
  - [ ] 实现真实的 `addLiquidity` 调用 Router 合约
  - [ ] **实现真实的 `addLiquidityETH` 调用 Router 合约（使用MockWETH）**
  - [ ] 流动性计算和预览基于真实储备量
  - [ ] 添加代币授权检查和 approve 功能
  - [ ] 记录流动性计算错误和交易失败到日志
- [ ] 实现简单的添加流动性组件
  - [ ] `components/liquidity/AddLiquidity.tsx`
  - [ ] 记录组件状态错误和用户操作错误到日志
- [ ] 实现流动性状态管理 `store/useLiquidityStore.ts`
  - [ ] 只管理添加流动性相关状态
  - [ ] 集成错误日志记录

## 阶段五：用户界面开发

### 5.1 布局组件
- [ ] 实现头部导航 `components/layout/Header.tsx`
  - [ ] Logo 和品牌标识
  - [ ] 主导航菜单
  - [ ] 钱包连接按钮
- [ ] 实现侧边栏（可选） `components/layout/Sidebar.tsx`
- [ ] 实现页脚 `components/layout/Footer.tsx`

### 5.2 页面路由
- [ ] 创建交换页面 `app/swap/page.tsx`
- [ ] 创建添加流动性页面 `app/add-liquidity/page.tsx`
- [ ] **创建池子查看页面 `app/pools/page.tsx`**
  - [ ] **显示所有交易对池子列表**
  - [ ] **简单表格布局：池子地址、Token0、Token1**
- [ ] 创建首页 `app/page.tsx`
- [ ] 配置页面路由和导航

### 5.3 池子功能开发
- [ ] 创建获取所有池子的Hook
  - [ ] `hooks/useAllPools.ts` - 获取所有交易对数据
  - [ ] 调用Factory.allPairsLength()获取池子总数
  - [ ] 批量调用Factory.allPairs(i)获取所有池子地址
  - [ ] 对每个池子调用token0()和token1()获取代币地址
  - [ ] 返回简单的池子列表数据结构
- [ ] 更新导航菜单
  - [ ] 在Header.tsx中添加"池子"导航链接
  - [ ] 配置路由到/pools页面
- [ ] 实现池子页面组件
  - [ ] 简单的表格或列表展示
  - [ ] 显示池子地址、Token0地址、Token1地址
  - [ ] 添加加载状态处理
  - [ ] 基础错误处理

### 5.4 响应式设计
- [ ] 实现移动端适配
- [ ] 优化平板设备显示
- [ ] 测试各种屏幕尺寸

### 5.5 用户体验优化
- [ ] 实现加载状态指示器
- [ ] 实现错误状态处理
- [ ] 实现成功提示和通知
- [ ] 实现交易历史记录（可选）

## 阶段六：核心功能测试

### 6.1 合约功能测试
- [ ] 验证合约部署成功
  - [ ] 检查 Factory 合约地址和状态
  - [ ] 测试 Factory.createPair 基本功能
- [ ] 部署测试代币
  - [ ] 使用私钥部署 TokenA（如 TestUSDC）
  - [ ] **验证MockWETH已部署（替代TestWETH）**
  - [ ] 验证代币基本功能（mint、transfer）
  - [ ] **测试MockWETH的deposit/withdraw功能**

### 6.2 交易对和流动性测试（使用 Router）
- [ ] 创建交易对
  - [ ] **创建 TokenA/MockWETH 交易对（替代TokenA/TokenB）**
  - [ ] 调用 Factory.createPair(tokenA, mockWETH) 或通过 Router 自动创建
  - [ ] 验证 Pair 合约创建成功
  - [ ] 记录 Pair 合约地址
- [ ] 使用 Router 添加初始流动性
  - [ ] 调用 Router.addLiquidity(tokenA, mockWETH, amounts...)
  - [ ] **测试 Router.addLiquidityETH(tokenA, amounts...) 使用MockWETH**
  - [ ] 验证 LP 代币铸造
  - [ ] 检查流动性池储备量
  - [ ] 验证 Router 合约正确处理流动性添加

### 6.3 真实交换功能测试（Router 集成）
- [ ] 前端基础连接测试
  - [ ] 启动前端开发服务器：`npm run dev`
  - [ ] 验证钱包连接功能
  - [ ] **检查代币余额显示（包含MockWETH余额）**
  - [ ] **验证 Router 和 MockWETH 合约地址正确配置**
- [ ] 真实代币交换测试
  - [ ] 测试代币授权（approve）流程
  - [ ] 使用 Router.swapExactTokensForTokens 进行 TokenA → MockWETH 交换
  - [ ] **测试 Router.swapExactETHForTokens（ETH → TokenA，通过MockWETH）**
  - [ ] **测试 Router.swapTokensForExactETH（TokenA → ETH，通过MockWETH）**
  - [ ] 验证交换比例计算正确（基于真实储备量）
  - [ ] 确认交易成功执行并更新储备量
  - [ ] 检查用户余额变化正确性
  - [ ] 验证 LP 手续费分配

### 6.4 核心算法验证（基于 Router 合约）
- [ ] 验证 Router 合约中的 Uniswap V2 公式实现
  - [ ] 测试恒定乘积公式：x * y = k
  - [ ] 验证手续费计算正确（0.3%）
  - [ ] 测试滑点保护机制
  - [ ] 验证价格影响计算
- [ ] 端到端 DEX 功能验证
  - [ ] 完整流程：部署代币 → 添加流动性 → 交换代币
  - [ ] 验证所有 Router 功能正常工作
  - [ ] 确认前端与 Router 合约正确集成

## 阶段七：项目完善

### 7.1 代码优化
- [ ] 代码重构和清理
- [ ] 添加必要的注释
- [ ] 优化组件结构
- [ ] 确保代码规范一致性

### 7.2 文档完善
- [ ] 更新 v2-core/README.md（合约项目文档）
- [ ] 更新 v2-frontend/README.md（前端项目文档）
- [ ] 添加项目设置说明
- [ ] 记录重要的配置和地址
- [ ] 创建开发笔记

### 7.3 项目总结
- [ ] 整理项目成果
- [ ] 记录遇到的问题和解决方案
- [ ] 准备演示和展示材料

## 完成标准

每个任务项需要满足以下完成标准：
- ✅ 代码实现完成且功能正常
- ✅ 基础功能验证通过
- ✅ 代码审查完成
- ✅ 文档更新完成

## 优先级说明

- **高优先级**：核心功能，阻塞后续开发
- **中优先级**：重要功能，影响用户体验
- **低优先级**：附加功能，可后续迭代添加

## 预估时间

- **阶段一至二**：2-3 天（项目准备、合约升级、Router 集成和部署）
- **阶段三至四**：3-5 天（前端核心功能和 Router 集成）
- **阶段五**：2-3 天（UI 开发）
- **阶段六至七**：1-2 天（真实合约测试和项目完善）

**总预估时间：8-13 天**