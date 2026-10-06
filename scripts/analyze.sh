#!/bin/bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/analyze.sh <logfile> [--format text|csv] [--output <path>] [--verbose] [--help]

Exit codes:
  0  if analysis runs and no FAIL tests
  1  if FAIL tests found OR invalid usage
USAGE
}

VERBOSE=0
FORMAT="text"
OUTPUT=""

vlog() { if [ "$VERBOSE" -eq 1 ]; then echo "[VERBOSE] $*" >&2; fi; }

# ---- basic args ----
if [ $# -lt 1 ]; then
  usage
  exit 1
fi

LOGFILE="$1"
shift || true

# ---- parse flags ----
while [ $# -gt 0 ]; do
  case "$1" in
    --help) usage; exit 0 ;;
    --verbose) VERBOSE=1; shift ;;
    --format) FORMAT="${2:-}"; shift 2 ;;
    --output) OUTPUT="${2:-}"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

# ---- validate ----
if [ ! -f "$LOGFILE" ]; then
  echo "Error: log file not found: $LOGFILE" >&2
  exit 1
fi

if [ "$FORMAT" != "text" ] && [ "$FORMAT" != "csv" ]; then
  echo "Error: --format must be text or csv" >&2
  exit 1
fi

if [ -n "$OUTPUT" ]; then
  mkdir -p "$(dirname "$OUTPUT")"
fi

vlog "LOGFILE=$LOGFILE FORMAT=$FORMAT OUTPUT=${OUTPUT:-stdout}"

echo "TODO: analysis will be implemented in next step"
exit 0
