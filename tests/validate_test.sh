#!/usr/bin/env bats

load ../src/validate.sh

@test "validate_output_format accepts text" {
    if validate_output_format "text"; then
        :
    else
        return 1
    fi
}

@test "validate_output_format accepts json" {
    if validate_output_format "json"; then
        :
    else
        return 1
    fi
}

@test "validate_output_format accepts sarif" {
    if validate_output_format "sarif"; then
        :
    else
        return 1
    fi
}

@test "validate_output_format accepts openvex" {
    if validate_output_format "openvex"; then
        :
    else
        return 1
    fi
}

@test "validate_output_format rejects invalid" {
    run validate_output_format "invalid"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Invalid output-format"* ]]
}

@test "validate_scan_level accepts symbol" {
    if validate_scan_level "symbol"; then
        :
    else
        return 1
    fi
}

@test "validate_scan_level accepts package" {
    if validate_scan_level "package"; then
        :
    else
        return 1
    fi
}

@test "validate_scan_level accepts module" {
    if validate_scan_level "module"; then
        :
    else
        return 1
    fi
}

@test "validate_scan_level rejects invalid" {
    run validate_output_format "invalid"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Invalid output-format"* ]]
}

@test "validate_mode accepts source" {
    if validate_mode "source"; then
        :
    else
        return 1
    fi
}

@test "validate_mode accepts binary" {
    if validate_mode "binary"; then
        :
    else
        return 1
    fi
}

@test "validate_mode accepts extract" {
    if validate_mode "extract"; then
        :
    else
        return 1
    fi
}

@test "validate_mode rejects invalid" {
    run validate_mode "invalid"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Invalid mode"* ]]
}

@test "validate_show accepts traces" {
    if validate_show "traces"; then
        :
    else
        return 1
    fi
}

@test "validate_show accepts verbose" {
    if validate_show "verbose"; then
        :
    else
        return 1
    fi
}

@test "validate_show rejects invalid" {
    run validate_show "invalid"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Invalid show"* ]]
}

@test "validate_include_tests accepts true" {
    if validate_include_tests "true"; then
        :
    else
        return 1
    fi
}

@test "validate_include_tests accepts false" {
    if validate_include_tests "false"; then
        :
    else
        return 1
    fi
}

@test "validate_include_tests accepts empty string" {
    if validate_include_tests ""; then
        :
    else
        return 1
    fi
}

@test "validate_include_tests rejects invalid" {
    run validate_include_tests "maybe"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Invalid include-tests"* ]]
}

@test "validate_go_package accepts ./..." {
    if validate_go_package "./..."; then
        :
    else
        return 1
    fi
}

@test "validate_go_package accepts ./cmd/app" {
    if validate_go_package "./cmd/app"; then
        :
    else
        return 1
    fi
}

@test "validate_go_package rejects empty" {
    run validate_go_package ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: go-package cannot be empty"* ]]
}

@test "run_all_validations passes with valid inputs" {
    if run_all_validations "json" "symbol" "source" "" "false" "./..." "." "" "/workspace"; then
        :
    else
        return 1
    fi
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
    if validate_output_file_path "results.json" "/workspace"; then
        :
    else
        return 1
    fi
}

@test "validate_output_file_path allows empty path" {
    if validate_output_file_path "" "/workspace"; then
        :
    else
        return 1
    fi
}

@test "validate_output_file_path rejects path traversal" {
    run validate_output_file_path "../etc/passwd" "/workspace"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: output-file path must be within workspace"* ]]
}

@test "validate_work_dir_path allows valid path" {
    if validate_work_dir_path "src" "/workspace"; then
        :
    else
        return 1
    fi
}

@test "validate_work_dir_path allows dot" {
    if validate_work_dir_path "." "/workspace"; then
        :
    else
        return 1
    fi
}

@test "validate_work_dir_path rejects path traversal" {
    run validate_work_dir_path "../etc" "/workspace"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: work-dir path must be within workspace"* ]]
}

@test "validate_output_file_path rejects absolute path" {
    run validate_output_file_path "/etc/passwd" "/workspace"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: output-file path must be a relative path"* ]]
}

@test "validate_output_file_path rejects encoded traversal" {
    run validate_output_file_path "%2e%2e/%2e%2e/etc" "/workspace"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: output-file path must be within workspace"* ]]
}

@test "validate_output_file_path rejects double-encoded traversal" {
    run validate_output_file_path "..%252f..%252fetc" "/workspace"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: output-file path must be within workspace"* ]]
}

@test "validate_work_dir_path rejects absolute path" {
    run validate_work_dir_path "/etc/passwd" "/workspace"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: work-dir path must be a relative path"* ]]
}

@test "validate_work_dir_path rejects encoded traversal" {
    run validate_work_dir_path "%2e%2e/%2e%2e/etc" "/workspace"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: work-dir path must be within workspace"* ]]
}

@test "validate_work_dir_path rejects double-encoded traversal" {
    run validate_work_dir_path "..%252f..%252fetc" "/workspace"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: work-dir path must be within workspace"* ]]
}