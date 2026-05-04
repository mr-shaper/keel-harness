# Contributing to keel-harness

Thank you for your interest in contributing. keel-harness enforces a narrow kernel
scope intentionally — please read this guide before opening a PR or issue.

---

## Table of Contents

1. [Before You Start](#before-you-start)
2. [Development Setup](#development-setup)
3. [Running the Test Suites](#running-the-test-suites)
4. [Branch Naming](#branch-naming)
5. [Commit Message Format](#commit-message-format)
6. [Pre-Commit Hook Expectations](#pre-commit-hook-expectations)
7. [PR Review Process](#pr-review-process)
8. [Kernel Scope Policy](#kernel-scope-policy)

---

## Before You Start

- Read `workflows/pua-topology.md` — especially the P8 file-domain isolation rule.
  New hooks must not overlap with existing hook domains.
- Check open Issues before opening a duplicate.
- For any non-trivial change, open an Issue first and confirm scope with a maintainer.
  Scope creep is the enemy of a reusable harness.

---

## Development Setup

**Prerequisites** (install before anything else):

```bash
# 1. Claude Code CLI
# Install from https://claude.ai/code

# 2. superpowers plugin
claude plugin install superpowers@superpowers-marketplace

# 3. PUA plugin
git clone https://github.com/tanweai/pua ~/.claude/plugins/pua

# 4. jq (required by hooks and scripts)
brew install jq              # macOS
sudo apt-get install -y jq   # Debian/Ubuntu

# 5. Verify both plugins are present
ls ~/.claude/plugins/pua/plugin.json
```

**Clone and install:**

```bash
git clone https://github.com/mr-shaper/keel-harness.git
cd keel-harness
bash install.sh
```

`install.sh` Phase 0.5 detects missing prerequisites and aborts early.

---

## Running the Test Suites

Run all five suites from the repo root:

```bash
bash tests/test-install.sh
bash tests/test-manifest-completeness.sh
bash tests/test-pre-commit.sh
bash tests/test-sync.sh
bash tests/test-red-team.sh
```

All five must pass before a PR is considered ready. Paste the raw output
in your PR description — "tests pass" without evidence is not accepted.

Run the Layer 0 health check:

```bash
bash scripts/layer0-health-check.sh
```

---

## Branch Naming

```
<type>/<short-description>
```

Examples:

| Type | Example |
|------|---------|
| `fix` | `fix/stop-hook-next-action-blank` |
| `feat` | `feat/new-romeo-audit-dimension` |
| `docs` | `docs/layer0-spec-clarify` |
| `refactor` | `refactor/handoff-schema-field-rename` |
| `test` | `test/red-team-expand-cases` |

---

## Commit Message Format

keel-harness uses Conventional Commits style:

```
<type>(<scope>): <short summary>

[optional body]

[optional footer]
```

- **type**: `fix` / `feat` / `docs` / `refactor` / `test` / `chore`
- **scope**: affected component, e.g. `hooks`, `scripts`, `plugins`, `docs`, `tests`
- **summary**: imperative, lowercase, ≤72 chars, no period

Examples:

```
fix(hooks): stop hook emits next_action when state is missing
feat(scripts): add layer0 health-check script
docs(contributing): add branch naming section
```

---

## Pre-Commit Hook Expectations

keel-harness ships a pre-commit hook (`hooks/pre-commit`). It runs automatically
on `git commit`. Expect it to:

- Verify manifest completeness (`manifest.json` entries match actual files)
- Run a fast subset of the test suite

If the pre-commit hook fails, **do not bypass with `--no-verify`**. Fix the
underlying issue and recommit.

New hooks you add must:
1. Pass the Layer 0 health check (`layer0-health-check.sh`)
2. Include a corresponding test case in `tests/`
3. Be registered in `manifest.json`

---

## PR Review Process

1. Open a PR against `main` using the PR template.
2. Fill every section — especially **Test Evidence** (paste raw command output).
3. A maintainer will review within **5 business days**.
4. Reviewers will check:
   - File domain isolation (no overlap with other hook domains)
   - Layer 0 health check passes
   - Evidence pasted (not just claimed)
   - Scope alignment with kernel policy
5. Approval requires 1 maintainer review.

---

## Kernel Scope Policy

keel-harness is intentionally narrow. The kernel covers:

- 24h cross-session continuity (handoff files, state)
- Canonical honesty enforcement (Romeo audit, evidence gates)
- P10-9-8-7 nested parallel agent topology enforcement

Features outside this scope belong in a separate plugin or skill, not the kernel.
If unsure, open an Issue labeled `scope-question` before writing code.
