# Repository Structure

Complete overview of the agent skills repository organization.

## Directory Tree

```
ravenna-claude/
├── skills/                          # ✅ Cross-agent compatible skills
│   ├── api-code-generator/
│   │   ├── SKILL.md                # Main skill definition
│   │   └── references/
│   │       └── PATTERNS.md         # Detailed code patterns
│   ├── code-action/
│   │   ├── SKILL.md                # Main skill definition
│   │   └── references/
│   │       ├── EXAMPLES.md         # Usage examples
│   │       ├── ERROR_HANDLING.md   # Error scenarios
│   │       └── VALIDATION.md       # Validation rules
│   └── debug-workflows/
│       └── SKILL.md                # Main skill definition
│
├── config/                          # 🔧 Agent-specific configurations
│   ├── README.md                   # Config overview
│   ├── claude/                     # ✅ Claude Code (fully supported)
│   │   ├── README.md
│   │   ├── setup.sh
│   │   ├── mcp.json
│   │   └── .claude-plugin/
│   │       ├── plugin.json         # userConfig schema (prompts for API key)
│   │       └── mcp.json
│   ├── copilot/                    # ⚠️ GitHub Copilot (experimental)
│   │   └── README.md
│   ├── warp/                       # ⚠️ Warp (hypothetical)
│   │   ├── README.md
│   │   └── warp-config.yaml
│   ├── pi/                         # ⚠️ Pi (experimental)
│   │   └── README.md
│   └── generic/                    # 📋 Templates for any agent
│       ├── README.md
│       ├── config-template.json
│       ├── config-template.yaml
│       └── config-template.toml
│
├── .claude-plugin/                  # Plugin metadata (copied by setup.sh)
├── .mcp.json                        # MCP config (uses env vars)
│
├── README.md                        # Main documentation
├── CONTRIBUTING.md                  # Contribution guide
├── AGENTSKILLS.md                   # agentskills format guide
├── STRUCTURE.md                     # This file
│
└── .gitignore
```

## File Types

### ✅ Universal (Cross-Agent)

**Skills** (`skills/*/SKILL.md`):
- Work with any agent supporting agentskills
- Agent-agnostic instructions
- Progressive disclosure with `references/`

**Documentation**:
- `README.md` - Repository overview
- `AGENTSKILLS.md` - Format guide
- `CONTRIBUTING.md` - Contribution guidelines

### 🔧 Agent-Specific

**Claude Code** (`config/claude/`):
- MCP configuration
- Plugin metadata
- Setup automation

**Other Agents** (`config/*/`):
- Agent-specific setup
- Configuration templates
- Integration guides

### 📋 Templates

**Generic** (`config/generic/`):
- JSON/YAML/TOML config templates
- Integration guidelines
- Implementation checklist

## Key Differences

### Skills vs. Config

| Aspect | Skills (`skills/`) | Config (`config/`) |
|--------|-------------------|-------------------|
| **Purpose** | What to do | How to connect |
| **Compatibility** | ✅ Cross-agent | ❌ Agent-specific |
| **Format** | agentskills | Agent-defined |
| **Changes** | Rarely | Per-agent setup |

### agentskills Format vs. Agent Config

**agentskills (Universal)**:
```
skills/api-code-generator/SKILL.md
---
name: api-code-generator
description: Generate TypeScript API code...
---
# Instructions for any agent...
```

**Agent Config (Specific)**:
```
config/claude/mcp.json
{
  "mcpServers": {
    "mcp": {
      "url": "${env.RAVENNA_API_URL}",
      ...
    }
  }
}
```

## Usage Patterns

### Pattern 1: Skills Only (No Deployment)

```
User: Generate code for GitHub API
Agent: Reads skills/api-code-generator/SKILL.md
Agent: Generates TypeScript code
✅ Works with any agent
```

### Pattern 2: Skills + Deployment (Needs Config)

```
User: Deploy code to Ravenna
Agent: Reads skills/code-action/SKILL.md
Agent: Reads config/claude/mcp.json
Agent: Connects to Ravenna API
Agent: Deploys code action
⚠️ Requires agent-specific config
```

## Setup by Agent

### Claude Code

```bash
# Use dedicated config
cd config/claude
./setup.sh

# Or manual
export RAVENNA_API_KEY=your-key
claude --plugin-dir .
```

**Files used:**
- `config/claude/mcp.json`
- `config/claude/.claude-plugin/`
- `skills/*/SKILL.md`

### Copilot

```bash
# Copy skills
cp -r skills ~/.github/copilot/skills/

# Configure credentials
export RAVENNA_API_KEY="your-key"
```

**Files used:**
- `skills/*/SKILL.md`

### Others

See `config/your-agent/README.md`

## What to Edit

### Adding a New Skill

**Edit:**
```
skills/
└── new-skill/
    ├── SKILL.md          # Create this
    └── references/       # Optional
```

**Don't edit:**
- Config files (agent-specific)

### Adding Agent Support

**Edit:**
```
config/
└── new-agent/
    ├── README.md         # Create this
    └── config.xyz        # Agent-specific config
```

**Update:**
- `config/README.md` - Add to agent list
- Main `README.md` - Add installation section

### Fixing MCP Connection

**Edit:**
```
config/claude/mcp.json     # Update connection settings
```

**Or:**
```bash
export RAVENNA_API_URL=new-url
export RAVENNA_API_KEY=new-key
```

## Migration from v1.0.0

**Old structure:**
```
.
├── .mcp.json                    # Claude-specific
├── .claude-plugin/              # Claude-specific
└── skills/*/SKILL.md           # Claude-specific language
```

**New structure (v2.0.0):**
```
.
├── config/                      # Agent-specific configs
│   ├── claude/                 # Claude Code
│   ├── copilot/                # GitHub Copilot
│   ├── warp/                   # Warp
│   ├── pi/                     # Pi
│   └── generic/                # Templates
└── skills/                      # ✅ Universal skills
    └── */SKILL.md              # Agent-agnostic
```

**Migration steps:**

1. **Old config files moved** to `config/claude/`
2. **Skills rewritten** to be agent-agnostic
3. **New configs added** for other agents
4. **Documentation updated** with agent-specific guides

## Future Structure

### Planned Additions

```
skills/
├── graphql-code-generator/     # GraphQL support
├── database-query/             # SQL/MongoDB
└── github-actions/             # CI/CD integration

config/
├── cursor/                     # Cursor IDE
├── continue/                   # Continue.dev
└── aider/                      # Aider
```

### Extension Points

**Custom skills:**
```
skills/
└── my-custom-skill/
    ├── SKILL.md
    └── scripts/
        └── custom.py
```

**Custom agent config:**
```
config/
└── my-agent/
    ├── README.md
    └── config.yaml
```

### Validate Config

```bash
# Claude config
cd config/claude
./setup.sh --validate

# Check MCP connection
claude --plugin-dir ../.. --validate-mcp
```

## More Information

- **Main README**: [README.md](README.md)
- **Config Guide**: [config/README.md](config/README.md)
- **agentskills Format**: [AGENTSKILLS.md](AGENTSKILLS.md)
- **Contributing**: [CONTRIBUTING.md](CONTRIBUTING.md)

---

**Structure last updated:** 2026-04-21 (v2.0.0)
