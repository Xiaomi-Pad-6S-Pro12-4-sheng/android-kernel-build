# 在参数解析部分添加
    --enable-docker)
        ENABLE_DOCKER=true
        shift
        ;;

# 在构建逻辑部分添加 Docker 支持
# 启用 Docker 支持（如果请求）
if [ "$ENABLE_DOCKER" = true ]; then
    echo "🐳 启用 Docker 容器支持..."
    bash scripts/enable-docker-support.sh
    bash scripts/device-docker-config.sh $DEVICE
    
    # 重新生成配置依赖
    make O=$OUT_DIR_DEVICE olddefconfig
fi
