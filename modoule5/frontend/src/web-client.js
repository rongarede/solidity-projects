import { createPublicClient, http, keccak256, encodePacked, hexToNumber, hexToBigInt, toHex } from 'viem'
import { foundry } from 'viem/chains'

// 创建客户端连接到本地网络
const client = createPublicClient({
  chain: foundry,
  transport: http('http://127.0.0.1:8545')
})

// 合约地址 (从部署中获取)
const CONTRACT_ADDRESS = '0x5FbDB2315678afecb367f032d93F642f64180aa3'

// 全局变量
let currentLocks = []

// 页面加载时初始化
document.addEventListener('DOMContentLoaded', function() {
  document.getElementById('contract-address').textContent = CONTRACT_ADDRESS
})

// 计算动态数组的存储槽位
function calculateArraySlot(baseSlot) {
  return keccak256(encodePacked(['uint256'], [BigInt(baseSlot)]))
}

// 读取数组长度
async function getArrayLength() {
  try {
    const lengthData = await client.getStorageAt({
      address: CONTRACT_ADDRESS,
      slot: toHex(0, { size: 32 })
    })
    return hexToNumber(lengthData)
  } catch (error) {
    console.error('Failed to read array length:', error)
    throw error
  }
}

// 解析LockInfo结构体
function parseLockInfo(slot1Data, slot2Data, index) {
  // slot1: address(20 bytes) + startTime(8 bytes) + padding(4 bytes)
  // slot2: amount(32 bytes)
  
  // 解析地址 (最后20字节)
  const userAddress = '0x' + slot1Data.slice(-40)
  
  // 解析startTime (第21-28字节，即倒数第41-48位)
  const startTimeHex = '0x' + slot1Data.slice(26, 42)
  const startTime = hexToBigInt(startTimeHex)
  
  // 解析amount
  const amount = hexToBigInt(slot2Data)
  
  return {
    index,
    user: userAddress,
    startTime: Number(startTime),
    amount: amount,
    formattedAmount: formatAmount(amount),
    formattedTime: formatTimestamp(Number(startTime))
  }
}

// 格式化金额 (Wei to ETH)
function formatAmount(amountWei) {
  const eth = Number(amountWei) / 1e18
  return `${eth} ETH`
}

// 格式化时间戳
function formatTimestamp(timestamp) {
  const date = new Date(timestamp * 1000)
  return date.toLocaleString('zh-CN')
}

// 显示错误信息
function showError(message) {
  const errorDiv = document.getElementById('error')
  errorDiv.textContent = message
  errorDiv.style.display = 'block'
  setTimeout(() => {
    errorDiv.style.display = 'none'
  }, 5000)
}

// 显示加载状态
function setLoading(isLoading) {
  const loadingDiv = document.getElementById('loading')
  const readBtn = document.getElementById('read-btn')
  const refreshBtn = document.getElementById('refresh-btn')
  
  if (isLoading) {
    loadingDiv.style.display = 'block'
    readBtn.disabled = true
    refreshBtn.disabled = true
  } else {
    loadingDiv.style.display = 'none'
    readBtn.disabled = false
    refreshBtn.disabled = false
  }
}

// 更新统计信息
function updateStats(locks) {
  const totalLocks = locks.length
  const totalAmount = locks.reduce((sum, lock) => sum + Number(lock.amount), 0) / 1e18
  const uniqueUsers = new Set(locks.map(lock => lock.user)).size
  
  document.getElementById('total-locks').textContent = totalLocks
  document.getElementById('total-amount').textContent = totalAmount.toFixed(2)
  document.getElementById('unique-users').textContent = uniqueUsers
  
  document.getElementById('stats').style.display = 'flex'
}

// 渲染锁仓数据表格
function renderLocks(locks) {
  const tbody = document.getElementById('locks-tbody')
  tbody.innerHTML = ''
  
  locks.forEach(lock => {
    const row = document.createElement('tr')
    row.innerHTML = `
      <td>${lock.index}</td>
      <td class="address">${lock.user}</td>
      <td class="timestamp">${lock.formattedTime}</td>
      <td class="amount">${lock.formattedAmount}</td>
      <td class="timestamp">${lock.startTime}</td>
    `
    tbody.appendChild(row)
  })
  
  document.getElementById('locks-container').style.display = 'block'
}

// 读取所有锁仓信息
async function readAllLocks() {
  try {
    setLoading(true)
    document.getElementById('error').style.display = 'none'
    
    // 读取数组长度
    const arrayLength = await getArrayLength()
    console.log(`Array length: ${arrayLength}`)
    
    if (arrayLength === 0) {
      showError('未找到锁仓记录')
      return []
    }
    
    // 计算数组起始槽位
    const baseSlot = calculateArraySlot(0)
    console.log(`Array starts at slot: ${baseSlot}`)
    
    const locks = []
    
    // 读取每个锁仓信息
    for (let i = 0; i < arrayLength; i++) {
      try {
        // 每个LockInfo结构体占用2个槽位
        const slot1 = BigInt(baseSlot) + BigInt(i * 2)
        const slot2 = BigInt(baseSlot) + BigInt(i * 2 + 1)
        
        // 读取两个槽位的数据
        const [slot1Data, slot2Data] = await Promise.all([
          client.getStorageAt({
            address: CONTRACT_ADDRESS,
            slot: toHex(slot1, { size: 32 })
          }),
          client.getStorageAt({
            address: CONTRACT_ADDRESS,
            slot: toHex(slot2, { size: 32 })
          })
        ])
        
        // 解析数据
        const lockInfo = parseLockInfo(slot1Data, slot2Data, i)
        locks.push(lockInfo)
        
        // 在控制台打印结果
        console.log(`locks[${i}]: user: ${lockInfo.user}, startTime: ${lockInfo.formattedTime}, amount: ${lockInfo.formattedAmount}`)
        
      } catch (error) {
        console.error(`Failed to read lock ${i}:`, error)
        showError(`读取锁仓记录 ${i} 失败: ${error.message}`)
      }
    }
    
    return locks
    
  } catch (error) {
    console.error('Error reading contract storage:', error)
    showError(`读取合约存储失败: ${error.message}`)
    return []
  } finally {
    setLoading(false)
  }
}

// 主要的读取函数
window.readLocks = async function() {
  try {
    console.log('🔍 Reading ReadLock contract storage...')
    
    const locks = await readAllLocks()
    
    if (locks.length > 0) {
      currentLocks = locks
      renderLocks(locks)
      updateStats(locks)
      
      // 更新最后更新时间
      document.getElementById('last-update').textContent = new Date().toLocaleString('zh-CN')
      
      console.log(`✅ Successfully read ${locks.length} locks from contract`)
    }
    
  } catch (error) {
    console.error('❌ Error in readLocks:', error)
    showError(`读取失败: ${error.message}`)
  }
}

// 刷新数据
window.refreshData = async function() {
  await readLocks()
}

// 导出函数供其他模块使用
export { readAllLocks, CONTRACT_ADDRESS }