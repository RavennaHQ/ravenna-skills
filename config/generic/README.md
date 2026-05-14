# Generic Agent Configuration

Templates and guidelines for integrating these skills with any AI agent.

## Overview

These skills are written in the [agentskills](https://agentskills.io) format, designed to work across different AI agents. This directory provides generic templates for integration.

## Basic Requirements

For an agent to use these skills, it needs:

### 1. **Skill Loading**

Ability to read and parse `SKILL.md` files:
- Parse YAML frontmatter
- Read markdown instructions
- Optionally load `references/` files on demand

### 2. **Core Capabilities**

**For api-code-generator:**
- ✅ Fetch web content (to read API documentation)
- ✅ Generate and write code files
- ✅ No external API required

**For code-action:**
- ✅ Invoke other skills (api-code-generator)
- ✅ Validate generated code
- ⚠️ HTTP API calls (to deploy to Ravenna)
- ⚠️ Optional: Open editor for review

**For debug-workflows:**
- ⚠️ HTTP API calls (to Ravenna MCP)
- ✅ Parse and display JSON responses

## Integration Approaches

### Approach 1: Native Support

Agent natively supports agentskills format:

```
# Agent loads skills from directory
agent load-skills ./skills/

# Agent recognizes skill invocations
/api-code-generator
/code-action
/debug-workflows
```

**Best For:** Agents with built-in agentskills support

### Approach 2: Manual Loading

User provides skill instructions as context:

```
# User copies SKILL.md content into chat
Agent, here are instructions for the api-code-generator skill:
[paste SKILL.md content]

Now use these instructions to generate code for [API].
```

**Best For:** Agents without native skill support

### Approach 3: Extension/Plugin

Custom extension bridges agent and skills:

```javascript
// hypothetical-agent-extension.js
const skills = loadSkills('./skills/');

agent.onCommand('/api-code-generator', (args) => {
  const skill = skills.get('api-code-generator');
  return executeSkill(skill, args);
});
```

**Best For:** Agents with plugin/extension systems

### Approach 4: Hybrid

Mix of manual and automated:

```
# User provides skill name
Use the api-code-generator skill

# Agent fetches SKILL.md
# Agent follows instructions
# Agent generates code
```

**Best For:** Agents with file system access

## Configuration Template

### Environment Variables

```bash
# Required for code-action and debug-workflows skills
export RAVENNA_API_KEY="your-api-key"
export RAVENNA_API_URL="https://core.ravenna.ai/mcp"
```

### Config File Format

Choose based on your agent's preference:

**JSON:**
```json
{
  "skills": {
    "directory": "./skills",
    "enabled": ["api-code-generator", "code-action", "debug-workflows"]
  },
  "integrations": {
    "ravenna": {
      "url": "${RAVENNA_API_URL}",
      "auth": {
        "type": "bearer",
        "token": "${RAVENNA_API_KEY}"
      }
    }
  }
}
```

**YAML:**
```yaml
skills:
  directory: ./skills
  enabled:
    - api-code-generator
    - code-action
    - debug-workflows

integrations:
  ravenna:
    url: ${RAVENNA_API_URL}
    auth:
      type: bearer
      token: ${RAVENNA_API_KEY}
```

**TOML:**
```toml
[skills]
directory = "./skills"
enabled = ["api-code-generator", "code-action", "debug-workflows"]

[integrations.ravenna]
url = "${RAVENNA_API_URL}"

[integrations.ravenna.auth]
type = "bearer"
token = "${RAVENNA_API_KEY}"
```

## Implementation Checklist

Building agent support? Use this checklist:

### Basic Support
- [ ] Read `SKILL.md` files
- [ ] Parse YAML frontmatter
- [ ] Extract skill name and description
- [ ] Read markdown instructions
- [ ] Pass instructions to agent

### Progressive Disclosure
- [ ] Load main SKILL.md first
- [ ] Load `references/` files on demand
- [ ] Track which files are already loaded
- [ ] Avoid loading duplicates

### Skill Invocation
- [ ] Detect skill invocation (e.g., `/skill-name`)
- [ ] Load corresponding skill
- [ ] Execute skill instructions
- [ ] Return results to user

### Advanced Features
- [ ] Skill discovery (list available skills)
- [ ] Skill parameters (pass arguments)
- [ ] Skill dependencies (e.g., code-action needs api-code-generator)

### API Integration (Optional)
- [ ] HTTP client for external APIs
- [ ] Environment variable expansion
- [ ] Authentication (Bearer, API Key, etc.)
- [ ] Error handling and retries

## Testing Your Integration

### Test 1: Load Skills

```
Can you list the available skills in ./skills/?
```

Expected: Agent finds 3 skills (api-code-generator, code-action, debug-workflows)

### Test 2: Simple Generation

```
Use api-code-generator to create code for a simple REST API.
API Docs: https://jsonplaceholder.typicode.com/
Fetch user by ID.
```

Expected: Agent generates TypeScript code with run(), inputSchema, outputSchema

### Test 3: Complex Workflow

```
Use code-action to:
1. Generate code for GitHub API
2. Validate the code structure
3. Deploy it to Ravenna
```

Expected: Agent follows multi-step workflow, or indicates which steps need manual intervention

## Files in This Directory

- `README.md` (this file) - Integration guidelines
- `config-template.json` - Generic JSON config
- `config-template.yaml` - Generic YAML config
- `config-template.toml` - Generic TOML config
- Environment variables: `RAVENNA_API_KEY`, `RAVENNA_API_URL`

## Getting Help

### For Agent Developers

Integrating agentskills support?

- **Spec**: [agentskills.io/specification](https://agentskills.io/specification)
- **Examples**: [github.com/agentskills/agentskills](https://github.com/agentskills/agentskills)
- **Community**: [Discord](https://discord.gg/agentskills)

### For Users

Want to use these skills with your preferred agent?

1. Check if your agent supports agentskills
2. Try manual loading (copy SKILL.md content)
3. Request native support from agent developers
4. Use Claude Code as alternative (guaranteed support)

## Contributing

Integrated these skills with a new agent?

1. Document your approach
2. Add agent-specific config to `config/your-agent/`
3. Submit PR with:
   - Setup instructions
   - Configuration files
   - Known limitations
   - Usage examples

## More Information

- **Skills Documentation**: [../../skills/](../../skills/)
- **Main README**: [../../README.md](../../README.md)
- **agentskills Format**: [../../AGENTSKILLS.md](../../AGENTSKILLS.md)
- **Contributing**: [../../CONTRIBUTING.md](../../CONTRIBUTING.md)
