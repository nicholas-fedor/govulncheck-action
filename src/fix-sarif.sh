#!/bin/bash
# SARIF post-processing to fix duplicate CVE tags
# Workaround for https://github.com/golang/go/issues/75890

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

    local temp_file
    temp_file=$(mktemp)

    trap 'rm -f "$temp_file"' EXIT

    jq '.runs[].tool.driver.rules |= map(select(.properties != null and .properties.tags != null) | .properties.tags |= unique)' "$output_file" > "$temp_file" && mv "$temp_file" "$output_file"

    trap - EXIT

    echo "SARIF duplicate tags fixed"
}

# If run directly, execute fix
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    INPUTS_OUTPUT_FILE="${INPUTS_OUTPUT_FILE:-}"
    fix_sarif "$INPUTS_OUTPUT_FILE"
fi
