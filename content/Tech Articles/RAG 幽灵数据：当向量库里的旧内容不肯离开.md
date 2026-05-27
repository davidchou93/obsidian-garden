

当你在 Obsidian 改完一份笔记，打开 AI 助手提问，它却引用了你三天前的旧版本——这就是 RAG 系统中的"幽灵数据"问题。文件更新了，但向量数据库里的旧 embedding 不会自动消失，新旧版本同时被检索出来，AI 只能硬着头皮把互相矛盾的内容拼成答案。

---

## 问题本质：Embedding 是快照，不是镜像

向量检索只看语义相似度，不看时间先后。你笔记里"项目方案"的旧版和新版，embedding 向量可能非常接近，检索时两者同时被召回。LLM 拿到矛盾内容后，会试图"调和"它们，给出一个自信但错误的综合结论。传统数据库里旧记录至少有时间戳可查，但 embedding 空间里，新旧版本几乎无法区分。

---

## 典型场景：反复修改的笔记

一篇医疗 RAG 的案例：系统同时检索到新旧两份治疗指南，embedding 相似度都很高，LLM 差点建议使用已废弃的治疗协议——幸好人工审核拦截。映射到个人知识库：你的"项目管理笔记"从 v1 初步想法改到 v3 最终决策，向量库里三个版本共存。问"为什么选方案 A"，AI 可能把 v2 里否决 A 的理由和 v3 里支持 A 的理由都列出来。这种错误最危险的不是"答错"，而是"答得似是而非"，让你花额外时间分辨。

---

## 三层防御体系

### 第一层：标记与同步

从源头让 chunk 带"身份证"入库。每个 chunk 附加来源路径、文件哈希、修改时间戳。文件系统用 chokidar 等工具监控变更，内容变化时计算新哈希，仅对变更的 chunk 重新嵌入，旧版本直接删除或标记失效。同一文件不要保留多版本共存。

### 第二层：检索策略

检索时不只看语义相似度，还要加权新鲜度。混合评分公式：语义相似度占 70%，时间衰减占 30%——30 天内 1.0，半年内 0.9，一年内 0.7。检索到同一主题的多版本时，优先返回最新，检测到明显矛盾则在回答中提示用户。对特别重要的领域，可以附加元数据过滤，限定只检索某日期后的内容。

### 第三层：定期治理

建立"staleness"指标主动发现幽灵数据：监控库中最旧文档的年龄、被检索文档的中位年龄、整体新鲜度评分。低于 85% 自动告警，低于 70% 进入降级模式。每周扫描一次，比对文件系统存在性，清理已删除文件残留的 embedding。对文档按重要性分层：Critical（0 天容忍）、High（7 天）、Medium（30 天）、Low（90 天）。

---

## 针对 Obsidian + AnythingLLM 的建议

- **AnythingLLM 现状**：同步粒度偏粗，缺乏增量更新和版本标记。可结合外部工具补足。
- **向量库选型**：Chroma（支持元数据过滤和 upsert）或 Weaviate（内置版本控制概念）。
- **文件监控**：chokidar 跨平台监听 Obsidian vault 变更事件。
- **嵌入模型管理**：记录模型版本号，切换模型时重建索引，避免新旧 embedding 不兼容。
- **自建 MCP/ACP 接口时**：暴露 `get_knowledge_status()` 返回库新鲜度评分和最近更新时间；查询接口增加 `freshness_threshold` 参数，让调用方限定只查最近 N 天的内容。

---

## 结论

文件系统是唯一的真相源，向量库只是需要持续维护的检索缓存。即使只有几百篇笔记，也需要"增量更新 + 时间标记 + 定期清理"的意识。知识库服务应该暴露自身的新鲜度状态，而不是假装自己永远最新。

---

**参考来源**
- "RAG Systems Have a Dirty Secret: Your Context Window is Poisoned" (Reliable Data Engineering, 2026)
- "Data Cascading Risks in RAG Pipelines" (Priyanka Nirmale, 2025)
- "The Knowledge Decay Problem" (David Richards, 2025)
- "How Do RAG Systems Handle Outdated Information?" (Am I Cited, 2025)
- "Why Your Enterprise RAG System Needs Real-Time Vector Database Updates" (David Richards, 2025)
