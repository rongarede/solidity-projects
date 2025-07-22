// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Receiver.sol";

/**
 * @title MyCollectible
 * @dev 标准ERC721 NFT合约实现
 * @notice 这是一个可铸造的NFT收藏品合约
 */
contract MyCollectible is IERC721 {
    
    // ============ 状态变量 ============
    
    /// @dev 合约名称
    string private _name;
    
    /// @dev 合约符号
    string private _symbol;
    
    /// @dev 基础URI，用于构建tokenURI
    string private _baseTokenURI;
    
    /// @dev 下一个要铸造的tokenId
    uint256 private _nextTokenId;
    
    /// @dev 合约拥有者
    address public owner;
    
    /// @dev tokenId到拥有者的映射
    mapping(uint256 => address) private _owners;
    
    /// @dev 拥有者到余额的映射
    mapping(address => uint256) private _balances;
    
    /// @dev tokenId到授权地址的映射
    mapping(uint256 => address) private _tokenApprovals;
    
    /// @dev 拥有者到操作员的全部授权映射
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    /// @dev tokenId到URI的映射
    mapping(uint256 => string) private _tokenURIs;
    
    // ============ 事件定义 ============
    
    /// @dev NFT铸造事件
    event Mint(address indexed to, uint256 indexed tokenId, string tokenURI);
    
    // ============ 修饰器 ============
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }
    
    modifier tokenExists(uint256 tokenId) {
        require(_exists(tokenId), "Token does not exist");
        _;
    }
    
    // ============ 构造函数 ============
    
    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_
    ) {
        _name = name_;
        _symbol = symbol_;
        _baseTokenURI = baseTokenURI_;
        owner = msg.sender;
        _nextTokenId = 1; // 从1开始
    }
    
    // ============ ERC721 标准函数 ============
    
    /**
     * @dev 返回合约名称
     */
    function name() public view returns (string memory) {
        return _name;
    }
    
    /**
     * @dev 返回合约符号
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    /**
     * @dev 返回指定tokenId的拥有者
     */
    function ownerOf(uint256 tokenId) public view override tokenExists(tokenId) returns (address) {
        return _owners[tokenId];
    }
    
    /**
     * @dev 返回指定地址拥有的NFT数量
     */
    function balanceOf(address ownerAddr) public view override returns (uint256) {
        require(ownerAddr != address(0), "Balance query for zero address");
        return _balances[ownerAddr];
    }
    
    /**
     * @dev 返回指定tokenId的授权地址
     */
    function getApproved(uint256 tokenId) public view override tokenExists(tokenId) returns (address) {
        return _tokenApprovals[tokenId];
    }
    
    /**
     * @dev 检查操作员是否被拥有者授权管理所有NFT
     */
    function isApprovedForAll(address ownerAddr, address operator) public view override returns (bool) {
        return _operatorApprovals[ownerAddr][operator];
    }
    
    /**
     * @dev 授权指定地址管理特定tokenId
     */
    function approve(address to, uint256 tokenId) public override tokenExists(tokenId) {
        address tokenOwner = ownerOf(tokenId);
        require(to != tokenOwner, "Approval to current owner");
        require(
            msg.sender == tokenOwner || isApprovedForAll(tokenOwner, msg.sender),
            "Not owner nor approved for all"
        );
        
        _approve(to, tokenId);
    }
    
    /**
     * @dev 设置或取消操作员授权
     */
    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "Approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    /**
     * @dev 转移NFT
     */
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner nor approved");
        _transfer(from, to, tokenId);
    }
    
    /**
     * @dev 安全转移NFT
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }
    
    /**
     * @dev 安全转移NFT（带数据）
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }
    
    // ============ 扩展功能 ============
    
    /**
     * @dev 铸造NFT
     * @param to 接收者地址
     * @param tokenURI NFT的metadata URI
     * @return tokenId 新铸造的tokenId
     */
    function mint(address to, string memory tokenURI) public onlyOwner returns (uint256) {
        require(to != address(0), "Mint to zero address");
        
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        
        _balances[to]++;
        _owners[tokenId] = to;
        _tokenURIs[tokenId] = tokenURI;
        
        emit Transfer(address(0), to, tokenId);
        emit Mint(to, tokenId, tokenURI);
        
        return tokenId;
    }
    
    /**
     * @dev 批量铸造NFT
     * @param to 接收者地址
     * @param amount 铸造数量
     * @param baseURI 基础URI前缀
     */
    function batchMint(address to, uint256 amount, string memory baseURI) public onlyOwner {
        require(to != address(0), "Mint to zero address");
        require(amount > 0, "Amount must be greater than 0");
        
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _nextTokenId;
            _nextTokenId++;
            
            _balances[to]++;
            _owners[tokenId] = to;
            _tokenURIs[tokenId] = string(abi.encodePacked(baseURI, _toString(tokenId)));
            
            emit Transfer(address(0), to, tokenId);
            emit Mint(to, tokenId, _tokenURIs[tokenId]);
        }
    }
    
    /**
     * @dev 返回tokenURI
     */
    function tokenURI(uint256 tokenId) public view tokenExists(tokenId) returns (string memory) {
        string memory uri = _tokenURIs[tokenId];
        
        // 如果设置了特定的URI，返回它
        if (bytes(uri).length > 0) {
            return uri;
        }
        
        // 否则返回baseURI + tokenId
        return bytes(_baseTokenURI).length > 0 
            ? string(abi.encodePacked(_baseTokenURI, _toString(tokenId)))
            : "";
    }
    
    /**
     * @dev 设置基础URI
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseTokenURI = baseURI_;
    }
    
    /**
     * @dev 获取下一个tokenId
     */
    function nextTokenId() public view returns (uint256) {
        return _nextTokenId;
    }
    
    /**
     * @dev 获取总供应量
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId - 1;
    }
    
    /**
     * @dev 转移合约所有权
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is zero address");
        owner = newOwner;
    }
    
    // ============ 内部函数 ============
    
    /**
     * @dev 检查token是否存在
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }
    
    /**
     * @dev 内部授权函数
     */
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }
    
    /**
     * @dev 检查是否为授权者或拥有者
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "Operator query for nonexistent token");
        address tokenOwner = ownerOf(tokenId);
        return (spender == tokenOwner || 
                getApproved(tokenId) == spender || 
                isApprovedForAll(tokenOwner, spender));
    }
    
    /**
     * @dev 内部转移函数
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "Transfer from incorrect owner");
        require(to != address(0), "Transfer to zero address");
        
        // 清除授权
        _approve(address(0), tokenId);
        
        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;
        
        emit Transfer(from, to, tokenId);
    }
    
    /**
     * @dev 安全转移内部函数
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "Transfer to non ERC721Receiver");
    }
    
    /**
     * @dev 检查接收者是否实现了IERC721Receiver
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("Transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    
    /**
     * @dev 将uint256转换为字符串
     */
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
