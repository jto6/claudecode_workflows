#!/usr/bin/env bash
set -euo pipefail

if ! command -v bats >/dev/null 2>&1; then
	echo "bats not installed — skipping tests. Install: sudo apt install bats" >&2
	exit 0
fi

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
exec bats "$REPO/test/"
