#!/bin/bash
# Build govulncheck arguments based on inputs
# Returns the arguments as a space-separated string

# shellcheck disable=SC2317
# Command appears unreachable - but return is valid when sourced for BATS tests

set -euo pipefail

build_args() {
    local work_dir="$1"
    local output_format="$2"
    local go_package="$3"
    local scan_level="$4"
    local include_tests="$5"
    local build_tags="$6"
    local db_url="$7"
    local mode="$8"
    local show="$9"

    local args=("-C" "$work_dir" "-format" "$output_format")

    # Only add -scan-level if not default (symbol)
    if [[ -n "$scan_level" && "$scan_level" != "symbol" ]]; then
        args+=(-scan-level "$scan_level")
    fi

    # Only add -test if explicitly enabled and in source mode
    # Note: -test is only valid for source mode
    if [[ "$include_tests" == "true" && "$mode" == "source" ]]; then
        args+=(-test)
    fi

    # Only add -tags if provided
    if [[ -n "$build_tags" ]]; then
        args+=(-tags "$build_tags")
    fi

    # Only add -db if custom DB URL provided
    if [[ -n "$db_url" ]]; then
        args+=(-db "$db_url")
    fi

    # Only add -mode if not default (source)
    if [[ -n "$mode" && "$mode" != "source" ]]; then
        args+=(-mode "$mode")
    fi

    # Only add -show if provided and output format is text
    # Note: -show is only valid for text output format
    if [[ -n "$show" && "$output_format" == "text" ]]; then
        args+=(-show "$show")
    fi

    # Add the package to scan
    args+=("$go_package")

    # Output the arguments with NUL delimiter
    printf '%s\0' "${args[@]}"
}

# If sourced with test mode, run tests
if [[ "${BATS_TEST:-false}" == "true" ]]; then
    return 0 2>/dev/null || exit 0
fi

# If run directly, build and print arguments
if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" == "${0}" ]]; then
    build_args \
        "${INPUTS_WORK_DIR:-.}" \
        "${INPUTS_OUTPUT_FORMAT:-text}" \
        "${INPUTS_GO_PACKAGE:-./...}" \
        "${INPUTS_SCAN_LEVEL:-symbol}" \
        "${INPUTS_INCLUDE_TESTS:-false}" \
        "${INPUTS_BUILD_TAGS:-}" \
        "${INPUTS_DB_URL:-}" \
        "${INPUTS_MODE:-source}" \
        "${INPUTS_SHOW:-}"
fi
