#!/bin/bash
# ==============================================================================
# JarvisLabs Instance Initialization Script
# ==============================================================================
# This script installs missing utilities (tree, gh cli) and automates GitHub 
# credential helper configuration.
#
# Usage:
#   # Install tree & gh, then log in interactively:
#   ./init_jarvis.sh
#
#   # Install and authenticate automatically using a GitHub token:
#   ./init_jarvis.sh --token YOUR_GITHUB_TOKEN
# ==============================================================================

set -e

# Parse GitHub token argument if provided
GH_TOKEN=""
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --token) GH_TOKEN="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

echo "⚙️  Starting JarvisLabs initialization..."

# 1. Install 'tree' command
if ! command -v tree &> /dev/null; then
    echo "📦 Installing 'tree' utility..."
    sudo apt-get update -y && sudo apt-get install -y tree
    echo "✅ 'tree' installed successfully."
else
    echo "✅ 'tree' is already installed."
fi

# 2. Install GitHub CLI (gh) via official apt repository
if ! command -v gh &> /dev/null; then
    echo "📦 Installing GitHub CLI via apt..."
    sudo apt-get update -y
    sudo apt-get install -y gh
    echo "✅ GitHub CLI (gh) installed successfully."
else
    echo "✅ GitHub CLI (gh) is already installed."
fi

# 3. Authenticate GitHub CLI & configure git helper
# Check if token was provided in args or exists in environment
if [ -z "$GH_TOKEN" ]; then
    GH_TOKEN="$GITHUB_TOKEN"
fi

if [ -n "$GH_TOKEN" ]; then
    echo "🔑 Authenticating GitHub CLI with token..."
    echo "$GH_TOKEN" | gh auth login --with-token
    echo "🐙 Configuring Git credential helper..."
    gh auth setup-git
    echo "✅ Git credentials configured. You can now push/pull without logging in!"
else
    echo "ℹ️  No GITHUB_TOKEN provided."
    echo "👉 Run 'gh auth login' followed by 'gh auth setup-git' to log in manually."
fi

# 4. Install python dependencies
echo "📦 Installing project python packages..."
pip install transformers accelerate bitsandbytes sentencepiece protobuf datasets psutil gputil tabulate sentence-transformers qwen-vl-utils soundfile matplotlib torchvision peft trl

echo -e "\n🎉 Initialization complete! Your environment is ready."
