import React, { useState } from 'react';
import { ethers } from 'ethers';

interface SendEtherButtonProps {
  toAddress: string;
  amount: string;
  onSuccess?: (txHash: string) => void;
  onError?: (error: string) => void;
}

export const SendEtherButton: React.FC<SendEtherButtonProps> = ({
  toAddress,
  amount,
  onSuccess,
  onError,
}) => {
  const [isLoading, setIsLoading] = useState(false);
  const [txHash, setTxHash] = useState<string>('');
  const [error, setError] = useState<string>('');
  const [isSuccess, setIsSuccess] = useState(false);

  const checkMetaMaskConnection = async (): Promise<boolean> => {
    if (typeof window.ethereum === 'undefined') {
      throw new Error('MetaMask not found');
    }

    try {
      const accounts = await window.ethereum.request({
        method: 'eth_requestAccounts',
      });
      return accounts.length > 0;
    } catch (error) {
      throw new Error('User rejected MetaMask connection');
    }
  };

  const sendEther = async () => {
    setIsLoading(true);
    setError('');
    setTxHash('');
    setIsSuccess(false);

    try {
      // 检查MetaMask连接
      await checkMetaMaskConnection();

      // 创建provider和signer
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();

      // 验证地址格式
      if (!ethers.isAddress(toAddress)) {
        throw new Error('Invalid recipient address');
      }

      // 验证金额
      if (!amount || parseFloat(amount) <= 0) {
        throw new Error('Invalid amount');
      }

      // 构建交易
      const transaction = {
        to: toAddress,
        value: ethers.parseEther(amount),
      };

      // 发送交易
      const txResponse = await signer.sendTransaction(transaction);
      setTxHash(txResponse.hash);

      // 等待交易确认
      const receipt = await txResponse.wait();
      
      if (receipt && receipt.status === 1) {
        setIsSuccess(true);
        onSuccess?.(txResponse.hash);
      } else {
        throw new Error('Transaction failed');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      setError(errorMessage);
      onError?.(errorMessage);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="send-ether-container">
      <button
        onClick={sendEther}
        disabled={isLoading}
        className="send-ether-button"
        data-testid="send-ether-button"
      >
        {isLoading ? 'Sending...' : 'Send ETH'}
      </button>

      {isLoading && (
        <div data-testid="loading-indicator" className="loading">
          Transaction in progress...
        </div>
      )}

      {txHash && !error && (
        <div data-testid="tx-hash" className="tx-hash">
          Transaction Hash: {txHash}
        </div>
      )}

      {isSuccess && (
        <div data-testid="success-message" className="success">
          交易成功 ✅
        </div>
      )}

      {error && (
        <div data-testid="error-message" className="error">
          Error: {error}
        </div>
      )}

      <div className="transaction-info">
        <p>To: {toAddress}</p>
        <p>Amount: {amount} ETH</p>
      </div>
    </div>
  );
};

export default SendEtherButton;