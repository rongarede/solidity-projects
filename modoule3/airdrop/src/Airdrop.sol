// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/utils/Pausable.sol";

/**
 * @title AirdropDistributor
 * @dev 基于 Merkle Tree 的代币空投分发合约
 * @notice 用户可以通过提供 Merkle Proof 来领取指定数量的代币
 */
contract AirdropDistributor is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // ============ State Variables ============

    /// @notice 要分发的 ERC20 代币合约地址
    IERC20 public immutable token;

    /// @notice Merkle Tree 根哈希
    bytes32 public merkleRoot;

    /// @notice 记录已领取的地址，防止重复领取
    mapping(address => bool) public hasClaimed;

    /// @notice 总的已领取数量
    uint256 public totalClaimed;

    /// @notice 最大可领取总量限制
    uint256 public maxClaimableAmount;

    // ============ Events ============

    /// @notice 成功领取空投事件
    event Claimed(address indexed account, uint256 amount);

    /// @notice Merkle Root 更新事件
    event MerkleRootUpdated(bytes32 oldRoot, bytes32 newRoot);

    /// @notice 最大可领取总量更新事件
    event MaxClaimableAmountUpdated(uint256 oldAmount, uint256 newAmount);

    /// @notice 管理员提取剩余代币事件
    event TokensWithdrawn(address indexed to, uint256 amount);

    // ============ Errors ============

    error InvalidProof();
    error AlreadyClaimed();
    error ExceedsMaxClaimable();
    error ZeroAmount();
    error ZeroAddress();
    error InsufficientBalance();

    // ============ Constructor ============

    /**
     * @dev 构造函数
     * @param _token 要分发的 ERC20 代币地址
     * @param _merkleRoot 初始的 Merkle Tree 根哈希
     * @param _maxClaimableAmount 最大可领取总量
     */
    constructor(
        address _token,
        bytes32 _merkleRoot,
        uint256 _maxClaimableAmount
    ) Ownable(msg.sender) {
        if (_token == address(0)) revert ZeroAddress();
        
        token = IERC20(_token);
        merkleRoot = _merkleRoot;
        maxClaimableAmount = _maxClaimableAmount;
    }

    // ============ External Functions ============

    /**
     * @notice 通过 Merkle Proof 领取空投
     * @param to 接收代币的地址
     * @param amount 领取的代币数量
     * @param proof Merkle Tree 证明
     */
    function claimWithMerkle(
        address to,
        uint256 amount,
        bytes32[] calldata proof
    ) external nonReentrant whenNotPaused {
        // Checks
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        if (hasClaimed[to]) revert AlreadyClaimed();
        if (totalClaimed + amount > maxClaimableAmount) revert ExceedsMaxClaimable();

        // 验证 Merkle Proof
        bytes32 leaf = keccak256(abi.encodePacked(to, amount));
        if (!MerkleProof.verify(proof, merkleRoot, leaf)) {
            revert InvalidProof();
        }

        // 检查合约余额是否足够
        if (token.balanceOf(address(this)) < amount) revert InsufficientBalance();

        // Effects
        hasClaimed[to] = true;
        totalClaimed += amount;

        // Interactions
        token.safeTransfer(to, amount);

        emit Claimed(to, amount);
    }

    /**
     * @notice 检查地址是否可以领取指定数量的代币
     * @param account 要检查的地址
     * @param amount 要领取的数量
     * @param proof Merkle Tree 证明
     * @return 是否可以领取
     */
    function canClaim(
        address account,
        uint256 amount,
        bytes32[] calldata proof
    ) external view returns (bool) {
        if (hasClaimed[account]) return false;
        if (amount == 0) return false;
        if (totalClaimed + amount > maxClaimableAmount) return false;

        bytes32 leaf = keccak256(abi.encodePacked(account, amount));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    // ============ Owner Functions ============

    /**
     * @notice 更新 Merkle Root（仅限所有者）
     * @param _merkleRoot 新的 Merkle Tree 根哈希
     */
    function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        bytes32 oldRoot = merkleRoot;
        merkleRoot = _merkleRoot;
        emit MerkleRootUpdated(oldRoot, _merkleRoot);
    }

    /**
     * @notice 更新最大可领取总量（仅限所有者）
     * @param _maxClaimableAmount 新的最大可领取总量
     */
    function updateMaxClaimableAmount(uint256 _maxClaimableAmount) external onlyOwner {
        uint256 oldAmount = maxClaimableAmount;
        maxClaimableAmount = _maxClaimableAmount;
        emit MaxClaimableAmountUpdated(oldAmount, _maxClaimableAmount);
    }

    /**
     * @notice 暂停合约（仅限所有者）
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice 恢复合约（仅限所有者）
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice 提取合约中的剩余代币（仅限所有者）
     * @param to 接收地址
     * @param amount 提取数量，0 表示提取全部
     */
    function withdrawTokens(address to, uint256 amount) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();

        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) revert InsufficientBalance();

        uint256 withdrawAmount = amount == 0 ? balance : amount;
        if (withdrawAmount > balance) revert InsufficientBalance();

        token.safeTransfer(to, withdrawAmount);
        emit TokensWithdrawn(to, withdrawAmount);
    }

    /**
     * @notice 紧急提取任意 ERC20 代币（仅限所有者）
     * @param tokenAddress 代币合约地址
     * @param to 接收地址
     * @param amount 提取数量
     */
    function emergencyWithdraw(
        address tokenAddress,
        address to,
        uint256 amount
    ) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();
        if (tokenAddress == address(0)) revert ZeroAddress();

        IERC20(tokenAddress).safeTransfer(to, amount);
    }

    // ============ View Functions ============

    /**
     * @notice 获取合约中代币余额
     * @return 代币余额
     */
    function getTokenBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @notice 获取剩余可领取数量
     * @return 剩余可领取数量
     */
    function getRemainingClaimable() external view returns (uint256) {
        return maxClaimableAmount - totalClaimed;
    }

    /**
     * @notice 生成 Merkle Tree 叶子节点哈希
     * @param account 地址
     * @param amount 数量
     * @return 叶子节点哈希
     */
    function getLeafHash(address account, uint256 amount) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, amount));
    }
}
