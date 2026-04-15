#!/usr/bin/env bats

load ../src/build-args.sh

@test "build_args returns basic arguments" {
    local output_file
    output_file=$(mktemp)
    build_args "." "text" "./..." "symbol" "false" "" "" "source" "" > "$output_file"
    mapfile -t -d '' result < "$output_file"
    rm -f "$output_file"
    result_str="${result[*]}"
    [[ "$result_str" == *"-C"*". "*"-format"*text*"./..."* ]]
}

@test "build_args includes scan-level when not default" {
    local output_file
    output_file=$(mktemp)
    build_args "." "text" "./..." "module" "false" "" "" "source" "" > "$output_file"
    mapfile -t -d '' result < "$output_file"
    rm -f "$output_file"
    result_str="${result[*]}"
    [[ "$result_str" == *"-scan-level"*module* ]]
}

@test "build_args excludes scan-level when default" {
    local output_file
    output_file=$(mktemp)
    build_args "." "text" "./..." "symbol" "false" "" "" "source" "" > "$output_file"
    mapfile -t -d '' result < "$output_file"
    rm -f "$output_file"
    result_str="${result[*]}"
    [[ "$result_str" != *"-scan-level"* ]]
}

@test "build_args includes -test when enabled in source mode" {
    local output_file
    output_file=$(mktemp)
    build_args "." "text" "./..." "symbol" "true" "" "" "source" "" > "$output_file"
    mapfile -t -d '' result < "$output_file"
    rm -f "$output_file"
    result_str="${result[*]}"
    [[ "$result_str" == *"-test"* ]]
}

@test "build_args excludes -test when disabled" {
    local output_file
    output_file=$(mktemp)
    build_args "." "text" "./..." "symbol" "false" "" "" "source" "" > "$output_file"
    mapfile -t -d '' result < "$output_file"
    rm -f "$output_file"
    result_str="${result[*]}"
    [[ "$result_str" != *"-test"* ]]
}

@test "build_args excludes -test in binary mode" {
    local output_file
    output_file=$(mktemp)
    build_args "." "text" "./..." "symbol" "true" "" "" "binary" "" > "$output_file"
    mapfile -t -d '' result < "$output_file"
    rm -f "$output_file"
    result_str="${result[*]}"
    [[ "$result_str" != *"-test"* ]]
}

@test "build_args includes -tags when provided" {
    local output_file
    output_file=$(mktemp)
    build_args "." "text" "./..." "symbol" "false" "tag1,tag2" "" "source" "" > "$output_file"
    mapfile -t -d '' result < "$output_file"
    rm -f "$output_file"
    result_str="${result[*]}"
    [[ "$result_str" == *"-tags"*tag1,tag2* ]]
}

@test "build_args excludes -tags when empty" {
    local output_file
    output_file=$(mktemp)
    build_args "." "text" "./..." "symbol" "false" "" "" "source" "" > "$output_file"
    mapfile -t -d '' result < "$output_file"
    rm -f "$output_file"
    result_str="${result[*]}"
    [[ "$result_str" != *"-tags"* ]]
}

@test "build_args includes -db when provided" {
    local output_file
    output_file=$(mktemp)
    build_args "." "text" "./..." "symbol" "false" "" "https://custom.db" "source" "" > "$output_file"
    mapfile -t -d '' result < "$output_file"
    rm -f "$output_file"
    result_str="${result[*]}"
    [[ "$result_str" == *"-db"*https://custom.db* ]]
}

@test "build_args excludes -db when empty" {
    local output_file
    output_file=$(mktemp)
    build_args "." "text" "./..." "symbol" "false" "" "" "source" "" > "$output_file"
    mapfile -t -d '' result < "$output_file"
    rm -f "$output_file"
    result_str="${result[*]}"
    [[ "$result_str" != *"-db"* ]]
}

@test "build_args includes -mode when not default" {
    local output_file
    output_file=$(mktemp)
    build_args "." "text" "./..." "symbol" "false" "" "" "binary" "" > "$output_file"
    mapfile -t -d '' result < "$output_file"
    rm -f "$output_file"
    result_str="${result[*]}"
    [[ "$result_str" == *"-mode"*binary* ]]
}

@test "build_args excludes -mode when default" {
    local output_file
    output_file=$(mktemp)
    build_args "." "text" "./..." "symbol" "false" "" "" "source" "" > "$output_file"
    mapfile -t -d '' result < "$output_file"
    rm -f "$output_file"
    result_str="${result[*]}"
    [[ "$result_str" != *"-mode"* ]]
}

@test "build_args includes -show when provided with text format" {
    local output_file
    output_file=$(mktemp)
    build_args "." "text" "./..." "symbol" "false" "" "" "source" "traces" > "$output_file"
    mapfile -t -d '' result < "$output_file"
    rm -f "$output_file"
    result_str="${result[*]}"
    [[ "$result_str" == *"-show"*traces* ]]
}

@test "build_args excludes -show when empty" {
    local output_file
    output_file=$(mktemp)
    build_args "." "text" "./..." "symbol" "false" "" "" "source" "" > "$output_file"
    mapfile -t -d '' result < "$output_file"
    rm -f "$output_file"
    result_str="${result[*]}"
    [[ "$result_str" != *"-show"* ]]
}

@test "build_args excludes -show with non-text format" {
    local output_file
    output_file=$(mktemp)
    build_args "." "json" "./..." "symbol" "false" "" "" "source" "verbose" > "$output_file"
    mapfile -t -d '' result < "$output_file"
    rm -f "$output_file"
    result_str="${result[*]}"
    [[ "$result_str" != *"-show"* ]]
}
