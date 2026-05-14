# Pi Configuration

Configuration for using these skills with [Pi](https://pi.ai/).

## Status

⚠️ **Experimental** - Pi's support for agentskills format is unknown.

The skills are written in agentskills format which should be compatible with any agent, but Pi-specific integration details are TBD.

## Concept

Skills should work with Pi if it supports loading external skill definitions. Configuration would be agent-specific.

## Skills That Should Work

### ✅ api-code-generator

Pure code generation skill - no external API required.

**Usage in Pi:**
```
Can you use the api-code-generator skill to create TypeScript code for the GitHub users API?

API Docs: https://docs.github.com/rest/users/users#get-a-user
I need a function to fetch user information by username.
```

### ⚠️ code-action

Requires Ravenna API for deployment. May need custom integration.

### ⚠️ debug-workflows

Requires Ravenna MCP connection. May need custom integration.

## Setup (If Supported)

### 1. Environment Variables

Set in your shell:

```bash
export RAVENNA_API_KEY="your-ravenna-api-key"
export RAVENNA_API_URL="https://core.ravenna.ai/mcp"
```

### 2. Load Skills (Hypothetical)

If Pi supports external skills:

```
Pi, please load skills from: /path/to/ravenna-claude/skills
```

Or configure in Pi settings (if available).

### 3. Reference Skills

When using Pi, explicitly mention skill names:

```
Use the api-code-generator skill to...
Use the code-action skill to...
Use the debug-workflows skill to...
```

## Current Workaround

Until Pi natively supports agentskills:

### Option 1: Copy Instructions

Copy skill instructions into Pi chat:

1. Open `skills/api-code-generator/SKILL.md`
2. Copy the content
3. Paste into Pi chat as context
4. Ask Pi to follow the instructions

### Option 2: Use Claude Code

Use Claude Code for full skill support:

```bash
cd /path/to/ravenna-claude
claude --plugin-dir .
```

### Option 3: Manual Process

1. **Use Pi for brainstorming** - Discuss what you want to build
2. **Use Claude Code for generation** - Generate code with skills
3. **Use Pi for refinement** - Review and improve with Pi

## Testing Pi Support

Want to test if Pi supports these skills?

1. Try explicitly referencing a skill:
   ```
   Pi, use the api-code-generator skill from this repository
   to create code for [your API].
   ```

2. Try uploading SKILL.md:
   ```
   Pi, I'm uploading a skill definition. Please follow its instructions
   to generate API code.
   [Upload skills/api-code-generator/SKILL.md]
   ```

3. Report your findings:
   - Open GitHub issue
   - Share what worked/didn't work
   - Help us document Pi compatibility

## Configuration Files

### Environment Variables

Set these for Ravenna API access:

```bash
export RAVENNA_API_KEY="your-key"
export RAVENNA_API_URL="https://core.ravenna.ai/mcp"
```

## Pi-Specific Features (If Any)

If Pi adds agentskills support, document here:

- How to load skills
- Configuration format
- API integration methods
- Limitations and workarounds

## Alternative: Full-Featured Clients

For guaranteed skill support, use:

- **Claude Code** (recommended) - Native agentskills support
- **Claude Desktop** - Full AI features
- **Claude Web** - Browser-based access

## Getting Your API Key

1. Go to [ravenna.ai](https://ravenna.ai)
2. Sign up or log in
3. Navigate to API Keys section
4. Generate a new API key

## Feedback

Tested Pi with these skills? Let us know:

- **Issues**: [GitHub Issues](https://github.com/RavennaHQ/ravenna-skills/issues)
- **What works**: Share successful patterns
- **What doesn't**: Help us improve compatibility
- **Feature requests**: What would make Pi integration better?

## More Information

- **Skills Documentation**: [../../skills/](../../skills/)
- **Main README**: [../../README.md](../../README.md)
- **agentskills Format**: [../../AGENTSKILLS.md](../../AGENTSKILLS.md)
- **Pi Website**: [https://pi.ai](https://pi.ai)
