# Uniswap V2 DApp - Multi-Chain DEX Implementation

A complete decentralized exchange (DEX) implementation based on Uniswap V2 protocol, supporting both **Polygon** and **Base** networks with significantly reduced gas costs.

[![Solidity](https://img.shields.io/badge/Solidity-0.8+-blue.svg)](https://soliditylang.org/)
[![Next.js](https://img.shields.io/badge/Next.js-15-black.svg)](https://nextjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5-blue.svg)](https://www.typescriptlang.org/)
[![Foundry](https://img.shields.io/badge/Foundry-✓-red.svg)](https://getfoundry.sh/)

## 🌟 Features

- **Token Swapping**: Exchange any ERC20 tokens with automatic price calculation
- **Liquidity Management**: Add/remove liquidity to earn trading fees
- **Multi-Chain Support**: Deploy on Polygon (low fees) and Base networks
- **Pool Analytics**: View all trading pairs and liquidity pools
- **Wallet Integration**: Support for MetaMask and Coinbase Wallet
- **Real-time Pricing**: Live price updates from on-chain data
- **Error Monitoring**: Comprehensive logging and error tracking

## 🏗️ Tech Stack

### Smart Contracts
- **Solidity 0.8+** with Foundry framework
- **Uniswap V2 Core Protocol** (Factory, Router, Pair contracts)
- **MockWETH** for independent testing environments

### Frontend
- **Next.js 15** with App Router
- **TypeScript** for type safety
- **Tailwind CSS** for styling
- **viem** & **wagmi** for blockchain interaction
- **Zustand** for state management
- **React Query** for data fetching

### Networks
- **Polygon Mainnet** (137) - Ultra-low fees (~$0.03 per transaction)
- **Base Mainnet** (8453) - Low fees (~$1-3 per transaction)

## 📁 Project Structure

```
modoule5/
├── README.md                          # This file
├── components.json                    # UI components config
│
├── v2-core/                          # 🔹 Smart Contracts (Foundry)
│   ├── contracts/
│   │   ├── UniswapV2Factory.sol
│   │   ├── UniswapV2Router02.sol
│   │   ├── UniswapV2Pair.sol
│   │   ├── UniswapV2ERC20.sol
│   │   ├── interfaces/               # Contract interfaces
│   │   ├── libraries/                # Shared libraries
│   │   └── test/                     # Mock contracts
│   ├── script/                       # Deployment scripts
│   │   ├── DeployFactory.s.sol
│   │   ├── DeployRouter.s.sol
│   │   ├── DeployFactoryPolygon.s.sol
│   │   └── DeployRouterPolygon.s.sol
│   ├── test/                         # Contract tests
│   ├── contracts-addresses.json      # Base network addresses
│   ├── contracts-addresses-polygon.json # Polygon addresses
│   ├── todo.md                       # Development roadmap
│   └── movetopolygontodo.md         # Polygon migration plan
│
├── v2-frontend/                      # 🔹 Web Application (Next.js)
│   ├── src/
│   │   ├── app/                      # App Router pages
│   │   │   ├── swap/                 # Token swap page
│   │   │   ├── add-liquidity/        # Add liquidity page
│   │   │   ├── pools/                # Pools overview
│   │   │   └── api/                  # API routes
│   │   ├── components/               # React components
│   │   │   ├── swap/                 # Swap-related UI
│   │   │   ├── liquidity/            # Liquidity management
│   │   │   ├── wallet/               # Wallet connection
│   │   │   └── ui/                   # Reusable UI components
│   │   ├── hooks/                    # Custom React hooks
│   │   ├── lib/                      # Utility libraries
│   │   │   ├── contracts.ts          # Contract configurations
│   │   │   ├── tokens.ts             # Token definitions
│   │   │   ├── wagmi.ts              # Wallet configuration
│   │   │   └── utils.ts              # Helper functions
│   │   ├── store/                    # State management
│   │   └── types/                    # TypeScript definitions
│   ├── docs/                         # Documentation assets
│   ├── logs/                         # Error logging
│   └── public/                       # Static assets
│
├── safewallet/                       # 🔸 Additional Projects
├── NFTMarket/                        # NFT marketplace implementation
├── MultiSigWallet/                   # Multi-signature wallet
├── LockCoin/                         # Token vesting contract
├── ReadLock/                         # Read-only lock mechanism
├── UUPS/                            # Upgradeable proxy pattern
├── frontend/                        # Legacy frontend
├── polygon-test/                    # Polygon testing environment
└── protocol-v2/                     # Aave V2 protocol reference
```

## 🚀 Quick Start

### Prerequisites
- **Node.js** 18+ and npm/yarn
- **Foundry** for smart contract development
- **Git** for version control
- **Wallet** (MetaMask or Coinbase Wallet)
- **MATIC** tokens for Polygon gas fees

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd modoule5
```

2. **Install dependencies**

Smart Contracts:
```bash
cd v2-core
forge install
```

Frontend:
```bash
cd v2-frontend
npm install
```

3. **Environment Setup**

Create `.env` file in `v2-core`:
```bash
PRIVATE_KEY=your_private_key_here
POLYGONSCAN_API_KEY=your_polygonscan_api_key
```

4. **Start Development**

Frontend (in `v2-frontend` directory):
```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

## 🌐 Deployed Contracts

### Polygon Mainnet (Chain ID: 137)
- **Factory**: [`0xAd359064D6315e30045D24dCBd41A078Fc8DfacC`](https://polygonscan.com/address/0xAd359064D6315e30045D24dCBd41A078Fc8DfacC)
- **Router**: [`0x3ebaF23B04ee529EA55f67ea934699185Dd91D25`](https://polygonscan.com/address/0x3ebaF23B04ee529EA55f67ea934699185Dd91D25)
- **MockWETH**: [`0xaEC13518815Fb88ad241dC945e00dAe350c426Db`](https://polygonscan.com/address/0xaEC13518815Fb88ad241dC945e00dAe350c426Db)
- **Test Token A (TTA)**: [`0xcB76bF429B49397363c36123DF9c2F93627e4f92`](https://polygonscan.com/address/0xcB76bF429B49397363c36123DF9c2F93627e4f92)
- **Test Token B (TTB)**: [`0x7822811bF7b966611aD456F285298f9b4cda053b`](https://polygonscan.com/address/0x7822811bF7b966611aD456F285298f9b4cda053b)

**Deployment Cost**: 0.178 POL (~$0.10 USD)

### Base Mainnet (Chain ID: 8453)
- **Factory**: `0x2E2812638232c64eeC81B4a2DFd4ca975887d571`
- **Router**: `0xcEc76053fBa3fDB41570B816bc42d4DB7497bC72`
- **MockWETH**: `0x7Ff8501f89DBFde83ad5b46ce04a508403a28700`

## 💰 Gas Cost Comparison

| Operation | Base Network | Polygon | Savings |
|-----------|--------------|---------|---------|
| Token Swap | $1-3 | $0.01-0.03 | 99%+ |
| Add Liquidity | $2-5 | $0.02-0.05 | 95%+ |
| Token Approval | $0.5-1 | $0.005-0.01 | 99%+ |
| Remove Liquidity | $2-4 | $0.02-0.04 | 95%+ |

**Result**: Polygon offers 95-99% gas fee reduction compared to Base network!

## 🛠️ Development

### Smart Contract Development

```bash
cd v2-core

# Compile contracts
forge build

# Run tests
forge test

# Deploy to Polygon
forge script script/DeployFactoryPolygon.s.sol --rpc-url https://polygon-rpc.com --broadcast --verify

# Deploy to Base
forge script script/DeployFactory.s.sol --rpc-url https://mainnet.base.org --broadcast --verify
```

### Frontend Development

```bash
cd v2-frontend

# Start development server
npm run dev

# Build for production
npm run build

# Type checking
npm run lint
```

### Testing

```bash
# Test smart contracts
cd v2-core
forge test -vv

# Test specific contract
forge test --match-contract UniswapV2Router02BasicTest

# Gas report
forge test --gas-report
```

## 🔗 API Routes

### Frontend Routes
- **`/`** - Home page with feature overview
- **`/swap`** - Token swapping interface
- **`/add-liquidity`** - Add liquidity to pools
- **`/pools`** - View all trading pairs
- **`/liquidity`** - Manage your liquidity positions

### API Endpoints
- **`/api/log-error`** - Error logging endpoint (POST)

## 🔧 Configuration

### Network Configuration (wagmi.ts)
```typescript
export const config = createConfig({
  chains: [polygon], // or [base] for Base network
  connectors: [metaMask(), coinbaseWallet()],
  transports: {
    [polygon.id]: http('https://polygon-rpc.com'),
  },
})
```

### Contract Configuration (contracts.ts)
All contract addresses and ABIs are configured in `src/lib/contracts.ts` with automatic network detection.

## 🐛 Troubleshooting

### Common Issues

1. **"Failed to fetch" Error**
   - Check network connection to RPC endpoint
   - Verify contract addresses are correct for selected network
   - Ensure wallet is connected to the right network

2. **Transaction Fails**
   - Check token balances and allowances
   - Verify slippage tolerance is sufficient
   - Ensure gas limit is adequate

3. **Wallet Connection Issues**
   - Clear browser cache and MetaMask cache
   - Check if correct network is selected
   - Verify wallet has sufficient native tokens for gas

4. **Input Field Issues**
   - If amounts keep changing, check for useEffect loops
   - Clear local storage if state is corrupted
   - Refresh the page to reset component state

### Network Configuration

**Add Polygon Network to MetaMask**:
- Network Name: `Polygon`
- RPC URL: `https://polygon-rpc.com`
- Chain ID: `137`
- Currency Symbol: `MATIC`
- Block Explorer: `https://polygonscan.com`

## 📖 Documentation

- **Smart Contracts**: See `v2-core/README.md`
- **Frontend**: See `v2-frontend/README.md`
- **Development Tasks**: See `v2-core/todo.md`
- **Polygon Migration**: See `v2-core/movetopolygontodo.md`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

This project is licensed under the GPL-3.0 License - see the [LICENSE](v2-core/LICENSE) file for details.

## 🙏 Acknowledgments

- **Uniswap Labs** for the original V2 protocol design
- **Foundry** team for excellent development tools
- **wagmi** and **viem** for Web3 integration
- **Next.js** team for the amazing React framework

## 📞 Support

For issues and questions:
- Open an issue on GitHub
- Check existing documentation in `/docs` folders
- Review error logs in `v2-frontend/logs/error-log.txt`

---

**Built with ❤️ for the DeFi community**