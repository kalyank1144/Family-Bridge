#!/bin/bash

# Setup Git Hooks for FamilyBridge
# This script configures Git to use the custom hooks from .githooks directory

set -e

echo "🔧 Setting up Git hooks for FamilyBridge..."

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not in a Git repository"
    exit 1
fi

# Check if .githooks directory exists
if [ ! -d ".githooks" ]; then
    echo "❌ Error: .githooks directory not found"
    exit 1
fi

# Configure Git to use .githooks directory
echo "📁 Configuring Git to use .githooks directory..."
git config core.hooksPath .githooks

# Make hooks executable
echo "🔧 Making hooks executable..."
chmod +x .githooks/*

# List available hooks
echo ""
echo "✅ Git hooks setup completed!"
echo ""
echo "📋 Available hooks:"
for hook in .githooks/*; do
    if [ -f "$hook" ]; then
        hook_name=$(basename "$hook")
        echo "  - $hook_name"
    fi
done

echo ""
echo "🎯 Hooks are now active for this repository"
echo ""
echo "📝 Available commands:"
echo "  - Disable hooks temporarily: git commit --no-verify"
echo "  - Push without hooks: git push --no-verify"
echo "  - Reset to default hooks: git config --unset core.hooksPath"
echo ""
echo "🚀 Happy coding!"