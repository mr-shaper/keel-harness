## Summary

What changed and why. Keep it short — a paragraph at most.

## Type of change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing behavior to change)
- [ ] Documentation update
- [ ] Refactor (no functional change)
- [ ] Test / CI improvement

## Test evidence

Paste raw command output. Claims need evidence — this is the project's
canonical-honesty rule, applied to your PR.

```
$ bash tests/test-install.sh
<output>

$ bash tests/test-sync.sh
<output>

$ bash tests/test-pre-commit.sh
<output>

$ bash tests/test-red-team.sh
<output>

$ bash tests/test-manifest-completeness.sh
<output>
```

## Layer 0 health check

Confirm the install layer 0 contract still passes:

```
$ INSTALL_DRY_RUN=1 HARNESS_HOME=/tmp/test-harness CLAUDE_HOME=/tmp/test-claude bash install.sh
... Layer 0 Health: 5/5 elements OK
```

## Related issues / discussions

Closes #
References #

## Screenshots (if visual change)
