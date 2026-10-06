# Usage Guide

## analyze.sh

```bash
./scripts/analyze.sh <logfile> [--format text|csv] [--output <path>] [--verbose] [--help]
```

### Arguments
- `<logfile>`: Path to the log file (required)

### Options
- `--format text|csv` (default: `text`)
- `--output <path>` (default: stdout)
- `--verbose`
- `--compare <oldlog>` show regressions (old PASS -> new FAIL)
- `--help`

### Exit Codes
- `0` if no FAIL tests
- `1` if any FAIL tests OR invalid usage