#!/bin/bash
# 创建 MacServerMonitor 的 DMG 安装包
# 包含拖拽安装界面

set -e

VERSION=${1:-"1.0.0"}
APP_NAME="MacServerMonitor"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
VOLUME_NAME="${APP_NAME}"

echo "🔨 开始创建 DMG 安装包..."
echo "📦 版本: $VERSION"

# 检查 app 是否存在
if [ ! -d "build/${APP_NAME}.app" ]; then
    echo "❌ 错误: build/${APP_NAME}.app 不存在"
    echo "请先运行 ./build.sh $VERSION"
    exit 1
fi

# 清理旧的 DMG
echo "🧹 清理旧的 DMG..."
rm -f "build/${DMG_NAME}"

# 确保先卸载可能已挂载的卷
echo "🔍 检查并卸载已挂载的卷..."
if [ -d "/Volumes/${VOLUME_NAME}" ]; then
    hdiutil detach "/Volumes/${VOLUME_NAME}" -quiet 2>/dev/null || true
fi

# 创建临时目录
DMG_TEMP_DIR="build/dmg-temp"
rm -rf "$DMG_TEMP_DIR"
mkdir -p "$DMG_TEMP_DIR"

# 复制 app 到临时目录
echo "📋 复制 .app 到临时目录..."
cp -R "build/${APP_NAME}.app" "$DMG_TEMP_DIR/"

# 创建 Applications 的软链接
echo "🔗 创建 Applications 快捷方式..."
ln -s /Applications "$DMG_TEMP_DIR/Applications"

# 创建一个简单的说明文件
cat > "$DMG_TEMP_DIR/安装说明.txt" << 'EOF'
安装方法：

将 MacServerMonitor.app 拖拽到 Applications 文件夹即可

Installation:

Drag MacServerMonitor.app to the Applications folder
EOF

# 创建 DMG（直接压缩，不挂载修改）
echo "📀 创建 DMG..."
hdiutil create -volname "$VOLUME_NAME" \
               -srcfolder "$DMG_TEMP_DIR" \
               -ov \
               -format UDZO \
               -imagekey zlib-level=9 \
               "build/${DMG_NAME}"

# 清理临时文件
rm -rf "$DMG_TEMP_DIR"

echo ""
echo "✅ DMG 创建完成！"
echo "📍 位置: build/${DMG_NAME}"
echo ""
echo "💡 提示："
echo "  1. 双击 DMG 文件来挂载"
echo "  2. 将 MacServerMonitor.app 拖拽到 Applications 快捷方式"
echo "  3. 推出 DMG"
ls -lh "build/${DMG_NAME}"
