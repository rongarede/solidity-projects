// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/UniswapV2ERC20.sol";

contract TestUniswapV2ERC20 is UniswapV2ERC20 {
    function mint(address to, uint256 value) external {
        _mint(to, value);
    }

    function burn(address from, uint256 value) external {
        _burn(from, value);
    }
}

contract UniswapV2ERC20Test is Test {
    TestUniswapV2ERC20 token;
    address user1;
    address user2;
    uint256 constant INITIAL_SUPPLY = 1000e18;

    function setUp() public {
        token = new TestUniswapV2ERC20();
        user1 = address(0x1111);
        user2 = address(0x2222);
        
        token.mint(address(this), INITIAL_SUPPLY);
    }

    function testBasicERC20Properties() public {
        assertEq(token.name(), "Uniswap V2");
        assertEq(token.symbol(), "UNI-V2");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(address(this)), INITIAL_SUPPLY);
    }

    function testTransfer() public {
        uint256 transferAmount = 100e18;
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(this), user1, transferAmount);
        
        bool success = token.transfer(user1, transferAmount);
        
        assertTrue(success);
        assertEq(token.balanceOf(address(this)), INITIAL_SUPPLY - transferAmount);
        assertEq(token.balanceOf(user1), transferAmount);
    }

    function testTransferInsufficientBalance() public {
        uint256 transferAmount = INITIAL_SUPPLY + 1;
        
        vm.expectRevert();
        token.transfer(user1, transferAmount);
    }

    function testApprove() public {
        uint256 approveAmount = 200e18;
        
        vm.expectEmit(true, true, false, true);
        emit Approval(address(this), user1, approveAmount);
        
        bool success = token.approve(user1, approveAmount);
        
        assertTrue(success);
        assertEq(token.allowance(address(this), user1), approveAmount);
    }

    function testTransferFrom() public {
        uint256 approveAmount = 200e18;
        uint256 transferAmount = 150e18;
        
        token.approve(user1, approveAmount);
        
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(this), user2, transferAmount);
        
        bool success = token.transferFrom(address(this), user2, transferAmount);
        
        assertTrue(success);
        assertEq(token.balanceOf(address(this)), INITIAL_SUPPLY - transferAmount);
        assertEq(token.balanceOf(user2), transferAmount);
        assertEq(token.allowance(address(this), user1), approveAmount - transferAmount);
    }

    function testTransferFromInfiniteAllowance() public {
        uint256 transferAmount = 150e18;
        
        token.approve(user1, type(uint256).max);
        
        vm.prank(user1);
        bool success = token.transferFrom(address(this), user2, transferAmount);
        
        assertTrue(success);
        assertEq(token.balanceOf(address(this)), INITIAL_SUPPLY - transferAmount);
        assertEq(token.balanceOf(user2), transferAmount);
        assertEq(token.allowance(address(this), user1), type(uint256).max);
    }

    function testTransferFromInsufficientAllowance() public {
        uint256 approveAmount = 100e18;
        uint256 transferAmount = 150e18;
        
        token.approve(user1, approveAmount);
        
        vm.prank(user1);
        vm.expectRevert();
        token.transferFrom(address(this), user2, transferAmount);
    }

    function testMint() public {
        uint256 mintAmount = 500e18;
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), user1, mintAmount);
        
        token.mint(user1, mintAmount);
        
        assertEq(token.totalSupply(), INITIAL_SUPPLY + mintAmount);
        assertEq(token.balanceOf(user1), mintAmount);
    }

    function testBurn() public {
        uint256 burnAmount = 300e18;
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(this), address(0), burnAmount);
        
        token.burn(address(this), burnAmount);
        
        assertEq(token.totalSupply(), INITIAL_SUPPLY - burnAmount);
        assertEq(token.balanceOf(address(this)), INITIAL_SUPPLY - burnAmount);
    }

    function testBurnInsufficientBalance() public {
        uint256 burnAmount = INITIAL_SUPPLY + 1;
        
        vm.expectRevert();
        token.burn(address(this), burnAmount);
    }

    function testPermit() public {
        uint256 privateKey = 0x1234;
        address owner = vm.addr(privateKey);
        address spender = user1;
        uint256 value = 100e18;
        uint256 deadline = block.timestamp + 1 hours;
        
        token.mint(owner, 1000e18);
        
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                token.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(
                    token.PERMIT_TYPEHASH(),
                    owner,
                    spender,
                    value,
                    token.nonces(owner),
                    deadline
                ))
            )
        );
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, value);
        
        token.permit(owner, spender, value, deadline, v, r, s);
        
        assertEq(token.allowance(owner, spender), value);
        assertEq(token.nonces(owner), 1);
    }

    function testPermitExpired() public {
        uint256 privateKey = 0x1234;
        address owner = vm.addr(privateKey);
        address spender = user1;
        uint256 value = 100e18;
        uint256 deadline = block.timestamp - 1;
        
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                token.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(
                    token.PERMIT_TYPEHASH(),
                    owner,
                    spender,
                    value,
                    token.nonces(owner),
                    deadline
                ))
            )
        );
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        
        vm.expectRevert('UniswapV2: EXPIRED');
        token.permit(owner, spender, value, deadline, v, r, s);
    }

    function testPermitInvalidSignature() public {
        address owner = user1;
        address spender = user2;
        uint256 value = 100e18;
        uint256 deadline = block.timestamp + 1 hours;
        
        vm.expectRevert('UniswapV2: INVALID_SIGNATURE');
        token.permit(owner, spender, value, deadline, 27, bytes32(0), bytes32(0));
    }

    function testDomainSeparator() public {
        uint256 chainId = block.chainid;
        bytes32 expectedDomainSeparator = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(token.name())),
                keccak256(bytes('1')),
                chainId,
                address(token)
            )
        );
        
        assertEq(token.DOMAIN_SEPARATOR(), expectedDomainSeparator);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}