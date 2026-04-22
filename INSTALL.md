# Ravenna Plugin Installation Guide

## Quick Setup

### Option 1: Using Environment Variables (Easiest)

```bash
# Set your credentials
export RAVENNA_API_URL="https://core.ravenna.ai/mcp"
export RAVENNA_API_KEY="your-api-key-here"

# Start Claude with the plugin
cd /Users/kailash/code/ravenna-claude
claude --plugin-dir .
```

### Option 2: Using .env file

```bash
# Create .env file from example
cp .env.example .env

# Edit .env and add your credentials
# Then source it
source .env

# Start Claude
claude --plugin-dir .
```

### Option 3: Let Claude Prompt You

The plugin should prompt you for:
1. Ravenna API URL (default: https://core.ravenna.ai/mcp)
2. Ravenna API Key (your key from ravenna.ai)

However, if Claude doesn't prompt you, use Option 1 or 2.

## Troubleshooting

### Plugin Not Loading

**Symptom:** No prompt for credentials, MCP list is empty

**Solutions:**

1. **Verify you're in the right directory:**
   ```bash
   pwd  # Should show /Users/kailash/code/ravenna-claude
   ```

2. **Check plugin structure:**
   ```bash
   ./test-plugin.sh
   ```

3. **Try different paths:**
   ```bash
   # From parent directory
   cd ..
   claude --plugin-dir ./ravenna-claude

   # Or point directly to plugin dir
   claude --plugin-dir ./ravenna-claude/.claude-plugin
   ```

4. **Use environment variables explicitly:**
   ```bash
   RAVENNA_API_URL='https://core.ravenna.ai/mcp' \
   RAVENNA_API_KEY='your-key' \
   claude --plugin-dir .
   ```

### MCP Server Not Appearing

**Symptom:** Plugin loads but MCP server list is empty

**Possible causes:**
- Config values not resolved
- MCP configuration file not found
- Invalid JSON in mcp.json

**Solutions:**

1. **Check MCP configuration:**
   ```bash
   cat .claude-plugin/mcp.json
   # Should show valid JSON with template variables
   ```

2. **Validate the configuration:**
   ```bash
   jq . .claude-plugin/mcp.json
   ```

3. **Test with hardcoded values temporarily:**

   Edit `.claude-plugin/mcp.json` and replace template variables with actual values:
   ```json
   {
     "mcpServers": {
       "ravenna": {
         "url": "https://core.ravenna.ai/mcp",
         "type": "http",
         "headers": {
           "Authorization": "Bearer your-actual-key-here"
         }
       }
     }
   }
   ```

   Then test:
   ```bash
   claude --plugin-dir .
   ```

### Credentials Not Being Prompted

If Claude isn't prompting for API URL and key:

1. **Check if values are already cached:**
   ```bash
   # Look for existing config
   ls -la ~/.claude/
   # or
   ls -la ~/.config/claude/
   ```

2. **Clear any cached credentials:**
   ```bash
   # Remove plugin-specific config if it exists
   rm -rf ~/.claude/plugins/ravenna*
   ```

3. **Set environment variables instead:**
   Use Option 1 from Quick Setup above

## Verifying Installation

Once Claude starts with the plugin:

1. **Check for the Ravenna MCP server:**
   ```
   /mcp list
   ```
   Should show: `ravenna` server

2. **List available skills:**
   ```
   /skills
   ```
   Should show:
   - `api-code-generator`
   - `code-action`

3. **Test a skill:**
   ```
   /api-code-generator
   ```

## Get Your API Key

Don't have a Ravenna API key yet?

1. Visit: https://ravenna.ai
2. Sign up or log in
3. Navigate to API Keys section
4. Generate a new API key
5. Copy and save it securely

## Still Having Issues?

Run the diagnostic script:
```bash
./test-plugin.sh
```

Check the output for any ✗ marks and fix those issues first.

## Alternative: Install as System Plugin

If `--plugin-dir` isn't working, you can install it globally:

```bash
# Create plugins directory if it doesn't exist
mkdir -p ~/.claude/plugins

# Copy plugin to system location
cp -r .claude-plugin ~/.claude/plugins/ravenna

# Copy MCP config
cp .mcp.json ~/.claude/plugins/ravenna/

# Start Claude normally
claude
```

Then Claude should auto-discover the plugin.
