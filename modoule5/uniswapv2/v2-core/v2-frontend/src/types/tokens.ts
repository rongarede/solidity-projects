export interface Token {
  address: string;
  symbol: string;
  name: string;
  decimals: number;
  balance?: string;
  logoURI?: string;
  isNative?: boolean;
  isMockWETH?: boolean;
}

export enum TokenSource {
  DEFAULT = 'default',
  USER_OWNED = 'user_owned',
  CUSTOM = 'custom'
}

export interface TokenWithSource extends Token {
  source: TokenSource;
}

export interface TokenSearchResult {
  tokens: TokenWithSource[];
  loading: boolean;
  error: string | null;
}

export interface TokenBalance {
  token: Token;
  balance: bigint;
  formattedBalance: string;
  loading: boolean;
  error: string | null;
}

export interface TokenPair {
  token0: Token;
  token1: Token;
  pairAddress?: string;
}

export interface TokenAllowance {
  owner: string;
  spender: string;
  allowance: bigint;
}