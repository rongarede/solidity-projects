#!/bin/bash

# Subgraph Studio 部署脚本
# 使用方法: ./scripts/deploy.sh YOUR_DEPLOY_KEY YOUR_SUBGRAPH_SLUG

if [ $# -ne 2 ]; then
    echo "使用方法: $0 <DEPLOY_KEY> <SUBGRAPH_SLUG>"
    echo "示例: $0 abcd1234... your-username/nft-marketplace-polygon"
    exit 1
fi

DEPLOY_KEY=$1
SUBGRAPH_SLUG=$2

echo "🚀 开始部署到 Subgraph Studio..."
echo "📋 Subgraph: $SUBGRAPH_SLUG"

# 认证
echo "🔑 认证 Graph CLI..."
graph auth --studio $DEPLOY_KEY

if [ $? -ne 0 ]; then
    echo "❌ 认证失败，请检查 deploy key"
    exit 1
fi

# 重新生成代码（确保最新）
echo "🔧 重新生成代码..."
graph codegen

if [ $? -ne 0 ]; then
    echo "❌ 代码生成失败"
    exit 1
fi

# 构建
echo "🏗️ 构建 subgraph..."
graph build

if [ $? -ne 0 ]; then
    echo "❌ 构建失败"
    exit 1
fi

# 部署
echo "📤 部署到 Studio..."
graph deploy --studio $SUBGRAPH_SLUG

if [ $? -eq 0 ]; then
    echo "✅ 部署成功！"
    echo "🌐 访问 https://thegraph.com/studio/subgraph/$SUBGRAPH_SLUG 查看详情"
else
    echo "❌ 部署失败"
    exit 1
fi