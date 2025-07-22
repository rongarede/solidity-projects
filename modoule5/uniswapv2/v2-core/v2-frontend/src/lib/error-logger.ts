export type ErrorType = 'wallet' | 'transaction' | 'network' | 'calculation' | 'ui' | 'unknown';

export interface ErrorLogData {
  timestamp: string;
  errorType: ErrorType;
  message: string;
  stack?: string;
  url?: string;
  userAgent?: string;
  context?: Record<string, any>;
}

class ErrorLogger {
  private isInitialized = false;

  /**
   * 初始化全局错误监控
   */
  public initialize() {
    if (this.isInitialized || typeof window === 'undefined') {
      return;
    }

    // 捕获 JavaScript 错误
    window.onerror = (message, source, lineno, colno, error) => {
      this.logError({
        errorType: 'ui',
        message: typeof message === 'string' ? message : 'Unknown error',
        stack: error?.stack,
        context: {
          line: lineno,
          column: colno,
          source
        }
      });
      return false; // 不阻止默认错误处理
    };

    // 捕获 Promise 未处理的 rejection
    window.addEventListener('unhandledrejection', (event) => {
      const errorType = this.categorizeError(event.reason);
      
      this.logError({
        errorType,
        message: event.reason?.message || 'Unhandled promise rejection',
        stack: event.reason?.stack,
        context: {
          type: 'unhandledrejection',
          reason: event.reason
        }
      });
    });

    this.isInitialized = true;
    console.log('[Error Logger] 错误监控系统已初始化');
  }

  /**
   * 手动记录错误
   */
  public async logError(errorData: Omit<ErrorLogData, 'timestamp' | 'url' | 'userAgent'>) {
    try {
      const fullErrorData: ErrorLogData = {
        ...errorData,
        timestamp: new Date().toISOString(),
        url: typeof window !== 'undefined' ? window.location.href : undefined,
        userAgent: typeof navigator !== 'undefined' ? navigator.userAgent : undefined
      };

      // 发送到后端 API
      await fetch('/api/log-error', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(fullErrorData),
      });

      // 在开发环境下也输出到控制台
      if (process.env.NODE_ENV === 'development') {
        console.error('[Error Logger]', fullErrorData);
      }
    } catch (error) {
      // 避免无限循环，记录错误发送失败的情况
      console.error('Failed to send error log:', error);
    }
  }

  /**
   * 记录钱包相关错误
   */
  public async logWalletError(message: string, context?: Record<string, any>) {
    await this.logError({
      errorType: 'wallet',
      message,
      context
    });
  }

  /**
   * 记录交易相关错误
   */
  public async logTransactionError(message: string, context?: Record<string, any>) {
    await this.logError({
      errorType: 'transaction',
      message,
      context
    });
  }

  /**
   * 记录网络相关错误
   */
  public async logNetworkError(message: string, context?: Record<string, any>) {
    await this.logError({
      errorType: 'network',
      message,
      context
    });
  }

  /**
   * 记录计算相关错误
   */
  public async logCalculationError(message: string, context?: Record<string, any>) {
    await this.logError({
      errorType: 'calculation',
      message,
      context
    });
  }

  /**
   * 记录UI相关错误
   */
  public async logUIError(message: string, context?: Record<string, any>) {
    await this.logError({
      errorType: 'ui',
      message,
      context
    });
  }

  /**
   * 根据错误内容自动分类错误类型
   */
  private categorizeError(error: any): ErrorType {
    const message = error?.message?.toLowerCase() || '';
    const stack = error?.stack?.toLowerCase() || '';
    
    // 钱包相关关键词
    if (message.includes('wallet') || message.includes('metamask') || 
        message.includes('coinbase') || message.includes('connect') ||
        message.includes('account') || message.includes('signature')) {
      return 'wallet';
    }
    
    // 交易相关关键词
    if (message.includes('transaction') || message.includes('gas') ||
        message.includes('revert') || message.includes('insufficient') ||
        message.includes('approval') || message.includes('allowance')) {
      return 'transaction';
    }
    
    // 网络相关关键词
    if (message.includes('network') || message.includes('rpc') ||
        message.includes('timeout') || message.includes('fetch') ||
        message.includes('connection') || message.includes('cors')) {
      return 'network';
    }
    
    // 计算相关关键词
    if (message.includes('overflow') || message.includes('underflow') ||
        message.includes('division') || message.includes('nan') ||
        message.includes('calculation') || message.includes('math')) {
      return 'calculation';
    }
    
    return 'unknown';
  }
}

// 创建单例实例
export const errorLogger = new ErrorLogger();

// 导出便捷方法
export const logWalletError = errorLogger.logWalletError.bind(errorLogger);
export const logTransactionError = errorLogger.logTransactionError.bind(errorLogger);
export const logNetworkError = errorLogger.logNetworkError.bind(errorLogger);
export const logCalculationError = errorLogger.logCalculationError.bind(errorLogger);
export const logUIError = errorLogger.logUIError.bind(errorLogger);
export const logError = errorLogger.logError.bind(errorLogger);

export default errorLogger;