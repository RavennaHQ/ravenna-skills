# Warp Configuration

Configuration for using these skills with [Warp](https://www.warp.dev/).

## Status

⚠️ **Hypothetical** - This configuration is a template for potential Warp integration.

Warp's AI features may support agentskills in the future. This config shows how integration could work.

## Concept

If Warp supports agentskills format, integration would look like:

```yaml
# .warp/skills.yaml
skills:
  - path: ../../skills/api-code-generator
  - path: ../../skills/code-action
  - path: ../../skills/debug-workflows

integrations:
  - name: ravenna
    type: http-api
    base_url: ${RAVENNA_API_URL}
    auth:
      type: bearer
      token: ${RAVENNA_API_KEY}
```

## Setup

### 1. Environment Variables

Add to your shell profile (`~/.zshrc`, `~/.bashrc`, etc.):

```bash
export RAVENNA_API_KEY="your-ravenna-api-key"
export RAVENNA_API_URL="https://core.ravenna.ai/mcp"
```

### 2. Load Skills (Hypothetical)

```bash
# If Warp supports skill loading
warp skills load ../../skills/

# Or configure in Warp settings
warp config set skills.directory "$(pwd)/../../skills"
```

### 3. Configure API Integration (Hypothetical)

```bash
# If Warp supports API integrations
warp integrations add ravenna \
  --url "$RAVENNA_API_URL" \
  --auth bearer \
  --token "$RAVENNA_API_KEY"
```

## Usage (Hypothetical)

In Warp terminal:

```bash
# Generate API code
warp ai "Use api-code-generator skill to create GitHub API integration"

# Deploy code action
warp ai "Use code-action skill to deploy this code to Ravenna"

# Debug workflow
warp ai "Use debug-workflows skill to test workflow wf_abc123"
```

## Current Workaround

Until Warp natively supports agentskills:

### Use Claude Code CLI

```bash
# In Warp terminal, use Claude Code
cd /path/to/ravenna-claude
claude --plugin-dir .

# Then use skills normally
```

### Use Warp + Claude Code Together

1. **Warp for terminal work**: Git, file operations, running code
2. **Claude Code for AI features**: Generate code, deploy actions

### Shell Aliases

Add to your shell profile:

```bash
# Quick access to Claude Code
alias claude-skills='cd /path/to/ravenna-claude && claude --plugin-dir .'

# Generate API code
alias gen-api='claude-skills --command "/api-code-generator"'

# Deploy code action
alias deploy-action='claude-skills --command "/code-action"'
```

## Files

### `warp-config.yaml` (Template)

Hypothetical configuration for Warp integration.

```yaml
# ~/.warp/config.yaml (hypothetical)
ai:
  skills:
    enabled: true
    directories:
      - ~/code/ravenna-claude/skills

  integrations:
    ravenna:
      type: http
      base_url: https://core.ravenna.ai/mcp
      auth:
        type: bearer
        token_env: RAVENNA_API_KEY
```

### Environment Variables

Set `RAVENNA_API_KEY` and optionally `RAVENNA_API_URL` in your shell.

## Feature Request

Interested in Warp support? Let them know:

1. **Warp Discord**: Request agentskills support
2. **Warp GitHub**: Open feature request
3. **This Repo**: Tell us you want Warp support

We'll prioritize Warp integration based on demand.

## Alternative: Full-Featured Clients

For full skill support now, use:

- **Claude Code** (recommended) - Native agentskills support
- **Claude Desktop** - Full AI features
- **Claude Web** - Browser-based access

## Getting Your API Key

1. Go to [ravenna.ai](https://ravenna.ai)
2. Sign up or log in
3. Navigate to API Keys section
4. Generate a new API key

## More Information

- **Skills Documentation**: [../../skills/](../../skills/)
- **Main README**: [../../README.md](../../README.md)
- **Warp Docs**: [https://docs.warp.dev](https://docs.warp.dev)
