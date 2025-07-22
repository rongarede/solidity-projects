# Uniswap V2 Base链 + Viem 完整部署方案

## 项目概述

本文档详细描述了如何将 Uniswap V2 核心合约部署到 Base 链，并使用 Viem 框架构建前端应用的完整方案。

## 一、Base链合约部署方案

### 1. Base网络配置

- **Base Mainnet**: Chain ID 8453
- **Base Sepolia (测试网)**: Chain ID 84532
- **RPC**: 
  - 主网: https://mainnet.base.org
  - 测试网: https://sepolia.base.org
- **区块浏览器**: https://basescan.org

### 2. 环境准备

```bash
# 安装 Foundry (推荐)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# 或使用 Hardhat
npm install --save-dev hardhat
```

### 3. 部署配置

#### Foundry 配置 (foundry.toml)

```toml
[profile.default]
src = "contracts"
out = "out"
libs = ["lib"]
solc_version = "0.5.16"

[rpc_endpoints]
base_mainnet = "https://mainnet.base.org"
base_sepolia = "https://sepolia.base.org"

[etherscan]
base = { key = "${BASESCAN_API_KEY}", url = "https://api.basescan.org/api" }
```

### 4. 部署脚本

#### 部署 UniswapV2Factory

```bash
# 测试网部署
forge create --rpc-url base_sepolia \
  --private-key $PRIVATE_KEY \
  --verify --etherscan-api-key $BASESCAN_API_KEY \
  contracts/UniswapV2Factory.sol:UniswapV2Factory \
  --constructor-args $FEE_TO_SETTER

# 主网部署
forge create --rpc-url base_mainnet \
  --private-key $PRIVATE_KEY \
  --verify --etherscan-api-key $BASESCAN_API_KEY \
  contracts/UniswapV2Factory.sol:UniswapV2Factory \
  --constructor-args $FEE_TO_SETTER
```

### 5. 合约部署顺序

1. **UniswapV2Factory** - 核心工厂合约
2. **测试代币** (可选) - 用于创建交易对测试
3. **记录合约地址** - 保存到配置文件供前端使用

### 6. 部署后验证

- 验证合约在 Basescan 上的状态
- 测试 Factory 合约的 createPair 功能
- 确认事件日志正常输出

## 二、Viem 前端架构方案

### 1. 技术栈选择

```json
{
  "框架": "Next.js 14 (App Router)",
  "类型系统": "TypeScript",
  "区块链库": "Viem + Wagmi",
  "UI组件": "shadcn/ui + Tailwind CSS",
  "状态管理": "Zustand",
  "图表库": "Recharts",
  "样式": "Tailwind CSS",
  "钱包连接": "ConnectKit"
}
```

### 2. 项目初始化

```bash
# 创建 Next.js 项目
npx create-next-app@latest uniswap-v2-frontend --typescript --tailwind --app

# 安装核心依赖
npm install viem wagmi @wagmi/core @wagmi/connectors
npm install @tanstack/react-query

# 安装 UI 组件
npx shadcn-ui@latest init
npm install connectkit

# 安装状态管理和工具
npm install zustand
npm install recharts
```

### 3. 项目结构

```
src/
├── app/                    # Next.js App Router
│   ├── globals.css
│   ├── layout.tsx
│   ├── page.tsx
│   ├── swap/
│   │   └── page.tsx
│   └── pool/
│       └── page.tsx
├── components/             # UI 组件
│   ├── ui/                # shadcn/ui 基础组件
│   ├── layout/            # 布局组件
│   │   ├── Header.tsx
│   │   ├── Footer.tsx
│   │   └── Sidebar.tsx
│   ├── swap/              # 交换相关组件
│   │   ├── SwapCard.tsx
│   │   ├── TokenSelect.tsx
│   │   └── SwapButton.tsx
│   ├── pool/              # 流动性池组件
│   │   ├── PoolCard.tsx
│   │   ├── AddLiquidity.tsx
│   │   └── RemoveLiquidity.tsx
│   └── wallet/            # 钱包组件
│       ├── ConnectButton.tsx
│       └── WalletInfo.tsx
├── hooks/                 # 自定义 hooks
│   ├── useSwap.ts
│   ├── usePool.ts
│   ├── useTokenBalance.ts
│   └── useTokenPrice.ts
├── lib/                   # 工具库和配置
│   ├── viem.ts           # Viem 配置
│   ├── wagmi.ts          # Wagmi 配置
│   ├── contracts.ts      # 合约配置和 ABI
│   ├── tokens.ts         # 代币列表配置
│   └── utils.ts          # 工具函数
├── store/                # Zustand 状态管理
│   ├── useSwapStore.ts
│   ├── usePoolStore.ts
│   └── useUserStore.ts
├── types/                # TypeScript 类型定义
│   ├── contracts.ts
│   ├── tokens.ts
│   └── swap.ts
└── constants/            # 常量配置
    ├── chains.ts
    ├── contracts.ts
    └── tokens.ts
```

### 4. Viem 核心配置

#### lib/viem.ts

```typescript
import { createPublicClient, createWalletClient, http } from 'viem'
import { base, baseSepolia } from 'viem/chains'

export const publicClient = createPublicClient({
  chain: base,
  transport: http('https://mainnet.base.org')
})

export const testPublicClient = createPublicClient({
  chain: baseSepolia,
  transport: http('https://sepolia.base.org')
})
```

#### lib/wagmi.ts

```typescript
import { createConfig, http } from 'wagmi'
import { base, baseSepolia } from 'wagmi/chains'
import { coinbaseWallet, metaMask, walletConnect } from 'wagmi/connectors'

export const wagmiConfig = createConfig({
  chains: [base, baseSepolia],
  connectors: [
    metaMask(),
    coinbaseWallet({ appName: 'Uniswap V2 Clone' }),
    walletConnect({ projectId: 'your-project-id' })
  ],
  transports: {
    [base.id]: http('https://mainnet.base.org'),
    [baseSepolia.id]: http('https://sepolia.base.org')
  }
})
```

#### lib/contracts.ts

```typescript
import { Address } from 'viem'

export const CONTRACT_ADDRESSES = {
  [base.id]: {
    factory: '0x...' as Address, // 部署后的 Factory 地址
  },
  [baseSepolia.id]: {
    factory: '0x...' as Address, // 测试网 Factory 地址
  }
}

export const FACTORY_ABI = [
  // UniswapV2Factory ABI
] as const

export const PAIR_ABI = [
  // UniswapV2Pair ABI
] as const
```

### 5. 核心功能实现

#### 钱包连接组件

```typescript
// components/wallet/ConnectButton.tsx
import { ConnectKitButton } from 'connectkit'

export function ConnectButton() {
  return (
    <ConnectKitButton.Custom>
      {({ isConnected, show, truncatedAddress, ensName }) => (
        <button onClick={show}>
          {isConnected ? ensName ?? truncatedAddress : "Connect Wallet"}
        </button>
      )}
    </ConnectKitButton.Custom>
  )
}
```

#### 交换功能 Hook

```typescript
// hooks/useSwap.ts
import { useWriteContract, useReadContract } from 'wagmi'
import { parseUnits } from 'viem'

export function useSwap() {
  const { writeContract } = useWriteContract()
  
  const swapExactTokensForTokens = async (
    amountIn: string,
    amountOutMin: string,
    path: Address[],
    to: Address,
    deadline: bigint
  ) => {
    return writeContract({
      address: ROUTER_ADDRESS,
      abi: ROUTER_ABI,
      functionName: 'swapExactTokensForTokens',
      args: [
        parseUnits(amountIn, 18),
        parseUnits(amountOutMin, 18),
        path,
        to,
        deadline
      ]
    })
  }

  return { swapExactTokensForTokens }
}
```

### 6. 状态管理

#### store/useSwapStore.ts

```typescript
import { create } from 'zustand'

interface SwapState {
  tokenA: Token | null
  tokenB: Token | null
  amountA: string
  amountB: string
  slippage: number
  setTokenA: (token: Token) => void
  setTokenB: (token: Token) => void
  setAmountA: (amount: string) => void
  setAmountB: (amount: string) => void
  setSlippage: (slippage: number) => void
  swapTokens: () => void
}

export const useSwapStore = create<SwapState>((set, get) => ({
  tokenA: null,
  tokenB: null,
  amountA: '',
  amountB: '',
  slippage: 0.5,
  setTokenA: (token) => set({ tokenA: token }),
  setTokenB: (token) => set({ tokenB: token }),
  setAmountA: (amount) => set({ amountA: amount }),
  setAmountB: (amount) => set({ amountB: amount }),
  setSlippage: (slippage) => set({ slippage }),
  swapTokens: () => {
    const { tokenA, tokenB } = get()
    set({ tokenA: tokenB, tokenB: tokenA })
  }
}))
```

## 三、开发流程

### 1. 环境搭建

```bash
# 1. 克隆项目
git clone <your-repo>
cd uniswap-v2-frontend

# 2. 安装依赖
npm install

# 3. 配置环境变量
cp .env.example .env.local
# 编辑 .env.local 添加必要配置

# 4. 启动开发服务器
npm run dev
```

### 2. 合约集成步骤

1. **生成合约类型**
   ```bash
   # 使用 wagmi cli 生成类型
   npx wagmi generate
   ```

2. **配置合约地址**
   - 更新 `constants/contracts.ts`
   - 添加正确的合约地址和 ABI

3. **测试合约调用**
   - 先在测试网验证功能
   - 确保所有合约方法正常工作

### 3. 功能开发顺序

1. **基础设施**
   - 钱包连接功能
   - 网络切换
   - 基础 UI 组件

2. **代币管理**
   - 代币列表加载
   - 余额查询
   - 代币选择器

3. **交换功能**
   - 价格计算
   - 滑点设置
   - 交换执行

4. **流动性管理**
   - 添加流动性
   - 移除流动性
   - LP 代币管理

5. **用户体验**
   - 交易历史
   - 价格图表
   - 通知系统

### 4. 测试策略

```bash
# 单元测试
npm run test

# E2E 测试
npm run test:e2e

# 类型检查
npm run type-check

# 代码规范检查
npm run lint
```

### 5. 部署上线

#### Vercel 部署

```bash
# 1. 安装 Vercel CLI
npm i -g vercel

# 2. 登录并部署
vercel login
vercel --prod

# 3. 配置环境变量
# 在 Vercel 控制台添加生产环境变量
```

#### 环境变量配置

```env
# .env.local
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_project_id
NEXT_PUBLIC_FACTORY_ADDRESS_MAINNET=0x...
NEXT_PUBLIC_FACTORY_ADDRESS_TESTNET=0x...
NEXT_PUBLIC_ENABLE_TESTNETS=true
```

## 四、安全考虑

### 1. 智能合约安全

- 使用 Slither 进行合约安全分析
- 实施交易滑点保护
- 设置合理的交易截止时间

### 2. 前端安全

- 验证所有用户输入
- 实施 CSP (Content Security Policy)
- 使用 HTTPS 部署

### 3. 用户资金安全

- 明确显示交易详情
- 实施交易确认流程
- 提供交易状态实时更新

## 五、监控和维护

### 1. 应用监控

- 集成 Sentry 错误监控
- 设置性能监控
- 配置用户行为分析

### 2. 合约监控

- 监控合约事件
- 设置异常交易告警
- 定期检查合约状态

### 3. 持续优化

- 定期更新依赖包
- 优化 gas 费用
- 改进用户界面

---

## 总结

本方案提供了完整的 Uniswap V2 在 Base 链上的部署和前端开发指南，使用现代化的 Viem 技术栈确保了类型安全和优秀的开发体验。通过遵循本文档的步骤，可以构建一个功能完整、安全可靠的去中心化交易所应用。