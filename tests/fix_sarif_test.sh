#!/usr/bin/env bats

load ../src/fix-sarif.sh

@test "fix_sarif function exists" {
    if type -t fix_sarif; then
        :
    else
        return 1
    fi
}

@test "fix_sarif handles missing file path" {
    run fix_sarif ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: INPUTS_OUTPUT_FILE is required"* ]]
}

@test "fix_sarif handles non-existent file" {
    run fix_sarif "/nonexistent/file.sarif"
    [ "$status" -eq 1 ]
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

    if fix_sarif "$temp_file"; then
        :
    else
        rm -f "$temp_file"
        return 1
    fi

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

    if fix_sarif "$temp_file"; then
        :
    else
        rm -f "$temp_file"
        return 1
    fi

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

    if fix_sarif "$temp_file"; then
        :
    else
        rm -f "$temp_file"
        return 1
    fi

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

    if fix_sarif "$temp_file"; then
        :
    else
        rm -f "$temp_file"
        return 1
    fi

    has_properties=$(jq -r '.runs[0].tool.driver.rules[0] | has("properties")' "$temp_file")
    [[ "$has_properties" == "false" ]]

    rm -f "$temp_file"
}