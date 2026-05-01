# License Compatibility Audit — harness-engineering OSS v0.1.0

**Date**: 2026-05-01  
**Auditor**: P8-η (B3 钦定, W1 Day 2)  
**Our License**: Apache-2.0 (declared in README.md; LICENSE file not yet committed — action item)  
**Scope**: All deps that touch our redistribute boundary

---

## 段 1: 兼容性矩阵

| 名称 | 版本 | License | 我们的关系 | Apache-2.0 兼容? | 风险 | 修法 |
|------|------|---------|-----------|-----------------|------|------|
| **harness-engineering (我们)** | 0.1.0 | Apache-2.0 (planned) | D 直发 — our code | — | 低 | 补 LICENSE 文件 (action) |
| **sync.sh / hooks/*.sh** | — | Apache-2.0 (我们自写) | D 直发 — our code | 是 | 无 | — |
| **install.sh** | — | Apache-2.0 (我们自写) | D 直发 — our code | 是 | 无 | — |
| **superpowers (Jesse Vincent)** | marketplace | MIT | A fork / optional install | 是 | 无 | LICENSE file confirmed: MIT, copyright Jesse Vincent |
| **PUA plugin (tanweai)** | 5.x | MIT | B optional (`--with-pua`) | 是 | 无 | LICENSE confirmed: MIT (plugin.json + README badge); we do not redistribute, user self-installs |
| **tacit-kb (Maintainer 私造)** | — | UNDECLARED | B optional (`--with-tacit-kb`) | 未知 | 中 | 见段 3 |
| **docsync-v3-mp (Maintainer 私造)** | — | UNDECLARED | B optional | 未知 | 中 | 见段 3 |
| **compound-selfcheck-plugin (Maintainer 私造)** | — | MIT | B optional (sub-plugin of docsync) | 是 | 无 | plugin.json author Maintainer, license MIT |
| **oodc plugin (Maintainer 私造)** | — | UNLICENSED | B optional | 未知 | 中 | 见段 3 |
| **claude-mem (thedotmack / Alex Newman)** | 12.0.1 | **AGPL-3.0** | B optional (`--with-claude-mem`) | **否** | **高** | 见段 2 |
| **bash** | 3.2.57 (macOS) | GPL-2.0 (macOS BSD) | runtime — OS-bundled | — | 无 | OS standard, not redistributed |
| **git** | 2.50.1 (Apple Git) | LGPL-2.1 | runtime — OS-bundled | — | 无 | OS standard, not redistributed |
| **jq** | 1.7.1 | MIT | runtime — user installs | 是 | 无 | MIT confirmed |
| **sed** | BSD (macOS) | BSD | runtime — OS-bundled | — | 无 | OS standard |
| **shellcheck** | 0.11.0 | GPL-3.0-or-later | CI/dev tooling only | — | 低 | Dev tool only, not redistributed in kernel |
| **GitHub Actions** | — | MIT (actions/checkout etc.) | CI pipeline | 是 | 无 | Standard marketplace actions; Apache-2.0 compatible |

---

## 段 2: GPL/AGPL 命中清单

| 名称 | License | 命中类型 | 我们的关系 | 风险等级 | 修法 |
|------|---------|---------|-----------|---------|------|
| **claude-mem** | **AGPL-3.0** | AGPL 命中 | B optional — install.sh `--with-claude-mem` flag 引导用户从源仓自装 | **高** | **P9 决策点**: 我们不直接 redistribute claude-mem 二进制/源码。但 install.sh 若主动 `git clone` / `npm install` claude-mem → 可能触发 AGPL 传染链。修法: install.sh 仅打印"参见 https://github.com/thedotmack/claude-mem (AGPL-3.0) 请用户自行安装"; 不在脚本内 exec clone/install。需 P9 钦定措辞。 |
| **shellcheck** | GPL-3.0-or-later | GPL-3 命中 | Dev/CI 工具 — 用户本地安装; 我们不打包 | 低 | 仅 CI 使用, 不随 kernel 分发, 无污染风险 |

> **结论**: 实质 AGPL 传染风险仅 1 处 = claude-mem。shellcheck 为纯 dev/CI 工具, 不传染。kernel 代码 (sync.sh / hooks/*.sh / install.sh) 本身无 GPL/AGPL 引入。

---

## 段 3: UNDECLARED License 清单 + P9 决策建议

| 名称 | 实际归属 | 调查结论 | P9 决策建议 |
|------|---------|---------|------------|
| **tacit-kb** | Maintainer 私造 | 无 LICENSE 文件, 无 plugin.json 声明. 完全 Maintainer 自有代码 | 建议: (a) 在 install.sh 中标注 "private plugin, no public repo" 不对外提供安装路径; OR (b) Maintainer 补 MIT/Apache-2.0 声明后 optional install 可打 link。P9 钦定选 (a) 或 (b). |
| **docsync-v3-mp** | Maintainer 私造 | 仅含 compound-selfcheck-plugin (MIT, Maintainer). 顶层无 LICENSE 文件 | 同 tacit-kb: 建议 (a). docsync 为内部工作流, 不对外 optional install 是 safe default. |
| **oodc** | Maintainer 私造 | plugin.json `"license": "UNLICENSED"` — 显式 UNLICENSED | 建议: 不在 install.sh 提供 oodc optional install 路径, 标注 "internal plugin"; OR Maintainer 补 Apache-2.0 声明. P9 决策前保持 UNLICENSED = 不分发. |

---

## 段 4: 总体 Verdict

**NEEDS_DECISION**

理由:
1. **Apache-2.0 kernel (D 直发)**: PASS — 我们自写代码完全 Apache-2.0 兼容。
2. **superpowers (A)**: PASS — MIT 兼容 Apache-2.0。
3. **PUA (B optional)**: PASS — MIT; 我们不 redistribute, 用户自装。
4. **claude-mem (B optional)**: **NEEDS_DECISION** — AGPL-3.0。install.sh 实现方式决定是否污染。若仅打印 URL 提示用户手动装 → PASS。若 `git clone` / `npm install` → 需重新评估传染链。**P9 必须在 W3 install.sh 实现前钦定 claude-mem 安装方式。**
5. **Maintainer 私造 plugins (tacit-kb / docsync / oodc)**: **NEEDS_DECISION** — UNDECLARED。三个选项全部安全, 但需 P9 钦定: 不提供安装路径 (safe) OR Maintainer 补 license 声明。
6. **补 LICENSE 文件**: Apache-2.0 LICENSE 文件尚未提交到 repo — 需 W1 内补上。

---

## 段 5: 复 Audit 计划

| 时间节点 | 触发条件 | 复 Audit 范围 |
|---------|---------|-------------|
| **W3 install.sh 实现前** | claude-mem 安装方式确定后 | 重新评估 AGPL-3.0 传染链 |
| **W4 red-team test** | 5 层隐私防护测试 | 顺带验证 license 注释/声明无私人信息泄漏 |
| **W6 cross-platform dry-run** | macOS + Linux cross-verify | 重跑本 audit checklist; 验证 runtime tooling (bash/git/jq) 版本 + license 无变化 |
| **pre-launch W7** | GitHub 公开前最终确认 | 全量 license 扫描: `grep -r "GPL\|AGPL" kernel/` 确保 kernel 代码无污染 |

---

*Audit 依据真值来源: `~/.claude/plugins/marketplaces/thedotmack/LICENSE` (AGPL-3.0) / `~/.claude/plugins/marketplaces/superpowers-marketplace/LICENSE` (MIT) / `~/.claude/plugins/pua/plugin.json` (MIT) / `~/.claude/plugins/docsync-v3-mp/plugins/compound-selfcheck-plugin/plugin.json` (MIT) / `~/.claude/plugins/oodc/plugin.json` (UNLICENSED) / `brew info shellcheck` (GPL-3.0-or-later) / `~/.claude/plugins/marketplaces/thedotmack/package.json` (AGPL-3.0 v12.0.1)*

