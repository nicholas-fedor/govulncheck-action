#!/usr/bin/env bats

# Test SARIF fix functionality
load ../src/fix-sarif.sh

@test "fix_sarif function exists" {
    type -t fix_sarif | grep -q function
}

@test "fix_sarif handles missing file path" {
    run fix_sarif ""
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"Error: INPUTS_OUTPUT_FILE is required"* ]]
}

@test "fix_sarif handles non-existent file" {
    run fix_sarif "/nonexistent/file.sarif"
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

    run fix_sarif "$temp_file"
    [[ "$status" -eq 0 ]]

    tag_count=$(jq -r '.runs[0].tool.driver.rules[0].properties.tags | length' "$temp_file")
    [[ "$tag_count" -eq 1 ]]

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

    run fix_sarif "$temp_file"
    [[ "$status" -eq 0 ]]

    tag_count=$(jq -r '.runs[0].tool.driver.rules[0].properties.tags | length' "$temp_file")
    [[ "$tag_count" -eq 1 ]]

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

    run fix_sarif "$temp_file"
    [[ "$status" -eq 0 ]]

    rm -f "$temp_file"
}
