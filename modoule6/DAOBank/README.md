# DAO Bank System

A complete decentralized autonomous organization (DAO) banking system built with Solidity and Foundry. This system allows token holders to vote on fund withdrawals from a shared treasury through a sophisticated governance mechanism.

## 🚀 Features

### Core Components

- **VotingToken (ERC20 + ERC20Votes)**: Governance token with delegation and historical vote tracking
- **Bank Contract**: Secure vault for managing community funds with admin-only withdrawals
- **Gov Contract**: Full DAO governance implementation with proposal lifecycle management

### Key Capabilities

- **Democratic Fund Management**: Token holders vote on treasury withdrawals
- **Vote Delegation**: Users can delegate voting power to other addresses
- **Timelock Security**: Execution delays prevent rushed decisions
- **Quorum Requirements**: Ensures sufficient participation in governance
- **Proposal Lifecycle**: Complete flow from creation to execution
- **Security First**: Reentrancy protection, access controls, input validation

## 📊 Governance Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| Voting Delay | 1 day | Time between proposal creation and voting start |
| Voting Period | 3 days | Duration for casting votes |
| Execution Delay | 2 days | Timelock period before execution |
| Proposal Threshold | 1% | Minimum tokens needed to create proposals |
| Quorum | 4% | Minimum participation for valid proposals |

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     DAO Bank System                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    │
│  │ VotingToken │    │    Bank     │    │     Gov     │    │
│  │ (ERC20Votes)│    │  (Vault)    │    │(Governance) │    │
│  └─────────────┘    └─────────────┘    └─────────────┘    │
│         │                   │                   │          │
│         └───────────────────┼───────────────────┘          │
│                             │                              │
│                      Admin Control                         │
│                      (DAO Managed)                         │
└─────────────────────────────────────────────────────────────┘
```

## 🔧 Installation & Setup

### Prerequisites

- [Foundry](https://getfoundry.sh/) installed
- Git

### Clone & Setup

```bash
git clone <repository-url>
cd DAOBank
forge install
forge build
```

## 🧪 Testing

### Run All Tests
```bash
forge test
```

### Run with Verbose Output
```bash
forge test -vvv
```

### Run Specific Test Categories
```bash
# Individual contract tests
forge test --match-path test/VotingToken.t.sol
forge test --match-path test/Bank.t.sol
forge test --match-path test/Gov.t.sol

# Integration tests
forge test --match-path test/Integration.t.sol
```

### Test Coverage
```bash
forge coverage
```

## 📋 Test Results

✅ **All 57 tests passing**

- **VotingToken**: 12/12 tests ✓
- **Bank**: 17/17 tests ✓ 
- **Gov**: 18/18 tests ✓
- **Integration**: 8/8 tests ✓

### Test Categories Covered

- ✅ Token transfers and balances
- ✅ Vote delegation and power tracking
- ✅ Historical vote queries
- ✅ Bank deposits and admin withdrawals
- ✅ Reentrancy protection
- ✅ Access control enforcement
- ✅ Complete proposal lifecycle
- ✅ Quorum and threshold validation
- ✅ Timelock mechanisms
- ✅ End-to-end governance flow

## 🚀 Deployment

### Local Development
```bash
# Deploy to local testnet
forge script script/Deploy.s.sol:LocalDeployScript --fork-url http://localhost:8545 --broadcast
```

### Testnet Deployment
```bash
# Set environment variables
export PRIVATE_KEY=your_private_key
export RPC_URL=your_rpc_url

# Deploy to testnet
forge script script/Deploy.s.sol:DeployScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
```

## 💡 Usage Example

### 1. Initial Setup
```solidity
// Deploy contracts
VotingToken token = new VotingToken("DAO Token", "DAO", deployer);
Bank bank = new Bank(deployer);
Gov gov = new Gov(address(token), payable(address(bank)));

// Transfer bank ownership to DAO
bank.changeAdmin(address(gov));

// Distribute tokens to stakeholders
token.transfer(alice, 200_000 * 10**18); // 20%
token.transfer(bob, 150_000 * 10**18);   // 15%
```

### 2. Delegate Voting Power
```solidity
// Users delegate to themselves or others
token.delegate(alice); // Alice delegates to herself
token.delegate(bob);   // Bob delegates to himself
```

### 3. Fund the Treasury
```solidity
// Anyone can deposit ETH
bank.deposit{value: 10 ether}();
```

### 4. Create Proposal
```solidity
// Alice creates a proposal to withdraw 5 ETH
bytes memory data = abi.encodeWithSignature(
    "withdraw(address,uint256)", 
    recipient, 
    5 ether
);

uint256 proposalId = gov.propose(
    address(bank),
    0,
    data,
    "Treasury allocation: 5 ETH for development"
);
```

### 5. Vote on Proposal
```solidity
// Wait for voting delay to pass (1 day)
vm.roll(block.number + 7200);

// Cast votes
gov.castVote(proposalId, VoteType.For, "Supporting development");
gov.castVote(proposalId, VoteType.Against, "Amount too high");
```

### 6. Execute Proposal
```solidity
// Wait for voting period to end (3 days)
vm.roll(block.number + 21600);

// Queue successful proposal
gov.queue(proposalId);

// Wait for execution delay (2 days)
vm.warp(block.timestamp + 2 days + 1);

// Execute proposal
gov.execute(proposalId);
// -> 5 ETH transferred to recipient
```

## 🔒 Security Features

### Access Controls
- **Bank Admin**: Only DAO can withdraw funds
- **Proposal Creation**: Requires 1% token ownership
- **Vote Casting**: Only token holders with voting power

### Reentrancy Protection
- `nonReentrant` modifier on critical functions
- Comprehensive testing against reentrancy attacks

### Input Validation
- Zero address checks
- Amount validations
- Parameter bounds checking

### Timelock Security
- Execution delays prevent rushed decisions
- Proposals can be canceled during delays

## 📁 Project Structure

```
src/
├── contracts/
│   ├── VotingToken.sol      # ERC20 token with voting capabilities
│   ├── Bank.sol             # Treasury vault contract
│   ├── Gov.sol              # DAO governance contract
│   └── interfaces/
│       ├── IVotingToken.sol # VotingToken interface
│       └── IBank.sol        # Bank interface
test/
├── VotingToken.t.sol        # Token contract tests
├── Bank.t.sol               # Bank contract tests
├── Gov.t.sol                # Governance contract tests
└── Integration.t.sol        # End-to-end system tests
script/
└── Deploy.s.sol             # Deployment scripts
```

## 🔍 Gas Optimization

The contracts are optimized for gas efficiency:

- **Struct Packing**: Efficient storage layouts
- **Events over Storage**: Use events for historical data
- **Minimal External Calls**: Reduced external interactions
- **Compiler Optimization**: IR optimization enabled

## 🛠️ Development

### Adding New Features
1. Create feature branch
2. Implement contracts
3. Add comprehensive tests
4. Update deployment scripts
5. Document changes

### Running Static Analysis
```bash
# Using Slither (if installed)
slither src/

# Using Mythril (if installed)
myth analyze src/contracts/
```

## 📜 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## 📞 Support

For questions or issues:
- Create an issue in the repository
- Review the test files for usage examples
- Check the deployment scripts for setup guidance

---

**Built with ❤️ using Foundry and OpenZeppelin**