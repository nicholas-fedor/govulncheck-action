#!/usr/bin/env bats

load ../src/validate.sh

@test "validate_output_format accepts text" {
    run validate_output_format "text"
    [ "$status" -eq 0 ]
}

@test "validate_output_format accepts json" {
    run validate_output_format "json"
    [ "$status" -eq 0 ]
}

@test "validate_output_format accepts sarif" {
    run validate_output_format "sarif"
    [ "$status" -eq 0 ]
}

@test "validate_output_format accepts openvex" {
    run validate_output_format "openvex"
    [ "$status" -eq 0 ]
}

@test "validate_output_format rejects invalid" {
    run validate_output_format "invalid"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Invalid output-format"* ]]
}

@test "validate_scan_level accepts symbol" {
    run validate_scan_level "symbol"
    [ "$status" -eq 0 ]
}

@test "validate_scan_level accepts package" {
    run validate_scan_level "package"
    [ "$status" -eq 0 ]
}

@test "validate_scan_level accepts module" {
    run validate_scan_level "module"
    [ "$status" -eq 0 ]
}

@test "validate_scan_level rejects invalid" {
    run validate_scan_level "invalid"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Invalid scan-level"* ]]
}

@test "validate_mode accepts source" {
    run validate_mode "source"
    [ "$status" -eq 0 ]
}

@test "validate_mode accepts binary" {
    run validate_mode "binary"
    [ "$status" -eq 0 ]
}

@test "validate_mode accepts extract" {
    run validate_mode "extract"
    [ "$status" -eq 0 ]
}

@test "validate_mode rejects invalid" {
    run validate_mode "invalid"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Invalid mode"* ]]
}

@test "validate_show accepts traces" {
    run validate_show "traces"
    [ "$status" -eq 0 ]
}

@test "validate_show accepts verbose" {
    run validate_show "verbose"
    [ "$status" -eq 0 ]
}

@test "validate_show rejects invalid" {
    run validate_show "invalid"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Invalid show"* ]]
}

@test "validate_include_tests accepts true" {
    run validate_include_tests "true"
    [ "$status" -eq 0 ]
}

@test "validate_include_tests accepts false" {
    run validate_include_tests "false"
    [ "$status" -eq 0 ]
}

@test "validate_include_tests rejects empty string" {
    run validate_include_tests ""
    [ "$status" -eq 0 ]
}

@test "validate_include_tests rejects invalid" {
    run validate_include_tests "maybe"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Invalid include-tests"* ]]
}

@test "validate_go_package accepts ./..." {
    run validate_go_package "./..."
    [ "$status" -eq 0 ]
}

@test "validate_go_package accepts ./cmd/app" {
    run validate_go_package "./cmd/app"
    [ "$status" -eq 0 ]
}

@test "validate_go_package rejects empty" {
    run validate_go_package ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: go-package cannot be empty"* ]]
}

@test "run_all_validations passes with valid inputs" {
    run run_all_validations "json" "symbol" "source" "" "false" "./..." "." "" "/workspace"
    [ "$status" -eq 0 ]
}

@test "run_all_validations fails with invalid output-format" {
    run run_all_validations "invalid" "symbol" "source" "" "false" "./..." "." "" "/workspace"
    [ "$status" -eq 1 ]
}

@test "run_all_validations fails with invalid scan-level" {
    run run_all_validations "text" "invalid" "source" "" "false" "./..." "." "" "/workspace"
    [ "$status" -eq 1 ]
}

@test "run_all_validations fails with invalid mode" {
    run run_all_validations "text" "symbol" "invalid" "" "false" "./..." "." "" "/workspace"
    [ "$status" -eq 1 ]
}

@test "run_all_validations fails with invalid show" {
    run run_all_validations "text" "symbol" "source" "invalid" "false" "./..." "." "" "/workspace"
    [ "$status" -eq 1 ]
}

@test "run_all_validations fails with invalid include-tests" {
    run run_all_validations "text" "symbol" "source" "" "maybe" "./..." "." "" "/workspace"
    [ "$status" -eq 1 ]
}

@test "run_all_validations fails with empty go-package" {
    run run_all_validations "text" "symbol" "source" "" "false" "" "." "" "."
    [ "$status" -eq 1 ]
}

@test "validate_output_file_path allows valid path" {
    run validate_output_file_path "results.json" "/workspace"
    [ "$status" -eq 0 ]
}

@test "validate_output_file_path allows empty path" {
    run validate_output_file_path "" "/workspace"
    [ "$status" -eq 0 ]
}

@test "validate_output_file_path rejects path traversal" {
    run validate_output_file_path "../etc/passwd" "/workspace"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: output-file path must be within workspace"* ]]
}

@test "validate_work_dir_path allows valid path" {
    run validate_work_dir_path "src" "/workspace"
    [ "$status" -eq 0 ]
}

@test "validate_work_dir_path allows dot" {
    run validate_work_dir_path "." "/workspace"
    [ "$status" -eq 0 ]
}

@test "validate_work_dir_path rejects path traversal" {
    run validate_work_dir_path "../etc" "/workspace"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: work-dir path must be within workspace"* ]]
}
