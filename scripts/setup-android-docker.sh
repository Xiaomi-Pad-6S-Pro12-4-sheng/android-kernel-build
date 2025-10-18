#!/bin/bash
# Android 设备上的 Docker 环境设置

set -e

echo "📱 设置 Android Docker 环境..."

# 检查 root 权限
if [ "$(id -u)" != "0" ]; then
    echo "❌ 需要 root 权限运行此脚本"
    exit 1
fi

# 创建必要的目录
mkdir -p /data/docker
mkdir -p /data/docker/volumes
mkdir -p /data/docker/config

# 检查内核是否支持容器
echo "🔍 检查内核容器支持..."

check_kernel_feature() {
    local feature=$1
    if grep -q "$feature" /proc/config.gz 2>/dev/null || grep -q "$feature=y" /proc/config 2>/dev/null; then
        echo "✅ $feature: 已启用"
        return 0
    else
        echo "❌ $feature: 未启用"
        return 1
    fi
}

echo "检查命名空间支持:"
check_kernel_feature CONFIG_NAMESPACES
check_kernel_feature CONFIG_USER_NS
check_kernel_feature CONFIG_PID_NS
check_kernel_feature CONFIG_NET_NS

echo "检查控制组支持:"
check_kernel_feature CONFIG_CGROUPS
check_kernel_feature CONFIG_MEMCG
check_kernel_feature CONFIG_CGROUP_SCHED

echo "检查存储驱动支持:"
check_kernel_feature CONFIG_OVERLAY_FS
check_kernel_feature CONFIG_BLK_DEV_DM

# 安装 Docker (如果尚未安装)
if ! command -v docker &> /dev/null; then
    echo "📥 安装 Docker..."
    
    # 下载静态 Docker 二进制文件
    DOCKER_VERSION="20.10.7"
    cd /tmp
    wget -q https://download.docker.com/linux/static/stable/aarch64/docker-${DOCKER_VERSION}.tgz
    tar xzf docker-${DOCKER_VERSION}.tgz
    cp docker/* /usr/bin/
    
    # 创建 Docker 服务脚本
    cat > /etc/init.d/docker << 'EOF'
#!/system/bin/sh
# Docker 启动脚本

case "$1" in
    start)
        echo "启动 Docker 守护进程..."
        /usr/bin/dockerd --data-root /data/docker &
        ;;
    stop)
        echo "停止 Docker 守护进程..."
        pkill dockerd
        ;;
    *)
        echo "使用方法: $0 {start|stop}"
        exit 1
        ;;
esac
EOF

    chmod +x /etc/init.d/docker
fi

# 配置 Docker 守护进程
cat > /data/docker/config/daemon.json << 'EOF'
{
  "data-root": "/data/docker",
  "storage-driver": "overlay2",
  "iptables": false,
  "ip-forward": false,
  "ip-masq": false,
  "userland-proxy": false,
  "debug": true,
  "log-level": "info",
  "cgroup-parent": "docker",
  "exec-opts": [
    "native.cgroupdriver=cgroupfs"
  ]
}
EOF

# 创建 Docker 启动脚本
cat > /usr/local/bin/start-docker << 'EOF'
#!/system/bin/sh
# 启动 Docker

echo "🐳 启动 Docker..."

# 挂载 cgroup
mkdir -p /sys/fs/cgroup
mount -t tmpfs cgroup /sys/fs/cgroup

# 挂载各个 cgroup 子系统
for subsystem in cpu cpuacct cpuset memory blkio devices freezer net_cls perf_event net_prio pids rdma; do
    mkdir -p /sys/fs/cgroup/$subsystem
    mount -t cgroup -o $subsystem cgroup /sys/fs/cgroup/$subsystem 2>/dev/null || true
done

# 启动 Docker 守护进程
/usr/bin/dockerd --config-file /data/docker/config/daemon.json &

# 等待 Docker 启动
sleep 5

# 测试 Docker
if docker version &>/dev/null; then
    echo "✅ Docker 启动成功!"
    echo "运行 'docker ps' 测试"
else
    echo "❌ Docker 启动失败"
fi
EOF

chmod +x /usr/local/bin/start-docker

# 创建 Docker 使用示例脚本
cat > /data/docker/docker-examples.sh << 'EOF'
#!/system/bin/sh
# Docker 使用示例

echo "🐳 Docker 使用示例"

# 1. 运行 Alpine Linux 容器
echo "1. 运行 Alpine Linux 测试容器:"
docker run --rm alpine echo "Hello from Docker on Android!"

# 2. 运行 BusyBox 容器
echo "2. 运行 BusyBox 容器:"
docker run --rm -it busybox sh -c "echo 'BusyBox 容器运行正常'"

# 3. 运行 Nginx 容器 (如果网络正常)
echo "3. 运行 Nginx 测试:"
docker run --rm -d -p 8080:80 --name nginx-test nginx:alpine
sleep 2
curl -s http://localhost:8080 | head -n 5
docker stop nginx-test

echo "✅ Docker 示例完成"
EOF

chmod +x /data/docker/docker-examples.sh

echo ""
echo "✅ Android Docker 环境设置完成!"
echo ""
echo "📋 使用方法:"
echo "1. 启动 Docker: start-docker"
echo "2. 测试 Docker: docker ps"
echo "3. 运行示例: /data/docker/docker-examples.sh"
echo ""
echo "⚠️  注意:"
echo "- 需要内核支持容器功能"
echo "- 可能需要手动挂载 cgroup 文件系统"
echo "- 某些网络功能可能受限"
