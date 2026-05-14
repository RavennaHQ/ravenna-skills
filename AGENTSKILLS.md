# agentskills Format Guide

This repository follows the [agentskills](https://agentskills.io) format, making skills compatible across multiple AI agents.

## What is agentskills?

agentskills is an open, community-maintained format for creating reusable AI agent capabilities. Skills written in this format work across different AI agents (Claude, GitHub Copilot, Pi, etc.) without modification.

**Key Principles:**
1. **Write once, use everywhere** - Cross-agent compatibility
2. **Progressive disclosure** - Load only what you need
3. **Standard format** - Easy to validate and share
4. **Open and extensible** - Community contributions welcome

Learn more: [agentskills.io](https://agentskills.io)

---

## Directory Structure

Each skill follows this structure:

```
skill-name/
├── SKILL.md          # Required: metadata + instructions
├── scripts/          # Optional: executable code
├── references/       # Optional: detailed documentation
└── assets/           # Optional: templates, resources
```

### SKILL.md (Required)

The `SKILL.md` file contains:
1. **YAML frontmatter** - Metadata about the skill
2. **Markdown body** - Instructions for AI agents

Example:

```markdown
---
name: skill-name
description: What the skill does and when to use it
license: MIT
compatibility: Optional environment requirements
metadata:
  version: "1.0.0"
  author: your-name
---

# Skill Name

Instructions for AI agents...
```

### references/ (Optional)

Contains detailed documentation that agents load on-demand:

```
references/
├── EXAMPLES.md       # Detailed usage examples
├── PATTERNS.md       # Common patterns and code samples
├── ERROR_HANDLING.md # Error scenarios and recovery
└── VALIDATION.md     # Validation rules and formats
```

**Benefits:**
- Keep main SKILL.md concise (<500 lines)
- Reduce initial context load
- Better organization
- Easier maintenance

### scripts/ (Optional)

Contains executable code that agents can run:

```
scripts/
├── helper.py         # Python helper script
├── transform.js      # JavaScript utility
└── validate.sh       # Shell script
```

Scripts should:
- Be self-contained
- Include clear error messages
- Handle edge cases gracefully
- Document dependencies

### assets/ (Optional)

Contains static resources:

```
assets/
├── template.json     # JSON template
├── config-sample.yml # Configuration example
└── diagram.png       # Visual aid
```

---

## SKILL.md Frontmatter

### Required Fields

#### name (Required)

- **Type:** string
- **Length:** 1-64 characters
- **Format:** Lowercase letters (a-z), numbers (0-9), hyphens (-)
- **Rules:**
  - Must match directory name
  - No leading/trailing hyphens
  - No consecutive hyphens (`--`)
- **Example:** `api-code-generator`

#### description (Required)

- **Type:** string
- **Length:** 1-1024 characters
- **Should include:**
  - What the skill does
  - When to use it
  - Keywords for discoverability
- **Example:** "Generate TypeScript API code from REST documentation. Use when integrating with APIs or creating reusable client functions."

### Optional Fields

#### license (Optional)

- **Type:** string
- **Purpose:** Specify skill license
- **Examples:**
  - `MIT`
  - `Apache-2.0`
  - `Proprietary. See LICENSE.txt`

#### compatibility (Optional)

- **Type:** string
- **Length:** max 500 characters
- **Purpose:** Specify environment requirements
- **Examples:**
  - `Requires Node.js 18+ and TypeScript`
  - `Designed for Claude Code or similar products`
  - `Requires git, docker, and internet access`

#### metadata (Optional)

- **Type:** object (key-value pairs)
- **Purpose:** Additional custom metadata
- **Example:**
  ```yaml
  metadata:
    version: "1.0.0"
    author: jane-doe
    tags:
      - api
      - typescript
    updated: "2026-04-21"
  ```

#### allowed-tools (Optional, Experimental)

- **Type:** string (space-separated tool names)
- **Purpose:** Pre-approved tools the skill may use
- **Example:** `allowed-tools: Bash(git:*) Bash(jq:*) Read`
- **Note:** Support varies by agent

---

## Progressive Disclosure

Skills should use progressive disclosure to minimize context usage:

### Level 1: Metadata (~100 tokens)

The `name` and `description` fields are loaded at startup for all skills. Keep these concise but informative.

**Used for:** Skill discovery and selection

### Level 2: Instructions (<5000 tokens recommended)

The main SKILL.md body is loaded when the skill is activated. Keep under 500 lines.

**Used for:** Core instructions and basic examples

### Level 3: Resources (as needed)

Files in `references/`, `scripts/`, and `assets/` are loaded only when required.

**Used for:** Detailed examples, error handling, validation rules, etc.

---

## Writing Agent-Agnostic Skills

Skills should work across different AI agents. Follow these guidelines:

### ❌ Agent-Specific Language

```markdown
Use the WebFetch tool to retrieve the API documentation.
Call the Skill tool to invoke api-code-generator.
Use the MCP tool create_code_action to deploy.
```

### ✅ Generic Capabilities

```markdown
Retrieve the API documentation from the provided URL.
Invoke the api-code-generator skill to generate code.
Deploy the code action using the deployment platform API.
```

### Describe Capabilities, Not Tools

Instead of assuming specific tool names:
- "Fetch web content" vs "Use WebFetch tool"
- "Generate code" vs "Call code generator"
- "Execute shell command" vs "Use Bash tool"

### Use compatibility Field for Specifics

If a skill requires specific capabilities:

```yaml
---
name: my-skill
description: General description
compatibility: Requires ability to fetch web content, execute shell commands, and read/write files. Designed for Claude Code or similar products.
---
```

---

## This Repository's Structure

### Skills Included

1. **api-code-generator/**
   - Main: `SKILL.md` (400 lines)
   - References: `references/PATTERNS.md` (detailed patterns)

2. **code-action/**
   - Main: `SKILL.md` (450 lines)
   - References:
     - `references/EXAMPLES.md` (detailed examples)
     - `references/ERROR_HANDLING.md` (error scenarios)
     - `references/VALIDATION.md` (validation rules)

3. **debug-workflows/**
   - Main: `SKILL.md` (700 lines)
   - Note: Could be split further if needed

### Why This Structure?

**Before agentskills format:**
- Single 2298-line SKILL.md file (code-action)
- Claude-specific terminology
- Difficult to maintain
- Slow to load

**After agentskills format:**
- Main SKILL.md <500 lines
- Detailed content in references/
- Agent-agnostic language
- Cross-agent compatible
- Faster loading
- Better organization

---

## Cross-Agent Compatibility

### Tested Agents

- ✅ **Claude Code** (CLI, Desktop, Web, IDE extensions)
- ⏳ **GitHub Copilot** (format compatible, testing in progress)
- ⏳ **Pi** (format compatible, testing in progress)
- ⏳ **Other agents** (should work per spec)

### Testing with Different Agents

If you test these skills with other agents, please report:

1. **Agent name and version**
2. **Which skills you tested**
3. **What worked**
4. **What didn't work**
5. **Any modifications needed**

Submit your findings as a GitHub issue or discussion.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed contribution guidelines.

**Quick checklist:**
- [ ] Follow directory structure
- [ ] Add proper frontmatter
- [ ] Keep main SKILL.md <500 lines
- [ ] Use agent-agnostic language
- [ ] Test with multiple agents if possible
- [ ] Include examples
- [ ] Document limitations

---

## Resources

### Official Resources

- **Specification:** https://agentskills.io/specification
- **Examples:** https://github.com/agentskills/agentskills
- **Community:** https://discord.gg/agentskills

### This Repository

- **README:** [README.md](README.md) - Overview and installation
- **Contributing:** [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guide

### Individual Skills

- [api-code-generator](skills/api-code-generator/SKILL.md)
- [code-action](skills/code-action/SKILL.md)
- [debug-workflows](skills/debug-workflows/SKILL.md)

---

## Migration from v1.0.0

If you used v1.0.0 (Claude-specific format):

### What Changed

- ✅ Added proper frontmatter to all skills
- ✅ Split large files into main + references
- ✅ Made language agent-agnostic
- ✅ Follows agentskills specification
- ✅ Cross-agent compatible

### Migration Guide

**For skill users:**
- Skills work the same way, just load with your agent
- New agent-agnostic language is more portable
- Reference files loaded on-demand

**For skill developers:**
- Update frontmatter format (add `name` field)
- Split large SKILL.md files
- Use generic language instead of tool names

---

## Questions?

- **Format questions:** https://agentskills.io
- **Repository issues:** https://github.com/RavennaHQ/ravenna-skills/issues
- **General discussion:** https://github.com/RavennaHQ/ravenna-skills/discussions

---

**Made with ❤️ using the agentskills format**
