'use client';

import { useEffect, useState } from 'react';
import errorLogger from '../lib/error-logger';

/**
 * 全局错误监控组件
 * 在应用启动时初始化错误监控系统
 */
export default function ErrorMonitor() {
  const [isClient, setIsClient] = useState(false);

  useEffect(() => {
    setIsClient(true);
    // 只在客户端初始化错误监控
    if (typeof window !== 'undefined') {
      errorLogger.initialize();
    }
  }, []);

  // 这个组件不渲染任何UI
  return null;
}