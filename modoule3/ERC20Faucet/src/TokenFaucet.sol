// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title TokenFaucet
 * @dev ERC20 代币水龙头合约，允许用户定期领取测试代币
 */
contract TokenFaucet is Ownable {
    // 绑定的 ERC20 代币合约
    IERC20 public immutable token;
    
    // 每次领取的代币数量
    uint256 public faucetAmount;
    
    // 领取冷却时间（秒）
    uint256 public cooldownTime;
    
    // 记录每个地址上次领取的时间
    mapping(address => uint256) public lastRequestTime;
    
    // 重入防御状态变量
    bool private _locked;
    
    // 重入防御修饰符
    modifier nonReentrant() {
        require(!_locked, "ReentrancyGuard: reentrant call");
        _locked = true;
        _;
        _locked = false;
    }
    
    // 事件
    event TokensRequested(address indexed user, uint256 amount, uint256 timestamp);
    event FaucetAmountUpdated(uint256 oldAmount, uint256 newAmount);
    event CooldownTimeUpdated(uint256 oldTime, uint256 newTime);
    event TokensWithdrawn(address indexed owner, uint256 amount);
    
    // 错误定义
    error CooldownNotExpired(uint256 remainingTime);
    error InsufficientFaucetBalance();
    error InvalidAmount();
    error InvalidCooldownTime();
    error WithdrawFailed();
    
    /**
     * @dev 构造函数
     * @param _token TestToken 合约地址
     * @param _faucetAmount 每次领取的代币数量（不包含小数位）
     * @param _cooldownTime 冷却时间（秒）
     */
    constructor(
        address _token,
        uint256 _faucetAmount,
        uint256 _cooldownTime
    ) Ownable(msg.sender) {
        require(_token != address(0), "Token address cannot be zero");
        
        token = IERC20(_token);
        faucetAmount = _faucetAmount * 10**18; // 转换为 wei 单位
        cooldownTime = _cooldownTime;
        
        emit FaucetAmountUpdated(0, faucetAmount);
        emit CooldownTimeUpdated(0, cooldownTime);
    }
    
    /**
     * @dev 用户领取代币
     */
    function requestTokens() external nonReentrant {
        address user = msg.sender;
        
        // 检查冷却时间
        if (lastRequestTime[user] != 0) {
            uint256 timeSinceLastRequest = block.timestamp - lastRequestTime[user];
            if (timeSinceLastRequest < cooldownTime) {
                revert CooldownNotExpired(cooldownTime - timeSinceLastRequest);
            }
        }
        
        // 检查水龙头余额
        uint256 faucetBalance = token.balanceOf(address(this));
        if (faucetBalance < faucetAmount) {
            revert InsufficientFaucetBalance();
        }
        
        // 更新用户上次领取时间
        lastRequestTime[user] = block.timestamp;
        
        // 转账代币给用户
        bool success = token.transfer(user, faucetAmount);
        require(success, "Token transfer failed");
        
        emit TokensRequested(user, faucetAmount, block.timestamp);
    }
    
    /**
     * @dev 设置每次领取的代币数量（仅 owner）
     * @param _amount 新的领取数量（不包含小数位）
     */
    function setAmount(uint256 _amount) external onlyOwner {
        if (_amount == 0) {
            revert InvalidAmount();
        }
        
        uint256 oldAmount = faucetAmount;
        faucetAmount = _amount * 10**18;
        
        emit FaucetAmountUpdated(oldAmount, faucetAmount);
    }
    
    /**
     * @dev 设置冷却时间（仅 owner）
     * @param _cooldownTime 新的冷却时间（秒）
     */
    function setCooldown(uint256 _cooldownTime) external onlyOwner {
        if (_cooldownTime == 0) {
            revert InvalidCooldownTime();
        }
        
        uint256 oldTime = cooldownTime;
        cooldownTime = _cooldownTime;
        
        emit CooldownTimeUpdated(oldTime, cooldownTime);
    }
    
    /**
     * @dev Owner 提取未使用的代币
     * @param _amount 提取数量（wei 单位），0 表示提取全部
     */
    function withdraw(uint256 _amount) external onlyOwner nonReentrant {
        uint256 balance = token.balanceOf(address(this));
        uint256 withdrawAmount = _amount == 0 ? balance : _amount;
        
        require(withdrawAmount <= balance, "Insufficient balance");
        
        bool success = token.transfer(owner(), withdrawAmount);
        if (!success) {
            revert WithdrawFailed();
        }
        
        emit TokensWithdrawn(owner(), withdrawAmount);
    }
    
    /**
     * @dev 查询用户距离下次可领取的剩余时间
     * @param _user 用户地址
     * @return 剩余冷却时间（秒），0 表示可以立即领取
     */
    function getRemainingCooldown(address _user) external view returns (uint256) {
        if (lastRequestTime[_user] == 0) {
            return 0; // 从未领取过
        }
        
        uint256 timeSinceLastRequest = block.timestamp - lastRequestTime[_user];
        if (timeSinceLastRequest >= cooldownTime) {
            return 0; // 冷却时间已过
        }
        
        return cooldownTime - timeSinceLastRequest;
    }
    
    /**
     * @dev 查询水龙头当前余额
     * @return 水龙头合约持有的代币数量
     */
    function getFaucetBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
    
    /**
     * @dev 查询用户是否可以领取代币
     * @param _user 用户地址
     * @return 是否可以领取
     */
    function canRequestTokens(address _user) external view returns (bool) {
        // 检查水龙头余额
        if (token.balanceOf(address(this)) < faucetAmount) {
            return false;
        }
        
        // 检查冷却时间
        if (lastRequestTime[_user] == 0) {
            return true; // 从未领取过
        }
        
        uint256 timeSinceLastRequest = block.timestamp - lastRequestTime[_user];
        return timeSinceLastRequest >= cooldownTime;
    }
}