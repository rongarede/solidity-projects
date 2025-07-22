import { useState, useEffect, useCallback } from 'react';
import { useAccount, usePublicClient } from 'wagmi';
import { getContract, parseAbi } from 'viem';
import { Token, TokenWithSource, TokenSource } from '@/types/tokens';
import { MOCKWETH_TOKEN } from '@/lib/tokens';

// Common ERC20 tokens on Base network - using centralized MockWETH configuration
const COMMON_TOKENS: Token[] = [
  MOCKWETH_TOKEN,
  {
    address: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',
    symbol: 'USDC',
    name: 'USD Coin',
    decimals: 6,
    isNative: false,
  },
  {
    address: '0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb',
    symbol: 'DAI',
    name: 'Dai Stablecoin',
    decimals: 18,
    isNative: false,
  },
];

const ERC20_ABI = parseAbi([
  'function balanceOf(address owner) view returns (uint256)',
  'function symbol() view returns (string)',
  'function name() view returns (string)',
  'function decimals() view returns (uint8)',
  'event Transfer(address indexed from, address indexed to, uint256 value)',
]);

export function useUserTokens() {
  const { address: userAddress } = useAccount();
  const publicClient = usePublicClient();
  const [userTokens, setUserTokens] = useState<TokenWithSource[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const scanUserTokens = useCallback(async () => {
    if (!userAddress || !publicClient) return;

    setLoading(true);
    setError(null);

    try {
      const tokensWithBalance: TokenWithSource[] = [];

      // Add ETH as native token
      const ethBalance = await publicClient.getBalance({
        address: userAddress,
      });

      if (ethBalance > 0n) {
        tokensWithBalance.push({
          address: '0x0000000000000000000000000000000000000000',
          symbol: 'ETH',
          name: 'Ethereum',
          decimals: 18,
          isNative: true,
          balance: ethBalance.toString(),
          source: TokenSource.USER_OWNED,
        });
      }

      // Check balances for common tokens
      for (const token of COMMON_TOKENS) {
        try {
          const contract = getContract({
            address: token.address as `0x${string}`,
            abi: ERC20_ABI,
            client: publicClient,
          });

          const balance = await contract.read.balanceOf([userAddress]);

          if (balance > 0n) {
            tokensWithBalance.push({
              ...token,
              balance: balance.toString(),
              source: TokenSource.USER_OWNED,
            });
          }
        } catch (tokenError) {
          console.warn(`Failed to get balance for token ${token.symbol}:`, tokenError);
        }
      }

      // Scan for additional tokens through Transfer events
      try {
        const currentBlock = await publicClient.getBlockNumber();
        const fromBlock = currentBlock > 10000n ? currentBlock - 10000n : 0n;
        
        const logs = await publicClient.getLogs({
          address: undefined,
          event: {
            type: 'event',
            name: 'Transfer',
            inputs: [
              { name: 'from', type: 'address', indexed: true },
              { name: 'to', type: 'address', indexed: true },
              { name: 'value', type: 'uint256', indexed: false },
            ],
          },
          args: {
            to: userAddress,
          },
          fromBlock,
          toBlock: 'latest',
        });

        const uniqueTokenAddresses = new Set<string>();
        
        logs.forEach((log) => {
          if (log.address) {
            uniqueTokenAddresses.add(log.address.toLowerCase());
          }
        });

        // Remove already checked tokens
        COMMON_TOKENS.forEach(token => {
          uniqueTokenAddresses.delete(token.address.toLowerCase());
        });

        // Check balances for discovered tokens
        for (const tokenAddress of uniqueTokenAddresses) {
          try {
            const contract = getContract({
              address: tokenAddress as `0x${string}`,
              abi: ERC20_ABI,
              client: publicClient,
            });

            const [balance, symbol, name, decimals] = await Promise.all([
              contract.read.balanceOf([userAddress]),
              contract.read.symbol(),
              contract.read.name(),
              contract.read.decimals(),
            ]);

            if (balance > 0n) {
              tokensWithBalance.push({
                address: tokenAddress,
                symbol,
                name,
                decimals,
                balance: balance.toString(),
                source: TokenSource.USER_OWNED,
              });
            }
          } catch (tokenError) {
            console.warn(`Failed to get token info for ${tokenAddress}:`, tokenError);
          }
        }
      } catch (scanError) {
        console.warn('Failed to scan Transfer events:', scanError);
      }

      setUserTokens(tokensWithBalance);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to scan user tokens';
      setError(errorMessage);
      console.error('Error scanning user tokens:', err);
    } finally {
      setLoading(false);
    }
  }, [userAddress, publicClient]);

  const getAllTokens = useCallback(() => {
    const defaultTokens: TokenWithSource[] = COMMON_TOKENS.map(token => ({
      ...token,
      source: TokenSource.DEFAULT,
    }));

    // Add ETH as default token
    const ethToken: TokenWithSource = {
      address: '0x0000000000000000000000000000000000000000',
      symbol: 'ETH',
      name: 'Ethereum',
      decimals: 18,
      isNative: true,
      source: TokenSource.DEFAULT,
    };

    return [ethToken, ...defaultTokens, ...userTokens];
  }, [userTokens]);

  useEffect(() => {
    if (userAddress) {
      scanUserTokens();
    }
  }, [userAddress, scanUserTokens]);

  return {
    userTokens,
    allTokens: getAllTokens(),
    loading,
    error,
    refetch: scanUserTokens,
  };
}