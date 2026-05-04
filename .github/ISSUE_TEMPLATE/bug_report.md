---
name: Bug report
about: Report a bug to help us improve keel-harness
title: "[Bug] "
labels: bug
assignees: ''
---

## Describe the bug

A clear and concise description of what the bug is.

## Steps to reproduce

1. Run `...`
2. With env `HARNESS_HOME=...`
3. Observe `...`

## Expected behavior

What you expected to happen.

## Actual behavior

What actually happened. Paste relevant command output:

```
<paste output here>
```

## Environment

- OS (run `uname -a`):
- Bash version (`bash --version | head -1`):
- Claude Code version:
- keel-harness version (`grep _harness_version manifest.json` or commit SHA):
- Install method (one-line `curl | bash` / cloned repo / other):

## Hook trace excerpt

If the bug involves hook misfire, paste the last 30 lines of
`.harness/hook-trace.log`:

```
<paste output of: tail -n30 .harness/hook-trace.log>
```

## Additional context

Anything else that might be relevant — Layer 0 health output, recent
commits, related issues, screenshots.
