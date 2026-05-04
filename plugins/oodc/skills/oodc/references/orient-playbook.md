# Orient — Multi-Perspective Positioning Playbook

## Expert Dynamic Routing Table

Match 2-4 perspective experts based on domain signals from the Observe output. **Hard cap: at most 4**.

| Domain signal | Recommended experts | Rationale |
|---|---|---|
| AI/ML product | karpathy + ilya + naval | Technical reliability + safety + leverage |
| Consumer / growth | mrbeast + jobs + musk | Content + taste + cost |
| Finance / quant | taleb + munger + naval | Risk + multi-model + leverage |
| Content creation | naval + paul-graham + mrbeast | Leverage + writing + growth |
| Infrastructure / tooling | musk + feynman + karpathy | First principles + simplification + reliability |
| Methodology / cognition | feynman + munger + naval | Understanding + pluralism + first principles |
| Education / career | zhangxuefeng + naval + paul-graham | Practical + leverage + insight |
| Business model | zhang-yiming + naval + munger | Distribution + leverage + multi-model |

**Rules**:
- Read the Observe summary → match domain signals → invoke the corresponding experts
- Default when no match: musk + naval + feynman
- Multi-domain crossover: top 1 per domain, cap at 4
- Invocation: `Skill("{perspective-name}")` — instruction: "use only mental models and decision heuristics; skip role-play and voice DNA."

## Assumption Failure-Check Template

First step of Orient: list 3 current assumptions and stress-test them (Boyd "destruction and creation").

```
### Assumption 1: {content}
- Supporting evidence: {data from Observe}
- Counter evidence: {data from Observe or logical reasoning}
- Confidence: high / medium / low
- If wrong: {blast radius and alternatives}

### Assumption 2: ...
### Assumption 3: ...
```

Low-confidence assumptions → mark for verification in Decide or quick-prototype testing in Create.

## PUA P10 Three Questions

After the expert review, do a final P10 review:

1. **Existential anchoring**: Does this project make sense in the user's solo-team portfolio? Does it serve specific user strategy and individual brand?
2. **Idiocy index**: current cost / theoretical minimum cost = ? If the index is >5, there is significant room for optimization.
3. **First question of the five-step algorithm**: Why does this requirement/feature/step exist? Who proposed it? Can it be deleted?

## A-Grade Benchmark Comparison Checklist

Use existing A-grade skills for taste calibration (≥3 must pass for Orient to be complete):

- [ ] **Router-table completeness**: Like design-md, is there a clear mapping from trigger condition → workflow → output artifact?
- [ ] **NEVER list**: Are there ≥5 explicit "do not do" items? (prevents the agent from drifting)
- [ ] **Token efficiency**: Can the core information be conveyed in ≤500 words? (SKILL.md body within limit)
- [ ] **Progressive Disclosure**: Are heavy details correctly layered? (L1 metadata / L2 SKILL.md / L3 references)
- [ ] **Solo-team maintainable**: Can a single person maintain this output? Is the complexity manageable?

## Orient Output Format

Produce a unified summary at Orient close:

```
## Orient summary

### Dominant view (majority consensus among experts)
{1-3 core direction recommendations}

### Minority view (valuable dissent)
{1-2 noteworthy contrarian opinions}

### Synthesized recommendation
{integrated direction based on dominant + minority}

### Confidence
Overall: high / medium / low
Largest uncertainty: {specific area}

### Assumption status update
{which assumptions verified / refuted / still uncertain}
```

## Skill Dispatch Hard Rule

Orient expert review **must** invoke `Skill()` or `Agent()` for real.

| ✅ Correct | ❌ Wrong (12 laziness patterns #1 #2) |
|---|---|
| `Skill("feynman-perspective")` | "From a Feynman perspective..." |
| `Agent(subagent_type="pua:cto-p10")` | "P10 three questions completed inline" |
| `Skill("pua:p10")` actual call | "PUA P10: idiocy index ~5" |

**Sole exception**: Plan Mode disables Skill → use Agent as proxy, tag `[via Agent proxy]`.

## PUA Full Parameter Format

The `pua:` field produced by Orient must include 4 parameters; missing any one = incomplete:

```
pua: flavor=🟠Alibaba | pressure=L2 | redlines=loop-closure+fact-driven+exhaustive | switch_chain=Alibaba→🔴Huawei→⬛Musk
```

## Fast-loop Orient Minimum Checklist (no skipping)

Even in fast-loop, [ORIENT_VERDICT] must contain all fields:
- assumptions: 3 (can be terse)
- experts_invoked: at least 1 inline analysis + framework name, tagged `[⚠️ fast]`
- pua: all 4 parameters (flavor / pressure / redlines / switch_chain)
- pipeline_phases: cite the trim-table to explain which Phases run

**Fast ≠ skip. Fast = condensed but complete.**

## PUA Parameter Glossary
- **flavor**: auto-selected by methodology routing table (or user-specified)
- **pressure**: L1 (first time) / L2 (after 2 failures) / L3 (3) / L4 (5+)
- **redlines**: this checkpoint of the three red lines
- **switch_chain**: switch sequence when current flavor fails
