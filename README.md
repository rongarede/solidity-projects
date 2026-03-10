# Solidity Projects

A collection of Solidity smart contract projects covering DeFi protocols, NFT mechanics, token standards, and on-chain governance — built with Foundry and Hardhat.

## Projects

### Module 2 — ETH Banking
| Project | Description |
|---------|-------------|
| `Bank` | ETH deposit contract with top-3 depositor ranking |
| `BigBank` | Extended Bank with admin controls and access layers |

### Module 3 — Token Standards
| Project | Description |
|---------|-------------|
| `BaseERC20` | Custom ERC-20 token implementation |
| `BaseERC721` | SimpleNFT with basic minting |
| `TokenBank` | ERC-20 deposit vault |
| `ERC20Faucet` | Token faucet for testing |
| `NFTMarket` | Dutch auction NFT marketplace |

### Module 4 — On-Chain Interaction
| Project | Description |
|---------|-------------|
| `TokenBank` | ERC-20 interaction with deploy scripts |
| `ReadChain` | On-chain data reader |
| `cliWallet` | Command-line wallet tool |

### Module 5 — Advanced DeFi
| Project | Description |
|---------|-------------|
| `MultiSigWallet` | Multi-signature wallet contract |
| `UUPS` | Upgradeable proxy (MemeFactory + MemeToken) |
| `TokenVester` | Token vesting with lock schedule |
| `NFTMarket` | Optimized Dutch auction marketplace |
| `uniswapv2` | Full Uniswap V2 fork (core + periphery) with Polygon deploy |

### Module 6 — DeFi Protocols
| Project | Description |
|---------|-------------|
| `CallOption` | On-chain options (OptionSeries) |
| `DAOBank` | DAO governance (VotingToken + Gov + Bank) |
| `FlashSwap` | Flash loan arbitrage (PerfectArbitrage) |
| `launchpund` | Meme token launchpad with Uniswap integration |
| `OnlineOrcle` | Simple TWAP oracle |
| `RebaseToken` | Elastic supply token |
| `StakePool` | Staking pool (KKToken + rewards) |
| `vAMM` | Virtual AMM perpetual DEX |

### Module 7 — The Graph
| Project | Description |
|---------|-------------|
| `meme-token-tracker` | Subgraph for meme token events |
| `nft-marketplace-subgraph` | Subgraph for NFT marketplace |

## Tech Stack

- **Language**: Solidity 0.8+
- **Frameworks**: Foundry (forge/cast/anvil), Hardhat
- **Libraries**: OpenZeppelin, Uniswap V2/V3
- **Testing**: Foundry fuzz testing, unit tests
- **Networks**: Ethereum, Polygon

## License

MIT
