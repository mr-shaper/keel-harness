# Observe — Full-Domain Observation Protocol

## Tool Routing Table (hard-coded, the agent should not guess)

| Research target | Tool | Command/method | Fallback |
|---|---|---|---|
| GitHub ecosystem | `web-access` skill (CDP Proxy localhost:3456) | Browse github.com/search + topic pages + repo READMEs | WebSearch |
| X/Twitter community | `bird` skill | bird search "{keyword}" | WebSearch site:x.com |
| Deep knowledge extraction | `notebooklm` CLI | Full NLM pipeline (see below) | Inline analysis with `[⚠️ non-NLM source]` tag |
| Local knowledge | Read tool | Read project-relevant local doc directories | — |
| Notion | Notion MCP | notion-search → notion-fetch | Skip |
| Existing skills | ls + Read | `ls ~/.claude/skills/shelf/` → Read SKILL.md | — |
| Knowledge base | kb.py CLI (optional `tacit-kb` plugin) | `python3 ~/.claude/plugins/tacit-kb/scripts/kb.py query "{keywords}" --domain {domain}` | Skip |

## Project Type × Source Matrix

| Source | Skill | MCP | WebApp | CLI | Library | APP |
|---|---|---|---|---|---|---|
| **GitHub** | upstream repo + similar skills | example MCP servers | competitors + frameworks | similar CLIs | similar packages | competitor apps |
| **X/Bird** | skill creation tips | MCP best practices | framework discussions | CLI UX discussions | API design discussions | platform development |
| **NLM** | upstream README + 3-5 reference SKILL.mds | official docs + sample READMEs | competitor URLs + framework docs | 3-5 CLI READMEs | 5 package READMEs | competitor docs |
| **Local** | local skill library | local AI systems notes | local research reports | local AI systems notes | local AI systems notes | per project |
| **Notion** | relevant pages | relevant pages | relevant pages | relevant pages | relevant pages | relevant pages |

**High-value sources for any project type**:
- Local lessons-learned log (past similar-project mistakes)
- Local decision log (past similar-project decisions)
- Existing NLM notebooks (`notebooklm list` to view)

## NotebookLM Full Pipeline

### Step 1: Find sources

Use the matrix above to determine the source list. **Goal: slow-loop ≥30 sources, large project 50-100**.

### Step 2: Create / reuse a notebook

```bash
notebooklm list                                    # check existing
notebooklm create "OODC: {project name} Research" --json  # new
notebooklm use {notebook_id}                        # set context
```

### Step 3: Add sources (3 paths)

```bash
# A: Known URLs (interval 1-2s)
notebooklm source add "https://github.com/xxx/README.md" --json
notebooklm source add ./local-file.pdf --json

# B: Auto Web Research
notebooklm source add-research "{domain} best practices 2026" --mode deep --no-wait
notebooklm source add-research "{project type} design patterns" --mode deep --no-wait

# C: Local files
notebooklm source add ~/path/to/lessons-learned.md
notebooklm source add ~/path/to/related-file.md
```

Wait for processing:
```bash
notebooklm research wait -n {notebook_id} --import-all --timeout 1800
notebooklm source list --json  # confirm all status=ready
```

### Step 4: Structured questions (6 mandatory + 2 optional)

**Iron rule: every `ask` must include `--json --save-as-note`**

```bash
# Q1: Constraints and limits
notebooklm ask "Based on all sources, what are the top 5 constraints and hard limitations for building a {project type} that does {goal}? Distinguish physical/technical hard constraints vs convention/preference soft constraints." --json --save-as-note --note-title "OODC-Q1-Constraints"

# Q2: Anti-patterns
notebooklm ask "What are the 5 most common design anti-patterns in {domain}? For each: what it looks like, why people fall into it, correct approach." --json --save-as-note --note-title "OODC-Q2-AntiPatterns"

# Q3: Existing art and competitors
notebooklm ask "What existing tools/frameworks/projects already solve parts of {goal}? For each, strengths and gaps." --json --save-as-note --note-title "OODC-Q3-ExistingArt"

# Q4: Integration points
notebooklm ask "What systems/APIs/tools does a {project type} for {goal} typically integrate with? Integration risks?" --json --save-as-note --note-title "OODC-Q4-Integration"

# Q5: Efficiency
notebooklm ask "How can the core value of {goal} be communicated in under 500 words? Essential vs nice-to-have? What defers to references?" --json --save-as-note --note-title "OODC-Q5-Efficiency"

# Q6: Failure modes
notebooklm ask "Top 5 reasons projects like {goal} fail? Early warning sign and prevention for each." --json --save-as-note --note-title "OODC-Q6-FailureModes"

# Q7 (when there is upstream): upstream strategy
notebooklm ask "Comparing upstream with our requirements: accept as-is / customize / build from scratch for each component? Justify." --json --save-as-note --note-title "OODC-Q7-UpstreamStrategy"

# Q8 (when user-facing): user mental model
notebooklm ask "Target user mental model about {domain}? Terminology? Expectations when interacting with {project type}?" --json --save-as-note --note-title "OODC-Q8-UserMentalModel"
```

### Step 5: Extract Observe output

Distill structured summary from NLM answers:
- Hard constraints list (Q1)
- Anti-patterns to avoid (Q2)
- Reusable existing art (Q3)
- Integration risk matrix (Q4)
- Core information distillation (Q5)
- Failure prevention checklist (Q6)
- [optional] Upstream per-file strategy draft (Q7)
- [optional] User expectation map (Q8)

**This summary is the only input to Orient** — Claude does not cite raw sources, only the NLM structured answers.

## NLM Fallback Plan

| Failure | Fallback |
|---|---|
| Login expired | `notebooklm login` → user not present → Claude analyzes inline + `[⚠️ non-NLM source]` |
| `source add` failed | Skip that source, ≥15 sources is enough to proceed |
| `research deep` timed out | Switch to `--mode fast` → if also fails → manually add URLs |
| Poor `ask` quality | Follow up with `-c {conversation_id}` requesting more specifics + source citations |
| Insufficient sources | Supplement with Notion MCP + local files + web-access scrape |

## Parallel Agent Dispatch Template

Slow-loop Observe uses 3 agents in parallel:

```
Agent 1 prompt: "Use the web-access skill to browse GitHub. Search: {kw1}, {kw2}.
Browse the top-10 repo READMEs. Output ≤600 words: each repo name + URL +
core idea + implication for our project."

Agent 2 prompt: "Use the bird skill to search X/Twitter. Search: {kw1}, {kw2}.
Output ≤600 words: each tweet's author + content summary + implication for our project."

Agent 3 prompt: "RESEARCH TASK — EXECUTE commands, do not plan. Use the notebooklm CLI.
First `notebooklm list` to view existing notebooks. Then create → source add → ask 6 questions.
Output ≤600 words: notebook ID + source list + complete answers to the 6 questions."
```

## NLM Agent 4-Layer Anti-Laziness

**Layer 1 — Hard-coded prompt**: Every NLM agent prompt opens with:
`RESEARCH TASK — EXECUTE commands, do not plan. RUN commands, return results. Do NOT say "I will do X". Just DO X.`

**Layer 2 — Return verification** (all 4 must pass to accept):
- [ ] Notebook ID (UUID)
- [ ] ≥5 sources added
- [ ] ≥6 Q&A complete answer text
- [ ] report/mind-map generation confirmed

**Layer 3 — Plan Mode isolation**: Use `subagent_type: "general-purpose"`. Returns a plan instead of results → re-dispatch + append `THE PREVIOUS AGENT ONLY WROTE A PLAN. RUN COMMANDS.`

**Layer 4 — SendMessage preload**: At session start, run `ToolSearch("select:SendMessage")` to preload.
