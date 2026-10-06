#!/bin/bash
set -euo pipefail

OUTDIR="output"
mkdir -p "$OUTDIR"

TXT_REPORT="$OUTDIR/summary_report.txt"
HTML_REPORT="$OUTDIR/report.html"

: > "$TXT_REPORT"

# HTML header
cat > "$HTML_REPORT" <<'HTML'
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>RISC-V Log Report</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    table { border-collapse: collapse; width: 100%; }
    th, td { border: 1px solid #ddd; padding: 8px; }
    th { background: #f2f2f2; }
    .pass { color: green; font-weight: bold; }
    .fail { color: red; font-weight: bold; }
  </style>
</head>
<body>
<h2>RISC-V Log Analyzer Report</h2>
<table>
  <tr>
    <th>Log File</th>
    <th>Total</th>
    <th>Pass</th>
    <th>Fail</th>
    <th>Skip</th>
    <th>Pass Rate (%)</th>
    <th>Min Time</th>
    <th>Max Time</th>
    <th>Avg Time</th>
    <th>Verdict</th>
  </tr>
HTML

for f in test_data/*.log; do
  echo "==============================" >> "$TXT_REPORT"
  echo "FILE: $f" >> "$TXT_REPORT"
  echo "==============================" >> "$TXT_REPORT"

  # IMPORTANT: analyzer returns exit 1 on FAIL logs (expected), so don't stop the script:
  ./scripts/analyze.sh "$f" --format text >> "$TXT_REPORT" || true
  echo "" >> "$TXT_REPORT"

  CSV_ALL="$(./scripts/analyze.sh "$f" --format csv 2>/dev/null || true)"
  CSV_ROW="$(printf "%s\n" "$CSV_ALL" | tail -n 1)"

  IFS=',' read -r log_file total pass fail skip pass_rate min_time min_test max_time max_test avg_time failed_tests <<< "$CSV_ROW"

  if [ "${fail:-0}" -gt 0 ]; then
    verdict="FAIL"
    verdict_class="fail"
  else
    verdict="PASS"
    verdict_class="pass"
  fi

  cat >> "$HTML_REPORT" <<HTML
  <tr>
    <td>${log_file}</td>
    <td>${total}</td>
    <td>${pass}</td>
    <td>${fail}</td>
    <td>${skip}</td>
    <td>${pass_rate}</td>
    <td>${min_time}s</td>
    <td>${max_time}s</td>
    <td>${avg_time}s</td>
    <td class="${verdict_class}">${verdict}</td>
  </tr>
HTML
done

# HTML footer
cat >> "$HTML_REPORT" <<'HTML'
</table>
</body>
</html>
HTML

echo "Wrote: $TXT_REPORT"
echo "Wrote: $HTML_REPORT"