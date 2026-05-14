# Common Patterns Reference

This document provides detailed examples and patterns for API code generation.

## Table of Contents

- [Authentication Patterns](#authentication-patterns)
- [Error Handling Patterns](#error-handling-patterns)
- [Axios with Retry Pattern](#axios-with-retry-pattern)
- [Pagination Patterns](#pagination-patterns)
- [Schema Patterns](#schema-patterns)

---

## Authentication Patterns

### Bearer Token

```typescript
headers: {
  'Authorization': `Bearer ${token}`,
  'Content-Type': 'application/json'
}
```

### API Key (Header)

```typescript
headers: {
  'X-API-Key': apiKey,
  'Content-Type': 'application/json'
}
```

### API Key (Query)

```typescript
const url = `https://api.example.com/endpoint?api_key=${apiKey}&param=${value}`;
```

### Basic Auth

```typescript
const credentials = btoa(`${username}:${password}`);
headers: {
  'Authorization': `Basic ${credentials}`
}
```

---

## Error Handling Patterns

### Comprehensive Status Code Handling

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

### Rate Limiting with Exponential Backoff

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

---

## Axios with Retry Pattern

### When to Use Axios

- API requires automatic retry logic
- Need request/response interceptors
- Complex timeout requirements
- Documented reliability issues

### Basic Setup

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

### Advanced Configuration

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

---

## Pagination Patterns

### When to Implement Pagination

- API documentation mentions pages, cursors, or `next` links
- Response includes metadata like `has_more`, `next_cursor`, or `Link` headers
- Endpoint returns list/collection resources

### Cursor-Based Pagination

```typescript
export async function run(apiKey: string, maxPages?: number): Promise<Record<string, unknown>> {
  const maxPagesValue = maxPages || 10;

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

### Offset/Limit Pagination

```typescript
export async function run(apiKey: string): Promise<Record<string, unknown>> {
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

### Link Header Pagination (GitHub-style)

```typescript
export async function run(token: string): Promise<Record<string, unknown>> {
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

### Page Number Pagination

```typescript
export async function run(apiKey: string): Promise<Record<string, unknown>> {
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

---

## Schema Patterns

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

### Array of Objects Pattern

```typescript
export const outputSchema = [
  {
    name: 'repositories',
    type: 'array',
    description: 'List of repositories',
    optional: false,
    nested: [
      {
        name: 'item',
        type: 'object',
        description: 'Repository details',
        optional: false,
        nested: [
          { name: 'name', type: 'string', description: 'Repository name', optional: false, nested: [] },
          { name: 'stars', type: 'number', description: 'Star count', optional: false, nested: [] },
          { name: 'language', type: 'string', description: 'Primary language', optional: true, nested: [] }
        ]
      }
    ]
  }
]
```

### Complex Nested Example

```typescript
export const outputSchema = [
  {
    name: 'customer',
    type: 'object',
    description: 'Customer details',
    optional: false,
    nested: [
      { name: 'id', type: 'string', description: 'Customer ID', optional: false, nested: [] },
      { name: 'email', type: 'string', description: 'Customer email', optional: false, nested: [] },
      {
        name: 'paymentMethods',
        type: 'array',
        description: 'Array of payment methods',
        optional: false,
        nested: [
          {
            name: 'item',
            type: 'object',
            description: 'Payment method',
            optional: false,
            nested: [
              { name: 'id', type: 'string', description: 'Payment method ID', optional: false, nested: [] },
              { name: 'type', type: 'string', description: 'Type (card, bank)', optional: false, nested: [] },
              {
                name: 'card',
                type: 'object',
                description: 'Card details',
                optional: true,
                nested: [
                  { name: 'brand', type: 'string', description: 'Card brand', optional: false, nested: [] },
                  { name: 'last4', type: 'string', description: 'Last 4 digits', optional: false, nested: [] },
                  { name: 'expMonth', type: 'number', description: 'Expiration month', optional: false, nested: [] },
                  { name: 'expYear', type: 'number', description: 'Expiration year', optional: false, nested: [] }
                ]
              }
            ]
          }
        ]
      }
    ]
  }
]
```

---

## Additional Examples

### Example: Paginated API with Retry Logic

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
  { name: 'token', type: 'secret', description: 'GitHub personal access token', optional: false, nested: [] },
  { name: 'org', type: 'string', description: 'Organization name', optional: false, nested: [] },
  { name: 'maxPages', type: 'number', description: 'Maximum number of pages to fetch (default: 10)', optional: true, nested: [] }
];

export const outputSchema = [
  {
    name: 'repositories',
    type: 'array',
    description: 'Array of repository objects',
    optional: false,
    nested: [
      { name: 'name', type: 'string', description: 'Repository name', optional: false, nested: [] },
      { name: 'fullName', type: 'string', description: 'Full repository name (org/repo)', optional: false, nested: [] },
      { name: 'description', type: 'string', description: 'Repository description', optional: true, nested: [] },
      { name: 'url', type: 'string', description: 'Repository URL', optional: false, nested: [] },
      { name: 'stars', type: 'number', description: 'Star count', optional: false, nested: [] },
      { name: 'language', type: 'string', description: 'Primary programming language', optional: true, nested: [] }
    ]
  },
  { name: 'total', type: 'number', description: 'Total number of repositories fetched', optional: false, nested: [] },
  { name: 'pages', type: 'number', description: 'Number of pages fetched', optional: false, nested: [] }
];
```
