#!/bin/bash
# 高通平台专用依赖下载脚本 - 修正版

set -e

echo "📱 开始下载高通平台依赖..."

QCOM_DIR="$GITHUB_WORKSPACE/qcom-dependencies"
mkdir -p $QCOM_DIR
cd $QCOM_DIR

# 创建设备特定的依赖目录
DEVICES=("mondrian" "vermeer" "sheng")  # 修正：使用正确的设备代号
for device in "${DEVICES[@]}"; do
    mkdir -p $device/vendor
    mkdir -p $device/firmware
    mkdir -p $device/dts
done

# 下载骁龙8 Gen 2相关工具
echo "📥 下载骁龙8 Gen 2专用工具..."

# 1. 下载SM8550/SM8475设备树示例
if [ ! -d "qcom-dts-examples" ]; then
    git clone --depth=1 https://github.com/LineageOS/android_kernel_qcom_msm-4.19.git qcom-dts-examples
    # 提取设备树相关文件
    cp -r qcom-dts-examples/arch/arm64/boot/dts/vendor/ $QCOM_DIR/dts-common/
fi

# 2. 下载骁龙调试工具
if [ ! -d "qcom-debug-tools" ]; then
    git clone --depth=1 https://github.com/andersson/kernel-tools.git qcom-debug-tools
    cd qcom-debug-tools
    make -j$(nproc)
    cd ..
fi

# 3. 下载Adreno GPU相关工具
if [ ! -d "adreno-tools" ]; then
    git clone --depth=1 https://github.com/freedreno/envytools.git adreno-tools
    cd adreno-tools
    make -j$(nproc)
    cd ..
fi

# 创建设备特定的环境配置
cat > environment-setup.sh << 'EOF'
#!/bin/bash
# 高通构建环境设置 - 修正版

export QCOM_BUILD=true
export QCOM_DEVICE=$1

# 设置设备特定的环境变量
case "$QCOM_DEVICE" in
    "mondrian")  # 红米 K60 (SM8475 - 骁龙8+ Gen 1)
        export QCOM_SOC=sm8475
        export QCOM_GPU=adreno730
        export QCOM_CHIPSET=taro
        export DEFCONFIG=vendor/sm8475_defconfig
        ;;
    "vermeer")   # 红米 K70 (SM8550 - 骁龙8 Gen 2)
        export QCOM_SOC=sm8550
        export QCOM_GPU=adreno740
        export QCOM_CHIPSET=kalama
        export DEFCONFIG=vendor/sm8550_defconfig
        ;;
    "sheng")     # 小米 Pad 6S Pro (SM8550 - 骁龙8 Gen 2)
        export QCOM_SOC=sm8550  
        export QCOM_GPU=adreno740
        export QCOM_CHIPSET=kalama
        export DEFCONFIG=vendor/sm8550_defconfig
        ;;
    *)
        echo "❌ 未知设备: $QCOM_DEVICE"
        exit 1
        ;;
esac

# 设置芯片特定的编译标志
case "$QCOM_SOC" in
    "sm8550")
        export CFLAGS="$CFLAGS -march=armv9-a+dotprod"
        ;;
    "sm8475")
        export CFLAGS="$CFLAGS -march=armv8.2-a+dotprod"
        ;;
esac

echo "✅ 高通环境设置完成: 设备=$QCOM_DEVICE, 芯片=$QCOM_SOC, GPU=$QCOM_GPU"
EOF

chmod +x environment-setup.sh

echo "✅ 高通依赖下载完成!"
