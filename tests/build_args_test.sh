#!/usr/bin/env bats

load ../src/build-args.sh

@test "build_args returns basic arguments" {
    output_file=$(mktemp)
    build_args "." "text" "./..." "symbol" "false" "" "" "source" "" > "$output_file"
    output=$(tr '\0' ' ' < "$output_file")
    rm -f "$output_file"
    [[ "$output" == *"-C"*". "*"-format"*text*"./..."* ]]
}

@test "build_args includes scan-level when not default" {
    output=$(build_args "." "text" "./..." "module" "false" "" "" "source" "")
    [[ "$output" == *"-scan-level"*module* ]]
}

@test "build_args excludes scan-level when default" {
    output=$(build_args "." "text" "./..." "symbol" "false" "" "" "source" "")
    [[ "$output" != *"-scan-level"* ]]
}

@test "build_args includes -test when enabled in source mode" {
    output=$(build_args "." "text" "./..." "symbol" "true" "" "" "source" "")
    [[ "$output" == *"-test"* ]]
}

@test "build_args excludes -test when disabled" {
    output=$(build_args "." "text" "./..." "symbol" "false" "" "" "source" "")
    [[ "$output" != *"-test"* ]]
}

@test "build_args excludes -test in binary mode" {
    output=$(build_args "." "text" "./..." "symbol" "true" "" "" "binary" "")
    [[ "$output" != *"-test"* ]]
}

@test "build_args includes -tags when provided" {
    output=$(build_args "." "text" "./..." "symbol" "false" "tag1,tag2" "" "source" "")
    [[ "$output" == *"-tags"*tag1,tag2* ]]
}

@test "build_args excludes -tags when empty" {
    output=$(build_args "." "text" "./..." "symbol" "false" "" "" "source" "")
    [[ "$output" != *"-tags"* ]]
}

@test "build_args includes -db when provided" {
    output=$(build_args "." "text" "./..." "symbol" "false" "" "https://custom.db" "source" "")
    [[ "$output" == *"-db"*https://custom.db* ]]
}

@test "build_args excludes -db when empty" {
    output=$(build_args "." "text" "./..." "symbol" "false" "" "" "source" "")
    [[ "$output" != *"-db"* ]]
}

@test "build_args includes -mode when not default" {
    output=$(build_args "." "text" "./..." "symbol" "false" "" "" "binary" "")
    [[ "$output" == *"-mode"*binary* ]]
}

@test "build_args excludes -mode when default" {
    output=$(build_args "." "text" "./..." "symbol" "false" "" "" "source" "")
    [[ "$output" != *"-mode"* ]]
}

@test "build_args includes -show when provided with text format" {
    output=$(build_args "." "text" "./..." "symbol" "false" "" "" "source" "traces")
    [[ "$output" == *"-show"*traces* ]]
}

@test "build_args excludes -show when empty" {
    output=$(build_args "." "text" "./..." "symbol" "false" "" "" "source" "")
    [[ "$output" != *"-show"* ]]
}

@test "build_args excludes -show with non-text format" {
    output=$(build_args "." "json" "./..." "symbol" "false" "" "" "source" "verbose")
    [[ "$output" != *"-show"* ]]
}
