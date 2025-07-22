'use client';

import { useCallback } from 'react';
import { 
  logWalletError, 
  logTransactionError, 
  logNetworkError, 
  logCalculationError, 
  logUIError, 
  logError,
  type ErrorType 
} from '../lib/error-logger';

/**
 * 错误日志记录 Hook
 * 提供便捷的错误记录方法供React组件使用
 */
export function useErrorLogger() {
  
  const logWalletErrorCallback = useCallback(async (message: string, context?: Record<string, any>) => {
    try {
      await logWalletError(message, context);
    } catch (error) {
      console.error('Failed to log wallet error:', error);
    }
  }, []);

  const logTransactionErrorCallback = useCallback(async (message: string, context?: Record<string, any>) => {
    try {
      await logTransactionError(message, context);
    } catch (error) {
      console.error('Failed to log transaction error:', error);
    }
  }, []);

  const logNetworkErrorCallback = useCallback(async (message: string, context?: Record<string, any>) => {
    try {
      await logNetworkError(message, context);
    } catch (error) {
      console.error('Failed to log network error:', error);
    }
  }, []);

  const logCalculationErrorCallback = useCallback(async (message: string, context?: Record<string, any>) => {
    try {
      await logCalculationError(message, context);
    } catch (error) {
      console.error('Failed to log calculation error:', error);
    }
  }, []);

  const logUIErrorCallback = useCallback(async (message: string, context?: Record<string, any>) => {
    try {
      await logUIError(message, context);
    } catch (error) {
      console.error('Failed to log UI error:', error);
    }
  }, []);

  const logErrorCallback = useCallback(async (errorType: ErrorType, message: string, context?: Record<string, any>) => {
    try {
      await logError({ errorType, message, context });
    } catch (error) {
      console.error('Failed to log error:', error);
    }
  }, []);

  /**
   * 尝试执行异步操作，如果失败则记录错误
   */
  const tryWithErrorLogging = useCallback(async <T>(
    operation: () => Promise<T>,
    errorType: ErrorType,
    operationName: string,
    context?: Record<string, any>
  ): Promise<T | null> => {
    try {
      return await operation();
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      await logErrorCallback(errorType, `${operationName} failed: ${errorMessage}`, {
        ...context,
        originalError: error
      });
      return null;
    }
  }, [logErrorCallback]);

  /**
   * 包装钱包操作，自动记录错误
   */
  const tryWalletOperation = useCallback(async <T>(
    operation: () => Promise<T>,
    operationName: string,
    context?: Record<string, any>
  ): Promise<T | null> => {
    return tryWithErrorLogging(operation, 'wallet', operationName, context);
  }, [tryWithErrorLogging]);

  /**
   * 包装交易操作，自动记录错误
   */
  const tryTransactionOperation = useCallback(async <T>(
    operation: () => Promise<T>,
    operationName: string,
    context?: Record<string, any>
  ): Promise<T | null> => {
    return tryWithErrorLogging(operation, 'transaction', operationName, context);
  }, [tryWithErrorLogging]);

  /**
   * 包装网络操作，自动记录错误
   */
  const tryNetworkOperation = useCallback(async <T>(
    operation: () => Promise<T>,
    operationName: string,
    context?: Record<string, any>
  ): Promise<T | null> => {
    return tryWithErrorLogging(operation, 'network', operationName, context);
  }, [tryWithErrorLogging]);

  return {
    // 直接记录错误的方法
    logWalletError: logWalletErrorCallback,
    logTransactionError: logTransactionErrorCallback,
    logNetworkError: logNetworkErrorCallback,
    logCalculationError: logCalculationErrorCallback,
    logUIError: logUIErrorCallback,
    logError: logErrorCallback,
    
    // 包装操作的方法
    tryWithErrorLogging,
    tryWalletOperation,
    tryTransactionOperation,
    tryNetworkOperation
  };
}