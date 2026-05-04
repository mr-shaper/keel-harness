# MOCK ATTACK DATA — fake-PII.md
# This file is a red-team test fixture. It intentionally contains PII keywords
# that should be BLOCKED by the 5-layer privacy protection system.
# DO NOT use this content as real configuration.

## Simulated Private Username Leak

author: maintainer
github_user: mrshaper
alias: "OSS_MAINTAINER"

## Simulated Email Leak

contact: oss-test-author@example.test
alternate: oss-test-user@example.test

## Simulated Private Path Leak

home_dir: /Users/mrshaper/Library/Mobile Documents/com~apple~CloudDocs/AI/Claude/
config_path: /Users/mrshaper/.claude/settings.json
cache: /Users/mrshaper/.cache/harness

## Simulated Enterprise/Corp Keyword Leak

employer: example-employer
network: example-employer
crm: feishu
messaging: dingtalk

## Simulated Identity Mapping

real_name: Mr Shaper Zhu
internal_alias: mrshaper
team: example-employer-US-KA
project: example-employer Last-Mile Solutions
