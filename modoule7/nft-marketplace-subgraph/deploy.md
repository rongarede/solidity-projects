# 部署到 Subgraph Studio 指南

## 步骤 1: 创建 Subgraph
1. 访问 https://thegraph.com/studio/
2. 使用 GitHub 登录
3. 点击 "Create a Subgraph"
4. 输入名称: `nft-marketplace-polygon`
5. 选择网络: Polygon (Matic)

## 步骤 2: 获取部署信息
从 Studio 页面复制：
- Subgraph slug: `your-username/nft-marketplace-polygon`
- Deploy key: `your-deploy-key`

## 步骤 3: 认证和部署
```bash
# 使用你的 deploy key 认证
graph auth --studio YOUR_DEPLOY_KEY

# 部署到 Studio
graph deploy --studio your-subgraph-slug

# 或者一步完成
graph deploy --studio your-subgraph-slug --access-token YOUR_DEPLOY_KEY
```

## 步骤 4: 监控部署
- 部署后，在 Studio 中查看同步状态
- 等待索引完成（可能需要几分钟到几小时）
- 查看 GraphQL playground 测试查询

## 示例查询
```graphql
{
  nfts(first: 10) {
    id
    tokenId
    owner
    tokenURI
  }
  
  auctions(first: 5, orderBy: createdAtTimestamp, orderDirection: desc) {
    id
    tokenId
    seller
    startingPrice
    endingPrice
    successful
    cancelled
  }
}
```

## 注意事项
- 确保合约地址正确
- 部署区块号应该是合约创建区块或稍早的区块
- 首次同步可能需要较长时间
- 可以在 Studio 中查看日志和错误信息