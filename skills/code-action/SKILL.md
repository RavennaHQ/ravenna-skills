---
description: Generate TypeScript code from API documentation and automatically deploy it as a Ravenna code action with full schema support
---

# Code Action Generator Skill

Generate production-ready TypeScript code from REST API documentation and deploy it directly to Ravenna as an executable code action. This skill provides an end-to-end workflow: API docs → TypeScript code → Ravenna code action.

## Usage

This skill provides a seamless workflow for creating code actions:
1. **Provide API Documentation URL** - Link to REST API documentation
2. **Describe What You Want** - Natural language description of functionality
3. **Optional: Specify Name** - Custom action name (auto-generated if omitted)
4. **Optional: Request Review** - Add "review" to open editor before deployment

The skill will:
1. Generate TypeScript code using api-code-generator patterns
2. Optionally opkn code in editor for review/editing
3. Validate code structure and schemas
4. Create or update the code action in Ravenna via MCP
5. Confirm successful deployment with full details

## Input Format

### Create New Action
```
Create a code action for {description}
API Docs: {documentation-url}
```

### Update Existing Action
```
Update {action-name} to {changes}
API Docs: {documentation-url}
```

### With Custom Name
```
Create a code action named "{custom-name}" for {description}
API Docs: {documentation-url}
```

### With Editor Review
```
Create a code action for {description} and let me review it
API Docs: {documentation-url}
```

Or use keywords: "review", "edit", "show me", "let me check"

## Output Format

The skill provides:
- Confirmation of creation/update
- Action name
- Input parameter list with types and descriptions
- Output field list with types and descriptions
- Usage guidance

---

## Instructions for Claude

When this skill is invoked, you are a code action orchestrator. Follow these steps precisely:

### Step 1: Parse User Input

Extract from the user's request:
- **API Documentation URL** (required)
- **User Request/Description** (required)
- **Custom Name** (optional)
- **Operation Type** (create vs update)
- **Review Mode** (optional)

**Detection patterns:**
- **Create**: Default unless update keywords present
- **Update**: Request contains "update", "modify", "change", "extend", "add to"
- **Custom Name**: Explicitly in quotes or after "named"
- **Review Mode**: Request contains "review", "edit", "show me", "let me check", "let me see"

**Validation:**
- Ensure API documentation URL is present
- Ensure description is clear and actionable

### Step 2: Invoke API Code Generator

Use the **Skill** tool to invoke api-code-generator:

```
Tool: Skill
Parameters:
  skill: "api-code-generator"
  args: "Generate API integration code for:\n- API Docs: {url}\n- Request: {request}"
```

**What to capture:**
The generated TypeScript code will include:
- `export async function run(...)` - The main function
- `export const inputSchema = [...]` - Input parameters
- `export const outputSchema = [...]` - Output structure

**Error handling:**
If api-code-generator fails:
- Capture the error message
- Report to user with helpful suggestions
- Do not proceed to validation

### Step 3: Validate Generated Code

**Structure Validation:**

Check for all three required exports:
```typescript
✓ export async function run(...) exists
✓ export const inputSchema = [...] exists
✓ export const outputSchema = [...] exists
```

Verify function signature:
```typescript
✓ run() is declared as async
✓ run() accepts positional arguments (not an object)
✓ run() returns Promise<Record<string, unknown>>
```

**Schema Validation:**

For each entry in `inputSchema` and `outputSchema`:
```typescript
✓ Has 'name' field (string, camelCase)
✓ Has 'type' field (valid type from allowed list)
✓ Has 'description' field (string, non-empty)
✓ Has 'optional' field (boolean: true or false)
✓ Has 'nested' field (array, empty for primitives)
```

**Valid type values:**
- Primitives: `string`, `number`, `boolean`, `void`
- Special: `secret`, `date`, `datetime`
- Complex: `object`, `array`

**Nested schema rules:**
- Primitives and special types: `nested: []`
- Objects: `nested` contains array of property schemas
- Arrays: `nested` contains single-entry array with item schema

**If validation fails:**
1. Identify specific issue
2. Attempt automatic fix if possible:
   - Add missing fields with reasonable defaults
   - Fix type casing (e.g., "String" → "string")
   - Ensure nested arrays exist
3. If auto-fix succeeds: proceed
4. If fails: report error to user with details

### Step 3.5: Editor Review (Optional)

**When to use:**
- User request includes "review", "edit", "show me", "let me check", "let me see"
- User explicitly asks to review code before deployment
- Complex integrations where user wants to verify logic

**Skip this step if:**
- User doesn't request review
- Simple, straightforward integrations
- User trusts generated code

**Review Process:**

1. **Write code to temporary file:**
   ```bash
   # Create temp file with descriptive name
   tmpfile="/tmp/code-action-{action-name}-$(date +%s).ts"

   # Write complete TypeScript code to file
   Write tool: file_path=$tmpfile, content={generated-code}
   ```

2. **Open in user's editor:**
   ```bash
   # Use user's preferred editor (respects $EDITOR)
   ${EDITOR:-nano} "$tmpfile"

   # Common editors: $EDITOR, nano, vim, code (VS Code), subl (Sublime)
   # Wait for editor to close (blocking command)
   ```

3. **Inform user:**
   ```
   📝 Opening code in editor for review...

   File: {tmpfile}

   You can now:
   - Review the generated code
   - Make any edits you want
   - Add custom logic or error handling
   - Adjust parameter validation

   Save and close the editor when done (or Ctrl+C to cancel).
   ```

4. **Wait for editor to close:**
   - Command is blocking, waits for user to exit editor
   - User can save changes and exit
   - Or cancel (Ctrl+C) to abort operation

5. **Read edited code:**
   ```bash
   # Read the file back after user closes editor
   Read tool: file_path=$tmpfile
   ```

6. **Detect changes:**
   - Compare edited code to original
   - If different: inform user "✓ Changes detected"
   - If unchanged: inform user "No changes made"

7. **Re-validate edited code:**
   - Run all validation checks again (Step 3)
   - Ensure still has 3 exports
   - Verify schemas are still valid
   - Check function signature

   **If validation fails:**
   - Show specific errors to user
   - Ask: "Code validation failed. Would you like to:"
     - "1. Edit again to fix issues"
     - "2. Use original generated code"
     - "3. Cancel operation"
   - Handle user choice:
     - Edit again: Return to step 2 (open editor)
     - Use original: Revert to generated code, continue
     - Cancel: Abort operation

8. **Extract updated schemas:**
   - If user edited inputSchema or outputSchema
   - Parse the edited values
   - Ensure they're still valid JSON/arrays
   - Use edited schemas for deployment

9. **Cleanup:**
   ```bash
   # Optionally remove temp file (or keep for debugging)
   rm "$tmpfile"
   ```

**Benefits of review mode:**
- User sees exactly what code will be deployed
- Can add custom validation logic
- Can improve error messages
- Can add logging or debugging
- Can optimize performance
- Full transparency and control

**Example flow:**
```
User: "Create a code action for GitHub user fetch and let me review it"

1. Generate code via api-code-generator
2. Validate structure ✓
3. Write to /tmp/code-action-github-user-fetch-1234567890.ts
4. Open in editor (nano/vim/$EDITOR)
5. User reviews, adds custom error handling, saves
6. Read edited code back
7. Re-validate ✓
8. Continue to deployment with edited code
```

### Step 4: Determine Action Name

**If Custom Name Provided:**

Validate and normalize:
```typescript
1. Convert to lowercase
2. Replace spaces and underscores with hyphens
3. Remove any characters not in [a-z0-9-]
4. Ensure length is 3-50 characters
5. Remove leading/trailing hyphens
6. Remove consecutive hyphens (-- → -)
```

**Valid format:** `/^[a-z0-9]+(-[a-z0-9]+)*$/`

**If Auto-generating:**

Apply this algorithm:
```typescript
1. Extract words from user request
2. Remove stop words: ["the", "a", "an", "and", "or", "via", "using", "with", "for", "to", "from", "by"]
3. Keep first 5-7 meaningful words
4. Convert to lowercase
5. Join with hyphens
6. Truncate to 50 characters if needed
7. Remove trailing hyphens if truncated

Example transformations:
"send emails via SendGrid with templates"
  → ["send", "emails", "sendgrid", "templates"]
  → "send-emails-sendgrid-templates"

"fetch GitHub user information including repositories"
  → ["fetch", "github", "user", "information", "including", "repositories"]
  → "fetch-github-user-information-including" (truncated at 50)
  → "fetch-github-user-information" (removed incomplete word)
```

**Validation:**
- Final name must be 3-50 characters
- Must match: `/^[a-z0-9]+(-[a-z0-9]+)*$/`
- Must not start/end with hyphen
- Must not contain consecutive hyphens

### Step 5: Generate Description

Create a concise description (1-2 sentences, 10-200 characters) from the user request:

**Guidelines:**
- Focus on **purpose** (what it does)
- Include the API/service name
- Mention key capabilities or main features
- Use present tense
- Be clear and specific
- Avoid technical jargon unless necessary

**Examples:**
- "Send transactional emails via SendGrid API with template support and tracking"
- "Fetch GitHub user information including profile data, repositories, and activity statistics"
- "Process credit card payments through Stripe with automatic receipt generation and refund handling"
- "Retrieve weather forecasts for any location using OpenWeatherMap API with hourly and daily data"

**Template:**
`"{Action verb} {what} via/using {service/API} {with optional key features}"`

### Step 6: Deploy to Ravenna via MCP

**For CREATE Operations:**

1. **Call MCP tool** `create_code_action`:
   ```json
   {
     "name": "{action-name}",
     "description": "{description}",
     "code": "{typescript-code}",
     "inputSchema": [{...}],
     "outputSchema": [{...}]
   }
   ```

2. **Handle responses:**

   - **201 Created** ✅
     - Success! Proceed to Step 7 (feedback)

   - **409 Conflict** ⚠️
     - Action with this name already exists
     - Ask user: "⚠️  Action '{name}' already exists. Would you like to update it instead? (y/n)"
     - If yes: Switch to UPDATE flow (call update_code_action)
     - If no: Ask for different name, then retry CREATE with new name

   - **422 Validation Error** ⚠️
     - Schema format doesn't match Ravenna requirements
     - Parse error response for specific field/issue
     - Attempt to fix schema:
       - Ensure all required fields present
       - Fix type values to match allowed list
       - Correct nested structure
     - Retry CREATE once with corrected schema
     - If still fails: Report detailed error to user

   - **401 Unauthorized** ❌
     - Authentication failed (invalid/missing API key)
     - Guide user: "Authentication failed. Please check your Ravenna API key:"
     - "1. Set environment variable: export RAVENNA_API_KEY='your-key'"
     - "2. Or configure in user settings"
     - "Get your API key from: https://ravenna.ai"
     - Abort operation

   - **429 Rate Limit** ⏳
     - Too many requests
     - Extract `Retry-After` header value (seconds)
     - Inform user: "Rate limited by Ravenna API. Retrying in {N} seconds..."
     - Wait specified duration
     - Retry CREATE operation
     - If rate limited again: Report to user, suggest trying later

   - **500-504 Server Error** 🔄
     - Ravenna server experiencing issues
     - Retry with exponential backoff:
       - Attempt 1: Immediate retry
       - Attempt 2: Wait 2 seconds, retry
       - Attempt 3: Wait 4 seconds, retry
     - If all attempts fail: Report error to user
     - Message: "Ravenna server error after 3 attempts. Please try again later."

**For UPDATE Operations:**

1. **First, verify existence** - Call `get_code_action`:
   ```json
   {
     "name": "{action-name}"
   }
   ```

2. **Handle get_code_action responses:**

   - **200 OK** ✅
     - Action exists, retrieve current details
     - Optionally show user what's changing (diff)
     - Proceed to update

   - **404 Not Found** ⚠️
     - Action doesn't exist
     - Ask user: "⚠️  Action '{name}' doesn't exist. Would you like to create it instead? (y/n)"
     - If yes: Switch to CREATE flow
     - If no: Abort operation

3. **Call MCP tool** `update_code_action`:
   ```json
   {
     "name": "{action-name}",
     "description": "{description}",
     "code": "{typescript-code}",
     "inputSchema": [{...}],
     "outputSchema": [{...}]
   }
   ```

4. **Handle update responses:**
   - Same as CREATE responses (409, 422, 401, 429, 500-504)
   - On success (200): Proceed to Step 7 with "Updated" instead of "Created"

**Retry Logic:**

For retryable errors (500-504, network errors):
```typescript
maxAttempts = 3
for attempt in 1..maxAttempts:
  try:
    result = call_mcp_tool(...)
    return result  // Success
  catch (error):
    if not_retryable(error):  // 4xx errors except 429
      throw error
    if attempt < maxAttempts:
      wait_seconds = 2 ^ (attempt - 1)  // 0s, 2s, 4s
      sleep(wait_seconds)
    else:
      throw error  // All attempts exhausted
```

**Do NOT retry:**
- 400 Bad Request
- 401 Unauthorized
- 403 Forbidden
- 404 Not Found
- 422 Validation Error
- Other 4xx errors (except 429)

### Step 7: Provide Feedback

**On Success (CREATE or UPDATE):**

Display comprehensive confirmation:

```
✅ {Created|Updated} code action: {action-name}

Description: {description}

Input Parameters:
{for each input in inputSchema:}
  - {name} ({type}{", optional" if optional}): {description}
{end for}

Output:
{for each output in outputSchema:}
  - {name} ({type}{", optional" if optional}): {description}
{end for}

{If UPDATE operation:}
Changes Made:
  - {list of key changes, e.g., "Added 'company' field to output"}
  - {another change}
{end if}

Usage:
  This action is now available in Ravenna and can be invoked with the input parameters listed above.
```

**Example success message:**
```
✅ Created code action: fetch-github-user

Description: Fetch GitHub user information including profile data and statistics

Input Parameters:
  - username (string): GitHub username to fetch
  - token (secret, optional): GitHub personal access token for higher rate limits

Output:
  - login (string): GitHub username
  - name (string, optional): Full name
  - bio (string, optional): User biography
  - publicRepos (number): Number of public repositories
  - followers (number): Follower count
  - following (number): Following count
  - createdAt (datetime): Account creation timestamp

Usage:
  This action is now available in Ravenna and can be invoked with a GitHub username.
```

**On Error:**

Provide clear, actionable error message:

```
❌ Failed to {create|update} code action: {action-name}

Error: {error-type}
Reason: {error-message}

Suggested Actions:
  - {specific suggestion 1}
  - {specific suggestion 2}
  - {specific suggestion 3}

{If relevant, include:}
Need help? Check:
  - API documentation URL is correct and accessible
  - Ravenna API key is configured (environment: RAVENNA_API_KEY)
  - Action name follows naming rules (lowercase, hyphens, 3-50 chars)
  - MCP server is reachable at: https://core.ravenna.ai/mcp
```

**Example error messages:**

```
❌ Failed to create code action: send-emails

Error: Code generation failed
Reason: Unable to fetch API documentation - 404 Not Found

Suggested Actions:
  - Verify the API documentation URL is correct
  - Check if the documentation requires authentication
  - Try an alternative documentation source
  - Provide specific endpoint details directly

Need help? Provide a valid, publicly accessible API documentation URL.
```

```
❌ Failed to create code action: stripe-payments

Error: Schema validation failed
Reason: Invalid type 'String' in inputSchema field 'apiKey' - must be lowercase 'string'

Suggested Actions:
  - This has been automatically fixed, retrying...
```

### Step 8: Validation Checklist

Before completing, verify all criteria are met:

**Code Generation:**
- [ ] api-code-generator skill was successfully invoked
- [ ] TypeScript code was generated without errors
- [ ] Code contains all three required exports

**Code Validation:**
- [ ] `run()` function exists and is async
- [ ] `inputSchema` is an array with at least one entry
- [ ] `outputSchema` is an array with at least one entry
- [ ] All schema entries have 5 required fields (name, type, description, optional, nested)
- [ ] All types are valid (string, number, boolean, object, array, secret, date, datetime, void)
- [ ] Nested arrays are properly structured

**Editor Review (if requested):**
- [ ] Review mode correctly detected from user request
- [ ] Code written to temporary file
- [ ] Editor opened successfully (user was able to review/edit)
- [ ] Edited code read back after user closed editor
- [ ] Re-validation performed on edited code
- [ ] Any user edits are reflected in final deployment

**Action Metadata:**
- [ ] Action name is valid (3-50 chars, kebab-case)
- [ ] Description is clear and concise (10-200 chars)
- [ ] Operation type correctly identified (create vs update)

**MCP Deployment:**
- [ ] Correct MCP tool was called (create_code_action or update_code_action)
- [ ] All required parameters were provided
- [ ] Tool call succeeded (201/200 response)
- [ ] Errors were handled gracefully

**User Feedback:**
- [ ] Success/error message was displayed
- [ ] Message includes all relevant details
- [ ] Actionable suggestions provided for errors
- [ ] User knows what happened and next steps

---

## Example Invocations

### Example 1: Create GitHub User Fetcher

**User Input:**
```
Create a code action for fetching GitHub user information by username
API Docs: https://docs.github.com/rest/users/users#get-a-user
```

**Process:**
1. **Parse:** URL extracted, no custom name, CREATE operation
2. **Invoke api-code-generator:**
   - Generates TypeScript with fetch call to GitHub API
   - Includes authentication with optional token
   - Handles 404 for user not found
3. **Validate:** 3 exports ✓, schemas valid ✓
4. **Name:** Auto-generate → "fetch-github-user-information" (truncated) → "fetch-github-user"
5. **Description:** "Fetch GitHub user information including profile data and statistics"
6. **Deploy:** `create_code_action` called → 201 Created ✓
7. **Feedback:** Success confirmation displayed

**Output:**
```
✅ Created code action: fetch-github-user

Description: Fetch GitHub user information including profile data and statistics

Input Parameters:
  - username (string): GitHub username to fetch
  - token (secret, optional): GitHub personal access token for higher rate limits

Output:
  - login (string): GitHub username
  - name (string, optional): Full name
  - bio (string, optional): User biography
  - publicRepos (number): Number of public repositories
  - followers (number): Follower count
  - following (number): Following count
  - avatarUrl (string): Profile avatar URL
  - createdAt (datetime): Account creation timestamp

Usage:
  This action is now available in Ravenna and can be invoked with a GitHub username.
```

### Example 2: Update Existing Action

**User Input:**
```
Update fetch-github-user to also include the user's company and location
API Docs: https://docs.github.com/rest/users/users#get-a-user
```

**Process:**
1. **Parse:** UPDATE operation detected, name="fetch-github-user"
2. **Verify:** `get_code_action("fetch-github-user")` → 200 OK (exists)
3. **Invoke api-code-generator:** Generate updated code with company and location fields
4. **Validate:** New code includes company and location ✓
5. **Deploy:** `update_code_action` called → 200 OK ✓
6. **Feedback:** Confirmation with changes listed

**Output:**
```
✅ Updated code action: fetch-github-user

Description: Fetch GitHub user information including profile data, statistics, and location details

Input Parameters:
  - username (string): GitHub username to fetch
  - token (secret, optional): GitHub personal access token

Output:
  - login (string): GitHub username
  - name (string, optional): Full name
  - bio (string, optional): User biography
  - company (string, optional): Company name
  - location (string, optional): User location
  - publicRepos (number): Public repository count
  - followers (number): Follower count
  - following (number): Following count
  - avatarUrl (string): Profile avatar URL
  - createdAt (datetime): Account creation timestamp

Changes Made:
  - Added 'company' output field (string, optional)
  - Added 'location' output field (string, optional)
  - Updated description to mention location details

Usage:
  This action is now available with enhanced location information.
```

### Example 3: Create with Custom Name

**User Input:**
```
Create a code action named "stripe-charge" for processing credit card payments
API Docs: https://stripe.com/docs/api/charges/create
```

**Process:**
1. **Parse:** Custom name="stripe-charge", CREATE operation
2. **Invoke api-code-generator:** Generate Stripe payment processing code
3. **Validate:** Code valid ✓
4. **Name:** Use custom "stripe-charge" (already valid format) ✓
5. **Description:** "Process credit card payments via Stripe API with automatic receipt generation"
6. **Deploy:** `create_code_action` → 201 Created ✓

**Output:**
```
✅ Created code action: stripe-charge

Description: Process credit card payments via Stripe API with automatic receipt generation

Input Parameters:
  - apiKey (secret): Stripe secret API key
  - amount (number): Amount to charge in cents
  - currency (string): Three-letter ISO currency code (e.g., 'usd')
  - source (string): Payment source token or card ID
  - description (string, optional): Charge description for customer
  - receiptEmail (string, optional): Email address to send receipt

Output:
  - chargeId (string): Stripe charge ID
  - status (string): Charge status (succeeded, pending, failed)
  - amount (number): Amount charged in cents
  - currency (string): Currency code
  - receiptUrl (string, optional): URL for customer receipt
  - createdAt (datetime): Charge creation timestamp

Usage:
  This action can process credit card payments with your Stripe account.
```

### Example 4: Handle Conflict (Action Exists)

**User Input:**
```
Create a code action for sending emails via SendGrid
API Docs: https://docs.sendgrid.com/api-reference/mail-send
```

**Process:**
1. **Parse:** No custom name, CREATE operation
2. **Invoke api-code-generator:** Code generated successfully
3. **Name:** Auto-generate → "send-emails-sendgrid"
4. **Deploy:** `create_code_action("send-emails-sendgrid")` → **409 Conflict** ⚠️

**Prompt User:**
```
⚠️  Action 'send-emails-sendgrid' already exists.

Would you like to update it instead? (y/n)
```

**If user responds "yes":**
- Switch to UPDATE flow
- Call `update_code_action("send-emails-sendgrid", ...)`
- Display update confirmation

**If user responds "no":**
```
Please provide a different name for your action, or use the 'update' keyword to modify the existing action.

Suggestion: Try "send-emails-sendgrid-v2" or specify a custom name with:
"Create a code action named 'your-custom-name' for..."
```

### Example 5: Handle Not Found (Update Non-Existent)

**User Input:**
```
Update weather-forecast to include hourly data
API Docs: https://api.openweathermap.org/data/2.5/forecast
```

**Process:**
1. **Parse:** UPDATE operation, name="weather-forecast"
2. **Verify:** `get_code_action("weather-forecast")` → **404 Not Found** ⚠️

**Prompt User:**
```
⚠️  Action 'weather-forecast' doesn't exist.

Would you like to create it instead? (y/n)
```

**If user responds "yes":**
- Switch to CREATE flow
- Generate code for weather forecast with hourly data
- Call `create_code_action("weather-forecast", ...)`
- Display creation confirmation

**If user responds "no":**
```
Operation cancelled. Use 'list_code_actions' to see available actions, or create a new action with:
"Create a code action for..."
```

### Example 6: Error - Invalid URL

**User Input:**
```
Create a code action for a payment API
API Docs: https://nonexistent-api-docs.example.com/docs
```

**Process:**
1. **Parse:** URL extracted
2. **Invoke api-code-generator:** `WebFetch` fails → 404 Not Found
3. **Error propagated back**

**Output:**
```
❌ Failed to generate code for action

Error: Unable to fetch API documentation
Reason: The URL https://nonexistent-api-docs.example.com/docs is not accessible (404 Not Found)

Suggested Actions:
  - Verify the API documentation URL is correct
  - Check if the documentation requires authentication
  - Try an alternative documentation source (e.g., official API docs)
  - Search for the official documentation: "payment api documentation"

Need help? Provide a valid, publicly accessible API documentation URL.
```

### Example 7: Pagination Support

**User Input:**
```
Create a code action to list all repositories for a GitHub organization with pagination
API Docs: https://docs.github.com/rest/repos/repos#list-organization-repositories
```

**Process:**
1. **Parse:** CREATE operation, pagination mentioned
2. **Invoke api-code-generator:**
   - Generates code with pagination loop
   - Includes maxPages parameter to limit results
   - Parses Link headers for next page
3. **Validate:** Complex code with pagination logic ✓
4. **Deploy:** Create action successfully

**Output:**
```
✅ Created code action: list-organization-repositories

Description: List all repositories for a GitHub organization with pagination support

Input Parameters:
  - org (string): GitHub organization name
  - token (secret): GitHub personal access token
  - maxPages (number, optional): Maximum number of pages to fetch (default: 10)
  - perPage (number, optional): Results per page (default: 30, max: 100)

Output:
  - repositories (array): Array of repository objects
    - name (string): Repository name
    - fullName (string): Full repository name (org/repo)
    - description (string, optional): Repository description
    - stargazersCount (number): Number of stars
    - forksCount (number): Number of forks
    - language (string, optional): Primary language
    - updatedAt (datetime): Last update timestamp
  - totalCount (number): Total repositories fetched
  - pagesFetched (number): Number of pages fetched

Usage:
  This action fetches repositories with automatic pagination, respecting rate limits.
```

### Example 8: Complex Nested Schema

**User Input:**
```
Create a code action to get Stripe customer details including all payment methods
API Docs: https://stripe.com/docs/api/customers/retrieve
```

**Process:**
1. **Invoke api-code-generator:** Generates code with nested customer and payment method objects
2. **Validate:** Nested schemas properly structured ✓
3. **Deploy:** Create action with complex schema

**Output:**
```
✅ Created code action: get-stripe-customer

Description: Retrieve Stripe customer details including profile and payment methods

Input Parameters:
  - apiKey (secret): Stripe secret API key
  - customerId (string): Stripe customer ID

Output:
  - customer (object): Customer details
    - id (string): Customer ID
    - email (string): Customer email
    - name (string, optional): Customer name
    - phone (string, optional): Phone number
    - created (datetime): Customer creation timestamp
    - defaultSource (string, optional): Default payment method ID
    - paymentMethods (array): Array of payment methods
      - id (string): Payment method ID
      - type (string): Type (card, bank_account, etc.)
      - card (object, optional): Card details
        - brand (string): Card brand (visa, mastercard, etc.)
        - last4 (string): Last 4 digits
        - expMonth (number): Expiration month
        - expYear (number): Expiration year
      - createdAt (datetime): Payment method creation timestamp

Usage:
  This action retrieves comprehensive customer information from Stripe.
```

### Example 9: Editor Review Mode

**User Input:**
```
Create a code action for sending Slack messages and let me review the code
API Docs: https://api.slack.com/methods/chat.postMessage
```

**Process:**
1. **Parse:** CREATE operation, **review mode detected** ✓
2. **Invoke api-code-generator:** Generate Slack message sending code
3. **Validate:** Code structure valid ✓
4. **Write to temp file:** `/tmp/code-action-send-slack-message-1711234567.ts`
5. **Open in editor:** User's $EDITOR (nano/vim/code)

**User sees in editor:**
```typescript
export async function run(token: string, channel: string, text: string, threadTs?: string): Promise<Record<string, unknown>> {
  const headers = {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  };

  const body = JSON.stringify({
    channel,
    text,
    ...(threadTs && { thread_ts: threadTs })
  });

  const response = await fetch('https://slack.com/api/chat.postMessage', {
    method: 'POST',
    headers,
    body
  });

  if (!response.ok) {
    throw new Error(`Slack API error: ${response.status}`);
  }

  const data = await response.json();

  if (!data.ok) {
    throw new Error(`Slack error: ${data.error}`);
  }

  return {
    messageTs: data.ts,
    channel: data.channel,
    text: data.message.text
  };
}

export const inputSchema = [
  { name: 'token', type: 'secret', description: 'Slack bot token', optional: false, nested: [] },
  { name: 'channel', type: 'string', description: 'Channel ID or name', optional: false, nested: [] },
  { name: 'text', type: 'string', description: 'Message text', optional: false, nested: [] },
  { name: 'threadTs', type: 'string', description: 'Thread timestamp for replies', optional: true, nested: [] }
];

export const outputSchema = [
  { name: 'messageTs', type: 'string', description: 'Message timestamp', optional: false, nested: [] },
  { name: 'channel', type: 'string', description: 'Channel where sent', optional: false, nested: [] },
  { name: 'text', type: 'string', description: 'Sent message text', optional: false, nested: [] }
];
```

**User edits:**
- Adds better error messages
- Adds validation for empty text
- Adds support for attachments parameter

**Edited code:**
```typescript
export async function run(token: string, channel: string, text: string, threadTs?: string, attachments?: string): Promise<Record<string, unknown>> {
  // Validate inputs
  if (!text || text.trim().length === 0) {
    throw new Error('Message text cannot be empty');
  }

  const headers = {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  };

  const body: any = {
    channel,
    text,
  };

  if (threadTs) {
    body.thread_ts = threadTs;
  }

  if (attachments) {
    body.attachments = JSON.parse(attachments);
  }

  const response = await fetch('https://slack.com/api/chat.postMessage', {
    method: 'POST',
    headers,
    body: JSON.stringify(body)
  });

  if (!response.ok) {
    throw new Error(`Slack API HTTP error: ${response.status} ${response.statusText}`);
  }

  const data = await response.json();

  if (!data.ok) {
    throw new Error(`Slack API error: ${data.error || 'Unknown error'}`);
  }

  return {
    messageTs: data.ts,
    channel: data.channel,
    text: data.message.text,
    success: true
  };
}

export const inputSchema = [
  { name: 'token', type: 'secret', description: 'Slack bot token (starts with xoxb-)', optional: false, nested: [] },
  { name: 'channel', type: 'string', description: 'Channel ID (e.g., C1234567890) or name (e.g., #general)', optional: false, nested: [] },
  { name: 'text', type: 'string', description: 'Message text (supports Slack markdown)', optional: false, nested: [] },
  { name: 'threadTs', type: 'string', description: 'Thread timestamp for replies (e.g., 1234567890.123456)', optional: true, nested: [] },
  { name: 'attachments', type: 'string', description: 'JSON string of message attachments', optional: true, nested: [] }
];

export const outputSchema = [
  { name: 'messageTs', type: 'string', description: 'Message timestamp (unique ID)', optional: false, nested: [] },
  { name: 'channel', type: 'string', description: 'Channel where message was sent', optional: false, nested: [] },
  { name: 'text', type: 'string', description: 'Sent message text', optional: false, nested: [] },
  { name: 'success', type: 'boolean', description: 'Whether send was successful', optional: false, nested: [] }
];
```

**User saves and closes editor**

6. **Read edited code:** Changes detected ✓
7. **Re-validate:** New code structure valid ✓, schemas valid ✓
8. **Name:** Auto-generate → "send-slack-message"
9. **Description:** "Send messages to Slack channels with support for threads and attachments"
10. **Deploy:** `create_code_action` with **edited code** → 201 Created ✓

**Output:**
```
✓ Changes detected - using your edited code

✅ Created code action: send-slack-message

Description: Send messages to Slack channels with support for threads and attachments

Input Parameters:
  - token (secret): Slack bot token (starts with xoxb-)
  - channel (string): Channel ID (e.g., C1234567890) or name (e.g., #general)
  - text (string): Message text (supports Slack markdown)
  - threadTs (string, optional): Thread timestamp for replies (e.g., 1234567890.123456)
  - attachments (string, optional): JSON string of message attachments

Output:
  - messageTs (string): Message timestamp (unique ID)
  - channel (string): Channel where message was sent
  - text (string): Sent message text
  - success (boolean): Whether send was successful

Customizations Applied:
  - Added empty text validation
  - Improved error messages with status details
  - Added attachments parameter support
  - Enhanced parameter descriptions
  - Added success boolean to output

Usage:
  This action sends Slack messages with your custom enhancements applied.
```

**Key Benefits Demonstrated:**
- ✅ User reviewed generated code before deployment
- ✅ Added custom validation logic (empty text check)
- ✅ Improved error messages (HTTP status, detailed errors)
- ✅ Extended functionality (attachments parameter)
- ✅ Enhanced documentation (better parameter descriptions)
- ✅ Full transparency and control

---

## Validation Rules

### Code Structure Requirements

**Must Have:**
- Exactly 3 exports: `run`, `inputSchema`, `outputSchema`
- No additional exports allowed
- No default exports

**run() Function Requirements:**
```typescript
✓ Must be declared as async
✓ Must accept positional arguments (not an object parameter)
✓ Argument order must match inputSchema array order exactly
✓ Must return Promise<Record<string, unknown>>
✓ Optional parameters use TypeScript ?: syntax
✓ Function body must contain actual logic (not just a stub)
```

**Schema Requirements:**
```typescript
✓ Must be arrays (not objects)
✓ Cannot be empty (must have at least one entry)
✓ Must be JSON-serializable (no functions, symbols, etc.)
✓ Array order defines positional argument order
```

### Schema Entry Requirements

**Required Fields (all must be present):**

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

**Field Validation Rules:**

**name:**
- Type: string
- Format: camelCase (e.g., `userId`, `apiKey`, `maxResults`)
- Must not contain spaces or special characters (except underscore)
- Length: 1-50 characters
- Must be unique within the same schema

**type:**
- Type: string
- Must be one of the valid types (case-sensitive):
  - **Primitives:** `string`, `number`, `boolean`, `void`
  - **Special:** `secret`, `date`, `datetime`
  - **Complex:** `object`, `array`
- Invalid: `String`, `Number`, `int`, `float`, `str`, etc.

**description:**
- Type: string
- Must be non-empty
- Length: 5-200 characters
- Should be clear and actionable
- Should describe the purpose, not just repeat the name
- Good: "GitHub personal access token for authentication"
- Bad: "token" or "The token"

**optional:**
- Type: boolean
- Must be exactly `true` or `false`
- Cannot be: `1`, `0`, `"true"`, `"false"`, `null`, `undefined`
- Meaning:
  - `false` = required parameter/field
  - `true` = optional parameter/field

**nested:**
- Type: array
- For primitives (`string`, `number`, `boolean`, `secret`, `date`, `datetime`, `void`): Must be empty `[]`
- For `object`: Array of property schemas (recursive structure)
- For `array`: Single-entry array containing the item schema
- Cannot be: `null`, `undefined`, missing

### Nested Schema Rules

**For Object Types:**
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

**For Array Types:**
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

**For Arrays of Objects:**
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

### Name Format Rules

**Action Names:**

Valid format: `/^[a-z0-9]+(-[a-z0-9]+)*$/`

**Requirements:**
- Lowercase letters (a-z) only
- Numbers (0-9) allowed
- Hyphens (-) for word separation
- Length: 3-50 characters
- No leading or trailing hyphens
- No consecutive hyphens
- Must be descriptive and clear

**Valid Examples:**
- `fetch-github-user`
- `send-email-sendgrid`
- `stripe-payment-v2`
- `get-weather-forecast`
- `list-org-repos`

**Invalid Examples:**
- `FetchUser` (uppercase) → normalize to `fetchuser`
- `fetch_user` (underscore) → normalize to `fetch-user`
- `fetch user` (space) → normalize to `fetch-user`
- `ab` (too short) → reject, ask for longer name
- `-fetch-user` (leading hyphen) → normalize to `fetch-user`
- `fetch--user` (consecutive hyphens) → normalize to `fetch-user`
- `ThisIsWayTooLongOfANameForAnActionAndShouldBeTruncated123` (>50 chars) → truncate to 50

### Description Requirements

**Format:**
- Length: 10-200 characters
- Complete sentence(s) with proper punctuation
- Focus on purpose and capability
- Include service/API name
- Mention key features if relevant

**Guidelines:**
- Use present tense ("Fetch", "Send", "Process")
- Be specific about what it does
- Avoid generic phrases like "This action..." at the start
- No technical jargon unless necessary for clarity

**Good Examples:**
- "Send transactional emails via SendGrid API with template support and tracking"
- "Fetch GitHub user information including profile data and statistics"
- "Process credit card payments through Stripe with automatic receipt generation"

**Bad Examples:**
- "Emails" (too short, not descriptive)
- "This action sends emails using an API" (generic, starts with "This action")
- "Utilizes the SendGrid API to facilitate electronic mail transmission" (jargon, overly verbose)

---

## Error Handling

### Code Generation Errors

#### API Documentation Unreachable

**Error Type:** WebFetch Failed
**Cause:** URL returns 404, 403, timeout, or network error
**Detection:** api-code-generator returns error with fetch details

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

#### Invalid API Documentation

**Error Type:** Parsing Failed
**Cause:** Documentation format unrecognized or insufficient detail
**Detection:** api-code-generator unable to extract endpoint information

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

#### Code Generation Timeout

**Error Type:** Timeout
**Cause:** WebFetch or generation takes longer than expected (>60s)
**Detection:** api-code-generator timeout or hangs

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

### MCP Tool Errors

#### 401 Unauthorized

**Error Type:** Authentication Failed
**Cause:** Invalid or missing Ravenna API key
**Detection:** MCP tool returns 401 status

**Action:**
1. Check if RAVENNA_API_KEY environment variable is set
2. Guide user to configure API key
3. Provide link to get API key
4. Do not retry (won't succeed without valid key)

**Error Message Template:**
```
❌ Failed to {create|update} code action

Error: Authentication failed
Reason: Invalid or missing Ravenna API key

Suggested Actions:
  1. Set your API key as an environment variable:
     export RAVENNA_API_KEY='your-api-key-here'

  2. Or configure it in user settings/config

  3. Get your API key from: https://ravenna.ai

  4. Verify your key is valid and not expired

Once configured, try your request again.
```

#### 404 Not Found (Update Operation)

**Error Type:** Action Not Found
**Cause:** Attempting to update a code action that doesn't exist
**Detection:** get_code_action returns 404

**Action:**
1. Confirm action name with user
2. Offer to list existing actions
3. Ask if user wants to create instead
4. If yes: switch to CREATE flow

**Error Message Template:**
```
⚠️  Action '{name}' doesn't exist.

The code action you're trying to update was not found in Ravenna.

Would you like to:
  1. Create it as a new action instead? (y/n)
  2. View all existing actions to find the correct name
  3. Check the spelling of the action name

Respond with 'y' to create, or provide the correct action name.
```

#### 409 Conflict (Create Operation)

**Error Type:** Action Already Exists
**Cause:** Attempting to create a code action with a name that's already taken
**Detection:** create_code_action returns 409

**Action:**
1. Inform user that action exists
2. Ask if they want to update the existing action instead
3. If yes: switch to UPDATE flow
4. If no: ask for a different name

**Error Message Template:**
```
⚠️  Action '{name}' already exists.

A code action with this name is already in Ravenna.

Would you like to:
  1. Update the existing action with new code? (y/n)
  2. Choose a different name for your new action
  3. View the existing action's details first

Respond with:
  - 'y' to update the existing action
  - 'n' to provide a different name
  - 'view' to see the existing action details
```

#### 422 Validation Error

**Error Type:** Schema Validation Failed
**Cause:** Schema format doesn't match Ravenna's requirements
**Detection:** create_code_action or update_code_action returns 422

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

Error: {specific validation error from Ravenna}

Automatic fixes applied:
  - {fix 1, e.g., "Changed type 'String' to 'string' in field 'username'"}
  - {fix 2, e.g., "Added missing 'nested' field to 'apiKey'"}

Retrying with corrected schema...

{If retry succeeds: show success message}
{If retry fails: show detailed error and ask user for help}
```

#### 429 Rate Limit

**Error Type:** Rate Limit Exceeded
**Cause:** Too many requests to Ravenna API in short time
**Detection:** create_code_action or update_code_action returns 429

**Action:**
1. Extract `Retry-After` header value (seconds)
2. Inform user of wait time
3. Wait specified duration
4. Retry request automatically
5. If rate limited again: report to user, suggest trying later

**Error Message Template:**
```
⏳ Rate limit exceeded - Ravenna API

Reason: Too many requests in a short period

Action: Waiting {N} seconds before retrying...

{After waiting, automatically retry}

{If retry succeeds: show success message}
{If rate limited again: "Please wait a few minutes before trying again"}
```

#### 500-504 Server Errors

**Error Type:** Server Error
**Cause:** Ravenna MCP server experiencing issues
**Detection:** create_code_action or update_code_action returns 5xx status

**Action:**
1. Retry with exponential backoff:
   - Attempt 1: Immediate retry
   - Attempt 2: Wait 2 seconds
   - Attempt 3: Wait 4 seconds
2. If all fail: report error to user
3. Suggest trying again later
4. Provide status page link if available

**Error Message Template:**
```
🔄 Ravenna server error - Retrying...

Error: {status} {statusText}

Attempt 1/3: Retrying immediately...
{If fails} Attempt 2/3: Retrying in 2 seconds...
{If fails} Attempt 3/3: Retrying in 4 seconds...

{If all attempts fail:}
❌ Failed to {create|update} code action after 3 attempts

Error: Ravenna server is experiencing issues
Reason: Received {status} error from server

Suggested Actions:
  - Try again in a few minutes
  - Check Ravenna status page: https://status.ravenna.ai (if available)
  - Verify your network connection
  - Contact Ravenna support if issue persists

Your code has been generated and validated - you can retry deployment without regenerating.
```

#### Network Errors

**Error Type:** Connection Failed
**Cause:** Network connectivity issue, DNS failure, timeout
**Detection:** MCP tool call throws network exception

**Action:**
1. Verify MCP server URL in .mcp.json
2. Check network connectivity
3. Retry with backoff (max 3 attempts)
4. If fails: suggest checking configuration

**Error Message Template:**
```
❌ Network error - Unable to connect to Ravenna

Error: {error message, e.g., "ECONNREFUSED", "ETIMEDOUT"}

Suggested Actions:
  1. Verify your network connection is active
  2. Check MCP server configuration in .mcp.json:
     - URL should be: https://core.ravenna.ai/mcp
     - Authorization header should include your API key
  3. Verify Ravenna service is accessible (try in browser)
  4. Check for firewall or proxy issues
  5. Try again in a few moments

Configuration file: /Users/kailash/code/ravenna-claude/.mcp.json
```

### Validation Errors

#### Missing Exports

**Error Type:** Incomplete Code Structure
**Cause:** Generated code missing run, inputSchema, or outputSchema
**Detection:** Code validation step finds < 3 exports

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

#### Schema Format Invalid

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

#### Type Mismatch

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

### Recovery Strategies

#### Automatic Recovery

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

#### User Guidance Recovery

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

#### Abort Conditions

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

## Tools Required

### Claude Tools

**Skill** (Required)
- **Purpose:** Invoke the api-code-generator skill for code generation
- **Usage:** `skill: "api-code-generator"`, `args: "Generate API integration code for..."`
- **Output:** Complete TypeScript code with run(), inputSchema, outputSchema

**ToolSearch** (Optional)
- **Purpose:** Discover available MCP tools if needed
- **Usage:** `query: "select:create_code_action,update_code_action,get_code_action"`
- **Output:** MCP tool definitions

### MCP Tools (from Ravenna)

**create_code_action** (Required for CREATE operations)
- **Purpose:** Create a new code action in Ravenna
- **Parameters:**
  - `name` (string): Action name (kebab-case, 3-50 chars)
  - `description` (string): Action description (10-200 chars)
  - `code` (string): Complete TypeScript code
  - `inputSchema` (array): Input parameter schema
  - `outputSchema` (array): Output structure schema
- **Returns:** Action details with ID and confirmation (201 Created)
- **Errors:** 409 (conflict), 422 (validation), 401 (auth), 429 (rate limit), 5xx (server)

**get_code_action** (Required for UPDATE operations)
- **Purpose:** Retrieve existing code action details
- **Parameters:**
  - `name` (string): Action name to retrieve
- **Returns:** Full action details including code and schemas (200 OK)
- **Errors:** 404 (not found), 401 (auth), 429 (rate limit), 5xx (server)

**update_code_action** (Required for UPDATE operations)
- **Purpose:** Modify an existing code action
- **Parameters:**
  - `name` (string): Action name (required)
  - `description` (string, optional): New description
  - `code` (string, optional): New code
  - `inputSchema` (array, optional): New input schema
  - `outputSchema` (array, optional): New output schema
- **Returns:** Updated action details (200 OK)
- **Errors:** 404 (not found), 422 (validation), 401 (auth), 429 (rate limit), 5xx (server)

**delete_code_action** (Optional, for future use)
- **Purpose:** Remove a code action
- **Parameters:**
  - `name` (string): Action name to delete
- **Returns:** Confirmation (200 OK)
- **Errors:** 404 (not found), 401 (auth), 5xx (server)

**list_code_actions** (Helpful for conflict resolution)
- **Purpose:** List all available code actions
- **Parameters:** None
- **Returns:** Array of action summaries (name, description)
- **Errors:** 401 (auth), 429 (rate limit), 5xx (server)

### Optional Tools

**LSP** (Optional, if available)
- **Purpose:** TypeScript syntax validation before deployment
- **Usage:** Validate generated TypeScript code for syntax errors
- **Benefit:** Catch compilation errors before creating action

**AskUserQuestion** (For user interaction)
- **Purpose:** Prompt user for decisions during conflict resolution
- **Usage:** Ask yes/no questions or request input
- **Examples:** "Update existing action?", "Provide a different name?"

---

## Related Skills

### api-code-generator (Dependency)

**Purpose:** Generate production-ready TypeScript API integration code
**Location:** `/Users/kailash/code/ravenna-claude/skills/api-code-generator/SKILL.md`

**Use for:** Converting API documentation to TypeScript code
**Provides:** Complete code with run(), inputSchema, outputSchema
**Invoked by:** This skill (code-action) in Step 2

**Key features:**
- Fetches and parses API documentation
- Generates type-safe TypeScript functions
- Supports authentication patterns (Bearer, API key, Basic auth)
- Handles pagination (cursor, offset, Link header, page number)
- Includes error handling and retries
- Supports both fetch and axios+axios-retry

**Relationship:**
This skill (code-action) orchestrates the end-to-end workflow:
1. code-action receives user request
2. code-action invokes api-code-generator for code generation
3. code-action validates the generated code
4. code-action deploys to Ravenna via MCP
5. code-action provides feedback to user

### code-review (Future)

**Purpose:** Review generated code quality before deployment
**Use for:** Validating code quality, security, and best practices
**Provides:** Quality assessment and improvement suggestions

**Potential integration:**
- Run code-review after generation, before deployment
- Catch security vulnerabilities (SQL injection, XSS)
- Suggest optimizations (caching, error handling)
- Ensure code follows TypeScript best practices

---

## Best Practices

### For Users

**1. Provide Clear Documentation URLs**
- ✅ Link directly to specific endpoint documentation
- ✅ Use official API docs when available
- ✅ Ensure URLs are publicly accessible
- ❌ Avoid landing pages or general overviews
- ❌ Don't use URLs that require authentication

**Good examples:**
- `https://docs.github.com/rest/users/users#get-a-user`
- `https://stripe.com/docs/api/charges/create`
- `https://docs.sendgrid.com/api-reference/mail-send/mail-send`

**Bad examples:**
- `https://github.com` (too general)
- `https://api.example.com` (no docs)
- `https://internal.company.com/api` (requires auth)

**2. Be Specific in Requests**
- ✅ "Create action to send email with attachments via SendGrid"
- ✅ "Fetch GitHub user profile including repositories and activity"
- ❌ "email action" (too vague)
- ❌ "github stuff" (unclear)

**3. Use Descriptive Names**
- ✅ If providing custom name, make it clear and specific
- ✅ Follow kebab-case convention
- ✅ Keep names focused on single responsibility
- ❌ Generic names like "api" or "fetch"
- ❌ Very long names that are hard to remember

**Examples:**
- ✅ `github-user-fetch`
- ✅ `sendgrid-email-send`
- ✅ `stripe-payment-create`
- ❌ `api`
- ❌ `do-stuff-with-the-github-api-for-users-and-repos`

**4. Use Editor Review Mode When Needed**
- ✅ **Use review for:** Complex integrations, security-sensitive code, production deployments
- ✅ **Use review to:** Add custom validation, improve error messages, add logging
- ✅ **Use review to:** Verify generated code quality before deployment
- ❌ **Skip review for:** Simple, straightforward APIs you trust
- ❌ **Skip review for:** Rapid prototyping or testing

**When to use review mode:**
- First time using an API (verify code quality)
- Handling sensitive data (API keys, user data)
- Production deployments (review before going live)
- Complex logic (pagination, authentication, retries)
- Want to add custom error handling or validation

**Example requests:**
- "Create a code action for Stripe payments and let me review it"
- "Create GitHub integration and show me the code first"
- "Build Slack webhook handler, I want to edit it before deploying"

**5. Test Actions After Creation**
- Verify action works as expected with real data
- Check error handling with invalid inputs
- Update if additional fields are needed
- Test edge cases (missing optionals, pagination limits)

**6. Keep Actions Focused**
- One action = one API operation
- Don't try to combine multiple endpoints in one action
- Split complex workflows into multiple actions
- Compose actions together for complex workflows

### For Skill Implementation

**1. Always Validate Before Deploying**
- Check code structure is complete (3 exports)
- Verify all schema fields are present and valid
- Ensure type consistency between function and schemas
- Catch issues early before calling MCP tools

**2. Provide Clear Feedback**
- Success messages should include full parameter/output details
- Error messages should have actionable suggestions
- Progress updates for long operations (waiting, retrying)
- Be transparent about automatic fixes applied

**3. Handle Conflicts Gracefully**
- Always ask user preference (update vs rename)
- Never silently overwrite existing actions
- Offer alternatives (list actions, suggest names)
- Preserve user's work and intent

**4. Retry Intelligently**
- Use exponential backoff for server errors
- Limit retry attempts (max 3)
- Don't retry 4xx errors (except 429 rate limit)
- Inform user of retries and wait times
- Respect Retry-After headers

**5. Maintain Code Quality**
- Generated code should be production-ready
- Include proper error handling
- Validate required parameters
- Return clean, transformed data (not raw responses)
- Follow TypeScript best practices

**6. Be Security Conscious**
- Use `secret` type for sensitive data (API keys, tokens, passwords)
- Don't log or display secret values
- Validate URLs before fetching
- Sanitize user inputs in generated code
- Avoid code injection vulnerabilities

**7. Document Everything**
- Clear descriptions for all parameters
- Explain optional vs required fields
- Document expected input formats
- Specify output structure
- Include usage examples in feedback

---

## Performance Considerations

### Expected Timing

**End-to-End Performance:**

| Operation | Expected Time | Details |
|-----------|---------------|---------|
| Code Generation | 5-15 seconds | Via api-code-generator skill invocation |
| Validation | <1 second | Local checks, very fast |
| MCP Tool Call | 1-3 seconds | Network round-trip to Ravenna |
| **Total (CREATE)** | **10-20 seconds** | Parse → Generate → Validate → Deploy |
| **Total (UPDATE)** | **12-25 seconds** | Includes get_code_action call |

**Factors affecting timing:**
- **API docs size:** Large docs take longer to fetch and parse
- **Code complexity:** Pagination and retry logic add generation time
- **Network latency:** Affects MCP tool call duration
- **Retries:** Each retry adds 2-4 seconds + operation time

### Optimization Tips

**1. Minimize Sequential Operations**
- Validation runs locally (no network delay)
- Only one MCP call per operation (create or update)
- No unnecessary tool calls

**2. Fast Failure**
- Validate inputs early (before generation)
- Don't retry non-retryable errors
- Abort quickly on user cancellation

**3. Provide Progress Updates**
- Inform user at each major step
- Show retry attempts and wait times
- Display "Working..." during generation

**4. Cache When Possible**
- Consider caching generated names to avoid duplicates
- Reuse validated schemas for similar requests
- (Future: Cache common API patterns)

**5. Set Reasonable Timeouts**
- Total operation timeout: 60 seconds
- WebFetch timeout: 30 seconds (in api-code-generator)
- MCP call timeout: 10 seconds
- Allow user to retry if timeout occurs

### Bottlenecks and Mitigations

**1. API Documentation Fetch (Slowest)**
- **Issue:** Large docs (>1MB) take 10-30 seconds
- **Mitigation:** Handled by api-code-generator, use focused doc URLs
- **User action:** Link to specific endpoint docs, not entire API reference

**2. Code Generation**
- **Issue:** Complex APIs with pagination take longer (10-15s)
- **Mitigation:** Accept this as necessary complexity
- **User action:** Be patient, quality code takes time

**3. MCP Network Latency**
- **Issue:** Slow connections affect tool call duration
- **Mitigation:** Retry with backoff on network errors
- **User action:** Ensure stable internet connection

**4. Retry Delays**
- **Issue:** Each retry adds 2-4 seconds wait time
- **Mitigation:** Limit retries to 3 attempts, use exponential backoff
- **Trade-off:** Resilience vs speed

### Performance Metrics

**Target SLAs:**
- **Success rate:** >95% for valid inputs
- **P50 latency:** <15 seconds (create), <20 seconds (update)
- **P95 latency:** <30 seconds (create), <40 seconds (update)
- **Error rate:** <5% (excluding user errors like invalid URLs)
- **Retry success:** >90% of retryable errors succeed within 3 attempts

**Monitoring:**
- Track operation duration by step
- Measure MCP tool call latency
- Monitor retry frequency and success rate
- Alert on timeout spikes or high error rates

---

## Limitations

**API Documentation:**
- Requires publicly accessible documentation
- Works best with REST APIs (GraphQL support limited)
- May struggle with very complex or poorly documented APIs
- Cannot handle documentation requiring authentication

**Code Generation:**
- Generated code quality depends on documentation quality
- Complex authentication flows (OAuth 2.0 multi-step) may need manual adjustment
- WebSocket and streaming APIs not fully supported
- Binary data handling (file uploads) may be basic

**MCP Integration:**
- Requires valid Ravenna API key
- Subject to Ravenna rate limits
- Network connectivity required
- MCP server must be accessible

**Name Generation:**
- Auto-generated names may not always be perfect
- Collisions possible with common API terms
- 50-character limit may truncate descriptive names
- Non-English API names may not normalize well

**Schema Support:**
- Very deeply nested structures (>10 levels) may be complex
- Circular references not supported
- Some exotic TypeScript types may not map to schema types
- Validation of complex conditional types is limited

**Performance:**
- Large API documentation (>5MB) may timeout
- Complex integrations may take 20-30 seconds
- Network latency affects total time
- No offline mode (requires internet)

---

## Future Enhancements

### Phase 2 (Post-MVP)

**1. Batch Operations**
- Create multiple actions in one invocation
- Useful for APIs with many similar endpoints
- Example: "Create actions for all Stripe payment methods"

**2. Action Templates**
- Library of common API patterns
- Quick-start for popular services (GitHub, Stripe, SendGrid, etc.)
- Pre-validated code for common use cases
- Example: `/code-action template:sendgrid-email`

**3. Test Mode** *(Editor review mode already available - see v1.1.0)*
- Non-interactive validation without deployment
- Preview generated action in terminal (no editor)
- Dry-run MCP calls to validate schemas
- Example: `/code-action test "fetch github user"`
- Note: Use "review" keyword for interactive editing

**4. Diff Viewer for Updates**
- Show side-by-side comparison of changes
- Highlight what's being added/removed
- Require explicit confirmation before update
- Prevent accidental overwrites

**5. Version History**
- Track action changes over time
- Rollback to previous version
- Compare versions
- Example: `/code-action history fetch-github-user`

### Phase 3 (Advanced Features)

**1. Action Dependencies**
- Actions that call other actions
- Dependency graph visualization
- Circular dependency detection
- Composite workflows

**2. Analytics Integration**
- Track action usage frequency
- Monitor performance and errors
- Alert on failures
- Usage reports

**3. A/B Testing Support**
- Deploy multiple variants of an action
- Split traffic between versions
- Compare results
- Gradual rollout

**4. Code Action Marketplace**
- Share actions publicly
- Browse community actions
- Import/fork actions
- Rating and reviews

**5. Visual Schema Builder**
- GUI for schema editing
- Drag-and-drop fields
- Real-time validation
- Interactive type selection

**6. Enhanced Authentication**
- OAuth 2.0 flow support
- Token refresh logic
- Multiple auth methods per action
- Secure credential storage

**7. GraphQL Support**
- Parse GraphQL schemas
- Generate typed queries
- Handle subscriptions
- Support fragments and variables

---

## Changelog

### v1.1.0 (2026-04-01) - Editor Review Mode

**New Features:**
- ✅ **Editor review mode** - Open generated code in editor before deployment
- ✅ Review detection from user requests ("review", "edit", "show me", "let me check")
- ✅ Write code to temporary file for editing
- ✅ Wait for user to review and make changes
- ✅ Re-validate edited code before deployment
- ✅ Support for $EDITOR environment variable (nano, vim, code, etc.)
- ✅ Detect and report user changes vs original code
- ✅ Full transparency and user control over deployed code

**Example Usage:**
```
Create a code action for sending Slack messages and let me review it
API Docs: https://api.slack.com/methods/chat.postMessage
```

### v1.0.0 (2026-04-01) - Initial Release

**Features:**
- ✅ End-to-end code action workflow (docs → code → Ravenna)
- ✅ Automatic code generation via api-code-generator skill
- ✅ CREATE and UPDATE operations
- ✅ Auto-generated kebab-case names from requests
- ✅ Custom name support
- ✅ Comprehensive validation (code structure + schemas)
- ✅ MCP integration with all 5 Ravenna tools
- ✅ Conflict resolution (409, 404 handling)
- ✅ Error handling with retry logic (5xx, 429)
- ✅ Clear success/error feedback with full details
- ✅ 8+ example invocations
- ✅ Complete documentation (validation rules, error handling, best practices)

**Known Issues:**
- OAuth 2.0 flows require manual intervention
- Very large API docs (>5MB) may timeout
- GraphQL support is limited

---

## Support

**Getting Help:**

1. **Documentation:**
   - This skill: `/Users/kailash/code/ravenna-claude/skills/code-action/SKILL.md`
   - api-code-generator: `/Users/kailash/code/ravenna-claude/skills/api-code-generator/SKILL.md`
   - Main README: `/Users/kailash/code/ravenna-claude/README.md`

2. **Common Issues:**
   - Authentication errors: Check RAVENNA_API_KEY environment variable
   - Name conflicts: Use update operation or choose different name
   - Invalid schemas: Check type values are lowercase and valid
   - Network errors: Verify internet connection and MCP server URL

3. **Reporting Bugs:**
   - Include the full error message
   - Provide the API documentation URL you used
   - Share the user request that triggered the issue
   - Note any error codes from MCP tools

4. **Feature Requests:**
   - Describe the use case
   - Explain why current functionality is insufficient
   - Suggest potential implementation approach

**Contact:**
- GitHub Issues: [Repository issues page]
- Ravenna Docs: https://docs.ravenna.ai/
- MCP Server Status: https://status.ravenna.ai/ (if available)

---

**Ready to create code actions!** 🚀

```
/code-action

Create a code action for {your API integration}
API Docs: {documentation-url}
```
