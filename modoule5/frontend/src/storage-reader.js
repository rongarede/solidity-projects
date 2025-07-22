import { createPublicClient, http, keccak256, encodePacked, hexToNumber, hexToBigInt, toHex, size } from 'viem'
import { foundry } from 'viem/chains'
import fs from 'fs'

// 创建客户端连接到本地网络
const client = createPublicClient({
  chain: foundry,
  transport: http('http://127.0.0.1:8545')
})

// 从broadcast文件读取合约地址
function getContractAddress() {
  try {
    const broadcastFile = '../ReadLock/broadcast/ReadLock.s.sol/31337/run-latest.json'
    const broadcast = JSON.parse(fs.readFileSync(broadcastFile, 'utf8'))
    return broadcast.transactions[0].contractAddress
  } catch (error) {
    console.error('Failed to read contract address:', error)
    // 如果读取失败，使用默认地址
    return '0x5FbDB2315678afecb367f032d93F642f64180aa3'
  }
}

// 计算动态数组的存储槽位
function calculateArraySlot(baseSlot) {
  return keccak256(encodePacked(['uint256'], [BigInt(baseSlot)]))
}

// 读取数组长度
async function getArrayLength(contractAddress) {
  try {
    const lengthData = await client.getStorageAt({
      address: contractAddress,
      slot: toHex(0, { size: 32 })
    })
    return hexToNumber(lengthData)
  } catch (error) {
    console.error('Failed to read array length:', error)
    return 0
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
  return date.toLocaleString()
}

// 读取所有锁仓信息
async function readAllLocks() {
  const contractAddress = getContractAddress()
  console.log(`Reading from contract: ${contractAddress}`)
  
  // 读取数组长度
  const arrayLength = await getArrayLength(contractAddress)
  console.log(`Array length: ${arrayLength}`)
  
  if (arrayLength === 0) {
    console.log('No locks found.')
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
          address: contractAddress,
          slot: toHex(slot1, { size: 32 })
        }),
        client.getStorageAt({
          address: contractAddress,
          slot: toHex(slot2, { size: 32 })
        })
      ])
      
      // 解析数据
      const lockInfo = parseLockInfo(slot1Data, slot2Data, i)
      locks.push(lockInfo)
      
      // 打印结果
      console.log(`locks[${i}]: user: ${lockInfo.user}, startTime: ${lockInfo.formattedTime}, amount: ${lockInfo.formattedAmount}`)
      
    } catch (error) {
      console.error(`Failed to read lock ${i}:`, error)
    }
  }
  
  return locks
}

// 主函数
async function main() {
  console.log('🔍 Reading ReadLock contract storage...')
  console.log('=' .repeat(60))
  
  try {
    const locks = await readAllLocks()
    
    console.log('=' .repeat(60))
    console.log(`✅ Successfully read ${locks.length} locks from contract`)
    
    // 返回数据供前端使用
    return locks
    
  } catch (error) {
    console.error('❌ Error reading contract storage:', error)
    return []
  }
}

// 如果直接运行此脚本
if (import.meta.url === `file://${process.argv[1]}`) {
  main()
}

export { readAllLocks, getContractAddress }