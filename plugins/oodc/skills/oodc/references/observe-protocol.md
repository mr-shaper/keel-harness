# Observe — 全域观察协议

## 工具路由表（写死，Agent 不需要猜）

| 调研目标 | 工具 | 命令/方式 | 降级方案 |
|---------|------|----------|---------|
| GitHub 生态 | `web-access` skill (CDP Proxy localhost:3456) | 浏览 github.com/search + topic pages + repo README | WebSearch 替代 |
| X/Twitter 社区 | `bird` skill | bird search "{关键词}" | WebSearch site:x.com |
| 深度知识萃取 | `notebooklm` CLI | 完整 NLM 管道（见下方） | Claude 自行分析 + 标注 `[⚠️ 非NLM来源]` |
| iCloud 资产 | Read tool | 读 iCloud 对应业务目录 | — |
| Notion 知识库 | Notion MCP | notion-search → notion-fetch | 跳过 |
| 现有 Skill | ls + Read | `ls ~/.claude/skills/shelf/` → Read SKILL.md | — |
| tacit-kb | kb.py CLI | `python3 ~/.claude/plugins/tacit-kb/scripts/kb.py query "{关键词}" --domain {domain}` | 跳过 |

## 项目类型 × 源清单矩阵

| 源类型 | Skill | MCP | WebApp | CLI | Library | APP |
|--------|-------|-----|--------|-----|---------|-----|
| **GitHub** | 上游 repo + 同类 skill | MCP server 示例 | 竞品 + 框架 | ��类 CLI | 同类包 | 竞品应用 |
| **X/Bird** | skill 创建 tips | MCP 最佳实践 | 框架讨论 | CLI UX 讨论 | API 设计讨论 | 平台开发 |
| **NLM** | 上游 README + 标杆 SKILL.md × 3-5 | 官方文档 + 示例 README | 竞品 URL + 框架 docs | CLI README × 3-5 | 包 README × 5 | 竞品文档 |
| **iCloud** | `05-技能库/` | `04-AI系统/` | `06-调研报告/` | `04-AI系统/` | `04-AI系统/` | 按项目 |
| **Notion** | 相关知识页面 | 相关知识页面 | 相关知识页面 | 相关知识页面 | 相关知识页面 | 相关知识页面 |

**所有类型通用高价值源**：
- `记忆库/教训复盘.md`（同类项目历史踩坑）
- `记忆库/决策日志.md`（同类项目历史决���）
- 现有 NLM notebooks（`notebooklm list` 查看）

## NotebookLM 完整管道

### 步骤 1：找材料

按上方矩阵确定源清单。**目标：slow-loop ≥30 source，大项目 50-100**。

### 步骤 2：创建/复用 Notebook

```bash
notebooklm list                                    # 查现有
notebooklm create "OODC: {项目名} Research" --json  # 新建
notebooklm use {notebook_id}                        # 设上下文
```

### 步骤 3：灌源（3 路）

```bash
# A: 已知 URL（间隔 1-2s）
notebooklm source add "https://github.com/xxx/README.md" --json
notebooklm source add ./local-file.pdf --json

# B: 自动 Web Research
notebooklm source add-research "{领域} best practices 2026" --mode deep --no-wait
notebooklm source add-research "{项目类型} design patterns" --mode deep --no-wait

# C: iCloud/本地文件
notebooklm source add ~/Library/Mobile\ Documents/.../教训复盘.md
notebooklm source add ~/Library/Mobile\ Documents/.../相关文件.md
```

等待处理：
```bash
notebooklm research wait -n {notebook_id} --import-all --timeout 1800
notebooklm source list --json  # 确认全部 status=ready
```

### 步骤 4：结构化提问（6 必问 + 2 按需）

**铁律：所有 ask 加 `--json --save-as-note`**

```bash
# Q1: 约束与限制
notebooklm ask "Based on all sources, what are the top 5 constraints and hard limitations for building a {项目类型} that does {目标}? Distinguish physical/technical hard constraints vs convention/preference soft constraints." --json --save-as-note --note-title "OODC-Q1-Constraints"

# Q2: 反模式
notebooklm ask "What are the 5 most common design anti-patterns in {领域}? For each: what it looks like, why people fall into it, correct approach." --json --save-as-note --note-title "OODC-Q2-AntiPatterns"

# Q3: 现有技术与竞品
notebooklm ask "What existing tools/frameworks/projects already solve parts of {目标}? For each, strengths and gaps." --json --save-as-note --note-title "OODC-Q3-ExistingArt"

# Q4: 集成点
notebooklm ask "What systems/APIs/tools does a {项目类型} for {目标} typically integrate with? Integration risks?" --json --save-as-note --note-title "OODC-Q4-Integration"

# Q5: 效率
notebooklm ask "How can the core value of {目标} be communicated in under 500 words? Essential vs nice-to-have? What defers to references?" --json --save-as-note --note-title "OODC-Q5-Efficiency"

# Q6: 失败模式
notebooklm ask "Top 5 reasons projects like {目标} fail? Early warning sign and prevention for each." --json --save-as-note --note-title "OODC-Q6-FailureModes"

# Q7 (有上游时): 上游策略
notebooklm ask "Comparing upstream with our requirements: accept as-is / customize / build from scratch for each component? Justify." --json --save-as-note --note-title "OODC-Q7-UpstreamStrategy"

# Q8 (面向用户时): 用��心智模型
notebooklm ask "Target user mental model about {领域}? Terminology? Expectations when interacting with {项目类型}?" --json --save-as-note --note-title "OODC-Q8-UserMentalModel"
```

### 步骤 5：提取 Observe 产出

从 NLM 回答中提取结构化摘要：
- 硬约束列表（Q1）
- 必避反模式（Q2）
- 可复用现有技术（Q3）
- 集成风险矩阵（Q4）
- 核心信息蒸馏（Q5）
- 失败预防清单（Q6）
- [按需] 上游 per-file 策略初稿（Q7）
- [按需] 用户期望地图（Q8）

**此摘要是 Orient 的唯一输入** — Claude 不引用原始资料，只引用 NLM 结构化回答。

## NLM 降级方案

| 故障 | 降级 |
|------|------|
| 登录过期 | `notebooklm login` → the user 不在 → Claude 自行分析 + `[⚠️ 非NLM来源]` |
| source add 失败 | 跳过该源，≥15 source 即可继续 |
| research deep 超��� | 切 `--mode fast` → 也失败 → 手动添加 URL |
| ask 质量差 | 追问 `-c {conversation_id}` 要求更具体+引用源 |
| 源数不够 | 补充 Notion MCP + iCloud 文件 + web-access 抓取 |

## 并行 Agent Dispatch 模板

Slow-loop Observe 使用 3 Agent 并行：

```
Agent 1 prompt: "用 web-access skill 浏览 GitHub。搜索: {关键词1}, {关键词2}。
浏览 top 10 repo README。输出≤600词：每个 repo 名+URL+核心想法+对本项目的启发。"

Agent 2 prompt: "用 bird skill 搜索 X/Twitter。搜索: {关键词1}, {关键词2}。
输出≤600词：每条 tweet 作者+内容摘要+对本项目的启发。"

Agent 3 prompt: "RESEARCH TASK — EXECUTE commands, do not plan. 用 notebooklm CLI。
先 notebooklm list 查现有 notebook。然后 create→source add→ask 6 问题。
输出≤600词：notebook ID + source 列表 + 6 个问题的完整回答。"
```

## NLM Agent 4 层防偷懒

**Layer 1 — Prompt 硬编码**: 所有 NLM Agent prompt 以此开头：
`RESEARCH TASK — EXECUTE commands, do not plan. RUN commands, return results. Do NOT say "I will do X". Just DO X.`

**Layer 2 — 返回验证** (4 项全过才接受):
- [ ] Notebook ID (UUID)
- [ ] ≥5 source 已添加
- [ ] ≥6 Q&A 完整回答文本
- [ ] report/mind-map 生成确认

**Layer 3 — Plan Mode 隔离**: 用 `subagent_type: "general-purpose"`。返回 plan 不返回结果 → 重发 + 追加 `THE PREVIOUS AGENT ONLY WROTE A PLAN. RUN COMMANDS.`

**Layer 4 — SendMessage 预加载**: Session 开始 `ToolSearch("select:SendMessage")` 预加载
