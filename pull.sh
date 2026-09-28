#!/usr/bin/env bash

# Pull latest changes from the remote repository
# Mirrors standard Wheelhouser repository behavior

set -euo pipefail

git_cmd=$(command -v git || true)
if [ -z "$git_cmd" ]; then
    echo "Git not found. Please ensure Git is installed."
    exit 1
fi

if ! $git_cmd rev-parse --is-inside-work-tree &> /dev/null; then
    echo "Not in a git repository. Aborting."
    exit 1
fi

FORCE=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--force)
            FORCE=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

current_branch=$($git_cmd rev-parse --abbrev-ref HEAD)
echo "Pulling latest changes for branch '$current_branch'..."

if [ "$FORCE" = true ]; then
    $git_cmd fetch origin
    $git_cmd reset --hard "origin/$current_branch"
    echo "Successfully updated to origin/$current_branch."
    exit 0
fi

stashed=false
if [ -n "$($git_cmd status --porcelain)" ]; then
    echo "Warning: You have uncommitted changes. Stashing before pulling..."
    if ! $git_cmd stash; then
        echo "Failed to stash changes. Aborting."
        exit 1
    fi
    stashed=true
fi

if ! $git_cmd pull origin "$current_branch"; then
    echo "Pull failed. Please resolve any conflicts manually."
    exit 1
fi

if [ "$stashed" = true ]; then
    $git_cmd stash pop || true
fi

echo "Pull completed successfully."
