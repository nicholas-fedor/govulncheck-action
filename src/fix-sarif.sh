#!/bin/bash
# SARIF post-processing to fix duplicate CVE tags
# Workaround for https://github.com/golang/go/issues/75890

# shellcheck disable=SC2317
# Command appears unreachable - but return is valid when sourced for BATS tests

set -euo pipefail

fix_sarif() {
    local output_file="$1"

    if [[ -z "$output_file" ]]; then
        echo "Error: INPUTS_OUTPUT_FILE is required"
        return 1
    fi

    if [[ ! -f "$output_file" ]]; then
        echo "Error: Output file does not exist: $output_file"
        return 1
    fi

    jq '.runs[].tool.driver.rules |= map(.properties.tags |= (if . != null then unique else . end))' "$output_file" > "${output_file}.tmp" && mv "${output_file}.tmp" "$output_file"

    echo "SARIF duplicate tags fixed"
}

# If sourced with test mode, run tests
if [[ "${BATS_TEST:-false}" == "true" ]]; then
    return 0 2>/dev/null || exit 0
fi

# If run directly, execute fix
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    INPUTS_OUTPUT_FILE="${INPUTS_OUTPUT_FILE:-}"
    fix_sarif "$INPUTS_OUTPUT_FILE"
fi
