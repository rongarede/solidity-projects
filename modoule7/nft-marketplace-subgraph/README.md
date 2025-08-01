# NFT Marketplace Subgraph

A [The Graph](https://thegraph.com/) subgraph for indexing NFT marketplace events on Polygon network. This subgraph tracks NFT transfers, approvals, auction creation, and purchase events from both the NFT contract and Dutch auction marketplace contract.

## 📋 Overview

This subgraph indexes two smart contracts on Polygon:

- **NFT Contract (MyCollectible)**: `0x690E2728911d9D5738e116F5cb2CF66927Eb3FcF`
- **Dutch Auction Market**: `0x3fd69c63410b407C714d4535f56F0d7797764eeA`

## 🏗️ Schema

### Entities

- **NFT**: Represents individual NFT tokens with metadata
- **Transfer**: Records all NFT transfer events
- **Approval**: Tracks NFT approval events
- **ApprovalForAll**: Records operator approval events
- **Auction**: Stores Dutch auction information
- **Purchase**: Records successful NFT purchases

## 🚀 Getting Started

### Prerequisites

```bash
npm install -g @graphprotocol/graph-cli
```

### Installation

1. Clone and navigate to the project:
```bash
cd nft-marketplace-subgraph
npm install
```

2. Generate code from schema:
```bash
npm run codegen
```

3. Build the subgraph:
```bash
npm run build
```

## 📝 Available Scripts

- `npm run codegen` - Generate AssemblyScript types from GraphQL schema
- `npm run build` - Build the subgraph
- `npm run deploy` - Deploy to hosted service
- `npm run create-local` - Create subgraph on local Graph node
- `npm run deploy-local` - Deploy to local Graph node

## 📊 Tracked Events

### NFT Contract Events
- `Transfer` - NFT ownership transfers
- `Approval` - Single token approvals
- `ApprovalForAll` - Operator approvals

### Marketplace Events
- `AuctionCreated` - New Dutch auctions
- `AuctionSuccessful` - Completed purchases
- `AuctionCancelled` - Cancelled auctions

## 🔧 Configuration

The subgraph is configured in `subgraph.yaml` with:
- Network: `matic` (Polygon)
- Start block: `20000000`
- Event handlers for both contracts

## 📁 Project Structure

```
├── abis/                           # Contract ABI files
│   ├── MyCollectible.json
│   └── NFTMarketDutchAuction.json
├── src/                            # Mapping functions
│   ├── my-collectible.ts
│   └── nft-market-dutch-auction.ts
├── schema.graphql                  # GraphQL schema
├── subgraph.yaml                   # Subgraph configuration
└── package.json                    # Dependencies and scripts
```

## 🌐 Network Information

- **Network**: Polygon (Matic)
- **Chain ID**: 137
- **Explorer**: [Polygonscan](https://polygonscan.com/)

## 📜 License

UNLICENSED

## 🛠️ Development

For local development and testing:

1. Run a local Graph node
2. Create the subgraph locally: `npm run create-local`
3. Deploy to local node: `npm run deploy-local`

## 📚 Resources

- [The Graph Documentation](https://thegraph.com/docs/)
- [AssemblyScript API](https://thegraph.com/docs/en/developing/assemblyscript-api/)
- [Polygon Network Info](https://polygon.technology/)