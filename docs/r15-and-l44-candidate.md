# R15 three-piece pattern + L44 candidate

> A long-running harness project tends to accumulate one big "live" file
> (`PROJECT_STATE.md`) that everyone touches and no one prunes. R15 is the
> meta-rule that keeps that file from becoming a tar pit; L44 is the
> harness-side candidate law that requires the rule be enforced in code,
> not just intent.

## R15 — the three-piece pattern for a "backbone" file

Any file that the harness uses as a long-running project backbone (today:
`PROJECT_STATE.md`) must ship with **three coordinated pieces**:

1. **Inline size contract**. The file declares its own limits at the top —
   typically as an HTML comment plus a `size-contract:` block in frontmatter:

   ```markdown
   <!-- BACKBONE-FROZEN sN | size-contract: ≤200 LOC ≤25k bytes | alert-threshold: 180 LOC | canonical-md5: <hash> | last-touched: YYYY-MM-DD -->
   ```

   The contract is part of the file, not a side document — readers and
   tooling both see the limit at first read.

2. **Forcing-function hook**. A PostToolUse hook
   (`hooks/post-tool-project-state-size-gate.sh`) inspects the file after
   every Write/Edit/MultiEdit and emits `[SIZE-GATE-ALERT]` to stderr
   (plus `alert.log` and `hook-trace.log`) once the alert threshold is
   crossed. The hook is alert-only — it never exits non-zero — so the user
   is informed but never blocked. (The non-blocking behaviour is L43
   compliance: a backbone-discipline alert is not a security gate.)

3. **Canonical md5 baseline**. The known-good size of the file — the
   contract's "this is what the backbone should look like at sprint N" —
   is captured as `canonical-md5: <hash>` in the inline contract and
   restated in `patterns/decisions/` whenever the baseline shifts. The
   md5 is a cheap drift-detection anchor: if the live md5 ever stops
   matching the captured baseline outside an authorised collapse, the
   contract has drifted silently.

## L44 candidate (Cat-H freeze-period reference)

In Cat-H rule terms (see `HARNESS_BIBLE.md §9`):

> **L44 (candidate)**: any file the harness designates as a project
> backbone must enforce its size contract through a forcing-function hook,
> not through documented intent alone.

This is a *candidate* — the harness is currently in v1.13 freeze, so no
new Cat-H law is being ratified. L44 captures the rule for future
ratification once the freeze lifts. Until then, R15 (the rule) plus the
three-piece implementation (the practice) are the operational form.

## Why the three pieces have to coexist

Each of the three pieces alone fails:

- **Contract without a hook**: documented but unenforced. The harness's own
  history shows backbone files routinely outgrowing their stated limits
  when there is no enforcement loop.
- **Hook without a contract**: enforced but unmotivated. A reader of the
  file does not see the limit and assumes the alert is arbitrary.
- **Contract + hook without a baseline**: enforced *now* but no anchor
  against which to detect silent drift later.

The three pieces together create a closed loop: the file declares its own
limit, the hook enforces it, and the baseline records the limit's
historical truth.

## Sibling rules

R15 sits next to a small family of harness backbone-discipline rules:

- **L23**: project state may not be invented from session memory; it must
  read from `PROJECT_STATE.md` or fail.
- **L31**: `CLAUDE.md` revisions go through the six-dimension audit before
  ratification.
- **L41**: a file's canonical md5 is the contract's anchor; "the same file
  with a different md5" is a drift signal worth surfacing.
- **L43**: hook matchers in `settings.json` must be literal whitelists,
  never `*`. (R15's hook ships with a `Write|Edit|MultiEdit` matcher for
  this reason.)

R15 also pairs with the alpha.5/6 PCT-gate rule R12, third constraint:
*the hook must be observed firing in a fresh terminal before the fix is
considered shipped*. R15's forcing-function hook gives R12 something
concrete to verify against on the backbone-discipline side.

## How to apply R15 to a new backbone file

If a future harness component declares a new "backbone" file (a file that
will be touched across many sprints by many actors), the cheap recipe is:

1. Add an HTML-comment `BACKBONE-FROZEN` line and a `size-contract:`
   frontmatter block at the top (see `templates/PROJECT_STATE.md.template`).
2. Write a sibling `post-tool-<file>-size-gate.sh` matching the structure
   of `post-tool-project-state-size-gate.sh` (alert-only, exit 0 always,
   matcher whitelist).
3. Register the hook in `templates/settings.json.template` with an
   explicit `Write|Edit|MultiEdit` matcher (never `*`).
4. Commit the initial file's md5 as the canonical baseline in the
   contract.

## Cross-reference

- Hook: `hooks/post-tool-project-state-size-gate.sh`
- Backbone template: `templates/PROJECT_STATE.md.template`
- Sprint-history convention: `docs/sprint-history-spec.md`

---

# R16 three-piece pattern + L45 candidate (alpha.8 NEW, sibling R15)

## R16 — the three-piece pattern for a "must-ask" gate on a restricted file pattern

R15 governs *backbone* files — files that already exist and grow over time.
R16 is its sibling for *restricted* files — files that should not be written
at all without explicit user ratify. The first instance is the harness's
`handoff-sN-to-sN+1.md` family.

The three coordinated pieces:

1. **PreToolUse hook with a literal whitelist matcher and a regex filter**.
   The hook registers under `Write|Edit|MultiEdit` (never `*`, per L43) and
   filters the target path internally with an anchored regex
   (`handoff-s[0-9]+-to-s[0-9]+\.md$`) so the work is proportional. Outside
   the regex match the hook is a silent pass-through.

2. **Multiple exempt paths**. A blocking gate with no escape is a foot-gun.
   R16 requires at least:
   - A first-class auto-exempt for the legitimate originator (here:
     `HARNESS_HANDOFF_VIA_STOP=1`, set by the Stop hook itself).
   - A user-set env flag for a known-intentional bypass
     (`HARNESS_HANDOFF_USER_OK=1`).
   - A natural-language ratify path (transcript scan for a small literal
     keyword family). The keyword family is a closed set, not LLM
     classification — the hook stays a `grep -E`.

3. **Default block + stderr education**. When no exempt fires, exit 2 with
   stderr lines that *enumerate every PASS path* so the user can unblock
   without reading source. A blocking gate that does not teach itself wastes
   the user's time on every false positive.

## L45 candidate (Cat-H freeze-period reference)

> **L45 (candidate)**: any file pattern the harness designates as
> *restricted* (must not be written without explicit ratify) must enforce
> the restriction through a PreToolUse hook with a whitelist matcher, an
> internal regex filter, and at least one auto-exempt path. The
> originating Stop/PostToolUse path that legitimately needs to write the
> file must always be auto-exempt.

L45 is filed as a candidate during the v1.13 freeze; R16 + the three-piece
practice carry the rule operationally until the freeze lifts.

## Why R15 and R16 are siblings

R15 governs growth. R16 governs creation. Both rely on the same hook
discipline (literal whitelist matcher, internal regex filter, never block
the originator) and both rely on a `pattern + hook + escape valve`
trio that closes against silent drift on one side and against
foot-gun-by-design on the other.

A future restricted pattern (e.g. a project's secrets file, an immutable
log, an externally-signed manifest) reuses R16's recipe by changing only
the regex filter and the literal-keyword family.

## Sibling rules (extended for R16)

- **L23**: project state may not be invented from session memory; must
  read or fail. (R15 keeps the file readable; R16 keeps it from being
  silently overwritten.)
- **L24**: matcher-scope-mismatch — Stop-event matchers and Write-event
  matchers are different scopes. R16 exists *because* of L24: the Stop
  hook's PCT gate cannot stop a Write tool, so a separate PreToolUse hook
  covers the Write scope.
- **L31**: `CLAUDE.md` revisions go through six-dimension audit.
- **L41**: canonical md5 anchors a contract against silent drift.
- **L43**: hook matchers must be literal whitelists, never `*`. R16's
  hook ships with `Write|Edit|MultiEdit` for this reason.

## How to apply R16 to a new restricted pattern

1. Define the regex filter (`<pattern>`) and the literal-keyword family
   that constitutes user ratify (≤7 short phrases, English + native
   language).
2. Write `hooks/pre-tool-<topic>-must-ask-gate.sh` modelled on
   `hooks/pre-tool-handoff-must-ask-gate.sh` — same set/exit semantics,
   same three exempt paths.
3. Identify the originator (the legitimate auto-source for that file).
   Set its env flag at the top of the originator's script
   (`export HARNESS_<TOPIC>_VIA_<ORIG>=1`).
4. Register the hook in `templates/settings.json.template` with an
   explicit `Write|Edit|MultiEdit` matcher.
5. Document the regex, the keyword family, and the originator's
   auto-exempt env in the same docs file as the rule itself.

## Cross-reference (R16)

- Hook: `hooks/pre-tool-handoff-must-ask-gate.sh`
- Originator's env-set: `hooks/stop-handoff-writer.sh` (line 12,
  `export HARNESS_HANDOFF_VIA_STOP=1`)
