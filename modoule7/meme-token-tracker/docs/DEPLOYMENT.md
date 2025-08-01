# 🚀 部署指南

本文档提供了 Meme Token Tracker 在不同环境下的详细部署指南。

## 📋 目录

- [部署前准备](#部署前准备)
- [StreamingFast 平台部署](#streamingfast-平台部署)
- [Docker 部署](#docker-部署)
- [云服务器部署](#云服务器部署)
- [生产环境配置](#生产环境配置)
- [监控与运维](#监控与运维)
- [故障排除](#故障排除)

## 📦 部署前准备

### 1. 环境要求

| 组件 | 版本要求 | 安装方法 |
|------|----------|----------|
| Rust | 1.88+ | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` |
| Protocol Buffers | 3.0+ | `brew install protobuf` (macOS) / `apt install protobuf-compiler` (Ubuntu) |
| Substreams CLI | 1.0+ | `curl -sSf https://install.streamingfast.io/substreams \| bash` |
| Docker | 20.0+ | [Docker 官网](https://docs.docker.com/get-docker/) |

### 2. 依赖检查

```bash
# 检查所有依赖
./scripts/check_dependencies.sh

# 或手动检查
rustc --version    # rust 1.88.0
protoc --version   # libprotoc 29.3
substreams version # substreams version 1.16.1
docker --version   # Docker version 20.10.0
```

### 3. 获取 API 凭证

1. 访问 [StreamingFast Dashboard](https://app.streamingfast.io/)
2. 注册/登录账户
3. 创建新的 API Key
4. 记录 API Token (格式: `sf_api_key_xxxxxxxx`)

## 🌟 StreamingFast 平台部署

### 方法 1: 直接部署 (推荐)

```bash
# 1. 构建项目
cargo build --release --target wasm32-unknown-unknown

# 2. 验证构建
ls -la target/wasm32-unknown-unknown/release/substreams.wasm

# 3. 打包项目
substreams pack substreams.yaml

# 4. 推送到 StreamingFast
substreams push meme-token-tracker-v0.1.0.spkg

# 5. 验证部署
substreams info meme-token-tracker
```

### 方法 2: CI/CD 自动部署

创建 `.github/workflows/deploy.yml`:

```yaml
name: Deploy to StreamingFast

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Rust
        uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
          target: wasm32-unknown-unknown
      
      - name: Install Substreams CLI
        run: |
          curl -sSf https://install.streamingfast.io/substreams | bash
          echo "$HOME/.local/bin" >> $GITHUB_PATH
      
      - name: Build project
        run: cargo build --release --target wasm32-unknown-unknown
      
      - name: Pack and deploy
        env:
          SUBSTREAMS_API_TOKEN: ${{ secrets.SUBSTREAMS_API_TOKEN }}
        run: |
          substreams pack substreams.yaml
          substreams push meme-token-tracker-${{ github.ref_name }}.spkg
```

### 部署配置

```yaml
# substreams.prod.yaml - 生产环境配置
specVersion: v0.1.0
package:
  name: "meme-token-tracker-prod"
  version: v1.0.0
  url: "https://github.com/your-org/meme-token-tracker"

network: mainnet

modules:
  - name: map_token_transfers
    kind: map
    initialBlock: 17000000
    inputs:
      - source: sf.ethereum.type.v2.Block
    output:
      type: proto:meme.TokenTransfers

  - name: map_token_rankings
    kind: map
    initialBlock: 17000000
    inputs:
      - map: map_token_transfers
    output:
      type: proto:meme.TokenRankings

params:
  endpoint: "eth.streamingfast.io:443"
  timeout: "300s"
  retry_count: 5
  buffer_size: 1000
```

## 🐳 Docker 部署

### 1. 创建 Dockerfile

```dockerfile
# Multi-stage build for optimized image
FROM rust:1.88-slim as builder

# Install dependencies
RUN apt-get update && apt-get install -y \
    protobuf-compiler \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Add WebAssembly target
RUN rustup target add wasm32-unknown-unknown

# Set working directory
WORKDIR /app

# Copy source code
COPY . .

# Build the project
RUN cargo build --release --target wasm32-unknown-unknown

# Runtime stage
FROM debian:bullseye-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Substreams CLI
RUN curl -sSf https://install.streamingfast.io/substreams | bash
ENV PATH="/root/.local/bin:$PATH"

# Set working directory
WORKDIR /app

# Copy built artifacts
COPY --from=builder /app/target/wasm32-unknown-unknown/release/substreams.wasm ./target/wasm32-unknown-unknown/release/
COPY --from=builder /app/substreams.yaml .
COPY --from=builder /app/proto ./proto/

# Copy deployment scripts
COPY scripts/docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose ports (if needed for monitoring)
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
CMD ["run"]
```

### 2. 创建 docker-compose.yml

```yaml
version: '3.8'

services:
  meme-token-tracker:
    build:
      context: .
      dockerfile: Dockerfile
    environment:
      - SUBSTREAMS_API_TOKEN=${SUBSTREAMS_API_TOKEN}
      - SUBSTREAMS_ENDPOINT=eth.streamingfast.io:443
      - START_BLOCK=17000000
      - RUST_LOG=info
    volumes:
      - ./logs:/app/logs
      - ./data:/app/data
    restart: unless-stopped
    networks:
      - meme-tracker-net
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "3"

  # Optional: Prometheus monitoring
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
    networks:
      - meme-tracker-net

  # Optional: Grafana dashboard
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-storage:/var/lib/grafana
      - ./monitoring/grafana/dashboards:/etc/grafana/provisioning/dashboards
    networks:
      - meme-tracker-net

networks:
  meme-tracker-net:
    driver: bridge

volumes:
  grafana-storage:
```

### 3. 部署脚本

```bash
#!/bin/bash
# scripts/docker-entrypoint.sh

set -e

# Function to wait for healthy connection
wait_for_endpoint() {
    echo "Waiting for StreamingFast endpoint..."
    timeout 60 bash -c 'until curl -s $SUBSTREAMS_ENDPOINT > /dev/null; do sleep 2; done'
    echo "Endpoint is reachable!"
}

# Function to start health check server
start_health_server() {
    # Simple health check server
    while true; do
        echo -e "HTTP/1.1 200 OK\n\n$(date): Healthy" | nc -l -p 8080 -q 1
    done &
}

case "$1" in
    "run")
        wait_for_endpoint
        start_health_server
        
        echo "Starting Meme Token Tracker..."
        exec substreams run \
            -e ${SUBSTREAMS_ENDPOINT} \
            substreams.yaml \
            map_token_rankings \
            --start-block ${START_BLOCK:-17000000} \
            --production-mode
        ;;
    "test")
        echo "Running tests..."
        exec substreams run \
            -e ${SUBSTREAMS_ENDPOINT} \
            substreams.yaml \
            map_token_rankings \
            --start-block 19000000 \
            --stop-block 19000100
        ;;
    "pack")
        echo "Packing Substreams..."
        exec substreams pack substreams.yaml
        ;;
    *)
        echo "Usage: $0 {run|test|pack}"
        exit 1
        ;;
esac
```

### 4. Docker 部署命令

```bash
# 构建镜像
docker build -t meme-token-tracker:latest .

# 运行容器
docker run -d \
  --name meme-tracker \
  -e SUBSTREAMS_API_TOKEN=your_token_here \
  -e START_BLOCK=17000000 \
  -v $(pwd)/logs:/app/logs \
  --restart unless-stopped \
  meme-token-tracker:latest

# 使用 docker-compose (推荐)
docker-compose up -d

# 查看日志
docker-compose logs -f meme-token-tracker

# 停止服务
docker-compose down
```

## ☁️ 云服务器部署

### AWS EC2 部署

#### 1. 创建 EC2 实例

```bash
# 使用 AWS CLI 创建实例
aws ec2 run-instances \
  --image-id ami-0c02fb55956c7d316 \
  --instance-type t3.medium \
  --key-name your-key-pair \
  --security-group-ids sg-your-security-group \
  --subnet-id subnet-your-subnet \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=meme-token-tracker}]'
```

#### 2. 配置服务器

```bash
# 连接到服务器
ssh -i your-key.pem ec2-user@your-ec2-ip

# 安装依赖
sudo yum update -y
sudo yum install -y docker git

# 启动 Docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# 安装 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

#### 3. 部署应用

```bash
# 克隆项目
git clone your-repo-url
cd meme-token-tracker

# 设置环境变量
echo "SUBSTREAMS_API_TOKEN=your_token" > .env

# 启动服务
docker-compose up -d

# 配置自动启动
sudo systemctl enable docker
```

### Google Cloud Platform 部署

```bash
# 使用 Cloud Run 部署
gcloud run deploy meme-token-tracker \
  --image gcr.io/your-project/meme-token-tracker \
  --platform managed \
  --region us-central1 \
  --set-env-vars SUBSTREAMS_API_TOKEN=your_token \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 1 \
  --max-instances 10
```

### DigitalOcean Droplet 部署

```bash
# 创建 Droplet
doctl compute droplet create meme-tracker \
  --region nyc3 \
  --image ubuntu-22-04-x64 \
  --size s-2vcpu-2gb \
  --ssh-keys your-ssh-key-id

# 配置和部署同 AWS EC2 步骤
```

## 🔧 生产环境配置

### 1. 环境变量配置

```bash
# /etc/systemd/system/meme-token-tracker.env
SUBSTREAMS_API_TOKEN=your_production_token
SUBSTREAMS_ENDPOINT=eth.streamingfast.io:443
START_BLOCK=17000000
RUST_LOG=info
LOG_LEVEL=info
METRICS_PORT=9090
HEALTH_CHECK_PORT=8080
```

### 2. Systemd 服务配置

```ini
# /etc/systemd/system/meme-token-tracker.service
[Unit]
Description=Meme Token Tracker Substreams
After=network.target
Wants=network.target

[Service]
Type=simple
User=meme-tracker
Group=meme-tracker
WorkingDirectory=/opt/meme-token-tracker
EnvironmentFile=/etc/systemd/system/meme-token-tracker.env
ExecStart=/usr/local/bin/substreams run -e ${SUBSTREAMS_ENDPOINT} substreams.yaml map_token_rankings --start-block ${START_BLOCK}
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=meme-token-tracker

[Install]
WantedBy=multi-user.target
```

### 3. 日志配置

```bash
# 配置 rsyslog
echo 'if $programname == "meme-token-tracker" then /var/log/meme-token-tracker.log' >> /etc/rsyslog.d/50-meme-tracker.conf

# 配置 logrotate
cat > /etc/logrotate.d/meme-token-tracker << EOF
/var/log/meme-token-tracker.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    create 0644 meme-tracker meme-tracker
    postrotate
        systemctl reload rsyslog
    endscript
}
EOF
```

### 4. 反向代理配置 (Nginx)

```nginx
# /etc/nginx/sites-available/meme-token-tracker
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        return 301 https://$server_name$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    ssl_certificate /path/to/your/cert.pem;
    ssl_certificate_key /path/to/your/key.pem;
    
    location /health {
        proxy_pass http://localhost:8080/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    location /metrics {
        proxy_pass http://localhost:9090/metrics;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        # 限制访问
        allow 10.0.0.0/8;
        allow 192.168.0.0/16;
        deny all;
    }
}
```

## 📊 监控与运维

### 1. 健康检查

```bash
#!/bin/bash
# scripts/health_check.sh

HEALTH_ENDPOINT="http://localhost:8080/health"
TIMEOUT=10

if curl -f -s --max-time $TIMEOUT $HEALTH_ENDPOINT > /dev/null; then
    echo "✅ Service is healthy"
    exit 0
else
    echo "❌ Service is unhealthy"
    exit 1
fi
```

### 2. 监控指标

```yaml
# monitoring/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'meme-token-tracker'
    static_configs:
      - targets: ['localhost:9090']
    scrape_interval: 5s
    metrics_path: /metrics
```

### 3. 告警配置

```yaml
# monitoring/alertmanager.yml
groups:
  - name: meme-token-tracker
    rules:
      - alert: ServiceDown
        expr: up{job="meme-token-tracker"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Meme Token Tracker service is down"
          
      - alert: HighMemoryUsage
        expr: process_resident_memory_bytes > 500000000
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage detected"
```

### 4. 自动备份

```bash
#!/bin/bash
# scripts/backup.sh

BACKUP_DIR="/opt/backups/meme-token-tracker"
DATE=$(date +%Y%m%d_%H%M%S)

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份配置文件
tar -czf $BACKUP_DIR/config_$DATE.tar.gz \
  substreams.yaml \
  docker-compose.yml \
  .env

# 备份日志 (最近7天)
find /var/log -name "*meme-token-tracker*" -mtime -7 -exec cp {} $BACKUP_DIR/ \;

# 清理旧备份 (保留30天)
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete

echo "Backup completed: $BACKUP_DIR/config_$DATE.tar.gz"
```

## 🚨 故障排除

### 常见部署问题

#### 1. WASM 构建失败
```bash
# 解决方案
rustup target add wasm32-unknown-unknown
cargo clean
cargo build --release --target wasm32-unknown-unknown
```

#### 2. Docker 容器启动失败
```bash
# 检查日志
docker logs meme-token-tracker

# 检查环境变量
docker exec meme-token-tracker printenv | grep SUBSTREAMS
```

#### 3. StreamingFast 连接问题
```bash
# 测试连接
curl -v https://eth.streamingfast.io:443

# 检查 API Token
substreams auth
```

#### 4. 内存不足
```bash
# 调整 Docker 内存限制
docker run --memory=2g meme-token-tracker

# 监控内存使用
docker stats meme-token-tracker
```

### 性能优化

```bash
# 调整区块范围
export START_BLOCK=18000000  # 较新的区块

# 增加缓冲区
export BUFFER_SIZE=2000

# 调整并发数
export PARALLEL_JOBS=2
```

## 📚 部署检查清单

### 部署前检查
- [ ] 所有依赖已安装
- [ ] API Token 已获取并配置
- [ ] 代码已构建并测试通过
- [ ] 配置文件已审查
- [ ] 网络连接正常

### 部署时检查
- [ ] WASM 文件生成成功
- [ ] 容器/服务启动正常
- [ ] 健康检查通过
- [ ] 日志输出正常
- [ ] 监控指标可见

### 部署后检查
- [ ] 数据处理正常
- [ ] 性能指标达标
- [ ] 告警配置生效
- [ ] 备份策略执行
- [ ] 文档更新完成

---

**🎯 部署成功后，您的 Meme Token Tracker 将实时处理以太坊数据，为您提供最新的 meme token 活跃度分析！**