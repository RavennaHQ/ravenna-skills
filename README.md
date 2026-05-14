# Agent Skills for API Integration

[![agentskills](https://img.shields.io/badge/format-agentskills-blue.svg)](https://agentskills.io)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)

> **Write once, use everywhere** - Skills that work across Claude, GitHub Copilot, Pi, and other AI agents.

A collection of production-ready skills for generating, deploying, and debugging TypeScript API integrations. Built using the [agentskills](https://agentskills.io) format for maximum cross-agent compatibility.

---

## 🌟 What is agentskills?

agentskills is an open format for creating reusable AI agent capabilities. Skills written in this format work across different AI agents (Claude, Copilot, Pi, etc.) without modification.

**Key Benefits:**
- ✅ **Cross-agent compatible** - Use the same skills in any agent
- ✅ **Progressive disclosure** - Load only what you need
- ✅ **Community maintained** - Open format backed by Anthropic
- ✅ **Easy to validate** - Standard format with validation tools

Learn more at [agentskills.io](https://agentskills.io)

---

## 📦 Skills Included

### 1. api-code-generator

Generate production-ready TypeScript API integration code from REST API documentation.

**Use when:** Integrating with a new REST API, creating reusable API client functions

**Features:**
- Analyzes API docs automatically
- Generates type-safe schemas
- Includes error handling and pagination
- Supports multiple authentication methods

[View Documentation](skills/api-code-generator/SKILL.md)

### 2. code-action

Generate TypeScript code and deploy it as an executable code action with full schema support.

**Use when:** Creating reusable, deployable API integrations

**Features:**
- End-to-end workflow (docs → code → deployment)
- Automatic validation
- Optional editor review mode
- Error handling and retry logic

[View Documentation](skills/code-action/SKILL.md)

### 3. debug-workflows

Debug and test workflows by manually triggering them with custom payloads.

**Use when:** Debugging workflow execution, testing integration logic

**Features:**
- Manual workflow triggering
- Step-by-step execution analysis
- Comprehensive debugging patterns
- Error root cause identification

[View Documentation](skills/debug-workflows/SKILL.md)

---

## 🚀 Installation

**Quick start by agent:**

### Claude Code ✅ (Recommended)

```bash
# Clone the repository
git clone https://github.com/RavennaHQ/ravenna-skills.git
cd ravenna-skills

# Run setup
cd config/claude && ./setup.sh && cd ../..

# Start Claude Code — it will prompt for your API key
claude --plugin-dir .
```

**Full documentation:** [config/claude/README.md](config/claude/README.md)

### GitHub Copilot ⚠️ (Experimental)

```bash
# Copy skills to Copilot directory
cp -r skills/* ~/.github/copilot/skills/

# Set credentials via environment
export RAVENNA_API_KEY="your-key"
```

**Full documentation:** [config/copilot/README.md](config/copilot/README.md)

### Warp ⚠️ (Via Claude CLI)

```bash
# Use Claude Code from Warp terminal
cd ravenna-claude
claude --plugin-dir .
```

**Full documentation:** [config/warp/README.md](config/warp/README.md)

### Pi ⚠️ (Experimental)

Manual skill loading - see documentation.

**Full documentation:** [config/pi/README.md](config/pi/README.md)

### Other Agents

Use generic templates as starting point.

**Full documentation:** [config/generic/README.md](config/generic/README.md)

---

**📚 Agent Compatibility Guide:** [config/README.md](config/README.md)

---

## 📖 Skills Format

Each skill follows the agentskills format:

```
skill-name/
├── SKILL.md          # Required: metadata + instructions
├── scripts/          # Optional: executable code
├── references/       # Optional: detailed documentation
└── assets/           # Optional: templates, resources
```

### SKILL.md Structure

Every `SKILL.md` has YAML frontmatter followed by markdown instructions:

```markdown
---
name: skill-name
description: What the skill does and when to use it
license: MIT
compatibility: Environment requirements (optional)
metadata:
  version: "1.0.0"
  author: your-name
---

# Skill Name

Instructions for AI agents...
```

**Required Fields:**
- `name` - Skill name (lowercase, hyphens, must match directory)
- `description` - What it does and when to use it (1-1024 chars)

**Optional Fields:**
- `license` - License name or file reference
- `compatibility` - Environment requirements
- `metadata` - Custom key-value pairs

---

## 🎯 Quick Start

### Example 1: Generate API Code

```
Use api-code-generator skill to create GitHub API integration

API Docs: https://docs.github.com/rest/users/users#get-a-user
Request: Fetch GitHub user information by username
```

**Result:** Complete TypeScript code with `run()` function, `inputSchema`, and `outputSchema`.

### Example 2: Deploy Code Action

```
Use code-action skill to deploy the code

Create a code action for fetching GitHub user information
API Docs: https://docs.github.com/rest/users/users#get-a-user
```

**Result:** Code generated, validated, and deployed as executable action.

### Example 3: Debug Workflow

```
Use debug-workflows skill to test

Debug workflow wf_abc123 with test payload:
{
  "event_type": "user_created",
  "user_id": "test_123"
}
```

**Result:** Workflow execution analysis with step-by-step details.

---

## 🔧 Configuration

### For code-action Skill

Requires access to a code action deployment platform (e.g., Ravenna).

If using Claude Code with `--plugin-dir .`, credentials are configured automatically via the plugin system. For other agents or CI:

```bash
export RAVENNA_API_KEY="your-api-key-here"
```

### For debug-workflows Skill

Requires connection to workflow platform:

```bash
# Configure MCP connection (for Claude Code)
# See .mcp.json for configuration
```

---

## 📚 Documentation

### Main Documentation

- [agentskills Specification](https://agentskills.io/specification) - Format details
- [agentskills GitHub](https://github.com/agentskills/agentskills) - Source repository

### Skill Documentation

Each skill has detailed documentation:

- **api-code-generator**
  - [SKILL.md](skills/api-code-generator/SKILL.md) - Main instructions
  - [references/PATTERNS.md](skills/api-code-generator/references/PATTERNS.md) - Code patterns

- **code-action**
  - [SKILL.md](skills/code-action/SKILL.md) - Main instructions
  - [references/EXAMPLES.md](skills/code-action/references/EXAMPLES.md) - Usage examples
  - [references/ERROR_HANDLING.md](skills/code-action/references/ERROR_HANDLING.md) - Error scenarios
  - [references/VALIDATION.md](skills/code-action/references/VALIDATION.md) - Validation rules

- **debug-workflows**
  - [SKILL.md](skills/debug-workflows/SKILL.md) - Main instructions

---

## 🤝 Contributing

Contributions welcome! To add a new skill:

1. Create a new directory in `skills/`
2. Follow the agentskills format:
   - Add `SKILL.md` with proper frontmatter
   - Keep main instructions concise (<500 lines)
   - Move detailed content to `references/`
3. Test with multiple agents if possible
4. Submit a pull request

**Areas for contribution:**
- New skills for different APIs
- Improvements to existing skills
- Additional code generation patterns
- More comprehensive examples
- Cross-agent testing and compatibility

---

## 📋 Requirements

**General:**
- Skills work with any agent supporting agentskills format
- No specific runtime required for skill definitions

**For Code Generation (api-code-generator, code-action):**
- Ability to fetch web content
- Ability to generate and write TypeScript code

**For Deployment (code-action):**
- Access to deployment platform (e.g., Ravenna MCP server)
- Platform credentials configured

**For Workflow Debugging (debug-workflows):**
- Connection to workflow platform
- Workflow trigger and inspect capabilities

---

## 🛠️ Agent Compatibility

These skills have been tested with:

- ✅ **Claude Code** (CLI, Desktop, Web, IDE extensions)
- ⏳ **GitHub Copilot** (format compatible, testing in progress)
- ⏳ **Pi** (format compatible, testing in progress)
- ⏳ **Other agents** (should work, needs testing)

The agentskills format is designed for maximum compatibility. If you test these skills with other agents, please report your results!

---

## 📄 License

MIT License - see [LICENSE](./LICENSE) file for details.

**Individual licenses:**
- api-code-generator: MIT
- code-action: MIT
- debug-workflows: MIT

---

## 🙏 Credits

**Built with:**
- [agentskills](https://agentskills.io) - Open format by Anthropic
- TypeScript - Generated code language
- Ravenna - Code action platform (for code-action and debug-workflows)

**Inspired by:**
- Model Context Protocol (MCP)
- OpenAI Function Calling
- GitHub Actions workflow syntax

---

## 📞 Support

**Getting Help:**

1. **Skill Documentation:** Check each skill's SKILL.md file
2. **agentskills Docs:** [agentskills.io](https://agentskills.io)
3. **Issues:** [GitHub Issues](https://github.com/RavennaHQ/ravenna-skills/issues)
4. **Community:** [agentskills Discord](https://discord.gg/agentskills)

**Common Issues:**

- **Skill not loading:** Verify SKILL.md frontmatter is valid
- **Name mismatch error:** Ensure `name` field matches directory name
- **Agent not recognizing skill:** Check agent supports agentskills format
- **Deployment failing:** Verify platform credentials are configured

---

## 🔄 Version History

### v2.0.0 (2026-04-21) - **agentskills Format**

- 🔄 **Complete rewrite** to follow agentskills specification
- ✅ Added proper frontmatter to all skills (`name`, `description`, `license`, etc.)
- ✅ Split large files into main SKILL.md + references/
- ✅ Made skills agent-agnostic (work with Claude, Copilot, Pi, etc.)
- ✅ Improved progressive disclosure (keep main files <500 lines)
- ✅ Updated README for cross-agent compatibility
- ⚠️ **Breaking:** Directory structure changed to follow agentskills format

### v1.0.0 (2026-03-30) - Initial Release

- ✅ Claude-specific plugin format
- ✅ Three skills: api-code-generator, code-action, debug-workflows
- ✅ MCP integration
- ✅ Basic documentation

---

## 🌟 What's Next?

**Planned Features:**
- More skills for common APIs (Stripe, Twilio, AWS, etc.)
- GitHub Actions skill for CI/CD integration
- Database query skill (SQL, MongoDB, etc.)
- Testing skill for generated code
- Documentation generation skill

**Help Wanted:**
- Test skills with non-Claude agents
- Add skills for popular services
- Improve documentation
- Create video tutorials
- Translate to other languages

---

## 🚀 Ready to Go!

```bash
# Get started
git clone https://github.com/RavennaHQ/ravenna-skills.git
cd ravenna-claude

# Use with your favorite agent
claude --plugin-dir .
```

Then use any skill:

```
/api-code-generator
Generate API integration code for GitHub users API
API Docs: https://docs.github.com/rest/users/users#get-a-user
```

**Happy coding!** 🎉
