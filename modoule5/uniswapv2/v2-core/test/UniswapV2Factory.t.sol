// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/UniswapV2Factory.sol";
import "../contracts/UniswapV2Pair.sol";
import "./mocks/MockERC20.sol";

contract UniswapV2FactoryTest is Test {
    UniswapV2Factory factory;
    MockERC20 tokenA;
    MockERC20 tokenB;
    address feeToSetter;
    address pair;

    function setUp() public {
        feeToSetter = address(this);
        factory = new UniswapV2Factory(feeToSetter);
        tokenA = new MockERC20("Token A", "TKA", 18);
        tokenB = new MockERC20("Token B", "TKB", 18);
    }

    function testFactoryDeployment() public {
        assertEq(factory.feeToSetter(), feeToSetter);
        assertEq(factory.allPairsLength(), 0);
        assertEq(factory.feeTo(), address(0));
    }

    function testFeeToSetterConfiguration() public {
        address newFeeToSetter = address(0x1234);
        
        factory.setFeeToSetter(newFeeToSetter);
        assertEq(factory.feeToSetter(), newFeeToSetter);
    }

    function testCreatePairBasicFunctionality() public {
        address expectedPair = factory.createPair(address(tokenA), address(tokenB));
        
        assertFalse(expectedPair == address(0));
        assertEq(factory.allPairsLength(), 1);
        assertEq(factory.allPairs(0), expectedPair);
        assertEq(factory.getPair(address(tokenA), address(tokenB)), expectedPair);
        assertEq(factory.getPair(address(tokenB), address(tokenA)), expectedPair);
    }

    function testCreatePairTokenOrder() public {
        address pair1 = factory.createPair(address(tokenA), address(tokenB));
        
        UniswapV2Pair pairContract = UniswapV2Pair(pair1);
        address token0 = pairContract.token0();
        address token1 = pairContract.token1();
        
        assertTrue(token0 < token1);
        
        if (address(tokenA) < address(tokenB)) {
            assertEq(token0, address(tokenA));
            assertEq(token1, address(tokenB));
        } else {
            assertEq(token0, address(tokenB));
            assertEq(token1, address(tokenA));
        }
    }

    function testCreatePairErrorHandling() public {
        vm.expectRevert('UniswapV2: IDENTICAL_ADDRESSES');
        factory.createPair(address(tokenA), address(tokenA));
        
        vm.expectRevert('UniswapV2: ZERO_ADDRESS');
        factory.createPair(address(0), address(tokenB));
        
        factory.createPair(address(tokenA), address(tokenB));
        
        vm.expectRevert('UniswapV2: PAIR_EXISTS');
        factory.createPair(address(tokenA), address(tokenB));
        
        vm.expectRevert('UniswapV2: PAIR_EXISTS');
        factory.createPair(address(tokenB), address(tokenA));
    }

    function testSetFeeTo() public {
        address newFeeTo = address(0x5678);
        
        factory.setFeeTo(newFeeTo);
        assertEq(factory.feeTo(), newFeeTo);
    }

    function testOnlyFeeToSetterCanSetFeeTo() public {
        address notFeeToSetter = address(0x9999);
        address newFeeTo = address(0x5678);
        
        vm.prank(notFeeToSetter);
        vm.expectRevert('UniswapV2: FORBIDDEN');
        factory.setFeeTo(newFeeTo);
    }

    function testOnlyFeeToSetterCanSetFeeToSetter() public {
        address notFeeToSetter = address(0x9999);
        address newFeeToSetter = address(0x1111);
        
        vm.prank(notFeeToSetter);
        vm.expectRevert('UniswapV2: FORBIDDEN');
        factory.setFeeToSetter(newFeeToSetter);
    }
}