# Claude Code Configuration

Configuration files for using these skills with [Claude Code](https://claude.ai/code).

## Quick Setup

```bash
# From repository root
cd config/claude
./setup.sh
```

Then start Claude Code — it will prompt you for your API key on first use.

## Manual Setup

### 1. Copy Configuration Files

```bash
# From repository root
cp -r config/claude/.claude-plugin .claude-plugin
cp config/claude/mcp.json .mcp.json
```

### 2. Start Claude Code

```bash
claude --plugin-dir .
```

Claude Code will prompt you to configure:
- **api_url**: Ravenna API endpoint (defaults to `https://core.ravenna.ai/mcp`)
- **api_key**: Your Ravenna API key (stored encrypted)

## Authentication

There are two ways to authenticate, depending on your use case:

### Plugin Config (Recommended for Local Development)

When you run Claude Code with `--plugin-dir .`, the plugin prompts for configuration interactively:

```bash
claude --plugin-dir .
```

Claude Code will prompt you for:
- **api_url**: Ravenna API endpoint (defaults to `https://core.ravenna.ai/mcp`)
- **api_key**: Your Ravenna API key (stored encrypted)

Your API key is stored encrypted in Claude's settings — never written to disk as plaintext.

### Environment Variables (Recommended for CI/Automation)

For non-interactive environments, use the root `.mcp.json` with environment variables:

```bash
export RAVENNA_API_KEY="your-ravenna-api-key"
export RAVENNA_API_URL="https://core.ravenna.ai/mcp"  # optional, has default

claude  # no --plugin-dir flag
```

The root `.mcp.json` reads from `RAVENNA_API_KEY` and `RAVENNA_API_URL` environment variables.

## Files

### `mcp.json` (Root Config)

Root MCP server configuration for environment variable mode:

- Uses `${env.RAVENNA_API_KEY}` — Your Ravenna API key (required)
- Uses `${env.RAVENNA_API_URL}` — Ravenna API endpoint (defaults to `https://core.ravenna.ai/mcp`)
- Used when running `claude` without `--plugin-dir`

### `.claude-plugin/` (Plugin Metadata)

Plugin metadata directory:

- `plugin.json` — Plugin metadata with `userConfig` schema (defines interactive prompts)
- Used when running `claude --plugin-dir .`

Note: The `.mcp.json` file goes in the repository root, not inside `.claude-plugin/`

### `setup.sh`

Automated setup script. Copies plugin files to the repository root.

## Getting Your API Key

1. Go to [ravenna.ai](https://ravenna.ai)
2. Sign up or log in
3. Navigate to API Keys section
4. Generate a new API key
5. Start Claude Code — it will prompt you to enter it

## Usage

Once configured, use the skills:

```
/api-code-generator
Generate API integration code from documentation
```

```
/code-action
Deploy code as executable actions
```

```
/debug-workflows
Debug and test Ravenna workflows
```

## Troubleshooting

### "Authentication failed" error

- Re-run Claude Code and re-enter your API key when prompted
- Or verify `RAVENNA_API_KEY` env var is set correctly
- Check the key is valid at ravenna.ai

### "Connection refused" error

- Check `RAVENNA_API_URL` is correct
- Verify network connectivity
- Try default URL: `https://core.ravenna.ai/mcp`

### Plugin not loading

```bash
# Reload plugins
/reload-plugins

# Check MCP connection
/mcp

# Restart with debug mode
claude --debug --plugin-dir .
```

### Skills not appearing

- Ensure you're in the repository root
- Check `skills/` directory exists
- Verify SKILL.md files have proper frontmatter

## Development Setup

For local Ravenna development:

```bash
export RAVENNA_API_URL="http://localhost:3000/mcp"
export RAVENNA_API_KEY="your-local-dev-key"
```

## More Information

- **Skills Documentation**: [../../skills/](../../skills/)
- **Main README**: [../../README.md](../../README.md)
- **Contributing**: [../../CONTRIBUTING.md](../../CONTRIBUTING.md)
- **Ravenna Docs**: [https://docs.ravenna.ai](https://docs.ravenna.ai)
