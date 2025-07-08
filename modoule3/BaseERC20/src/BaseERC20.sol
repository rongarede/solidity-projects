// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract BaseERC20 is ERC20 {
    /**
     * @dev 构造函数，创建 BaseERC20 代币
     * 总发行量：100,000,000 个代币（考虑 18 位小数）
     * 所有代币在部署时铸造给部署者
     */
    constructor() ERC20("BaseERC20", "BERC20") {
        // 铸造 100,000,000 个代币给部署者
        // 100,000,000 * 10^18 = 100000000000000000000000000
        _mint(msg.sender, 100_000_000 * 10**decimals());
    }
}