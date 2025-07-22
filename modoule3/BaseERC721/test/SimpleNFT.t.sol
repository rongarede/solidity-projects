// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/SimpleNFT.sol";

contract SimpleNFTTest is Test {
    SimpleNFT public nft;
    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    
    function setUp() public {
        vm.prank(owner);
        nft = new SimpleNFT(
            "Test NFT",
            "TNFT",
            "https://test.com/"
        );
    }
    
    function testMint() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        nft.mint{value: 0.01 ether}(user1);
        
        assertEq(nft.balanceOf(user1), 1);
        assertEq(nft.ownerOf(0), user1);
        assertEq(nft.totalSupply(), 1);
    }
    
    function testAdminMint() public {
        vm.prank(owner);
        nft.adminMint(user1, 5);
        
        assertEq(nft.balanceOf(user1), 5);
        assertEq(nft.totalSupply(), 5);
    }
    
    function testSetMintPrice() public {
        vm.prank(owner);
        nft.setMintPrice(0.05 ether);
        
        assertEq(nft.mintPrice(), 0.05 ether);
    }
    
    function test_Revert_If_InsufficientPayment() public {
        vm.deal(user1, 0.005 ether);
        vm.prank(user1);
        vm.expectRevert(SimpleNFT.InsufficientPayment.selector);
        nft.mint{value: 0.005 ether}(user1);
    }
    
    function test_Revert_If_MaxSupplyExceeded() public {
        vm.prank(owner);
        vm.expectRevert(SimpleNFT.MaxSupplyExceeded.selector);
        nft.adminMint(user1, 1001);
    }
    
    function testWithdraw() public {
        // 用户铸造
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        nft.mint{value: 0.01 ether}(user1);
        
        uint256 initialBalance = owner.balance;
        
        // 所有者提取
        vm.prank(owner);
        nft.withdraw();
        
        assertEq(owner.balance, initialBalance + 0.01 ether);
        assertEq(address(nft).balance, 0);
    }
}
