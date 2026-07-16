#!/bin/sh

# ==========================================
# ContainerIndicator 安装脚本
# ==========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

DMG_NAME="ContainerIndicator_Installer.dmg"
DMG_PATH="${PROJECT_DIR}/${DMG_NAME}"
APP_NAME="ContainerIndicator.app"
APP_BUNDLE_ID="whoever.ContainerIndicator"
INSTALL_DIR="/Applications"

# 1. 检查 DMG 是否存在
if [ ! -f "${DMG_PATH}" ]; then
    echo "❌ 找不到 DMG 文件: ${DMG_PATH}"
    echo "💡 请先运行 scripts/build_dmg.sh 生成安装包。"
    exit 1
fi

# 2. 挂载 DMG
echo "💿 正在挂载 ${DMG_NAME}..."
MOUNT_OUTPUT=$(hdiutil attach "${DMG_PATH}" -nobrowse 2>&1)
MOUNT_DIR=$(echo "$MOUNT_OUTPUT" | grep "/Volumes/" | awk '{print $NF}')

if [ -z "$MOUNT_DIR" ] || [ ! -d "$MOUNT_DIR" ]; then
    echo "❌ 挂载 DMG 失败！"
    echo "$MOUNT_OUTPUT"
    exit 1
fi
echo "✅ 已挂载到: ${MOUNT_DIR}"

# 3. 检查 App 是否存在
if [ ! -d "${MOUNT_DIR}/${APP_NAME}" ]; then
    echo "❌ DMG 中找不到 ${APP_NAME}"
    hdiutil detach "$MOUNT_DIR" -quiet
    exit 1
fi

# 4. 停止正在运行的应用
if pgrep -x "ContainerIndicator" > /dev/null 2>&1; then
    echo "⏹️  正在停止 ContainerIndicator..."
    osascript -e "quit app \"ContainerIndicator\"" 2>/dev/null || killall ContainerIndicator 2>/dev/null || true
    sleep 1
fi

# 5. 移除旧版本
if [ -d "${INSTALL_DIR}/${APP_NAME}" ]; then
    echo "🗑️  移除旧版本..."
    rm -rf "${INSTALL_DIR}/${APP_NAME}"
fi

# 6. 复制 App 到 /Applications
echo "📦 正在安装 ${APP_NAME} 到 ${INSTALL_DIR}..."
cp -R "${MOUNT_DIR}/${APP_NAME}" "${INSTALL_DIR}/"

# 7. 卸载 DMG
echo "⏏️  正在卸载 DMG..."
hdiutil detach "$MOUNT_DIR" -quiet

# 8. 验证安装
if [ ! -d "${INSTALL_DIR}/${APP_NAME}" ]; then
    echo "❌ 安装失败，${INSTALL_DIR} 中未找到 ${APP_NAME}"
    exit 1
fi

# 9. 启动应用
echo "🚀 正在启动 ContainerIndicator..."
open "${INSTALL_DIR}/${APP_NAME}"

echo "🎉 安装完成！"
echo "📍 已安装到: ${INSTALL_DIR}/${APP_NAME}"
