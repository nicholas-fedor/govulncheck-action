#!/usr/bin/env bats

load ../src/build-args.sh

@test "build_args returns basic arguments" {
    result=$(build_args "." "text" "./..." "symbol" "false" "" "" "source" "")
    [[ "$result" == *"-C"*"."*" -format"*"text"*"./..."* ]]
}

@test "build_args includes scan-level when not default" {
    result=$(build_args "." "text" "./..." "module" "false" "" "" "source" "")
    [[ "$result" == *"-scan-level"*"module"* ]]
}

@test "build_args excludes scan-level when default" {
    result=$(build_args "." "text" "./..." "symbol" "false" "" "" "source" "")
    [[ "$result" != *"-scan-level"* ]]
}

@test "build_args includes -test when enabled in source mode" {
    result=$(build_args "." "text" "./..." "symbol" "true" "" "" "source" "")
    [[ "$result" == *"-test"* ]]
}

@test "build_args excludes -test when disabled" {
    result=$(build_args "." "text" "./..." "symbol" "false" "" "" "source" "")
    [[ "$result" != *"-test"* ]]
}

@test "build_args excludes -test in binary mode" {
    result=$(build_args "." "text" "./..." "symbol" "true" "" "" "binary" "")
    [[ "$result" != *"-test"* ]]
}

@test "build_args includes -tags when provided" {
    result=$(build_args "." "text" "./..." "symbol" "false" "tag1,tag2" "" "source" "")
    [[ "$result" == *"-tags"*"tag1,tag2"* ]]
}

@test "build_args excludes -tags when empty" {
    result=$(build_args "." "text" "./..." "symbol" "false" "" "" "source" "")
    [[ "$result" != *"-tags"* ]]
}

@test "build_args includes -db when provided" {
    result=$(build_args "." "text" "./..." "symbol" "false" "" "https://custom.db" "source" "")
    [[ "$result" == *"-db"*"https://custom.db"* ]]
}

@test "build_args excludes -db when empty" {
    result=$(build_args "." "text" "./..." "symbol" "false" "" "" "source" "")
    [[ "$result" != *"-db"* ]]
}

@test "build_args includes -mode when not default" {
    result=$(build_args "." "text" "./..." "symbol" "false" "" "" "binary" "")
    [[ "$result" == *"-mode"*"binary"* ]]
}

@test "build_args excludes -mode when default" {
    result=$(build_args "." "text" "./..." "symbol" "false" "" "" "source" "")
    [[ "$result" != *"-mode"* ]]
}

@test "build_args includes -show when provided with text format" {
    result=$(build_args "." "text" "./..." "symbol" "false" "" "" "source" "traces")
    [[ "$result" == *"-show"*"traces"* ]]
}

@test "build_args excludes -show when empty" {
    result=$(build_args "." "text" "./..." "symbol" "false" "" "" "source" "")
    [[ "$result" != *"-show"* ]]
}

@test "build_args excludes -show with non-text format" {
    result=$(build_args "." "json" "./..." "symbol" "false" "" "" "source" "verbose")
    [[ "$result" != *"-show"* ]]
}
