#!/bin/bash
# Setup script for Claude Code integration

set -e

echo "Setting up Claude Code integration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get the repo root (parent directory of config)
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CLAUDE_DIR="$REPO_ROOT/.claude-plugin"

# Create .claude-plugin directory
echo "Setting up plugin directory..."
mkdir -p "$CLAUDE_DIR"

# Copy plugin files
cp "$REPO_ROOT/config/claude/.claude-plugin/plugin.json" "$CLAUDE_DIR/"
cp "$REPO_ROOT/config/claude/mcp.json" "$REPO_ROOT/.mcp.json"

echo ""
echo "Setup complete!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Start Claude Code:"
echo ""
echo "  cd $REPO_ROOT"
echo "  claude --plugin-dir ."
echo ""
echo "Authentication:"
echo ""
echo "Claude will prompt you for your Ravenna API credentials on first use."
echo "Your API key is stored encrypted in Claude's settings."
echo ""
echo "For CI/automation, use environment variables instead:"
echo ""
echo "  export RAVENNA_API_KEY='your-key'"
echo "  export RAVENNA_API_URL='https://core.ravenna.ai/mcp'  # optional"
echo "  claude  # without --plugin-dir flag"
echo ""
