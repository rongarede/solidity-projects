# TokenBank Frontend

极简的TokenBank DApp前端界面，支持ERC20代币的存取操作。

## 功能特性

- 🔗 钱包连接（MetaMask等）
- 💰 余额查询（TEST代币和银行余额）
- 📥 代币存款（自动处理授权）
- 📤 代币取款
- 📊 实时交易状态

## 技术栈

- React + TypeScript
- Viem + Wagmi
- Base主网

## 合约地址

- **TokenBank**: `0xcB76bF429B49397363c36123DF9c2F93627e4f92`
- **TEST Token**: `0x134bd50D5347eE1aD950Dc79B10d17bD1048c7A1`

## 开发运行

```bash
npm install
npm run dev
```

## 生产构建

```bash
npm run build
```

## 使用说明

1. 确保钱包连接到Base主网
2. 点击"Connect Wallet"连接钱包
3. 在存款区域输入金额，点击存款（首次需要授权）
4. 在取款区域输入金额，点击取款
5. 查看余额和交易状态

## 注意事项

- 需要Base主网的ETH支付Gas费
- 首次存款需要先授权代币使用权限
- 交易确认需要等待区块确认