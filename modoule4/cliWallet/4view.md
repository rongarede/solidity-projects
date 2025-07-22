- # ETH CLI钱包项目 - 4View 架构分析
  collapsed:: true
	- ## 项目概述
		- ETH CLI钱包是一个基于 Viem.js 和 TypeScript 构建的以太坊命令行钱包应用
		- 专为 Base 网络优化，支持钱包管理、余额查询和 ERC20 代币转账功能
		- 采用模块化设计，提供命令行和交互式两种使用模式

- # 1. 逻辑视图 (Logical View)
  collapsed:: true
	- ## 核心模块架构
		- ### 钱包管理模块 (`wallet.ts`)
		  collapsed:: true
			- 钱包生成与导入
			- 私钥管理与本地存储 
			- 钱包信息序列化
			- 本地钱包文件验证
		- ### 余额查询模块 (`balance.ts`)
		  collapsed:: true
			- ETH 余额查询
			- ERC20 代币余额查询
			- 网络信息获取
			- 地址验证功能
		- ### 转账模块 (`transfer.ts`)
		  collapsed:: true
			- ERC20 代币转账
			- Gas 费用估算
			- 批量转账支持
			- 交易状态跟踪
		- ### 命令行界面模块 (`cli.ts`)
		  collapsed:: true
			- 交互式菜单系统
			- 命令行参数解析
			- 用户输入验证
			- 统一错误处理
	- ## 模块依赖关系
		- ```mermaid
		  graph TD
		      A[cli.ts - 主入口] --> B[wallet.ts - 钱包管理]
		      A --> C[balance.ts - 余额查询]
		      A --> D[transfer.ts - 转账功能]
		      D --> B
		      C --> E[Viem.js - 区块链交互]
		      D --> E
		  ```

- # 2. 开发视图 (Development View)
  collapsed:: true
	- ## 技术栈组成
		- ### 核心依赖
		  collapsed:: true
			- **TypeScript** `5.3+` - 类型安全开发
			- **Viem.js** `2.7+` - 现代以太坊库
			- **Commander.js** `11.1+` - 命令行框架
			- **Inquirer.js** `9.2+` - 交互式界面
			- **dotenv** `16.3+` - 环境变量管理
		- ### 开发工具
		  collapsed:: true
			- **tsc** - TypeScript 编译器
			- **tsx** - TypeScript 执行器
			- **npm** - 包管理工具
	- ## 项目结构
		- ```
		  cliWallet/
		  ├── src/                    
		  │   ├── cli.ts             # 🚪 入口文件，命令行界面
		  │   ├── wallet.ts          # 🔑 钱包管理功能
		  │   ├── balance.ts         # 💰 余额查询功能
		  │   └── transfer.ts        # 💸 转账功能
		  ├── dist/                  # 📦 编译输出目录
		  ├── package.json           # ⚙️ 项目配置
		  ├── tsconfig.json         # 🔧 TypeScript 配置
		  ├── .env.example          # 📋 环境变量模板
		  └── README.md             # 📖 项目文档
		  ```
	- ## 构建流程
		- `npm install` → 安装依赖
		- `npm run build` → TypeScript 编译
		- `npm run dev` → 开发模式运行
		- `npm run cli` → 生产模式运行

- # 3. 进程视图 (Process View)
  collapsed:: true
	- ## 核心业务流程
		- ### 钱包创建流程
		  collapsed:: true
			- ```mermaid
			  flowchart TD
			      A[用户启动应用] --> B[选择创建新钱包]
			      B --> C[生成随机私钥和地址]
			      C --> D[显示钱包信息]
			      D --> E{询问是否保存到本地}
			      E -->|是| F[保存到 wallet.json]
			      E -->|否| G[仅显示信息]
			      F --> H[操作完成]
			      G --> H
			  ```
		- ### 余额查询流程
		  collapsed:: true
			- ```mermaid
			  flowchart TD
			      A[选择余额查询] --> B{选择地址来源}
			      B -->|本地钱包| C[加载 wallet.json]
			      B -->|手动输入| D[输入地址]
			      C --> E{选择查询类型}
			      D --> E
			      E -->|ETH| F[查询 ETH 余额]
			      E -->|ERC20| G[输入代币地址]
			      E -->|网络信息| H[获取网络信息]
			      G --> I[查询代币余额]
			      F --> J[显示结果]
			      I --> J
			      H --> J
			  ```
		- ### 转账流程
		  collapsed:: true
			- ```mermaid
			  flowchart TD
			      A[选择转账功能] --> B[加载本地钱包]
			      B --> C[输入转账参数]
			      C --> D{是否估算 Gas}
			      D -->|是| E[执行 Gas 估算]
			      D -->|否| F[用户确认交易]
			      E --> G{费用确认}
			      G -->|确认| F
			      G -->|取消| H[取消转账]
			      F --> I[构建并签名交易]
			      I --> J[广播到网络]
			      J --> K[等待交易确认]
			      K --> L[显示结果]
			  ```
	- ## 并发与异步处理
		- **事件循环**: 基于 Node.js 单线程事件循环
		- **RPC 调用**: 异步处理区块链网络请求
		- **用户交互**: 同步模式确保操作安全性
		- **错误处理**: 统一异常捕获和用户提示

- # 4. 物理视图 (Physical View)
  collapsed:: true
	- ## 部署架构
		- ### 本地环境部署
		  collapsed:: true
			- ```
			  用户设备 (本地环境)
			  ├── Node.js 运行时 (≥18.0.0)
			  ├── ETH CLI 钱包应用
			  ├── 本地钱包文件 (wallet.json)
			  └── 环境配置 (.env)
			  ```
		- ### 网络连接架构
		  collapsed:: true
			- ```mermaid
			  graph TD
			      A[ETH CLI 钱包] -->|HTTPS/WSS| B[Base 网络 RPC 节点]
			      B --> C[Base 区块链网络]
			      C --> D[以太坊生态系统]
			  ```
	- ## RPC 节点配置
		- ### 支持的提供商
		  collapsed:: true
			- **Base 官方**: `https://mainnet.base.org`
			- **Alchemy**: `https://base-mainnet.g.alchemy.com/v2/{API_KEY}`
			- **Infura**: `https://base-mainnet.infura.io/v3/{PROJECT_ID}`
			- **LlamaRPC**: `https://base.llamarpc.com`
	- ## 安全架构
		- ### 数据安全
		  collapsed:: true
			- **私钥存储**: 仅本地存储，不上传网络
			- **文件权限**: 钱包文件系统权限保护
			- **环境隔离**: 支持多环境配置
		- ### 通信安全
		  collapsed:: true
			- **HTTPS 加密**: 所有 RPC 通信使用 HTTPS
			- **无中间人**: 直连 RPC 节点，无代理服务器
			- **本地签名**: 交易本地签名，私钥不离开设备

- # 项目特性总结
  collapsed:: true
	- ## 功能特性
		- 🔑 **钱包管理**: 生成、导入、本地存储
		- 💰 **余额查询**: ETH 和 ERC20 代币支持
		- 💸 **智能转账**: EIP-1559 标准，Gas 优化
		- 🌐 **网络支持**: Base 主网专项优化
		- 🔒 **安全设计**: 私钥本地化，多重确认
	- ## 技术特性
		- **类型安全**: 完整 TypeScript 支持
		- **现代工具链**: Viem.js 替代传统 web3.js
		- **用户友好**: 交互式 CLI 界面
		- **可扩展性**: 模块化架构设计
		- **错误处理**: 完善的异常处理机制

- # 扩展路线图
  collapsed:: true
	- ## 短期目标 (Q1-Q2)
		- [ ] 支持更多 EVM 兼容网络
		- [ ] 添加批量转账功能
		- [ ] 实现交易历史查询
		- [ ] 增加助记词钱包支持
	- ## 长期愿景 (Q3-Q4)
		- [ ] 多签钱包集成
		- [ ] DeFi 协议交互
		- [ ] NFT 资产管理
		- [ ] 硬件钱包支持

- # 文档说明
  id:: 64f8b2c3-1234-5678-9abc-def012345678
	- 本文档基于 **4+1 视图模型**，全面展示了 ETH CLI 钱包项目的架构设计与实现细节
	- 采用 **Logseq** 格式编写，支持层级折叠和链接引用
	- 文档版本: `v1.0.0` | 更新时间: {{date}}
	- 维护者: [[项目团队]]