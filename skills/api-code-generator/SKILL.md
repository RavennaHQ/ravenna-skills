---
description: Generate production-ready TypeScript API integration code from any REST API documentation. Analyzes API docs and creates complete TypeScript files with proper error handling, pagination support, retry logic, and type-safe schemas.
---

# API Code Generator Skill

Generate fully functional, self-contained TypeScript code that integrates with any REST API by reading its documentation.

## Usage

This skill generates TypeScript code that follows a strict, standardized structure. Provide:
1. **API Documentation URL** - Link to the API documentation
2. **User Request** - What you want the code to accomplish

The skill will:
1. Fetch and analyze the API documentation
2. Generate complete TypeScript code with proper error handling
3. Return code that's ready to save and run with `bun run <file>.ts`

## Input Format

```
Generate API integration code for:
- API Docs: <documentation-url>
- Request: <what-you-want-to-accomplish>
```

## Output Format

The skill generates a complete TypeScript file with exactly three exports:

```typescript
export async function run(input: Record<string, unknown>): Promise<Record<string, unknown>>
export const inputSchema = { /* schema */ }
export const outputSchema = { /* schema */ }
```

---

## Instructions for Claude

When this skill is invoked, you are an expert TypeScript code generator. Follow these instructions precisely:

### Step 1: Fetch API Documentation

Use WebFetch to retrieve the API documentation from the provided URL. Extract:
- Base URLs and endpoints
- Authentication methods
- Request/response formats
- Required vs optional parameters
- Error responses

### Step 2: Generate TypeScript Code

Create a **single, complete TypeScript file** with exactly three exports. Follow this structure:

#### 1. The `run` Function

```typescript
export async function run(apiKey: string, param1: string, param2?: number): Promise<Record<string, unknown>> {
  // Parameters are passed as positional arguments
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

  // Parse response
  const data = await response.json();

  // Return clean, useful results (not entire response)
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
- Use native `fetch` for simple APIs OR `axios` + `axios-retry` for complex scenarios (see patterns below)
- Handle errors gracefully with clear messages
- Handle pagination if the API returns paginated results
- Return clean, transformed data (not raw API responses)

#### 2. The `inputSchema` Schema

```typescript
export const inputSchema = [
  {
    name: 'propertyName',
    type: 'string' | 'number' | 'boolean' | 'object' | 'array' | 'void' | 'secret' | 'date' | 'datetime',
    description: 'What this property is for',
    optional: false, // false means required, true means optional
    nested: [] // for object/array types: array of field schemas (recursive structure)
  }
]
```

**Requirements:**
- Define all input parameters the function needs as an **array**
- Array order determines positional argument order in the `run` function
- Use clear, descriptive names
- Include helpful descriptions
- Set `optional: false` for required fields, `optional: true` for optional fields
- For `object` types, use `nested` array to define nested properties (recursive structure)
- For `array` types, use `nested` to define the item structure (array of field schemas)
- Use `secret` type for sensitive data like API keys and tokens

#### 3. The `outputSchema` Schema

```typescript
export const outputSchema = [
  {
    name: 'propertyName',
    type: 'string' | 'number' | 'boolean' | 'object' | 'array' | 'void' | 'secret' | 'date' | 'datetime',
    description: 'What this property represents',
    optional: false, // false means always present, true means conditional
    nested: [] // for object/array types: array of field schemas (recursive structure)
  }
]
```

**Requirements:**
- Define all output properties the function returns as an **array**
- Match the structure of what `run()` actually returns
- Include descriptions for each property
- Set `optional: false` for properties always present, `optional: true` for conditional properties
- For `object` types, use `nested` array to define nested properties (recursive structure)
- For `array` types, use `nested` to define the item structure (array of field schemas)

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

**HTTP Client Choice:**
```typescript
// ✅ Good - Native fetch (simple APIs, no dependencies)
const response = await fetch(url);

// ✅ Good - Axios with retry (complex APIs, automatic retries)
import axios from 'axios';
import axiosRetry from 'axios-retry';
const client = axios.create();
axiosRetry(client, { retries: 3 });
const response = await client.get(url);

// When to use each:
// - Native fetch: Simple GET/POST, no retry logic needed
// - Axios + retry: Need automatic retries, timeouts, interceptors
```

### Step 4: Validation Checklist

Before returning the code, verify:

- [ ] Has all three exports: `run`, `inputSchema`, `outputSchema`
- [ ] Input schema matches what `run()` expects
- [ ] Output schema matches what `run()` returns
- [ ] Required parameters are validated
- [ ] Errors include context (status codes, messages)
- [ ] Uses native `fetch` OR axios with axios-retry (with clear reasoning)
- [ ] If using axios, includes proper retry configuration
- [ ] Handles pagination if API returns paginated results
- [ ] Returns clean, transformed data
- [ ] Includes helpful comments for complex logic
- [ ] Property descriptions are clear and accurate
- [ ] If using axios/axios-retry, includes installation instructions in comments

### Step 5: Output Format

Return ONLY the TypeScript code. Do not include:
- Markdown code blocks (no ``` backticks)
- Explanations before or after the code
- Installation instructions
- Usage examples (these go in comments if needed)

The output should be **immediately executable** when saved to a `.ts` file.

---

## Example Invocations

### Example 1: GitHub API

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
  {
    name: 'token',
    type: 'secret',
    description: 'GitHub personal access token',
    optional: false,
    nested: []
  },
  {
    name: 'owner',
    type: 'string',
    description: 'Repository owner username',
    optional: false,
    nested: []
  },
  {
    name: 'repo',
    type: 'string',
    description: 'Repository name',
    optional: false,
    nested: []
  },
  {
    name: 'title',
    type: 'string',
    description: 'Issue title',
    optional: false,
    nested: []
  },
  {
    name: 'body',
    type: 'string',
    description: 'Issue description/body',
    optional: true,
    nested: []
  },
  {
    name: 'labels',
    type: 'array',
    description: 'Issue labels',
    optional: true,
    nested: [
      {
        name: 'item',
        type: 'string',
        description: 'Label name',
        optional: false,
        nested: []
      }
    ]
  }
];

export const outputSchema = [
  {
    name: 'issueNumber',
    type: 'number',
    description: 'The created issue number',
    optional: false,
    nested: []
  },
  {
    name: 'issueUrl',
    type: 'string',
    description: 'URL to view the issue',
    optional: false,
    nested: []
  },
  {
    name: 'createdAt',
    type: 'datetime',
    description: 'ISO timestamp when issue was created',
    optional: false,
    nested: []
  }
];
```

### Example 2: Simple REST API

**Input:**
```
Generate API integration code for:
- API Docs: https://jsonplaceholder.typicode.com/
- Request: Get a user by ID and return their name, email, and username
```

**Output:**
```typescript
export async function run(userId: number): Promise<Record<string, unknown>> {
  if (!userId) {
    throw new Error('userId is required');
  }

  const response = await fetch(`https://jsonplaceholder.typicode.com/users/${userId}`);

  if (!response.ok) {
    throw new Error(`Failed to fetch user: ${response.status} ${response.statusText}`);
  }

  const user = await response.json();

  return {
    id: user.id,
    name: user.name,
    email: user.email,
    username: user.username
  };
}

export const inputSchema = [
  {
    name: 'userId',
    type: 'number',
    description: 'The ID of the user to retrieve',
    optional: false,
    nested: []
  }
];

export const outputSchema = [
  {
    name: 'id',
    type: 'number',
    description: 'User ID',
    optional: false,
    nested: []
  },
  {
    name: 'name',
    type: 'string',
    description: 'Full name',
    optional: false,
    nested: []
  },
  {
    name: 'email',
    type: 'string',
    description: 'Email address',
    optional: false,
    nested: []
  },
  {
    name: 'username',
    type: 'string',
    description: 'Username',
    optional: false,
    nested: []
  }
];
```

### Example 3: Paginated API with Retry Logic

**Input:**
```
Generate API integration code for:
- API Docs: https://docs.github.com/rest/repos/repos#list-organization-repositories
- Request: List all repositories for an organization with pagination and retry logic
```

**Output:**
```typescript
// Installation required: npm install axios axios-retry OR bun add axios axios-retry
import axios from 'axios';
import axiosRetry from 'axios-retry';

export async function run(token: string, org: string, maxPages?: number): Promise<Record<string, unknown>> {
  const maxPagesValue = maxPages || 10;

  if (!token || !org) {
    throw new Error('Missing required parameters: token, org');
  }

  // Configure axios with retry logic
  const client = axios.create({
    timeout: 10000,
    headers: {
      'Authorization': `Bearer ${token}`,
      'Accept': 'application/vnd.github+json'
    }
  });

  axiosRetry(client, {
    retries: 3,
    retryDelay: axiosRetry.exponentialDelay,
    retryCondition: (error) => {
      return axiosRetry.isNetworkOrIdempotentRequestError(error)
        || (error.response?.status >= 500 && error.response?.status < 600);
    }
  });

  // Fetch all pages
  const allRepos = [];
  let page = 1;

  while (page <= maxPagesValue) {
    try {
      const response = await client.get(
        `https://api.github.com/orgs/${org}/repos`,
        { params: { page, per_page: 100 } }
      );

      if (response.data.length === 0) {
        break; // No more repos
      }

      allRepos.push(...response.data);
      page++;

      // Check if there's a next page from Link header
      const linkHeader = response.headers.link;
      if (!linkHeader || !linkHeader.includes('rel="next"')) {
        break;
      }
    } catch (error) {
      if (axios.isAxiosError(error)) {
        const status = error.response?.status || 0;
        const message = error.response?.data?.message || error.message;

        if (status === 404) {
          throw new Error(`Organization '${org}' not found`);
        } else if (status === 401) {
          throw new Error('Authentication failed - check your token');
        } else if (status === 403) {
          throw new Error('Access forbidden - insufficient permissions');
        }

        throw new Error(`GitHub API error ${status}: ${message}`);
      }
      throw error;
    }
  }

  return {
    repositories: allRepos.map(repo => ({
      name: repo.name,
      fullName: repo.full_name,
      description: repo.description,
      url: repo.html_url,
      stars: repo.stargazers_count,
      language: repo.language
    })),
    total: allRepos.length,
    pages: page - 1
  };
}

export const inputSchema = [
  {
    name: 'token',
    type: 'secret',
    description: 'GitHub personal access token',
    optional: false,
    nested: []
  },
  {
    name: 'org',
    type: 'string',
    description: 'Organization name',
    optional: false,
    nested: []
  },
  {
    name: 'maxPages',
    type: 'number',
    description: 'Maximum number of pages to fetch (default: 10)',
    optional: true,
    nested: []
  }
];

export const outputSchema = [
  {
    name: 'repositories',
    type: 'array',
    description: 'Array of repository objects',
    optional: false,
    nested: [
      {
        name: 'name',
        type: 'string',
        description: 'Repository name',
        optional: false,
        nested: []
      },
      {
        name: 'fullName',
        type: 'string',
        description: 'Full repository name (org/repo)',
        optional: false,
        nested: []
      },
      {
        name: 'description',
        type: 'string',
        description: 'Repository description',
        optional: true,
        nested: []
      },
      {
        name: 'url',
        type: 'string',
        description: 'Repository URL',
        optional: false,
        nested: []
      },
      {
        name: 'stars',
        type: 'number',
        description: 'Star count',
        optional: false,
        nested: []
      },
      {
        name: 'language',
        type: 'string',
        description: 'Primary programming language',
        optional: true,
        nested: []
      }
    ]
  },
  {
    name: 'total',
    type: 'number',
    description: 'Total number of repositories fetched',
    optional: false,
    nested: []
  },
  {
    name: 'pages',
    type: 'number',
    description: 'Number of pages fetched',
    optional: false,
    nested: []
  }
];
```

---

## Common Patterns

### Authentication Patterns

**Bearer Token:**
```typescript
headers: {
  'Authorization': `Bearer ${token}`,
  'Content-Type': 'application/json'
}
```

**API Key (Header):**
```typescript
headers: {
  'X-API-Key': apiKey,
  'Content-Type': 'application/json'
}
```

**API Key (Query):**
```typescript
const url = `https://api.example.com/endpoint?api_key=${apiKey}&param=${value}`;
```

**Basic Auth:**
```typescript
const credentials = btoa(`${username}:${password}`);
headers: {
  'Authorization': `Basic ${credentials}`
}
```

### Error Handling Patterns

**Comprehensive Status Code Handling:**
```typescript
if (!response.ok) {
  const errorBody = await response.text();

  switch (response.status) {
    // 4xx Client Errors
    case 400:
      throw new Error(`Bad request: ${errorBody}`);
    case 401:
      throw new Error(`Authentication failed - check your API key`);
    case 403:
      throw new Error(`Access forbidden - insufficient permissions`);
    case 404:
      throw new Error(`Resource not found: ${errorBody}`);
    case 405:
      throw new Error(`Method not allowed`);
    case 409:
      throw new Error(`Conflict - resource already exists: ${errorBody}`);
    case 422:
      throw new Error(`Validation error: ${errorBody}`);
    case 429:
      const retryAfter = response.headers.get('Retry-After');
      throw new Error(`Rate limit exceeded. Retry after ${retryAfter} seconds`);

    // 5xx Server Errors (retryable)
    case 500:
      throw new Error(`Server error - try again later: ${errorBody}`);
    case 502:
      throw new Error(`Bad gateway - service temporarily unavailable`);
    case 503:
      throw new Error(`Service unavailable - try again later`);
    case 504:
      throw new Error(`Gateway timeout - request took too long`);

    default:
      throw new Error(`API error ${response.status}: ${errorBody}`);
  }
}
```

**Rate Limiting with Exponential Backoff:**
```typescript
async function fetchWithRetry(url: string, options: RequestInit, maxRetries = 3) {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    const response = await fetch(url, options);

    if (response.ok) {
      return response;
    }

    // Retry on 5xx errors or 429
    if (response.status >= 500 || response.status === 429) {
      const delay = Math.min(1000 * Math.pow(2, attempt), 10000);
      await new Promise(resolve => setTimeout(resolve, delay));
      continue;
    }

    // Don't retry on 4xx errors (except 429)
    throw new Error(`API error ${response.status}: ${await response.text()}`);
  }

  throw new Error(`Max retries exceeded`);
}
```

### Axios with Retry Pattern

**When to Use Axios:**
- API requires automatic retry logic
- Need request/response interceptors
- Complex timeout requirements
- Documented reliability issues

**Basic Setup:**
```typescript
// Installation: npm install axios axios-retry OR bun add axios axios-retry
import axios from 'axios';
import axiosRetry from 'axios-retry';

export async function run(apiKey: string): Promise<Record<string, unknown>> {
  // Configure axios with retry
  const client = axios.create({
    timeout: 10000,
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json'
    }
  });

  // Configure retry behavior
  axiosRetry(client, {
    retries: 3,
    retryDelay: axiosRetry.exponentialDelay,
    retryCondition: (error) => {
      // Retry on network errors or 5xx server errors
      return axiosRetry.isNetworkOrIdempotentRequestError(error)
        || (error.response?.status >= 500 && error.response?.status < 600);
    }
  });

  try {
    const response = await client.get('https://api.example.com/resource');

    return {
      data: response.data,
      status: response.status
    };
  } catch (error) {
    if (axios.isAxiosError(error)) {
      const status = error.response?.status || 0;
      const message = error.response?.data?.message || error.message;
      throw new Error(`API error ${status}: ${message}`);
    }
    throw error;
  }
}
```

**Advanced Configuration:**
```typescript
axiosRetry(client, {
  retries: 5,
  retryDelay: (retryCount) => {
    return retryCount * 1000; // 1s, 2s, 3s, 4s, 5s
  },
  retryCondition: (error) => {
    // Custom retry logic
    if (error.response?.status === 429) return true; // Rate limit
    if (error.response?.status >= 500) return true;  // Server errors
    if (error.code === 'ECONNABORTED') return true;  // Timeout
    return false;
  },
  onRetry: (retryCount, error) => {
    console.log(`Retry attempt ${retryCount} for ${error.config?.url}`);
  }
});
```

### Pagination Patterns

**When to Implement Pagination:**
- API documentation mentions pages, cursors, or `next` links
- Response includes metadata like `has_more`, `next_cursor`, or `Link` headers
- Endpoint returns list/collection resources

**Cursor-Based Pagination:**
```typescript
export async function run(input: Record<string, unknown>): Promise<Record<string, unknown>> {
  const apiKey = input.apiKey as string;
  const maxPages = (input.maxPages as number) || 10; // Optional limit

  if (!apiKey) {
    throw new Error('apiKey is required');
  }

  const allItems = [];
  let cursor = null;
  let pageCount = 0;

  do {
    const url = cursor
      ? `https://api.example.com/items?cursor=${cursor}&limit=100`
      : `https://api.example.com/items?limit=100`;

    const response = await fetch(url, {
      headers: { 'Authorization': `Bearer ${apiKey}` }
    });

    if (!response.ok) {
      throw new Error(`API error ${response.status}: ${await response.text()}`);
    }

    const data = await response.json();
    allItems.push(...data.items);

    cursor = data.next_cursor;
    pageCount++;

  } while (cursor && pageCount < maxPages);

  return {
    items: allItems,
    total: allItems.length,
    pages: pageCount,
    hasMore: cursor !== null
  };
}
```

**Offset/Limit Pagination:**
```typescript
export async function run(input: Record<string, unknown>): Promise<Record<string, unknown>> {
  const apiKey = input.apiKey as string;
  const limit = 100;
  let offset = 0;
  const allItems = [];

  while (true) {
    const response = await fetch(
      `https://api.example.com/items?limit=${limit}&offset=${offset}`,
      { headers: { 'Authorization': `Bearer ${apiKey}` } }
    );

    if (!response.ok) {
      throw new Error(`API error: ${response.status}`);
    }

    const data = await response.json();

    if (data.items.length === 0) {
      break; // No more items
    }

    allItems.push(...data.items);
    offset += limit;

    // Optional: break if we have total count
    if (data.total && allItems.length >= data.total) {
      break;
    }
  }

  return { items: allItems, total: allItems.length };
}
```

**Link Header Pagination (GitHub-style):**
```typescript
export async function run(input: Record<string, unknown>): Promise<Record<string, unknown>> {
  const token = input.token as string;
  let url = 'https://api.github.com/repos/owner/repo/issues';
  const allItems = [];

  while (url) {
    const response = await fetch(url, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Accept': 'application/vnd.github+json'
      }
    });

    if (!response.ok) {
      throw new Error(`GitHub API error: ${response.status}`);
    }

    const items = await response.json();
    allItems.push(...items);

    // Parse Link header for next page
    const linkHeader = response.headers.get('Link');
    url = null;

    if (linkHeader) {
      const nextMatch = linkHeader.match(/<([^>]+)>;\s*rel="next"/);
      if (nextMatch) {
        url = nextMatch[1];
      }
    }
  }

  return { items: allItems, total: allItems.length };
}
```

**Page Number Pagination:**
```typescript
export async function run(input: Record<string, unknown>): Promise<Record<string, unknown>> {
  const apiKey = input.apiKey as string;
  const allItems = [];
  let page = 1;
  let hasMore = true;

  while (hasMore) {
    const response = await fetch(
      `https://api.example.com/items?page=${page}&per_page=100`,
      { headers: { 'Authorization': `Bearer ${apiKey}` } }
    );

    if (!response.ok) {
      throw new Error(`API error: ${response.status}`);
    }

    const data = await response.json();

    if (data.items.length === 0) {
      hasMore = false;
    } else {
      allItems.push(...data.items);
      page++;

      // Check if there's a next page indicator
      hasMore = data.has_next_page || data.items.length === 100;
    }
  }

  return { items: allItems, total: allItems.length, pages: page - 1 };
}
```

### Nested Object Pattern

```typescript
export const outputSchema = [
  {
    name: 'user',
    type: 'object',
    description: 'User information',
    optional: false,
    nested: [
      {
        name: 'name',
        type: 'string',
        description: 'User name',
        optional: false,
        nested: []
      },
      {
        name: 'email',
        type: 'string',
        description: 'User email',
        optional: false,
        nested: []
      }
    ]
  }
]
```

### Array Pattern

```typescript
export const outputSchema = [
  {
    name: 'users',
    type: 'array',
    description: 'List of users',
    optional: false,
    nested: [
      {
        name: 'id',
        type: 'number',
        description: 'User ID',
        optional: false,
        nested: []
      },
      {
        name: 'name',
        type: 'string',
        description: 'User name',
        optional: false,
        nested: []
      }
    ]
  }
]
```

---

## Tools Required

This skill requires:
- **WebFetch** - To retrieve API documentation

---

## Tips for Best Results

1. **Provide direct documentation URLs** - Link to specific endpoint docs, not landing pages
2. **Be specific in requests** - "Create user with name and email" > "user endpoint"
3. **Check for authentication** - Note if API requires keys/tokens
4. **Review generated schemas** - Ensure they match your needs
5. **Test the generated code** - Always test before production use

---

## Limitations

- Works best with REST APIs
- Requires publicly accessible documentation
- May need adjustment for complex OAuth flows
- GraphQL support is limited
- Generated code uses native fetch (no dependencies) OR axios+axios-retry (when retry logic needed)
- When using axios, requires npm/bun installation of dependencies

---

## Related Skills

- `code-review` - Review generated code for quality
- `documentation-generator` - Create docs for the generated functions
