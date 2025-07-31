// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/tokens/TokenA.sol";
import "../../src/tokens/TokenB.sol";
import "../../src/tokens/TokenC.sol";

contract TokenTest is Test {
    TokenA public tokenA;
    TokenB public tokenB;
    TokenC public tokenC;
    
    address public owner = address(this);
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    
    function setUp() public {
        tokenA = new TokenA();
        tokenB = new TokenB();
        tokenC = new TokenC();
    }
    
    function testInitialSupply() public {
        assertEq(tokenA.totalSupply(), 1_000_000 * 10**18);
        assertEq(tokenB.totalSupply(), 1_000_000 * 10**18);
        assertEq(tokenC.totalSupply(), 1_000_000 * 10**18);
    }
    
    function testOwnerBalance() public {
        assertEq(tokenA.balanceOf(owner), 1_000_000 * 10**18);
        assertEq(tokenB.balanceOf(owner), 1_000_000 * 10**18);
        assertEq(tokenC.balanceOf(owner), 1_000_000 * 10**18);
    }
    
    function testTokenMetadata() public {
        assertEq(tokenA.name(), "Token A");
        assertEq(tokenA.symbol(), "TKNA");
        assertEq(tokenA.decimals(), 18);
        
        assertEq(tokenB.name(), "Token B");
        assertEq(tokenB.symbol(), "TKNB");
        assertEq(tokenB.decimals(), 18);
        
        assertEq(tokenC.name(), "Token C");
        assertEq(tokenC.symbol(), "TKNC");
        assertEq(tokenC.decimals(), 18);
    }
    
    function testTransfer() public {
        uint256 transferAmount = 1000 * 10**18;
        
        tokenA.transfer(user1, transferAmount);
        assertEq(tokenA.balanceOf(user1), transferAmount);
        assertEq(tokenA.balanceOf(owner), 1_000_000 * 10**18 - transferAmount);
        
        tokenB.transfer(user1, transferAmount);
        assertEq(tokenB.balanceOf(user1), transferAmount);
        
        tokenC.transfer(user1, transferAmount);
        assertEq(tokenC.balanceOf(user1), transferAmount);
    }
    
    function testApproveAndTransferFrom() public {
        uint256 approveAmount = 5000 * 10**18;
        uint256 transferAmount = 2000 * 10**18;
        
        tokenA.approve(user1, approveAmount);
        assertEq(tokenA.allowance(owner, user1), approveAmount);
        
        vm.prank(user1);
        tokenA.transferFrom(owner, user2, transferAmount);
        
        assertEq(tokenA.balanceOf(user2), transferAmount);
        assertEq(tokenA.allowance(owner, user1), approveAmount - transferAmount);
    }
    
    function testFailTransferInsufficientBalance() public {
        vm.prank(user1);
        tokenA.transfer(user2, 1 * 10**18);
    }
    
    function testFailTransferFromInsufficientAllowance() public {
        tokenA.transfer(user1, 1000 * 10**18);
        
        vm.prank(user1);
        tokenA.transferFrom(owner, user2, 1 * 10**18);
    }
}