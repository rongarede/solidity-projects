// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/BaseERC20.sol";

contract BaseERC20Test is Test {
    BaseERC20 public token;
    address public owner;
    address public user1 = address(0x1);
    address public user2 = address(0x2);

    function setUp() public {
        owner = address(this);
        token = new BaseERC20();
    }

    function testTokenMetadata() public {
        assertEq(token.name(), "BaseERC20");
        assertEq(token.symbol(), "BERC20");
        assertEq(token.decimals(), 18);
    }

    function testTotalSupply() public {
        uint256 expectedSupply = 100_000_000 * 10**18;
        assertEq(token.totalSupply(), expectedSupply);
        assertEq(token.balanceOf(owner), expectedSupply);
    }

    function testTransfer() public {
        uint256 amount = 1000 * 10**18;
        
        token.transfer(user1, amount);
        
        assertEq(token.balanceOf(user1), amount);
        assertEq(token.balanceOf(owner), 100_000_000 * 10**18 - amount);
    }

    function testApproveAndTransferFrom() public {
        uint256 amount = 1000 * 10**18;
        
        // 授权
        token.approve(user1, amount);
        assertEq(token.allowance(owner, user1), amount);
        
        // 从授权中转账
        vm.prank(user1);
        token.transferFrom(owner, user2, amount);
        
        assertEq(token.balanceOf(user2), amount);
        assertEq(token.allowance(owner, user1), 0);
    }
}