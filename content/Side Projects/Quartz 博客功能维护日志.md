# Quartz 博客功能维护日志

> 记录基于 Quartz 的公开博客（Tech Articles）待开启功能及实现流程。
> Created: 2026-05-27

---

## 📋 待办事项

- [ ] 开启「最近文章」功能
- [ ] 开启「评论系统」（Giscus）

---

## 1. 最近文章列表

### 目标
在文章页面底部（或首页）展示最近更新的 5 篇笔记。

### 实现步骤

1. **启用插件**
   编辑 `quartz.config.yaml`，将 `recent-notes` 的 `enabled` 改为 `true`：
   ```yaml
   - source: github:quartz-community/recent-notes
     enabled: true
     options:
       limit: 5
       showTags: true
       title: "最近更新"
     layout:
       position: afterBody
       priority: 10
   ```

2. **调整页面布局（如需在首页显示）**
   在 `quartz.config.yaml` 的 `layout.byPageType` 中为 `content` 或 `index` 页面添加 `recent-notes` 组件位置。

3. **重新构建测试**
   ```bash
   cd ~/Obsidian/quartz-public
   npx quartz build --serve
   ```

4. **提交并推送**
   ```bash
   git add quartz.config.yaml
   git commit -m "feat: enable recent notes"
   git push origin main
   ```

---

## 2. 评论系统（Giscus）

### 目标
为每篇文章底部添加基于 GitHub Discussions 的评论框。

### 前置条件
- GitHub 仓库 `davidchou93/quartz-tech-notes` 为 **Public**
- 已开启仓库的 **Discussions** 功能
- 已安装 [Giscus GitHub App](https://github.com/apps/giscus)

### 实现步骤

1. **获取 Giscus 配置参数**
   访问 [giscus.app](https://giscus.app)，输入仓库名，记录生成的：
   - `repoId`
   - `categoryId`（选择 Announcements）

2. **安装评论插件**
   ```bash
   cd ~/Obsidian/quartz-public
   npx quartz plugin add github:quartz-community/comments
   ```

3. **配置 quartz.config.yaml**
   添加或修改：
   ```yaml
   - source: github:quartz-community/comments
     enabled: true
     options:
       provider: giscus
       options:
         repo: davidchou93/quartz-tech-notes
         repoId: <从 giscus.app 获取>
         category: Announcements
         categoryId: <从 giscus.app 获取>
         lang: zh-CN
     layout:
       position: afterBody
       priority: 10
   ```

4. **重新构建测试**
   ```bash
   npx quartz build --serve
   ```

5. **提交并推送**
   ```bash
   git add quartz.config.yaml
   git commit -m "feat: add Giscus comments"
   git push origin main
   ```

### 单篇文章禁用评论
在文章 frontmatter 中加入：
```yaml
---
title: 某篇文章
comments: false
---
```

---

## 📝 变更记录

| 日期 | 变更 | 状态 |
|------|------|------|
| 2026-05-27 | 创建维护日志 | ✅ |
| 2026-05-27 | 待开启：最近文章 | ⏳ |
| 2026-05-27 | 待开启：评论系统 | ⏳ |

---

## 相关链接

- 博客域名：`articles.doctor-david.org`
- 仓库：`https://github.com/davidchou93/quartz-tech-notes`
- 本地路径：`~/Obsidian/quartz-public/`
- 内容源：`~/Obsidian/Brain Extension/Career & Technical Hub/Tech Articles/`

---

tags:
  - side-project
  - quartz
  - blog
  - devops
