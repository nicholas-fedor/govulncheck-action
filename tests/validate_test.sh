#!/usr/bin/env bats

# shellcheck source=../src/validate.sh disable=SC1091
source "${BATS_TEST_DIRNAME}/../src/validate.sh"

@test "validate_output_format accepts text"    { validate_output_format "text"    || return 1; }
@test "validate_output_format accepts json"    { validate_output_format "json"    || return 1; }
@test "validate_output_format accepts sarif"   { validate_output_format "sarif"   || return 1; }
@test "validate_output_format accepts openvex" { validate_output_format "openvex" || return 1; }

@test "validate_output_format rejects invalid" {
    local tmp status=0
    tmp=$(mktemp)
    validate_output_format "invalid" > "$tmp" 2>&1 || status=$?
    output=$(cat "$tmp")
    rm -f "$tmp"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"Error: Invalid output-format"* ]]
}

@test "validate_scan_level accepts symbol"  { validate_scan_level "symbol"  || return 1; }
@test "validate_scan_level accepts package" { validate_scan_level "package" || return 1; }
@test "validate_scan_level accepts module"  { validate_scan_level "module"  || return 1; }

@test "validate_scan_level rejects invalid" {
    local tmp status=0
    tmp=$(mktemp)
    validate_scan_level "invalid" > "$tmp" 2>&1 || status=$?
    output=$(cat "$tmp")
    rm -f "$tmp"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"Error: Invalid scan-level"* ]]
}

@test "validate_mode accepts source"  { validate_mode "source"  || return 1; }
@test "validate_mode accepts binary"  { validate_mode "binary"  || return 1; }
@test "validate_mode accepts extract" { validate_mode "extract" || return 1; }

@test "validate_mode rejects invalid" {
    local tmp status=0
    tmp=$(mktemp)
    validate_mode "invalid" > "$tmp" 2>&1 || status=$?
    output=$(cat "$tmp")
    rm -f "$tmp"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"Error: Invalid mode"* ]]
}

@test "validate_show accepts traces"  { validate_show "traces"  || return 1; }
@test "validate_show accepts verbose" { validate_show "verbose" || return 1; }

@test "validate_show rejects invalid" {
    local tmp status=0
    tmp=$(mktemp)
    validate_show "invalid" > "$tmp" 2>&1 || status=$?
    output=$(cat "$tmp")
    rm -f "$tmp"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"Error: Invalid show"* ]]
}

@test "validate_include_tests accepts true"         { validate_include_tests "true"  || return 1; }
@test "validate_include_tests accepts false"        { validate_include_tests "false" || return 1; }
@test "validate_include_tests accepts empty string" { validate_include_tests ""      || return 1; }

@test "validate_include_tests rejects invalid" {
    local tmp status=0
    tmp=$(mktemp)
    validate_include_tests "maybe" > "$tmp" 2>&1 || status=$?
    output=$(cat "$tmp")
    rm -f "$tmp"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"Error: Invalid include-tests"* ]]
}

@test "validate_go_package accepts ./..."     { validate_go_package "./..."     || return 1; }
@test "validate_go_package accepts ./cmd/app" { validate_go_package "./cmd/app" || return 1; }

@test "validate_go_package rejects empty" {
    local tmp status=0
    tmp=$(mktemp)
    validate_go_package "" > "$tmp" 2>&1 || status=$?
    output=$(cat "$tmp")
    rm -f "$tmp"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"Error: go-package cannot be empty"* ]]
}

@test "run_all_validations passes with valid inputs" {
    run_all_validations "json" "symbol" "source" "" "false" "./..." "." "" "/workspace" || return 1
}

@test "run_all_validations fails with invalid output-format" {
    local tmp status=0
    tmp=$(mktemp)
    run_all_validations "invalid" "symbol" "source" "" "false" "./..." "." "" "/workspace" > "$tmp" 2>&1 || status=$?
    output=$(cat "$tmp")
    rm -f "$tmp"
    [[ "$status" -eq 1 ]]
}

@test "run_all_validations fails with invalid scan-level" {
    local tmp status=0
    tmp=$(mktemp)
    run_all_validations "text" "invalid" "source" "" "false" "./..." "." "" "/workspace" > "$tmp" 2>&1 || status=$?
    output=$(cat "$tmp")
    rm -f "$tmp"
    [[ "$status" -eq 1 ]]
}

@test "run_all_validations fails with invalid mode" {
    local tmp status=0
    tmp=$(mktemp)
    run_all_validations "text" "symbol" "invalid" "" "false" "./..." "." "" "/workspace" > "$tmp" 2>&1 || status=$?
    output=$(cat "$tmp")
    rm -f "$tmp"
    [[ "$status" -eq 1 ]]
}

@test "run_all_validations fails with invalid show" {
    local tmp status=0
    tmp=$(mktemp)
    run_all_validations "text" "symbol" "source" "invalid" "false" "./..." "." "" "/workspace" > "$tmp" 2>&1 || status=$?
    output=$(cat "$tmp")
    rm -f "$tmp"
    [[ "$status" -eq 1 ]]
}

@test "run_all_validations fails with invalid include-tests" {
    local tmp status=0
    tmp=$(mktemp)
    run_all_validations "text" "symbol" "source" "" "maybe" "./..." "." "" "/workspace" > "$tmp" 2>&1 || status=$?
    output=$(cat "$tmp")
    rm -f "$tmp"
    [[ "$status" -eq 1 ]]
}

@test "run_all_validations fails with empty go-package" {
    local tmp status=0
    tmp=$(mktemp)
    run_all_validations "text" "symbol" "source" "" "false" "" "." "" "." > "$tmp" 2>&1 || status=$?
    output=$(cat "$tmp")
    rm -f "$tmp"
    [[ "$status" -eq 1 ]]
}

@test "validate_output_file_path allows valid path"     { validate_output_file_path "results.json" "/workspace" || return 1; }
@test "validate_output_file_path allows empty path"     { validate_output_file_path "" "/workspace" || return 1; }
@test "validate_work_dir_path allows valid path"        { validate_work_dir_path "src" "/workspace" || return 1; }
@test "validate_work_dir_path allows dot"               { validate_work_dir_path "." "/workspace" || return 1; }

@test "validate_output_file_path rejects path traversal" {
    local tmp status=0
    tmp=$(mktemp)
    validate_output_file_path "../etc/passwd" "/workspace" > "$tmp" 2>&1 || status=$?
    output=$(cat "$tmp")
    rm -f "$tmp"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"Error: output-file path must be within workspace"* ]]
}

@test "validate_work_dir_path rejects path traversal" {
    local tmp status=0
    tmp=$(mktemp)
    validate_work_dir_path "../etc" "/workspace" > "$tmp" 2>&1 || status=$?
    output=$(cat "$tmp")
    rm -f "$tmp"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"Error: work-dir path must be within workspace"* ]]
}

@test "validate_output_file_path rejects absolute path" {
    local tmp status=0
    tmp=$(mktemp)
    validate_output_file_path "/etc/passwd" "/workspace" > "$tmp" 2>&1 || status=$?
    output=$(cat "$tmp")
    rm -f "$tmp"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"Error: output-file path must be a relative path"* ]]
}

@test "validate_output_file_path rejects encoded traversal" {
    local tmp status=0
    tmp=$(mktemp)
    validate_output_file_path "%2e%2e/%2e%2e/etc" "/workspace" > "$tmp" 2>&1 || status=$?
    output=$(cat "$tmp")
    rm -f "$tmp"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"Error: output-file path must be within workspace"* ]]
}

@test "validate_output_file_path rejects double-encoded traversal" {
    local tmp status=0
    tmp=$(mktemp)
    validate_output_file_path "..%252f..%252fetc" "/workspace" > "$tmp" 2>&1 || status=$?
    output=$(cat "$tmp")
    rm -f "$tmp"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"Error: output-file path must be within workspace"* ]]
}

@test "validate_work_dir_path rejects absolute path" {
    local tmp status=0
    tmp=$(mktemp)
    validate_work_dir_path "/etc/passwd" "/workspace" > "$tmp" 2>&1 || status=$?
    output=$(cat "$tmp")
    rm -f "$tmp"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"Error: work-dir path must be a relative path"* ]]
}

@test "validate_work_dir_path rejects encoded traversal" {
    local tmp status=0
    tmp=$(mktemp)
    validate_work_dir_path "%2e%2e/%2e%2e/etc" "/workspace" > "$tmp" 2>&1 || status=$?
    output=$(cat "$tmp")
    rm -f "$tmp"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"Error: work-dir path must be within workspace"* ]]
}

@test "validate_work_dir_path rejects double-encoded traversal" {
    local tmp status=0
    tmp=$(mktemp)
    validate_work_dir_path "..%252f..%252fetc" "/workspace" > "$tmp" 2>&1 || status=$?
    output=$(cat "$tmp")
    rm -f "$tmp"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"Error: work-dir path must be within workspace"* ]]
}
