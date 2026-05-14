---
name: api-code-generator
description: Generate production-ready TypeScript API integration code from REST API documentation. Analyzes API docs and creates complete TypeScript files with proper error handling, pagination support, retry logic, and type-safe schemas. Use when you need to integrate with any REST API.
license: MIT
compatibility: Requires ability to fetch web content and generate code. Works with any agent that can read documentation and write TypeScript.
metadata:
  version: "2.0.0"
  author: ravenna-claude
---

# API Code Generator Skill

Generate fully functional, self-contained TypeScript code that integrates with any REST API by reading its documentation.

## When to Use This Skill

- Integrating with a new REST API
- Creating reusable API client functions
- Need proper error handling and retry logic
- Want type-safe schemas for inputs and outputs

## What You Need

1. **API Documentation URL** - Link to the API documentation
2. **Clear Description** - What you want the code to accomplish

## What You Get

Complete TypeScript code with:
- `export async function run(...)` - Main function with positional arguments
- `export const inputSchema = [...]` - Input parameter definitions
- `export const outputSchema = [...]` - Output structure definitions

The code is ready to save and run with `bun run <file>.ts` or `node <file>.ts`.

---

## Instructions for AI Agents

When this skill is invoked, you are a TypeScript code generator. Follow these steps:

### Step 1: Fetch API Documentation

Retrieve the API documentation from the provided URL. Extract:
- Base URLs and endpoints
- Authentication methods (Bearer, API key, Basic auth, etc.)
- Request/response formats
- Required vs optional parameters
- Error responses and status codes

### Step 2: Generate TypeScript Code

Create a **single, complete TypeScript file** with exactly three exports:

#### 1. The `run` Function

```typescript
export async function run(apiKey: string, param1: string, param2?: number): Promise<Record<string, unknown>> {
  // Parameters are positional arguments with explicit types
  // Optional parameters use TypeScript optional syntax (param?: type)

  // Validate required parameters
  if (!apiKey || !param1) {
    throw new Error('Missing required parameters: apiKey, param1');
  }

  // Make API call using native fetch
  const response = await fetch('https://api.example.com/endpoint', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ param1, param2 })
  });

  // Handle errors with context
  if (!response.ok) {
    const error = await response.text();
    throw new Error(`API error ${response.status}: ${error}`);
  }

  // Parse and return clean results
  const data = await response.json();

  return {
    id: data.id,
    status: data.status,
    createdAt: data.created_at
  };
}
```

**Requirements:**
- Must be `async`
- Takes **positional arguments** with explicit types (not an object)
- Arguments order matches the order in `inputSchema`
- Optional parameters use TypeScript optional syntax (`param?: type`)
- Returns `Promise<Record<string, unknown>>`
- Validate required parameters before using
- Use native `fetch` for simple APIs
- Handle errors gracefully with clear messages
- Handle pagination if the API returns paginated results
- Return clean, transformed data (not raw API responses)

**When to use axios + axios-retry instead of fetch:**
- API requires automatic retry logic
- Need request/response interceptors
- Complex timeout requirements
- Documented reliability issues

#### 2. The `inputSchema` Array

```typescript
export const inputSchema = [
  {
    name: 'propertyName',
    type: 'string' | 'number' | 'boolean' | 'object' | 'array' | 'void' | 'secret' | 'date' | 'datetime',
    description: 'What this property is for',
    optional: false, // false = required, true = optional
    nested: [] // for object/array types: array of field schemas (recursive structure)
  }
]
```

**Requirements:**
- Define all input parameters as an **array**
- Array order determines positional argument order in `run` function
- Use clear, descriptive names (camelCase)
- Include helpful descriptions
- Set `optional: false` for required fields, `optional: true` for optional fields
- For `object` types, use `nested` array to define nested properties
- For `array` types, use `nested` to define the item structure
- Use `secret` type for sensitive data like API keys and tokens

#### 3. The `outputSchema` Array

```typescript
export const outputSchema = [
  {
    name: 'propertyName',
    type: 'string' | 'number' | 'boolean' | 'object' | 'array' | 'void' | 'secret' | 'date' | 'datetime',
    description: 'What this property represents',
    optional: false, // false = always present, true = conditional
    nested: [] // for object/array types: array of field schemas (recursive structure)
  }
]
```

**Requirements:**
- Define all output properties as an **array**
- Match the structure of what `run()` actually returns
- Include descriptions for each property
- Set `optional: false` for properties always present, `optional: true` for conditional properties
- For `object` types, use `nested` array to define nested properties
- For `array` types, use `nested` to define the item structure

### Step 3: Code Quality Standards

**Type Safety:**
```typescript
// ✅ Good
const token = input.token as string;
if (!token) throw new Error('token is required');

// ❌ Bad
const token = input.token; // No type assertion
```

**Error Handling:**
```typescript
// ✅ Good
if (!response.ok) {
  const error = await response.text();
  throw new Error(`GitHub API error: ${response.status} ${error}`);
}

// ❌ Bad
if (!response.ok) throw new Error('Error');
```

**Clean Returns:**
```typescript
// ✅ Good - Return only what's needed
return {
  issueNumber: issue.number,
  issueUrl: issue.html_url,
  createdAt: issue.created_at
};

// ❌ Bad - Return entire response
return issue;
```

### Step 4: Validation Checklist

Before returning the code, verify:

- [ ] Has all three exports: `run`, `inputSchema`, `outputSchema`
- [ ] Input schema matches what `run()` expects
- [ ] Output schema matches what `run()` returns
- [ ] Required parameters are validated
- [ ] Errors include context (status codes, messages)
- [ ] Uses native `fetch` OR axios with axios-retry (with clear reasoning)
- [ ] Handles pagination if API returns paginated results
- [ ] Returns clean, transformed data
- [ ] Includes helpful comments for complex logic
- [ ] Property descriptions are clear and accurate

### Step 5: Output Format

Return ONLY the TypeScript code. Do not include:
- Markdown code blocks (no ``` backticks)
- Explanations before or after the code
- Installation instructions
- Usage examples (these go in comments if needed)

The output should be **immediately executable** when saved to a `.ts` file.

---

## Example: GitHub API Integration

**Input:**
```
Generate API integration code for:
- API Docs: https://docs.github.com/rest/issues/issues#create-an-issue
- Request: Create a GitHub issue with title, body, and optional labels
```

**Output:**
```typescript
export async function run(token: string, owner: string, repo: string, title: string, body?: string, labels?: string[]): Promise<Record<string, unknown>> {
  if (!token || !owner || !repo || !title) {
    throw new Error('Missing required parameters: token, owner, repo, title');
  }

  const response = await fetch(`https://api.github.com/repos/${owner}/${repo}/issues`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Accept': 'application/vnd.github+json',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      title,
      body: body || '',
      labels: labels || []
    })
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`GitHub API error: ${response.status} ${error}`);
  }

  const issue = await response.json();

  return {
    issueNumber: issue.number,
    issueUrl: issue.html_url,
    createdAt: issue.created_at
  };
}

export const inputSchema = [
  { name: 'token', type: 'secret', description: 'GitHub personal access token', optional: false, nested: [] },
  { name: 'owner', type: 'string', description: 'Repository owner username', optional: false, nested: [] },
  { name: 'repo', type: 'string', description: 'Repository name', optional: false, nested: [] },
  { name: 'title', type: 'string', description: 'Issue title', optional: false, nested: [] },
  { name: 'body', type: 'string', description: 'Issue description/body', optional: true, nested: [] },
  {
    name: 'labels',
    type: 'array',
    description: 'Issue labels',
    optional: true,
    nested: [
      { name: 'item', type: 'string', description: 'Label name', optional: false, nested: [] }
    ]
  }
];

export const outputSchema = [
  { name: 'issueNumber', type: 'number', description: 'The created issue number', optional: false, nested: [] },
  { name: 'issueUrl', type: 'string', description: 'URL to view the issue', optional: false, nested: [] },
  { name: 'createdAt', type: 'datetime', description: 'ISO timestamp when issue was created', optional: false, nested: [] }
];
```

---

## Common Patterns

For detailed examples of:
- Authentication patterns (Bearer, API Key, Basic Auth)
- Error handling strategies
- Pagination patterns (cursor, offset, Link header, page number)
- Nested objects and arrays
- Using axios with retry logic

See [references/PATTERNS.md](references/PATTERNS.md)

---

## Limitations

- Works best with REST APIs
- Requires publicly accessible documentation
- May need adjustment for complex OAuth flows
- GraphQL support is limited
- Generated code uses native fetch (no dependencies) OR axios+axios-retry (when retry logic needed)

---

## Tips for Best Results

1. **Provide direct documentation URLs** - Link to specific endpoint docs, not landing pages
2. **Be specific in requests** - "Create user with name and email" > "user endpoint"
3. **Check for authentication** - Note if API requires keys/tokens
4. **Review generated schemas** - Ensure they match your needs
5. **Test the generated code** - Always test before production use
