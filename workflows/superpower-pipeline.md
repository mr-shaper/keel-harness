---
type: workflow
domain: ai-systems
name: Superpower Pipeline — Complete Engineering Pipeline
description: Strategy Lead Work Mode. Complete Phase 0-4 flow for complex engineering projects from zero to release. Orchestrates existing Workflows + Superpowers; no new agent roles are created.
created: 2026-01-01
confidence: 0.9
stale: false
last_ingested: 2026-04-30T00:00:00Z
---

# Superpower Pipeline — Complete Engineering Pipeline

> Strategy Lead Work Mode. Read this file when kicking off a complex engineering project and follow the steps in order.
> Core principle: **Orchestrate existing Workflows + Superpowers. Do not invent new agent roles.**

## Trigger

Activate SUPERPOWER / complete engineering pipeline / follow standard process / run full pipeline / "build a X" (large project)

## Applicability

- New product / app / skill / MCP / WebApp / CLI starting from scratch → ✅ Run Pipeline
- Cross-module refactor (affecting 3+ files) → ✅ Run Pipeline
- Small change (<3 steps) → ❌ Handle inline directly
- Pure research / content work → ❌ Use research/content mode instead

---

## Phase 0: Kickoff

Confirm the **5 Project Elements** (ask the user or accept if already provided):

| Element | Required | Example |
|---------|----------|---------|
| Project name | ✅ | my-tool |
| One-liner goal | ✅ | What problem does it solve? |
| Type | ✅ | Skill / MCP / WebApp / CLI / Library / APP |
| Target directory | ✅ | $CLAUDE_HOME/../path/to/project |
| Visibility | As needed | public / private |

Then:
1. Check the type trim table to determine which phases to execute
2. `TaskCreate` all phase tasks (for tracking)
3. Create the project directory structure

---

## Phase 1: Exploration (⚡ 3 Agents in parallel)

Use `superpowers:dispatching-parallel-agents` or launch 3 Tasks in parallel directly:

| Task Agent | Core prompt | Referenced workflow | Output |
|------------|-------------|---------------------|--------|
| Agent A: Requirements | brainstorming → user personas, pain points, MVP scope, user stories | workflows/product.md | docs/PRD.md |
| Agent B: Research | competitive analysis, tech stack recommendations, risk assessment, key challenges | workflows/research.md | docs/RESEARCH.md |
| Agent C: Architecture | module breakdown, data models, interface definitions, 2-3 alternative designs | workflows/architect.md | docs/ARCHITECTURE.md |

**Agent prompt template**:
```
You are {role}. Project: {name}, goal: {one_liner}, type: {type}.
Follow the output format in workflows/{mode}.md.
Write output to {project_dir}/docs/{output_file}.
Constraint: solo maintainer, MVP ≤ 3 core features.
```

---

## Phase 2: Decision Convergence

1. Strategy Lead reads all three docs/ outputs
2. Identify conflicts and dependencies (PRD requirements vs. architecture feasibility vs. research risks)
3. **superpowers:writing-plans** → output a modular implementation plan
4. User approval required (must wait for explicit sign-off before entering Phase 3)

**Quality gates**:
- [ ] PRD has a clear "what we are NOT building" section
- [ ] Architecture includes 2-3 alternatives with a recommended option and rationale
- [ ] Implementation plan has a module topological order (what comes first)
- [ ] Solo maintainer constraints accounted for (maintenance cost, complexity)

---

## Phase 3: Development

**superpowers:executing-plans** takes over, automatically including the following pipeline:

```
superpowers:executing-plans
  ├─ superpowers:test-driven-development   (tests before implementation, per module)
  ├─ superpowers:code-reviewer             (review at each checkpoint)
  └─ superpowers:verification-before-completion (verify before marking module done)
```

**Development principles**:
1. Skeleton first — project structure, config files, entrypoints
2. Core modules → dependent modules (follow topological order)
3. Module done = tests pass + review pass
4. No hardcoded secrets; follow existing code style

**Parallel development**: use `superpowers:subagent-driven-development` for independent modules

---

## Phase 4: Wrap-Up

1. **superpowers:verification-before-completion** — full end-to-end verification
2. **README.md** + **CHANGELOG.md** — project documentation
3. **doc-sync** — sync affected system docs (DOC_GUIDE, etc.)
4. **Memory** — record key decisions and lessons learned
5. Git tag / GitHub release (as needed)
6. Notify owner with completion summary + acceptance checklist

---

## Project Type Trim Table

| Type | Phase 1 | Phase 2 | Phase 3 | Phase 4 Special |
|------|---------|---------|---------|-----------------|
| **Skill** | Lightweight (skip competitive research) | ✅ | ✅ + TDD | shelf deploy + CSO description |
| **MCP Server** | ✅ Full | ✅ | ✅ + TDD | MCP registration + settings.json |
| **WebApp** | ✅ Full | ✅ | ✅ | Deploy + domain |
| **CLI Tool** | Lightweight | ✅ | ✅ | npm publish / bin config |
| **Library** | ✅ Full | ✅ | ✅ + TDD focused | npm publish + API docs |
| **APP** | ✅ Full | ✅ | ✅ | Platform-specific release |
| **Refactor** | Skip | ✅ Plan directly | ✅ | Regression testing emphasis |

---

## Launch Template

```
Activate SUPERPOWER mode.
Project: {name}
Goal: {one_liner}
Directory: {path}
Type: Skill / MCP / WebApp / CLI / Library / APP
```

---

## Output Structure

```
{project}/
├── docs/
│   ├── PRD.md
│   ├── RESEARCH.md
│   └── ARCHITECTURE.md
├── src/
├── tests/
├── README.md
├── CHANGELOG.md
└── {config files}
```

---

## References

- **Superpowers**: brainstorming, writing-plans, executing-plans, dispatching-parallel-agents, subagent-driven-development, test-driven-development, code-reviewer, verification-before-completion
- **Workflows**: product.md, research.md, architect.md
- **Skills**: doc-sync, skill-creator (for Skill projects), mcp-builder (for MCP projects)
