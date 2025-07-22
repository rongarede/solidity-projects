// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract TokenBank {
    // BaseERC20 代币合约接口
    IERC20 public immutable token;
    
    // 记录每个用户的存款余额
    mapping(address => uint256) public balances;
    
    // 记录总存款金额
    uint256 public totalDeposits;
    
    // 重入保护状态变量
    bool private _locked;
    
    // 重入保护修饰符
    modifier nonReentrant() {
        require(!_locked, "ReentrancyGuard: reentrant call");
        _locked = true;
        _;
        _locked = false;
    }
    
    // 事件
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    
    // 错误定义
    error InsufficientBalance();
    error ZeroAmount();
    error TransferFailed();
    
    /**
     * @dev 构造函数
     * @param _token BaseERC20 代币合约地址
     */
    constructor(address _token) {
        require(_token != address(0), "Token address cannot be zero");
        token = IERC20(_token);
    }
    
    /**
     * @dev 存入代币
     * @param amount 存入的代币数量
     * 
     * 注意：用户需要先调用 token.approve(address(this), amount) 授权
     */
    function deposit(uint256 amount) external nonReentrant {
        if (amount == 0) {
            revert ZeroAmount();
        }
        
        // 从用户账户转移代币到本合约
        bool success = token.transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert TransferFailed();
        }
        
        // 更新用户余额和总存款
        balances[msg.sender] += amount;
        totalDeposits += amount;
        
        emit Deposit(msg.sender, amount);
    }
    
    /**
     * @dev 取出代币
     * @param amount 取出的代币数量
     */
    function withdraw(uint256 amount) external nonReentrant {
        if (amount == 0) {
            revert ZeroAmount();
        }
        
        if (balances[msg.sender] < amount) {
            revert InsufficientBalance();
        }
        
        // ✅ 遵循 CEI 模式：先更新状态，再转账
        balances[msg.sender] -= amount;
        totalDeposits -= amount;
        
        bool success = token.transfer(msg.sender, amount);
        if (!success) {
            revert TransferFailed();
        }
        
        emit Withdraw(msg.sender, amount);
    }
    
    /**
     * @dev 查询用户的存款余额
     * @param user 用户地址
     * @return 用户的存款余额
     */
    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
    
    /**
     * @dev 查询合约中的代币总余额
     * @return 合约持有的代币总量
     */
    function getContractBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
    
    /**
     * @dev 获取代币合约地址
     * @return 代币合约地址
     */
    function getTokenAddress() external view returns (address) {
        return address(token);
    }
}