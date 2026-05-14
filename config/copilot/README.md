# GitHub Copilot Configuration

Configuration for using these skills with [GitHub Copilot](https://github.com/features/copilot).

## Status

⚠️ **Experimental** - GitHub Copilot support for agentskills format is in development.

The skills are written in agentskills format which should be compatible with Copilot, but configuration for Ravenna API integration may require custom extensions.

## Setup (Skills Only)

Skills can be loaded into Copilot's workspace:

```bash
# Copy skills to your project
cp -r ../../skills ~/.github/copilot/skills/

# Or link them
ln -s $(pwd)/../../skills ~/.github/copilot/skills/ravenna
```

## Configuration

### Option 1: Environment Variables (Recommended)

Set in your shell or CI environment:

```bash
export RAVENNA_API_KEY="your-ravenna-api-key"
export RAVENNA_API_URL="https://core.ravenna.ai/mcp"
```

### Option 2: GitHub Secrets

For team usage, store in GitHub repository secrets:

1. Go to repository Settings → Secrets and variables → Actions
2. Add secrets:
   - `RAVENNA_API_KEY`
   - `RAVENNA_API_URL` (optional)

## Skills Usage

### Basic Skills

These skills work out-of-the-box with Copilot:

**✅ api-code-generator** - Generate TypeScript API code
- No external API required
- Pure code generation
- Works in any Copilot-enabled editor

Usage in comments:
```typescript
// Use api-code-generator skill to create GitHub API integration
// API Docs: https://docs.github.com/rest/users/users#get-a-user
// Generate code to fetch user by username
```

### Advanced Skills (Require Integration)

These skills need Ravenna API access:

**⚠️ code-action** - Deploy code as actions
- Requires Ravenna API connection
- May need custom Copilot extension
- Alternative: Use Claude Code for deployment

**⚠️ debug-workflows** - Debug Ravenna workflows
- Requires Ravenna MCP connection
- May need custom Copilot extension
- Alternative: Use Claude Code for debugging

## Limitations

GitHub Copilot currently has limitations for agentskills:

1. **No native MCP support** - Cannot connect to Ravenna MCP directly
2. **Extension required** - May need custom VS Code extension for API integration
3. **Skill discovery** - Copilot may not automatically discover skills

## Workarounds

### Hybrid Approach

Use Copilot for code generation, Claude Code for deployment:

1. **In VS Code with Copilot:**
   ```typescript
   // Use api-code-generator to create code
   // [Copilot generates the code]
   ```

2. **Switch to Claude Code for deployment:**
   ```bash
   claude --plugin-dir /path/to/ravenna-claude
   # /code-action
   # Deploy the generated code
   ```

### Custom Extension

Create a VS Code extension that:
- Reads agentskills from `skills/` directory
- Connects to Ravenna API
- Bridges Copilot and Ravenna

See `extension-template/` for a starter template (coming soon).

## Future Plans

We're tracking Copilot support:

- [ ] Test skills with Copilot Workspace
- [ ] Create VS Code extension for Ravenna integration
- [ ] Document Copilot-specific usage patterns
- [ ] Add Copilot-native deployment methods

## Alternative: Use Claude Code

For full functionality, use Claude Code:

```bash
cd /path/to/ravenna-claude
claude --plugin-dir .
```

All skills work seamlessly with Claude Code.

## Getting Your API Key

1. Go to [ravenna.ai](https://ravenna.ai)
2. Sign up or log in
3. Navigate to API Keys section
4. Generate a new API key

## Feedback

Testing Copilot support? Let us know:

- **Issues**: [GitHub Issues](https://github.com/RavennaHQ/ravenna-skills/issues)
- **What works**: Share successful patterns
- **What doesn't**: Help us improve compatibility

## More Information

- **Skills Documentation**: [../../skills/](../../skills/)
- **Main README**: [../../README.md](../../README.md)
- **agentskills Format**: [../../AGENTSKILLS.md](../../AGENTSKILLS.md)
