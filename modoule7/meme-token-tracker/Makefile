# Meme Token Tracker - Makefile
# 简化常用的构建、测试和部署操作

.PHONY: help install build test clean pack deploy run docs lint fmt check-deps

SHELL := /bin/bash

# 默认目标
help: ## 显示帮助信息
	@echo "🚀 Meme Token Tracker - 可用命令:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "📝 环境变量:"
	@echo "  SUBSTREAMS_API_TOKEN - StreamingFast API Token (必需)"
	@echo "  START_BLOCK          - 起始区块号 (默认: 17000000)"
	@echo "  STOP_BLOCK           - 结束区块号 (可选)"
	@echo ""

# 安装依赖
install: ## 安装项目依赖
	@echo "📦 安装项目依赖..."
	source ~/.cargo/env && rustup target add wasm32-unknown-unknown
	@if ! command -v substreams >/dev/null 2>&1; then \
		echo "⚠️  Substreams CLI 未安装，请运行:"; \
		echo "curl -sSf https://install.streamingfast.io/substreams | bash"; \
	else \
		echo "✅ Substreams CLI 已安装: $$(substreams version)"; \
	fi

# 检查依赖
check-deps: ## 检查所有依赖是否已安装
	@echo "🔍 检查依赖..."
	@source ~/.cargo/env && echo "Rust: $$(rustc --version)"
	@source ~/.cargo/env && echo "Cargo: $$(cargo --version)"
	@if source ~/.cargo/env && rustup target list --installed | grep -q wasm32-unknown-unknown; then \
		echo "✅ WebAssembly 目标已安装"; \
	else \
		echo "❌ WebAssembly 目标未安装，运行 'make install'"; \
	fi
	@if command -v substreams >/dev/null 2>&1; then \
		echo "✅ Substreams CLI: $$(substreams version)"; \
	else \
		echo "❌ Substreams CLI 未安装"; \
	fi

# 构建项目
build: ## 构建 Substreams WebAssembly 模块
	@echo "🔨 构建项目..."
	source ~/.cargo/env && cargo build --release --target wasm32-unknown-unknown
	@echo "✅ 构建完成"
	@ls -lah target/wasm32-unknown-unknown/release/substreams.wasm

# 快速构建 (开发模式)
build-dev: ## 快速构建 (开发模式)
	@echo "🔨 快速构建..."
	source ~/.cargo/env && cargo build --target wasm32-unknown-unknown
	@ls -lah target/wasm32-unknown-unknown/debug/substreams.wasm

# 运行测试
test: ## 运行所有测试
	@echo "🧪 运行测试套件..."
	source ~/.cargo/env && cargo test
	@echo "✅ 所有测试通过"

# 性能测试
test-perf: ## 运行性能测试
	@echo "🧪 运行性能测试..."
	source ~/.cargo/env && cargo test test_large_dataset_performance -- --nocapture

# 代码格式化
fmt: ## 格式化代码
	@echo "🎨 格式化代码..."
	source ~/.cargo/env && cargo fmt
	@echo "✅ 代码格式化完成"

# 代码检查
lint: ## 代码质量检查
	@echo "🔍 代码质量检查..."
	source ~/.cargo/env && cargo clippy -- -D warnings
	@echo "✅ 代码检查通过"

# 清理构建产物
clean: ## 清理构建产物
	@echo "🧹 清理构建产物..."
	source ~/.cargo/env && cargo clean
	rm -f *.spkg
	@echo "✅ 清理完成"

# 验证配置
validate: ## 验证 Substreams 配置
	@echo "✅ 验证配置文件..."
	export PATH="$$HOME/.local/bin:$$PATH" && substreams validate substreams.yaml
	@echo "✅ 配置文件有效"

# 打包项目
pack: build ## 打包 Substreams 项目
	@echo "📦 打包项目..."
	export PATH="$$HOME/.local/bin:$$PATH" && substreams pack substreams.yaml
	@echo "✅ 打包完成"
	@ls -lah *.spkg

# 部署到 StreamingFast
deploy: ## 部署到 StreamingFast 平台
	@echo "🚀 开始部署..."
	@if [ -z "$(SUBSTREAMS_API_TOKEN)" ]; then \
		echo "❌ 错误: SUBSTREAMS_API_TOKEN 环境变量未设置"; \
		echo "请设置: export SUBSTREAMS_API_TOKEN=your_token"; \
		exit 1; \
	fi
	./deploy.sh
	@echo "✅ 部署完成"

# 运行 Substreams (本地测试)
run: build ## 运行 Substreams (最近100个区块)
	@echo "🔄 运行 Substreams..."
	@if [ -f .env ]; then source .env; fi && \
	if [ -z "$$SUBSTREAMS_API_TOKEN" ]; then \
		echo "❌ 错误: SUBSTREAMS_API_TOKEN 环境变量未设置"; \
		echo "获取 Token: https://app.streamingfast.io/"; \
		echo "设置: export SUBSTREAMS_API_TOKEN=your_token"; \
		exit 1; \
	fi && \
	export http_proxy=http://127.0.0.1:1087 && \
	export https_proxy=http://127.0.0.1:1087 && \
	export PATH="$$HOME/.local/bin:$$PATH" && \
	substreams run -H "x-api-key: server_18beb5bedfedd25f848665fe73d5d155" \
		-e mainnet.eth.streamingfast.io:443 \
		substreams.yaml \
		map_token_rankings \
		--start-block $${START_BLOCK:-17000000} \
		--stop-block +100

# 运行实时流式数据
run-live: build ## 运行实时流式数据
	@echo "🔄 启动实时数据流..."
	@if [ -f .env ]; then source .env; fi && \
	export http_proxy=http://127.0.0.1:1087 && \
	export https_proxy=http://127.0.0.1:1087 && \
	export PATH="$$HOME/.local/bin:$$PATH" && \
	substreams run -e eth.streamingfast.io:443 \
		substreams.yaml \
		map_token_rankings \
		--start-block -100

# 运行测试数据
run-test: build ## 运行测试数据 (小范围)
	@echo "🔄 运行测试数据..."
	@if [ -f .env ]; then source .env; fi && \
	export http_proxy=http://127.0.0.1:1087 && \
	export https_proxy=http://127.0.0.1:1087 && \
	export PATH="$$HOME/.local/bin:$$PATH" && \
	substreams run -H "x-api-key: server_18beb5bedfedd25f848665fe73d5d155" \
		-e mainnet.eth.streamingfast.io:443 \
		substreams.yaml \
		map_token_rankings \
		--start-block 19000000 \
		--stop-block 19000020

# 运行更大范围测试
run-extended: build ## 运行扩展测试 (50个区块)
	@echo "🔄 运行扩展测试..."
	@if [ -f .env ]; then source .env; fi && \
	export http_proxy=http://127.0.0.1:1087 && \
	export https_proxy=http://127.0.0.1:1087 && \
	export PATH="$$HOME/.local/bin:$$PATH" && \
	substreams run -H "x-api-key: server_18beb5bedfedd25f848665fe73d5d155" \
		-e mainnet.eth.streamingfast.io:443 \
		substreams.yaml \
		map_token_rankings \
		--start-block 19000000 \
		--stop-block 19000050

# 运行主网测试脚本
run-mainnet-test: build ## 运行主网配置测试
	@echo "🔄 运行主网测试..."
	./run_mainnet_test.sh

# 开发环境设置
dev-setup: install ## 设置开发环境
	@echo "🛠️  设置开发环境..."
	@if [ ! -f .env.example ]; then \
		echo "# Meme Token Tracker 环境变量" > .env.example; \
		echo "SUBSTREAMS_API_TOKEN=your_streamingfast_api_token" >> .env.example; \
		echo "START_BLOCK=17000000" >> .env.example; \
		echo "RUST_LOG=info" >> .env.example; \
	fi
	@echo "✅ 开发环境设置完成"
	@echo "💡 提示: 复制 .env.example 到 .env 并填入您的 API Token"

# 全面检查
check-all: check-deps fmt lint test validate ## 运行所有检查
	@echo "✅ 所有检查通过"

# 生产构建
production: clean build test pack ## 生产环境构建
	@echo "✅ 生产构建完成"

# 状态信息
status: ## 显示项目状态
	@echo "📊 项目状态:"
	@echo ""
	@echo "🔧 环境信息:"
	@source ~/.cargo/env && echo "  Rust: $$(rustc --version)"
	@if [ -f target/wasm32-unknown-unknown/release/substreams.wasm ]; then \
		echo "  WASM: ✅ ($$(ls -lah target/wasm32-unknown-unknown/release/substreams.wasm | awk '{print $$5}'))"; \
	else \
		echo "  WASM: ❌ (未构建)"; \
	fi
	@if ls *.spkg >/dev/null 2>&1; then \
		echo "  包文件: ✅ ($$(ls -t *.spkg | head -1))"; \
	else \
		echo "  包文件: ❌ (未打包)"; \
	fi
	@echo ""
	@echo "🎯 追踪的 Token:"
	@echo "  - SHIB: 0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce"
	@echo "  - PEPE: 0x6982508145454ce325ddbe47a25d4ec3d2311933"
	@echo "  - BAND: 0xba11d00c5f74255f56a5e366f4f77f5a186d7f55"
	@echo "  - APE:  0x4d224452801aced8b2f0aebe155379bb5d594381"
	@echo "  - FRAX: 0x853d955acef822db058eb8505911ed77f175b99e"
	@echo ""
	@if [ -n "$$SUBSTREAMS_API_TOKEN" ]; then \
		echo "🔑 API Token: ✅ 已设置"; \
	else \
		echo "🔑 API Token: ❌ 未设置"; \
	fi

# 兼容旧版本命令
install-target: install ## (已弃用) 使用 make install 代替
setup: install build ## (已弃用) 使用 make dev-setup 代替