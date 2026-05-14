# Detailed Examples

This document provides comprehensive examples of code action generation workflows.

## Table of Contents

- [Basic Examples](#basic-examples)
- [Advanced Examples](#advanced-examples)
- [Error Scenarios](#error-scenarios)
- [Edge Cases](#edge-cases)

---

## Basic Examples

### Example 1: GitHub User Fetcher

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
4. **Name:** Auto-generate → "fetch-github-user-information" → "fetch-github-user"
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
  This action is now available and can be invoked with a GitHub username.
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

---

## Advanced Examples

### Example 4: Editor Review Mode

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

**User sees in editor and makes changes:**
- Adds better error messages
- Adds validation for empty text
- Adds support for attachments parameter

**Continue:**
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
  - threadTs (string, optional): Thread timestamp for replies
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

### Example 5: Pagination Support

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

### Example 6: Complex Nested Schema

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

---

## Error Scenarios

### Example 7: Handle Conflict (Action Exists)

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

### Example 8: Handle Not Found (Update Non-Existent)

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
Operation cancelled. Use the action listing feature to see available actions, or create a new action with:
"Create a code action for..."
```

### Example 9: Error - Invalid URL

**User Input:**
```
Create a code action for a payment API
API Docs: https://nonexistent-api-docs.example.com/docs
```

**Process:**
1. **Parse:** URL extracted
2. **Invoke api-code-generator:** Fetch fails → 404 Not Found
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

---

## Edge Cases

### Example 10: Very Long Generated Name

**User Input:**
```
Create a code action for integrating with the comprehensive enterprise resource planning system API
```

**Process:**
1. Auto-generate name: "integrating-comprehensive-enterprise-resource-planning-system-api" (72 chars)
2. Truncate to 50 chars: "integrating-comprehensive-enterprise-resource-pla"
3. Remove incomplete word: "integrating-comprehensive-enterprise-resource"
4. Final: "integrating-comprehensive-enterprise-resource"

### Example 11: Name with Special Characters

**User Input:**
```
Create a code action named "Send@Emails_v2.0" for sending emails
```

**Process:**
1. Normalize: Remove @, convert _ to -, remove dots
2. Result: "send-emails-v20"
3. Valid ✓

### Example 12: Minimal API Documentation

**User Input:**
```
Create a code action for simple GET request
API Docs: https://example.com/api/simple
```

**Process:**
1. Generate basic code with minimal documentation
2. Include sensible defaults
3. Add comments noting assumptions made
4. Deploy with caveat in description
