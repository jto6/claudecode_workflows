#!/usr/bin/env bats

REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
BIN="$REPO/bin"
FIXTURES="$BATS_TEST_DIRNAME/fixtures"

setup() {
	export PATH="$BATS_TEST_DIRNAME/mocks:$PATH"
	unset ANTHROPIC_API_KEY
	unset ANTHROPIC_BASE_URL
	unset ANTHROPIC_CUSTOM_HEADERS
	unset LLM_REWRITE_MODEL
	unset ANTHROPIC_SMALL_FAST_MODEL
	export MOCK_CURL_RESPONSE_FILE="$FIXTURES/api-ok.json"
	rm -f "$BATS_TMPDIR/curl.body" "$BATS_TMPDIR/curl.args" "$BATS_TMPDIR/claude.invoked"
}

# ── error paths ──────────────────────────────────────────────────────────────

@test "errors when neither ANTHROPIC_API_KEY nor ANTHROPIC_BASE_URL is set" {
	run bash "$BIN/llm-rewrite" "$FIXTURES/prompt.md" <<< "input text"
	[ "$status" -ne 0 ]
	[[ "$output" == *"ANTHROPIC_API_KEY or ANTHROPIC_BASE_URL"* ]]
}

@test "errors when no prompt file argument given" {
	export ANTHROPIC_API_KEY="test-key"
	run bash "$BIN/llm-rewrite" <<< "input text"
	[ "$status" -ne 0 ]
}

@test "exits non-zero when API returns an error response" {
	export ANTHROPIC_API_KEY="test-key"
	export MOCK_CURL_RESPONSE_FILE="$FIXTURES/api-error.json"
	run bash "$BIN/llm-rewrite" "$FIXTURES/prompt.md" <<< "input text"
	[ "$status" -ne 0 ]
}

# ── auth paths ───────────────────────────────────────────────────────────────

@test "passes ANTHROPIC_API_KEY as x-api-key header" {
	export ANTHROPIC_API_KEY="my-test-key"
	run bash "$BIN/llm-rewrite" "$FIXTURES/prompt.md" <<< "input text"
	[ "$status" -eq 0 ]
	grep -qx "x-api-key: my-test-key" "$BATS_TMPDIR/curl.args"
}

@test "uses ANTHROPIC_BASE_URL as endpoint when API key set" {
	export ANTHROPIC_API_KEY="my-test-key"
	export ANTHROPIC_BASE_URL="https://fake-gateway.example.com"
	run bash "$BIN/llm-rewrite" "$FIXTURES/prompt.md" <<< "input text"
	[ "$status" -eq 0 ]
	grep -qx "https://fake-gateway.example.com/v1/messages" "$BATS_TMPDIR/curl.args"
}

@test "obtains token from helper when only ANTHROPIC_BASE_URL is set" {
	export ANTHROPIC_BASE_URL="https://fake-gateway.example.com"
	# Create fake token helper at the path the mock node will report
	mkdir -p "$BATS_TMPDIR/fake-node/lib/node_modules/@ti/claude-code/lib"
	touch "$BATS_TMPDIR/fake-node/lib/node_modules/@ti/claude-code/lib/get-token.js"
	export MOCK_NODE_PREFIX="$BATS_TMPDIR/fake-node"

	run bash "$BIN/llm-rewrite" "$FIXTURES/prompt.md" <<< "input text"
	[ "$status" -eq 0 ]
	grep -qx "x-api-key: fake-test-token" "$BATS_TMPDIR/curl.args"
	grep -qx "https://fake-gateway.example.com/v1/messages" "$BATS_TMPDIR/curl.args"
}

# ── headers ──────────────────────────────────────────────────────────────────

@test "forwards ANTHROPIC_CUSTOM_HEADERS as curl -H args" {
	export ANTHROPIC_API_KEY="test-key"
	export ANTHROPIC_CUSTOM_HEADERS="x-team-id: my-team"
	run bash "$BIN/llm-rewrite" "$FIXTURES/prompt.md" <<< "input text"
	[ "$status" -eq 0 ]
	grep -qx "x-team-id: my-team" "$BATS_TMPDIR/curl.args"
}

@test "forwards multiple ANTHROPIC_CUSTOM_HEADERS lines" {
	export ANTHROPIC_API_KEY="test-key"
	export ANTHROPIC_CUSTOM_HEADERS=$'x-header-a: foo\nx-header-b: bar'
	run bash "$BIN/llm-rewrite" "$FIXTURES/prompt.md" <<< "input text"
	[ "$status" -eq 0 ]
	grep -qx "x-header-a: foo" "$BATS_TMPDIR/curl.args"
	grep -qx "x-header-b: bar" "$BATS_TMPDIR/curl.args"
}

# ── request body ─────────────────────────────────────────────────────────────

@test "appends suffix to system prompt when provided" {
	export ANTHROPIC_API_KEY="test-key"
	run bash "$BIN/llm-rewrite" "$FIXTURES/prompt.md" "extra suffix line" <<< "input"
	[ "$status" -eq 0 ]
	jq -e '.system | contains("extra suffix line")' "$BATS_TMPDIR/curl.body" >/dev/null
}

@test "does not append suffix when second arg is empty string" {
	export ANTHROPIC_API_KEY="test-key"
	PROMPT_CONTENT=$(<"$FIXTURES/prompt.md")
	run bash "$BIN/llm-rewrite" "$FIXTURES/prompt.md" "" <<< "input"
	[ "$status" -eq 0 ]
	BODY_SYSTEM=$(jq -r '.system' "$BATS_TMPDIR/curl.body")
	[ "$BODY_SYSTEM" = "$PROMPT_CONTENT" ]
}

@test "uses LLM_REWRITE_MODEL when set" {
	export ANTHROPIC_API_KEY="test-key"
	export LLM_REWRITE_MODEL="claude-opus-4-7"
	run bash "$BIN/llm-rewrite" "$FIXTURES/prompt.md" <<< "input"
	[ "$status" -eq 0 ]
	jq -e '.model == "claude-opus-4-7"' "$BATS_TMPDIR/curl.body" >/dev/null
}

@test "uses ANTHROPIC_SMALL_FAST_MODEL as fallback when LLM_REWRITE_MODEL unset" {
	export ANTHROPIC_API_KEY="test-key"
	export ANTHROPIC_SMALL_FAST_MODEL="claude-haiku-4-5"
	run bash "$BIN/llm-rewrite" "$FIXTURES/prompt.md" <<< "input"
	[ "$status" -eq 0 ]
	jq -e '.model == "claude-haiku-4-5"' "$BATS_TMPDIR/curl.body" >/dev/null
}

@test "defaults model to claude-haiku-4-5 when no model env vars set" {
	export ANTHROPIC_API_KEY="test-key"
	run bash "$BIN/llm-rewrite" "$FIXTURES/prompt.md" <<< "input"
	[ "$status" -eq 0 ]
	jq -e '.model == "claude-haiku-4-5"' "$BATS_TMPDIR/curl.body" >/dev/null
}

@test "sends user text as the message content" {
	export ANTHROPIC_API_KEY="test-key"
	run bash "$BIN/llm-rewrite" "$FIXTURES/prompt.md" <<< "my specific input"
	[ "$status" -eq 0 ]
	jq -e '.messages[0].content == "my specific input"' "$BATS_TMPDIR/curl.body" >/dev/null
}

# ── response ─────────────────────────────────────────────────────────────────

@test "outputs .content[0].text on success" {
	export ANTHROPIC_API_KEY="test-key"
	run bash "$BIN/llm-rewrite" "$FIXTURES/prompt.md" <<< "input"
	[ "$status" -eq 0 ]
	[ "$output" = "mocked output" ]
}
