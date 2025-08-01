#!/bin/bash

# Meme Token Tracker - Local Test Script
# This script tests the Substreams modules locally

set -e

echo "🧪 Starting local Substreams test..."

# Build the project first
echo "📦 Building project..."
cargo build --release

# Check if the WASM file exists
if [ ! -f "./target/wasm32-unknown-unknown/release/substreams.wasm" ]; then
    echo "❌ WASM file not found. Build failed."
    exit 1
fi

echo "✅ Build successful. WASM file generated."

# Test parameters
START_BLOCK=18000000
STOP_BLOCK=18000010
ENDPOINT="eth.streamingfast.io:443"

echo "🔍 Testing map_token_transfers module..."
echo "Block range: $START_BLOCK to $STOP_BLOCK"

# Test map_token_transfers
substreams run \
    -e $ENDPOINT \
    substreams.yaml \
    map_token_transfers \
    --start-block $START_BLOCK \
    --stop-block $STOP_BLOCK \
    --production-mode || {
    echo "❌ map_token_transfers test failed"
    exit 1
}

echo "✅ map_token_transfers test passed"

echo "🔍 Testing map_token_rankings module..."

# Test map_token_rankings
substreams run \
    -e $ENDPOINT \
    substreams.yaml \
    map_token_rankings \
    --start-block $START_BLOCK \
    --stop-block $STOP_BLOCK \
    --production-mode || {
    echo "❌ map_token_rankings test failed"
    exit 1
}

echo "✅ map_token_rankings test passed"

echo "🎉 All local tests passed successfully!"
echo ""
echo "📊 Test Summary:"
echo "  - Build: ✅"
echo "  - WASM Generation: ✅"
echo "  - Token Transfers Module: ✅"
echo "  - Token Rankings Module: ✅"
echo ""
echo "🚀 Ready for deployment testing!"