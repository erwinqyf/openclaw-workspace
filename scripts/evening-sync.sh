#!/bin/bash
# 晚间同步脚本 v3 - 每天零点执行
# 功能：双仓库推送（workspace 完整备份 + using_log 日记）

set -e

WORKSPACE="/home/admin/.openclaw/workspace"
MEMORY_DIR="$WORKSPACE/memory"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

echo "[$TIMESTAMP] 🌙 开始晚间同步..."

# 0. 部门任务环节
echo "[$TIMESTAMP] 🏢 开始部门任务处理..."
DEPT_SCRIPT="$WORKSPACE/skills/department-manager/scripts/departments.py"
if [ -f "$DEPT_SCRIPT" ]; then
    # 生成部门报告
    python3 "$DEPT_SCRIPT" report >> "$WORKSPACE/memory/department-report.md" 2>&1
    echo "[$TIMESTAMP] ✓ 部门报告已生成"
    
    # 检查是否有待处理任务
    ACTIVE_TASKS=$(python3 "$DEPT_SCRIPT" active 2>&1 | grep -c "任务 ID" || echo "0")
    echo "[$TIMESTAMP] 活跃任务数：$ACTIVE_TASKS"
fi

# 1. 技能学习环节（Live and Learn!）
echo "[$TIMESTAMP] 📚 开始技能学习..."
LEARNING_LOG="$MEMORY_DIR/learning-log.md"
if [ ! -f "$LEARNING_LOG" ]; then
    cat > "$LEARNING_LOG" << EOF
# 技能学习日志

## $(date +%Y-%m-%d)
_待 Claw 填充学习进展_

---
EOF
fi
echo "[$TIMESTAMP] ✓ 学习日志就绪"

# 2. 确保目录结构存在
mkdir -p "$MEMORY_DIR/projects"
mkdir -p "$WORKSPACE/obsidian-vault"

# 注意：memory/YYYY-MM-DD.md 由 AI 在会话中自然写入，脚本不自动创建

# 3. 更新项目总览（从各项目 status.md 聚合）
PROJECTS_FILE="$MEMORY_DIR/projects.md"
echo "[$TIMESTAMP] 更新项目总览..."
cat > "$PROJECTS_FILE" << EOF
# Projects - 当前项目状态

_最后更新：$DATE_

## 进行中

EOF
    for status_file in "$MEMORY_DIR/projects/*/status.md"; do
        if [ -f "$status_file" ]; then
            project_name=$(basename $(dirname "$status_file"))
            echo "### $project_name" >> "$PROJECTS_FILE"
            grep -A 5 "## 状态" "$status_file" >> "$PROJECTS_FILE" 2>/dev/null || true
            echo "" >> "$PROJECTS_FILE"
        fi
    done

# 4. 生成关键词索引
INDEX_FILE="$MEMORY_DIR/INDEX.md"
echo "[$TIMESTAMP] 生成关键词索引..."
cat > "$INDEX_FILE" << EOF
# Memory Index - 关键词索引

_自动生成，用于快速检索记忆内容_

**最后生成**: $DATE $(date +%H:%M)

---

## 🔖 关键词索引

| 关键词 | 相关文件 | 日期 | 摘要 |
|--------|---------|------|------|
EOF

# 从所有 markdown 文件提取关键词标签
for mdfile in $(find "$MEMORY_DIR" -name "*.md" -type f); do
    filename=$(basename "$mdfile")
    filepath=$(echo "$mdfile" | sed "s|$WORKSPACE/memory/||")
    filedate=$(stat -c %y "$mdfile" 2>/dev/null | cut -d' ' -f1)
    
    # 提取标签行
    tags=$(grep -o "#[a-zA-Z0-9_]\+" "$mdfile" 2>/dev/null | sort -u | head -5)
    # 提取第一行标题作为摘要
    summary=$(head -1 "$mdfile" | sed 's/^# //' | cut -c1-40)
    
    if [ -n "$tags" ]; then
        for tag in $tags; do
            echo "| $tag | \`$filepath\` | $filedate | $summary... |" >> "$INDEX_FILE"
        done
    fi
done

cat >> "$INDEX_FILE" << EOF

---

## 📁 文件结构

\`\`\`
memory/
├── INDEX.md                    # 本文件（关键词索引）
├── MEMORY.md                   # 核心索引（全局）
├── lessons.md                  # 踩坑记录
├── projects.md                 # 项目总览
├── YYYY-MM-DD.md              # 每日日志
└── projects/
    └── <project-name>/
        └── status.md          # 项目状态
\`\`\`

---

_此索引由晚间同步脚本自动更新_
EOF

# 5. 生成 Obsidian 当日笔记
OBSIDIAN_NOTE="$WORKSPACE/obsidian-vault/$DATE.md"
if [ ! -f "$OBSIDIAN_NOTE" ]; then
    echo "[$TIMESTAMP] 创建 Obsidian 笔记 $OBSIDIAN_NOTE"
    cat > "$OBSIDIAN_NOTE" << EOF
# $DATE - 每日笔记

## 📝 今日摘要
_待 Claw 填充_

## 🎯 关键决策
- 

## 📌 待办事项
- [ ] 

## 💡 灵感/想法
- 

## 🪞 与 Claw 的对话亮点
- 

---
**创建时间**: $TIMESTAMP
**标签**: #daily #journal
EOF
fi

# 6. Git commit 工作区变更（本地）
cd "$WORKSPACE"
if git status --porcelain | grep -q .; then
    echo "[$TIMESTAMP] 📦 检测到变更，准备 commit..."
    git add -A
    git commit -m "🌙 晚间同步 $DATE - auto"
    echo "[$TIMESTAMP] ✅ 本地 commit 完成"
else
    echo "[$TIMESTAMP] ✓ 无变更，跳过 commit"
fi

# 7. 推送到 workspace 仓库（完整备份）
echo "[$TIMESTAMP] ☁️ 推送到 workspace 仓库..."
git push workspace master 2>/dev/null && echo "[$TIMESTAMP] ✅ workspace 推送成功" || echo "[$TIMESTAMP] ⚠️ workspace 推送失败"

# 8. 推送到 using_log 仓库（只保留 README.md 作为日记）
echo "[$TIMESTAMP] 📝 推送到 using_log 仓库..."
# 使用 subtree 方式只推送 README.md
# 先创建临时分支
git checkout -b temp-log-branch 2>/dev/null || git checkout temp-log-branch
# 只保留 README.md
git checkout master -- README.md
git add README.md
git commit -m "📝 更新日记 $DATE" || echo "[$TIMESTAMP] 无变更"
git push origin temp-log-branch:master --force 2>/dev/null && echo "[$TIMESTAMP] ✅ using_log 推送成功" || echo "[$TIMESTAMP] ⚠️ using_log 推送失败"
# 切回 master
git checkout master
# 删除临时分支
git branch -D temp-log-branch 2>/dev/null || true

echo "[$TIMESTAMP] ✨ 晚间同步完成"
