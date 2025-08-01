#!/bin/bash

# Setup Proxy Configuration Script
# 设置代理配置脚本

echo "🌐 设置代理配置..."

# 1. 备份原配置文件
if [ -f "/opt/homebrew/etc/proxychains.conf" ]; then
    echo "📄 备份原配置文件..."
    sudo cp /opt/homebrew/etc/proxychains.conf /opt/homebrew/etc/proxychains.conf.backup
    echo "✅ 备份完成: /opt/homebrew/etc/proxychains.conf.backup"
fi

# 2. 应用新配置
echo "📝 应用新的代理配置..."
sudo cp ./proxychains.conf /opt/homebrew/etc/proxychains.conf
echo "✅ 配置已更新"

# 3. 设置环境变量
echo "🔧 设置环境变量..."
cat >> ~/.zshrc << 'EOF'

# Proxy Configuration for Terminal
# 终端代理配置
export http_proxy=http://127.0.0.1:1087
export https_proxy=http://127.0.0.1:1087
export ALL_PROXY=socks5://127.0.0.1:1080

# Proxychains alias
alias pc='proxychains4'
EOF

# 4. 应用环境变量到当前会话
export http_proxy=http://127.0.0.1:1087
export https_proxy=http://127.0.0.1:1087
export ALL_PROXY=socks5://127.0.0.1:1080

echo "✅ 代理配置完成!"
echo ""
echo "🚀 使用方法:"
echo "  1. 直接使用环境变量代理:"
echo "     curl https://github.com"
echo ""
echo "  2. 使用 proxychains:"
echo "     proxychains4 curl https://github.com"
echo "     # 或者使用别名:"
echo "     pc curl https://github.com"
echo ""
echo "  3. 测试代理连接:"
echo "     proxychains4 curl -I https://github.com"
echo ""
echo "💡 重新加载shell配置: source ~/.zshrc"