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

# ---------- args ----------
if [ $# -lt 1 ]; then
  usage
  exit 1
fi

LOGFILE="$1"
shift || true

while [ $# -gt 0 ]; do
  case "$1" in
    --help) usage; exit 0 ;;
    --verbose) VERBOSE=1; shift ;;
    --format)
      [ $# -ge 2 ] || { echo "Error: --format needs a value" >&2; exit 1; }
      FORMAT="$2"; shift 2 ;;
    --output)
      [ $# -ge 2 ] || { echo "Error: --output needs a path" >&2; exit 1; }
      OUTPUT="$2"; shift 2 ;;
    *) echo "Error: unknown option '$1'" >&2; usage; exit 1 ;;
  esac
done

# ---------- validate ----------
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

NOW="$(date "+%Y-%m-%d %H:%M:%S")"
vlog "LOGFILE=$LOGFILE FORMAT=$FORMAT OUTPUT=${OUTPUT:-stdout}"

# ---------- counts ----------
TOTAL="$(grep -E 'TEST (PASS|FAIL|SKIP):' "$LOGFILE" | wc -l | awk '{print $1}')"
PASS="$(grep -c 'TEST PASS:' "$LOGFILE" || true)"
FAIL="$(grep -c 'TEST FAIL:' "$LOGFILE" || true)"
SKIP="$(grep -c 'TEST SKIP:' "$LOGFILE" || true)"

PASS_RATE="$(awk -v p="$PASS" -v t="$TOTAL" 'BEGIN{ if(t==0) printf "0.0"; else printf "%.1f", (p*100.0/t) }')"

FAILED_LIST="$(grep 'TEST FAIL:' "$LOGFILE" | awk '{print $4}' | sed '/^$/d' || true)"

# ---------- timing stats (no awk quoting issues) ----------
TIMING_LINE="$(
awk -f - "$LOGFILE" <<'AWK'
BEGIN { tcount=0; }
{
  # Capture: TEST ...: <name> ... (<time>s)
  if (match($0, /TEST (PASS|FAIL|SKIP): ([^ ]+).* \(([0-9.]+)s\)/, m)) {
    test=m[2];
    time=m[3]+0.0;

    tcount++;
    tsum += time;

    if (tcount==1 || time < tmin) { tmin=time; tmin_name=test; }
    if (tcount==1 || time > tmax) { tmax=time; tmax_name=test; }
  }
}
END {
  if (tcount==0) {
    print "NA\tNA\tNA\tNA\tNA";
  } else {
    avg = tsum/tcount;
    printf("%.2f\t%s\t%.2f\t%s\t%.2f\n", tmin, tmin_name, tmax, tmax_name, avg);
  }
}
AWK
)"

IFS=$'\t' read -r MIN_T MIN_TEST MAX_T MAX_TEST AVG_T <<< "$TIMING_LINE"

# ---------- report ----------
if [ "$FORMAT" = "csv" ]; then
  FAILED_JOINED="$(printf "%s\n" "$FAILED_LIST" | paste -sd ';' -)"
  REPORT="log_file,total,pass,fail,skip,pass_rate,min_time,min_test,max_time,max_test,avg_time,failed_tests
$LOGFILE,$TOTAL,$PASS,$FAIL,$SKIP,$PASS_RATE,$MIN_T,$MIN_TEST,$MAX_T,$MAX_TEST,$AVG_T,$FAILED_JOINED"
else
  REPORT="=== RISC-V Simulation Log Analysis ===
Log file: $LOGFILE
Analysis date: $NOW
--- Results Summary ---
Total tests: $TOTAL
Passed: $PASS ($PASS_RATE%)
Failed: $FAIL
Skipped: $SKIP
--- Failed Tests ---"

  if [ "$FAIL" -eq 0 ]; then
    REPORT="$REPORT
None"
  else
    i=1
    while IFS= read -r t; do
      [ -n "$t" ] || continue
      REPORT="$REPORT
$i. $t"
      i=$((i+1))
    done <<< "$FAILED_LIST"
  fi

  REPORT="$REPORT
--- Timing Statistics ---"
  if [ "$MIN_T" = "NA" ]; then
    REPORT="$REPORT
No timing data found"
  else
    REPORT="$REPORT
Min time: ${MIN_T}s (${MIN_TEST})
Max time: ${MAX_T}s (${MAX_TEST})
Avg time: ${AVG_T}s"
  fi

  if [ "$FAIL" -gt 0 ]; then
    REPORT="$REPORT
--- Verdict: FAIL ---
Exit code: 1"
  else
    REPORT="$REPORT
--- Verdict: PASS ---
Exit code: 0"
  fi
fi

# ---------- output ----------
if [ -n "$OUTPUT" ]; then
  printf "%s\n" "$REPORT" > "$OUTPUT"
else
  printf "%s\n" "$REPORT"
fi

# ---------- exit code ----------
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0