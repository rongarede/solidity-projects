// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";


/**
 * @title TestToken
 * @dev 测试用的 ERC20 代币合约
 */
contract TestToken is ERC20 {
    /**
     * @dev 构造函数
     * 创建总供应量为 1,000,000 个 TST 代币，全部分配给部署者
     */
    constructor() ERC20("TestToken", "TST") {
        // 铸造 1,000,000 个代币给部署者
        // 1,000,000 * 10^18 = 1000000000000000000000000
        _mint(msg.sender, 1_000_000 * 10**decimals());
    }
}