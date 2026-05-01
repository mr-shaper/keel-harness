# MOCK ATTACK DATA — fake-secrets.md
# This file is a red-team test fixture. It intentionally contains secret/token
# patterns that should be BLOCKED by the 5-layer privacy protection system.
# DO NOT use any of these as real credentials — they are synthetic test values.

## Simulated Anthropic API Key Leak

ANTHROPIC_KEY=sk-ant-abc123XYZ_456_real_looking_secret_token
export SK_ANT="sk-ant-api03-fakefakefakefakefakefakefakefakefake"

## Simulated OpenAI Key Leak

OPENAI_KEY=sk-or-real-secret-here
export OPENAI_API_KEY="sk-or-v1-fakeOpenAIKeyForRedTeamTestOnly123456"

## Simulated Gemini Key Leak

GEMINI_API_KEY=fake-gemini-secret-12345
export GOOGLE_AI_KEY="AIzaSyFakeGeminiKeyForRedTeamTestOnly789"

## Simulated Generic Secret/Token Leak

DATABASE_SECRET=my-fake-db-secret-value-123
API_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.fakepayload.fakesig

## Simulated Account ID + Credential Combo Leak (sync.sh Layer 2 target)

# Account credential for oss-test-user (private UID — must not leave ~/.claude)
account_uid: oss-test-user
