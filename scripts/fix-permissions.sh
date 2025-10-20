#!/bin/bash

# 修复脚本执行权限和路径问题

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "==================================================="
echo "修复脚本执行权限"
echo "==================================================="

# 给所有bash脚本添加执行权限
chmod +x "$ROOT_DIR/quick-start.sh"
chmod +x "$ROOT_DIR/scripts"/*.sh

echo "✅ 脚本执行权限已设置"

echo "\n==================================================="
echo "创建Windows兼容性说明文件"
echo "==================================================="

cat > "$ROOT_DIR/WINDOWS_NOTES.md" << 'EOF'
# Windows环境运行说明

由于这些脚本是为Linux环境编写的，在Windows上运行时需要注意以下几点：

## 推荐方法

### 1. 使用Windows Subsystem for Linux (WSL)

1. 安装WSL 2: https://docs.microsoft.com/zh-cn/windows/wsl/install
2. 选择Ubuntu 22.04或更高版本
3. 在WSL中克隆或复制项目文件
4. 按照README.md中的说明执行脚本

### 2. 使用Git Bash

如果没有WSL，可以使用Git Bash来运行脚本：

1. 安装Git for Windows: https://git-scm.com/download/win
2. 确保在安装过程中选择安装Git Bash
3. 右键点击项目文件夹，选择"Git Bash Here"
4. 按照README.md中的说明执行脚本

## 注意事项

- 路径分隔符：脚本中使用的是Linux风格的路径分隔符(`/`)，在Windows上可能需要注意
- 权限问题：Windows不使用Linux的权限系统，可能需要确保文件有正确的属性
- 工具链兼容性：部分工具链可能只支持Linux环境，建议在WSL中运行

## 常见问题

1. **权限错误**: 确保在Git Bash中运行，或使用管理员权限
2. **路径错误**: 检查文件路径是否正确，注意Windows和Linux路径的区别
3. **工具找不到**: 确保所有依赖都已正确安装

如果遇到问题，强烈建议使用WSL 2进行构建，这是最可靠的方法。
EOF

echo "✅ Windows兼容性说明文件已创建"
echo "\n==================================================="
echo "所有修复完成！"
echo "请参考WINDOWS_NOTES.md了解如何在Windows环境中运行脚本"
echo "==================================================="