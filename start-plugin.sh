#!/bin/bash

# Ravenna Plugin Startup Script

echo "🚀 Starting Ravenna Claude Plugin..."
echo ""

# Check if .env file exists
if [ -f .env ]; then
    echo "📝 Loading credentials from .env file..."
    source .env
else
    echo "⚠️  No .env file found. Using environment variables or will prompt."
    echo ""
fi

# Check credentials
if [ -z "$RAVENNA_API_URL" ]; then
    echo "❌ RAVENNA_API_URL not set"
    echo "   Please set it in .env file or export it:"
    echo "   export RAVENNA_API_URL='https://core.ravenna.ai/mcp'"
    echo ""
fi

if [ -z "$RAVENNA_API_KEY" ]; then
    echo "❌ RAVENNA_API_KEY not set"
    echo "   Please set it in .env file or export it:"
    echo "   export RAVENNA_API_KEY='your-api-key-here'"
    echo ""
    echo "   Get your API key from: https://ravenna.ai"
    echo ""
fi

# Show current values (masked)
echo "Current configuration:"
echo "  API URL: ${RAVENNA_API_URL:-not set}"
if [ -n "$RAVENNA_API_KEY" ]; then
    echo "  API Key: ${RAVENNA_API_KEY:0:10}... (set)"
else
    echo "  API Key: not set"
fi
echo ""

# Start Claude
echo "Starting Claude Code with plugin..."
echo ""
claude --plugin-dir .
