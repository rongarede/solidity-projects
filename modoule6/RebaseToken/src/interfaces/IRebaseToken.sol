// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRebaseToken is IERC20 {
    // Events
    event Rebase(uint256 indexed yearsElapsed, uint256 newIndex);

    /**
     * @notice Triggers annual deflation - reduces total supply by 1% per year
     * @dev Only callable by owner, applies compound deflation for elapsed years
     * @dev Formula: newIndex = currentIndex * (0.99)^yearsElapsed
     * @dev Emits Rebase event with yearsElapsed and newIndex
     */
    function rebase() external;

    /**
     * @notice Provides transparent rebase information for users
     * @return currentIndex The current deflation index (starts at 1e18)
     * @return blocksUntilNextRebase Number of blocks until next eligible rebase
     * @return expectedNextRebaseImpact Expected index after next rebase (1% deflation)
     */
    function getRebaseInfo() external view returns (
        uint256 currentIndex,
        uint256 blocksUntilNextRebase,
        uint256 expectedNextRebaseImpact
    );

    /**
     * @notice Returns the shares balance for a given account
     * @param account The address to query
     * @return shares The number of shares owned by the account
     */
    function sharesOf(address account) external view returns (uint256 shares);

    /**
     * @notice Converts token amount to shares based on current index
     * @param amount The token amount to convert
     * @return shares The equivalent number of shares
     */
    function getSharesByAmount(uint256 amount) external view returns (uint256 shares);

    /**
     * @notice Converts shares to token amount based on current index
     * @param shares The number of shares to convert
     * @return amount The equivalent token amount
     */
    function getAmountByShares(uint256 shares) external view returns (uint256 amount);

    /**
     * @notice Returns the total number of shares in existence
     * @return totalShares The total shares across all accounts
     */
    function totalShares() external view returns (uint256 totalShares);
}