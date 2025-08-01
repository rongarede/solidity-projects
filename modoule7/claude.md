# NFT Marketplace Subgraph 初始化

## 目标
为 Polygon 网络上的 NFT 合约和荷兰拍卖市场合约创建 The Graph subgraph。

## 合约信息
- **网络**: polygon
- **NFT 合约**: `0x690E2728911d9D5738e116F5cb2CF66927Eb3FcF`
- **市场合约**: `0x3fd69c63410b407C714d4535f56F0d7797764eeA`

## 实现路径

### 1. 环境准备
```bash
npm install -g @graphprotocol/graph-cli
```

### 2. 项目初始化
```bash
graph init --from-contract 0x690E2728911d9D5738e116F5cb2CF66927Eb3FcF \
  --network polygon \
  --contract-name MyCollectible \
  nft-marketplace-subgraph

cd nft-marketplace-subgraph
```

### 3. 获取部署区块号
- 访问 polygonscan.com 查看两个合约的部署区块号
- 记录并更新到 subgraph.yaml 中的 startBlock

### 4. 添加第二个合约
- 在 subgraph.yaml 添加市场合约配置
- 创建 `abis/NFTMarketDutchAuction.json`
- 创建 `src/nft-market-dutch-auction.ts`

### 5. 更新 Schema
更新 schema.graphql 定义实体：NFT, Transfer, Auction, Purchase, ApprovalForAll

### 6. 构建部署
```bash
graph codegen
graph build
```

## 关键文件
- `subgraph.yaml` - 配置两个合约
- `schema.graphql` - 定义数据结构  
- `abis/` - 存放合约 ABI
- `src/` - 映射函数

## 下一步
1. 完成初始化
2. 配置第二个合约
3. 测试构建
4. 部署到 Subgraph Studio