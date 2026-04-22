#!/bin/bash

echo "=== Testing Ravenna Claude Plugin ==="
echo ""

echo "1. Checking plugin structure..."
echo "   - plugin.json exists: $([ -f .claude-plugin/plugin.json ] && echo '✓' || echo '✗')"
echo "   - mcp.json in plugin dir: $([ -f .claude-plugin/mcp.json ] && echo '✓' || echo '✗')"
echo "   - mcp.json at root: $([ -f .mcp.json ] && echo '✓' || echo '✗')"
echo "   - skills directory: $([ -d skills ] && echo '✓' || echo '✗')"
echo ""

echo "2. Validating JSON files..."
if jq empty .claude-plugin/plugin.json 2>/dev/null; then
    echo "   - plugin.json: ✓ Valid"
else
    echo "   - plugin.json: ✗ Invalid"
fi

if jq empty .claude-plugin/mcp.json 2>/dev/null; then
    echo "   - .claude-plugin/mcp.json: ✓ Valid"
else
    echo "   - .claude-plugin/mcp.json: ✗ Invalid"
fi
echo ""

echo "3. Checking environment variables..."
echo "   - RAVENNA_API_URL: ${RAVENNA_API_URL:-not set}"
echo "   - RAVENNA_API_KEY: ${RAVENNA_API_KEY:+set}"
echo ""

echo "4. Testing with Claude Code..."
echo "   Run one of these commands to test:"
echo ""
echo "   Option A (point to root directory):"
echo "   $ claude --plugin-dir ./ravenna-claude"
echo ""
echo "   Option B (point to plugin directory directly):"
echo "   $ claude --plugin-dir ./ravenna-claude/.claude-plugin"
echo ""
echo "   Option C (with environment variables):"
echo "   $ RAVENNA_API_URL='https://core.ravenna.ai/mcp' RAVENNA_API_KEY='your-key' claude --plugin-dir ./ravenna-claude"
echo ""
