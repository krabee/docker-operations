#!/usr/bin/env bash
# scan-secrets.sh — pre-push guard. Exit 1 if credentials or personal/host data are found.
# usage: ./scripts/scan-secrets.sh [path]        (default: repo root)
set -uo pipefail
TARGET="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
FAIL=0

scan() { # name, pattern, grep-flag(i or empty)
  local name="$1" pat="$2" flag="${3:-}" out
  out=$(grep -rn${flag}E --exclude-dir=.git --exclude-dir=node_modules \
        --binary-files=without-match -- "$pat" "$TARGET" 2>/dev/null) || true
  if [ -n "$out" ]; then
    printf '\n[HIT] %s\n%s\n' "$name" "$out"
    FAIL=1
  fi
}

scan "private-key-block"    'BEGIN [A-Z ]*PRIVATE KEY'
scan "cloud-access-key"     'AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}'
scan "github-token"         'ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}'
scan "slack-token"          'xox[baprs]-[A-Za-z0-9-]{10,}'
scan "llm-api-key"          'sk-[A-Za-z0-9]{20,}'
scan "generic-assignment"   '(password|passwd|secret|api[_-]?key|token)[[:space:]]*[=:][[:space:]]*["'"'"']?[A-Za-z0-9_./+=-]{8,}' i
scan "private-ip"           '\b(192\.168\.[0-9]+\.[0-9]+|10\.[0-9]+\.[0-9]+\.[0-9]+|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]+\.[0-9]+)\b'
scan "email-address"        '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
scan "secret-dir-path"      '~/\.(ssh|aws|kube|gnupg|docker/config)|/home/[A-Za-z0-9._-]+/\.(ssh|aws|kube|gnupg)'
scan "thai-phone-or-taxid"  '\b0[0-9]{8,9}\b|\b[0-9]{13}\b'

if [ "$FAIL" -eq 0 ]; then
  echo "OK — no credential or personal/host data patterns found in: $TARGET"
else
  echo
  echo "FAILED — review the hits above. False positives must be justified in the PR description."
fi
exit "$FAIL"
