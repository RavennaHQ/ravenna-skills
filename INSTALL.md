# Ravenna Plugin Installation Guide

## Quick Setup

### Option 1: Plugin System (Recommended)

```bash
# Clone and setup
git clone https://github.com/RavennaHQ/ravenna-skills.git
cd ravenna-skills
cd config/claude && ./setup.sh && cd ../..

# Start Claude — it will prompt for your API key
claude --plugin-dir .
```

The plugin system stores your API key encrypted in Claude's settings. No plaintext files on disk.

### Option 2: Environment Variables (CI/Automation)

```bash
export RAVENNA_API_KEY="your-api-key-here"

# Start Claude
cd ravenna-skills
claude --plugin-dir .
```

Environment variables take precedence over plugin config.

## Troubleshooting

### Plugin Not Loading

**Symptom:** No prompt for credentials, MCP list is empty

**Solutions:**

1. **Verify you're in the right directory:**
   ```bash
   ls .claude-plugin/plugin.json  # Should exist
   ```

2. **Re-run setup:**
   ```bash
   cd config/claude && ./setup.sh && cd ../..
   ```

3. **Try with explicit env vars:**
   ```bash
   RAVENNA_API_KEY='your-key' claude --plugin-dir .
   ```

### MCP Server Not Appearing

**Symptom:** Plugin loads but MCP server list is empty

**Solutions:**

1. **Validate the configuration:**
   ```bash
   jq . .mcp.json
   ```

2. **Check MCP connection:**
   ```
   /mcp
   ```

### Credentials Not Being Prompted

If Claude isn't prompting for the API key:

1. **Check if values are already cached:**
   ```bash
   ls -la ~/.claude/
   ```

2. **Set environment variables instead:**
   ```bash
   export RAVENNA_API_KEY="your-key"
   claude --plugin-dir .
   ```

## Verifying Installation

Once Claude starts with the plugin:

1. **Check for the Ravenna MCP server:**
   ```
   /mcp
   ```
   Should show: `plugin:ravenna:mcp` server

2. **Test a skill:**
   ```
   /api-code-generator
   ```

## Get Your API Key

1. Visit: https://ravenna.ai
2. Sign up or log in
3. Navigate to API Keys section
4. Generate a new API key

## Alternative: Install as System Plugin

```bash
# Create plugins directory
mkdir -p ~/.claude/plugins

# Copy plugin to system location
cp -r .claude-plugin ~/.claude/plugins/ravenna
cp .mcp.json ~/.claude/plugins/ravenna/

# Start Claude normally
claude
```
