#!/usr/bin/env bats

# shellcheck source=../src/fix-sarif.sh disable=SC1091
source "${BATS_TEST_DIRNAME}/../src/fix-sarif.sh"

@test "fix_sarif function exists" {
    type -t fix_sarif | grep -q function
}

@test "fix_sarif handles missing file path" {
    local tmp status=0
    tmp=$(mktemp)
    fix_sarif "" > "$tmp" 2>&1 || status=$?
    output=$(cat "$tmp")
    rm -f "$tmp"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"Error: INPUTS_OUTPUT_FILE is required"* ]]
}

@test "fix_sarif handles non-existent file" {
    local tmp status=0
    tmp=$(mktemp)
    fix_sarif "/nonexistent/file.sarif" > "$tmp" 2>&1 || status=$?
    output=$(cat "$tmp")
    rm -f "$tmp"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"does not exist"* ]]
}

@test "fix_sarif removes duplicate tags" {
    local temp_file
    temp_file=$(mktemp)
    cat > "$temp_file" << 'EOF'
{
  "runs": [
    {
      "tool": {
        "driver": {
          "rules": [
            {
              "id": "GO-2024-0001",
              "properties": {
                "tags": ["CVE-2024-0001", "CVE-2024-0001"]
              }
            }
          ]
        }
      }
    }
  ]
}
EOF

    fix_sarif "$temp_file" || return 1

    tags=$(jq -c '.runs[0].tool.driver.rules[0].properties.tags' "$temp_file")
    [[ "$tags" == '["CVE-2024-0001"]' ]]

    rm -f "$temp_file"
}

@test "fix_sarif handles empty rules array" {
    local temp_file
    temp_file=$(mktemp)
    cat > "$temp_file" << 'EOF'
{
  "runs": [
    {
      "tool": {
        "driver": {
          "rules": []
        }
      }
    }
  ]
}
EOF

    fix_sarif "$temp_file" || return 1

    rm -f "$temp_file"
}

@test "fix_sarif preserves non-duplicate tags" {
    local temp_file
    temp_file=$(mktemp)
    cat > "$temp_file" << 'EOF'
{
  "runs": [
    {
      "tool": {
        "driver": {
          "rules": [
            {
              "id": "GO-2024-0001",
              "properties": {
                "tags": ["CVE-2024-0001"]
              }
            }
          ]
        }
      }
    }
  ]
}
EOF

    fix_sarif "$temp_file" || return 1

    tags=$(jq -c '.runs[0].tool.driver.rules[0].properties.tags' "$temp_file")
    [[ "$tags" == '["CVE-2024-0001"]' ]]

    rm -f "$temp_file"
}

@test "fix_sarif handles rules without properties" {
    local temp_file
    temp_file=$(mktemp)
    cat > "$temp_file" << 'EOF'
{
  "runs": [
    {
      "tool": {
        "driver": {
          "rules": [
            {
              "id": "GO-2024-0001"
            }
          ]
        }
      }
    }
  ]
}
EOF

    fix_sarif "$temp_file" || return 1

    rule=$(jq -c '.runs[0].tool.driver.rules' "$temp_file")
    [[ "$rule" == '[{"id":"GO-2024-0001"}]' ]]

    rm -f "$temp_file"
}

@test "fix_sarif keeps rules without tags alongside rules with tags" {
    local temp_file
    temp_file=$(mktemp)
    cat > "$temp_file" << 'EOF'
{
  "runs": [
    {
      "tool": {
        "driver": {
          "rules": [
            {
              "id": "GO-2024-0001",
              "properties": {}
            },
            {
              "id": "GO-2024-0002",
              "properties": {
                "tags": ["CVE-2024-0002", "CVE-2024-0002"]
              }
            }
          ]
        }
      }
    }
  ]
}
EOF

    fix_sarif "$temp_file" || return 1

    rules=$(jq -c '.runs[0].tool.driver.rules' "$temp_file")
    [[ "$rules" == '[{"id":"GO-2024-0001","properties":{}},{"id":"GO-2024-0002","properties":{"tags":["CVE-2024-0002"]}}]' ]]

    rm -f "$temp_file"
}

@test "fix_sarif removes duplicate stacks and keeps their order" {
    local temp_file
    temp_file=$(mktemp)
    cat > "$temp_file" << 'EOF'
{
  "runs": [
    {
      "tool": {
        "driver": {
          "rules": []
        }
      },
      "results": [
        {
          "ruleId": "GO-2024-0001",
          "stacks": [
            {"message": {"text": "stack b"}, "frames": [{"module": "b"}]},
            {"message": {"text": "stack b"}, "frames": [{"module": "b"}]},
            {"message": {"text": "stack a"}, "frames": [{"module": "a"}]},
            {"message": {"text": "stack a"}, "frames": [{"module": "a"}]}
          ]
        }
      ]
    }
  ]
}
EOF

    fix_sarif "$temp_file" || return 1

    stacks=$(jq -c '[.runs[0].results[0].stacks[].message.text]' "$temp_file")
    [[ "$stacks" == '["stack b","stack a"]' ]]

    rm -f "$temp_file"
}

@test "fix_sarif keeps stacks that differ only in frames" {
    local temp_file
    temp_file=$(mktemp)
    cat > "$temp_file" << 'EOF'
{
  "runs": [
    {
      "tool": {
        "driver": {
          "rules": []
        }
      },
      "results": [
        {
          "ruleId": "GO-2024-0001",
          "stacks": [
            {"message": {"text": "stack"}, "frames": [{"module": "a"}]},
            {"message": {"text": "stack"}, "frames": [{"module": "b"}]}
          ]
        }
      ]
    }
  ]
}
EOF

    fix_sarif "$temp_file" || return 1

    count=$(jq '.runs[0].results[0].stacks | length' "$temp_file")
    [[ "$count" -eq 2 ]]

    rm -f "$temp_file"
}

@test "fix_sarif handles results without stacks" {
    local temp_file
    temp_file=$(mktemp)
    cat > "$temp_file" << 'EOF'
{
  "runs": [
    {
      "tool": {
        "driver": {
          "rules": []
        }
      },
      "results": [
        {
          "ruleId": "GO-2024-0001"
        }
      ]
    }
  ]
}
EOF

    fix_sarif "$temp_file" || return 1

    result=$(jq -c '.runs[0].results' "$temp_file")
    [[ "$result" == '[{"ruleId":"GO-2024-0001"}]' ]]

    rm -f "$temp_file"
}
