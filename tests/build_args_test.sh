#!/usr/bin/env bats

load ../src/build-args.sh

@test "build_args returns basic arguments" {
    mapfile -t -d '' result < <(build_args "." "text" "./..." "symbol" "false" "" "" "source" "")
    result_str="${result[*]}"
    [[ "$result_str" == *"-C"*". "*"-format"*text*"./..."* ]]
}

@test "build_args includes scan-level when not default" {
    mapfile -t -d '' result < <(build_args "." "text" "./..." "module" "false" "" "" "source" "")
    result_str="${result[*]}"
    [[ "$result_str" == *"-scan-level"*module* ]]
}

@test "build_args excludes scan-level when default" {
    mapfile -t -d '' result < <(build_args "." "text" "./..." "symbol" "false" "" "" "source" "")
    result_str="${result[*]}"
    [[ "$result_str" != *"-scan-level"* ]]
}

@test "build_args includes -test when enabled in source mode" {
    mapfile -t -d '' result < <(build_args "." "text" "./..." "symbol" "true" "" "" "source" "")
    result_str="${result[*]}"
    [[ "$result_str" == *"-test"* ]]
}

@test "build_args excludes -test when disabled" {
    mapfile -t -d '' result < <(build_args "." "text" "./..." "symbol" "false" "" "" "source" "")
    result_str="${result[*]}"
    [[ "$result_str" != *"-test"* ]]
}

@test "build_args excludes -test in binary mode" {
    mapfile -t -d '' result < <(build_args "." "text" "./..." "symbol" "true" "" "" "binary" "")
    result_str="${result[*]}"
    [[ "$result_str" != *"-test"* ]]
}

@test "build_args includes -tags when provided" {
    mapfile -t -d '' result < <(build_args "." "text" "./..." "symbol" "false" "tag1,tag2" "" "source" "")
    result_str="${result[*]}"
    [[ "$result_str" == *"-tags"*tag1,tag2* ]]
}

@test "build_args excludes -tags when empty" {
    mapfile -t -d '' result < <(build_args "." "text" "./..." "symbol" "false" "" "" "source" "")
    result_str="${result[*]}"
    [[ "$result_str" != *"-tags"* ]]
}

@test "build_args includes -db when provided" {
    mapfile -t -d '' result < <(build_args "." "text" "./..." "symbol" "false" "" "https://custom.db" "source" "")
    result_str="${result[*]}"
    [[ "$result_str" == *"-db"*https://custom.db* ]]
}

@test "build_args excludes -db when empty" {
    mapfile -t -d '' result < <(build_args "." "text" "./..." "symbol" "false" "" "" "source" "")
    result_str="${result[*]}"
    [[ "$result_str" != *"-db"* ]]
}

@test "build_args includes -mode when not default" {
    mapfile -t -d '' result < <(build_args "." "text" "./..." "symbol" "false" "" "" "binary" "")
    result_str="${result[*]}"
    [[ "$result_str" == *"-mode"*binary* ]]
}

@test "build_args excludes -mode when default" {
    mapfile -t -d '' result < <(build_args "." "text" "./..." "symbol" "false" "" "" "source" "")
    result_str="${result[*]}"
    [[ "$result_str" != *"-mode"* ]]
}

@test "build_args includes -show when provided with text format" {
    mapfile -t -d '' result < <(build_args "." "text" "./..." "symbol" "false" "" "" "source" "traces")
    result_str="${result[*]}"
    [[ "$result_str" == *"-show"*traces* ]]
}

@test "build_args excludes -show when empty" {
    mapfile -t -d '' result < <(build_args "." "text" "./..." "symbol" "false" "" "" "source" "")
    result_str="${result[*]}"
    [[ "$result_str" != *"-show"* ]]
}

@test "build_args excludes -show with non-text format" {
    mapfile -t -d '' result < <(build_args "." "json" "./..." "symbol" "false" "" "" "source" "verbose")
    result_str="${result[*]}"
    [[ "$result_str" != *"-show"* ]]
}
