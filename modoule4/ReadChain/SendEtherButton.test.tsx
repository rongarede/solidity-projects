import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { ethers } from 'ethers';
import SendEtherButton from './SendEtherButton';

// Mock ethers.js
jest.mock('ethers', () => ({
  ethers: {
    BrowserProvider: jest.fn(),
    isAddress: jest.fn(),
    parseEther: jest.fn(),
  },
}));

// Mock window.ethereum
const mockEthereum = {
  request: jest.fn(),
};

// TypeScript declarations for mocked modules
const mockedEthers = ethers as jest.Mocked<typeof ethers>;

describe('SendEtherButton', () => {
  // Mock functions
  const mockSendTransaction = jest.fn();
  const mockWait = jest.fn();
  const mockGetSigner = jest.fn();
  const mockBrowserProvider = jest.fn();

  beforeEach(() => {
    // Reset all mocks
    jest.clearAllMocks();
    
    // Setup window.ethereum mock
    Object.defineProperty(window, 'ethereum', {
      value: mockEthereum,
      writable: true,
    });

    // Setup ethers mocks
    mockedEthers.isAddress.mockReturnValue(true);
    mockedEthers.parseEther.mockReturnValue('1000000000000000000' as any); // 1 ETH in wei
    
    mockBrowserProvider.mockImplementation(() => ({
      getSigner: mockGetSigner,
    }));
    
    mockedEthers.BrowserProvider = mockBrowserProvider as any;
    
    mockGetSigner.mockResolvedValue({
      sendTransaction: mockSendTransaction,
    });

    // Setup default successful transaction response
    mockSendTransaction.mockResolvedValue({
      hash: '0x123456789abcdef',
      wait: mockWait,
    });
    
    mockWait.mockResolvedValue({
      status: 1,
      transactionHash: '0x123456789abcdef',
    });

    // Setup default MetaMask connection
    mockEthereum.request.mockResolvedValue(['0x1234567890123456789012345678901234567890']);
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  const defaultProps = {
    toAddress: '0x742Ca0cb7C23E3F2C823EdE63dB6C2b4b19D16Cb',
    amount: '1.0',
  };

  describe('Successful Transaction Flow', () => {
    test('should render component with correct initial state', () => {
      render(<SendEtherButton {...defaultProps} />);
      
      expect(screen.getByTestId('send-ether-button')).toBeInTheDocument();
      expect(screen.getByText('Send ETH')).toBeInTheDocument();
      expect(screen.getByText('To: 0x742Ca0cb7C23E3F2C823EdE63dB6C2b4b19D16Cb')).toBeInTheDocument();
      expect(screen.getByText('Amount: 1.0 ETH')).toBeInTheDocument();
    });

    test('should successfully send ETH and show success message', async () => {
      const onSuccess = jest.fn();
      const onError = jest.fn();
      
      render(
        <SendEtherButton 
          {...defaultProps} 
          onSuccess={onSuccess}
          onError={onError}
        />
      );
      
      const sendButton = screen.getByTestId('send-ether-button');
      fireEvent.click(sendButton);

      // Check loading state
      expect(screen.getByTestId('loading-indicator')).toBeInTheDocument();
      expect(screen.getByText('Transaction in progress...')).toBeInTheDocument();
      expect(sendButton).toBeDisabled();

      // Wait for transaction completion
      await waitFor(() => {
        expect(screen.getByTestId('success-message')).toBeInTheDocument();
      });

      // Verify success state
      expect(screen.getByText('交易成功 ✅')).toBeInTheDocument();
      expect(screen.getByTestId('tx-hash')).toBeInTheDocument();
      expect(screen.getByText('Transaction Hash: 0x123456789abcdef')).toBeInTheDocument();
      
      // Verify callbacks
      expect(onSuccess).toHaveBeenCalledWith('0x123456789abcdef');
      expect(onError).not.toHaveBeenCalled();

      // Verify ethers calls
      expect(mockEthereum.request).toHaveBeenCalledWith({
        method: 'eth_requestAccounts',
      });
      expect(mockedEthers.BrowserProvider).toHaveBeenCalledWith(window.ethereum);
      expect(mockGetSigner).toHaveBeenCalled();
      expect(mockedEthers.isAddress).toHaveBeenCalledWith(defaultProps.toAddress);
      expect(mockedEthers.parseEther).toHaveBeenCalledWith(defaultProps.amount);
      expect(mockSendTransaction).toHaveBeenCalledWith({
        to: defaultProps.toAddress,
        value: '1000000000000000000',
      });
      expect(mockWait).toHaveBeenCalled();
    });
  });

  describe('Error Handling', () => {
    test('should handle MetaMask not found error', async () => {
      // Remove window.ethereum
      Object.defineProperty(window, 'ethereum', {
        value: undefined,
        writable: true,
      });

      const onError = jest.fn();
      render(<SendEtherButton {...defaultProps} onError={onError} />);
      
      fireEvent.click(screen.getByTestId('send-ether-button'));

      await waitFor(() => {
        expect(screen.getByTestId('error-message')).toBeInTheDocument();
      });

      expect(screen.getByText('Error: MetaMask not found')).toBeInTheDocument();
      expect(onError).toHaveBeenCalledWith('MetaMask not found');
      expect(screen.queryByTestId('success-message')).not.toBeInTheDocument();
    });

    test('should handle user rejection of MetaMask connection', async () => {
      mockEthereum.request.mockRejectedValue(new Error('User rejected'));

      const onError = jest.fn();
      render(<SendEtherButton {...defaultProps} onError={onError} />);
      
      fireEvent.click(screen.getByTestId('send-ether-button'));

      await waitFor(() => {
        expect(screen.getByTestId('error-message')).toBeInTheDocument();
      });

      expect(screen.getByText('Error: User rejected MetaMask connection')).toBeInTheDocument();
      expect(onError).toHaveBeenCalledWith('User rejected MetaMask connection');
    });

    test('should handle invalid recipient address', async () => {
      mockedEthers.isAddress.mockReturnValue(false);

      const onError = jest.fn();
      render(<SendEtherButton {...defaultProps} onError={onError} />);
      
      fireEvent.click(screen.getByTestId('send-ether-button'));

      await waitFor(() => {
        expect(screen.getByTestId('error-message')).toBeInTheDocument();
      });

      expect(screen.getByText('Error: Invalid recipient address')).toBeInTheDocument();
      expect(onError).toHaveBeenCalledWith('Invalid recipient address');
    });

    test('should handle invalid amount', async () => {
      const onError = jest.fn();
      render(<SendEtherButton {...defaultProps} amount="0" onError={onError} />);
      
      fireEvent.click(screen.getByTestId('send-ether-button'));

      await waitFor(() => {
        expect(screen.getByTestId('error-message')).toBeInTheDocument();
      });

      expect(screen.getByText('Error: Invalid amount')).toBeInTheDocument();
      expect(onError).toHaveBeenCalledWith('Invalid amount');
    });

    test('should handle transaction failure during send', async () => {
      const transactionError = new Error('Insufficient funds');
      mockSendTransaction.mockRejectedValue(transactionError);

      const onError = jest.fn();
      render(<SendEtherButton {...defaultProps} onError={onError} />);
      
      fireEvent.click(screen.getByTestId('send-ether-button'));

      await waitFor(() => {
        expect(screen.getByTestId('error-message')).toBeInTheDocument();
      });

      expect(screen.getByText('Error: Insufficient funds')).toBeInTheDocument();
      expect(onError).toHaveBeenCalledWith('Insufficient funds');
      expect(screen.queryByTestId('success-message')).not.toBeInTheDocument();
    });

    test('should handle transaction failure during confirmation', async () => {
      mockWait.mockResolvedValue({
        status: 0, // Failed transaction
        transactionHash: '0x123456789abcdef',
      });

      const onError = jest.fn();
      render(<SendEtherButton {...defaultProps} onError={onError} />);
      
      fireEvent.click(screen.getByTestId('send-ether-button'));

      await waitFor(() => {
        expect(screen.getByTestId('error-message')).toBeInTheDocument();
      });

      expect(screen.getByText('Error: Transaction failed')).toBeInTheDocument();
      expect(onError).toHaveBeenCalledWith('Transaction failed');
      expect(screen.queryByTestId('success-message')).not.toBeInTheDocument();
    });

    test('should handle network error during transaction wait', async () => {
      mockWait.mockRejectedValue(new Error('Network error'));

      const onError = jest.fn();
      render(<SendEtherButton {...defaultProps} onError={onError} />);
      
      fireEvent.click(screen.getByTestId('send-ether-button'));

      await waitFor(() => {
        expect(screen.getByTestId('error-message')).toBeInTheDocument();
      });

      expect(screen.getByText('Error: Network error')).toBeInTheDocument();
      expect(onError).toHaveBeenCalledWith('Network error');
    });
  });

  describe('UI State Management', () => {
    test('should disable button during transaction', async () => {
      // Make transaction take longer to complete
      mockWait.mockImplementation(() => new Promise(resolve => setTimeout(() => resolve({ status: 1 }), 100)));

      render(<SendEtherButton {...defaultProps} />);
      
      const sendButton = screen.getByTestId('send-ether-button');
      fireEvent.click(sendButton);

      // Check button is disabled during transaction
      expect(sendButton).toBeDisabled();
      expect(screen.getByText('Sending...')).toBeInTheDocument();

      // Wait for completion
      await waitFor(() => {
        expect(screen.getByTestId('success-message')).toBeInTheDocument();
      });

      // Button should be enabled again
      expect(sendButton).not.toBeDisabled();
      expect(screen.getByText('Send ETH')).toBeInTheDocument();
    });

    test('should clear previous error when starting new transaction', async () => {
      // First, cause an error
      mockedEthers.isAddress.mockReturnValue(false);
      
      const { rerender } = render(<SendEtherButton {...defaultProps} />);
      fireEvent.click(screen.getByTestId('send-ether-button'));

      await waitFor(() => {
        expect(screen.getByTestId('error-message')).toBeInTheDocument();
      });

      // Now fix the error and try again
      mockedEthers.isAddress.mockReturnValue(true);
      rerender(<SendEtherButton {...defaultProps} />);
      
      fireEvent.click(screen.getByTestId('send-ether-button'));

      // Error should be cleared
      expect(screen.queryByTestId('error-message')).not.toBeInTheDocument();
      
      await waitFor(() => {
        expect(screen.getByTestId('success-message')).toBeInTheDocument();
      });
    });
  });

  describe('Edge Cases', () => {
    test('should handle empty amount string', async () => {
      const onError = jest.fn();
      render(<SendEtherButton {...defaultProps} amount="" onError={onError} />);
      
      fireEvent.click(screen.getByTestId('send-ether-button'));

      await waitFor(() => {
        expect(screen.getByTestId('error-message')).toBeInTheDocument();
      });

      expect(screen.getByText('Error: Invalid amount')).toBeInTheDocument();
    });

    test('should handle negative amount', async () => {
      const onError = jest.fn();
      render(<SendEtherButton {...defaultProps} amount="-1" onError={onError} />);
      
      fireEvent.click(screen.getByTestId('send-ether-button'));

      await waitFor(() => {
        expect(screen.getByTestId('error-message')).toBeInTheDocument();
      });

      expect(screen.getByText('Error: Invalid amount')).toBeInTheDocument();
    });

    test('should handle multiple rapid clicks', async () => {
      render(<SendEtherButton {...defaultProps} />);
      
      const sendButton = screen.getByTestId('send-ether-button');
      
      // Click multiple times rapidly
      fireEvent.click(sendButton);
      fireEvent.click(sendButton);
      fireEvent.click(sendButton);

      // Only one transaction should be initiated
      expect(mockSendTransaction).toHaveBeenCalledTimes(1);
      
      await waitFor(() => {
        expect(screen.getByTestId('success-message')).toBeInTheDocument();
      });
    });
  });
});