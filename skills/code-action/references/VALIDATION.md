# Validation Rules Reference

This document provides comprehensive validation rules for code actions.

## Table of Contents

- [Code Structure Requirements](#code-structure-requirements)
- [Schema Entry Requirements](#schema-entry-requirements)
- [Name Format Rules](#name-format-rules)
- [Description Requirements](#description-requirements)
- [Nested Schema Rules](#nested-schema-rules)

---

## Code Structure Requirements

### Must Have

- Exactly 3 exports: `run`, `inputSchema`, `outputSchema`
- No additional exports allowed
- No default exports

### run() Function Requirements

```typescript
✓ Must be declared as async
✓ Must accept positional arguments (not an object parameter)
✓ Argument order must match inputSchema array order exactly
✓ Must return Promise<Record<string, unknown>>
✓ Optional parameters use TypeScript ?: syntax
✓ Function body must contain actual logic (not just a stub)
```

**Valid Example:**
```typescript
export async function run(apiKey: string, userId: number, options?: string[]): Promise<Record<string, unknown>> {
  if (!apiKey || !userId) {
    throw new Error('Missing required parameters');
  }
  // ... implementation
  return { success: true, data: result };
}
```

**Invalid Examples:**
```typescript
// ❌ Not async
export function run(apiKey: string): Promise<...> { ... }

// ❌ Object parameter instead of positional
export async function run(input: { apiKey: string, userId: number }): Promise<...> { ... }

// ❌ Wrong return type
export async function run(apiKey: string): Promise<string> { ... }

// ❌ Not using ? for optional parameters
export async function run(apiKey: string, options: string[] | undefined): Promise<...> { ... }
```

### Schema Requirements

```typescript
✓ Must be arrays (not objects)
✓ Cannot be empty (must have at least one entry)
✓ Must be JSON-serializable (no functions, symbols, etc.)
✓ Array order defines positional argument order
```

**Valid Example:**
```typescript
export const inputSchema = [
  { name: 'apiKey', type: 'secret', description: 'API key', optional: false, nested: [] },
  { name: 'userId', type: 'number', description: 'User ID', optional: false, nested: [] }
];
```

**Invalid Examples:**
```typescript
// ❌ Object instead of array
export const inputSchema = {
  apiKey: { type: 'secret', description: '...', optional: false, nested: [] }
};

// ❌ Empty array
export const inputSchema = [];

// ❌ Contains function
export const inputSchema = [
  { name: 'apiKey', type: 'string', validate: (x) => x.length > 0 }
];
```

---

## Schema Entry Requirements

### Required Fields

Every schema entry must have exactly these 5 fields:

```typescript
{
  name: string,        // Property name
  type: string,        // Type from valid list
  description: string, // Clear description
  optional: boolean,   // Required or optional
  nested: array        // Nested schema (empty for primitives)
}
```

**All 5 fields are required for every entry.**

### Field Validation Rules

#### name Field

- **Type:** string
- **Format:** camelCase (e.g., `userId`, `apiKey`, `maxResults`)
- **Must not** contain spaces or special characters (except underscore)
- **Length:** 1-50 characters
- **Must be unique** within the same schema

**Valid Examples:**
```
userId
apiKey
maxResults
isActive
createdAt
```

**Invalid Examples:**
```
user-id        // Use hyphens for action names, not schema fields
User ID        // Spaces not allowed
api_key        // Use camelCase (apiKey)
x              // Too short, not descriptive
veryLongAndDescriptiveParameterNameThatExceedsFiftyCharactersLimit  // Too long
```

#### type Field

- **Type:** string
- **Must be one of these valid types (case-sensitive):**

**Primitives:**
- `string` - Text values
- `number` - Integers or floats
- `boolean` - True/false values
- `void` - No return value

**Special:**
- `secret` - Sensitive data (API keys, passwords, tokens)
- `date` - Date-only values (YYYY-MM-DD)
- `datetime` - ISO 8601 timestamps (YYYY-MM-DDTHH:mm:ss.sssZ)

**Complex:**
- `object` - Structured data (requires `nested` array)
- `array` - Lists (requires `nested` array)

**Invalid types:**
```
String         // Must be lowercase: string
Number         // Must be lowercase: number
int            // Use: number
float          // Use: number
str            // Use: string
Date           // Use: date or datetime
Array          // Use: array
Object         // Use: object
any            // Not supported
unknown        // Not supported
```

#### description Field

- **Type:** string
- **Must be non-empty**
- **Length:** 5-200 characters
- **Should be clear and actionable**
- **Should describe the purpose, not just repeat the name**

**Good Examples:**
```
"GitHub personal access token for authentication"
"User ID to fetch profile information"
"Maximum number of results to return (default: 100)"
"Whether to include deleted items in results"
```

**Bad Examples:**
```
"token"                          // Too short, just repeats name
"The token"                      // Not helpful
"t"                              // Way too short
""                               // Empty
"A really really really long description that goes on and on explaining every possible detail about this parameter in excruciating detail that far exceeds the maximum length allowed"  // Too long (>200 chars)
```

#### optional Field

- **Type:** boolean
- **Must be exactly** `true` or `false`
- **Cannot be:** `1`, `0`, `"true"`, `"false"`, `null`, `undefined`

**Meaning:**
- `false` = required parameter/field (must be provided)
- `true` = optional parameter/field (can be omitted)

**Valid Examples:**
```typescript
{ name: 'apiKey', type: 'secret', optional: false, ... }     // Required
{ name: 'maxResults', type: 'number', optional: true, ... }  // Optional
```

**Invalid Examples:**
```typescript
{ name: 'apiKey', type: 'secret', optional: 0, ... }         // Must be boolean
{ name: 'apiKey', type: 'secret', optional: "false", ... }   // Must be boolean
{ name: 'apiKey', type: 'secret', ... }                      // Missing optional field
```

#### nested Field

- **Type:** array
- **For primitives** (`string`, `number`, `boolean`, `secret`, `date`, `datetime`, `void`): **Must be empty** `[]`
- **For `object`:** Array of property schemas (recursive structure)
- **For `array`:** Single-entry array containing the item schema
- **Cannot be:** `null`, `undefined`, missing

**Valid Examples:**

Primitive:
```typescript
{ name: 'apiKey', type: 'string', description: '...', optional: false, nested: [] }
```

Object:
```typescript
{
  name: 'user',
  type: 'object',
  description: 'User details',
  optional: false,
  nested: [
    { name: 'id', type: 'number', description: 'User ID', optional: false, nested: [] },
    { name: 'name', type: 'string', description: 'User name', optional: false, nested: [] }
  ]
}
```

Array:
```typescript
{
  name: 'tags',
  type: 'array',
  description: 'List of tags',
  optional: false,
  nested: [
    { name: 'item', type: 'string', description: 'Tag name', optional: false, nested: [] }
  ]
}
```

**Invalid Examples:**
```typescript
// ❌ Primitive with non-empty nested
{ name: 'apiKey', type: 'string', nested: [{ name: 'foo', ... }] }

// ❌ Object with empty nested
{ name: 'user', type: 'object', nested: [] }

// ❌ Array with multiple entries in nested
{ name: 'tags', type: 'array', nested: [
  { name: 'tag1', type: 'string', ... },
  { name: 'tag2', type: 'string', ... }
]}

// ❌ Missing nested field
{ name: 'apiKey', type: 'string', description: '...', optional: false }

// ❌ null nested
{ name: 'apiKey', type: 'string', nested: null }
```

---

## Name Format Rules

### Action Names

**Valid format:** `/^[a-z0-9]+(-[a-z0-9]+)*$/`

**Requirements:**
- Lowercase letters (a-z) only
- Numbers (0-9) allowed
- Hyphens (-) for word separation
- Length: 3-50 characters
- No leading or trailing hyphens
- No consecutive hyphens
- Must be descriptive and clear
- Must match the directory name (for agentskills format)

**Valid Examples:**
```
fetch-github-user
send-email-sendgrid
stripe-payment-v2
get-weather-forecast
list-org-repos
api-v3
```

**Invalid Examples:**
```
FetchUser              → normalize to: fetchuser (loses meaning, use hyphens)
fetch_user             → normalize to: fetch-user
Fetch-User             → normalize to: fetch-user
fetch user             → normalize to: fetch-user
-fetch-user            → normalize to: fetch-user
fetch-user-            → normalize to: fetch-user
fetch--user            → normalize to: fetch-user
ab                     → reject: too short (min 3 chars)
```

**Normalization Process:**
1. Convert to lowercase
2. Replace spaces and underscores with hyphens
3. Remove any characters not in [a-z0-9-]
4. Remove leading/trailing hyphens
5. Replace consecutive hyphens with single hyphen
6. Ensure length is 3-50 characters
7. If > 50 chars, truncate and remove incomplete words

---

## Description Requirements

### Format

- **Length:** 10-200 characters
- **Complete sentence(s)** with proper punctuation
- **Focus on purpose and capability**
- **Include service/API name**
- **Mention key features if relevant**

### Guidelines

- Use present tense ("Fetch", "Send", "Process")
- Be specific about what it does
- Avoid generic phrases like "This action..." at the start
- No technical jargon unless necessary for clarity

### Good Examples

```
"Send transactional emails via SendGrid API with template support and tracking"
"Fetch GitHub user information including profile data and statistics"
"Process credit card payments through Stripe with automatic receipt generation"
"Retrieve weather forecasts for any location using OpenWeatherMap API"
"List all repositories for a GitHub organization with pagination support"
```

### Bad Examples

```
"Emails"
// Too short, not descriptive

"This action sends emails using an API"
// Generic, starts with "This action"

"Utilizes the SendGrid API to facilitate electronic mail transmission"
// Jargon, overly verbose

"Send emails"
// Too vague, missing context

"A comprehensive solution for email delivery that handles all aspects of transactional and marketing email communications with advanced features including template support, analytics, tracking, and delivery optimization"
// Too long (>200 chars)
```

---

## Nested Schema Rules

### For Object Types

Object types must have a `nested` array containing property definitions.

**Structure:**
```typescript
{
  name: 'objectName',
  type: 'object',
  description: 'Object description',
  optional: false,
  nested: [
    { name: 'property1', type: '...', description: '...', optional: false, nested: [] },
    { name: 'property2', type: '...', description: '...', optional: false, nested: [] },
    // ... more properties
  ]
}
```

**Example:**
```typescript
{
  name: 'user',
  type: 'object',
  description: 'User details',
  optional: false,
  nested: [
    { name: 'id', type: 'number', description: 'User ID', optional: false, nested: [] },
    { name: 'email', type: 'string', description: 'Email address', optional: false, nested: [] },
    { name: 'age', type: 'number', description: 'User age', optional: true, nested: [] }
  ]
}
```

**Common Errors:**
```typescript
// ❌ Empty nested for object
{ name: 'user', type: 'object', nested: [] }

// ❌ Nested as object instead of array
{ name: 'user', type: 'object', nested: { id: {...}, email: {...} } }
```

### For Array Types

Array types must have a `nested` array containing a **single entry** that defines the item schema.

**Structure:**
```typescript
{
  name: 'arrayName',
  type: 'array',
  description: 'Array description',
  optional: false,
  nested: [
    { name: 'item', type: '...', description: '...', optional: false, nested: [] }
  ]
}
```

**Example - Array of Strings:**
```typescript
{
  name: 'tags',
  type: 'array',
  description: 'List of tags',
  optional: false,
  nested: [
    { name: 'item', type: 'string', description: 'Tag name', optional: false, nested: [] }
  ]
}
```

**Example - Array of Objects:**
```typescript
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
        { name: 'stars', type: 'number', description: 'Star count', optional: false, nested: [] }
      ]
    }
  ]
}
```

**Common Errors:**
```typescript
// ❌ Empty nested for array
{ name: 'tags', type: 'array', nested: [] }

// ❌ Multiple entries in nested (should be single entry defining item schema)
{
  name: 'tags',
  type: 'array',
  nested: [
    { name: 'tag1', type: 'string', ... },
    { name: 'tag2', type: 'string', ... }
  ]
}

// ❌ Direct properties instead of item wrapper
{
  name: 'repositories',
  type: 'array',
  nested: [
    { name: 'name', type: 'string', ... },
    { name: 'stars', type: 'number', ... }
  ]
}
```

### Deeply Nested Structures

Nested structures can be recursive - objects can contain objects/arrays, and arrays can contain objects/arrays.

**Example:**
```typescript
{
  name: 'customer',
  type: 'object',
  description: 'Customer details',
  optional: false,
  nested: [
    { name: 'id', type: 'string', description: 'Customer ID', optional: false, nested: [] },
    { name: 'email', type: 'string', description: 'Email', optional: false, nested: [] },
    {
      name: 'addresses',
      type: 'array',
      description: 'Customer addresses',
      optional: false,
      nested: [
        {
          name: 'item',
          type: 'object',
          description: 'Address details',
          optional: false,
          nested: [
            { name: 'street', type: 'string', description: 'Street address', optional: false, nested: [] },
            { name: 'city', type: 'string', description: 'City', optional: false, nested: [] },
            { name: 'zipCode', type: 'string', description: 'ZIP code', optional: false, nested: [] },
            {
              name: 'coordinates',
              type: 'object',
              description: 'GPS coordinates',
              optional: true,
              nested: [
                { name: 'lat', type: 'number', description: 'Latitude', optional: false, nested: [] },
                { name: 'lng', type: 'number', description: 'Longitude', optional: false, nested: [] }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

---

## Validation Checklist

Use this checklist to validate code actions:

### Code Structure
- [ ] File contains exactly 3 exports
- [ ] `export async function run(...)` exists
- [ ] `export const inputSchema = [...]` exists
- [ ] `export const outputSchema = [...]` exists
- [ ] No additional or default exports

### run() Function
- [ ] Declared as `async`
- [ ] Accepts positional arguments (not object)
- [ ] Arguments match inputSchema order
- [ ] Optional parameters use `?:` syntax
- [ ] Returns `Promise<Record<string, unknown>>`
- [ ] Contains actual implementation

### inputSchema
- [ ] Is an array (not object)
- [ ] Has at least one entry
- [ ] All entries have 5 required fields
- [ ] All `name` fields are camelCase strings
- [ ] All `type` fields are valid types
- [ ] All `description` fields are non-empty
- [ ] All `optional` fields are booleans
- [ ] All `nested` fields are arrays
- [ ] Primitives have `nested: []`
- [ ] Objects have populated `nested` array
- [ ] Arrays have single-entry `nested` array

### outputSchema
- [ ] Same validation as inputSchema
- [ ] Matches actual return structure of `run()`
- [ ] All returned properties are documented
- [ ] Optional properties marked correctly

### Action Metadata
- [ ] Name is 3-50 characters
- [ ] Name matches format: `/^[a-z0-9]+(-[a-z0-9]+)*$/`
- [ ] Description is 10-200 characters
- [ ] Description is clear and specific

---

## Auto-Fix Rules

These issues can be automatically fixed:

### Type Casing
```
"String" → "string"
"Number" → "number"
"Boolean" → "boolean"
"Object" → "object"
"Array" → "array"
```

### Missing nested
```
{ name: 'apiKey', type: 'string', optional: false }
→ { name: 'apiKey', type: 'string', optional: false, nested: [] }
```

### Name Normalization
```
"Fetch User" → "fetch-user"
"fetch_user" → "fetch-user"
"fetch--user" → "fetch-user"
"-fetch-user-" → "fetch-user"
```

### Whitespace
```
" apiKey " → "apiKey"
"  description  " → "description"
```

These fixes are applied automatically and logged for transparency.
