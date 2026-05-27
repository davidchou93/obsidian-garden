---

---
本文档包含 Atten-chine 的完整开发周期计划，采用策略1（自适应梯度更新）作为在线学习算法。每个阶段可独立实现和测试。

> [!note] 📋
> 技术栈确认

• 后端: Python + FastAPI
• 数据库: SQLite + SQLAlchemy
• 前端: Vue 3 + TypeScript + Vite + shadcn/ui
• AI: Ollama (qwen3-embedding:0.6b + Qwen3-4B)
• 算法: 策略1 - 自适应梯度更新
• 外网访问: Cloudflare Tunnel

---

# 🎯 Phase 1: 基础架构 (Week 1)

目标: 搭建数据库、API骨架、Ollama连接，完成第一篇文章的抓取和存储。

## Milestone 1.1: 数据库初始化

- [ ] 配置 SQLite 数据库（单文件，零部署）
- [ ] 创建 SQLAlchemy 模型 (articles, user_profiles, ratings)
- [ ] 验证向量维度 1024 与 qwen3-embedding 匹配，使用 Python 向量计算余弦相似度

> [!note]+ 💾 数据库 Schema (点击展开)
> ```sql
> -- 启用 pgvector
> CREATE EXTENSION IF NOT EXISTS vector;
> 
> -- 文章表
> CREATE TABLE articles (
>     id SERIAL PRIMARY KEY,
>     url TEXT UNIQUE NOT NULL,
>     title TEXT NOT NULL,
>     content TEXT,
>     summary TEXT,
>     source TEXT NOT NULL,
>     source_type TEXT NOT NULL,
>     embedding VECTOR(1024),
>     published_at TIMESTAMP,
>     fetched_at TIMESTAMP DEFAULT NOW(),
>     is_processed BOOLEAN DEFAULT FALSE
> );
> 
> -- 用户画像表 (策略1: 自适应梯度)
> CREATE TABLE user_profiles (
>     id SERIAL PRIMARY KEY,
>     user_id TEXT UNIQUE NOT NULL,
>     mean_vector VECTOR(1024),
>     var_vector VECTOR(1024),
>     obs_count INTEGER DEFAULT 0,
>     base_lr FLOAT DEFAULT 0.1,
>     created_at TIMESTAMP DEFAULT NOW(),
>     updated_at TIMESTAMP DEFAULT NOW()
> );
> 
> -- 评分记录表
> CREATE TABLE ratings (
>     id SERIAL PRIMARY KEY,
>     user_id TEXT REFERENCES user_profiles(user_id),
>     article_id INTEGER REFERENCES articles(id),
>     rating INTEGER CHECK (rating >= 1 AND rating <= 5),
>     rated_at TIMESTAMP DEFAULT NOW(),
>     UNIQUE(user_id, article_id)
> );
> 
> -- 索引
> CREATE INDEX ON articles USING ivfflat (embedding vector_cosine_ops);
> ```

## Milestone 1.2: FastAPI 项目骨架

- [ ] 初始化项目结构 (backend/, frontend/, docker-compose.yml)
- [ ] 配置 SQLAlchemy 连接 SQLite（同步模式）
- [ ] 实现健康检查端点 GET /health

> [!note]+ 📁 项目结构 (点击展开)
> ```plain text
> atten-chine/
> ├── backend/
> │   ├── app/
> │   │   ├── __init__.py
> │   │   ├── main.py
> │   │   ├── models.py
> │   │   ├── database.py
> │   │   ├── config.py
> │   │   ├── services/
> │   │   │   ├── embedder.py
> │   │   │   ├── summarizer.py
> │   │   │   ├── fetcher.py
> │   │   │   ├── recommender.py
> │   │   │   └── learner.py
> │   │   └── routers/
> │   │       ├── articles.py
> │   │       ├── ratings.py
> │   │       ├── sources.py
> │   │       └── admin.py
> │   ├── requirements.txt
> │   └── Dockerfile
> ├── frontend/
> │   ├── src/
> │   │   ├── components/
> │   │   ├── views/
> │   │   ├── services/
> │   │   └── stores/
> │   └── package.json
> └── docker-compose.yml
> ```

## Milestone 1.3: Ollama 集成

- [ ] 实现 embedding 服务: 调用 qwen3-embedding:0.6b
- [ ] 实现摘要服务: 调用 Qwen3-4B 生成摘要
- [ ] 添加错误重试和超时处理

## Phase 1 验收标准

- ✅ 数据库可正常连接，表结构正确
- ✅ GET /health 返回 {"status": "ok"}
- ✅ 可调用 Ollama 生成 1024 维 embedding

---

# 🔧 Phase 2: 核心功能 (Week 2)

目标: 实现 RSS 抓取、文章入库、推荐算法、评分反馈闭环。

## Milestone 2.1: RSS 抓取服务

- [ ] 实现 RSS feed 解析 (feedparser)
- [ ] 文章去重 (URL 唯一性检查)
- [ ] 抓取 → 摘要 → Embedding → 入库流水线
- [ ] 添加手动触发抓取的 API: POST /api/sources/{id}/fetch

## Milestone 2.2: 推荐算法实现

- [ ] 初始化用户画像 (mean=0, var=1)
- [ ] 实现自适应混合算法: <50条评分用贝叶斯更新，>50条评分用梯度下降
- [ ] 实现推荐排序: UCB探索机制 (得分 = 余弦相似度 + 不确定性奖励)
- [ ] 实现 GET /api/articles/feed 推荐接口

> [!note]+ 🧠 策略1: 自适应梯度更新 (点击展开)
> ```python
> # services/learner.py - 核心算法
> import numpy as np
> 
> class AdaptiveLearner:
>     def __init__(self, base_lr: float = 0.1):
>         self.base_lr = base_lr
>     
>     def update(self, mean_vec, var_vec, article_vec, rating, obs_count):
>         # 1-5分映射到 [-1, 1]
>         target = (rating - 3) / 2
>         
>         # 归一化文章向量
>         article_unit = article_vec / np.linalg.norm(article_vec)
>         
>         # 当前相似度
>         current_sim = np.dot(mean_vec, article_unit)
>         
>         # 自适应学习率: 维度级别
>         adaptive_lr = self.base_lr * var_vec
>         
>         # 误差驱动更新
>         error = target - current_sim
>         new_mean = mean_vec + adaptive_lr * error * article_unit
>         new_mean = new_mean / np.linalg.norm(new_mean)
>         
>         # 方差更新
>         update_strength = np.abs(article_unit) * adaptive_lr
>         new_var = var_vec * (1 - update_strength)
>         new_var = np.maximum(new_var, 0.01)
>         
>         return new_mean, new_var, obs_count + 1
>     
>     def recommend_score(self, mean_vec, var_vec, article_vec):
>         article_unit = article_vec / np.linalg.norm(article_vec)
>         expected_sim = np.dot(mean_vec, article_unit)
>         uncertainty = np.sqrt(np.dot(var_vec, article_unit ** 2))
>         return expected_sim + 0.1 * uncertainty
> ```

## Milestone 2.3: 评分反馈闭环

- [ ] 实现 POST /api/ratings 提交评分
- [ ] 评分后触发用户画像更新
- [ ] 防止重复评分 (唯一性约束)

## Phase 2 验收标准

- ✅ 可成功抓取 RSS 文章并存入数据库
- ✅ 新用户初始化后，/api/articles/feed 能返回推荐
- ✅ 提交评分后，用户向量和方差正确更新

---

# 🎨 Phase 3: 前端开发 (Week 3)

目标: 实现可交互的 WebUI，完成文章浏览、评分、管理功能。

## Milestone 3.1: 项目初始化

- [ ] Vue 3 + TypeScript + Vite 初始化
- [ ] 安装 shadcn/ui 组件库
- [ ] 配置 axios API 客户端

## Milestone 3.2: 推荐 Feed 页面

- [ ] 实现文章卡片组件 (标题/摘要/来源/时间)
- [ ] 实现 1-5 星评分按钮组件
- [ ] 实现 Feed 列表 (虚拟滚动优化)
- [ ] 评分后即时反馈 (Toast 提示)

## Milestone 3.3: 管理页面

- [ ] RSS 源管理 (添加/删除/启用/禁用)
- [ ] 已评分文章历史页面
- [ ] 手动触发抓取的按钮

## Phase 3 验收标准

- ✅ 用户可在 WebUI 浏览推荐文章列表
- ✅ 用户可点击 1-5 分进行评分
- ✅ 管理页面可操作 RSS 源

---

# 🚀 Phase 4: 增强功能 (Week 4)

目标: 添加调参辅助、Telegram 推送、YouTube 支持、系统监控。

## Milestone 4.1: 基础参数调节辅助

- [ ] 实现方差分布可视化 (柱状图/热力图)
- [ ] 学习进度仪表盘 (observation_count, 各源评分分布)
- [ ] 基础学习率调节滑块 (0.01-0.5)
- [ ] 异常检测: 所有方差<0.1 或 >0.5 时警告

> [!note]+ 📊 调参辅助面板设计 (点击展开)
> ```plain text
> Admin Dashboard 指标:
> 
> 1. 方差分布图
>    - X轴: 方差区间 (0-0.1, 0.1-0.2, ...)
>    - Y轴: 维度数量
>    - 目标: 呈现"少数低方差+多数中等"的分布
> 
> 2. 学习进度
>    - 总评分次数
>    - 最近7天评分趋势
>    - 各RSS源的文章/评分比例
> 
> 3. 参数调节
>    - 基础学习率: 滑块 0.01 - 0.5
>    - 探索权重: 滑块 0.0 - 0.3
>    - 最小方差: 滑块 0.001 - 0.1
> 
> 4. 系统健康
>    - PostgreSQL 连接状态
>    - Ollama 可用性
>    - 最近抓取时间/成功率
> ```

## Milestone 4.2: Telegram 推送

- [ ] 集成 python-telegram-bot
- [ ] 实现每日定时推送 Top 5 文章
- [ ] Telegram 内嵌评分按钮 (1-5)
- [ ] 推送失败重试机制

## Milestone 4.3: YouTube 支持

- [ ] 集成 yt-dlp 获取视频信息
- [ ] 字幕提取与摘要生成
- [ ] YouTube 频道订阅管理

## Phase 4 验收标准

- ✅ 管理员面板可查看方差分布和学习进度
- ✅ Telegram 每日自动推送推荐文章
- ✅ 可订阅 YouTube 频道并获取视频推荐

---

# 📅 时间线与检查点

建议按周推进，每个 Phase 完成后进行一次手动测试验证。

> [!note]+ ⏰ 详细时间分配 (点击展开)
> ```plain text
> Week 1 - Phase 1: 基础架构
> ├── Day 1-2: 数据库 + 项目结构
> ├── Day 3-4: Ollama 集成
> └── Day 5: 健康检查 + 测试
> 
> Week 2 - Phase 2: 核心功能
> ├── Day 1-2: RSS 抓取服务
> ├── Day 3-4: 推荐算法实现
> └── Day 5: 评分反馈闭环
> 
> Week 3 - Phase 3: 前端
> ├── Day 1-2: Vue 项目 + 组件库
> ├── Day 3-4: Feed 页面 + 评分
> └── Day 5: 管理页面
> 
> Week 4 - Phase 4: 增强
> ├── Day 1-2: 调参辅助面板
> ├── Day 3: Telegram 推送
> └── Day 4-5: YouTube + 集成测试
> ```

> [!warning] ⚠️
> **⚠️ 风险提示**

1. Ollama 模型加载较慢，首次请求可能超时，需配置重试
2. 冷启动阶段推荐质量较差，建议先用测试账号积累20+评分
3. PostgreSQL 向量索引需要足够数据量才能生效，前期可能不走索引
4. YouTube 抓取可能触发反爬，建议控制频率（每频道每天最多1次）

> [!tip] 💡
> **💡 后续优化方向**

• 周期性批量重训练（使用积累的数据离线优化）
• 多用户支持（如果有需求）
• 邮件源支持（IMAP）
• BBS/论坛抓取（如 V2EX、HN）
• 推荐结果 A/B 测试框架

开发计划创建完成。建议从 Phase 1 开始，逐步实现每个 milestone。

## 技术方案更新 (2026-04-03)

### 项目信息

- **项目位置**: `~/projects/attenchine/` (独立项目，非 OpenClaw skill)
- **数据库**: SQLite + SQLAlchemy（单文件，简化部署）
- **WebUI**: Vue 3 + TypeScript + Vite + shadcn/ui，通过 Cloudflare Tunnel 外网访问
- **部署**: Mac Mini 本地运行
- **数据库**: SQLite (单文件，零维护)

### 交互方式

- **WebUI 人工评分**（主要交互）
- 文章列表展示
- ⭐⭐⭐⭐⭐ 五星评分
- 批量评分模式
- 标签管理
- **Telegram 辅助交互**
- 定时推送高分文章
- 推送带 WebUI 链接（JWT token 验证）
- 支持回复批量评分格式：`1/5, 2/3, 3/5`（序号/评分）

### 开发阶段（5个 Phase）

**Phase 1: 基础架构**

- SQLite + SQLAlchemy 数据模型设计
- FreshRSS API 集成（定期拉取新文章）
- Ollama embedding 集成 (Qwen3-embed)
- 项目结构搭建在 `~/projects/attenchine/`

**Phase 2: WebUI 开发**

- FastAPI + Jinja2/htmx 技术栈
- 文章卡片展示（标题、摘要、来源、时间）
- 五星评分组件
- 批量评分模式（复选框 + 统一打分）
- 外网访问配置 (Tailscale/ngrok/Cloudflare Tunnel)

**Phase 3: Telegram Bot**

- python-telegram-bot 框架
- APScheduler 定时任务
- 高分文章推送算法
- WebUI 链接生成（带 JWT token 验证）
- 批量评分解析（正则提取 `序号/评分`）

**Phase 4: 推荐算法**

- 贝叶斯更新实现（用户画像不确定性建模）
- 用户兴趣向量实时更新
- 文章个性化排序
- 探索 vs 利用平衡

**Phase 5: 优化**

- 缓存策略（文章 embedding、用户画像）
- 数据备份机制
- 性能监控与调优
- 用户体验打磨

# Atten-chine 技术方案更新 (2026-04-03)

## 项目信息

- **项目位置**: `~/projects/attenchine/` (独立项目，非 OpenClaw skill)
- **技术栈**: Python (FastAPI + SQLAlchemy)
- **WebUI**: FastAPI + Jinja2/htmx，需外网访问
- **部署**: Mac Mini 本地运行
- **数据库**: SQLite (单文件，零维护)

---

## 交互方式

### WebUI 人工评分（主要交互）

- 文章列表展示
- ⭐⭐⭐⭐⭐ 五星评分
- 批量评分模式
- 标签管理

### Telegram 辅助交互

- 定时推送高分文章
- 推送带 WebUI 链接（JWT token 验证）
- 支持回复批量评分格式：`1/5, 2/3, 3/5`（序号/评分）

---

## 开发阶段（5个 Phase）

### Phase 1: 基础架构

- SQLite + SQLAlchemy 数据模型设计
- FreshRSS API 集成（定期拉取新文章）
- Ollama embedding 集成 (Qwen3-embed)
- 项目结构搭建在 `~/projects/attenchine/`

### Phase 2: WebUI 开发

- FastAPI + Jinja2/htmx 技术栈
- 文章卡片展示（标题、摘要、来源、时间）
- 五星评分组件
- 批量评分模式（复选框 + 统一打分）
- 外网访问配置 (Tailscale/ngrok/Cloudflare Tunnel)

### Phase 3: Telegram Bot

- python-telegram-bot 框架
- APScheduler 定时任务
- 高分文章推送算法
- WebUI 链接生成（带 JWT token 验证）
- 批量评分解析（正则提取 `序号/评分`）

### Phase 4: 推荐算法

- 贝叶斯更新实现（用户画像不确定性建模）
- 用户兴趣向量实时更新
- 文章个性化排序
- 探索 vs 利用平衡

### Phase 5: 优化

- 缓存策略（文章 embedding、用户画像）
- 数据备份机制
- 性能监控与调优
- 用户体验打磨

---

*生成时间: 2026-04-03*

# Atten-chine 技术方案更新 (2026-04-03)

## 项目信息

- **项目位置**: `~/projects/attenchine/` (独立项目，非 OpenClaw skill)
- **技术栈**: Python (FastAPI + SQLAlchemy)
- **WebUI**: FastAPI + Jinja2/htmx，需外网访问
- **部署**: Mac Mini 本地运行
- **数据库**: SQLite (单文件，零维护)

---

## 交互方式

### WebUI 人工评分（主要交互）

- 文章列表展示
- ⭐⭐⭐⭐⭐ 五星评分
- 批量评分模式
- 标签管理

### Telegram 辅助交互

- 定时推送高分文章
- 推送带 WebUI 链接（JWT token 验证）
- 支持回复批量评分格式：`1/5, 2/3, 3/5`（序号/评分）

---

## 开发阶段（5个 Phase）

### Phase 1: 基础架构

- SQLite + SQLAlchemy 数据模型设计
- FreshRSS API 集成（定期拉取新文章）
- Ollama embedding 集成 (Qwen3-embed)
- 项目结构搭建在 `~/projects/attenchine/`

### Phase 2: WebUI 开发

- FastAPI + Jinja2/htmx 技术栈
- 文章卡片展示（标题、摘要、来源、时间）
- 五星评分组件
- 批量评分模式（复选框 + 统一打分）
- 外网访问配置 (Tailscale/ngrok/Cloudflare Tunnel)

### Phase 3: Telegram Bot

- python-telegram-bot 框架
- APScheduler 定时任务
- 高分文章推送算法
- WebUI 链接生成（带 JWT token 验证）
- 批量评分解析（正则提取 `序号/评分`）

### Phase 4: 推荐算法

- 贝叶斯更新实现（用户画像不确定性建模）
- 用户兴趣向量实时更新
- 文章个性化排序
- 探索 vs 利用平衡

### Phase 5: 优化

- 缓存策略（文章 embedding、用户画像）
- 数据备份机制
- 性能监控与调优
- 用户体验打磨

---

*生成时间: 2026-04-03*

## 算法设计说明 (2026-04-03)

### 核心策略：自适应混合算法

采用分阶段切换策略，兼顾冷启动稳健性和后期响应速度：

**阶段1（评分数 < 50）：贝叶斯更新**

- 存储用户画像的概率分布（均值向量 + 方差向量）
- 初始状态：μ=0, σ²=1（完全不确定）
- 观测噪声固定为 0.5
- 卡尔曼增益控制更新幅度

**阶段2（评分数 ≥ 50）：梯度下降**

- 使用确定的均值向量作为用户画像
- 自适应学习率：lr = base_lr × variance
- 高分文章拉近，低分文章推远

### 推荐排序：UCB探索机制

- **利用项**：当前预测的匹配度
- **探索项**：不确定维度给予奖励
- 系数 c 控制探索强度（建议 0.3-0.5）

### UCB 的局限性

UCB 只能探索**用户画像已覆盖维度**的不确定性，无法主动发现全新领域。

例如：

- 用户画像：[编程: 0.9±0.1, 科技: 0.8±0.1, 艺术: 0.1±0.8]
- UCB 会优先探索艺术相关内容（因为方差大）
- 但如果画像中根本没有哲学维度，UCB 不会推荐哲学内容

### 打破信息茧房的后续优化方向

**Phase 5 可迭代的探索机制：**

| 机制 | 作用 | 实现建议 |

|------|------|----------|

| **语义邻近探索** | 推荐与用户偏好相似但不相同的内容 | 向量距离 0.3-0.7 区间加分 |

| **显性多样性注入** | 强制引入新领域 | 5% 概率随机推荐跨领域热门 |

| **趋势/社交信号** | 外部视角突破茧房 | 朋友推荐、全网趋势 |

| **定期冷启动** | 周期性重置部分维度方差 | 每月重置低频维度 σ²=0.5 |

**混合探索比例建议：**

- 80% UCB（已知空间内探索）
- 15% 语义邻近（边缘偏好）
- 5% 显性跨领域（完全突破）

---

*算法方案确认日期: 2026-04-03*

*参考案例: Spotify Bayesian surrogate model, 工业级矩阵分解+SGD*