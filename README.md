# riscv-log-analyzer

A shell-based tool that analyzes RISC-V simulation logs and generates summary reports.

## Features
- Counts total tests and PASS/FAIL/SKIP
- Pass rate calculation
- Lists failing test names
- Extracts timing info from `(0.82s)` and reports min/max/avg
- Output formats: text (default) and CSV

## Project Structure
```
riscv-log-analyzer/
├── README.md
├── Makefile
├── .gitignore
├── scripts/
│   ├── analyze.sh
│   ├── setup_env.sh
│   └── generate_report.sh
├── test_data/
│   ├── sample_sim.log
│   ├── sample_pass.log
│   └── sample_fail.log
├── output/          # generated (gitignored)
└── docs/
    └── USAGE.md
```

## Quick Start
```bash
make setup
make test
make report
```

## Examples

Text report:
```bash
./scripts/analyze.sh test_data/sample_fail.log
```

CSV report:
```bash
./scripts/analyze.sh test_data/sample_pass.log --format csv
```

Write report to a file:
```bash
./scripts/analyze.sh test_data/sample_fail.log --output output/fail_report.txt
```

Verbose mode:
```bash
./scripts/analyze.sh test_data/sample_pass.log --verbose
```

## Make Targets
- `make help`   : list targets
- `make setup`  : check required tools
- `make all`    : analyze all logs in `test_data/`
- `make test`   : basic checks (exit codes)
- `make report` : generate `output/summary_report.txt` and `output/report.html`
- `make clean`  : remove generated output filesConflictLine: B
