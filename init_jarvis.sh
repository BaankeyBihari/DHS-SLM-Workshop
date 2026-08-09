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

# Helper function to write/update environment variables in multiple shell configs
write_env_var() {
    local var_name="$1"
    local var_val="$2"
    
    # Write to .bashrc (Bash), .zshrc (Zsh), and .profile (Login/Jupyter daemon)
    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
        # Create file if it doesn't exist
        touch "$rc_file"
        
        # Check if variable is already in the file
        if grep -q "export $var_name=" "$rc_file"; then
            # Replace existing export (using | as delimiter to handle slash characters in keys)
            sed -i "s|export $var_name=.*|export $var_name=\"$var_val\"|g" "$rc_file"
        else
            # Append new export
            echo "export $var_name=\"$var_val\"" >> "$rc_file"
        fi
    done
    
    # Write to local .env file in the workspace root
    local env_file
    env_file="$(dirname "$0")/.env"
    touch "$env_file"
    if grep -q "^$var_name=" "$env_file"; then
        sed -i "s|^$var_name=.*|$var_name=\"$var_val\"|g" "$env_file"
    else
        echo "$var_name=\"$var_val\"" >> "$env_file"
    fi
}

echo "⚙️  Starting JarvisLabs initialization..."

# ── Step 0: Prompt and Persist Hugging Face and OpenAI Keys ──
echo "🔑 Checking credentials..."

# Hugging Face Token setup
if [ -z "$HF_TOKEN" ] && [ -z "$GITHUB_ACTIONS" ]; then
    read -rp "👉 Enter your Hugging Face Token (leave empty to skip): " input_hf
    if [ -n "$input_hf" ]; then
        HF_TOKEN="$input_hf"
    fi
fi

if [ -n "$HF_TOKEN" ]; then
    write_env_var "HF_TOKEN" "$HF_TOKEN"
    export HF_TOKEN
    echo "✅ HF_TOKEN configured and added to ~/.bashrc"
fi

# OpenAI API Key setup
if [ -z "$OPENAI_API_KEY" ] && [ -z "$GITHUB_ACTIONS" ]; then
    read -rp "👉 Enter your OpenAI API Key (leave empty to skip): " input_openai
    if [ -n "$input_openai" ]; then
        OPENAI_API_KEY="$input_openai"
    fi
fi

if [ -n "$OPENAI_API_KEY" ]; then
    write_env_var "OPENAI_API_KEY" "$OPENAI_API_KEY"
    export OPENAI_API_KEY
    echo "✅ OPENAI_API_KEY configured and added to ~/.bashrc"
fi
echo ""

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
