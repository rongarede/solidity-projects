'use client'

import { useState } from 'react'
import { useErrorLogger } from '../../hooks/useErrorLogger'

export default function TestErrorsPage() {
  const [testResult, setTestResult] = useState<string>('')
  const { 
    logWalletError, 
    logTransactionError, 
    logNetworkError, 
    logCalculationError, 
    logUIError,
    tryWalletOperation 
  } = useErrorLogger()

  const testJavaScriptError = () => {
    // 这将触发全局错误捕获
    throw new Error('这是一个测试的JavaScript错误')
  }

  const testPromiseRejection = () => {
    // 这将触发Promise rejection捕获
    Promise.reject(new Error('这是一个测试的Promise rejection错误'))
  }

  const testWalletError = async () => {
    await logWalletError('测试钱包连接失败', { 
      reason: 'user_rejected',
      walletType: 'MetaMask'
    })
    setTestResult('钱包错误已记录')
  }

  const testTransactionError = async () => {
    await logTransactionError('测试交易失败', {
      txHash: '0x123...',
      gasUsed: '21000',
      reason: 'insufficient_funds'
    })
    setTestResult('交易错误已记录')
  }

  const testNetworkError = async () => {
    await logNetworkError('测试网络连接超时', {
      endpoint: 'https://base-mainnet.g.alchemy.com',
      timeout: 5000
    })
    setTestResult('网络错误已记录')
  }

  const testCalculationError = async () => {
    await logCalculationError('测试计算溢出错误', {
      operation: 'division_by_zero',
      values: { a: 100, b: 0 }
    })
    setTestResult('计算错误已记录')
  }

  const testUIError = async () => {
    await logUIError('测试组件渲染错误', {
      component: 'TestErrorsPage',
      props: { test: true }
    })
    setTestResult('UI错误已记录')
  }

  const testWrappedOperation = async () => {
    const result = await tryWalletOperation(
      async () => {
        // 模拟一个会失败的钱包操作
        throw new Error('模拟的钱包操作失败')
      },
      '测试钱包操作',
      { operationType: 'connect' }
    )
    
    setTestResult(result ? '操作成功' : '操作失败，错误已自动记录')
  }

  return (
    <div className="container mx-auto p-8">
      <h1 className="text-3xl font-bold mb-8">错误监控测试页面</h1>
      
      <div className="grid grid-cols-2 gap-4 mb-8">
        <div className="space-y-4">
          <h2 className="text-xl font-semibold">自动错误捕获测试</h2>
          
          <button
            onClick={testJavaScriptError}
            className="w-full px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600"
          >
            触发JavaScript错误
          </button>
          
          <button
            onClick={testPromiseRejection}
            className="w-full px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600"
          >
            触发Promise Rejection
          </button>
        </div>

        <div className="space-y-4">
          <h2 className="text-xl font-semibold">手动错误记录测试</h2>
          
          <button
            onClick={testWalletError}
            className="w-full px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
          >
            记录钱包错误
          </button>
          
          <button
            onClick={testTransactionError}
            className="w-full px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
          >
            记录交易错误
          </button>
          
          <button
            onClick={testNetworkError}
            className="w-full px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
          >
            记录网络错误
          </button>
          
          <button
            onClick={testCalculationError}
            className="w-full px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
          >
            记录计算错误
          </button>
          
          <button
            onClick={testUIError}
            className="w-full px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
          >
            记录UI错误
          </button>
          
          <button
            onClick={testWrappedOperation}
            className="w-full px-4 py-2 bg-purple-500 text-white rounded hover:bg-purple-600"
          >
            测试包装操作
          </button>
        </div>
      </div>

      {testResult && (
        <div className="p-4 bg-green-100 border border-green-400 rounded">
          <p className="text-green-700">{testResult}</p>
        </div>
      )}

      <div className="mt-8">
        <h2 className="text-xl font-semibold mb-4">使用说明</h2>
        <div className="bg-gray-100 p-4 rounded">
          <p className="mb-2">1. 点击上面的按钮来触发不同类型的错误</p>
          <p className="mb-2">2. 错误会被自动记录到 <code>/logs/error-log.txt</code> 文件中</p>
          <p className="mb-2">3. Claude Code 可以读取这个文件来分析错误</p>
          <p>4. 打开浏览器控制台也可以看到错误信息</p>
        </div>
      </div>
    </div>
  )
}