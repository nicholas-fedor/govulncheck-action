#!/bin/bash
# Validation functions for govulncheck-action
# These functions are pure and testable

set -euo pipefail

validate_output_format() {
    local value="$1"
    case "$value" in
        text|json|sarif|openvex) return 0 ;;
        *) echo "Error: Invalid output-format '$value'. Valid values: text, json, sarif, openvex" && return 1 ;;
    esac
}

validate_scan_level() {
    local value="$1"
    case "$value" in
        module|package|symbol) return 0 ;;
        *) echo "Error: Invalid scan-level '$value'. Valid values: module, package, symbol" && return 1 ;;
    esac
}

validate_mode() {
    local value="$1"
    case "$value" in
        source|binary|extract) return 0 ;;
        *) echo "Error: Invalid mode '$value'. Valid values: source, binary, extract" && return 1 ;;
    esac
}

validate_show() {
    local value="$1"
    case "$value" in
        traces|verbose) return 0 ;;
        *) echo "Error: Invalid show '$value'. Valid values: traces, verbose" && return 1 ;;
    esac
}

validate_include_tests() {
    local value="$1"
    if [[ -n "$value" && "$value" != "true" && "$value" != "false" ]]; then
        echo "Error: Invalid include-tests '$value'. Valid values: true, false"
        return 1
    fi
    return 0
}

validate_go_package() {
    local value="$1"
    if [[ -z "$value" ]]; then
        echo "Error: go-package cannot be empty"
        return 1
    fi
    return 0
}

# Security: Validate output-file path is within workspace
validate_output_file_path() {
    local output_file="$1"
    local workspace="${2:-.}"

    if [[ -z "$output_file" ]]; then
        return 0
    fi

    local output_path
    output_path="$(realpath -m "$workspace/$output_file" 2>/dev/null || echo "$workspace/$output_file")"
    local workspace_path
    workspace_path="$(realpath -m "$workspace" 2>/dev/null || echo "$workspace")"

    if [[ "$output_path" != "$workspace_path"* ]]; then
        echo "Error: output-file path must be within workspace"
        return 1
    fi
    return 0
}

# Security: Validate work-dir path is within workspace
validate_work_dir_path() {
    local work_dir="$1"
    local workspace="${2:-.}"

    if [[ -z "$work_dir" || "$work_dir" == "." ]]; then
        return 0
    fi

    local work_dir_path
    work_dir_path="$(realpath -m "$workspace/$work_dir" 2>/dev/null || echo "$workspace/$work_dir")"
    local workspace_path
    workspace_path="$(realpath -m "$workspace" 2>/dev/null || echo "$workspace")"

    if [[ "$work_dir_path" != "$workspace_path"* ]]; then
        echo "Error: work-dir path must be within workspace"
        return 1
    fi
    return 0
}

run_all_validations() {
    local output_format="${1:-}"
    local scan_level="${2:-}"
    local mode="${3:-}"
    local show="${4:-}"
    local include_tests="${5:-}"
    local go_package="${6:-}"
    local work_dir="${7:-.}"
    local output_file="${8:-}"
    local workspace="${9:-.}"

    # Validate output-format
    if [[ -n "$output_format" ]]; then
        validate_output_format "$output_format" || return 1
    fi

    # Validate scan-level
    if [[ -n "$scan_level" ]]; then
        validate_scan_level "$scan_level" || return 1
    fi

    # Validate mode
    if [[ -n "$mode" ]]; then
        validate_mode "$mode" || return 1
    fi

    # Validate show
    if [[ -n "$show" ]]; then
        validate_show "$show" || return 1
    fi

    # Validate include-tests
    if [[ -n "$include_tests" ]]; then
        validate_include_tests "$include_tests" || return 1
    fi

    # Validate go-package (required, cannot be empty)
    validate_go_package "$go_package" || return 1

    # Security: Validate work-dir path
    validate_work_dir_path "$work_dir" "$workspace" || return 1

    # Security: Validate output-file path
    validate_output_file_path "$output_file" "$workspace" || return 1

    return 0
}
