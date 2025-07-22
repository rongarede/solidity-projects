import { NextRequest, NextResponse } from 'next/server';
import { writeFile, appendFile, mkdir } from 'fs/promises';
import { existsSync } from 'fs';
import path from 'path';

export interface ErrorLogData {
  timestamp: string;
  errorType: 'wallet' | 'transaction' | 'network' | 'calculation' | 'ui' | 'unknown';
  message: string;
  stack?: string;
  url?: string;
  userAgent?: string;
  context?: Record<string, any>;
}

export async function POST(request: NextRequest) {
  try {
    const errorData: ErrorLogData = await request.json();
    
    // 验证必需字段
    if (!errorData.timestamp || !errorData.errorType || !errorData.message) {
      return NextResponse.json(
        { success: false, error: 'Missing required fields' },
        { status: 400 }
      );
    }

    // 确保日志目录存在
    const logsDir = path.join(process.cwd(), 'logs');
    if (!existsSync(logsDir)) {
      await mkdir(logsDir, { recursive: true });
    }

    // 格式化错误日志条目
    const logEntry = {
      timestamp: errorData.timestamp,
      errorType: errorData.errorType,
      message: errorData.message,
      stack: errorData.stack,
      url: errorData.url,
      userAgent: errorData.userAgent,
      context: errorData.context
    };

    // 将错误信息追加到日志文件
    const logFilePath = path.join(logsDir, 'error-log.txt');
    const logLine = `${JSON.stringify(logEntry)}\n`;
    
    await appendFile(logFilePath, logLine, 'utf8');

    // 在控制台输出接收到的错误信息
    console.error('[Error Logger]', {
      type: errorData.errorType,
      message: errorData.message,
      timestamp: errorData.timestamp,
      url: errorData.url
    });

    return NextResponse.json({ success: true });
    
  } catch (error) {
    console.error('Failed to log error:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to log error' },
      { status: 500 }
    );
  }
}

// 只允许 POST 请求
export async function GET() {
  return NextResponse.json(
    { error: 'Method not allowed' },
    { status: 405 }
  );
}