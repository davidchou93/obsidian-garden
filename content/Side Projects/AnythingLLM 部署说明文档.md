---

---
Mac Mini 本地 AI 知识库部署方案

---

## 📋 部署架构

> AnythingLLM (Desktop) → Ollama (Embedding) → Chroma/Qdrant (Vector DB)

## 🧠 Embedding 模型对比


模型 | 大小 | 中文CMTEB | 英文MTEB | 内存占用 | 推荐度
Qwen3-4B 4bit | ~4GB | 72.4 | 73.4 | ~3GB | ⭐⭐⭐⭐⭐ 推荐
Qwen3-0.6B 4bit | ~1.2GB | 71.8 | 70.7 | ~1.5GB | ⭐⭐⭐⭐ 轻量
BGE-large-zh | ~640MB | 72.5 | 68.3 | ~2GB | ⭐⭐⭐ 中文优先

## 🗄️ 向量数据库选择

- Chroma (内置)：零配置，推荐起步使用
- Qdrant：Rust 高性能，适合大规模文档
- LanceDB：嵌入式，无服务器架构

## 📊 空间需求

> AnythingLLM: ~5GB
Ollama + Model: ~2GB
Chroma DB: ~2-5GB
Total: ~10-15GB (当前可用 70GB，完全足够)

## 🎯 最终技术选型确认

> [!success] ✅
> 选定方案：AnythingLLM + Ollama + Qwen3-4B 4bit量化 + Chroma内置向量数据库 + OpenClaw 集成

- Embedding 层：Qwen3-4B 4bit 量化，内存占用3GB，性能8000-10000 tokens/s
- 向量数据库：AnythingLLM 内置 Chroma，零配置，数据存在本地SSD
- LLM 层：保持现有 OpenClaw 外部 API Provider 配置不变，无需改动

## ⚡ 内存优化方案

## 🔗 OpenClaw 集成方案

1. 在 AnythingLLM 中启用开发者 API，端口 3001
2. OpenClaw 需要检索时调用 AnythingLLM 检索 API 获取相关文档片段
3. 把片段拼到 Prompt 中，按原有流程调用现有 LLM API

## ⚠️ 风险控制与备选方案

- 内存不足备选：切换到 Qwen3-0.6B 4bit，内存仅1.5GB，精度损失<1%
- 性能不足备选：切换到 MLX 版本 Qwen3-0.6B，吞吐量提升至44K tokens/s
- 中文精度不足备选：切换到 BGE-large-zh-v1.5，CMTEB 72.5分

> ✅ 部署状态：已完成

📅 部署时间：2026年3月25日
🖥️ 部署环境：Mac Mini (Apple Silicon)

本文档已从部署计划转换为说明文档，记录实际部署配置和使用方法。

---

## ⚙️ 实际部署配置

### 服务信息

- **部署主机**: Mac Mini (Apple Silicon)
- **部署时间**: 2026年3月

### 组件配置

#### 1. AnythingLLM Desktop

- **安装方式**: `brew install --cask anythingllm`
- **Web UI**: http://localhost:3001
- **API 端点**: http://localhost:3001/api
- **配置目录**: `~/.anythingllm/`

#### 2. Embedding 服务 (Ollama)

- **服务端口**: 11434
- **模型**: `qwen3-embed:0.6b`
- **安装方式**: `ollama pull qwen3-embed:0.6b`

#### 3. 本地 LLM 服务 (mlx-lm)

- **服务端口**: 8080
- **模型**: `mlx-community/Qwen3-4B-Instruct-2507-4bit`
- **启动方式**: LaunchAgent (`~/Library/LaunchAgents/com.user.mlxlmserver.plist`)
- **内存占用**: ~894 MB

#### 4. 向量数据库

- **类型**: Chroma (内置)
- **无需额外配置**

### LLM Provider 配置

AnythingLLM 中配置的 LLM Provider 如下：

| 配置项 | 值 |

|--------|-----|

| **Provider** | OpenAI Compatible |

| **Base URL** | `https://api.moonshot.cn/v1` |

| **Model** | `kimi-coding/k2p5` |

| **Context Window** | 131072 |

| **Max Tokens** | 32768 |

### 快速验证命令

# 检查 Ollama 服务

curl http://localhost:11434/api/tags

# 检查本地 LLM 服务

curl http://localhost:8080/v1/chat/completions \

-H "Content-Type: application/json" \

-d '{"model":"local-model","messages":[{"role":"user","content":"Hello"}]}'

# 检查 AnythingLLM API

curl http://localhost:3001/api/v1/workspace \

-H "Authorization: Bearer YOUR_API_KEY"

### 使用说明

4. **上传文档**: 通过 AnythingLLM Web UI 上传文档，自动进行 embedding
5. **创建 Workspace**: 每个知识库对应一个 workspace
6. **API 调用**: 使用 AnythingLLM 的 OpenAI 兼容 API 进行 RAG 查询
7. **OpenClaw 集成**: 可通过 API 同步记忆文件到 workspace

---

*文档更新时间: 2026-03-25*