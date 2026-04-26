#!/usr/bin/env bats

REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
BIN="$REPO/bin"
FIXTURES="$BATS_TEST_DIRNAME/fixtures"

setup() {
	export PATH="$BATS_TEST_DIRNAME/mocks:$PATH"
	export CLIP_BIN="$BATS_TEST_DIRNAME/mocks/clip"
	unset ANTHROPIC_API_KEY
	unset ANTHROPIC_BASE_URL
	unset ANTHROPIC_CUSTOM_HEADERS
	export MOCK_CURL_RESPONSE_FILE="$FIXTURES/api-ok.json"
	echo "test input text for routing" | "$CLIP_BIN" write
	rm -f "$BATS_TMPDIR/curl.body" "$BATS_TMPDIR/curl.args" "$BATS_TMPDIR/claude.invoked"
}

fast_path_ran() { [ -f "$BATS_TMPDIR/curl.body" ]; }
slow_path_ran() { [ -f "$BATS_TMPDIR/claude.invoked" ]; }

# ── routing ──────────────────────────────────────────────────────────────────

@test "routes to fast path when ANTHROPIC_API_KEY set" {
	export ANTHROPIC_API_KEY="test-key"
	run "$BIN/bulletize"
	[ "$status" -eq 0 ]
	fast_path_ran
	! slow_path_ran
}

@test "routes to slow path with --slow flag regardless of API key" {
	export ANTHROPIC_API_KEY="test-key"
	run "$BIN/bulletize" --slow
	[ "$status" -eq 0 ]
	slow_path_ran
	! fast_path_ran
}

@test "routes to slow path when positional arg present" {
	export ANTHROPIC_API_KEY="test-key"
	run "$BIN/bulletize" somefile.txt
	slow_path_ran
	! fast_path_ran
}

@test "-summarize always routes to slow path even with API key" {
	export ANTHROPIC_API_KEY="test-key"
	run "$BIN/bulletize" -summarize
	[ "$status" -eq 0 ]
	slow_path_ran
	! fast_path_ran
}

# ── -mmap suffix ─────────────────────────────────────────────────────────────

@test "-mmap passes 'Omit the leading' suffix to llm-rewrite" {
	export ANTHROPIC_API_KEY="test-key"
	run "$BIN/bulletize" -mmap
	[ "$status" -eq 0 ]
	fast_path_ran
	jq -e '.system | contains("Omit the leading")' "$BATS_TMPDIR/curl.body" >/dev/null
}

@test "without -mmap no suffix is added to the system prompt" {
	export ANTHROPIC_API_KEY="test-key"
	run "$BIN/bulletize"
	[ "$status" -eq 0 ]
	fast_path_ran
	# System prompt should be exactly the bulletize.md content (no extra suffix)
	EXPECTED=$(<"$REPO/prompts/bulletize.md")
	ACTUAL=$(jq -r '.system' "$BATS_TMPDIR/curl.body")
	[ "$ACTUAL" = "$EXPECTED" ]
}

# ── output routing ────────────────────────────────────────────────────────────

@test "-outfile writes result to file" {
	export ANTHROPIC_API_KEY="test-key"
	OUTFILE="$BATS_TMPDIR/bullets.md"
	run "$BIN/bulletize" -outfile "$OUTFILE"
	[ "$status" -eq 0 ]
	[ -f "$OUTFILE" ]
	[ "$(cat "$OUTFILE")" = "mocked output" ]
}

@test "fast path confirms with 'Bulletized: clipboard' on stdout" {
	export ANTHROPIC_API_KEY="test-key"
	run "$BIN/bulletize"
	[ "$status" -eq 0 ]
	[[ "$output" == *"Bulletized: clipboard"* ]]
}
