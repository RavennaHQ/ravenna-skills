# Error Handling Reference

This document provides comprehensive error handling strategies for code action generation.

## Table of Contents

- [Code Generation Errors](#code-generation-errors)
- [Deployment Errors](#deployment-errors)
- [Validation Errors](#validation-errors)
- [Recovery Strategies](#recovery-strategies)

---

## Code Generation Errors

### API Documentation Unreachable

**Error Type:** Fetch Failed
**Cause:** URL returns 404, 403, timeout, or network error
**Detection:** Code generator returns error with fetch details

**Action:**
1. Report error to user with specific HTTP status
2. Suggest verifying URL is correct
3. Check if docs require authentication
4. Recommend alternative documentation sources
5. Do not proceed to validation

**Error Message Template:**
```
❌ Failed to generate code

Error: Unable to fetch API documentation
Reason: The URL {url} is not accessible ({status}: {statusText})

Suggested Actions:
  - Verify the API documentation URL is correct
  - Check if the documentation requires authentication
  - Try an alternative documentation source
  - Ensure the URL is publicly accessible

Example: For GitHub API, use: https://docs.github.com/rest
```

### Invalid API Documentation

**Error Type:** Parsing Failed
**Cause:** Documentation format unrecognized or insufficient detail
**Detection:** Code generator unable to extract endpoint information

**Action:**
1. Ask user to clarify the specific API endpoint
2. Request additional details (HTTP method, parameters, response format)
3. Suggest providing a cURL example
4. Consider asking for specific sections of the documentation

**Error Message Template:**
```
❌ Failed to parse API documentation

Error: Unable to extract endpoint information
Reason: The documentation format at {url} could not be parsed

Suggested Actions:
  - Provide a direct link to a specific endpoint's documentation
  - Share a cURL example of the API call you want to make
  - Specify the HTTP method, endpoint path, and required parameters
  - Try a different documentation page that focuses on a single endpoint
```

### Code Generation Timeout

**Error Type:** Timeout
**Cause:** Fetch or generation takes longer than expected (>60s)
**Detection:** Code generator timeout or hangs

**Action:**
1. Retry once
2. If fails again, ask user to simplify request
3. Consider splitting into multiple smaller actions

**Error Message Template:**
```
❌ Code generation timed out

Error: Generation exceeded time limit
Reason: The API documentation may be too large or complex to process

Suggested Actions:
  - Try again (temporary network or server issue)
  - Simplify your request to a specific endpoint or subset of functionality
  - Split complex integrations into multiple smaller code actions
  - Provide a more focused documentation URL for a single endpoint
```

---

## Deployment Errors

### 401 Unauthorized

**Error Type:** Authentication Failed
**Cause:** Invalid or missing deployment platform credentials
**Detection:** Deployment call returns 401 status

**Action:**
1. Check if credentials are configured
2. Guide user to configure credentials
3. Provide link to get credentials
4. Do not retry (won't succeed without valid credentials)

**Error Message Template:**
```
❌ Failed to {create|update} code action

Error: Authentication failed
Reason: Invalid or missing deployment platform credentials

Suggested Actions:
  1. Set your credentials as environment variables
  2. Or configure them in your settings/config
  3. Get your credentials from the platform documentation
  4. Verify your credentials are valid and not expired

Once configured, try your request again.
```

### 404 Not Found (Update Operation)

**Error Type:** Action Not Found
**Cause:** Attempting to update a code action that doesn't exist
**Detection:** Get action returns 404

**Action:**
1. Confirm action name with user
2. Offer to list existing actions
3. Ask if user wants to create instead
4. If yes: switch to CREATE flow

**Error Message Template:**
```
⚠️  Action '{name}' doesn't exist.

The code action you're trying to update was not found.

Would you like to:
  1. Create it as a new action instead? (y/n)
  2. View all existing actions to find the correct name
  3. Check the spelling of the action name

Respond with 'y' to create, or provide the correct action name.
```

### 409 Conflict (Create Operation)

**Error Type:** Action Already Exists
**Cause:** Attempting to create a code action with a name that's already taken
**Detection:** Create action returns 409

**Action:**
1. Inform user that action exists
2. Ask if they want to update the existing action instead
3. If yes: switch to UPDATE flow
4. If no: ask for a different name

**Error Message Template:**
```
⚠️  Action '{name}' already exists.

A code action with this name is already deployed.

Would you like to:
  1. Update the existing action with new code? (y/n)
  2. Choose a different name for your new action
  3. View the existing action's details first

Respond with:
  - 'y' to update the existing action
  - 'n' to provide a different name
  - 'view' to see the existing action details
```

### 422 Validation Error

**Error Type:** Schema Validation Failed
**Cause:** Schema format doesn't match platform's requirements
**Detection:** Create/update action returns 422

**Action:**
1. Parse error response for specific field/issue
2. Identify problematic field
3. Attempt automatic fix:
   - Add missing required fields
   - Fix invalid type values (e.g., "String" → "string")
   - Correct nested structure
4. Retry with corrected schema (once)
5. If still fails: report detailed error to user

**Error Message Template:**
```
⚠️  Schema validation failed - attempting to fix...

Error: {specific validation error from platform}

Automatic fixes applied:
  - {fix 1, e.g., "Changed type 'String' to 'string' in field 'username'"}
  - {fix 2, e.g., "Added missing 'nested' field to 'apiKey'"}

Retrying with corrected schema...

{If retry succeeds: show success message}
{If retry fails: show detailed error and ask user for help}
```

### 429 Rate Limit

**Error Type:** Rate Limit Exceeded
**Cause:** Too many requests to deployment platform in short time
**Detection:** Create/update action returns 429

**Action:**
1. Extract `Retry-After` header value (seconds)
2. Inform user of wait time
3. Wait specified duration
4. Retry request automatically
5. If rate limited again: report to user, suggest trying later

**Error Message Template:**
```
⏳ Rate limit exceeded

Reason: Too many requests in a short period

Action: Waiting {N} seconds before retrying...

{After waiting, automatically retry}

{If retry succeeds: show success message}
{If rate limited again: "Please wait a few minutes before trying again"}
```

### 500-504 Server Errors

**Error Type:** Server Error
**Cause:** Deployment platform server experiencing issues
**Detection:** Create/update action returns 5xx status

**Action:**
1. Retry with exponential backoff:
   - Attempt 1: Immediate retry
   - Attempt 2: Wait 2 seconds, retry
   - Attempt 3: Wait 4 seconds, retry
2. If all fail: report error to user
3. Suggest trying again later
4. Provide status page link if available

**Error Message Template:**
```
🔄 Server error - Retrying...

Error: {status} {statusText}

Attempt 1/3: Retrying immediately...
{If fails} Attempt 2/3: Retrying in 2 seconds...
{If fails} Attempt 3/3: Retrying in 4 seconds...

{If all attempts fail:}
❌ Failed to {create|update} code action after 3 attempts

Error: Deployment platform is experiencing issues
Reason: Received {status} error from server

Suggested Actions:
  - Try again in a few minutes
  - Check platform status page (if available)
  - Verify your network connection
  - Contact platform support if issue persists

Your code has been generated and validated - you can retry deployment without regenerating.
```

### Network Errors

**Error Type:** Connection Failed
**Cause:** Network connectivity issue, DNS failure, timeout
**Detection:** Deployment call throws network exception

**Action:**
1. Verify platform URL configuration
2. Check network connectivity
3. Retry with backoff (max 3 attempts)
4. If fails: suggest checking configuration

**Error Message Template:**
```
❌ Network error - Unable to connect to deployment platform

Error: {error message, e.g., "ECONNREFUSED", "ETIMEDOUT"}

Suggested Actions:
  1. Verify your network connection is active
  2. Check platform configuration:
     - URL should be correct
     - Authorization should be configured
  3. Verify platform service is accessible (try in browser)
  4. Check for firewall or proxy issues
  5. Try again in a few moments
```

---

## Validation Errors

### Missing Exports

**Error Type:** Incomplete Code Structure
**Cause:** Generated code missing run, inputSchema, or outputSchema
**Detection:** Code validation finds < 3 exports

**Action:**
1. Identify which export(s) are missing
2. Attempt to regenerate code via api-code-generator
3. If regeneration fails: report to user with details
4. Suggest manual intervention or simplified request

**Error Message Template:**
```
❌ Code validation failed - Missing exports

Error: Generated code is missing required exports
Missing: {list of missing exports, e.g., "outputSchema"}

Expected:
  - export async function run(...)
  - export const inputSchema = [...]
  - export const outputSchema = [...]

Found:
  {list of exports that were found}

Suggested Actions:
  - Retrying code generation with more specific request...
  {If retry fails:}
  - Simplify your request to a single, specific API endpoint
  - Provide more detailed API documentation
  - Try a different documentation URL
```

### Schema Format Invalid

**Error Type:** Schema Validation Failed
**Cause:** Schema not an array, or entries missing required fields
**Detection:** Validation step checks schema structure

**Action:**
1. Identify specific validation failure
2. Attempt automatic fix:
   - Convert object to array if needed
   - Add missing fields with reasonable defaults
   - Fix type casing
3. If auto-fix succeeds: proceed with warning
4. If fails: report details to user

**Error Message Template:**
```
⚠️  Schema format issue detected - Attempting to fix...

Error: {specific issue, e.g., "inputSchema is not an array"}

Automatic fixes:
  - {fix applied, e.g., "Converted inputSchema object to array"}
  - {another fix, e.g., "Added missing 'nested' field to all entries"}

{If successful:}
✓ Schema corrected, proceeding with deployment...

{If unsuccessful:}
❌ Unable to automatically fix schema format

Details:
  {detailed explanation of what's wrong}

Suggested Actions:
  - Regenerate code with simpler request
  - Check API documentation format
  - Report issue if this persists
```

### Type Mismatch

**Error Type:** Schema Type Mismatch
**Cause:** run() parameter types don't match inputSchema
**Detection:** Comparison of function signature to schema

**Action:**
1. Compare run() signature to inputSchema
2. Identify mismatched types
3. Attempt to regenerate with correct types
4. Report discrepancies to user if can't fix

**Error Message Template:**
```
⚠️  Type mismatch between function and schema

Error: Parameter types in run() don't match inputSchema

Mismatches found:
  - Parameter 'username': function expects string, schema says number
  - Parameter 'maxResults': function expects number, schema says string

Suggested Actions:
  - Regenerating code to fix type inconsistencies...
  {If successful: proceed}
  {If unsuccessful: report to user with details}
```

---

## Recovery Strategies

### Automatic Recovery

These issues can be fixed automatically without user intervention:

- Schema formatting (object → array)
- Type casing ("String" → "string", "Number" → "number")
- Missing empty nested arrays (add `nested: []` for primitives)
- Extra whitespace in names (trim)
- Name normalization (spaces → hyphens, uppercase → lowercase)
- Consecutive hyphens in names (-- → -)

**Process:**
1. Detect issue during validation
2. Apply automatic fix
3. Log what was fixed (for user transparency)
4. Proceed with corrected values
5. Inform user of automatic fixes in success message

### User Guidance Recovery

These issues require user input to resolve:

- Invalid/inaccessible URLs → ask for alternative
- Name conflicts (409) → ask to update or rename
- Authentication errors (401) → guide to config
- Action not found (404) → ask to create or provide correct name
- Ambiguous requests → ask for clarification

**Process:**
1. Detect issue that requires user decision
2. Explain the situation clearly
3. Provide 2-3 actionable options
4. Wait for user response
5. Execute chosen option

### Abort Conditions

These situations require aborting the operation:

- Repeated generation failures (3+ attempts)
- User explicitly cancels (responds "no" to conflict resolution)
- Unrecoverable validation errors (after retry)
- Network errors after retry limit (3 attempts)
- 401 Unauthorized (cannot proceed without valid auth)

**Process:**
1. Detect abort condition
2. Explain why operation cannot continue
3. Provide clear next steps for user
4. Clean exit (no partial state)

---

## Retry Logic

### Retryable Errors

Retry with exponential backoff (max 3 attempts):
- 500-504 Server errors
- Network errors (ECONNREFUSED, ETIMEDOUT)
- 429 Rate limit (with Retry-After header)

**Pattern:**
```
maxAttempts = 3
for attempt in 1..maxAttempts:
  try:
    result = deploy(...)
    return result  # Success
  catch (error):
    if not_retryable(error):  # 4xx errors except 429
      throw error
    if attempt < maxAttempts:
      wait_seconds = 2 ^ (attempt - 1)  # 0s, 2s, 4s
      sleep(wait_seconds)
    else:
      throw error  # All attempts exhausted
```

### Non-Retryable Errors

Do NOT retry these errors:
- 400 Bad Request
- 401 Unauthorized
- 403 Forbidden
- 404 Not Found
- 409 Conflict
- 422 Validation Error
- Other 4xx errors (except 429)

These require user intervention or code changes, not retries.

---

## Error Handling Best Practices

1. **Be specific** - Include error codes, status messages, and context
2. **Be helpful** - Provide actionable suggestions, not just error messages
3. **Be transparent** - Show what's happening (retrying, fixing, waiting)
4. **Be forgiving** - Auto-fix common issues when possible
5. **Be respectful** - Don't retry endlessly, know when to give up
6. **Be informative** - Explain why something failed and what to do next
7. **Be consistent** - Use similar message formats for similar errors
