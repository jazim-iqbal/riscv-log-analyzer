.PHONY: help setup all test report clean

LOGS := $(wildcard test_data/*.log)

help:
	@echo "Targets:"
	@echo "  setup   - Check required tools"
	@echo "  all     - Run analyzer on all logs"
	@echo "  test    - Run basic tests (exit codes)"
	@echo "  report  - Generate output reports (text + HTML)"
	@echo "  clean   - Remove generated output files"

setup:
	@./scripts/setup_env.sh

all: setup
	@for f in $(LOGS); do \
		echo "----- $$f -----"; \
		./scripts/analyze.sh "$$f" || true; \
		echo ""; \
	done

test: setup
	@echo "Test: sample_pass.log should exit 0"
	@./scripts/analyze.sh test_data/sample_pass.log > /dev/null
	@echo "OK"

	@echo "Test: sample_fail.log should exit 1"
	@./scripts/analyze.sh test_data/sample_fail.log > /dev/null; \
	if [ $$? -eq 0 ]; then echo "FAIL: expected exit 1"; exit 1; fi
	@echo "OK"

	@echo "All tests passed."

report: setup
	@./scripts/generate_report.sh

clean:
	@rm -rf output/*
	@echo "Cleaned output/"
