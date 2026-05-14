---
name: code-action
description: Generate TypeScript code from API documentation and automatically deploy it as a code action with full schema support. Provides an end-to-end workflow from API docs to executable code action. Use when you need to create reusable, deployable API integrations.
license: MIT
compatibility: Requires ability to invoke code generation skills and access to a code action deployment platform (e.g., Ravenna MCP). Works with agents that can orchestrate multi-step workflows.
metadata:
  version: "1.1.0"
  author: ravenna-claude
  requires: api-code-generator skill
---

# Code Action Generator Skill

Generate production-ready TypeScript code from REST API documentation and deploy it directly as an executable code action. This skill provides an end-to-end workflow: API docs → TypeScript code → Deployed code action.

## When to Use This Skill

- Creating reusable API integrations
- Deploying code to a code action platform
- Need automated deployment after code generation
- Want validation and error handling built-in

## What You Need

1. **API Documentation URL** - Link to REST API documentation
2. **Description** - What you want the code to accomplish
3. **Optional: Custom Name** - Specific name for your code action
4. **Optional: Review Mode** - Request to review/edit code before deployment

## What You Get

- Complete TypeScript code (via api-code-generator skill)
- Validated code structure and schemas
- Deployed code action ready to use
- Full deployment confirmation with parameter details

---

## Core Workflow

### Step 1: Parse User Request

Extract from the user's request:
- **API Documentation URL** (required)
- **User Description** (required)
- **Custom Name** (optional) - Explicitly specified name
- **Operation Type** (create vs update)
- **Review Mode** (optional) - Keywords: "review", "edit", "show me"

**Detection patterns:**
- **Create**: Default unless update keywords present
- **Update**: Contains "update", "modify", "change", "extend"
- **Review Mode**: Contains "review", "edit", "show me", "let me check"

### Step 2: Invoke Code Generator

Use the api-code-generator skill to generate TypeScript code:

```
Input: API documentation URL + description
Output: Complete TypeScript with run(), inputSchema, outputSchema
```

Capture the generated code for validation and deployment.

### Step 3: Validate Generated Code

**Structure Validation:**
- ✓ Has `export async function run(...)`
- ✓ Has `export const inputSchema = [...]`
- ✓ Has `export const outputSchema = [...]`
- ✓ Function uses positional arguments
- ✓ Returns `Promise<Record<string, unknown>>`

**Schema Validation:**

For each entry in inputSchema and outputSchema:
- ✓ Has `name` field (string, camelCase)
- ✓ Has `type` field (string, number, boolean, object, array, secret, date, datetime, void)
- ✓ Has `description` field (non-empty string)
- ✓ Has `optional` field (boolean)
- ✓ Has `nested` field (array)

**Auto-fix common issues:**
- Convert type casing ("String" → "string")
- Add missing `nested: []` for primitives
- Normalize names (spaces → hyphens, lowercase)

See [references/VALIDATION.md](references/VALIDATION.md) for complete validation rules.

### Step 4: Optional Editor Review

**When requested** (user says "review", "edit", "show me"):

1. Write code to temporary file
2. Open in user's editor ($EDITOR, nano, vim, code)
3. Wait for user to save and close
4. Read edited code back
5. Re-validate edited code
6. Use edited code for deployment

**Benefits:**
- User sees exact code before deployment
- Can add custom validation logic
- Can improve error messages
- Full transparency and control

**Skip if not requested** - most users prefer automatic deployment.

### Step 5: Determine Action Name

**If Custom Name Provided:**
Validate and normalize:
- Convert to lowercase
- Replace spaces/underscores with hyphens
- Remove invalid characters
- Ensure 3-50 characters
- Match format: `/^[a-z0-9]+(-[a-z0-9]+)*$/`

**If Auto-generating:**
1. Extract keywords from description
2. Remove stop words ("the", "a", "an", "and", "or", "using", "with", "for")
3. Keep first 5-7 meaningful words
4. Join with hyphens
5. Truncate to 50 characters if needed

**Examples:**
- "send emails via SendGrid" → "send-emails-sendgrid"
- "fetch GitHub user info" → "fetch-github-user-info"

### Step 6: Generate Description

Create concise description (10-200 characters):

**Template:**
`"{Action verb} {what} via/using {service} {with key features}"`

**Examples:**
- "Send transactional emails via SendGrid API with template support"
- "Fetch GitHub user information including profile data and statistics"
- "Process credit card payments through Stripe with receipt generation"

### Step 7: Deploy Code Action

**For CREATE Operations:**

Call the deployment platform's create action:

```
Parameters:
- name: action name (kebab-case)
- description: concise description
- code: complete TypeScript code
- inputSchema: input parameter definitions
- outputSchema: output structure definitions
```

**Handle responses:**
- **201/200 Success** → Proceed to feedback
- **409 Conflict** → Action exists, ask to update instead
- **422 Validation Error** → Auto-fix and retry once
- **401 Unauthorized** → Guide user to configure credentials
- **429 Rate Limit** → Wait and retry
- **500-504 Server Error** → Retry with backoff (max 3 attempts)

**For UPDATE Operations:**

1. First verify action exists
2. Call update with new code/schemas
3. Handle same error responses as CREATE

See [references/ERROR_HANDLING.md](references/ERROR_HANDLING.md) for detailed error scenarios.

### Step 8: Provide Feedback

**On Success:**

```
✅ {Created|Updated} code action: {action-name}

Description: {description}

Input Parameters:
  - {name} ({type}{, optional}): {description}
  ...

Output:
  - {name} ({type}{, optional}): {description}
  ...

Usage:
  This action is now available and can be invoked with the input parameters listed above.
```

**On Error:**

```
❌ Failed to {create|update} code action: {action-name}

Error: {error-type}
Reason: {error-message}

Suggested Actions:
  - {specific suggestion 1}
  - {specific suggestion 2}
  ...
```

---

## Quick Examples

### Example 1: Create GitHub User Fetcher

**Input:**
```
Create a code action for fetching GitHub user information by username
API Docs: https://docs.github.com/rest/users/users#get-a-user
```

**Process:**
1. Parse: URL extracted, CREATE operation
2. Generate: Code created with GitHub API call
3. Validate: 3 exports ✓, schemas valid ✓
4. Name: Auto-generate → "fetch-github-user"
5. Deploy: Action created successfully
6. Feedback: Display confirmation with parameters

### Example 2: Create with Review Mode

**Input:**
```
Create a code action for sending Slack messages and let me review it
API Docs: https://api.slack.com/methods/chat.postMessage
```

**Process:**
1. Parse: REVIEW MODE detected ✓
2. Generate: Slack code created
3. Validate: Structure valid ✓
4. Open editor: User reviews and edits code
5. Re-validate: Edited code checked
6. Deploy: Deploy with user's customizations
7. Feedback: Confirm with custom changes noted

### Example 3: Update Existing Action

**Input:**
```
Update fetch-github-user to also include the user's company and location
API Docs: https://docs.github.com/rest/users/users#get-a-user
```

**Process:**
1. Parse: UPDATE operation, name="fetch-github-user"
2. Verify: Check action exists
3. Generate: Updated code with new fields
4. Validate: New fields in output schema ✓
5. Deploy: Update action
6. Feedback: Show what changed

See [references/EXAMPLES.md](references/EXAMPLES.md) for more detailed examples including error scenarios.

---

## Name Format Rules

**Valid format:** `/^[a-z0-9]+(-[a-z0-9]+)*$/`

**Requirements:**
- Lowercase letters (a-z) and numbers (0-9)
- Hyphens (-) for word separation
- Length: 3-50 characters
- No leading/trailing hyphens
- No consecutive hyphens

**Valid examples:**
- `fetch-github-user`
- `send-email-sendgrid`
- `stripe-payment-v2`

**Invalid examples:**
- `FetchUser` (uppercase)
- `fetch_user` (underscore)
- `-fetch` (leading hyphen)

---

## Schema Type Reference

**Primitives:**
- `string` - Text values
- `number` - Integers or floats
- `boolean` - True/false
- `void` - No return value

**Special:**
- `secret` - Sensitive data (API keys, passwords, tokens)
- `date` - Date-only values (YYYY-MM-DD)
- `datetime` - ISO 8601 timestamps

**Complex:**
- `object` - Structured data (requires `nested` array)
- `array` - Lists (requires `nested` array for item schema)

---

## Validation Checklist

Before completing, verify:

**Code Generation:**
- [ ] Code generator successfully invoked
- [ ] TypeScript code generated without errors
- [ ] Code contains all three required exports

**Code Validation:**
- [ ] `run()` function exists and is async
- [ ] `inputSchema` is array with entries
- [ ] `outputSchema` is array with entries
- [ ] All schema entries have 5 required fields
- [ ] All types are valid
- [ ] Nested arrays properly structured

**Editor Review (if requested):**
- [ ] Review mode detected from user request
- [ ] Code written to temporary file
- [ ] Editor opened successfully
- [ ] Edited code read back
- [ ] Re-validation performed

**Action Metadata:**
- [ ] Action name valid (3-50 chars, kebab-case)
- [ ] Description clear (10-200 chars)
- [ ] Operation type correct (create/update)

**Deployment:**
- [ ] Correct deployment method called
- [ ] All required parameters provided
- [ ] Call succeeded or error handled gracefully

**User Feedback:**
- [ ] Success/error message displayed
- [ ] Message includes relevant details
- [ ] User knows what happened and next steps

---

## Best Practices

### For Users

1. **Provide direct documentation URLs** - Link to specific endpoint docs
2. **Be specific in requests** - "Create user with name and email" vs "user endpoint"
3. **Use descriptive custom names** - If providing a name, make it clear
4. **Use review mode for important code** - Review production deployments
5. **Test after creation** - Verify action works as expected

### For Implementation

1. **Always validate before deploying** - Catch issues early
2. **Provide clear feedback** - Success and error messages should be actionable
3. **Handle conflicts gracefully** - Never silently overwrite
4. **Retry intelligently** - Exponential backoff for server errors
5. **Maintain code quality** - Generated code should be production-ready
6. **Be security conscious** - Use `secret` type for sensitive data
7. **Document everything** - Clear descriptions for all parameters

---

## Related Skills

- **api-code-generator** (dependency) - Generates the TypeScript code
- **code-review** (future) - Review code quality before deployment

---

## Additional Documentation

- [references/EXAMPLES.md](references/EXAMPLES.md) - Detailed usage examples
- [references/ERROR_HANDLING.md](references/ERROR_HANDLING.md) - Comprehensive error scenarios
- [references/VALIDATION.md](references/VALIDATION.md) - Complete validation rules

---

## Limitations

- Requires access to code action deployment platform
- OAuth 2.0 flows may need manual adjustment
- Very large API docs (>5MB) may timeout
- GraphQL support is limited
- Network connectivity required for deployment

---

## Summary

This skill orchestrates the complete workflow from API documentation to deployed code action:

1. **Generate** code via api-code-generator
2. **Validate** structure and schemas
3. **Optionally review** in editor before deployment
4. **Deploy** to code action platform
5. **Provide feedback** with full details

The result is a production-ready, reusable code action that can be invoked with the defined input parameters.
