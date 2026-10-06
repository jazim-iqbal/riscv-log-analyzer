#!/bin/bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/analyze.sh <logfile> [--format text|csv] [--output <path>] [--verbose] [--help]

Options:
  --format text|csv   (default: text)
  --output <path>     write report to file (default: stdout)
  --verbose           verbose logs to stderr
  --help              show help

Exit codes:
  0  if no FAIL tests
  1  if any FAIL tests OR invalid usage
USAGE
}

VERBOSE=0
FORMAT="text"
OUTPUT=""

vlog() { if [ "$VERBOSE" -eq 1 ]; then echo "[VERBOSE] $*" >&2; fi; }

# ---- args ----
if [ $# -lt 1 ]; then usage; exit 1; fi
LOGFILE="$1"
shift || true

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

# ---- analyze ----
AWK_OUT="$(awk '
function pct(a,b){ return (b==0)?0:(a*100.0/b) }

{
  if (match($0, /TEST (PASS|FAIL|SKIP): ([^ ]+)/, m)) {
    res=m[1]; test=m[2];
    total++;
    if (res=="PASS") pass++;
    else if (res=="FAIL") { fail++; fails[++fcount]=test; }
    else if (res=="SKIP") skip++;
  }
}

END{
  pass_rate=pct(pass,total);

  if (ENVIRON["FMT"]=="csv") {
    failed="";
    for(i=1;i<=fcount;i++) failed=failed ((i==1)?"":";") fails[i];
    print "total,pass,fail,skip,pass_rate,failed_tests";
    printf("%d,%d,%d,%d,%.1f,%s\n", total,pass,fail,skip,pass_rate,failed);
  } else {
    print "=== RISC-V Simulation Log Analysis ==="
    print "Log file: " ENVIRON["LOGFILE"]
    print "--- Results Summary ---"
    printf("Total tests: %d\n", total)
    printf("Passed: %d (%.1f%%)\n", pass, pct(pass,total))
    printf("Failed: %d (%.1f%%)\n", fail, pct(fail,total))
    printf("Skipped: %d (%.1f%%)\n", skip, pct(skip,total))

    print "--- Failed Tests ---"
    if (fcount==0) print "None"
    else for(i=1;i<=fcount;i++) printf("%d. %s\n", i, fails[i])

    if (fail>0) print "--- Verdict: FAIL ---"
    else        print "--- Verdict: PASS ---"
  }

  printf("__FAIL_COUNT__=%d\n", fail)
}
' "$LOGFILE")"

FAIL_COUNT="$(printf "%s\n" "$AWK_OUT" | tail -n 1 | cut -d= -f2)"
REPORT="$(printf "%s\n" "$AWK_OUT" | sed '$d')"

if [ -n "$OUTPUT" ]; then
  printf "%s\n" "$REPORT" > "$OUTPUT"
else
  printf "%s\n" "$REPORT"
fi

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
