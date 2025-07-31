// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library MathUtils {
    uint256 internal constant WAD = 1e18;
    
    function pow(uint256 base, uint256 exponent) internal pure returns (uint256) {
        if (exponent == 0) return WAD;
        if (base == 0) return 0;
        
        uint256 result = WAD;
        uint256 basePower = base;
        
        // Use binary exponentiation
        while (exponent > 0) {
            if (exponent & 1 != 0) {
                result = mulDiv(result, basePower, WAD);
            }
            basePower = mulDiv(basePower, basePower, WAD);
            exponent >>= 1;
        }
        
        return result;
    }
    
    function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256) {
        return (a * b + denominator / 2) / denominator;
    }
}