# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| v0.1.0-alpha | :white_check_mark: Active |
| Earlier releases | :x: Not supported |

Only the latest release receives security fixes.

## How to Report a Vulnerability

**Please do not report security vulnerabilities through public GitHub Issues.**

### Preferred: GitHub Private Security Advisory

1. Navigate to the [Security tab](https://github.com/mr-shaper/keel-harness/security/advisories) of this repository.
2. Click **"New draft security advisory"**.
3. Fill in the advisory form with:
   - A clear description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Any suggested mitigations

GitHub will notify maintainers immediately via private channel.

### Alternative: Email

Send details to `mrshaper@users.noreply.github.com` with the subject line:
`[keel-harness SECURITY] <brief description>`

Include:
- Affected component (hooks, scripts, plugins, install.sh)
- Reproduction steps
- Potential impact assessment

## Response Timeline

| Stage | Target |
|-------|--------|
| Initial acknowledgement | 2 business days |
| Triage and severity assessment | 5 business days |
| Fix for critical severity | 30 days |
| Fix for high severity | 60 days |
| Fix for medium / low | Best effort |

We will communicate updates through the private advisory thread.

## Disclosure Policy

keel-harness follows **coordinated disclosure**:

1. Maintainers confirm the vulnerability and assess severity.
2. A fix is developed in a private branch.
3. Once a fix is ready, a patch release is tagged.
4. A public GitHub Security Advisory is published simultaneously with the release.
5. CVE assignment is requested where appropriate.

We ask that reporters honor a **90-day embargo** from the initial report to allow
a fix to ship before public disclosure. If 90 days pass without a fix, reporters
are free to disclose responsibly with prior notice.

## Scope

Security issues in the following are in scope:

- Shell hooks (`hooks/`)
- Install script (`install.sh`)
- Bundled plugin scripts (`plugins/`)
- Workflow enforcement scripts (`scripts/`)

Out of scope: third-party dependencies (superpowers, PUA plugin). Report those
upstream to their respective maintainers.

## Recognition

Reporters who follow responsible disclosure will be acknowledged in the release
notes for the fix unless they request anonymity.
