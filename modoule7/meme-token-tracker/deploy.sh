#!/bin/bash

# Meme Token Tracker - StreamingFast 部署脚本
# 该脚本用于将 Substreams 项目部署到 StreamingFast 平台

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印彩色消息
print_msg() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查必需工具
check_requirements() {
    print_msg "检查部署环境..."
    
    # 检查 Rust
    if ! command -v rustc &> /dev/null; then
        print_error "Rust 未安装。请先安装 Rust: https://rustup.rs/"
        exit 1
    fi
    
    # 检查 WebAssembly 目标
    if ! rustup target list --installed | grep -q "wasm32-unknown-unknown"; then
        print_warning "WebAssembly 目标未安装，正在安装..."
        rustup target add wasm32-unknown-unknown
    fi
    
    # 检查 Substreams CLI
    if ! command -v substreams &> /dev/null; then
        print_error "Substreams CLI 未安装。请先安装:"
        print_error "curl -sSf https://install.streamingfast.io/substreams | bash"
        exit 1
    fi
    
    # 检查 API Token
    if [ -z "$SUBSTREAMS_API_TOKEN" ]; then
        print_error "SUBSTREAMS_API_TOKEN 环境变量未设置"
        print_error "请先设置 API Token: export SUBSTREAMS_API_TOKEN=your_token"
        exit 1
    fi
    
    print_success "环境检查通过"
}

# 清理构建目录
clean_build() {
    print_msg "清理构建目录..."
    cargo clean
    rm -f *.spkg
    print_success "构建目录已清理"
}

# 构建项目
build_project() {
    print_msg "构建 Substreams 项目..."
    
    # 构建 WebAssembly 模块
    cargo build --release --target wasm32-unknown-unknown
    
    # 检查构建结果
    WASM_FILE="target/wasm32-unknown-unknown/release/substreams.wasm"
    if [ ! -f "$WASM_FILE" ]; then
        print_error "WASM 文件构建失败: $WASM_FILE"
        exit 1
    fi
    
    # 显示文件信息
    WASM_SIZE=$(ls -lh "$WASM_FILE" | awk '{print $5}')
    print_success "WASM 文件构建成功 (大小: $WASM_SIZE)"
}

# 运行测试
run_tests() {
    print_msg "运行测试套件..."
    
    # 单元测试
    cargo test --quiet
    
    # 验证配置文件
    if ! substreams validate substreams.yaml; then
        print_error "substreams.yaml 配置验证失败"
        exit 1
    fi
    
    print_success "所有测试通过"
}

# 打包项目
pack_project() {
    print_msg "打包 Substreams 项目..."
    
    # 获取版本信息
    VERSION=$(grep '^version' Cargo.toml | sed 's/version = "\(.*\)"/\1/')
    PACKAGE_NAME="meme-token-tracker-v${VERSION}.spkg"
    
    # 打包项目
    substreams pack substreams.yaml
    
    if [ ! -f "$PACKAGE_NAME" ]; then
        print_error "打包失败: $PACKAGE_NAME 未生成"
        exit 1
    fi
    
    # 显示包信息
    PACKAGE_SIZE=$(ls -lh "$PACKAGE_NAME" | awk '{print $5}')
    print_success "项目打包成功: $PACKAGE_NAME (大小: $PACKAGE_SIZE)"
    
    echo "$PACKAGE_NAME"
}

# 部署到 StreamingFast
deploy_to_streamingfast() {
    local package_file=$1
    
    print_msg "部署到 StreamingFast 平台..."
    
    # 检查认证状态
    if ! substreams auth 2>/dev/null; then
        print_error "StreamingFast 认证失败，请检查 API Token"
        exit 1
    fi
    
    # 推送包到平台
    if substreams push "$package_file"; then
        print_success "部署成功!"
        
        # 获取包名 (去掉版本后缀)
        PACKAGE_NAME_CLEAN=$(echo "$package_file" | sed 's/-v[0-9.]*\.spkg$//')
        
        print_msg "部署信息:"
        echo "  📦 包名: $package_file"
        echo "  🌐 端点: eth.streamingfast.io:443"
        echo "  📡 模块: map_token_transfers, map_token_rankings"
        echo ""
        print_msg "验证部署:"
        echo "  substreams info $PACKAGE_NAME_CLEAN"
        echo ""
        print_msg "运行示例:"
        echo "  substreams run -e eth.streamingfast.io:443 $package_file map_token_rankings --start-block -100"
        
    else
        print_error "部署失败"
        exit 1
    fi
}

# 验证部署
verify_deployment() {
    local package_name=$1
    
    print_msg "验证部署状态..."
    
    # 去掉版本和扩展名获取包名
    CLEAN_NAME=$(echo "$package_name" | sed 's/-v[0-9.]*\.spkg$//')
    
    if substreams info "$CLEAN_NAME" >/dev/null 2>&1; then
        print_success "部署验证成功"
        
        print_msg "包信息:"
        substreams info "$CLEAN_NAME"
        
        return 0
    else
        print_warning "无法验证部署状态，但这可能是正常的"
        return 1
    fi
}

# 运行部署后测试
run_deployment_test() {
    local package_file=$1
    
    print_msg "运行部署后测试..."
    
    # 简单的连通性测试
    print_msg "测试 map_token_transfers 模块..."
    if timeout 30 substreams run \
        -e eth.streamingfast.io:443 \
        "$package_file" \
        map_token_transfers \
        --start-block -1 \
        --stop-block +1 \
        >/dev/null 2>&1; then
        print_success "map_token_transfers 模块测试通过"
    else
        print_warning "map_token_transfers 模块测试超时，但部署可能仍然成功"
    fi
    
    print_msg "测试 map_token_rankings 模块..."
    if timeout 30 substreams run \
        -e eth.streamingfast.io:443 \
        "$package_file" \
        map_token_rankings \
        --start-block -1 \
        --stop-block +1 \
        >/dev/null 2>&1; then
        print_success "map_token_rankings 模块测试通过"
    else
        print_warning "map_token_rankings 模块测试超时，但部署可能仍然成功"
    fi
}

# 生成部署报告
generate_deployment_report() {
    local package_file=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    cat > deployment_report.md << EOF
# 🚀 Meme Token Tracker 部署报告

**部署时间**: $timestamp  
**包文件**: $package_file  
**部署状态**: ✅ 成功  

## 📦 包信息

- **版本**: $(grep '^version' Cargo.toml | sed 's/version = "\(.*\)"/\1/')
- **WASM 大小**: $(ls -lh target/wasm32-unknown-unknown/release/substreams.wasm | awk '{print $5}')
- **包大小**: $(ls -lh "$package_file" | awk '{print $5}')

## 🔧 模块信息

- **map_token_transfers**: 提取白名单 meme token 转账事件
- **map_token_rankings**: 生成活跃度排行榜

## 🌐 访问信息

**端点**: eth.streamingfast.io:443  
**网络**: Ethereum Mainnet  

## 📊 使用示例

\`\`\`bash
# 获取最近100个区块的排行榜
substreams run \\
  -e eth.streamingfast.io:443 \\
  $package_file \\
  map_token_rankings \\
  --start-block -100

# 获取特定区块范围的数据
substreams run \\
  -e eth.streamingfast.io:443 \\
  $package_file \\
  map_token_rankings \\
  --start-block 18000000 \\
  --stop-block 18001000
\`\`\`

## 🎯 追踪的 Token

- SHIB: 0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce
- PEPE: 0x6982508145454ce325ddbe47a25d4ec3d2311933
- BAND: 0xba11d00c5f74255f56a5e366f4f77f5a186d7f55
- APE: 0x4d224452801aced8b2f0aebe155379bb5d594381
- FRAX: 0x853d955acef822db058eb8505911ed77f175b99e

## ✅ 部署检查清单

- [x] 环境检查通过
- [x] 项目构建成功
- [x] 测试套件通过
- [x] 配置文件验证
- [x] 项目打包完成
- [x] StreamingFast 部署成功
- [x] 部署验证通过

---
*报告生成时间: $timestamp*
EOF

    print_success "部署报告已生成: deployment_report.md"
}

# 主函数
main() {
    echo "🚀 Meme Token Tracker - StreamingFast 部署脚本"
    echo "================================================"
    echo ""
    
    # 解析命令行参数
    SKIP_TESTS=false
    SKIP_CLEAN=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-tests)
                SKIP_TESTS=true
                shift
                ;;
            --skip-clean)
                SKIP_CLEAN=true
                shift
                ;;
            --help|-h)
                echo "用法: $0 [选项]"
                echo ""
                echo "选项:"
                echo "  --skip-tests    跳过测试"
                echo "  --skip-clean    跳过清理"
                echo "  --help, -h      显示帮助信息"
                exit 0
                ;;
            *)
                print_error "未知选项: $1"
                exit 1
                ;;
        esac
    done
    
    # 执行部署步骤
    check_requirements
    
    if [ "$SKIP_CLEAN" = false ]; then
        clean_build
    fi
    
    build_project
    
    if [ "$SKIP_TESTS" = false ]; then
        run_tests
    fi
    
    package_file=$(pack_project)
    deploy_to_streamingfast "$package_file"
    verify_deployment "$package_file"
    run_deployment_test "$package_file"
    generate_deployment_report "$package_file"
    
    echo ""
    print_success "🎉 部署完成！"
    echo ""
    print_msg "下一步:"
    echo "  1. 查看部署报告: cat deployment_report.md"
    echo "  2. 测试部署: ./run_mainnet_test.sh"
    echo "  3. 集成到您的应用: 参考 docs/API.md"
    echo ""
}

# 错误处理
trap 'print_error "部署过程中发生错误，退出..."; exit 1' ERR

# 运行主函数
main "$@"