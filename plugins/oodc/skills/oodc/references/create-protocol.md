# Create — 闭环交付协议

## RED-GREEN-REFACTOR 严格顺序

### RED 阶段：先写失败测试

写 5 个压力测试场景，**不加载目标 skill**，观察 Agent 自然行为：

| # | 测试场景 | 组合压力 | 观察目标 |
|---|---------|---------|---------|
| 1 | "快速帮我做一个 X" | 时间压力 + 简单感 | 是否跳 Observe 直接写代码 |
| 2 | 给一个技术方案请求评估 | 权威 + 沉没成本 | 是否只用一个框架评估 |
| 3 | 中途改变关键决策 | 已有工作量 + 改动成本 | 是否全文更新 Plan |
| 4 | "帮我调研 GitHub 上的竞品" | 工具选择模糊 | 是否用 web-access 而非 WebSearch |
| 5 | Agent 写完后 | 疲劳 + 完成感 | 是否跳 KB/doc-sync/skill-check |

每个场景记录：
- Agent 做了什么选择
- 用了什么合理化借口（逐字记录）
- 哪些压力导致了违反

### GREEN 阶段：写最小 skill

只针对 RED 中观察到的**具体**失败写内容：
- 哪个合理化借��� → SKILL.md 中对应的 Red Flag
- 哪个跳步行为 → SKILL.md 中对应的硬门禁
- 哪个工具猜测 → observe-protocol 中对应的写死路由

有上游时：**先全量导入，再逐文件按 .upstream.json 策略魔改**。不预判删除。

### REFACTOR 阶段：堵漏洞

1. 重新运行 5 个 RED 场景（**加载 skill**），验证全部通过
2. Agent 找到新合理化借口 → 加入 Red Flags
3. 知识注入：从 NLM 答案中提��关键约束写入 skill
4. 运行结构验证：
   ```bash
   # Skill 类型项目
   python3 ~/.claude/skills/shelf/skill-creator/scripts/quick_validate.py \
     ~/.claude/plugins/oodc/skills/oodc/SKILL.md
   ```

## 8 项闭环清单

**全部通过才算完成**：

- [ ] RED 测试全部通过（5/5 场景 Agent 行为正确）
- [ ] SKILL.md ≤500 词（`wc -w` 验证 body，不含 frontmatter）
- [ ] frontmatter description 包含所有触发条件
- [ ] references 只有一层深（无 references 引用 references）
- [ ] Plugin 注册正确（installed_plugins.json 更新 + 重启验证）
- [ ] tacit-kb routing profile 更新（`kb.py extract --write --domain skills`）
- [ ] doc-sync 执行（DOC_GUIDE + SELFCHANGELOG + 04-AI系统 README）
- [ ] Claude-Mem 记录【决策】（`save_memory` title="【决策】OODC Plugin v1.0" importance="critical"）

## 记忆库 AI 草拟（项目完成时必做）

AI 草拟 + 推荐文件，the user 只做 approve/skip：

| 信号 | 文件 | 格式 |
|------|------|------|
| 架构决策 | 记忆库/决策日志.md | `## [日期] {项目名} — {决策}` |
| 踩坑/失败 | 记忆库/教训复盘.md | `## [日期] {项目名} — {教训}` |
| 认知转变 | 记忆库/关键洞察.md | `## [日期] {项目名} — {洞察}` |

路径: `~/Library/Mobile Documents/com~apple~CloudDocs/AI/Claude/记忆库/`

流程:
1. AI 生成 2-3 行草稿
2. 输出: "→ 推荐写入：记忆库/{文件}.md\n{草稿}\nthe user: approve / skip / 改写？"
3. approve → Read 文件 → 追加末尾
4. skip → 跳过

## Orient review 复查（Create 阶段第二次大师会诊）

交付前，调用 1-2 位大师做质量审查：

```
��题: "审视这个 {项目类型} 的最终产出。
1. 有什么明显的盲点？
2. 从你的框架看，最大的风险是什么？
3. 如果只能改一个地方，改哪里？"
```

大师选择：从 Orient 阶段使用的大师中选最相关的 1-2 位。

## OODC 自更新提示

Create 执行完成后，回顾本次 OODC 循环：

1. 流程中哪一步最费时？能否优化？
2. 哪个 reference 文件最常被加载？能否将高频内容上移到 SKILL.md？
3. 哪些 Red Flags 命中了？是否需要新增？
4. NLM 查询模板是否覆盖了本次需要的所有角度？

如有发现 → 记录到 Claude-Mem `【发现】OODC 自更新: {具体改进}`，下次更新 OODC 时批量处理。

## Evidence 强制规则（12 种偷懒 #9 #11）

**"全部通过"文字断言 = INVALID。** 必须 paste 命令 stdout。

| 正确 | 错误 |
|------|------|
| `$ wc -w SKILL.md` → `427` | "词数已验证通过" |
| `$ kb.py status` → `skills 81本...` | "KB 已更新" |
| `$ ls ~/.claude/plugins/oodc/` → [文件列表] | "文件结构正确" |

## 安装 ≠ 录入检测（12 种偷懒 #11）

任何新 skill/tool/plugin 安装后，Create 闭环必须检查:
- [ ] **shelf 体系**: 是否注册到 shelf/ 或 plugins/?
- [ ] **KB 域**: `kb.py ingest` + `compile` + `skill-routes --rebuild`?
- [ ] **upstream 追踪**: 有上游的是否有 .upstream.json?

缺任何一项 = "只做表面"，闭环不完整。

## 状态文件清理

Create 闭环最后一步（所有 evidence 确认后）:
```bash
rm ~/.claude/.oodc-state-{project}  # 删除本 session 的状态文件，不影响其他 session
```
