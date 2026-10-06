#!/bin/bash
set -euo pipefail

# This script checks that the required command-line tools exist.

required_tools=(bash grep awk sed sort uniq cut wc head tail)

missing=0

for t in "${required_tools[@]}"; do
  if ! command -v "$t" >/dev/null 2>&1; then
    echo "Missing tool: $t" >&2
    missing=1
  fi
done

if [ "$missing" -ne 0 ]; then
  echo "Setup FAILED: install missing tools." >&2
  exit 1
fi

echo "Setup OK: all required tools are available."
exit 0
