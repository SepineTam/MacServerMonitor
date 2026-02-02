#!/bin/bash
# MacServerMonitor 本地构建脚本
# 用于构建并打包 .app 文件

set -e  # 遇到错误时退出

echo "🔨 开始构建 MacServerMonitor..."

# 获取版本号（如果提供了参数则使用参数，否则使用默认）
VERSION=${1:-"1.0.0"}

echo "📦 版本号: $VERSION"

# 清理旧的构建
echo "🧹 清理旧构建..."
rm -rf build
rm -rf .build

# 构建 release 版本
echo "🔧 编译中..."
swift build -c release

# 创建 .app bundle 结构
echo "📱 创建 .app bundle..."
mkdir -p build/MacServerMonitor.app/Contents/MacOS
mkdir -p build/MacServerMonitor.app/Contents/Resources

# 复制可执行文件
echo "📋 复制可执行文件..."
cp .build/arm64-apple-macosx/release/MacServerMonitor build/MacServerMonitor.app/Contents/MacOS/
chmod +x build/MacServerMonitor.app/Contents/MacOS/MacServerMonitor

# 创建 Info.plist
echo "📝 创建 Info.plist..."
cat > build/MacServerMonitor.app/Contents/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MacServerMonitor</string>
    <key>CFBundleIdentifier</key>
    <string>com.github.sepinetam.MacServerMonitor</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>MacServerMonitor</string>
    <key>CFBundleDisplayName</key>
    <string>MacServerMonitor</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSSupportsSuddenTermination</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
</dict>
</plist>
EOF

# 复制图标
echo "🎨 复制图标..."
cp Resources/AppIcon.icns build/MacServerMonitor.app/Contents/Resources/

# 创建 ZIP 归档
echo "📦 创建 ZIP 归档..."
cd build
zip -r MacServerMonitor-$VERSION.zip MacServerMonitor.app
cd ..

# 创建 DMG 安装包
echo "💿 创建 DMG 安装包..."
./create-dmg.sh $VERSION

echo ""
echo "✅ 构建完成！"
echo "📍 .app 位置: build/MacServerMonitor.app"
echo "📍 ZIP 位置: build/MacServerMonitor-$VERSION.zip"
echo "📍 DMG 位置: build/MacServerMonitor-$VERSION.dmg"
echo ""
echo "💡 提示："
echo "  - 双击 build/MacServerMonitor.app 来运行应用"
echo "  - 或者双击 DMG 文件进行安装"
