// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract NetworkConfig {
    struct Config {
        address router;
        address weth;
        string name;
    }

    mapping(uint256 => Config) public networkConfigs;

    constructor() {
        // Ethereum Mainnet
        networkConfigs[1] = Config({
            router: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
            weth: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            name: "Ethereum Mainnet"
        });

        // Polygon Mainnet
        networkConfigs[137] = Config({
            router: 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff, // QuickSwap
            weth: 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270, // WMATIC
            name: "Polygon Mainnet"
        });

        // Sepolia Testnet
        networkConfigs[11155111] = Config({
            router: 0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008,
            weth: 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9,
            name: "Sepolia Testnet"
        });

        // Local Anvil (default to Ethereum addresses for testing)
        networkConfigs[31337] = Config({
            router: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
            weth: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            name: "Local Anvil"
        });
    }

    function getConfig(uint256 chainId) external view returns (Config memory) {
        Config memory config = networkConfigs[chainId];
        require(config.router != address(0), "Unsupported network");
        return config;
    }

    function getConfigForCurrentChain() external view returns (Config memory) {
        return this.getConfig(block.chainid);
    }
}