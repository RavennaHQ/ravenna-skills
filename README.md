# Ravenna Skills

Agent skills for building and managing API integrations on [Ravenna](https://ravenna.ai).

## Installation

```bash
git clone https://github.com/RavennaHQ/ravenna-skills.git
cd ravenna-skills
claude --plugin-dir .
```

Claude will prompt you for your Ravenna API key on first use. Get one at [ravenna.ai](https://ravenna.ai).

For CI/automation, set environment variables instead:

```bash
export RAVENNA_API_KEY="your-key"
export RAVENNA_API_URL="https://core.ravenna.ai/mcp"  # optional
```

## Skills

### api-code-generator

Generate production-ready TypeScript API integration code from REST API documentation. Analyzes docs and produces complete code with error handling, pagination, retry logic, and type-safe schemas.

### code-action

End-to-end workflow: generate TypeScript code from API docs and deploy it as an executable code action on Ravenna. Includes validation and optional review before deployment.

### debug-workflows

Debug and test Ravenna workflows by manually triggering them with custom payloads and analyzing execution results step-by-step.

## Structure

```
skills/
  api-code-generator/   # TypeScript API code generation
  code-action/          # Generate + deploy as code action
  debug-workflows/      # Workflow debugging and testing
.claude-plugin/         # Plugin metadata
.mcp.json               # MCP server configuration
```

## License

MIT
