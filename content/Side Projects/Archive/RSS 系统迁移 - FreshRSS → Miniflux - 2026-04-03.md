---

---
# RSS 系统迁移 - FreshRSS → Miniflux

## 迁移概览

| 项目 | 详情 |

|------|------|

| **迁移日期** | 2026-04-03 |

| **旧系统** | FreshRSS (10.0.9.121:18080) |

| **新系统** | Miniflux (10.0.9.121:18080) |

| **订阅源数量** | 194 个 |

| **分类数量** | 17 个 |

---

## 部署信息

### Miniflux 配置

- **URL**: http://10.0.9.121:18080
- **API Token: **`072bc6619e812d4137daeec3b83320944e7dc18a9688f2b8d6f485cd8ce068b4`
- **代理配置**: 10.0.9.101:7897 (用于 RSS 抓取)

---

## RSS 订阅源验证

从两个 GitHub 仓库验证了 283 个 RSS 链接：

- https://github.com/plenaryapp/awesome-rss-feeds
- https://github.com/tuan3w/awesome-tech-rss

### 有效订阅源统计

**总计: 179 个有效订阅源**

- Engineering Blogs: 29
- Machine Learning: 21
- Apple: 16
- Programming: 16
- Tech: 15
- Business & Economy: 14
- Movies: 9
- 其他分类: 59

---

## Miniflux 功能特性

### ✅ 支持的功能

- 原生 REST API 支持
- 已读/收藏状态管理
- Webhook 推送功能（新文章推送）
- 资源占用低（Go + PostgreSQL）

### ❌ 限制

- 不支持自定义标签（需要自建标签服务）

---

## 下一步计划

- [ ] 开发 Webhook 接收服务，将文章推送到 PocketBase
- [ ] 在 PocketBase 中维护标签、评分等自定义数据

---

*记录时间: 2026-04-03*