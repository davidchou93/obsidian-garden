#!/bin/bash
# sync-to-quartz.sh - 同步 Obsidian 文件夹到 Quartz 发布目录

set -e

# 配置：Obsidian Vault 根目录
VAULT_ROOT="/Users/davidchou/Obsidian/Brain Extension"

# 配置：Quartz 目录
QUARTZ_ROOT="/Users/davidchou/Obsidian/quartz-public"
CONTENT_DIR="$QUARTZ_ROOT/content"

# 配置：要同步的文件夹列表
# 格式："Obsidian相对路径|content目录名"
# 目前只同步 Tech Articles，以后添加新的在这里加一行
SYNC_FOLDERS=(
    # 格式: "Obsidian相对路径|content目录名"
    # 左侧: 相对于 VAULT_ROOT 的 Obsidian 文件夹路径
    # 右侧: 发布后在 content/ 下的目录名（URL中会显示）

    # Tech Articles - 技术文章
    "Career & Technical Hub/Tech Articles|Tech Articles"

    # Side Projects Logs - 个人项目记录
    "Side Projects Logs|Side Projects"
)

echo "🔧 Syncing Obsidian → Quartz..."
echo ""

# 确保 content 目录存在
mkdir -p "$CONTENT_DIR"

# 遍历每个配置的文件夹
for item in "${SYNC_FOLDERS[@]}"; do
    # 拆分源路径和目标名称
    src_path="${item%%|*}"
    dest_name="${item##*|}"
    
    src_full="$VAULT_ROOT/$src_path"
    dest_full="$CONTENT_DIR/$dest_name"
    
    if [ ! -d "$src_full" ]; then
        echo "⚠️  Source not found: $src_full"
        continue
    fi
    
    echo "📂 Syncing: $src_path → content/$dest_name"
    
    # 删除旧内容（如果是 symlink 或旧复制）
    if [ -L "$dest_full" ] || [ -d "$dest_full" ]; then
        rm -rf "$dest_full"
    fi
    
    # 复制新内容（排除 .obsidian 等）
    rsync -av --delete \
        --exclude='.obsidian' \
        --exclude='.git' \
        --exclude='*.tmp' \
        --exclude='.DS_Store' \
        "$src_full/" "$dest_full/"
    
    echo "   ✅ Done: $dest_name"
    echo ""
done

echo "📝 Checking for changes..."
cd "$QUARTZ_ROOT"

# 检查是否有变更
if git diff --quiet && git diff --cached --quiet; then
    echo "🔄 No changes detected. Skipping commit."
    exit 0
fi

# Git 操作
git add content/
git commit -m "Sync Obsidian content: $(date '+%Y-%m-%d %H:%M')"

echo ""
echo "🚀 Pushing to GitHub..."
git push

echo ""
echo "✨ Done! Cloudflare Pages will rebuild automatically."
