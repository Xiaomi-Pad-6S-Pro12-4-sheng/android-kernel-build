# Xiaomi Pad 6S Pro Kernel Build

此项目专为**Xiaomi Pad 6S Pro** (设备代号: `sheng`) 设计，提供内核构建环境和工具。本项目支持构建基于 **Linux 5.15.x** 版本的内核，适用于搭载骁龙 8 Gen 2 处理器的设备。

## 设备信息

- **设备名称**: Xiaomi Pad 6S Pro
- **设备代号**: `sheng`
- **处理器**: 骁龙 8 Gen 2 (SM8550)
- **内核版本**: Linux 5.15.x
- **架构**: arm64/aarch64

## 功能特性

✅ **官方内核支持**: 基于小米官方内核源码构建
✅ **Docker容器支持**: 内核可启用Docker所需的全部功能
✅ **优化配置**: 针对平板设备进行的性能和功耗优化
✅ **自动化构建**: 支持GitHub Actions在线构建
✅ **完整工具链**: 包含所有必要的编译工具

## 快速开始

### 本地构建

1. **克隆仓库**
   ```bash
   git clone https://github.com/Xiaomi-Pad-6S-Pro12-4-sheng/android-kernel-build.git
   cd android-kernel-build
   ```

2. **设置环境**
   ```bash
   bash scripts/setup-environment.sh
   ```

3. **下载依赖**
   ```bash
   bash scripts/download-toolchains.sh
   bash scripts/download-qcom-deps.sh
   ```

4. **构建内核**
   ```bash
   bash scripts/build-kernel.sh -d sheng -k 5.15
   ```

### 启用Docker支持

如果需要Docker容器支持，使用以下命令构建：

```bash
bash scripts/build-kernel.sh -d sheng -k 5.15 --enable-docker
```

## 在线构建

1. 在GitHub仓库页面，点击 **Actions** 标签
2. 选择 **Build Xiaomi Pad 6S Pro Kernel** 工作流
3. 点击 **Run workflow** 并选择相应参数
4. 构建完成后，可在Artifacts部分下载编译好的内核

## 构建参数

构建脚本支持以下参数：

- `-d, --device`: 指定设备（默认为`sheng`）
- `-k, --kernel-version`: 指定内核版本（默认为`5.15`）
- `-c, --clean`: 执行清洁构建
- `--enable-docker`: 启用Docker容器支持
- `-t, --toolchain`: 选择工具链（`clang`或`gcc`）

## 项目结构

```
├── .github/            # GitHub Actions工作流配置
├── scripts/            # 构建脚本和工具
├── toolchains/         # 编译工具链（会自动下载）
└── README.md           # 项目说明文档
```

## 构建产物

成功构建后，产物将位于`out/sheng/`目录，包括：

- **内核镜像**: `Image.gz-dtb`
- **内核配置**: `.config`
- **设备树文件**: `dtb/`目录
- **内核模块**: `modules/`目录

## 注意事项

1. 构建过程需要约**2-3小时**，取决于你的网络速度和电脑性能
2. 确保磁盘空间至少有**20GB**可用
3. 推荐使用Linux系统进行本地构建
4. 首次构建会下载大量依赖，耗时较长

## 贡献

欢迎提交Issue和Pull Request来改进这个项目！

## 许可证

本项目采用MIT许可证 - 详情请查看LICENSE文件