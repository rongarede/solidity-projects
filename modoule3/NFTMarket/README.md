# NFT 荷兰拍卖市场 (NFTMarketDutchAuction)

这是一个基于Solidity实现的去中心化NFT荷兰拍卖市场。该合约允许用户以荷兰拍卖的方式出售其拥有的ERC721标准的NFT。在荷兰拍卖中，资产的价格会随着时间的推移而线性下降，直到有买家出价或达到设定的底价。

## 1. 这是什么？ (What)

`NFTMarketDutchAuction` 是一个智能合约，它提供了一个在以太坊区块链上进行NFT荷兰式拍卖的平台。其核心特性包括：

- **去中心化交易**: 无需中心化机构的介入，买卖双方可以直接通过智能合约进行交易。
- **价格动态调整**: NFT的售价从一个较高的起始价开始，随着预设时间的流逝而平滑地降低，直至达到最低价。
- **ERC721 标准兼容**: 支持任何遵循ERC721标准的NFT进行拍卖。
- **安全设计**: 内置防重入攻击机制，确保交易过程的资金安全。
- **事件驱动**: 关键操作（如创建、成功购买、取消拍卖）都会触发事件，便于链下应用追踪拍卖状态。

## 2. 为什么需要它？ (Why)

传统的NFT定价和销售模式（如固定价格或英式拍卖）存在一些局限性。荷兰拍卖为NFT市场引入了一种高效的价格发现机制：

- **加速销售**: 对于急于出售资产的卖家，荷兰拍卖可以通过动态降价来吸引买家，从而可能比传统拍卖更快地完成交易。
- **减少价格猜测**: 卖家无需精确预测市场的最高出价意愿，只需设定一个价格范围即可。
- **对买家友好**: 买家可以在自己认为价格合适时随时入场，无需在拍卖结束前持续竞价，创造了一种“先到先得”的公平环境。

该项目旨在为NFT生态系统提供一个灵活、安全且高效的交易新选择。

## 3. 如何使用？ (How)

### 合约核心功能

#### 卖家操作

1.  **授权 (Approve)**
    在创建拍卖之前，卖家必须首先授权`NFTMarketDutchAuction`合约转移其想要出售的NFT。这可以通过调用NFT合约的`approve()`或`setApprovalForAll()`函数来完成。

2.  **创建拍卖 (`createAuction`)**
    卖家调用此函数来启动一个新的荷兰拍卖。

    ```solidity
    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startPrice,
        uint256 endPrice,
        uint256 duration
    ) external returns (uint256 auctionId)
    ```

    - `nftContract`: NFT的合约地址。
    - `tokenId`: 要拍卖的NFT的ID。
    - `startPrice`: 拍卖的起始价格（以wei为单位）。
    - `endPrice`: 拍卖的最低价格（以wei为单位）。
    - `duration`: 拍卖的持续时间（以秒为单位）。

    成功创建后，NFT将被转移到拍卖合约中保管，并触发`AuctionCreated`事件。

3.  **取消拍卖 (`cancelAuction`)**
    如果拍卖尚未售出，卖家可以随时取消拍卖。

    ```solidity
    function cancelAuction(uint256 auctionId) external
    ```

    - `auctionId`: 要取消的拍卖ID。

    取消后，NFT将安全地退还给卖家，并触发`AuctionCancelled`事件。

#### 买家操作

1.  **购买NFT (`buy`)**
    买家在拍卖期间可以随时调用此函数购买NFT。

    ```solidity
    function buy(uint256 auctionId) external payable
    ```

    - `auctionId`: 要购买的拍卖ID。

    买家需要发送等于或大于当前拍卖价格的ETH。合约会自动计算当前价格，完成NFT和资金的转移。如果支付的金额超过当前价格，多余的部分将自动退还给买家。交易成功后，触发`AuctionSuccessful`事件。

#### 查询功能

- **获取当前价格 (`getCurrentPrice`)**: 查询指定拍卖的实时价格。
- **获取拍卖信息 (`getAuction`)**: 获取指定拍卖的所有详细信息（卖家、NFT信息、价格、状态等）。
- **检查拍卖是否过期 (`isAuctionExpired`)**: 检查一个拍卖是否已经结束。

### 本地开发与测试

本项目使用 [Foundry](https://github.com/foundry-rs/foundry)进行开发和测试。

1.  **安装 Foundry**:
    ```bash
    curl -L https://foundry.paradigm.xyz | bash
    foundryup
    ```

2.  **安装依赖**:
    ```bash
    forge install
    ```

3.  **运行测试**:
    ```bash
    forge test
    ```

    测试覆盖了所有核心功能，包括正常流程、边界条件和安全检查。

## 4. 如何贡献？ (How to Contribute)

我们欢迎社区的贡献！如果您发现了bug或有功能改进的建议，请遵循以下步骤：

1.  **Fork** 本仓库。
2.  创建一个新的分支 (`git checkout -b feature/your-feature-name`)。
3.  进行修改并编写相应的测试用例。
4.  确保所有测试都通过 (`forge test`)。
5.  提交您的修改 (`git commit -m 'Add some feature'`)。
6.  将您的分支推送到GitHub (`git push origin feature/your-feature-name`)。
7.  创建一个 **Pull Request**。

## +1. 注意事项与未来展望

### 安全考虑

- **防重入**: 合约使用了OpenZeppelin的`ReentrancyGuard`来防止在支付过程中发生重入攻击。
- **参数验证**: `createAuction`函数对输入参数进行了严格的检查，确保拍卖参数的有效性（如起始价必须高于结束价）。
- **所有权与授权**: 在创建拍卖时，合约会验证`msg.sender`是否为NFT的真正所有者，并检查合约是否获得了转移授权。

### 未来展望

- **版税标准支持**: 集成EIP-2981版税标准，使版税能够在拍卖成功后自动支付给创作者。
- **批量拍卖**: 增加对批量创建荷兰拍卖的支持，方便拥有大量NFT的用户。
- **前端集成**: 开发一个用户友好的前端界面，简化用户与合约的交互。
- **多代币支付**: 支持使用ERC20代币（如WETH, DAI）进行支付。
