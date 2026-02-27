#!/bin/bash
# Sync reference repositories from repos.json

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
REFS_DIR="$ROOT_DIR/references"
REPOS_FILE="$REFS_DIR/repos.json"

if [ ! -f "$REPOS_FILE" ]; then
    echo "Error: repos.json not found at $REPOS_FILE"
    exit 1
fi

echo "Syncing reference repositories..."

# Parse repos.json and clone/update each repo
jq -c '.repos[]' "$REPOS_FILE" | while read -r repo; do
    name=$(echo "$repo" | jq -r '.name')
    url=$(echo "$repo" | jq -r '.url')
    branch=$(echo "$repo" | jq -r '.branch // "main"')
    
    repo_dir="$REFS_DIR/$name"
    
    if [ -d "$repo_dir" ]; then
        echo "Updating $name..."
        cd "$repo_dir"
        git fetch origin
        git checkout "$branch"
        git pull origin "$branch"
    else
        echo "Cloning $name..."
        git clone --branch "$branch" "$url" "$repo_dir"
    fi
done

echo "Done syncing references."
