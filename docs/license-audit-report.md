# License Compatibility Audit — keel-harness OSS v0.1.0

**Date**: 2026-05-01 (initial), revised 2026-05-03 (S2 W6 ship)
**Auditor**: P8-η (B3 ratified, W1 Day 2)
**Our license**: Apache-2.0 (declared in README.md and LICENSE file shipped in W1)
**Scope**: All deps that touch our redistribution boundary

---

## Section 1: Compatibility Matrix

| Name | Version | License | Our relationship | Apache-2.0 compatible? | Risk | Action |
|---|---|---|---|---|---|---|
| **keel-harness (us)** | 0.1.0 | Apache-2.0 | D direct — our code | — | low | LICENSE file shipped in W1 |
| **sync.sh / hooks/*.sh** | — | Apache-2.0 (our code) | D direct — our code | yes | none | — |
| **install.sh** | — | Apache-2.0 (our code) | D direct — our code | yes | none | — |
| **superpowers (Jesse Vincent / @obra)** | 5.0.7 | MIT | REQUIRED upstream — user installs | yes | none | LICENSE confirmed: MIT, copyright Jesse Vincent |
| **PUA plugin (TanWei / @tanweai)** | 3.0.0 | MIT | REQUIRED upstream — user installs | yes | none | LICENSE confirmed: MIT (plugin.json + README badge); we do not redistribute, user self-installs |
| **OODC plugin (mr-shaper)** | 1.4.0 | Apache-2.0 | BUNDLED — shipped in plugins/oodc/ | yes | none | License updated from UNLICENSED to Apache-2.0 by maintainer for OSS bundling |
| **claude-mem (thedotmack / Alex Newman)** | 12.0.1 | **AGPL-3.0** | optional (`--with-claude-mem`) | **no** | **high** | See Section 2 |
| **tacit-kb** | — | UNDECLARED | optional (`--with-tacit-kb`) | unknown | medium | See Section 3 |
| **docsync** | — | UNDECLARED | optional (`--with-docsync`) | unknown | medium | See Section 3 |
| **bash** | 3.2.57 (macOS) | GPL-2.0 (macOS BSD) | runtime — OS-bundled | — | none | OS standard, not redistributed |
| **git** | 2.50.1 (Apple Git) | LGPL-2.1 | runtime — OS-bundled | — | none | OS standard, not redistributed |
| **jq** | 1.7.1 | MIT | runtime — user installs | yes | none | MIT confirmed |
| **sed** | BSD (macOS) | BSD | runtime — OS-bundled | — | none | OS standard |
| **shellcheck** | 0.11.0 | GPL-3.0-or-later | CI/dev tooling only | — | low | Dev tool only, not redistributed in kernel |
| **GitHub Actions** | — | MIT (actions/checkout etc.) | CI pipeline | yes | none | Standard marketplace actions; Apache-2.0 compatible |

---

## Section 2: GPL/AGPL Hits

| Name | License | Hit type | Our relationship | Risk | Action |
|---|---|---|---|---|---|
| **claude-mem** | **AGPL-3.0** | AGPL hit | optional — install.sh `--with-claude-mem` flag prints URL only | **high** | install.sh prints "see https://github.com/thedotmack/claude-mem (AGPL-3.0); install yourself" — does NOT clone/install. AGPL contagion does not trigger because we do not redistribute the code. |
| **shellcheck** | GPL-3.0-or-later | GPL-3 hit | dev/CI tool — user installs locally; we do not bundle | low | CI-only usage; not shipped with kernel; no contamination risk |

> **Conclusion**: real AGPL contagion risk = 1 location (claude-mem), mitigated by URL-only install pattern. shellcheck is a pure dev/CI tool, no contagion. Kernel code (sync.sh / hooks/*.sh / install.sh) introduces zero GPL/AGPL.

---

## Section 3: UNDECLARED License List

| Name | Owner | Investigation | Decision |
|---|---|---|---|
| **tacit-kb** | private | No LICENSE file, no plugin.json declaration. Fully private code. | install.sh prints "private plugin, no public repo" without an install path. Only `--with-tacit-kb` URL hint. |
| **docsync** | private | Internal workflow plugin; no public repo | Same as tacit-kb: URL hint only, no installer path. Safe default = do not redistribute. |

---

## Section 4: Overall Verdict

**PASS** (after S2 W6 strategy overhaul — see commit c649e72)

Reasoning:
1. **Apache-2.0 kernel (D direct)**: PASS — our code is fully Apache-2.0 compatible.
2. **superpowers (REQUIRED)**: PASS — MIT compatible with Apache-2.0; user installs separately.
3. **PUA (REQUIRED)**: PASS — MIT; user installs separately, we do not redistribute.
4. **OODC (BUNDLED)**: PASS — re-licensed Apache-2.0 by maintainer for OSS bundling; sanitized to remove maintainer-specific business references.
5. **claude-mem (optional)**: PASS via URL-only pattern. install.sh `--with-claude-mem` prints URL + AGPL warning + "your responsibility to comply"; does not clone/install. AGPL contagion does not trigger.
6. **Private plugins (tacit-kb / docsync)**: PASS — URL hints only; no installer path provided. No redistribution.
7. **LICENSE file**: shipped in repo root.

---

## Section 5: Re-Audit Plan

| Trigger | Condition | Re-audit scope |
|---|---|---|
| Pre-launch (W7) | Before going public | Full license scan: `grep -rE "GPL\|AGPL" plugins/ workflows/ hooks/` to ensure kernel is uncontaminated. |
| Major release (v0.2.0+) | New deps introduced | Re-evaluate the AGPL contagion chain; verify runtime tooling versions (bash/git/jq) and their licenses are unchanged. |
| Upstream change (PUA / superpowers / OODC) | Source repos relicense | Stop bundling immediately; warn users; remove from REQUIRED list if license becomes incompatible. |

---

*Audit truth sources: `~/.claude/plugins/marketplaces/thedotmack/LICENSE` (AGPL-3.0) / `~/.claude/plugins/marketplaces/superpowers-marketplace/LICENSE` (MIT) / `~/.claude/plugins/pua/plugin.json` (MIT) / `plugins/oodc/plugin.json` (Apache-2.0, after re-license) / `brew info shellcheck` (GPL-3.0-or-later) / `~/.claude/plugins/marketplaces/thedotmack/package.json` (AGPL-3.0 v12.0.1)*
