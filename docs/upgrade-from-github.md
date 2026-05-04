# Upgrade from GitHub — How a Local harness Tracks Upstream

> SOP for keeping a local harness install in sync with `mr-shaper/keel-harness`
> on GitHub when a new release ships (v0.1.1, v0.2, etc.). Covers the
> common case (no local customizations) and the realistic case (you have
> edited a hook or template and don't want to lose it).

---

## TL;DR

```bash
# Common case: no local customizations
cd ~/dev/<your-keel-harness-clone>
git pull origin main
bash install.sh

# Verify
bash hooks/session-start-layer0-health.sh
```

If the install completes with `Layer 0 Health: 5/5 elements OK`, you are
done. The next session will pick up the new hooks and workflow MDs.

---

## The two layers and why this matters

A `keel-harness` install lives in two places:

| Layer | Where | What it is | Owns |
|-------|-------|------------|------|
| **Source clone** | `~/dev/<your-clone>/` | The git working tree of `mr-shaper/keel-harness` | latest upstream |
| **Active runtime** | `~/.claude/plugins/keel-harness-mp/` | Files actively read by Claude Code hooks | what the agent sees this session |

`install.sh` is the bridge. It reads `manifest.json` from your source
clone and copies the listed `kernel_files` into the runtime layer.
**The runtime is a snapshot.** Editing it directly works for one session
but does not survive a re-install.

The upgrade workflow always touches both layers:

```
git pull (source)  →  bash install.sh (re-snapshot to runtime)  →  verify
```

---

## Case 1 — Clean upgrade (no local edits)

You haven't modified anything in the source clone or the runtime. The
upgrade is mechanical:

```bash
cd ~/dev/<your-keel-harness-clone>

# 1. Stash any uncommitted file (just in case — should be empty)
git status                # expect: "working tree clean"

# 2. Pull upstream
git fetch origin
git pull origin main

# 3. (Optional) Note the new tag
git tag -l | tail -3      # see the new release tag

# 4. Re-run install (takes ~5 seconds)
bash install.sh

# 5. Verify Layer 0
bash hooks/session-start-layer0-health.sh
```

Expected output of step 5:

```
[a] HARNESS_HOME directory present       OK
[b] At least 1 enforce-core hook present OK
[c] settings.json contains "harness"     OK
[d] CLAUDE.md exists and readable        OK
[e] CLAUDE.md contains "§harness mode"   OK
Layer 0 Health: 5/5 elements OK
```

If any element fails, see "Troubleshooting" below.

---

## Case 2 — You have edited a hook or template

The realistic case. You have customized something (an extra hook, a tweak
to a template, a new entry in `manifest.json`) and you don't want
`git pull` or `install.sh` to overwrite it.

The pattern is **fork-and-rebase**, not in-place edit:

### Option A — Track upstream as a separate remote

Best when your customizations are substantial and you want to stay close
to upstream long-term.

```bash
cd ~/dev/<your-clone>

# One-time setup: rename current 'origin' to 'upstream'
git remote rename origin upstream
# Add your own fork as 'origin'
git remote add origin git@github.com:<your-username>/keel-harness.git

# Day-to-day: work on a feature branch off main
git checkout -b my-customizations

# Upgrade flow:
git fetch upstream
git rebase upstream/main          # apply your edits on top of upstream
# (resolve conflicts if any — see "Conflict resolution" below)
git push --force-with-lease origin my-customizations

# Re-snapshot to runtime
bash install.sh
bash hooks/session-start-layer0-health.sh
```

### Option B — Patch on top via per-file overlay

Best when your customizations are small (one hook, one template line).
Avoids long-running fork maintenance.

```bash
# 1. Capture your customizations as a patch BEFORE pulling
cd ~/dev/<your-clone>
git diff > /tmp/my-harness-customizations.patch

# 2. Reset to clean upstream
git checkout main
git pull origin main

# 3. Re-apply your patch
git apply /tmp/my-harness-customizations.patch
# (resolve conflicts manually if any)

# 4. Re-snapshot to runtime
bash install.sh
bash hooks/session-start-layer0-health.sh
```

### Option C — Replace specific files only via env override

For *additive* customizations (new hooks alongside the bundled ones),
not modifications. Set `HARNESS_HOME` to a directory that *contains*
your overlay layer, then run `install.sh` to copy upstream on top.
The overlay survives because `install.sh` only writes the files in
`manifest.json` `kernel_files` — anything else in `HARNESS_HOME` is
left alone.

```bash
# Your overlay layer at ~/.claude/plugins/keel-harness-overlay/ (custom name)
HARNESS_HOME=~/.claude/plugins/keel-harness-mp \
  bash install.sh

# Your custom hook at ~/.claude/plugins/keel-harness-mp/hooks/my-hook.sh
# is NOT touched (not in manifest.json), and is wired separately in
# settings.json.
```

---

## Conflict resolution

If `git rebase upstream/main` or `git apply` reports conflicts, the
typical files to inspect:

| File | Common conflict | Resolution |
|------|-----------------|------------|
| `manifest.json` | Both you and upstream added entries | Merge both lists (jq merge or manual JSON edit) |
| `templates/CLAUDE.md.*.template` | Both touched the contract | Re-apply your customization on top of new upstream text |
| `hooks/<your-hook>.sh` | Upstream added a hook with the same name | Rename your hook (e.g., `my-pre-commit.sh`) and update `settings.json` accordingly |
| `CHANGELOG.md` | You added local notes | Move your notes into your fork's branch-specific changelog |

After resolution, always re-run `bash install.sh` and verify Layer 0.

---

## Backup before upgrade

`install.sh` does **not** automatically back up the runtime layer. If you
have edited the runtime directly (not recommended, but happens), back up
first:

```bash
cp -R ~/.claude/plugins/keel-harness-mp \
      ~/.claude/plugins/keel-harness-mp.bak-$(date +%s)
```

If the upgrade goes wrong, restore:

```bash
rm -rf ~/.claude/plugins/keel-harness-mp
mv ~/.claude/plugins/keel-harness-mp.bak-<timestamp> \
   ~/.claude/plugins/keel-harness-mp
bash hooks/session-start-layer0-health.sh
```

---

## Settings.json upgrade behavior

`install.sh` Phase 3 runs a `jq -s '.[0] * .[1]'` merge between your
existing `~/.claude/settings.json` and the new
`templates/settings.json.template`. Your existing settings.json is
backed up to `~/.claude/settings.json.bak-<timestamp>` before the merge.

The merge is conservative: it adds new hooks the template introduces,
but it *replaces* your old harness hook entries with the new ones. If
you customized a harness hook command path, edit `settings.json` after
`install.sh` to restore your customization, then verify Layer 0.

---

## CHANGELOG-driven upgrade decisions

Before pulling a new release, scan `CHANGELOG.md` for the version range
between your installed version and the latest:

```bash
git log v0.1.0-alpha..HEAD --oneline -- CHANGELOG.md
```

The CHANGELOG explicitly calls out:

- **`Added`** entries — new files arrive in `manifest.json`.
- **`Changed`** entries — existing files modified (potential conflict
  zone for your customizations).
- **`Fixed`** entries — bugs you may have hit; pulling fixes them.
- **`Notes`** entries — design intent that may change how you customize.
- **`Candidates`** — proposals for the *next* release; nothing arrives
  with this one.

If a `Changed` entry overlaps your customization, expect a conflict and
budget time for resolution before pulling.

---

## Troubleshooting

### Layer 0 element (a) fails: HARNESS_HOME missing

```bash
echo $HARNESS_HOME              # confirm env var
ls -la $HARNESS_HOME            # confirm directory exists
# If env not set, default is ~/.claude/plugins/keel-harness-mp/
```

Solution: re-run `bash install.sh`.

### Layer 0 element (c) fails: settings.json no harness

```bash
grep -c "harness" ~/.claude/settings.json   # expect ≥1
```

If 0: your `settings.json` Phase 3 merge did not pick up the harness
block. Restore from backup and run `install.sh` with verbose output to
see why the merge skipped:

```bash
cp ~/.claude/settings.json.bak-<latest> ~/.claude/settings.json
bash install.sh --skip-deps-check 2>&1 | tee /tmp/install.log
grep -A5 "Phase 3" /tmp/install.log
```

### Layer 0 element (e) fails: §harness mode missing from CLAUDE.md

```bash
grep "§harness mode" ~/.claude/CLAUDE.md   # expect ≥1 hit
```

If 0: your global CLAUDE.md was not updated by Phase 2. Either you
declined the merge prompt or the merge wrote to the wrong path. Check
both `~/.claude/CLAUDE.md` and the source clone's
`templates/CLAUDE.md.global.template` — diff them and re-apply manually
if needed.

---

## What NOT to do

- **Do not edit files in `~/.claude/plugins/keel-harness-mp/` directly
  and expect them to survive an upgrade.** They will not. Edit the
  source clone (`~/dev/<your-clone>/`) and re-run `install.sh`, or use
  Option B/C above.
- **Do not `rm -rf ~/.claude/plugins/keel-harness-mp/` and re-install
  blindly.** Back up first. The runtime contains state you may want
  (e.g., backup `settings.json` files in `~/.claude/`).
- **Do not pull without reading CHANGELOG.** Especially for `0.x` releases,
  schema changes happen between minor versions.

---

## Where this lives in the kernel

This SOP is itself part of the kernel — entry in `manifest.json`
`kernel_files`. It ships with every release. If your local copy is stale
relative to upstream, `git diff upstream/main -- docs/upgrade-from-github.md`
shows the delta.
