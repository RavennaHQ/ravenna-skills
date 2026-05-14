# Agent-Specific Configuration

This directory contains configuration files for different AI agents. Each subdirectory provides agent-specific setup instructions and configuration files.

## Directory Structure

```
config/
├── claude/          # ✅ Claude Code (fully supported)
├── copilot/         # ⚠️ GitHub Copilot (experimental)
├── warp/            # ⚠️ Warp (hypothetical)
├── pi/              # ⚠️ Pi (experimental)
├── generic/         # 📋 Templates for any agent
└── README.md        # This file
```

## Quick Start by Agent

### Claude Code ✅

**Status:** Fully supported with MCP integration

```bash
cd config/claude
./setup.sh
```

**What you get:**
- Full skill support
- Ravenna MCP integration
- Code action deployment
- Workflow debugging

**Documentation:** [claude/README.md](claude/README.md)

---

### GitHub Copilot ⚠️

**Status:** Skills work, API integration experimental

```bash
cd config/copilot
# Follow README for setup
```

**What works:**
- ✅ api-code-generator (pure code generation)
- ⚠️ code-action (needs custom extension for deployment)
- ⚠️ debug-workflows (needs custom extension)

**Documentation:** [copilot/README.md](copilot/README.md)

---

### Warp ⚠️

**Status:** Hypothetical - awaiting Warp agentskills support

```bash
cd config/warp
# See README for workarounds
```

**Current approach:**
- Use Claude Code CLI from Warp terminal
- Shell aliases for quick access

**Documentation:** [warp/README.md](warp/README.md)

---

### Pi ⚠️

**Status:** Experimental - support unknown

```bash
cd config/pi
# See README for testing approaches
```

**Current approach:**
- Manual skill loading (copy instructions)
- Use Claude Code for full features

**Documentation:** [pi/README.md](pi/README.md)

---

### Generic 📋

**Status:** Templates for integrating with any agent

```bash
cd config/generic
# Use templates as starting point
```

**Contains:**
- Configuration templates (JSON, YAML, TOML)
- Integration guidelines
- Implementation checklist

**Documentation:** [generic/README.md](generic/README.md)

---

## Comparison

| Feature | Claude Code | Copilot | Warp | Pi | Generic |
|---------|-------------|---------|------|-----|---------|
| **Skills Load** | ✅ Native | ⚠️ Manual | ⚠️ Via CLI | ⚠️ Manual | 📋 Template |
| **api-code-generator** | ✅ Full | ✅ Works | ⚠️ Via CLI | ⚠️ Manual | - |
| **code-action** | ✅ Full | ⚠️ Extension needed | ⚠️ Via CLI | ⚠️ Manual | - |
| **debug-workflows** | ✅ Full | ⚠️ Extension needed | ⚠️ Via CLI | ⚠️ Manual | - |
| **MCP Integration** | ✅ Built-in | ❌ Not supported | ❌ Not supported | ❌ Unknown | - |
| **Setup Complexity** | 🟢 Easy | 🟡 Medium | 🟡 Medium | 🟡 Medium | - |
| **Documentation** | ✅ Complete | ⚠️ Partial | ⚠️ Hypothetical | ⚠️ Experimental | ✅ Template |

Legend: ✅ Fully supported | ⚠️ Partial/experimental | ❌ Not supported | 📋 Template | 🟢 Easy | 🟡 Medium | 🔴 Hard

---

## Common Setup

### Environment Variables

All agents need these environment variables for Ravenna integration:

```bash
# Required
export RAVENNA_API_KEY="your-api-key"

# Optional (defaults to https://core.ravenna.ai/mcp)
export RAVENNA_API_URL="https://core.ravenna.ai/mcp"
```

### Getting Your API Key

1. Go to [ravenna.ai](https://ravenna.ai)
2. Sign up or log in
3. Navigate to API Keys section
4. Generate a new API key
5. Copy and set as `RAVENNA_API_KEY`

For Claude Code, the plugin system will prompt you interactively — no manual env setup needed.

---

## Skills Overview

All agents can use these skills (with varying levels of support):

### 1. api-code-generator

**What it does:** Generate TypeScript API integration code from documentation

**Requirements:**
- ✅ Read web content
- ✅ Generate code
- ❌ No external API needed

**Agent compatibility:**
- ✅ Claude Code - Full support
- ✅ Copilot - Works great
- ⚠️ Warp - Via Claude CLI
- ⚠️ Pi - Manual loading

### 2. code-action

**What it does:** Deploy generated code as executable actions

**Requirements:**
- ✅ Code generation (via api-code-generator)
- ✅ Code validation
- ⚠️ HTTP API (to Ravenna)
- ⚠️ Optional editor integration

**Agent compatibility:**
- ✅ Claude Code - Full support
- ⚠️ Copilot - Needs extension
- ⚠️ Warp - Via Claude CLI
- ⚠️ Pi - Manual process

### 3. debug-workflows

**What it does:** Debug and test Ravenna workflows

**Requirements:**
- ⚠️ HTTP API (to Ravenna MCP)
- ✅ JSON parsing

**Agent compatibility:**
- ✅ Claude Code - Full support
- ⚠️ Copilot - Needs extension
- ⚠️ Warp - Via Claude CLI
- ⚠️ Pi - Manual process

---

## Adding a New Agent

Want to add configuration for a new agent?

### 1. Create Directory

```bash
mkdir config/your-agent
cd config/your-agent
```

### 2. Add Configuration Files

Create agent-specific config files:
- `README.md` - Setup instructions
- Authentication setup documentation
- Config files (JSON/YAML/etc.)
- Setup scripts (optional)

### 3. Test Integration

Test each skill:
- ✅ api-code-generator (should work with any agent)
- ⚠️ code-action (needs API integration)
- ⚠️ debug-workflows (needs API integration)

### 4. Document

Document in README.md:
- Setup steps
- What works vs. what doesn't
- Known limitations
- Workarounds
- Testing results

### 5. Submit PR

Submit a pull request with your new agent configuration!

---

## Troubleshooting

### "Authentication failed"

**Problem:** API key not recognized

**Solutions:**
- Check `RAVENNA_API_KEY` is set correctly
- Verify key is valid at ravenna.ai
- Ensure no extra whitespace
- Check env var is exported in current shell

### "Skill not found"

**Problem:** Agent can't find skills

**Solutions:**
- Verify `skills/` directory exists
- Check you're in repository root
- Ensure SKILL.md files have frontmatter
- Try absolute paths instead of relative

### "Connection refused"

**Problem:** Can't connect to Ravenna API

**Solutions:**
- Check `RAVENNA_API_URL` is correct
- Verify internet connectivity
- Try default URL: `https://core.ravenna.ai/mcp`
- Check firewall settings

### Agent-Specific Issues

Check your agent's README:
- [Claude Code troubleshooting](claude/README.md#troubleshooting)
- [Copilot troubleshooting](copilot/README.md#limitations)
- [Warp troubleshooting](warp/README.md#current-workaround)
- [Pi troubleshooting](pi/README.md#current-workaround)

---

## Contributing

### Tested a New Agent?

Share your results:

1. Open a GitHub issue or discussion
2. Include:
   - Agent name and version
   - What worked
   - What didn't work
   - Workarounds you found
3. We'll update the documentation

### Created Agent Configuration?

Submit a pull request:

1. Add your agent directory under `config/`
2. Include all setup files
3. Document everything in README.md
4. Test thoroughly
5. Submit PR

### Improvements?

Have ideas for existing configs?

- Open a GitHub issue
- Submit a pull request
- Start a discussion

---

## More Information

### Skills

- **Skills Directory:** [../skills/](../skills/)
- **agentskills Format:** [../AGENTSKILLS.md](../AGENTSKILLS.md)

### Documentation

- **Main README:** [../README.md](../README.md)
- **Contributing:** [../CONTRIBUTING.md](../CONTRIBUTING.md)
- **Installation Guide:** [../INSTALL.md](../INSTALL.md)

### External Resources

- **agentskills Spec:** [agentskills.io/specification](https://agentskills.io/specification)
- **Ravenna Docs:** [docs.ravenna.ai](https://docs.ravenna.ai)
- **Community:** [GitHub Discussions](https://github.com/RavennaHQ/ravenna-skills/discussions)

---

**Made with ❤️ for cross-agent compatibility**
