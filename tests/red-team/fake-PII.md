# MOCK ATTACK DATA — fake-PII.md
# This file is a red-team test fixture. It intentionally contains PII keywords
# that should be BLOCKED by the 5-layer privacy protection system.
# DO NOT use this content as real configuration.

## Simulated Private Username Leak

author: mrshaper
github_user: mr-shaper
alias: "Mr Shaper"

## Simulated Email Leak

contact: mrshaper@example.test
alternate: mrshaper@example.test

## Simulated Private Path Leak

home_dir: /Users/mr-shaper/Library/Mobile Documents/com~apple~CloudDocs/AI/Claude/
config_path: /Users/mr-shaper/.claude/settings.json
cache: /Users/mr-shaper/.cache/harness

## Simulated Enterprise/Corp Keyword Leak

employer: examplecorp
network: 示例公司物流
crm: feishu
messaging: dingtalk

## Simulated Identity Mapping

real_name: Mr Shaper
internal_alias: mr-shaper
team: examplecorp
project: 示例公司 Last-Mile Solutions
