// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MultiSigWallet
 * @dev 多签钱包合约，支持多个签名者共同管理资金
 */
contract MultiSigWallet is ReentrancyGuard, Ownable {
    using Address for address;

    // 自定义错误
    error InvalidOwner();
    error InvalidThreshold();
    error NotOwner();
    error TransactionNotExists();
    error TransactionAlreadyExecuted();
    error TransactionAlreadyConfirmed();
    error TransactionNotConfirmed();
    error InsufficientConfirmations();
    error TransactionFailed();

    // 事件定义
    event Submit(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    
    event Confirm(address indexed owner, uint256 indexed txIndex);
    event Revoke(address indexed owner, uint256 indexed txIndex);
    event Execute(address indexed owner, uint256 indexed txIndex);

    // 状态变量
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public threshold;

    // 交易结构
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
    }

    // 交易存储
    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    // 修饰符
    modifier onlyMultiSigOwner() {
        if (!isOwner[msg.sender]) revert NotOwner();
        _;
    }

    modifier txExists(uint256 _txIndex) {
        if (_txIndex >= transactions.length) revert TransactionNotExists();
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        if (transactions[_txIndex].executed) revert TransactionAlreadyExecuted();
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        if (isConfirmed[_txIndex][msg.sender]) revert TransactionAlreadyConfirmed();
        _;
    }


    /**
     * @dev 构造函数
     * @param _owners 多签持有人地址数组
     * @param _threshold 签名门槛
     */
    constructor(address[] memory _owners, uint256 _threshold) Ownable(msg.sender) {
        if (_owners.length == 0) revert InvalidOwner();
        if (_threshold == 0 || _threshold > _owners.length) revert InvalidThreshold();

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            if (owner == address(0)) revert InvalidOwner();
            if (isOwner[owner]) revert InvalidOwner();
            
            isOwner[owner] = true;
            owners.push(owner);
        }

        threshold = _threshold;
    }

    /**
     * @dev 接收以太币
     */
    receive() external payable {}

    /**
     * @dev 提交交易提案
     * @param _to 目标地址
     * @param _value 转账金额
     * @param _data 交易数据
     */
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlyMultiSigOwner {
        uint256 txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                confirmations: 0
            })
        );

        emit Submit(msg.sender, txIndex, _to, _value, _data);
    }

    /**
     * @dev 确认交易
     * @param _txIndex 交易索引
     */
    function confirmTransaction(uint256 _txIndex)
        public
        onlyMultiSigOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.confirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit Confirm(msg.sender, _txIndex);
    }

    /**
     * @dev 执行交易
     * @param _txIndex 交易索引
     */
    function executeTransaction(uint256 _txIndex)
        public
        nonReentrant
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        
        if (transaction.confirmations < threshold) {
            revert InsufficientConfirmations();
        }

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        
        if (!success) revert TransactionFailed();

        emit Execute(msg.sender, _txIndex);
    }

    /**
     * @dev 撤销确认
     * @param _txIndex 交易索引
     */
    function revokeConfirmation(uint256 _txIndex)
        public
        onlyMultiSigOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        if (!isConfirmed[_txIndex][msg.sender]) {
            revert TransactionNotConfirmed();
        }

        Transaction storage transaction = transactions[_txIndex];
        transaction.confirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit Revoke(msg.sender, _txIndex);
    }

    /**
     * @dev 获取所有者列表
     * @return 所有者地址数组
     */
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    /**
     * @dev 获取交易数量
     * @return 交易总数
     */
    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    /**
     * @dev 获取交易详情
     * @param _txIndex 交易索引
     * @return to 目标地址
     * @return value 转账金额
     * @return data 交易数据
     * @return executed 是否已执行
     * @return confirmations 确认数量
     */
    function getTransaction(uint256 _txIndex)
        public
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 confirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];
        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.confirmations
        );
    }

    /**
     * @dev 检查是否已确认交易
     * @param _txIndex 交易索引
     * @param _owner 所有者地址
     * @return 是否已确认
     */
    function isTransactionConfirmed(uint256 _txIndex, address _owner)
        public
        view
        returns (bool)
    {
        return isConfirmed[_txIndex][_owner];
    }

    /**
     * @dev 获取合约余额
     * @return 合约余额
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev 添加新的多签所有者（仅合约 owner 可调用）
     * @param _owner 新的所有者地址
     */
    function addOwner(address _owner) external onlyOwner {
        if (_owner == address(0)) revert InvalidOwner();
        if (isOwner[_owner]) revert InvalidOwner();
        
        isOwner[_owner] = true;
        owners.push(_owner);
    }

    /**
     * @dev 移除多签所有者（仅合约 owner 可调用）
     * @param _owner 要移除的所有者地址
     */
    function removeOwner(address _owner) external onlyOwner {
        if (!isOwner[_owner]) revert InvalidOwner();
        if (owners.length <= threshold) revert InvalidThreshold();
        
        isOwner[_owner] = false;
        
        // 从数组中移除
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == _owner) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
        }
    }

    /**
     * @dev 更新签名门槛（仅合约 owner 可调用）
     * @param _threshold 新的签名门槛
     */
    function updateThreshold(uint256 _threshold) external onlyOwner {
        if (_threshold == 0 || _threshold > owners.length) revert InvalidThreshold();
        threshold = _threshold;
    }
}