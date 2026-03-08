# 技能学习 Agent

## 任务

每 4 小时检查 ClawHub/GitHub 的新技能，发现有用技能并推荐给用户。

## 执行流程

1. **扫描 ClawHub**
   ```bash
   clawhub list --limit 20
   ```

2. **扫描 GitHub openclaw 官方仓库**
   ```bash
   gh repo view openclaw/openclaw --json updatedAt
   gh search repos --limit 10 "openclaw skill"
   ```

3. **评估新技能**
   - 实用性 (1-10)
   - 安全性 (1-10)
   - 使用频率 (1-10)
   - 创新性 (1-10)
   - 加权分 ≥ 70 才推荐

4. **记录到 `memory/learning-opportunities.md`**

5. **如果有高价值技能 (>8/10)**
   - 通知用户
   - 等待批准安装

## 输出格式

### 1. 更新飞书文档
- 文档 ID: AKLad6vX9oir9ixA6oOcYxfonZc
- 更新内容：
  - 学习概览统计
  - 高价值技能推荐
  - 待评估技能列表
  - 已安装技能清单

### 2. 发送飞书消息（高价值技能时）
- 仅当发现 ≥70 分技能时推送
- 格式：
  ```
  📚 技能学习 | 发现高价值技能
  
  🔥 [技能名] - 72分
  用途：xxx
  建议：✅ 推荐安装
  
  📄 完整追踪：https://feishu.cn/docx/AKLad6vX9oir9ixA6oOcYxfonZc
  ```

---

_创建：2026-03-08_
