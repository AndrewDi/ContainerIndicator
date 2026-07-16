#!/bin/sh

# ==========================================
# Xcode 原生依赖打包 DMG 脚本 (完美修复版)
# ==========================================

# 🌟 核心修复：将 Homebrew 的路径注入到当前脚本的 PATH 中
# 兼容 Apple Silicon (/opt/homebrew/bin) 和 Intel (/usr/local/bin)
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# 1. 定位项目根目录
# 优先使用 Xcode 环境变量，否则取脚本所在目录的上一级
if [ -n "$PROJECT_DIR" ]; then
    cd "$PROJECT_DIR" || { echo "❌ 无法切换到项目目录"; exit 1; }
else
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    cd "${SCRIPT_DIR}/.." || { echo "❌ 无法切换到项目目录"; exit 1; }
    export PROJECT_DIR="$(pwd)"
fi
echo "📍 当前工作目录: $(pwd)"

# 2. 基础变量配置
APP_SCHEME_NAME="ContainerIndicator"
APP_NAME="${APP_SCHEME_NAME}.app"
DMG_NAME="${APP_SCHEME_NAME}_Installer.dmg"
DMG_VOLUME_NAME="${APP_SCHEME_NAME}"

# 3. 动态获取 Xcode 刚刚编译好的 App 路径
if [ -n "$BUILT_PRODUCTS_DIR" ]; then
    BUILT_APP_PATH="${BUILT_PRODUCTS_DIR}/${APP_NAME}"
else
    # 命令行运行：从 DerivedData 自动查找
    DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
    BUILT_APP_PATH=$(find "$DERIVED_DATA" -path "*/Build/Products/Debug/${APP_NAME}" -type d 2>/dev/null | head -1)
fi

if [ -z "$BUILT_APP_PATH" ] || [ ! -d "${BUILT_APP_PATH}" ]; then
    echo "❌ 致命错误：找不到编译好的 ${APP_NAME}！"
    echo "💡 请先在 Xcode 中编译项目 (Cmd+B)，或确认 App Scheme 名称为 '${APP_SCHEME_NAME}'。"
    exit 1
fi
echo "✅ 找到编译产物: ${BUILT_APP_PATH}"

# 准备 DMG 输出路径 (直接输出到项目根目录)
DMG_OUTPUT_PATH="${PROJECT_DIR}/${DMG_NAME}"
echo "🧹 正在清理旧的 DMG 文件..."
rm -f "${DMG_OUTPUT_PATH}"

# 4. 检查 create-dmg 是否安装 (使用绝对路径优先，最稳妥)
CREATE_DMG_CMD="/opt/homebrew/bin/create-dmg"
if [ ! -x "$CREATE_DMG_CMD" ]; then
    # 如果不在 Apple Silicon 默认位置，尝试从更新后的 PATH 中找 (兼容 Intel Mac)
    CREATE_DMG_CMD=$(which create-dmg)
fi

if [ -z "$CREATE_DMG_CMD" ] || [ ! -x "$CREATE_DMG_CMD" ]; then
    echo "⚠️ 警告: 未检测到 create-dmg 工具。"
    echo "请在终端运行 'brew install create-dmg' 安装后重试。"
    exit 1
fi
echo "✅ 找到 create-dmg: $CREATE_DMG_CMD"

# 5. 准备一个干净的临时文件夹给 create-dmg 使用
DMG_SOURCE_DIR="${PROJECT_DIR}/build_dmg_temp_source"
rm -rf "${DMG_SOURCE_DIR}"
mkdir -p "${DMG_SOURCE_DIR}"

echo "📦 正在复制 ${APP_NAME} 到临时打包目录..."
cp -R "${BUILT_APP_PATH}" "${DMG_SOURCE_DIR}/"

# 6. 生成 DMG 镜像
echo "💿 正在生成 DMG 安装包..."

# 构建 create-dmg 参数 (可选参数必须在位置参数之前)
DMG_ARGS=(
    --volname "${DMG_VOLUME_NAME}"
    --window-pos 200 120
    --window-size 800 500
    --icon-size 100
    --icon "${APP_NAME}" 200 250
    --app-drop-link 600 250
    --hide-extension "${APP_NAME}"
    --skip-jenkins
    --no-internet-enable
)

# 如果项目根目录下有 assets/dmg_background.png，则自动使用
if [ -f "${PROJECT_DIR}/assets/dmg_background.png" ]; then
    DMG_ARGS+=(--background "${PROJECT_DIR}/assets/dmg_background.png")
fi

# 如果项目根目录下有 assets/app_icon.icns，则自动使用
if [ -f "${PROJECT_DIR}/assets/app_icon.icns" ]; then
    DMG_ARGS+=(--volicon "${PROJECT_DIR}/assets/app_icon.icns")
fi

# 位置参数放最后
DMG_ARGS+=(
    "${DMG_OUTPUT_PATH}"
    "${DMG_SOURCE_DIR}"
)

# 🌟 使用获取到的绝对路径执行打包
echo "$CREATE_DMG_CMD" "${DMG_ARGS[@]}"
"$CREATE_DMG_CMD" "${DMG_ARGS[@]}"
CREATE_DMG_STATUS=$?

# 7. 清理临时文件夹
rm -rf "${DMG_SOURCE_DIR}"

# 8. 检查结果
if [ $CREATE_DMG_STATUS -ne 0 ]; then
    echo "❌ 生成 DMG 失败！"
    exit 1
fi

echo "🎉 打包完成！"
echo "📍 DMG 文件位置: ${DMG_OUTPUT_PATH}"
