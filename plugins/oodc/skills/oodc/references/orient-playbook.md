# Orient — 多视角定位手册

## ��家动态路由表

按 Observe 输出的域信号匹配 2-4 位大师。**硬上限：最多 4 位**。

| 内容域信号 | 推荐大师 | 理由 |
|-----------|---------|------|
| AI/ML 产品 | karpathy + ilya + naval | 技术可靠性 + 安全 + 杠杆 |
| 消费应用 / 增长 | mrbeast + jobs + musk | 内容 + 品味 + 成本 |
| 金融 / 量化 | taleb + munger + naval | 风险 + 多元模型 + 杠杆 |
| 内容创作 | naval + paul-graham + mrbeast | 杠杆 + 写作 + ��长 |
| 基础设施 / 工具 | musk + feynman + karpathy | ��一性 + 简化 + 可靠 |
| 方法论 / 认知 | feynman + munger + naval | 理解 + 多元 + 第一性 |
| 教育 / 职业 | zhangxuefeng + naval + paul-graham | 实操 + 杠杆 + 洞察 |
| 商业模式 | zhang-yiming + naval + munger | 分发 + 杠杆 + 多元 |

**规则**：
- CTO 读 Observe 摘要 → 匹配域信号 → 调用对应大师
- 不匹配时默认：musk + naval + feynman
- 多域交叉时：每域 top 1，上限 4 位
- 调用方式：`Skill("{perspective-name}")` — 指示"只用心智模型和决策启发式分析，跳过角色扮演和表达DNA"

## 假设失效检查模板

Orient 第一步：列出 3 个当前假设并检验（Boyd "破坏与创造"）。

```
### 假设 1: {假设内容}
- 支撑证据: {来自 Observe 的数据}
- 反驳证据: {来自 Observe 的数据或逻辑推理}
- 置信度: 高/中/低
- 如果错了: {影响范围和备选方案}

### 假设 2: ...
### 假设 3: ...
```

低置信度假设 → 标记需要在 Decide 中验证或在 Create 中快速原型测试。

## PUA P10 复盘三问

大师会诊后，用 P10 视角做最终审视：

1. **存在主义锚定**：这个项目在 the user solo team的版图中有意义吗？它是否服务于 specific user strategy and individual brand？
2. **白痴指数**：当前做法的"成本" / 理论最低"成本" = ？如果指数 >5，有大幅优化空间。
3. **五步算法第一问**：这个需求/功能/步骤为什么存在？谁提出的？能不能删掉？

## A-grade benchmark 标杆对比清单

拿现有 A 级 Skill 做品味校准（≥3 项全过才算 Orient 完成）：

- [ ] **Router 表完整性**：是否像 design-md 一样有清晰的触发条件 → 工作流 → 输出物映射？
- [ ] **NEVER 禁忌**：是否有 ≥5 条明确的"不做什么"？（防止 Agent 走歪路）
- [ ] **Token 效率**：核心信息能否在 ��500 词内传达？（SKILL.md body 不超限）
- [ ] **Progressive Disclosure**：重信息是否正确分层？（L1 metadata / L2 SKILL.md / L3 references）
- [ ] **一人团队可维护**：the user 一个人能维护这个产出吗？复杂度是否可控？

## Orient 输出格式

Orient 完成后输出统一摘要：

```
## Orient 摘要

### dominant view 主流观点（多数大师共识）
{1-3 条核心方向建议}

### minority view 少数派观点（有价值的异见）
{1-2 条值得注意的���同看法}

### 综合建议
{基于主流+少数派合成的推荐方向}

### 置信度
整体: 高/中/低
最大不确定性: {具体哪个方面}

### 假设状态更新
{哪些假设被验证/推翻/仍不确定}
```

## Skill 调度强制规则

Orient 专家会诊**必须**用 `Skill()` 或 `Agent()` 实际调用。

| ✅ 正确 | ❌ 错误（12 种偷懒 #1 #2） |
|---------|--------------------------|
| `Skill("feynman-perspective")` | "从费曼的角度来看..." |
| `Agent(subagent_type="pua:cto-p10")` | "P10 三问已内联完成" |
| `Skill("pua:p10")` 实际调用 | "PUA P10: 白痴指数约 5" |

**唯一例外**: Plan Mode 下 Skill 不可用 → 用 Agent 代理，标注 `[via Agent 代理]`。

## PUA 完整参数格式

Orient 产出的 `pua:` 字段必须包含 4 个参数，缺任何一个 = 不完整：

```
pua: 味道=🟠阿里 | 压力=L2 | 红线=闭环验证+事实驱动+穷尽一切 | 切换链=阿里→🔴华为→⬛Musk
```

## Fast-loop Orient 最低清单（不可跳过）

即使 fast-loop，[ORIENT_VERDICT] 仍必须包含所有字段：
- assumptions: 3 个（可简短）
- experts_invoked: 至少 1 个内联分析 + 框架名，标注 `[⚠️ fast]`
- pua: 4 参数全写（味道/压力/红线/切换链）
- pipeline_phases: 引用裁剪表说明哪些 Phase 执行

**Fast ≠ 跳过。Fast = 精简但完整。**

## PUA 参数说明
- **味道**: 方法论路由表自动选择（或用户指定）
- **压力**: L1(首次)/L2(2次失败后)/L3(3次)/L4(5次+)
- **红线**: 三条红线的本次检查点
- **切换链**: 当前味道失败后的切换序列
