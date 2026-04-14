#!/bin/bash
# Main entrypoint for govulncheck-action
# Orchestrates validation and execution

set -euo pipefail

# Load validation functions (relative to action directory)
# shellcheck disable=SC1091
source "${GITHUB_ACTION_PATH}/src/validate.sh"

# Load argument builder (relative to action directory)
# shellcheck disable=SC1091
source "${GITHUB_ACTION_PATH}/src/build-args.sh"

# Get input values from environment
INPUTS_WORK_DIR="${INPUTS_WORK_DIR:-.}"
INPUTS_OUTPUT_FORMAT="${INPUTS_OUTPUT_FORMAT:-text}"
INPUTS_GO_PACKAGE="${INPUTS_GO_PACKAGE:-./...}"
INPUTS_SCAN_LEVEL="${INPUTS_SCAN_LEVEL:-symbol}"
INPUTS_INCLUDE_TESTS="${INPUTS_INCLUDE_TESTS:-false}"
INPUTS_BUILD_TAGS="${INPUTS_BUILD_TAGS:-}"
INPUTS_DB_URL="${INPUTS_DB_URL:-}"
INPUTS_MODE="${INPUTS_MODE:-source}"
INPUTS_SHOW="${INPUTS_SHOW:-}"
INPUTS_OUTPUT_FILE="${INPUTS_OUTPUT_FILE:-}"

# Get workspace path for validation
WORKSPACE="${GITHUB_WORKSPACE:-.}"

echo "Running validations..."
run_all_validations \
    "$INPUTS_OUTPUT_FORMAT" \
    "$INPUTS_SCAN_LEVEL" \
    "$INPUTS_MODE" \
    "$INPUTS_SHOW" \
    "$INPUTS_INCLUDE_TESTS" \
    "$INPUTS_GO_PACKAGE" \
    "$INPUTS_WORK_DIR" \
    "$INPUTS_OUTPUT_FILE" \
    "$WORKSPACE"

echo "Building govulncheck arguments..."
mapfile -t -d '' ARGS < <(build_args \
    "$INPUTS_WORK_DIR" \
    "$INPUTS_OUTPUT_FORMAT" \
    "$INPUTS_GO_PACKAGE" \
    "$INPUTS_SCAN_LEVEL" \
    "$INPUTS_INCLUDE_TESTS" \
    "$INPUTS_BUILD_TAGS" \
    "$INPUTS_DB_URL" \
    "$INPUTS_MODE" \
    "$INPUTS_SHOW"
)

echo "Running govulncheck with arguments: ${ARGS[*]}"

# Run govulncheck with or without output file
if [[ -n "$INPUTS_OUTPUT_FILE" ]]; then
    govulncheck "${ARGS[@]}" > "$INPUTS_OUTPUT_FILE"

    # Apply SARIF workaround if needed (https://github.com/golang/go/issues/75890)
    if [[ "$INPUTS_OUTPUT_FORMAT" == "sarif" ]]; then
        echo "Applying SARIF duplicate tags fix..."
        # shellcheck disable=SC1091
        source "${GITHUB_ACTION_PATH}/src/fix-sarif.sh"
        fix_sarif "$INPUTS_OUTPUT_FILE"
    fi
else
    govulncheck "${ARGS[@]}"
fi

echo "govulncheck completed successfully"
