#!/bin/bash
# 统一内核构建脚本 - 修正版

set -e

# 显示用法说明
show_usage() {
    echo "使用方法: $0 [选项]"
    echo "选项:"
    echo "  -d, --device DEVICE    指定设备 (mondrian|vermeer|sheng)"  # 修正：使用正确的设备代号
    echo "  -t, --toolchain TOOLCHAIN 指定工具链 (clang|gcc)"
    echo "  -c, --clean            清洁构建"
    echo "  -j, --jobs NUM         并行作业数"
    echo "  -p, --apply-patches    应用优化补丁"
    echo "  -h, --help            显示此帮助信息"
    echo ""
    echo "支持的设备:"
    echo "  mondrian - 红米 K60 (骁龙8+ Gen 1)"      # 修正：设备对应关系
    echo "  vermeer  - 红米 K70 (骁龙8 Gen 2)"       # 修正：设备对应关系
    echo "  sheng    - 小米 Pad 6S Pro (骁龙8 Gen 2)" # 修正：设备对应关系
}

# 默认参数
DEVICE=""
TOOLCHAIN="clang"
CLEAN_BUILD=false
APPLY_PATCHES=true
JOBS=$(nproc)

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--device)
            DEVICE="$2"
            shift 2
            ;;
        -t|--toolchain)
            TOOLCHAIN="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        -j|--jobs)
            JOBS="$2"
            shift 2
            ;;
        -p|--apply-patches)
            APPLY_PATCHES=$2
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            show_usage
            exit 1
            ;;
    esac
done

# 验证设备参数
if [ -z "$DEVICE" ]; then
    echo "❌ 错误: 必须指定设备"
    show_usage
    exit 1
fi

case $DEVICE in
    "mondrian"|"vermeer"|"sheng")  # 修正：使用正确的设备代号
        ;;
    *)
        echo "❌ 错误: 不支持的设备 '$DEVICE'"
        show_usage
        exit 1
        ;;
esac

# 设置构建环境
source scripts/setup-environment.sh
source scripts/download-qcom-deps.sh

echo "🏗️  开始构建 $DEVICE 内核..."
echo "📋 构建配置:"
echo "  - 设备: $DEVICE"
echo "  - 工具链: $TOOLCHAIN"
echo "  - 并行作业: $JOBS"
echo "  - 清洁构建: $CLEAN_BUILD"
echo "  - 应用补丁: $APPLY_PATCHES"

# 设置高通设备环境
source $QCOM_DIR/environment-setup.sh $DEVICE

# 设置工具链
case $TOOLCHAIN in
    "clang")
        export CLANG_TRIPLE=aarch64-linux-gnu-
        export CROSS_COMPILE=$TOOLCHAIN_DIR/gcc-arm64/bin/aarch64-linux-gnu-
        export CROSS_COMPILE_ARM32=$TOOLCHAIN_DIR/gcc-arm/bin/arm-linux-gnueabi-
        export CC=$TOOLCHAIN_DIR/aosp-clang/bin/clang
        export LD_LIBRARY_PATH=$TOOLCHAIN_DIR/aosp-clang/lib64:$LD_LIBRARY_PATH
        ;;
    "gcc")
        export CROSS_COMPILE=$TOOLCHAIN_DIR/gcc-arm64/bin/aarch64-linux-gnu-
        export CROSS_COMPILE_ARM32=$TOOLCHAIN_DIR/gcc-arm/bin/arm-linux-gnueabi-
        export CC=${CROSS_COMPILE}gcc
        ;;
    *)
        echo "❌ 错误: 不支持的工具链 '$TOOLCHAIN'"
        exit 1
        ;;
esac

# 设置输出目录
export OUT_DIR_DEVICE=$OUT_DIR/$DEVICE
mkdir -p $OUT_DIR_DEVICE

# 清洁构建（如果请求）
if [ "$CLEAN_BUILD" = true ]; then
    echo "🧹 执行清洁构建..."
    make mrproper
    rm -rf $OUT_DIR_DEVICE
    mkdir -p $OUT_DIR_DEVICE
fi

# 应用平台优化补丁
if [ "$APPLY_PATCHES" = true ]; then
    echo "🔧 应用平台优化补丁..."
    case $QCOM_SOC in
        "sm8550")
            # 应用骁龙8 Gen 2优化补丁
            if [ -f "$QCOM_DIR/kernel-patches/sm8550-cpu-optimization.patch" ]; then
                patch -p1 < $QCOM_DIR/kernel-patches/sm8550-cpu-optimization.patch || true
            fi
            ;;
        "sm8475")
            # 应用骁龙8+ Gen 1优化补丁
            if [ -f "$QCOM_DIR/kernel-patches/sm8475-gpu-optimization.patch" ]; then
                patch -p1 < $QCOM_DIR/kernel-patches/sm8475-gpu-optimization.patch || true
            fi
            ;;
    esac
fi

# 设置内核配置
echo "⚙️  配置内核..."
if [ -n "$DEFCONFIG" ]; then
    make O=$OUT_DIR_DEVICE $DEFCONFIG
else
    make O=$OUT_DIR_DEVICE ${DEVICE}_defconfig
fi

# 针对不同设备进行特定配置
case $DEVICE in
    "sheng")
        # 平板设备特定配置
        echo "CONFIG_INPUT_TOUCHSCREEN=y" >> $OUT_DIR_DEVICE/.config
        echo "CONFIG_TABLET_SPECIFIC=y" >> $OUT_DIR_DEVICE/.config
        echo "CONFIG_LARGESCREEN_OPTIMIZATIONS=y" >> $OUT_DIR_DEVICE/.config
        ;;
    "mondrian"|"vermeer")
        # 手机设备特定配置
        echo "CONFIG_MOBILE_OPTIMIZATIONS=y" >> $OUT_DIR_DEVICE/.config
        echo "CONFIG_SMALLSCREEN_OPTIMIZATIONS=y" >> $OUT_DIR_DEVICE/.config
        ;;
esac

# 开始构建内核
echo "🔨 开始编译内核..."
make -j$JOBS O=$OUT_DIR_DEVICE \
    ARCH=$ARCH \
    CC="$CC" \
    CROSS_COMPILE=$CROSS_COMPILE \
    CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32

# 构建模块
echo "🔨 编译内核模块..."
make -j$JOBS O=$OUT_DIR_DEVICE \
    ARCH=$ARCH \
    CC="$CC" \
    CROSS_COMPILE=$CROSS_COMPILE \
    CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32 \
    modules

# 构建设备树
echo "🔨 编译设备树..."
make -j$JOBS O=$OUT_DIR_DEVICE \
    ARCH=$ARCH \
    CC="$CC" \
    CROSS_COMPILE=$CROSS_COMPILE \
    dtbs

# 验证构建产物
echo "🔍 验证构建产物..."
if [ ! -f "$OUT_DIR_DEVICE/arch/arm64/boot/Image.gz-dtb" ]; then
    echo "❌ 错误: 内核镜像未找到!"
    ls -la $OUT_DIR_DEVICE/arch/arm64/boot/
    exit 1
fi

echo "✅ 内核构建完成!"
