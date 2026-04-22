# Ravenna Code Action Manager - Claude Plugin

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](./.claude-plugin/plugin.json)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)
[![Claude](https://img.shields.io/badge/Claude-Opus%204.6-purple.svg)](https://claude.ai)

> **Manage executable code actions in Ravenna - create, update, or delete TypeScript code snippets with full schema support**

A Claude plugin that connects to the Ravenna MCP server to manage code actions - reusable TypeScript functions that can be stored, retrieved, and executed on demand.

---

## 🚀 Quick Start

### Prerequisites

1. **Ravenna API key** - Get one from https://ravenna.ai
2. **Claude Code** version 1.0.33 or later

### Installation

**Quick Start:**

```bash
# 1. Set your credentials
export RAVENNA_API_URL="https://core.ravenna.ai/mcp"
export RAVENNA_API_KEY="your-api-key-here"

# 2. Load the plugin
cd /path/to/ravenna-claude
claude --plugin-dir .
```

**Detailed installation instructions:** See [INSTALL.md](./INSTALL.md)

**For local development:**
```bash
export RAVENNA_API_URL="http://localhost:3000/mcp"
export RAVENNA_API_KEY="your-local-api-key"
claude --plugin-dir .
```

**Troubleshooting:** If the plugin doesn't load or doesn't prompt for credentials, see the [troubleshooting section in INSTALL.md](./INSTALL.md#troubleshooting)

### First Use

```
/api-code-generator:generate

Create a code action to send emails via SendGrid API
```

Claude will generate the code, create the action in Ravenna, and confirm creation!

---

## ✨ Features

### 🎯 **Code Action Management**
- **CREATE** - Generate new code actions from natural language
- **UPDATE** - Modify existing actions with requested changes
- **DELETE** - Remove actions no longer needed
- **LIST** - View all available code actions

### 🤖 **Intelligent Code Generation**
- Type-safe TypeScript functions with positional arguments
- Automatic schema generation (input and output)
- Proper error handling and validation
- Support for pagination, authentication, and retries

### 🔌 **MCP Integration**
- Connects to Ravenna via Model Context Protocol
- Automatic tool discovery and invocation
- Persistent storage of code actions
- Cross-session action availability

### 📦 **Schema Management**
- Array-based input/output schemas
- Five required fields per schema entry
- Special types: `secret`, `date`, `datetime`, `void`
- Nested object and array support

### 🛡️ **Production Quality**
- Comprehensive error handling
- Parameter validation
- Clear error messages
- Type safety throughout

### 💡 **TypeScript LSP Support**
- Real-time type checking and diagnostics
- Go to definition and find references
- Type inference for better code generation
- Automatic error detection
- Inlay hints for parameters and return types
- See [LSP-SETUP.md](./LSP-SETUP.md) for installation

---

## 📚 Usage Examples

### Example 1: Create a New Code Action

```
/api-code-generator:generate

Create a code action to fetch GitHub user info by username using the GitHub API
```

**What Happens:**
1. Claude generates TypeScript code for the GitHub API call
2. Defines inputSchema: `username` (string), `token` (secret, optional)
3. Defines outputSchema: `login`, `name`, `bio`, `public_repos`, etc.
4. Calls Ravenna MCP `create_code_action` tool
5. Confirms creation: "✅ Created code action: fetch-github-user"

**Generated Code:**
```typescript
export async function run(username: string, token?: string): Promise<Record<string, unknown>> {
  const headers: Record<string, string> = {
    'Accept': 'application/vnd.github+json'
  };
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const response = await fetch(`https://api.github.com/users/${username}`, { headers });

  if (!response.ok) {
    if (response.status === 404) {
      throw new Error(`User '${username}' not found`);
    }
    throw new Error(`GitHub API error: ${response.status}`);
  }

  const user = await response.json();
  return {
    login: user.login,
    name: user.name,
    bio: user.bio,
    publicRepos: user.public_repos,
    followers: user.followers,
    following: user.following
  };
}

export const inputSchema = [
  { name: 'username', type: 'string', description: 'GitHub username', optional: false, nested: [] },
  { name: 'token', type: 'secret', description: 'GitHub personal access token', optional: true, nested: [] }
];

export const outputSchema = [
  { name: 'login', type: 'string', description: 'GitHub username', optional: false, nested: [] },
  { name: 'name', type: 'string', description: 'Full name', optional: true, nested: [] },
  { name: 'bio', type: 'string', description: 'User biography', optional: true, nested: [] },
  { name: 'publicRepos', type: 'number', description: 'Public repository count', optional: false, nested: [] },
  { name: 'followers', type: 'number', description: 'Follower count', optional: false, nested: [] },
  { name: 'following', type: 'number', description: 'Following count', optional: false, nested: [] }
];
```

### Example 2: Update an Existing Action

```
/api-code-generator:generate

Update the fetch-github-user action to also include the user's avatar URL
```

**What Happens:**
1. Claude calls Ravenna MCP `get_code_action` to retrieve current action
2. Modifies the code to include `avatar_url` in the return
3. Updates outputSchema to add `avatarUrl` field
4. Calls Ravenna MCP `update_code_action` with changes
5. Confirms: "✅ Updated fetch-github-user - now includes avatar URL"

### Example 3: Delete an Action

```
/api-code-generator:generate

Delete the old-weather-api code action
```

**What Happens:**
1. Claude calls Ravenna MCP `delete_code_action`
2. Confirms: "✅ Deleted code action: old-weather-api"

### Example 4: Create Action with Pagination

```
/api-code-generator:generate

Create a code action to list all repositories for a GitHub organization with pagination
```

**Generated Code Includes:**
- Pagination loop with `maxPages` parameter
- Link header parsing
- Accumulation of all results
- Proper error handling for rate limits

---

## 🏗️ Code Action Structure

Every code action has three required exports:

### 1. The `run` Function
```typescript
export async function run(...args: any[]): Promise<Record<string, unknown>> {
  // Positional arguments matching inputSchema order
  // Returns structured data matching outputSchema
}
```

### 2. The `inputSchema`
```typescript
export const inputSchema = [
  {
    name: 'paramName',
    type: 'string',        // or number, boolean, object, array, secret, date, datetime, void
    description: 'Parameter description',
    optional: false,       // false = required, true = optional
    nested: []             // Array of nested schemas for object/array types
  }
];
```

### 3. The `outputSchema`
```typescript
export const outputSchema = [
  {
    name: 'resultField',
    type: 'object',
    description: 'Result description',
    optional: false,
    nested: [/* nested field definitions */]
  }
];
```

---

## 🔧 MCP Server Configuration

The plugin connects to Ravenna's hosted MCP server. Configuration in `.mcp.json`:

```json
{
  "mcpServers": {
    "ravenna": {
      "url": "${user_config.api_url}",
      "type": "http",
      "headers": {
        "Authorization": "Bearer ${user_config.api_key}"
      }
    }
  }
}
```

The URL can be customized via user configuration to support:
- Production: `https://core.ravenna.ai/mcp`
- Staging: `https://staging.ravenna.ai/mcp`
- Local development: `http://localhost:3000/mcp`
- Self-hosted instances: Your custom URL

### Available MCP Tools

The Ravenna MCP server provides:

| Tool | Purpose | Parameters |
|------|---------|------------|
| `create_code_action` | Create new action | name, description, code, inputSchema, outputSchema |
| `get_code_action` | Retrieve action | name |
| `update_code_action` | Modify action | name, description?, code?, inputSchema?, outputSchema? |
| `delete_code_action` | Remove action | name |
| `list_code_actions` | List all actions | (none) |

---

## 🎯 Schema Types

### Basic Types
- `string` - Text values
- `number` - Integers or floats
- `boolean` - True/false values
- `void` - No return value

### Special Types
- `secret` - Sensitive data (API keys, passwords, tokens)
- `date` - Date-only values (YYYY-MM-DD)
- `datetime` - ISO 8601 timestamps (YYYY-MM-DDTHH:mm:ss.sssZ)

### Complex Types
- `object` - Structured data (use `nested` for properties)
- `array` - Lists (use `nested` for item structure)

### Nested Structure Example

```typescript
export const outputSchema = [
  {
    name: 'user',
    type: 'object',
    optional: false,
    nested: [
      { name: 'id', type: 'number', description: 'User ID', optional: false, nested: [] },
      { name: 'email', type: 'string', description: 'Email', optional: false, nested: [] },
      {
        name: 'settings',
        type: 'object',
        description: 'User settings',
        optional: true,
        nested: [
          { name: 'theme', type: 'string', description: 'UI theme', optional: false, nested: [] },
          { name: 'notifications', type: 'boolean', description: 'Enable notifications', optional: false, nested: [] }
        ]
      }
    ]
  }
];
```

---

## 🛠️ Development

### Testing Locally

```bash
# 1. Start Ravenna server (if running locally)
# (see Ravenna documentation)

# 2. Load plugin
claude --plugin-dir ./ravenna-claude

# 3. Configure connection when prompted
# API URL: http://localhost:3000
# API Key: your-ravenna-key

# 4. Test creating an action
/api-code-generator:generate
Create a code action to...
```

### Making Changes

1. Edit `skills/api-code-generator/SKILL.md`
2. Update `.mcp.json` if MCP config changes
3. Run `/reload-plugins` in Claude
4. Test with various operations (create/update/delete)

### Debugging

**Plugin not loading:**
```bash
claude --debug --plugin-dir ./ravenna-claude
```

**MCP connection issues:**
- Verify RAVENNA_API_URL is correct (default: https://core.ravenna.ai/mcp)
- Check API key is valid
- Ensure Ravenna server is accessible
- Test with curl: `curl -H "Authorization: Bearer YOUR_KEY" YOUR_API_URL`
- Check MCP server logs

**Skill not working:**
- Verify SKILL.md syntax
- Check MCP tools are available
- Test MCP tools manually: `/tool-inspector`

---

## 📊 Version History

### v2.0.0 (2026-03-30) - **Current (Major Rewrite)**
- 🔄 **Complete redesign** to work with Ravenna MCP server
- ✅ Create, update, delete code actions via MCP tools
- ✅ User configuration for Ravenna API URL and key
- ✅ MCP server configuration included
- ✅ Comprehensive action management
- ⚠️ **Breaking:** No longer generates standalone API code files

### v1.2.0 (2026-03-30)
- ✅ Positional arguments in `run` function
- ✅ Array-based schemas
- ✅ Changed `required` to `optional`
- ✅ Added types: `void`, `secret`, `date`, `datetime`

### v1.1.0 (2026-03-30)
- ✅ Axios + axios-retry support
- ✅ Pagination patterns
- ✅ Comprehensive error codes

See [CHANGELOG.md](./CHANGELOG.md) for full history.

---

## 📋 Requirements

- **Claude Code:** Version 1.0.33 or later
- **Ravenna API Key:** Get one from https://ravenna.ai
- **Model:** Claude Opus 4.6 or Sonnet 4.6
- **TypeScript LSP (Optional):** For enhanced type checking
  ```bash
  npm install -g typescript-language-server typescript
  ```
  See [LSP-SETUP.md](./LSP-SETUP.md) for details

---

## 🤝 Contributing

Contributions welcome! See [CONTRIBUTING.md](./CONTRIBUTING.md).

**Areas for contribution:**
- Additional code generation patterns
- More comprehensive error handling
- Support for other MCP servers
- Documentation improvements
- Example code actions

---

## 📄 License

MIT License - see [LICENSE](./LICENSE) file.

---

## 🙏 Credits

**Built for Claude by Claude** 🤖

Powered by:
- Claude Opus 4.6
- Ravenna MCP Server
- Model Context Protocol (MCP)
- TypeScript

---

## 📞 Support

- **Documentation:** [skills/api-code-generator/SKILL.md](./skills/api-code-generator/SKILL.md)
- **Issues:** [GitHub Issues](https://github.com/yourusername/ravenna-claude/issues)
- **Ravenna Docs:** [Ravenna API docs](https://docs.ravenna.ai/)

---

## 🌟 Star Us!

If this plugin helps you manage code actions, please star the repository!

---

**Ready to manage your code actions!** 🚀

```bash
claude plugin install api-code-generator@your-marketplace
```

Then:
```
/api-code-generator:generate
Create a code action to...
```
