# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2026-04-21 - **Agent-Specific Config Support**

### Added

#### Config Infrastructure
- ✅ **config/** directory with agent-specific configurations
- ✅ **config/claude/** - Full Claude Code setup with MCP integration
- ✅ **config/copilot/** - GitHub Copilot configuration templates
- ✅ **config/warp/** - Warp terminal integration guides
- ✅ **config/pi/** - Pi AI configuration templates
- ✅ **config/generic/** - Universal config templates (JSON/YAML/TOML)

#### Setup Automation
- ✅ **config/claude/setup.sh** - Automated setup script for Claude Code
- ✅ Agent-specific README files with detailed instructions
- ✅ Environment variable templates for each agent

#### Documentation
- ✅ **config/README.md** - Agent compatibility guide
- ✅ **STRUCTURE.md** - Complete repository structure overview
- ✅ Updated main README with agent-specific installation
- ✅ Cross-agent comparison tables

### Changed

#### Configuration Organization
- 🔄 **Moved** `.mcp.json` → `config/claude/mcp.json`
- 🔄 **Moved** `.claude-plugin/` → `config/claude/.claude-plugin/`
- 🔄 **Moved** `.env.example` → `config/claude/.env.example`
- 🔄 **Fixed** MCP authentication to use `${env.*}` instead of `${user_config.*}`

#### Skills (No Changes)
- ✅ Skills remain in `skills/` directory
- ✅ Already agent-agnostic from v1.1.0
- ✅ No breaking changes to skill functionality

### Fixed

- 🐛 **MCP authentication** - Now properly uses environment variables
- 🐛 **Cross-agent compatibility** - Separated agent-specific config from universal skills

### Migration Guide

#### For Existing Users

**Old setup (v1.x):**
```bash
export RAVENNA_API_KEY=your-key
claude --plugin-dir .
```

**New setup (v2.0):**
```bash
cd config/claude
./setup.sh
# Or manually:
export RAVENNA_API_KEY=your-key
claude --plugin-dir ../..
```

**What changed:**
- Configuration files moved to `config/claude/`
- MCP config now uses environment variables properly
- Skills remain unchanged (no migration needed)

#### For New Users

Choose your agent and follow the setup guide:
- **Claude Code**: `config/claude/README.md`
- **GitHub Copilot**: `config/copilot/README.md`
- **Warp**: `config/warp/README.md`
- **Pi**: `config/pi/README.md`
- **Other**: `config/generic/README.md`

---

## [1.1.0] - 2026-04-01 - **agentskills Format**

### Added
- ✅ Proper YAML frontmatter to all skills (`name`, `description`, `license`, etc.)
- ✅ Progressive disclosure with `references/` directories
- ✅ **api-code-generator/references/PATTERNS.md** - Detailed code patterns
- ✅ **code-action/references/EXAMPLES.md** - Usage examples
- ✅ **code-action/references/ERROR_HANDLING.md** - Error scenarios
- ✅ **code-action/references/VALIDATION.md** - Validation rules
- ✅ **AGENTSKILLS.md** - Format guide
- ✅ **CONTRIBUTING.md** - Contribution guidelines

### Changed
- 🔄 Skills rewritten to be agent-agnostic
- 🔄 Main SKILL.md files reduced to <500 lines
- 🔄 Detailed content moved to `references/`
- 🔄 Updated README for cross-agent compatibility

### Fixed
- 🐛 code-action SKILL.md was 2298 lines (now ~450 + references)
- 🐛 Claude-specific terminology replaced with generic language

---

## [1.0.0] - 2026-03-30 - **Initial Release**

### Added
- ✅ **api-code-generator** skill - Generate TypeScript API code
- ✅ **code-action** skill - Deploy code as actions
- ✅ **debug-workflows** skill - Debug Ravenna workflows
- ✅ MCP integration for Ravenna
- ✅ Basic documentation

### Features
- TypeScript code generation from API docs
- Automatic schema generation
- Error handling and pagination
- Code action deployment
- Workflow debugging

---

## Version History Summary

| Version | Date | Key Changes |
|---------|------|-------------|
| **2.0.0** | 2026-04-21 | 🎯 Agent-specific configs, Fixed MCP auth |
| **1.1.0** | 2026-04-01 | 📦 agentskills format, Cross-agent compatible |
| **1.0.0** | 2026-03-30 | 🚀 Initial release, Claude Code only |

---

## Upgrading

### From 1.1.0 to 2.0.0

**What changed:**
- Configuration files moved to `config/` directory
- MCP authentication now uses environment variables

**Action required:**
```bash
# 1. Update MCP config
cd config/claude
./setup.sh

# 2. Or manually update environment variables
export RAVENNA_API_KEY=your-key
export RAVENNA_API_URL=https://core.ravenna.ai/mcp

# 3. Restart Claude Code
claude --plugin-dir .
```

**No action needed for:**
- Skills (no changes)
- Existing code actions (still work)
- API keys (same keys work)

### From 1.0.0 to 2.0.0

**Major changes:**
- Skills now use agentskills format
- Configuration separated by agent
- Agent-agnostic language throughout

**Migration steps:**
```bash
# 1. Update to latest
git pull origin main

# 2. Setup for your agent
cd config/claude  # or copilot, warp, pi
./setup.sh        # (if available)

# 3. Update environment
export RAVENNA_API_KEY=your-key

# 4. Restart
claude --plugin-dir ../..
```

---

## Future Roadmap

### v2.1.0 (Planned)
- [ ] **graphql-code-generator** skill
- [ ] **database-query** skill
- [ ] VS Code extension for Copilot integration
- [ ] Enhanced Warp support

### v2.2.0 (Planned)
- [ ] **github-actions** skill for CI/CD
- [ ] **test-generator** skill
- [ ] Cursor IDE support
- [ ] Continue.dev support

### v3.0.0 (Future)
- [ ] Skill marketplace
- [ ] Skill dependencies
- [ ] Skill versioning
- [ ] Community skill registry

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

**Areas for contribution:**
- New skills
- Agent configurations
- Documentation improvements
- Bug fixes
- Feature requests

---

## Questions?

- **Issues**: [GitHub Issues](https://github.com/RavennaHQ/ravenna-skills/issues)
- **Discussions**: [GitHub Discussions](https://github.com/RavennaHQ/ravenna-skills/discussions)
- **agentskills**: [agentskills.io](https://agentskills.io)
