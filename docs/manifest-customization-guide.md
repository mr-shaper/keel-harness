# manifest.json Customization Guide

## Overview

The `manifest.json` shipped with keel-harness is a **template**. The
`private_blacklist_keywords` array contains generic placeholder strings, not
real user data. Before using keel-harness in production you **must** replace
these placeholders with your own personally-identifying information so the
handoff-read gate can actually protect your private context.

If you skip this step the privacy guard will fire on the wrong strings and
miss your real PII — the opposite of what you want.

---

## Where the file lives after install

```
~/.claude/plugins/keel-harness-mp/manifest.json
```

This is the live copy read by every hook at runtime. Edit this file directly.

---

## Placeholder → your real value mapping

| Placeholder in shipped manifest | Replace with |
|---|---|
| `mrshaper` | Your first name, lowercase (e.g. `alice`) |
| `mr-shaper` | Your GitHub / system username (e.g. `alice42`) |
| `mrshaper` | Your email prefix — the part before `@` (e.g. `alice.smith`) |
| `Mr Shaper` | Your Chinese alias or nickname, if any |
| `mrshaper` | Any secondary email handle or alias |
| `/Users/mr-shaper` | Your actual home directory path (e.g. `/Users/alice42`) |
| `examplecorp` | Your employer name in Latin script (e.g. `acmecorp`) |
| `示例公司` | Your employer name in Chinese characters, if applicable |
| `企业客户` | Internal job-context term you want blocked (e.g. `大客户`) |
| `your-private-config-dir` | Your private Claude config directory name (e.g. `claude-alice`) |

---

## How to customize — step by step

### 1. Open the live manifest

```bash
$EDITOR ~/.claude/plugins/keel-harness-mp/manifest.json
```

### 2. Replace placeholders in `private_blacklist_keywords`

Find each placeholder string and replace it with your real value. Example
before/after for a user named Alice on GitHub as `alicedev`:

```jsonc
// Before (shipped template)
"mrshaper",
"mr-shaper",
"/Users/mr-shaper",

// After (your customization)
"alice",
"alicedev",
"/Users/alicedev",
```

### 3. Add extra terms

You can add any additional strings to the array. Append them after the
existing entries. Good candidates:

- Internal project codenames
- Employer division or team names
- Your phone number prefix
- Any proprietary product names you reference in Claude sessions

```json
"my-secret-project",
"division-alpha",
"+1415"
```

### 4. Keep generic terms as-is

The following entries in the shipped manifest are **intentionally generic** —
they block common credential and SaaS patterns that apply to all users.
Do **not** remove them:

| Entry | Why it stays |
|---|---|
| `@gmail.com` | Blocks any Gmail address |
| `Last-Mile`, `Handover`, `分拨`, `运单` | Generic logistics terminology |
| `feishu`, `飞书`, `dingtalk`, `钉钉`, `wukong`, `alidocs` | SaaS tool names |
| `sk-ant`, `sk-or`, `API_KEY=`, `TOKEN=`, `SECRET=`, `OPENAI_KEY`, `GEMINI_API_KEY` | Credential leak patterns |
| `claude-roy`, `claude-mem-config` | Generic config-dir name examples |
| `alibaba 味`, `huawei 味`, etc. | Generic flavor terms in PUA plugin |
| `孙宇晨`, `张雪峰` | Public figures used as persona examples |
| `mama mode`, `yes mode` | Generic plugin mode names |

---

## Regex patterns

The `blacklist_regex_patterns` array uses regular expressions for dynamic
matching and ships with two patterns that catch most credential leaks:

```json
"[A-Z][a-z]+@[a-z]+\\.com"   // email-like strings
"sk-[a-zA-Z0-9_-]{20,}"      // Anthropic / OpenAI key format
```

You can add your own regex patterns here if your PII follows a predictable
format (e.g. a 9-digit employee ID or a project prefix like `PROJ-\d{4}`).

---

## Keeping your customization private

The installed copy at `~/.claude/plugins/keel-harness-mp/manifest.json` is
**not tracked by the keel-harness git repo** — it lives outside the repo
directory. Your edits stay local.

If you maintain a fork of keel-harness, do **not** commit your real PII back
to the repo. Use one of these approaches:

- Keep your fork private
- Add `manifest.json` to `.gitignore` in your fork
- Wait for the planned `manifest.local.json` override support (targeted for
  keel-harness v0.2.0)

---

## Verification after customization

Run the export test to confirm the blacklist fires on your real strings:

```bash
bash ~/.claude/plugins/keel-harness-mp/sync.sh export
```

The export will redact any keyword in `private_blacklist_keywords` from the
exported handoff. Spot-check the output to confirm your name, username, and
employer do not appear in plain text.

---

## Summary checklist

- [ ] Replaced `mrshaper` with your first name lowercase
- [ ] Replaced `mr-shaper` with your GitHub username
- [ ] Replaced `mrshaper` with your email prefix
- [ ] Replaced `/Users/mr-shaper` with your actual home directory
- [ ] Replaced `examplecorp` / `示例公司` with your employer
- [ ] Added any extra terms (project codenames, division names, etc.)
- [ ] Did **not** remove generic credential patterns
- [ ] Ran `sync.sh export` and confirmed PII is redacted
