#!/usr/bin/env bats

REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
BIN="$REPO/bin"
FIXTURES="$BATS_TEST_DIRNAME/fixtures"
PROMPTS="$REPO/prompts"

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

# Helper: did the fast path run? (mock curl was invoked)
fast_path_ran() { [ -f "$BATS_TMPDIR/curl.body" ]; }

# Helper: did the slow path run? (mock claude was invoked)
slow_path_ran() { [ -f "$BATS_TMPDIR/claude.invoked" ]; }

# ── routing ──────────────────────────────────────────────────────────────────

@test "routes to fast path when ANTHROPIC_API_KEY set" {
	export ANTHROPIC_API_KEY="test-key"
	run "$BIN/text-clean"
	[ "$status" -eq 0 ]
	fast_path_ran
	! slow_path_ran
}

@test "routes to slow path with --slow flag regardless of API key" {
	export ANTHROPIC_API_KEY="test-key"
	run "$BIN/text-clean" --slow
	[ "$status" -eq 0 ]
	slow_path_ran
	! fast_path_ran
}

@test "routes to slow path when positional arg present" {
	export ANTHROPIC_API_KEY="test-key"
	run "$BIN/text-clean" somefile.txt
	slow_path_ran
	! fast_path_ran
}

@test "routes to slow path when no API access configured" {
	run "$BIN/text-clean"
	[ "$status" -eq 0 ]
	slow_path_ran
	! fast_path_ran
}

@test "--fast errors when no API access configured" {
	run "$BIN/text-clean" --fast
	[ "$status" -ne 0 ]
	[[ "$output" == *"ANTHROPIC_API_KEY or ANTHROPIC_BASE_URL"* ]]
}

# ── prompt selection ─────────────────────────────────────────────────────────

@test "fast path uses technical prompt by default" {
	export ANTHROPIC_API_KEY="test-key"
	run "$BIN/text-clean"
	[ "$status" -eq 0 ]
	# Technical prompt contains "Confident, direct, precise"
	jq -e '.system | contains("Confident, direct, precise")' "$BATS_TMPDIR/curl.body" >/dev/null
}

@test "fast path uses conversational prompt for -conversational" {
	export ANTHROPIC_API_KEY="test-key"
	run "$BIN/text-clean" -conversational
	[ "$status" -eq 0 ]
	# Conversational prompt contains "Natural, approachable, readable"
	jq -e '.system | contains("Natural, approachable, readable")' "$BATS_TMPDIR/curl.body" >/dev/null
}

@test "fast path uses journal prompt for -journal" {
	export ANTHROPIC_API_KEY="test-key"
	run "$BIN/text-clean" -journal
	[ "$status" -eq 0 ]
	# Journal prompt contains "Personal, reflective, and introspective"
	jq -e '.system | contains("Personal, reflective, and introspective")' "$BATS_TMPDIR/curl.body" >/dev/null
}

# ── output routing ────────────────────────────────────────────────────────────

@test "-outfile writes result to file not clipboard" {
	export ANTHROPIC_API_KEY="test-key"
	OUTFILE="$BATS_TMPDIR/output.txt"
	run "$BIN/text-clean" -outfile "$OUTFILE"
	[ "$status" -eq 0 ]
	[ -f "$OUTFILE" ]
	[ "$(cat "$OUTFILE")" = "mocked output" ]
}

@test "fast path confirms with 'Cleaned: clipboard' on stdout" {
	export ANTHROPIC_API_KEY="test-key"
	run "$BIN/text-clean"
	[ "$status" -eq 0 ]
	[[ "$output" == *"Cleaned: clipboard"* ]]
}

@test "fast path confirms with 'Cleaned: <path>' when -outfile given" {
	export ANTHROPIC_API_KEY="test-key"
	OUTFILE="$BATS_TMPDIR/output.txt"
	run "$BIN/text-clean" -outfile "$OUTFILE"
	[ "$status" -eq 0 ]
	[[ "$output" == *"Cleaned: $OUTFILE"* ]]
}
