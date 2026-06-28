# Ravenna Workflow Building Guide
**Production Edition - Optimized**

## Overview
This guide provides comprehensive instructions for building production-ready workflows in Ravenna, including critical best practices and proven patterns from active production workflows.

---

## 🔴🔴🔴 THE GOLDEN RULE: ALWAYS VERIFY

**THIS IS THE MOST IMPORTANT RULE. Read this first, reference it constantly.**

### Why Verification Matters

Invalid field references cause runtime failures that are impossible to debug. Making changes without verification leads to:
- ❌ Invalid references that fail at runtime
- ❌ Schema confusion (`.input` vs `.output`)
- ❌ Cascading errors across multiple steps
- ❌ Hours of debugging and API calls to fix

**Verification takes 10 seconds. Fixing runtime errors takes hours.**

### The Mandatory Verification Workflow

For EVERY step you create or update:

```
┌─────────────────────────────────────────────────┐
│                                                 │
│   1. VERIFY   → Get suggestions first           │
│   2. UPDATE   → Use verified references         │
│   3. VERIFY   → Confirm it worked               │
│   4. PROCEED  → Move to next step               │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Example: The CORRECT Way

```javascript
// Step 1: VERIFY - Get suggestions for the step you're about to update
const stepSuggestions = await mcp__ravenna__workflowConfig__getStep({
  workflowId: "wf_XXX",
  workspaceId: "workspace-id",
  stepId: "step-to-update",
  suggestions: true  // 🔴 CRITICAL - Always set to true!
});

// Step 2: FIND CORRECT REFERENCES - Look in suggestions array
const ticketIdRef = stepSuggestions.suggestions.find(s =>
  s.field.semanticField === "ticketId" &&
  s.referenceId.includes(".output.ticketId")
);
// Found: "jp:$.trigger.output.ticketId"

const userMentionRef = stepSuggestions.suggestions.find(s =>
  s.field.key.includes("requester") &&
  s.referenceId.endsWith(".userMention")
);
// Found: "jp:$.trigger.output.ticket.requester.userMention"

// Step 3: UPDATE - Use the verified references
await mcp__ravenna__workflow__updateStep({
  workflowId: "wf_XXX",
  workspaceId: "workspace-id",
  id: "step-to-update",
  action: "RavTicketMessageAddAction",
  inputs: {
    ticketId: ticketIdRef.referenceId,  // ✅ Verified!
    comment: "{{@" + userMentionRef.referenceId + "}} Hello!"  // ✅ Verified!
  }
});

// Step 4: VERIFY AGAIN - Confirm the update worked
const verification = await mcp__ravenna__workflowConfig__getStep({
  workflowId: "wf_XXX",
  workspaceId: "workspace-id",
  stepId: "step-to-update",
  suggestions: true
});

// Check that references exist
const referencesValid = [ticketIdRef.referenceId, userMentionRef.referenceId].every(ref =>
  verification.suggestions.some(s => s.referenceId === ref)
);

if (!referencesValid) {
  console.error("❌ Invalid references detected!");
  // Fix before proceeding
} else {
  console.log("✅ All references verified, safe to proceed");
}
```

### Example: The WRONG Way (Never Do This!)

```javascript
// ❌ WRONG - Making assumptions without verification
await mcp__ravenna__workflow__updateStep({
  inputs: {
    ticketId: "jp:$.trigger.input.ticketId",  // Used .input instead of .output!
    comment: "{{@jp:$.trigger.output.ticket.requester.managerId}}"  // managerId doesn't have userMention!
  }
});

// ❌ WRONG - Updating multiple steps without verification
await updateStep1({ ... });  // What if this failed?
await updateStep2({ ... });  // What if step1 had wrong references?
await updateStep3({ ... });  // Now 3 steps have the same error!
```

**Remember: Verify BEFORE. Update ONCE. Verify AFTER. Move FORWARD.**

---

## Prerequisites

### Required Tools
- `mcp__ravenna__workflow__create` - Create new workflow
- `mcp__ravenna__workflow__addStep` - Add steps to workflow
- `mcp__ravenna__workflow__updateStep` - Update existing steps
- `mcp__ravenna__workflow__connectSteps` - Connect steps (rarely needed)
- `mcp__ravenna__workflow__updateConnection` - Update connection labels
- `mcp__ravenna__workflow__disconnectSteps` - Remove connections
- `mcp__ravenna__workflow__deleteSteps` - Delete steps
- `mcp__ravenna__workflow__repositionStep` - Move steps in hierarchy
- `mcp__ravenna__workflow__activate` - Activate workflow
- `mcp__ravenna__workflowConfig__getForWorkflow` - Get workflow structure
- `mcp__ravenna__workflowConfig__getStep` - Get step details with suggestions (🔴 CRITICAL TOOL!)
- `mcp__ravenna__workflowConfig__listApps` - List available actions

### Context Gathering
Before starting, gather:
1. **Workspace ID** - Use `mcp__ravenna__workspace__list` and filter by name
2. **Organization ID** - Obtained from workspace details
3. **Available Actions** - Use `mcp__ravenna__workflowConfig__listApps`
4. **Required Tags** - `mcp__ravenna__ticketTags__list/create`
5. **Status IDs** - `mcp__ravenna__ticketStatus__list` (workspace-specific!)

---

## Critical Concepts

### 1. Placeholder Steps & Conditionals

**The Rule:** Adding conditional/wait actions creates **multiple steps** automatically.

```javascript
// You add ONE step:
mcp__ravenna__workflow__addStep({
  action: "AITicketConditionalAction",
  // ... other params
})

// But the system creates THREE steps:
// 1. The conditional step itself (root)
// 2. step_left_XXX - "On Success" placeholder (for true branch)
// 3. step_right_XXX - "On Failure" placeholder (for false branch)
```

**Actions that create placeholder steps:**
- `IfElseAction` → `left` (true), `right` (false)
- `AITicketConditionalAction` → `left` (true), `right` (false)
- `WaitForApprovalAction` → `center` (approved), `left` (declined), `right` (timeout)

**Structure:**
```
IfElseAction / AITicketConditionalAction:
Root Step
├── left placeholder (true branch)
└── right placeholder (false branch)

WaitForApprovalAction:
Root Step
├── center placeholder (approved)
├── left placeholder (declined)
└── right placeholder (timeout)
```

**Best Practice: After adding conditionals, immediately fetch the workflow:**
```javascript
const workflowState = await mcp__ravenna__workflowConfig__getForWorkflow({
  id: "workflow-id",
  workspaceId: "workspace-id"
})

// Find placeholders by groupId and identifier
const conditionalStep = workflowState.steps.find(s => s.id === "your-conditional-id");
const groupId = conditionalStep.metadata.groupId;

const trueBranch = workflowState.steps.find(s =>
  s.metadata.groupId === groupId && s.metadata.identifier === "left"
);
const falseBranch = workflowState.steps.find(s =>
  s.metadata.groupId === groupId && s.metadata.identifier === "right"
);
```

**✅ RECOMMENDED: Update Placeholders Directly**
```javascript
// Replace the placeholder action with your actual action
await mcp__ravenna__workflow__updateStep({
  workflowId: "wf_XXX",
  workspaceId: "workspace-id",
  id: trueBranch.id,  // The placeholder step ID
  action: "RavAddsTicketTagAction",  // Replace PlaceholderAction
  title: "Add Success Tag",
  inputs: {
    tagIds: ["tag-id"],
    ticketId: "jp:$.trigger.output.ticketId"
  }
});
```

This creates cleaner workflow structure with fewer nested steps!

---

### 2. Field References - Complete Guide

All field references must use the `jp:$.stepId.output.fieldName` format. Never guess these - always get them from suggestions!

#### Rule A: `.input` vs `.output` - The Perspective

**🔴 CRITICAL DISTINCTION:**
- A step references **its own data** using `.input`
- **Other steps reference that step's data** using `.output`

**You almost always want `.output` when referencing other steps!**

```javascript
// ❌ WRONG - Using .input from another step's perspective
{
  ticketId: "jp:$.trigger.input.ticketId"  // FAILS!
}

// ✅ CORRECT - Using .output
{
  ticketId: "jp:$.trigger.output.ticketId"  // WORKS!
}
```

**Best Practice:** Always fetch suggestions from the **consumer step's perspective**, not the source step.

#### Rule B: Synthetic Fields Are Preferred

When suggestions show both a direct field and a synthetic field (prefixed with `synthetic-`), **ALWAYS use the synthetic field**.

```javascript
// Suggestions show TWO options:
[
  {
    referenceId: "jp:$.trigger.output.ticket.requester.Okta.managerId"  // ❌ Avoid
  },
  {
    key: "synthetic-...",
    referenceId: "jp:$.trigger.output.ticket.requester.Okta.manager.id"  // ✅ Use this!
  }
]
```

**Why?**
- More normalized structure (`.manager.id` vs `.managerId`)
- Access to nested object (`.manager.email`, `.manager.firstName`)
- Future-proof and platform-recommended

#### Rule C: User Mentions Require `.userMention`

The `{{@...}}` mention syntax **ONLY works** with fields ending in `.userMention`.

```javascript
// ✅ Works - Has .userMention
"{{@jp:$.trigger.output.ticket.requester.userMention}}"

// ❌ Fails - Manager fields don't have .userMention
"{{@jp:$.trigger.output.ticket.requester.Okta.manager.id}}"
```

**For fields without `.userMention`, use HTML format:**
```html
<span data-type="mention" class="mention" data-id="{{jp:$.trigger.output.ticket.requester.Okta.manager.id}}" data-label="{{jp:$.trigger.output.ticket.requester.Okta.manager.firstName}} {{jp:$.trigger.output.ticket.requester.Okta.manager.lastName}}">@{{jp:$.trigger.output.ticket.requester.Okta.manager.firstName}} {{jp:$.trigger.output.ticket.requester.Okta.manager.lastName}}</span>
```

#### Rule D: Text vs Select Field Wrapping

Different field types require different formats:

| Field Type | Format | Example |
|------------|--------|---------|
| `text`, `textarea`, `richtexteditor` | Wrapped in `{{}}` | `{{jp:$.step.output.url}}` |
| `select`, `multiselect` | Direct, no wrapping | `jp:$.step.output.ticketId` |
| Filter values | Wrapped in `{{}}` | `{{jp:$.step.output.value}}` |

```javascript
// ✅ CORRECT
{
  "ticketId": "jp:$.loop.output.item.id",  // Select field - no wrapping
  "url": "{{jp:$.trigger.output.prUrl}}",  // Text field - wrapped
  "name": "PR #{{jp:$.trigger.output.prNumber}}: {{jp:$.trigger.output.prTitle}}"  // Text with interpolation
}
```

#### Rule E: Common Reference Patterns

```javascript
// Basic fields
jp:$.stepId.output.ticketId
jp:$.stepId.output.isSuccess
jp:$.stepId.output.isApproved

// Ticket object
jp:$.stepId.output.ticket.id
jp:$.stepId.output.ticket.title
jp:$.stepId.output.ticket.requesterId
jp:$.stepId.output.ticket.assigneeId

// Form fields (JSONPath)
jp:$.stepId.output.ticket.requestType.{formId}.{fieldId}
jp:$.stepId.output.ticket.requestType.{formId}.{fieldId}.name

// Loop data
jp:$.loopStep.output.item
jp:$.loopStep.output.item.id
jp:$.loopStep.output.loop.size
jp:$.loopStep.output.loop.limit

// User mentions
jp:$.stepId.output.ticket.requester.userMention
jp:$.stepId.output.ticket.assignee.userMention
```

#### Rule F: Get Status/Tag IDs from Suggestions

**Never hardcode IDs - they vary per workspace!**

```javascript
// Get step with suggestions
const stepInfo = await mcp__ravenna__workflowConfig__getStep({
  stepId: "your-step-id",
  suggestions: true
});

// Parse selectOptions for statuses/tags
const statusInput = stepInfo.action.inputs.find(input => input.key === "statusId");
const statusOptions = statusInput.selectOptions;
// Example: [{label: "Done", value: "cmhaojczx0019mr3jzv6kwmkk"}, ...]
```

---

### 3. filterGroups - The Power Tool

**filterGroups** serve TWO purposes:

**Purpose 1: Filter Which Tickets Trigger the Workflow**
```javascript
{
  "action": "RavTicketCreatedTrigger",
  "inputs": {
    "filterGroups": [[{
      "field": "jp:$.input.ticket.requestType.{formId}.{fieldId}.approverIds",
      "value": null,
      "condition": "not_null"
    }]]
  }
}
```

**Purpose 2: Conditionally Execute Action Steps**
```javascript
{
  "action": "RavTicketMessageAddAction",
  "inputs": {
    "comment": "Success message",
    "filterGroups": [[{
      "field": "jp:$.trigger.output.ticket.requestType.{formId}.{fieldId}.provisioningMethod",
      "value": "group",
      "condition": "equals"
    }]]
  }
}
```

**Logic:**
- **Within a filter group** (inner array): Conditions are AND'd together (all must be true)
- **Between filter groups** (outer array): Groups are OR'd together (any group can pass)

```javascript
{
  "filterGroups": [
    [  // Group 1: requester is owner
      {"field": "...", "value": ["..."], "condition": "in"}
    ],
    [  // Group 2: requester is manager
      {"field": "...", "value": ["..."], "condition": "in"}
    ]
  ]
  // Passes if Group 1 OR Group 2 is satisfied
}
```

**Common Conditions:**
- `equals` - Exact match
- `not_equals` - Does not match
- `not_null` - Field has value
- `null` - Field is empty
- `contains` - String contains substring
- `in` - Value is in array

---

### 4. Other Critical Gotchas

#### Don't Trust Error Messages
API calls may return errors, but the operation might have succeeded. **Always fetch the latest workflow state** after operations that return errors before retrying.

#### Always Connect Before Deleting
When restructuring, create new connections first, verify, then delete orphaned steps. Prevents broken workflows.

#### Wait 1s After Adding Approvers
```javascript
// Step 1: Add approvers
await addStep({ action: "RavAddTicketApproversAction", ... });

// Step 2: ALWAYS wait 1s
await addStep({ action: "WaitAction", inputs: { duration: "1s" } });

// Step 3: Now wait for approval
await addStep({ action: "WaitForApprovalAction", ... });
```

#### Always Specify `sourceId`
Except for the first trigger step, **every step needs a `sourceId`** to connect it to the workflow. Missing `sourceId` creates disconnected root steps.

---

## Workflow Building Process

### Phase 1: Discovery

#### 1. List Available Actions
```javascript
mcp__ravenna__workflowConfig__listApps({
  workspaceId: "workspace-id"
})
```

**Key Action Categories:**
- **Triggers**: `RavTicketCreatedTrigger`, `RavTicketFormSubmittedTrigger`, `ai-prompt-trigger`, `CronAction`
- **Ticket Actions**: `RavAddsTicketTagAction`, `RavSetTicketStatusAction`, `RavTicketMessageAddAction`, `RavTicketUpdateAction`
- **User Actions**: `RavAddTicketApproversAction`, `RavSetTicketAssigneeAction`
- **Conditionals**: `IfElseAction`, `AITicketConditionalAction`, `ai-prompt`
- **Wait Actions**: `WaitAction`, `WaitForApprovalAction`, `WaitForMessageAction`, `RavTicketMessageMonitor`
- **Control Flow**: `RavGotoAction`, `LoopAction`, `EndLoopAction`, `RavSearchTicketsAction`
- **Integrations**: Okta, Google Workspace, Slack, Email actions
- **Monitoring**: `RavTicketMessageTrigger`, `RavTicketMessageMonitor`

#### 2. Gather Context
- **Tags** → `mcp__ravenna__ticketTags__list/create`
- **Statuses** → `mcp__ravenna__ticketStatus__list` (workspace-specific!)
- **Forms** → `mcp__ravenna__list_forms`
- **Custom Fields** → Appropriate list endpoints

### Phase 2: Creation

#### 1. Create Workflow
```javascript
const workflow = await mcp__ravenna__workflow__create({
  name: "Workflow Name",
  description: "Clear description",
  workspaceId: "workspace-id"
})
// Returns: { id: "wf_XXXXXXXXX", state: "Draft", ... }
```

#### 2. Add Trigger
```javascript
const trigger = await mcp__ravenna__workflow__addStep({
  workflowId: workflow.id,
  workspaceId: "workspace-id",
  title: "Ticket Created",
  action: "RavTicketCreatedTrigger",
  inputs: {
    organizationId: "org-id",
    workspaceId: "workspace-id",
    requestTypeIds: ["form-id"]  // Optional: filter to specific forms
  }
})
```

#### 3. Add Subsequent Steps
**🔴 CRITICAL: Always specify `sourceId` to connect steps!**

```javascript
await mcp__ravenna__workflow__addStep({
  workflowId: workflow.id,
  workspaceId: "workspace-id",
  title: "Step Title",
  action: "ActionName",
  sourceId: trigger.id,  // Connect to previous step
  inputs: {
    // 🔴 Get field references from suggestions!
  }
})
```

---

## Production Patterns

### Pattern 1: Simple Automated Provisioning
```
Trigger (Form Submitted)
  ↓
IfElse (Automated provisioning available?)
  ├─ TRUE:
  │   → Add User to Okta Group
  │   → Send Success Message
  │   → Set Status (Done)
  └─ FALSE:
      → Send "Manual Required" Message
      → Set Status (Waiting)
```

### Pattern 2: Approval-Based Workflow
```
Trigger
  ↓
Add Approvers
  ↓
Wait (1s)  ← 🔴 Required!
  ↓
Wait for Approval (3d)
  ├─ APPROVED:
  │   → Provision Access
  │   → Success Message
  │   → Status: Done
  ├─ DECLINED:
  │   → Declined Message
  │   → Status: Archived
  └─ TIMEOUT:
      → Timeout Message
      → Status: Archived
```

### Pattern 3: Manual Provisioning with Retry Loop
```
Trigger
  ↓
Add Owner as Approver
  ↓
Wait for Approval
  ├─ APPROVED:
  │   → Send "Please provision" (mention owner)
  │   → Wait for Message (3d)
  │   → AI: "Is it provisioned?"
  │     ├─ TRUE: → Status: Done
  │     └─ FALSE:
  │         → AI: "Need help?"
  │           ├─ TRUE: → Escalate to IT
  │           └─ FALSE:
  │               → Goto Wait (budget: 3)
  │                 → On Limit: Escalate to IT
  └─ DECLINED:
      → Status: Archived
```

### Pattern 4: Parent-Child Ticket Linking
```
Trigger (Child Ticket Created)
  ↓
AI: Extract employee data
  ↓
Search for Parent (by email)
  ├─ Found?
  │   ├─ TRUE: → Loop (limit: 1) → Link Parent
  │   └─ FALSE:
  │       → Search by Personal Email
  │         ├─ Found? → Link
  │         └─ Not Found?
  │             → Search by Name
  │               ├─ Found? → Link
  │               └─ Not Found? → Assign to IT
```

### Pattern 5: Stale Ticket Detection
```
RavTicketMessageTrigger (any message)
  ↓
RavTicketMessageMonitor (10d inactivity)
  ↓
RavSearchTicketsAction (get latest state)
  ↓
Loop (limit: 1)
  ↓
IfElse (Has assignee?)
  ├─ TRUE: → Slack DM to assignee
  └─ FALSE: → Slack channel notification
```

### Pattern 6: Scheduled Batch Operations
```
CronAction (daily 23:59 UTC)
  ↓
AI: Calculate target date
  ↓
RavSearchTicketsAction (find overdue tickets)
  ↓
Loop (limit: 50)
  ↓
  → Send notification
  → Update status
  ↓
EndLoop
```

### Pattern 7: Webhook Integration
```
External System → POST to webhook
  ↓
ai-prompt-trigger (extract fields)
  ↓
RavTicketCreateAction (use extracted data)
  ↓
Process ticket (tag, assign, notify)
```

### Pattern 8: Permission-Based Execution
```
Trigger
  ↓
Get Resource Info (e.g., Google Group)
  ├─ Found?
      ├─ TRUE:
      │   → IfElse: Requester is Owner OR Manager?
      │       ├─ TRUE: → Execute → Success
      │       └─ FALSE: → Deny message
      └─ FALSE:
          → "Not found" message
```

---

## Advanced Workflows

### Loop Pattern with RavGotoAction

```javascript
// Step 1: Wait for message
const waitStep = await addStep({
  action: "WaitForMessageAction",
  inputs: {
    duration: "3d",
    userIds: ["jp:$.trigger.output.ticket.ownerId"],
    ticketId: "jp:$.trigger.output.ticketId"
  }
});

// Step 2: AI check
const aiCheck = await addStep({
  sourceId: waitStep.id,
  action: "AITicketConditionalAction",
  inputs: {
    ticketId: "jp:$.trigger.output.ticketId",
    description: "Does the message confirm access was provisioned?"
  }
});

// Fetch workflow and find placeholders
const workflow = await getWorkflow();
const groupId = workflow.steps.find(s => s.id === aiCheck.id).metadata.groupId;
const confirmed = workflow.steps.find(s =>
  s.metadata.groupId === groupId && s.metadata.identifier === "left"
);
const notConfirmed = workflow.steps.find(s =>
  s.metadata.groupId === groupId && s.metadata.identifier === "right"
);

// Step 3a: If confirmed → Done
await addStep({
  sourceId: confirmed.id,
  action: "RavSetTicketStatusAction",
  inputs: {
    statusId: "done-status-id",
    ticketId: "jp:$.trigger.output.ticketId"
  }
});

// Step 3b: If not confirmed → Loop back with budget
const gotoStep = await addStep({
  sourceId: notConfirmed.id,
  action: "RavGotoAction",
  inputs: {
    stepId: waitStep.id,  // Loop back
    budget: 3  // Max 3 retries
  }
});

// Step 4: Handle limit reached → Escalate
await addStep({
  sourceId: gotoStep.id,  // Special "On Limit Reached" connection
  action: "RavSetTicketStatusAction",
  inputs: {
    statusId: "escalated-status-id",
    ticketId: "jp:$.trigger.output.ticketId"
  }
});
```

**Key Points:**
- `budget` limits number of loops
- Always handle the "On Limit Reached" branch
- Prevents infinite loops

### Loop/EndLoop Pattern

```javascript
// Step 1: Search for tickets
const search = await addStep({
  action: "RavSearchTicketsAction",
  inputs: {
    ticketFilter: [[
      {"field": "title", "value": "ONB_1", "condition": "contains"}
    ]]
  }
});

// Step 2: Start loop
const loop = await addStep({
  sourceId: search.id,
  action: "LoopAction",
  inputs: {
    limit: 50,  // Max iterations
    collection: ["jp:$.{search.id}.output.ticketIds"]
  }
});

// Step 3: Process each item
await addStep({
  sourceId: loop.id,
  action: "RavTicketUpdateAction",
  inputs: {
    ticketId: "jp:$.{loop.id}.output.item.id",  // Current item
    statusId: "new-status-id"
  }
});

// Step 4: End loop
await addStep({
  action: "EndLoopAction",
  inputs: {
    limit: "jp:$.{loop.id}.output.loop.limit"
  }
});
```

**Loop Data Access:**
- `jp:$.loopStep.output.item` - Current item
- `jp:$.loopStep.output.item.id` - Item property
- `jp:$.loopStep.output.loop.size` - Total items
- `jp:$.loopStep.output.loop.limit` - Max iterations

**Use `limit: 1` for single results** (e.g., "get first parent ticket")

### AI-Powered Decisions

```javascript
// Option 1: Check ticket content
{
  "action": "AITicketConditionalAction",
  "inputs": {
    "ticketId": "jp:$.trigger.output.ticketId",
    "description": "Is this ticket requesting software access? Check title and description. Return true if it's a software access request."
  }
}
// Returns: isSuccess = true/false

// Option 2: Interpret messages
{
  "action": "ai-prompt",
  "inputs": {
    "prompt": "Message: {{jp:$.waitStep.output.ticketMessage.message}}\n\nQuestion: Does this confirm password reset? Return TRUE if yes, FALSE if no."
  }
}
// Returns: isSuccess = true/false
```

**Best Practices:**
- Be specific and clear
- Ask yes/no questions
- Provide context
- Use for ambiguous situations

---

## Ticket Search & Parent-Child Relationships

### RavSearchTicketsAction

```javascript
{
  "action": "RavSearchTicketsAction",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "ticketFilter": [[
      {"field": "title", "value": "ONB_1", "condition": "contains"},
      {"field": "statusId", "value": ["done-id", "archived-id"], "condition": "not_in"}
    ]]
  }
}
// Returns: ticketIds (array)
```

**Common Filter Conditions:**
- `equals`, `not_equals`, `contains`, `not_contains`
- `in`, `not_in`
- `lte`, `gte` (for dates)
- `j_equals`, `j_not_null` (for custom fields with JSONPath)

**JSONPath for Custom Fields:**
```javascript
{
  "field": "[\"requestTypeId:formId\",\"customFields.path[0]:fieldId\",\"customFields\"]",
  "value": "search-value",
  "condition": "j_equals"
}
```

**Multiple Filter Groups = OR Logic:**
```javascript
{
  "ticketFilter": [
    [  // Group 1
      {"field": "title", "value": "ONB", "condition": "contains"}
    ],
    [  // Group 2
      {"field": "assigneeId", "value": "user-id", "condition": "equals"}
    ]
    // Matches Group 1 OR Group 2
  ]
}
```

### Creating Parent-Child Relationships

```javascript
{
  "action": "RavTicketUpdateAction",
  "inputs": {
    "ticketId": "child-ticket-id",
    "parentTicketId": "parent-ticket-id",
    "workspaceId": "...",
    "organizationId": "..."
  }
}
```

**Complete Pattern: Find and Link Parent**

```javascript
// Search → Loop (limit: 1) → Link

// Step 1: Search
const search = await addStep({
  action: "RavSearchTicketsAction",
  inputs: {
    ticketFilter: [[
      {"field": "title", "value": "ONB_1", "condition": "contains"},
      {"field": "[\"requestTypeId:formId\",\"customFields.email:fieldId\",\"customFields\"]",
       "value": "jp:$.extractStep.output.outputs.EmployeeEmail",
       "condition": "j_equals"}
    ]]
  }
});

// Step 2: Loop first result
const loop = await addStep({
  sourceId: search.id,
  action: "LoopAction",
  inputs: {
    limit: 1,  // Only first match
    collection: ["jp:$.{search.id}.output.ticketIds"]
  }
});

// Step 3: Link parent
await addStep({
  sourceId: loop.id,
  action: "RavTicketUpdateAction",
  inputs: {
    ticketId: "jp:$.trigger.output.ticketId",
    parentTicketId: "jp:$.{loop.id}.output.item.id"
  }
});

// Step 4: End loop
await addStep({
  action: "EndLoopAction",
  inputs: {
    limit: "jp:$.{loop.id}.output.loop.limit"
  }
});
```

---

## Scheduled Workflows & Monitoring

### CronAction

```javascript
{
  "action": "CronAction",
  "inputs": {
    "timezone": "UTC",
    "cronExpression": "59 23 * * *"  // Daily at 23:59 UTC
  }
}
```

**Common Cron Patterns:**
| Expression | Schedule |
|-----------|----------|
| `0 9 * * *` | Daily at 9 AM |
| `0 */6 * * *` | Every 6 hours |
| `0 9 * * 1` | Every Monday at 9 AM |
| `59 23 * * *` | Daily at 11:59 PM |
| `0 9 * * 1-5` | Weekdays at 9 AM |

### RavTicketMessageMonitor

**Waits for ABSENCE of messages** (inactivity detection).

```javascript
{
  "action": "RavTicketMessageMonitor",
  "inputs": {
    "duration": "10d",  // 10 days of NO activity
    "ticketId": "jp:$.trigger.output.ticket.id",
    "workspaceId": "...",
    "organizationId": "..."
  }
}
```

**🔴 CRITICAL: Always search after monitor** - Ticket state may have changed during the wait period!

```javascript
// Trigger → Monitor → Search → Loop → Notify

RavTicketMessageTrigger
  ↓
RavTicketMessageMonitor (10d)
  ↓
RavSearchTicketsAction (get latest state)
  ↓
Loop (limit: 1)
  ↓
IfElse (Has assignee?)
  ├─ TRUE: SlackSendDmMessageAction
  └─ FALSE: SlackSendChannelMessageAction
```

---

## Webhook Integration

### ai-prompt-trigger

Creates webhook endpoint with AI field extraction.

```javascript
{
  "action": "ai-prompt-trigger",
  "inputs": {
    "prompt": "Extract the following values from the payload:\nuserEmail\nusername\nentitlementName",
    "httpStatusCode": "202",  // Recommended for async processing
    "workspaceId": "...",
    "organizationId": "..."
  }
}
// Generates directUrl: "https://core.ravenna.ai/api/workflows/run?token=..."
```

**How It Works:**
1. Trigger generates unique `directUrl`
2. External system POSTs data to URL
3. AI extracts fields based on prompt
4. Access fields: `jp:$.trigger.output.outputs.{fieldName}`

**Example:**
```javascript
// Step 1: Webhook trigger
const trigger = await addStep({
  action: "ai-prompt-trigger",
  inputs: {
    prompt: "Extract:\nuserEmail\nappName\naccessLevel"
  }
});

// Step 2: Create ticket with extracted data
await addStep({
  sourceId: trigger.id,
  action: "RavTicketCreateAction",
  inputs: {
    title: "Access Request: {{jp:$.trigger.output.outputs.appName}} for {{jp:$.trigger.output.outputs.userEmail}}",
    description: "Level: {{jp:$.trigger.output.outputs.accessLevel}}"
  }
});
```

---

## Notifications

### Email
```javascript
{
  "action": "SendEmailAction",
  "inputs": {
    "subject": "Ticket requires attention",
    "userIds": ["user-id-1", "user-id-2"],  // Internal users
    "ticketId": "jp:$.trigger.output.ticketId",
    "description": "Email body",
    "emailAddresses": "external@company.com"  // Optional: external
  }
}
```

### Slack DM
```javascript
{
  "action": "SlackSendDmMessageAction",
  "inputs": {
    "message": "Your ticket has been stale for 10 days.",
    "slackUserIds": ["jp:$.trigger.output.ticket.assignee.id"],
    "slackAppId": "slack-app-id"
  }
}
```

### Slack Channel
```javascript
{
  "action": "SlackSendChannelMessageAction",
  "inputs": {
    "message": "New unassigned ticket: {{jp:$.trigger.output.ticket.title}}",
    "slackChannelId": "channel-id",
    "slackAppId": "slack-app-id",
    "slackIsEphemeral": false
  }
}
```

**Notification Strategy:**
| Scenario | Channel | Action |
|----------|---------|--------|
| Has assignee | Slack DM | `SlackSendDmMessageAction` |
| No assignee | Slack Channel | `SlackSendChannelMessageAction` |
| External stakeholder | Email | `SendEmailAction` |
| Audit trail | In-ticket | `RavTicketMessageAddAction` |

---

## Common Actions Quick Reference

### Triggers
- `RavTicketCreatedTrigger` - When any ticket created
- `RavTicketFormSubmittedTrigger` - When specific form submitted
- `RavTicketMessageTrigger` - When any message sent
- `ai-prompt-trigger` - Webhook with AI extraction
- `CronAction` - Scheduled execution

### Ticket Actions
- `RavAddsTicketTagAction` - Add tags
- `RavSetTicketStatusAction` - Change status
- `RavTicketMessageAddAction` - Post message
- `RavTicketUpdateAction` - Update properties/custom fields/parent
- `RavSetTicketAssigneeAction` - Assign ticket
- `RavAddTicketApproversAction` - Add approvers
- `RavTicketImportTaskTemplateAction` - Import checklist

### Conditionals
- `IfElseAction` - Rule-based (filterGroups)
- `AITicketConditionalAction` - AI evaluation
- `ai-prompt` - AI with custom prompt

### Wait Actions
- `WaitAction` - Simple delay
- `WaitForApprovalAction` - Wait for approval (3 branches)
- `WaitForMessageAction` - Wait for message from users
- `RavTicketMessageMonitor` - Wait for inactivity

### Control Flow
- `RavGotoAction` - Loop with budget
- `LoopAction` / `EndLoopAction` - Iterate collections
- `RavSearchTicketsAction` - Search with filters

### Integrations
- **Okta**: `OktaAddUserToGroupAction`, `OktaResetMFAPasswordAction`
- **Google**: `GoogleGetGroupInfoAction`, `GoogleAddUserToGroupAction`, `GoogleRemoveUserFromGroupAction`, `GoogleCheckEmailAvailabilityAction`

---

## Production Checklist

### Before Building
- [ ] Get workspace and organization IDs
- [ ] List available actions
- [ ] Get/create required tags
- [ ] Get status IDs (workspace-specific!)
- [ ] Identify form IDs if needed
- [ ] Diagram workflow logic

### During Building
- [ ] Create workflow in Draft
- [ ] 🔴 VERIFY field references before each step
- [ ] Add trigger with optional filterGroups
- [ ] **Fetch after adding conditionals/wait actions**
- [ ] Find placeholders by groupId + identifier
- [ ] Update placeholders directly (recommended)
- [ ] Get all references from suggestions (set to true!)
- [ ] Use `.output` not `.input` when referencing other steps
- [ ] Prefer synthetic fields when available
- [ ] Check if `.userMention` exists before using `{{@...}}`
- [ ] Wrap text fields in `{{}}`, use direct refs for select fields
- [ ] 🔴 VERIFY after each step update
- [ ] Handle ALL branches (left/right for IfElse, center/left/right for Approval)
- [ ] Add 1s wait after adding approvers
- [ ] Set budget on RavGotoAction loops
- [ ] Always search after monitors (get fresh state)
- [ ] Include status transitions and escalation paths

### Before Activating
- [ ] Final verification fetch
- [ ] Review all connections
- [ ] Test with real test ticket
- [ ] Verify all branches execute
- [ ] Check messages/notifications
- [ ] Confirm status transitions
- [ ] Document workflow

### After Activating
- [ ] Monitor first executions
- [ ] Check for errors
- [ ] Verify notifications
- [ ] Collect feedback

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Multiple start steps error | Added step without `sourceId` | Always specify `sourceId` except for trigger |
| Fields not interpolating | Wrong reference format | Get exact `referenceId` from suggestions |
| Conditional not working | Adding to root instead of placeholders | Fetch workflow, find placeholders, add to those |
| No timeout branch | Didn't fetch after WaitForApprovalAction | Fetch workflow to find all 3 placeholders |
| Loop never stops | No budget on RavGotoAction | Always set `budget` and handle "On Limit Reached" |
| Wrong status/tag ID | Hardcoded from another workspace | Get IDs from suggestions dynamically |
| Operation "failed" but worked | Backend inconsistency | Fetch latest state before assuming failure |
| filterGroups not working | Wrong field path | Get exact paths from suggestions |
| Integration failing | Resource doesn't exist / no permissions | Validate resource first, handle `isSuccess = false` |

---

## Key Takeaways

1. **🔴🔴🔴 VERIFY BEFORE. UPDATE ONCE. VERIFY AFTER. MOVE FORWARD.**
2. Always fetch after conditionals - they create hidden placeholders
3. Update placeholders directly with `updateStep` - cleaner structure
4. Use `.output` not `.input` when referencing other steps
5. Prefer synthetic fields (`.manager.id` not `.managerId`)
6. User mentions need `.userMention` field or HTML format
7. Text fields need `{{}}`, select fields don't
8. filterGroups: AND within groups, OR between groups
9. Handle ALL branches (left/right for IfElse, center/left/right for Approval)
10. Status IDs vary per workspace - get from suggestions
11. Wait 1s after adding approvers
12. Set budget on loops, handle limit reached
13. Always search after monitors (get fresh state)
14. Test before activating

---

## Conclusion

Building production-ready Ravenna workflows requires:
1. **Religiously following the verification workflow** (most important!)
2. Understanding automatic placeholder creation
3. Using correct field reference formats from suggestions
4. Proper error handling and escalation
5. Testing before activation

**Remember: Verification takes 10 seconds. Fixing runtime errors takes hours.**

Follow these patterns and you'll build reliable, maintainable workflows that handle edge cases gracefully!
