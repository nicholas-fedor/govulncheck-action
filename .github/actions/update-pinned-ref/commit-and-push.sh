#!/bin/bash
# Commits and pushes changes, creates PR if needed
# Uses GITHUB_TOKEN for git operations and gh CLI for PR creation

set -euo pipefail

# Validates that GITHUB_TOKEN is available in environment
# Returns:
#   0 if token present, 1 otherwise
validate_token() {
    if [[ -z "${GITHUB_TOKEN:-}" ]]; then
        echo "Error: GITHUB_TOKEN is required" >&2
        return 1
    fi

    return 0
}

# Configures git for github-actions[bot] identity
configure_git() {
    git config --local user.email "github-actions[bot]@users.noreply.github.com"
    git config --local user.name "github-actions[bot]"
}

# Creates or updates the specified branch
# Args:
#   $1 - Branch name
create_branch() {
    local branch="$1"

    git checkout -B "$branch" 2>/dev/null || git checkout -b "$branch"
}

# Stages and commits changes, pushes to remote
# Args:
#   $1 - File to commit
#   $2 - Branch name
# Sets changed=true/false in GITHUB_OUTPUT
commit_changes() {
    local readme_path="$1"
    local branch="$2"

    git add "$readme_path"

    if ! git diff --staged --quiet; then
        echo "changed=true" >> "$GITHUB_OUTPUT"
        git commit -m "docs(readme): update pinned action ref"
        git push -u origin "$branch" -f
        return 0
    fi

    echo "No changes to commit"
    echo "changed=false" >> "$GITHUB_OUTPUT"
    return 1
}

# Creates a pull request if one doesn't already exist
# Args:
#   $1 - README path for PR body
#   $2 - Branch name
create_pull_request() {
    local readme_path="$1"
    local branch="$2"

    local pr_exists
    pr_exists=$(gh pr view "$branch" --json number -q '.number' 2>/dev/null || echo "")

    if [[ -n "$pr_exists" ]]; then
        echo "PR already exists, no new PR created"
        return 0
    fi

    gh pr create \
        --title "docs: update pinned action ref in README" \
        --body "## Summary
- Update $readme_path with latest pinned action ref"
}

# Main entry point
# Args:
#   $1 - README path (default: README.md)
main() {
    local readme_path="${1:-README.md}"
    local branch="docs/update-pinned-ref"

    validate_token || return 1

    configure_git
    create_branch "$branch"

    if commit_changes "$readme_path" "$branch"; then
        create_pull_request "$readme_path" "$branch"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi