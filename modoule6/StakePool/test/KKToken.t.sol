// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {KKToken} from "../src/KKToken.sol";

contract KKTokenTest is Test {
    KKToken public kkToken;
    address public admin;
    address public minter1;
    address public minter2;
    address public user1;
    address public user2;
    
    event TokenMinted(address indexed to, uint256 amount, address indexed minter);
    event MinterRoleGranted(address indexed account, address indexed admin);
    event MinterRoleRevoked(address indexed account, address indexed admin);

    function setUp() public {
        admin = makeAddr("admin");
        minter1 = makeAddr("minter1");
        minter2 = makeAddr("minter2");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        vm.prank(admin);
        kkToken = new KKToken(admin);
    }

    function testInitialSetup() public {
        assertEq(kkToken.name(), "KK Token");
        assertEq(kkToken.symbol(), "KK");
        assertEq(kkToken.decimals(), 18);
        assertEq(kkToken.totalSupply(), 0);
        
        // Check admin has both roles
        assertTrue(kkToken.hasRole(kkToken.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(kkToken.hasRole(kkToken.MINTER_ROLE(), admin));
        assertTrue(kkToken.isMinter(admin));
    }

    function testConstructorWithZeroAddress() public {
        vm.expectRevert(KKToken.InvalidAddress.selector);
        new KKToken(address(0));
    }

    function testMintByAdmin() public {
        uint256 mintAmount = 1000 * 1e18;
        
        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit TokenMinted(user1, mintAmount, admin);
        
        kkToken.mint(user1, mintAmount);
        
        assertEq(kkToken.balanceOf(user1), mintAmount);
        assertEq(kkToken.totalSupply(), mintAmount);
    }

    function testMintByNonMinter() public {
        uint256 mintAmount = 1000 * 1e18;
        
        vm.prank(user1);
        vm.expectRevert(KKToken.UnauthorizedMinter.selector);
        kkToken.mint(user2, mintAmount);
    }

    function testMintZeroAmount() public {
        vm.prank(admin);
        vm.expectRevert(KKToken.InvalidAmount.selector);
        kkToken.mint(user1, 0);
    }

    function testMintToZeroAddress() public {
        vm.prank(admin);
        vm.expectRevert(KKToken.InvalidAddress.selector);
        kkToken.mint(address(0), 1000 * 1e18);
    }

    function testGrantMinterRole() public {
        vm.prank(admin);
        vm.expectEmit(true, true, false, false);
        emit MinterRoleGranted(minter1, admin);
        
        kkToken.grantMinterRole(minter1);
        
        assertTrue(kkToken.isMinter(minter1));
        assertTrue(kkToken.hasRole(kkToken.MINTER_ROLE(), minter1));
    }

    function testGrantMinterRoleToZeroAddress() public {
        vm.prank(admin);
        vm.expectRevert(KKToken.InvalidAddress.selector);
        kkToken.grantMinterRole(address(0));
    }

    function testRevokeMinterRole() public {
        // First grant the role
        vm.prank(admin);
        kkToken.grantMinterRole(minter1);
        assertTrue(kkToken.isMinter(minter1));
        
        // Then revoke it
        vm.prank(admin);
        vm.expectEmit(true, true, false, false);
        emit MinterRoleRevoked(minter1, admin);
        
        kkToken.revokeMinterRole(minter1);
        
        assertFalse(kkToken.isMinter(minter1));
        assertFalse(kkToken.hasRole(kkToken.MINTER_ROLE(), minter1));
    }

    function testNonAdminCannotGrantRole() public {
        vm.prank(user1);
        vm.expectRevert();
        kkToken.grantMinterRole(minter1);
    }

    function testNonAdminCannotRevokeRole() public {
        // First grant role as admin
        vm.prank(admin);
        kkToken.grantMinterRole(minter1);
        
        // Try to revoke as non-admin
        vm.prank(user1);
        vm.expectRevert();
        kkToken.revokeMinterRole(minter1);
    }

    function testMintAfterGrantingRole() public {
        uint256 mintAmount = 500 * 1e18;
        
        // Grant minter role to minter1
        vm.prank(admin);
        kkToken.grantMinterRole(minter1);
        
        // Minter1 should now be able to mint
        vm.prank(minter1);
        vm.expectEmit(true, false, false, true);
        emit TokenMinted(user1, mintAmount, minter1);
        
        kkToken.mint(user1, mintAmount);
        
        assertEq(kkToken.balanceOf(user1), mintAmount);
        assertEq(kkToken.totalSupply(), mintAmount);
    }

    function testCannotMintAfterRevokingRole() public {
        uint256 mintAmount = 500 * 1e18;
        
        // Grant then revoke minter role
        vm.prank(admin);
        kkToken.grantMinterRole(minter1);
        
        vm.prank(admin);
        kkToken.revokeMinterRole(minter1);
        
        // Minter1 should not be able to mint anymore
        vm.prank(minter1);
        vm.expectRevert(KKToken.UnauthorizedMinter.selector);
        kkToken.mint(user1, mintAmount);
    }

    function testMultipleMinters() public {
        uint256 mintAmount1 = 1000 * 1e18;
        uint256 mintAmount2 = 2000 * 1e18;
        
        // Grant minter roles
        vm.prank(admin);
        kkToken.grantMinterRole(minter1);
        
        vm.prank(admin);
        kkToken.grantMinterRole(minter2);
        
        // Both should be able to mint
        vm.prank(minter1);
        kkToken.mint(user1, mintAmount1);
        
        vm.prank(minter2);
        kkToken.mint(user2, mintAmount2);
        
        assertEq(kkToken.balanceOf(user1), mintAmount1);
        assertEq(kkToken.balanceOf(user2), mintAmount2);
        assertEq(kkToken.totalSupply(), mintAmount1 + mintAmount2);
    }

    function testGetMinterCount() public {
        // Initially only admin is minter
        assertEq(kkToken.getMinterCount(), 1);
        
        // Add more minters
        vm.prank(admin);
        kkToken.grantMinterRole(minter1);
        assertEq(kkToken.getMinterCount(), 2);
        
        vm.prank(admin);
        kkToken.grantMinterRole(minter2);
        assertEq(kkToken.getMinterCount(), 3);
        
        // Revoke one
        vm.prank(admin);
        kkToken.revokeMinterRole(minter1);
        assertEq(kkToken.getMinterCount(), 2);
    }

    function testGetMinter() public {
        // Add minters
        vm.prank(admin);
        kkToken.grantMinterRole(minter1);
        
        vm.prank(admin);
        kkToken.grantMinterRole(minter2);
        
        // Check we can get minters by index
        address firstMinter = kkToken.getMinter(0);
        address secondMinter = kkToken.getMinter(1);
        address thirdMinter = kkToken.getMinter(2);
        
        // One of them should be admin, others should be minter1 and minter2
        assertTrue(firstMinter == admin || firstMinter == minter1 || firstMinter == minter2);
        assertTrue(secondMinter == admin || secondMinter == minter1 || secondMinter == minter2);
        assertTrue(thirdMinter == admin || thirdMinter == minter1 || thirdMinter == minter2);
    }

    function testSupportsInterface() public {
        // Test AccessControl interface support
        assertTrue(kkToken.supportsInterface(0x7965db0b)); // AccessControl
        assertTrue(kkToken.supportsInterface(0x01ffc9a7)); // ERC165
    }

    function testLargeMint() public {
        uint256 largeAmount = 1e30; // Very large amount
        
        vm.prank(admin);
        kkToken.mint(user1, largeAmount);
        
        assertEq(kkToken.balanceOf(user1), largeAmount);
        assertEq(kkToken.totalSupply(), largeAmount);
    }

    function testMultipleMintsSameUser() public {
        uint256 mint1 = 1000 * 1e18;
        uint256 mint2 = 2000 * 1e18;
        uint256 mint3 = 3000 * 1e18;
        
        vm.startPrank(admin);
        kkToken.mint(user1, mint1);
        kkToken.mint(user1, mint2);
        kkToken.mint(user1, mint3);
        vm.stopPrank();
        
        assertEq(kkToken.balanceOf(user1), mint1 + mint2 + mint3);
        assertEq(kkToken.totalSupply(), mint1 + mint2 + mint3);
    }

    function testTransferAfterMint() public {
        uint256 mintAmount = 1000 * 1e18;
        uint256 transferAmount = 300 * 1e18;
        
        // Mint to user1
        vm.prank(admin);
        kkToken.mint(user1, mintAmount);
        
        // User1 transfers to user2
        vm.prank(user1);
        kkToken.transfer(user2, transferAmount);
        
        assertEq(kkToken.balanceOf(user1), mintAmount - transferAmount);
        assertEq(kkToken.balanceOf(user2), transferAmount);
        assertEq(kkToken.totalSupply(), mintAmount);
    }

    // Fuzz testing
    function testFuzzMint(uint256 amount) public {
        amount = bound(amount, 1, type(uint128).max); // Reasonable bounds
        
        vm.prank(admin);
        kkToken.mint(user1, amount);
        
        assertEq(kkToken.balanceOf(user1), amount);
        assertEq(kkToken.totalSupply(), amount);
    }

    function testFuzzMultipleMints(uint256 amount1, uint256 amount2, uint256 amount3) public {
        amount1 = bound(amount1, 1, type(uint64).max);
        amount2 = bound(amount2, 1, type(uint64).max);
        amount3 = bound(amount3, 1, type(uint64).max);
        
        vm.startPrank(admin);
        kkToken.mint(user1, amount1);
        kkToken.mint(user2, amount2);
        kkToken.mint(user1, amount3);
        vm.stopPrank();
        
        assertEq(kkToken.balanceOf(user1), amount1 + amount3);
        assertEq(kkToken.balanceOf(user2), amount2);
        assertEq(kkToken.totalSupply(), amount1 + amount2 + amount3);
    }

    // Test role management edge cases
    function testSelfRevokeMinterRole() public {
        // Grant minter role to minter1
        vm.prank(admin);
        kkToken.grantMinterRole(minter1);
        assertTrue(kkToken.isMinter(minter1));
        
        // minter1 tries to revoke their own role (should fail)
        vm.prank(minter1);
        vm.expectRevert();
        kkToken.revokeMinterRole(minter1);
    }

    function testAdminCanRevokeOwnMinterRole() public {
        // Admin revokes their own minter role
        vm.prank(admin);
        kkToken.revokeMinterRole(admin);
        
        assertFalse(kkToken.isMinter(admin));
        
        // Admin should still be able to grant roles (still has admin role)
        vm.prank(admin);
        kkToken.grantMinterRole(minter1);
        assertTrue(kkToken.isMinter(minter1));
        
        // But admin should not be able to mint anymore
        vm.prank(admin);
        vm.expectRevert(KKToken.UnauthorizedMinter.selector);
        kkToken.mint(user1, 1000 * 1e18);
    }
}