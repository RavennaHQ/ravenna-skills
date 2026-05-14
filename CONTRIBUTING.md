# Contributing to Agent Skills

Thank you for your interest in contributing! This guide will help you create or improve skills using the agentskills format.

## Table of Contents

- [Getting Started](#getting-started)
- [agentskills Format](#agentskills-format)
- [Creating a New Skill](#creating-a-new-skill)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)

---

## Getting Started

1. **Fork the repository**
2. **Clone your fork:**
   ```bash
   git clone https://github.com/RavennaHQ/ravenna-skills.git
   cd ravenna-claude
   ```
3. **Create a branch:**
   ```bash
   git checkout -b feature/my-new-skill
   ```

---

## agentskills Format

All skills must follow the [agentskills specification](https://agentskills.io/specification).

### Directory Structure

```
skill-name/
├── SKILL.md          # Required: metadata + instructions
├── scripts/          # Optional: executable code
├── references/       # Optional: detailed documentation
└── assets/           # Optional: templates, resources
```

### SKILL.md Format

Every `SKILL.md` must have YAML frontmatter:

```markdown
---
name: skill-name
description: What the skill does and when to use it (1-1024 chars)
license: MIT
compatibility: Optional environment requirements (max 500 chars)
metadata:
  version: "1.0.0"
  author: your-name
---

# Skill Name

Instructions for AI agents...
```

### Required Fields

- **name** (required)
  - 1-64 characters
  - Lowercase letters (a-z), numbers (0-9), hyphens (-)
  - Must match directory name
  - No leading/trailing hyphens
  - No consecutive hyphens
  - Example: `api-code-generator`

- **description** (required)
  - 1-1024 characters
  - Describe what it does AND when to use it
  - Include keywords for discoverability
  - Example: "Generate TypeScript API code from documentation. Use when integrating with REST APIs."

### Optional Fields

- **license** - License name or file reference
- **compatibility** - Environment requirements (max 500 chars)
- **metadata** - Custom key-value pairs
- **allowed-tools** - Pre-approved tools (experimental)

### Body Content

- Keep main SKILL.md under 500 lines
- Move detailed content to `references/`
- Use clear section headings
- Include examples
- Write step-by-step instructions
- Be agent-agnostic (don't assume specific tools)

---

## Creating a New Skill

### Step 1: Create Directory

```bash
mkdir -p skills/my-new-skill
cd skills/my-new-skill
```

### Step 2: Create SKILL.md

```bash
cat > SKILL.md << 'EOF'
---
name: my-new-skill
description: Brief description of what this skill does and when to use it
license: MIT
metadata:
  version: "1.0.0"
  author: your-name
---

# My New Skill

Brief overview of the skill.

## When to Use This Skill

- Use case 1
- Use case 2

## What You Need

1. Input requirement 1
2. Input requirement 2

## Instructions for AI Agents

Step-by-step instructions...

### Step 1: First Step

Details...

### Step 2: Second Step

Details...

## Examples

Example usage...

## Limitations

Known limitations...
EOF
```

### Step 3: Add References (Optional)

For detailed content, create reference files:

```bash
mkdir -p references
cat > references/EXAMPLES.md << 'EOF'
# Detailed Examples

Comprehensive examples...
EOF
```

### Step 4: Add Scripts (Optional)

For executable code:

```bash
mkdir -p scripts
cat > scripts/helper.py << 'EOF'
#!/usr/bin/env python3
# Helper script
EOF
chmod +x scripts/helper.py
```

---

## Testing

### Test with Claude Code

```bash
# Load your skill
claude --plugin-dir ./skills/my-new-skill

# Test in conversation
# Use the skill and verify it works correctly
```

### Test with Other Agents

If possible, test with:
- GitHub Copilot
- Pi
- Other agents supporting agentskills

Document your test results in the pull request.

### Manual Testing Checklist

- [ ] Skill loads without errors
- [ ] Instructions are clear and complete
- [ ] Examples work as expected
- [ ] Edge cases are handled
- [ ] Error messages are helpful
- [ ] References are accessible
- [ ] Scripts execute correctly (if any)

---

## Skill Quality Guidelines

### Keep It Concise

- Main SKILL.md should be <500 lines
- Move detailed content to `references/`
- Use progressive disclosure

### Be Agent-Agnostic

- Don't assume specific tool names (e.g., "WebFetch")
- Describe capabilities generically (e.g., "fetch web content")
- Agent-specific details go in `compatibility` field

**Bad:**
```markdown
Use the WebFetch tool to retrieve the API documentation.
```

**Good:**
```markdown
Retrieve the API documentation from the provided URL. Extract:
- Base URLs and endpoints
- Authentication methods
- Request/response formats
```

### Write Clear Instructions

- Use step-by-step format
- Number steps clearly
- Include examples for each major feature
- Explain WHY, not just WHAT

### Include Examples

Every skill should have:
- Basic usage example
- Advanced usage example (if applicable)
- Error handling example

### Document Limitations

Be honest about:
- What the skill can't do
- Known issues
- Platform requirements
- Dependencies

---

## Code Style

### Markdown

- Use ATX-style headers (`#`, `##`, etc.)
- Use fenced code blocks with language tags
- Use lists for multiple items
- Keep lines ≤120 characters when possible

### YAML Frontmatter

- Use double quotes for string values with special characters
- Indent with 2 spaces
- Keep metadata organized

**Example:**
```yaml
---
name: my-skill
description: "Clear description with: special characters"
license: MIT
compatibility: Requires Node.js 18+
metadata:
  version: "1.0.0"
  author: jane-doe
  tags:
    - api
    - typescript
---
```

---

## Submitting Changes

### Before Submitting

1. **Test thoroughly:**
   - Test all examples
   - Test edge cases
   - Test error handling

2. **Update documentation:**
   - Update README.md if adding new skill
   - Update CHANGELOG.md with your changes
   - Add examples to your SKILL.md

3. **Check formatting:**
   - Ensure markdown is properly formatted
   - Check for typos

### Commit Messages

Use clear, descriptive commit messages:

```
feat(api-code-generator): add support for OAuth 2.0

- Add OAuth flow detection
- Generate token refresh logic
- Update examples with OAuth
- Update PATTERNS.md reference

Fixes #123
```

**Format:**
- `feat(skill-name): description` - New feature
- `fix(skill-name): description` - Bug fix
- `docs(skill-name): description` - Documentation only
- `refactor(skill-name): description` - Code refactoring
- `test(skill-name): description` - Adding tests
- `chore: description` - Maintenance tasks

### Pull Request

1. **Push your branch:**
   ```bash
   git push origin feature/my-new-skill
   ```

2. **Create pull request** on GitHub

3. **PR Description should include:**
   - What changed and why
   - Testing performed
   - Screenshots/examples (if applicable)
   - Related issues (if any)

**Example PR description:**
```markdown
## Description
Adds a new skill for generating GraphQL API code.

## Changes
- Created new `graphql-code-generator` skill
- Added support for queries, mutations, and subscriptions
- Includes 5 comprehensive examples
- Full validation passing

## Testing
- ✓ Tested with Claude Code
- ✓ Tested with GitHub Copilot
- ✓ All examples work correctly

## Related Issues
Closes #45
```

### Review Process

1. Maintainers will review your PR
2. Address any feedback or requested changes
3. Once approved, maintainers will merge

---

## Questions?

- **agentskills Format:** https://agentskills.io/specification
- **Issues:** https://github.com/RavennaHQ/ravenna-skills/issues
- **Discussions:** https://github.com/RavennaHQ/ravenna-skills/discussions

---

Thank you for contributing! 🙏
