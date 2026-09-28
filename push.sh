#!/usr/bin/env bash

# Commit and push changes to the remote repository
# Mirrors standard Wheelhouser repository behavior

set -euo pipefail

MESSAGE=${1:-}
if [ -z "$MESSAGE" ]; then
    read -r -p "Commit message: " MESSAGE
fi

if [ -z "$MESSAGE" ]; then
    echo "Commit message is required. Aborting."
    exit 1
fi

git_cmd=$(command -v git || true)
if [ -z "$git_cmd" ]; then
    echo "Git not found. Please ensure Git is installed."
    exit 1
fi

$git_cmd status -sb || true

$git_cmd add -A

if $git_cmd diff --cached --quiet; then
    echo "No staged changes to commit."
    exit 0
fi

if ! $git_cmd commit -m "$MESSAGE"; then
    echo "Commit failed. Aborting push."
    exit 1
fi

current_branch=$($git_cmd rev-parse --abbrev-ref HEAD)
if [ "$current_branch" = "main" ]; then
    if ! $git_cmd push origin main; then
        echo "Push failed."
        exit 1
    fi
else
    echo "Current branch is '$current_branch'. Pushing that branch."
    if ! $git_cmd push origin "$current_branch"; then
        echo "Push failed."
        exit 1
    fi
fi

echo "Push completed successfully."
