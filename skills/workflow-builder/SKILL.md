# Ravenna Workflow Building Guide
**Production Edition - Updated with Real-World Patterns from IT Workspace**

## Overview
This guide provides comprehensive instructions for building production-ready workflows in Ravenna, including critical gotchas, best practices, and proven patterns from active production workflows.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Workflow Building Process](#workflow-building-process)
3. [Critical Learnings](#critical-learnings)
4. [Production Patterns](#production-patterns)
5. [Advanced Patterns](#advanced-patterns)
6. [Loops and Iteration](#loops-and-iteration)
7. [Ticket Search Patterns](#ticket-search-patterns)
8. [Parent-Child Tickets](#parent-child-tickets)
9. [Scheduled Workflows](#scheduled-workflows)
10. [Monitoring and Alerting](#monitoring-and-alerting)
11. [Webhook Integration](#webhook-integration)
12. [Email and Slack Notifications](#email-and-slack-notifications)
13. [Task Templates](#task-templates)
14. [Step-by-Step Examples](#step-by-step-examples)
15. [Common Action Types](#common-action-types)
16. [Troubleshooting](#troubleshooting)
17. [Production Checklist](#production-checklist)

---

## Prerequisites

### Required Tools
- `mcp__ravenna__workflow__create` - Create new workflow
- `mcp__ravenna__workflow__addStep` - Add steps to workflow
- `mcp__ravenna__workflow__updateStep` - Update existing steps
- `mcp__ravenna__workflow__connectSteps` - Connect steps (rarely needed directly)
- `mcp__ravenna__workflow__updateConnection` - Update connection labels
- `mcp__ravenna__workflow__disconnectSteps` - Remove connections
- `mcp__ravenna__workflow__deleteSteps` - Delete steps
- `mcp__ravenna__workflow__repositionStep` - Move steps in hierarchy
- `mcp__ravenna__workflow__activate` - Activate workflow
- `mcp__ravenna__workflowConfig__getForWorkflow` - Get workflow structure
- `mcp__ravenna__workflowConfig__getStep` - Get step details with suggestions
- `mcp__ravenna__workflowConfig__listApps` - List available actions

### Context Gathering
Before starting, gather:
1. **Workspace ID** - Use `mcp__ravenna__workspace__list` and filter by name
2. **Organization ID** - Obtained from workspace details
3. **Available Actions** - Use `mcp__ravenna__workflowConfig__listApps` to see what's possible
4. **Required Tags** - List or create tags via `mcp__ravenna__ticketTags__list/create`
5. **Status IDs** - Get from `mcp__ravenna__ticketStatus__list` (workspace-specific!)

---

## Workflow Building Process

### Phase 1: Discovery

#### 1.1 List Available Actions
```javascript
// Get all available actions for the workspace
mcp__ravenna__workflowConfig__listApps({
  workspaceId: "workspace-id-here"
})
```

**Key Action Types:**
- **Trigger** - Starts the workflow
  - `RavTicketCreatedTrigger` - When any ticket is created
  - `RavTicketFormSubmittedTrigger` - When specific form submitted
  - `RavTicketStatusChangedTrigger` - When status changes
  - `RavTicketAssignedTrigger` - When ticket assigned
  - `ai-prompt-trigger` - Webhook endpoint with AI field extraction
  - `RavTicketMessageTrigger` - When any message is sent to any ticket
  - `CronAction` - Scheduled execution (cron-based)

- **Activity** - Performs actions
  - Ticket Actions: `RavAddsTicketTagAction`, `RavSetTicketStatusAction`, `RavTicketMessageAddAction`, `RavTicketUpdateAction`, `RavTicketImportTaskTemplateAction`
  - User Actions: `RavAddTicketApproversAction`, `RavSetTicketAssigneeAction`
  - Integration Actions: `OktaAddUserToGroupAction`, `GoogleAddUserToGroupAction`, `GoogleCheckEmailAvailabilityAction`, `GoogleCreateEmailAliasAction`
  - Messaging Actions: `SendEmailAction`, `SlackSendDmMessageAction`, `SlackSendChannelMessageAction`

- **Conditional** - Makes decisions
  - `IfElseAction` - Rule-based conditional on field values
  - `AITicketConditionalAction` - AI-powered decision on ticket content
  - `ai-prompt` - AI evaluation of custom prompts

- **Wait** - Pause execution
  - `WaitAction` - Simple delay
  - `WaitForApprovalAction` - Wait for approval (3 branches!)
  - `WaitForMessageAction` - Wait for message from specific users
  - `RavTicketMessageMonitor` - Wait for a period of inactivity on a ticket

- **Control Flow** - Advanced patterns
  - `RavGotoAction` - Loop/retry with budget limit
  - `LoopAction` / `EndLoopAction` - Iterate over collections (arrays)
  - `RavSearchTicketsAction` - Search for tickets with complex filters

#### 1.2 Understand Dependencies
For your workflow, identify:
- **Tags** → `mcp__ravenna__ticketTags__list` and `mcp__ravenna__ticketTags__create`
- **Statuses** → `mcp__ravenna__ticketStatus__list` (IDs are workspace-specific!)
- **Forms** → `mcp__ravenna__list_forms` if using form-based triggers
- **Custom Fields** → Use appropriate list endpoints

### Phase 2: Creation

#### 2.1 Create the Workflow
```javascript
mcp__ravenna__workflow__create({
  name: "Workflow Name",
  description: "Clear description of what it does",
  workspaceId: "workspace-id"
})
```

**Response includes:**
- `id` - Workflow ID (format: `wf_XXXXXXXXX`)
- `state` - Initially "Draft"

#### 2.2 Add the Trigger

**Option A: Simple Ticket Created Trigger**
```javascript
mcp__ravenna__workflow__addStep({
  workflowId: "wf_XXXXXXXXX",
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

**Option B: Form-Specific Trigger**
```javascript
mcp__ravenna__workflow__addStep({
  workflowId: "wf_XXXXXXXXX",
  workspaceId: "workspace-id",
  title: "Form Submitted",
  action: "RavTicketFormSubmittedTrigger",
  inputs: {
    organizationId: "org-id",
    workspaceId: "workspace-id",
    formIds: ["specific-form-id"],
    requestTypeIds: ["specific-form-id"]
  }
})
```

**Option C: Trigger with filterGroups (Advanced)**
```javascript
mcp__ravenna__workflow__addStep({
  workflowId: "wf_XXXXXXXXX",
  workspaceId: "workspace-id",
  title: "Ticket Created - Software Access Only",
  action: "RavTicketCreatedTrigger",
  inputs: {
    organizationId: "org-id",
    workspaceId: "workspace-id",
    requestTypeIds: ["form-id"],
    filterGroups: [[{
      field: "jp:$.input.ticket.requestType.{formId}.{fieldId}",
      value: null,
      condition: "not_null"  // Only trigger if field has value
    }]]
  }
})
```

#### 2.3 Add Subsequent Steps
**CRITICAL:** Always specify `sourceId` to connect steps in sequence.

```javascript
mcp__ravenna__workflow__addStep({
  workflowId: "wf_XXXXXXXXX",
  workspaceId: "workspace-id",
  title: "Step Title",
  action: "ActionName",
  sourceId: "parent-step-id", // ID of the previous step
  inputs: {
    // Input fields here
  }
})
```

---

## Critical Learnings

### 🔴🔴🔴 CRITICAL #0: THE GOLDEN RULE - ALWAYS VERIFY BEFORE AND AFTER

**THIS IS THE MOST IMPORTANT RULE. If you only remember one thing, remember this:**

**NEVER make changes to workflow steps without verifying field references first. ALWAYS verify after each change before proceeding to the next.**

#### The Verification Workflow (MANDATORY)

```
For EVERY step you create or update:
1. BEFORE: Get suggestions to find correct field references
2. UPDATE: Make the change using verified references
3. AFTER: Get suggestions again to confirm the change worked
4. ONLY THEN: Proceed to the next step
```

**Why This Matters:**
- Invalid references cause runtime failures that are hard to debug
- Schema shows `.input` but you must use `.output` (see CRITICAL #3a)
- Synthetic fields are preferred but not always obvious (see CRITICAL #3b)
- User mentions have special requirements (see CRITICAL #3c)
- Making the same mistake across multiple steps wastes time and API calls

#### Example: The CORRECT Way

```javascript
// Step 1: VERIFY - Get suggestions for the step you're about to update
const stepSuggestions = await mcp__ravenna__workflowConfig__getStep({
  workflowId: "wf_XXX",
  workspaceId: "workspace-id",
  stepId: "step-to-update",
  suggestions: true  // CRITICAL!
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
    ticketId: ticketIdRef.referenceId,  // Verified!
    comment: "{{@" + userMentionRef.referenceId + "}} Hello!"  // Verified!
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

#### Example: The WRONG Way (Don't Do This!)

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
await updateStep4({ ... });  // Have to redo all 4!
```

**Remember:**
- Verification takes 10 seconds
- Fixing runtime errors takes hours
- **Verify BEFORE. Update ONCE. Verify AFTER. Move FORWARD.**

---

### 🔴 CRITICAL #1: Always Fetch After Adding Conditional Steps

**Why:** Adding conditionals/wait actions creates **multiple steps** automatically.

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
- `IfElseAction` → Creates `left` and `right` placeholders
- `AITicketConditionalAction` → Creates `left` and `right` placeholders
- `WaitForApprovalAction` → Creates `center` (approved), `left` (declined), `right` (timeout)

**Best Practice:**
```javascript
// After adding conditional step, immediately fetch the workflow
const workflowState = await mcp__ravenna__workflowConfig__getForWorkflow({
  id: "workflow-id",
  workspaceId: "workspace-id"
})

// Examine the "steps" and "connections" arrays to find placeholders
```

### 🔴 CRITICAL #2: Understanding Placeholder Step Structure

**IfElseAction / AITicketConditionalAction:**
```
Root Step (step_XXXXX_YYY)
├── Connection (isSuccess = true) → Left Placeholder (step_left_ZZZ)
└── Connection (isSuccess = false) → Right Placeholder (step_right_AAA)
```

**WaitForApprovalAction:**
```
Root Step (step_XXXXX_YYY)
├── Connection (isApproved = true) → Center Placeholder (step_center_ZZZ)
├── Connection (isApproved = false) → Left Placeholder (step_left_AAA)
└── Connection (isTimedOut = true) → Right Placeholder (step_right_BBB)
```

**How to Find Placeholders:**
```javascript
// After fetching workflow
const workflow = await getWorkflow();

// Find by groupId and identifier
const conditionalStep = workflow.steps.find(s => s.id === "your-conditional-id");
const groupId = conditionalStep.metadata.groupId;

// For IfElse/AIConditional:
const trueBranch = workflow.steps.find(s =>
  s.metadata.groupId === groupId && s.metadata.identifier === "left"
);
const falseBranch = workflow.steps.find(s =>
  s.metadata.groupId === groupId && s.metadata.identifier === "right"
);

// For WaitForApproval:
const approvedBranch = workflow.steps.find(s =>
  s.metadata.groupId === groupId &&
  (s.metadata.identifier === "center" || s.metadata.identifier === "center-placeholder")
);
const declinedBranch = workflow.steps.find(s =>
  s.metadata.groupId === groupId &&
  (s.metadata.identifier === "left" || s.metadata.identifier === "left-placeholder")
);
const timeoutBranch = workflow.steps.find(s =>
  s.metadata.groupId === groupId &&
  (s.metadata.identifier === "right" || s.metadata.identifier === "right-placeholder")
);
```

**How to Use - Two Approaches:**

**❌ Approach A: Add Children (Creates Extra Steps)**
```javascript
// Add action for true/approved branch
await mcp__ravenna__workflow__addStep({
  sourceId: trueBranch.id,  // or approvedBranch.id
  action: "RavAddsTicketTagAction",
  // ...
});

// Add action for false/declined branch
await mcp__ravenna__workflow__addStep({
  sourceId: falseBranch.id,  // or declinedBranch.id
  action: "RavAddsTicketTagAction",
  // ...
});
```

**✅ Approach B: Update Placeholders Directly (RECOMMENDED)**
```javascript
// Update the placeholder step itself - much cleaner!
await mcp__ravenna__workflow__updateStep({
  workflowId: "wf_XXX",
  workspaceId: "workspace-id",
  id: trueBranch.id,  // The placeholder step ID
  action: "RavAddsTicketTagAction",  // Replace placeholder with actual action
  title: "Add Success Tag",  // Update the title
  inputs: {
    // Your action inputs
    tagIds: ["tag-id"],
    ticketId: "jp:$.trigger.output.ticketId"
  }
});

// Same for the other branch
await mcp__ravenna__workflow__updateStep({
  workflowId: "wf_XXX",
  workspaceId: "workspace-id",
  id: falseBranch.id,
  action: "RavAddsTicketTagAction",
  title: "Add Failure Tag",
  inputs: {
    tagIds: ["different-tag-id"],
    ticketId: "jp:$.trigger.output.ticketId"
  }
});
```

**Why Update Placeholders Directly?**
1. **Cleaner workflow structure** - No extra layers of nesting
2. **Fewer steps** - Easier to read and maintain
3. **Same functionality** - Works exactly the same way
4. **Best practice** - This is how production workflows should be built

**Key Insight:** Placeholder steps are just regular steps with `PlaceholderAction`. You can update them to any action type you want using `updateStep`!

### 🔴 CRITICAL #3: Field Interpolation with `referenceId`

**Problem:** You might think references are like `{{step.field}}`, but that's WRONG.

**Solution:** Use `suggestions` to get the correct `referenceId` format.

**How to Get Correct References:**
```javascript
mcp__ravenna__workflowConfig__getStep({
  workflowId: "wf_XXX",
  workspaceId: "workspace-id",
  stepId: "step-id",
  suggestions: true  // CRITICAL: Set this to true
})
```

**Parse the Response:**
```javascript
// Look in "inputsWithSuggestions" object:
{
  "inputsWithSuggestions": {
    "ticketId": "jp:$.step_0625193951690_42B.output.ticketId"
    // ^^^^ This is the correct format!
  },
  "suggestions": [
    // Array of all available fields with their referenceIds
    {
      "label": "Ticket ID",
      "referenceId": "jp:$.step_0625193951690_42B.output.ticketId",
      // ...
    }
  ]
}
```

**Correct Usage:**
```javascript
// ❌ WRONG:
{
  ticketId: "{{step_0625193951690_42B.ticket.id}}"
}

// ✅ CORRECT:
{
  ticketId: "jp:$.step_0625193951690_42B.output.ticketId"
}
```

**Common Reference Patterns:**
```
// Basic fields
jp:$.stepId.output.ticketId
jp:$.stepId.output.isSuccess
jp:$.stepId.output.isApproved
jp:$.stepId.output.isTimedOut

// Ticket object
jp:$.stepId.output.ticket.id
jp:$.stepId.output.ticket.title
jp:$.stepId.output.ticket.requesterId
jp:$.stepId.output.ticket.assigneeId
jp:$.stepId.output.ticket.approverIds

// Form fields (complex path)
jp:$.stepId.output.ticket.requestType.{formId}.{fieldId}
jp:$.stepId.output.ticket.requestType.{formId}.{fieldId}.name
jp:$.stepId.output.ticket.requestType.{formId}.{fieldId}.approverIds

// Access levels
jp:$.stepId.output.ticket.accessLevel.id
jp:$.stepId.output.ticket.accessLevel.userGroupIds

// Message content
jp:$.stepId.output.ticketMessage.message

// Integration outputs
jp:$.stepId.output.googleGroupId
```

**Dynamic Content in Messages:**
Use `{{interpolation}}` syntax:
```javascript
{
  comment: "Hello {{jp:$.trigger.output.ticket.requester.firstName}}! Your access to {{jp:$.trigger.output.ticket.accessLevel.name}} has been approved."
}
```

**User Mentions (for Slack):**
```javascript
{
  comment: "{{@jp:$.trigger.output.ticket.approverIds.userMentions}} please provision access!"
}
```

**⚠️ CRITICAL: `.input` vs `.output` - Understanding the Perspective**

This is one of the most critical distinctions in workflow building that can break your workflow if you get it wrong:

**The Rule:**
- When a step references **its own data** (in its own suggestions), it uses `.input`
- When **another step references that step's data**, it uses `.output`

**Example:**

```javascript
// Trigger step (step_ABC123)
// When you call getStep with suggestions on the TRIGGER step itself:
{
  suggestions: [
    {
      label: "Ticket",
      referenceId: "jp:$.step_ABC123.input.ticketId"  // .input!
    }
  ]
}

// But from another step's perspective (like an action step):
// When you call getStep with suggestions on the ACTION step:
{
  suggestions: [
    {
      label: "Ticket",
      referenceId: "jp:$.step_ABC123.output.ticketId"  // .output!
    }
  ]
}
```

**Why This Matters:**

When you're building a workflow and adding steps, you should ALWAYS use suggestions from the **consumer step's perspective**, not the source step's perspective.

**❌ WRONG Approach:**
```javascript
// Get suggestions from the trigger step itself
const triggerSuggestions = await getStep({ stepId: "trigger" });
// This shows .input.ticketId

// Then use that in an action step
await addStep({
  action: "RavSetTicketStatusAction",
  inputs: {
    ticketId: "jp:$.trigger.input.ticketId"  // WRONG! Will fail!
  }
});
```

**✅ CORRECT Approach:**
```javascript
// Get suggestions from the ACTION step's perspective
const actionStepSuggestions = await getStep({ stepId: "actionStep" });
// This shows .output.ticketId for the trigger

// Use the correct reference
await addStep({
  action: "RavSetTicketStatusAction",
  inputs: {
    ticketId: "jp:$.trigger.output.ticketId"  // CORRECT!
  }
});
```

**Best Practice:**
Always fetch suggestions from the step that will **consume** the data, not from the step that **produces** it. The consumer's perspective gives you the correct `.output` references.

**Quick Reference:**
- `.input` = A step's own view of its incoming data
- `.output` = How other steps see that step's produced data
- **99% of the time, you want `.output` when referencing other steps**

### 🔴 CRITICAL #3a: Always Prefer Synthetic Fields

**The Rule:** When suggestions show both a direct field and a synthetic field (prefixed with `synthetic-`), ALWAYS use the synthetic field.

**Example:**

```javascript
// Suggestions show TWO options:
[
  {
    "key": "step_ABC.ticketId.requesterId.Okta.managerId",
    "referenceId": "jp:$.step_ABC.output.ticket.requester.Okta.managerId",
    "label": "Manager"
  },
  {
    "key": "synthetic-step_ABC.ticketId.requesterId.Okta.managerId.id",  // <-- synthetic!
    "referenceId": "jp:$.step_ABC.output.ticket.requester.Okta.manager.id",
    "label": "Manager"
  }
]
```

**❌ WRONG - Using non-synthetic field:**
```javascript
{
  assigneeId: "jp:$.trigger.output.ticket.requester.Okta.managerId"
}
```

**✅ CORRECT - Using synthetic field:**
```javascript
{
  assigneeId: "jp:$.trigger.output.ticket.requester.Okta.manager.id"  // Notice .manager.id not .managerId
}
```

**Why Synthetic Fields Are Better:**
1. **More normalized data structure** - `.manager.id` vs `.managerId`
2. **Consistent with nested object patterns** - Access related fields like `.manager.email`, `.manager.firstName`
3. **Future-proof** - Better alignment with API evolution
4. **Recommended by platform** - These are the preferred references

**How to Identify Synthetic Fields:**
- Look for `"synthetic-"` prefix in the `key` field
- Notice the path difference: `.managerId` → `.manager.id`
- The synthetic field provides access to the full nested object

**Common Patterns:**
```javascript
// Non-synthetic (avoid if synthetic exists)
jp:$.trigger.output.ticket.requester.Okta.managerId
jp:$.trigger.output.ticket.assigneeId

// Synthetic (preferred)
jp:$.trigger.output.ticket.requester.Okta.manager.id
jp:$.trigger.output.ticket.assignee.id
```

### 🔴 CRITICAL #3b: User Mentions - The `.userMention` Requirement

**The Rule:** The `{{@...}}` mention syntax ONLY works with fields that end in `.userMention`. You CANNOT mention users with regular ID fields.

**Why This Matters:**
User mentions create special formatting in tickets/messages that notifies users and adds them as followers. The system needs to know you want a mention, not just an ID.

**✅ Fields That Support `{{@...}}` Syntax:**

```javascript
// Requester
"{{@jp:$.trigger.output.ticket.requester.userMention}}"  // ✅ Works!

// Assignee
"{{@jp:$.trigger.output.ticket.assignee.userMention}}"   // ✅ Works!

// Approvers (if they have userMention field)
"{{@jp:$.trigger.output.ticket.approvers.userMention}}"  // ✅ Works!
```

**❌ Fields That DON'T Support `{{@...}}` Syntax:**

```javascript
// Manager fields don't have .userMention
"{{@jp:$.trigger.output.ticket.requester.Okta.manager.id}}"  // ❌ FAILS!
"{{@jp:$.trigger.output.ticket.requester.managerId}}"        // ❌ FAILS!

// Regular ID fields
"{{@jp:$.trigger.output.ticket.requesterId}}"                // ❌ FAILS!
"{{@jp:$.trigger.output.ticket.assigneeId}}"                 // ❌ FAILS!
```

**How to Mention Users Without `.userMention`:**

Use HTML mention format with the user's ID and display name:

```javascript
{
  comment: "<span data-type=\"mention\" class=\"mention\" data-id=\"{{jp:$.trigger.output.ticket.requester.Okta.manager.id}}\" data-label=\"{{jp:$.trigger.output.ticket.requester.Okta.manager.firstName}} {{jp:$.trigger.output.ticket.requester.Okta.manager.lastName}}\">@{{jp:$.trigger.output.ticket.requester.Okta.manager.firstName}} {{jp:$.trigger.output.ticket.requester.Okta.manager.lastName}}</span> Hi! Please provision access."
}
```

**HTML Mention Template:**
```html
<span
  data-type="mention"
  class="mention"
  data-id="{{USER_ID_REFERENCE}}"
  data-label="{{DISPLAY_NAME}}">
  @{{DISPLAY_NAME}}
</span>
```

**Complete Example - Mentioning a Manager:**

```javascript
// Step 1: Verify manager fields exist in suggestions
const suggestions = await getStep({ stepId: "yourStep", suggestions: true });
const managerIdRef = suggestions.suggestions.find(s =>
  s.referenceId.includes(".Okta.manager.id")
);
const managerFirstNameRef = suggestions.suggestions.find(s =>
  s.referenceId.includes(".Okta.manager.firstName")
);
const managerLastNameRef = suggestions.suggestions.find(s =>
  s.referenceId.includes(".Okta.manager.lastName")
);

// Step 2: Use HTML mention format
await updateStep({
  action: "RavTicketMessageAddAction",
  inputs: {
    comment: `<span data-type="mention" class="mention" data-id="{{${managerIdRef.referenceId}}}" data-label="{{${managerFirstNameRef.referenceId}}} {{${managerLastNameRef.referenceId}}}">@{{${managerFirstNameRef.referenceId}}} {{${managerLastNameRef.referenceId}}}</span> Please review this request.`
  }
});
```

**Quick Decision Tree:**

```
Does the field end with .userMention?
├─ YES → Use {{@jp:$.path.to.userMention}}
└─ NO  → Can you find the .id, .firstName, .lastName fields?
    ├─ YES → Use HTML mention format
    └─ NO  → Cannot mention this user (just use their name without @)
```

**Common Mistakes:**
1. ❌ Using `{{@...}}` with `.managerId` or `.manager.id`
2. ❌ Assuming all user fields have `.userMention`
3. ❌ Not checking suggestions to see if `.userMention` exists
4. ❌ Forgetting to verify field existence before using HTML format

**Remember:** ALWAYS verify in suggestions whether `.userMention` exists for a field before using the `{{@...}}` syntax!

### 🔴 CRITICAL #4: Text vs Select Field Interpolation

**Problem:** Not all fields handle references the same way!

**The Rule:**
- **Text/textarea/richtexteditor fields** → Wrap in `{{jp:$.reference}}`
- **Select/multiselect fields** → Use direct `jp:$.reference` (no wrapping)

**Why This Matters:**

Different field types expect different formats. Using the wrong format means the field won't interpolate and will be treated as a literal string.

**How to Know Which Format:**

Check the field type in the action definition (from `getStep` with suggestions):
- If `type: "text"`, `type: "textarea"`, or `type: "richtexteditor"` → Use `{{...}}`
- If `type: "select"` or `type: "multiselect"` → Use plain reference

**Examples:**

```javascript
// ❌ WRONG - Text field without wrapping
{
  "action": "RavLinkTicketAction",
  "inputs": {
    "ticketId": "jp:$.loopStep.output.item.id",  // ✓ select field (correct)
    "url": "jp:$.trigger.output.prUrl",          // ❌ text field (WRONG!)
    "name": "PR #123"                             // ✓ literal text (correct)
  }
}

// ✅ CORRECT - Text fields wrapped, select fields direct
{
  "action": "RavLinkTicketAction",
  "inputs": {
    "ticketId": "jp:$.loopStep.output.item.id",  // ✓ select field - no wrapping
    "url": "{{jp:$.trigger.output.prUrl}}",      // ✓ text field - wrapped!
    "name": "PR #{{jp:$.trigger.output.prNumber}}: {{jp:$.trigger.output.prTitle}}"  // ✓ text with interpolation
  }
}
```

**Common Field Types:**

| Field Type | Wrapping | Example |
|------------|----------|---------|
| `ticketId` (select) | No | `jp:$.step.output.ticketId` |
| `statusId` (select) | No | `jp:$.step.output.statusId` |
| `userIds` (multiselect) | No | `["jp:$.step.output.userIds"]` |
| `comment` (richtexteditor) | Yes | `{{jp:$.step.output.message}}` |
| `url` (text) | Yes | `{{jp:$.step.output.prUrl}}` |
| `name` (text) | Yes | `{{jp:$.step.output.name}}` |
| `title` (text) | Yes | `{{jp:$.step.output.title}}` |
| Filter `value` (text) | Yes | `{{jp:$.step.output.value}}` |

**Production Tip:**

When you call `getStep` with suggestions, look at the `type` field in the input definition to know which format to use. This is critical for webhook workflows where AI extracts text values that need to be used in various field types.

### 🔴 CRITICAL #5: filterGroups - The Power Tool

**filterGroups** serve TWO purposes:

**Purpose 1: Filter Which Tickets Trigger the Workflow**
```javascript
{
  "action": "RavTicketCreatedTrigger",
  "inputs": {
    "filterGroups": [[{
      // Only trigger if this field is NOT null
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
    "comment": "Success message for group provisioning",
    "filterGroups": [[{
      // Only send this message if provisioningMethod = "group"
      "field": "jp:$.trigger.output.ticket.requestType.{formId}.{fieldId}.provisioningMethod",
      "value": "group",
      "condition": "equals"
    }]]
  }
}
```

**Common Conditions:**
- `equals` - Exact match
- `not_null` - Field exists and has value
- `null` - Field is null/undefined
- `contains` - String contains substring
- `not_equals` - Does not match

**Multiple Conditions (AND logic within a group):**
```javascript
{
  "filterGroups": [[
    {"field": "...", "value": "value1", "condition": "equals"},
    {"field": "...", "value": null, "condition": "not_null"}
  ]]
}
// All conditions in inner array must be true
```

**Multiple Filter Groups (OR logic between groups):**
```javascript
{
  "filterGroups": [
    [  // Group 1 (all conditions must be true)
      {"field": "jp:$.trigger.output.ticket.requester.id", "value": ["jp:$.getGroupStep.output.googleGroup.googleGroupOwnerIds"], "condition": "in"}
    ],
    [  // Group 2 (all conditions must be true)
      {"field": "jp:$.trigger.output.ticket.requester.id", "value": ["jp:$.getGroupStep.output.googleGroup.googleGroupManagerIds"], "condition": "in"}
    ]
  ]
  // Group 1 OR Group 2 - if EITHER group is fully satisfied, condition passes
}
```

**Key Insight:** The outer array represents OR logic - if any single filter group is fully satisfied (all its conditions are true), the overall filterGroups evaluation passes. This enables powerful permission checks and multi-criteria matching.

**Production Example:**
Send different messages based on provisioning method:
```javascript
// Message 1: For automated provisioning
{
  "action": "RavTicketMessageAddAction",
  "inputs": {
    "comment": "You've been added to the Okta group!",
    "filterGroups": [[{
      "field": "jp:$.trigger.output.ticket.requestType.{formId}.{methodField}.provisioningMethod",
      "value": "group",
      "condition": "equals"
    }]]
  }
}

// Message 2: For manual provisioning
{
  "action": "RavTicketMessageAddAction",
  "inputs": {
    "comment": "The owner will manually provision your access.",
    "filterGroups": [[{
      "field": "jp:$.trigger.output.ticket.requestType.{formId}.{methodField}.provisioningMethod",
      "value": "manual",
      "condition": "equals"
    }]]
  }
}
```

### 🔴 CRITICAL #6: Don't Trust Error Messages

**Learning:** API calls may return errors, but the operation might have succeeded.

**Example:**
```javascript
// Returns error: "Unable to move step..."
mcp__ravenna__workflow__repositionStep({...})

// But when you fetch the workflow:
mcp__ravenna__workflowConfig__getForWorkflow({...})
// The step WAS actually moved!
```

**Best Practice:**
- After ANY operation that returns an error, fetch the latest workflow state
- Verify the actual state before retrying or taking corrective action
- Never assume failure based solely on error messages

### 🔴 CRITICAL #7: Always Connect Before Deleting

**Rule:** When restructuring workflows, always create new connections before removing old ones.

**Why:** Prevents orphaned steps and maintains workflow integrity.

**Correct Order:**
```javascript
// 1. Create new connection
mcp__ravenna__workflow__repositionStep({
  sourceId: "new-parent-id",
  id: "step-to-move"
});

// 2. Verify new structure
await getWorkflow();

// 3. Only then delete orphaned steps
mcp__ravenna__workflow__deleteSteps({
  stepIds: ["old-step-id"]
});
```

### 🔴 CRITICAL #8: Get Status/Tag IDs from Suggestions

**Don't hardcode IDs** - they vary per workspace!

**Correct Approach:**
```javascript
// Get step with suggestions
const stepInfo = await mcp__ravenna__workflowConfig__getStep({
  stepId: "your-step-id",
  suggestions: true
});

// Parse selectOptions for statuses/tags:
const statusInput = stepInfo.action.inputs.find(input => input.key === "statusId");
const statusOptions = statusInput.selectOptions;

// Example output:
[
  {label: "In Progress", value: "cmhaojczw000kmt2ho565y69a"},
  {label: "Open", value: "cmhaojczw000imt2h312wutaa"},
  {label: "Done", value: "cmhaojczx0019mr3jzv6kwmkk"},
  // ...
]
```

### 🔴 CRITICAL #9: Always Verify References After Creating/Updating Steps

**The Rule:** After EVERY step creation or update that uses field references, you MUST verify that all references are valid and match the semantic field requirements.

**Why This Matters:**
- Invalid references will cause workflow execution failures
- Semantic field mismatches can break interpolation
- Wrong field paths won't be caught until runtime

**Verification Process:**

**Step 1: Get Step with Suggestions**
```javascript
const stepInfo = await mcp__ravenna__workflowConfig__getStep({
  workflowId: "wf_XXX",
  workspaceId: "workspace-id",
  stepId: "step-you-just-created-or-updated",
  suggestions: true  // CRITICAL!
});
```

**Step 2: Verify Each Reference Exists**
For each field reference in your step inputs:
```javascript
// Example: You used "jp:$.step_ABC.output.ticket.requesterId"
// Search in suggestions array to confirm it exists:
const referenceExists = stepInfo.suggestions.some(s =>
  s.referenceId === "jp:$.step_ABC.output.ticket.requesterId"
);

if (!referenceExists) {
  // ❌ INVALID REFERENCE - Fix it!
  console.error("Reference not found in suggestions!");
}
```

**Step 3: Verify Semantic Field Compatibility**
Check that the source and target semantic fields match:
```javascript
// Example: duration field
const durationInput = stepInfo.action.inputs.find(i => i.key === "duration");
console.log(durationInput.semanticField);  // Should be "duration"
console.log(durationInput.type);  // Should be "number"

// Your reference must provide compatible data
// For duration: text outputs can work with mathematical operations
// For userId: must reference a field with semanticField "userId"
```

**Common Semantic Field Rules:**
- **`userId`** → Only accepts fields with `semanticField: "userId"`
- **`ticketId`** → Only accepts fields with `semanticField: "ticketId"`
- **`duration`** → Accepts duration strings like "3d", "1h", or mathematical expressions
- **`datetime`/`offset`** → Accepts ISO date strings or date arithmetic
- **Text fields** (`text`, `textarea`, `richtexteditor`) → Can accept any reference wrapped in `{{}}`
- **Select fields** (`select`, `multiselect`) → Use direct `jp:$` reference (no wrapping)

**Mathematical Operations in Duration Fields:**
Duration fields support mathematical operations with date/time references:
```javascript
// ✅ VALID - Calculate 10 days before a date
{
  duration: "{{jp:$.step_ABC.output.joiningDate}} - 10d"
}

// ✅ VALID - Add 2 hours to a time
{
  duration: "{{jp:$.step_ABC.output.startTime}} + 2h"
}

// ❌ INVALID - Can't use a text field directly in duration
{
  duration: "{{jp:$.step_ABC.output.response}}"  // Unless response is a duration string
}
```

**Example Verification Workflow:**
```javascript
// After creating/updating a step
const step = await mcp__ravenna__workflow__updateStep({
  // ... your step config with references
});

// IMMEDIATELY verify
const verification = await mcp__ravenna__workflowConfig__getStep({
  workflowId: "wf_XXX",
  workspaceId: "workspace-id",
  stepId: step.id,
  suggestions: true
});

// Check all references used in the step
const myReferences = [
  "jp:$.step_ABC.output.ticketId",
  "jp:$.step_DEF.output.ticket.requester.firstName"
];

myReferences.forEach(ref => {
  const exists = verification.suggestions.some(s => s.referenceId === ref);
  if (!exists) {
    console.error(`❌ Invalid reference: ${ref}`);
  } else {
    console.log(`✅ Valid reference: ${ref}`);
  }
});
```

**What to Check:**
1. ✅ All references exist in suggestions
2. ✅ Semantic fields match (userId → userId, ticketId → ticketId, etc.)
3. ✅ Text fields use `{{}}` wrapping
4. ✅ Select fields use direct `jp:$` (no wrapping)
5. ✅ Mathematical operations use correct syntax for duration/offset fields
6. ✅ Nested paths are correct (e.g., `.requester.Okta.managerId`, not `.requester.managerId`)

**Common Mistakes to Catch:**
- ❌ Using `.input` instead of `.output` when referencing from another step
- ❌ Using non-existent nested paths (e.g., `.managerId` instead of `.Okta.managerId`)
- ❌ Wrapping select field references in `{{}}`
- ❌ Not wrapping text field references in `{{}}`
- ❌ Using wrong semantic field types (text where userId is expected)
- ❌ Using hardcoded dates instead of dynamic references with math operations

**Best Practice:**
Make verification a habit after EVERY step creation/update. It takes 10 seconds and prevents hours of debugging runtime failures.

---

## Production Patterns

### Pattern 1: Simple Automated Provisioning
**Use when:** Low-risk apps, no approval needed, integration available

```
Trigger (Software Access Request)
  ↓
If/Else (Check if automated provisioning available?)
  ├─ TRUE:
  │   → Add User to Okta Group
  │   → Send Success Message
  │   → Set Status (Done)
  └─ FALSE:
      → Send "Manual Provisioning Required" Message
      → Set Status (Waiting)
```

**Implementation Tips:**
- Use `IfElseAction` with `filterGroups` checking provisioning method field
- Send different messages using `filterGroups` on message actions
- Always set appropriate status at the end

### Pattern 2: Approval-Based Workflow
**Use when:** Moderate-risk, manager approval required

```
Trigger
  ↓
Add Approvers
  ↓
Wait (1s) ← Ensures approvers are added before waiting
  ↓
Wait for Approval (3d)
  ├─ APPROVED:
  │   → Provision Access
  │   → Send Success Message
  │   → Set Status (Done)
  ├─ DECLINED:
  │   → Send Declined Message
  │   → Set Status (Archived)
  └─ TIMEOUT:
      → Send Timeout Message
      → Set Status (Archived)
```

**Implementation Tips:**
- Always add 1s wait after adding approvers
- Handle all 3 branches: Approved, Declined, Timeout
- Fetch workflow after adding WaitForApprovalAction to find all 3 placeholders

### Pattern 3: Manual Provisioning with Confirmation Loop
**Use when:** No API integration, requires human provisioning

```
Trigger
  ↓
Add Vault/Team Owner as Approver
  ↓
Wait for Approval
  ├─ APPROVED:
  │   → Send "Please provision" message (mention owner)
  │   → Wait for Message from Owner (3d)
  │   → AI: "Is it provisioned?"
  │     ├─ TRUE:
  │     │   → Set Status (Done)
  │     └─ FALSE:
  │         → AI: "Do they need help?"
  │           ├─ TRUE:
  │           │   → Set Status (Escalated)
  │           │   → Assign to IT
  │           └─ FALSE:
  │               → Goto "Wait for Message" (budget: 3)
  │                 → On Limit Reached:
  │                     → Set Status (Escalated)
  │                     → Assign to IT
  └─ DECLINED:
      → Set Status (Archived)
```

**Implementation Tips:**
- Use `WaitForMessageAction` with specific user IDs
- Use `AITicketConditionalAction` to interpret responses
- Use `RavGotoAction` for retry logic (always set budget!)
- Handle "On Limit Reached" branch for escalation

### Pattern 4: Integration with Validation
**Use when:** Managing external resources (Google Groups, etc.)

```
Trigger (Add/Remove from Group)
  ↓
Get Resource (e.g., Google Group)
  ├─ EXISTS:
  │   → Check User Membership
  │     ├─ IS MEMBER:
  │     │   → Remove User (if action=remove)
  │     │   → Notify Success
  │     │   → Set Status (Done)
  │     └─ NOT MEMBER:
  │         → Add User (if action=add)
  │         → Notify Success
  │         → Set Status (Done)
  └─ NOT FOUND:
      → Send "Group not found, please clarify" message
      → Set Status (Open) ← Keep open for follow-up
```

**Implementation Tips:**
- Always validate resource exists first
- Check current state before modifying
- Handle "not found" gracefully - don't fail, ask user to clarify
- Use different final statuses: Done vs Open (for follow-up)

### Pattern 5: Parent-Child Ticket Linking
**Use when:** Complex workflows with sub-tickets (onboarding, project management)

```
Trigger (Child Ticket Created)
  |
AI: Extract employee data (email, name)
  |
Search for Parent Ticket (by email)
  |-- Found?
  |   |-- TRUE:
  |   |   --> Loop (limit: 1)
  |   |   --> RavTicketUpdateAction (set parentTicketId)
  |   |-- FALSE:
  |       --> Search by Personal Email
  |           |-- Found? --> Link
  |           |-- Not Found? --> Search by Name
  |               |-- Found? --> Link
  |               |-- Not Found? --> Assign to IT for manual linking
```

**Implementation Tips:**
- Use `RavSearchTicketsAction` with custom field filters to find the parent
- Use `LoopAction` with `limit: 1` to get the first result
- Implement fallback search strategies (email -> name -> manual)
- Use `RavTicketUpdateAction` with `parentTicketId` to create the relationship

### Pattern 6: Cron-Based Batch Operations
**Use when:** Proactive operations - health checks, overdue detection, cleanup

```
CronAction (daily at 23:59 UTC)
  |
AI Prompt (calculate target date)
  |
RavSearchTicketsAction (find matching tickets)
  |
LoopAction (limit: 50)
  |-- Send notification to assignee
  |-- Update status to "Waiting"
  |
EndLoopAction
```

**Implementation Tips:**
- Use AI for date calculations ("add 7 days to today in YYYY-MM-DD")
- Set loop limits to prevent runaway processing (50 is a good default)
- Update ticket state during loop so items are not reprocessed next run
- Run during off-peak hours

### Pattern 7: Inactivity Monitoring
**Use when:** SLA management, ticket hygiene, stale ticket alerting

```
RavTicketMessageTrigger (fires on ANY message)
  |
RavTicketMessageMonitor (wait for 10 days inactivity)
  |
RavSearchTicketsAction (get latest ticket state)
  |
LoopAction (limit: 1)
  |
IfElse: Has assignee?
  |-- TRUE: SlackSendDmMessageAction to assignee
  |-- FALSE: SlackSendChannelMessageAction to team
```

**Implementation Tips:**
- Trigger fires on every message - the monitor handles the waiting
- Always search after the monitor period to get fresh ticket data
- Use conditional notifications: DM assignee if exists, channel if not
- Common durations: 5d for new tickets, 10d for all tickets

### Pattern 8: Webhook Integration with AI
**Use when:** Receiving data from external systems (HRIS, C1, procurement)

```
External System --> POST to webhook URL
  |
ai-prompt-trigger (extracts fields using AI)
  |
RavTicketCreateAction (create ticket with extracted data)
  |
Process ticket (tag, assign, notify)
```

**Implementation Tips:**
- Use `ai-prompt-trigger` to define what fields to extract from the payload
- The webhook URL is automatically generated (available as `directUrl`)
- Configure external system to POST JSON to the webhook URL
- Access extracted fields: `jp:$.trigger.output.outputs.{fieldName}`
- Use HTTP status code 202 for asynchronous processing

### Pattern 9: Permission-Based Execution
**Use when:** Sensitive operations that require role verification

```
Trigger
  |
Get Resource Info (e.g., Google Group)
  |-- Resource Found?
      |-- TRUE:
      |   --> IfElse: Requester is Owner OR Manager?
      |       |-- TRUE: Execute action --> Success message
      |       |-- FALSE: Deny message
      |-- FALSE:
          --> "Resource not found" message
```

**Permission Check with OR Logic:**
```javascript
{
  "action": "IfElseAction",
  "inputs": {
    "filterGroups": [
      [{  // Group 1: Is requester an owner?
        "field": "jp:$.trigger.output.ticket.requester.id",
        "value": ["jp:$.getGroupStep.output.googleGroup.googleGroupOwnerIds"],
        "condition": "in"
      }],
      [{  // Group 2: Is requester a manager?
        "field": "jp:$.trigger.output.ticket.requester.id",
        "value": ["jp:$.getGroupStep.output.googleGroup.googleGroupManagerIds"],
        "condition": "in"
      }]
    ]
  }
}
// Multiple filter groups = OR logic: passes if requester is owner OR manager
```

**Implementation Tips:**
- Use multiple filter groups for OR logic in permission checks
- Always validate the resource exists before checking permissions
- Provide clear denial messages explaining why access was refused

### Pattern 10: Multi-Level Approval with Escalation
**Use when:** High-risk access, multiple stakeholders

```
Trigger
  ↓
Add Approvers
  ↓
Wait for Approval Round 1 (2d)
  ├─ APPROVED:
  │   → Continue to provisioning
  └─ DECLINED:
      → Check if already declined once
        ├─ NO (first decline):
        │   → Wait for Approval Round 2 (2d)
        │     ├─ APPROVED → Continue
        │     └─ DECLINED:
        │         → Check again
        │           ├─ NO:
        │           │   → Wait for Approval Round 3 (3d)
        │           │     ├─ APPROVED → Continue
        │           │     └─ DECLINED → Final denial
        │           └─ YES:
        │               → Final denial
        └─ YES (already retried):
            → Final denial → Set Status (Archived)
```

**Implementation Tips:**
- Can check previous approval state: `jp:$.approvalStep.output.isApproved`
- Increase duration for each retry (2d → 2d → 3d)
- Eventually terminate after 2-3 retries
- Send clear messages at each stage

---

## Advanced Patterns

### Loop Pattern with RavGotoAction

**Use Case:** Retry confirmation checks with limit

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

// Step 2: AI check if confirmed
const aiCheck = await addStep({
  sourceId: waitStep.id,
  action: "AITicketConditionalAction",
  inputs: {
    ticketId: "jp:$.trigger.output.ticketId",
    description: "Does the message confirm that access was provisioned?"
  }
});

// Fetch to get placeholders
const workflow = await getWorkflow();
const confirmed = findPlaceholder(workflow, "left");
const notConfirmed = findPlaceholder(workflow, "right");

// Step 3a: If confirmed → Done
await addStep({
  sourceId: confirmed.id,
  action: "RavSetTicketStatusAction",
  inputs: {
    statusId: "done-status-id",
    ticketId: "jp:$.trigger.output.ticketId"
  }
});

// Step 3b: If not confirmed → Loop back with retry
const gotoStep = await addStep({
  sourceId: notConfirmed.id,
  action: "RavGotoAction",
  inputs: {
    stepId: aiCheck.id,  // Loop back to AI check
    budget: 3  // Maximum 3 retries
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
- `On Limit Reached` is a special branch (automatically created)
- Always handle the limit reached case!

### AI-Powered Decision Making

**Pattern 1: Check ticket content**
```javascript
{
  "action": "AITicketConditionalAction",
  "inputs": {
    "ticketId": "jp:$.trigger.output.ticketId",
    "description": "Check if this ticket is requesting access to software or an application. Look at both the title and description. Return true if it's a software access request, false otherwise."
  }
}
// Returns: isSuccess = true/false
```

**Pattern 2: Interpret user messages**
```javascript
// After WaitForMessageAction
{
  "action": "ai-prompt",
  "inputs": {
    "prompt": "Message: {{jp:$.waitStep.output.ticketMessage.message}}\n\nQuestion: Does this message confirm that the user wants their password reset? Return TRUE if yes, FALSE if no or unclear."
  }
}
// Returns: isSuccess = true/false
```

**Best Practices for AI Actions:**
- Be specific and clear in your prompt
- Ask yes/no questions
- Provide context from the ticket
- Use for ambiguous situations (intent detection, confirmation checking)

### Error Handling Pattern

**Always check integration action results:**
```javascript
// Step 1: Integration action
const oktaAction = await addStep({
  action: "OktaAddUserToGroupAction",
  inputs: { ... }
});

// Step 2: Fetch and find branches based on isSuccess
const workflow = await getWorkflow();
// Integration actions don't create placeholders automatically
// So we need to add conditionals ourselves

// Option A: Use filterGroups for conditional messages
await addStep({
  sourceId: oktaAction.id,
  action: "RavTicketMessageAddAction",
  inputs: {
    comment: "You've been added successfully!",
    filterGroups: [[{
      field: `jp:$.${oktaAction.id}.output.isSuccess`,
      value: true,
      condition: "equals"
    }]]
  }
});

await addStep({
  sourceId: oktaAction.id,
  action: "RavTicketMessageAddAction",
  inputs: {
    comment: "There was an error. IT has been notified.",
    filterGroups: [[{
      field: `jp:$.${oktaAction.id}.output.isSuccess`,
      value: false,
      condition: "equals"
    }]]
  }
});

// Option B: Add explicit conditional
const checkSuccess = await addStep({
  sourceId: oktaAction.id,
  action: "IfElseAction",
  inputs: {
    filterGroups: [[{
      field: `jp:$.${oktaAction.id}.output.isSuccess`,
      value: true,
      condition: "equals"
    }]]
  }
});

// Then handle branches...
```

**Escalation on Failure:**
```javascript
// On failure branch:
await addStep({
  action: "RavSetTicketStatusAction",
  inputs: {
    statusId: "escalated-status-id"
  }
});

await addStep({
  action: "RavSetTicketAssigneeAction",
  inputs: {
    userId: "it-admin-id",
    strategy: "User"
  }
});
```

---

## Loops and Iteration

### LoopAction / EndLoopAction

**Purpose:** Iterate over arrays of items (ticket IDs, search results, user lists, etc.)

**Basic Structure:**
```javascript
// Step 1: Start the loop
{
  "action": "LoopAction",
  "inputs": {
    "limit": 50,  // Maximum iterations (protect against runaway loops)
    "collection": ["jp:$.searchStep.output.ticketIds"],  // Array to iterate
    "workspaceId": "...",
    "organizationId": "..."
  }
}

// Step 2: Actions inside the loop (use loop item references)
// ... your actions here ...

// Step 3: End the loop
{
  "action": "EndLoopAction",
  "inputs": {
    "limit": "jp:$.loopStep.output.loop.limit",
    "workspaceId": "...",
    "organizationId": "..."
  }
}
```

### Accessing Loop Data

Inside a loop, access the current item and loop metadata:

| Reference | Description |
|-----------|-------------|
| `jp:$.loopStep.output.item` | The current item in the collection |
| `jp:$.loopStep.output.item.id` | Property of the current item |
| `jp:$.loopStep.output.item.title` | Another property of the current item |
| `jp:$.loopStep.output.loop.size` | Total number of items in collection |
| `jp:$.loopStep.output.loop.limit` | Maximum iteration limit |

### Pattern: Get First Result

When you want only the first item from a search (common for parent ticket lookup):

```javascript
{
  "action": "LoopAction",
  "inputs": {
    "limit": 1,  // Only process the first item
    "collection": ["jp:$.searchStep.output.ticketIds"]
  }
}
```

### Best Practices for Loops

1. **Always set a reasonable limit** - Production workflows use `limit: 50` for batch operations
2. **Use limit: 1 for single results** - When you want "first result" from search
3. **EndLoopAction is required** - Always close your loops
4. **Reference loop limit from the LoopAction output** - Use `jp:$.loopStep.output.loop.limit` in EndLoopAction

---

## Ticket Search Patterns

### RavSearchTicketsAction

**Purpose:** Search for tickets with complex filter criteria. Essential for finding related tickets, batch operations, and parent-child linking.

**Basic Example:**
```javascript
{
  "action": "RavSearchTicketsAction",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "ticketFilter": [[
      {"field": "title", "value": "ONB_1", "condition": "contains"},
      {"field": "statusId", "value": ["status-id-1", "status-id-2"], "condition": "not_in"}
    ]]
  }
}
```

### Filter Conditions Reference

| Condition | Description | Example Value |
|-----------|-------------|---------------|
| `equals` | Exact match | `"value"` |
| `not_equals` | Does not match | `"value"` |
| `contains` | String contains substring | `"ONB_1"` |
| `not_contains` | String does not contain | `"TEST"` |
| `in` | Value is in array | `["id1", "id2"]` |
| `not_in` | Value is not in array | `["id1", "id2"]` |
| `j_equals` | Custom field equals (JSONPath) | `"value"` |
| `j_not_null` | Custom field is not null | `null` |
| `lte` | Less than or equal (dates) | `"2026-12-31"` |
| `gte` | Greater than or equal (dates) | `"2026-01-01"` |

### JSONPath for Custom Fields

To search by custom field values, use the special JSONPath format:

```javascript
{
  "ticketFilter": [[
    {
      "field": "[\"requestTypeId:formId\",\"customFields.path[0]:fieldId\",\"customFields\"]",
      "value": "search-value",
      "condition": "j_equals"
    }
  ]]
}
```

**Checking custom field is not null:**
```javascript
{
  "field": "[\"requestTypeId:formId\",\"customFields.path[0]:fieldId\",\"customFields\"]",
  "value": null,
  "condition": "j_not_null"
}
```

### Multiple Filter Groups (OR Logic)

The `ticketFilter` supports multiple groups with OR logic between them:

```javascript
{
  "ticketFilter": [
    [  // Filter group 1 - conditions AND'd within
      {"field": "title", "value": "ONB_1", "condition": "contains"},
      {"field": "statusId", "value": ["done-id"], "condition": "not_in"}
    ],
    [  // Filter group 2 - conditions AND'd within
      {"field": "queue.name", "value": "IT", "condition": "equals"}
    ]
    // Groups are OR'd together: matches group 1 OR group 2
  ]
}
```

### Common Search Patterns

**Find tickets by title prefix:**
```javascript
{"field": "title", "value": "ONB_1", "condition": "contains"}
```

**Find open tickets (exclude closed statuses):**
```javascript
{"field": "statusId", "value": ["done-id", "archived-id"], "condition": "not_in"}
```

**Find overdue tickets:**
```javascript
{"field": "dueAt", "value": "2026-06-26", "condition": "lte"}
```

### Search + Loop Pattern

The most common pattern combines search with a loop:

```javascript
// Step 1: Search for tickets
{
  "action": "RavSearchTicketsAction",
  "inputs": {
    "ticketFilter": [[
      {"field": "title", "value": "ONB_1", "condition": "contains"}
    ]]
  }
}

// Step 2: Loop through results
{
  "action": "LoopAction",
  "inputs": {
    "limit": 50,
    "collection": ["jp:$.searchStep.output.ticketIds"]
  }
}

// Step 3: Process each ticket (inside loop)
{
  "action": "RavTicketUpdateAction",
  "inputs": {
    "ticketId": "jp:$.loopStep.output.item.id",
    "statusId": "new-status-id"
  }
}

// Step 4: End loop
{
  "action": "EndLoopAction",
  "inputs": {
    "limit": "jp:$.loopStep.output.loop.limit"
  }
}
```

---

## Parent-Child Tickets

### Overview

Parent-child ticket relationships enable complex workflows where a main ticket (parent) has sub-tickets (children) for different aspects of work.

**Example Structure:**
```
Parent: "ONB_1 - John Doe Onboarding"
  |-- Child: "IT Equipment for John Doe"
  |-- Child: "Quote INC-12345 for John Doe"
  |-- Child: "Device Order for John Doe"
```

### Creating Parent-Child Relationships

Use `RavTicketUpdateAction` with `parentTicketId`:

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

### Pattern: Find Parent and Link

The standard pattern for linking a child ticket to its parent:

```javascript
// Step 1: Search for parent ticket
{
  "action": "RavSearchTicketsAction",
  "inputs": {
    "ticketFilter": [[
      {"field": "title", "value": "ONB_1", "condition": "contains"},
      {
        "field": "[\"requestTypeId:formId\",\"customFields.path[0]:emailFieldId\",\"customFields\"]",
        "value": "jp:$.extractStep.output.outputs.EmployeeEmail",
        "condition": "j_equals"
      }
    ]]
  }
}

// Step 2: Loop through results (limit: 1 for first match)
{
  "action": "LoopAction",
  "inputs": {
    "limit": 1,
    "collection": ["jp:$.searchStep.output.ticketIds"]
  }
}

// Step 3: Update child ticket with parent reference
{
  "action": "RavTicketUpdateAction",
  "inputs": {
    "ticketId": "jp:$.trigger.output.ticketId",
    "parentTicketId": "jp:$.loopStep.output.item.id"
  }
}

// Step 4: End loop
{
  "action": "EndLoopAction",
  "inputs": {
    "limit": "jp:$.loopStep.output.loop.limit"
  }
}
```

### Multi-Strategy Search with Fallback

When employee data might appear in different fields, use cascading search strategies:

```
Search Strategy 1: Match by WorkEmail
  --> Found? --> Loop --> Link Parent --> Done

Search Strategy 2: Match by PersonalEmail
  --> Found? --> Loop --> Link Parent --> Done

Search Strategy 3: Match by Name
  --> Found? --> Loop --> Link Parent --> Done

All Failed? --> Assign to IT --> Manual Review
```

**Implementation:** Use nested If/Else conditionals checking if search results are not null before proceeding to the next strategy.

### Best Practices

1. **Use limit: 1 in the loop** - You typically want the single best parent match
2. **Search by unique identifiers first** - Email is more reliable than name
3. **Include status filters** - Exclude closed/archived parent tickets
4. **Handle "not found" gracefully** - Assign to human for manual linking
5. **Always search after extracting data** - Ensure you have clean field values

---

## Scheduled Workflows

### CronAction

**Purpose:** Run workflows on a recurring schedule (daily, hourly, weekly, etc.)

```javascript
{
  "action": "CronAction",
  "inputs": {
    "timezone": "UTC",
    "cronExpression": "59 23 * * *"  // Daily at 23:59 UTC
  }
}
```

### Cron Expression Reference

```
+---------------- minute (0 - 59)
|  +------------- hour (0 - 23)
|  |  +---------- day of month (1 - 31)
|  |  |  +------- month (1 - 12)
|  |  |  |  +---- day of week (0 - 6) (Sunday=0)
|  |  |  |  |
*  *  *  *  *
```

**Common Patterns:**
| Expression | Schedule |
|-----------|----------|
| `0 9 * * *` | Daily at 9:00 AM |
| `0 */6 * * *` | Every 6 hours |
| `0 9 * * 1` | Every Monday at 9:00 AM |
| `59 23 * * *` | Daily at 11:59 PM |
| `0 0 1 * *` | First day of each month at midnight |
| `0 9 * * 1-5` | Weekdays at 9:00 AM |

### Pattern: Cron-Based Batch Operations

```
CronAction (runs daily at 23:59 UTC)
  --> AI Prompt (calculate target due date)
  --> RavSearchTicketsAction (find overdue tickets)
  --> LoopAction (limit: 50)
      --> Send notification to assignee
      --> Update status to "Waiting"
  --> EndLoopAction
```

**Production Example - Onboarding Health Check:**
```javascript
// Step 1: Cron trigger
{
  "action": "CronAction",
  "inputs": {
    "timezone": "UTC",
    "cronExpression": "59 23 * * *"
  }
}

// Step 2: AI calculates the target date
{
  "action": "ai-prompt",
  "inputs": {
    "prompt": "Take today's date and add 7 days. Return in YYYY-MM-DD format."
  }
}

// Step 3: Search for tickets due within range
{
  "action": "RavSearchTicketsAction",
  "inputs": {
    "ticketFilter": [[
      {"field": "dueAt", "value": "jp:$.aiStep.output.outputs.date", "condition": "lte"},
      {"field": "statusId", "value": ["done-id", "archived-id"], "condition": "not_in"}
    ]]
  }
}

// Step 4: Loop and notify
{
  "action": "LoopAction",
  "inputs": {
    "limit": 50,
    "collection": ["jp:$.searchStep.output.ticketIds"]
  }
}
```

### Best Practices for Scheduled Workflows

1. **Use UTC timezone** for consistency across teams
2. **Set reasonable loop limits** (50 items max) to prevent runaway processing
3. **Use AI for date calculations** - more reliable than trying to compute in workflow logic
4. **Run during off-hours** when possible to avoid interference with interactive workflows
5. **Include status updates** so processed tickets are visibly changed

---

## Monitoring and Alerting

### RavTicketMessageMonitor

**Purpose:** Pause workflow execution until a ticket has been inactive (no messages) for a specified duration. Unlike `WaitForMessageAction` which waits FOR a message, this waits for the ABSENCE of messages.

```javascript
{
  "action": "RavTicketMessageMonitor",
  "inputs": {
    "duration": "10d",  // Wait for 10 days of NO activity
    "ticketId": "jp:$.trigger.output.ticket.id",
    "workspaceId": "...",
    "organizationId": "..."
  }
}
```

**Duration Examples:**
- `"5d"` - 5 days of inactivity
- `"10d"` - 10 days of inactivity
- `"24h"` - 24 hours of inactivity

### Pattern: Stale Ticket Detection

The complete inactivity monitoring pattern:

```
RavTicketMessageTrigger (fires on ANY message to ANY ticket)
  --> RavTicketMessageMonitor (wait for period of inactivity)
  --> RavSearchTicketsAction (get latest ticket state)
  --> LoopAction (process results)
  --> IfElse (check if assignee exists)
      |-- True: SlackSendDmMessageAction to assignee
      |-- False: SlackSendChannelMessageAction to team channel
```

**Why search after the monitor?** The ticket state may have changed during the inactivity period. The assignee, status, or other fields could be different from when the trigger originally fired. Always get fresh data.

### Production Implementation

```javascript
// Step 1: Trigger on any message
{
  "action": "RavTicketMessageTrigger",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "..."
  }
}

// Step 2: Wait for inactivity
{
  "action": "RavTicketMessageMonitor",
  "inputs": {
    "duration": "10d",
    "ticketId": "jp:$.trigger.output.ticket.id"
  }
}

// Step 3: Get latest ticket state
{
  "action": "RavSearchTicketsAction",
  "inputs": {
    "ticketFilter": [[
      {"field": "id", "value": "jp:$.trigger.output.ticket.id", "condition": "equals"}
    ]]
  }
}

// Step 4: Loop (limit: 1)
{
  "action": "LoopAction",
  "inputs": {
    "limit": 1,
    "collection": ["jp:$.searchStep.output.ticketIds"]
  }
}

// Step 5: Check if assignee exists and notify accordingly
{
  "action": "IfElseAction",
  "inputs": {
    "filterGroups": [[{
      "field": "jp:$.loopStep.output.item.assigneeId",
      "value": null,
      "condition": "not_null"
    }]]
  }
}

// True branch: DM the assignee
{
  "action": "SlackSendDmMessageAction",
  "inputs": {
    "message": "Ticket has been inactive for 10 days. Please review.",
    "slackUserIds": ["jp:$.loopStep.output.item.assigneeId"],
    "slackAppId": "..."
  }
}

// False branch: Notify team channel
{
  "action": "SlackSendChannelMessageAction",
  "inputs": {
    "message": "Unassigned ticket has been inactive for 10 days.",
    "slackChannelId": "team-channel-id",
    "slackAppId": "..."
  }
}
```

### Best Practices

1. **Always search after monitor** - Get latest ticket state before acting
2. **Use conditional notifications** - DM assignee if exists, team channel if not
3. **Choose appropriate durations** - 5 days for new tickets, 10 days for established ones
4. **Combine with status checks** - Only alert if ticket is still open

---

## Webhook Integration

### ai-prompt-trigger

**Purpose:** Create webhook endpoints that receive external data and use AI to extract structured fields from the payload.

```javascript
{
  "action": "ai-prompt-trigger",
  "inputs": {
    "prompt": "Extract the following values from the fields received in the payload:\nuserEmail\nusername\nentitlementName",
    "directUrl": "https://core.ravenna.ai/api/workflows/run?token=...",
    "workspaceId": "...",
    "httpStatusCode": "202",
    "organizationId": "..."
  }
}
```

### How It Works

1. The trigger generates a `directUrl` - a unique webhook URL
2. External systems POST data to this URL
3. AI extracts structured fields from the payload based on your prompt
4. Extracted fields are available as: `jp:$.trigger.output.outputs.{fieldName}`

### Setup Steps

1. Add `ai-prompt-trigger` as the first step in your workflow
2. Define the extraction prompt (list fields to extract)
3. Set appropriate HTTP status code (202 for "accepted, processing")
4. Get the `directUrl` from the trigger configuration
5. Configure the external system to POST to that URL
6. Use extracted fields in subsequent steps

### Production Example: External Access Request

```javascript
// Step 1: Webhook trigger with AI extraction
{
  "action": "ai-prompt-trigger",
  "inputs": {
    "prompt": "Extract the following values from the fields received in the payload:\nuserEmail\nusername\nentitlementName\nappName",
    "httpStatusCode": "202"
  }
}

// Step 2: Create ticket with extracted data
{
  "action": "RavTicketCreateAction",
  "inputs": {
    "title": "Access Request: {{jp:$.trigger.output.outputs.entitlementName}} for {{jp:$.trigger.output.outputs.username}}",
    "description": "User {{jp:$.trigger.output.outputs.userEmail}} requested access to {{jp:$.trigger.output.outputs.appName}}"
  }
}
```

### HTTP Status Codes

- `"202"` - Accepted (processing asynchronously) - recommended for most cases
- `"200"` - OK (synchronous acknowledgment)

### Security Considerations

- Each webhook URL contains a unique token
- Only share URLs with trusted systems
- Monitor webhook activity for unexpected calls
- Consider IP allowlisting at the network level

---

## Email and Slack Notifications

### SendEmailAction

**Purpose:** Send email notifications to internal users or external addresses.

```javascript
{
  "action": "SendEmailAction",
  "inputs": {
    "subject": "Your onboarding ticket requires attention",
    "userIds": ["user-id-1", "user-id-2"],  // Internal Ravenna users
    "ticketId": "jp:$.trigger.output.ticketId",
    "description": "Please review and complete the required tasks.",
    "emailAddresses": "external@company.com",  // Optional: external recipients
    "workspaceId": "...",
    "organizationId": "..."
  }
}
```

### SlackSendDmMessageAction

**Purpose:** Send direct messages to specific users via Slack.

```javascript
{
  "action": "SlackSendDmMessageAction",
  "inputs": {
    "message": "Your ticket has been inactive for 10 days. Please review and update.",
    "slackUserIds": ["jp:$.trigger.output.ticket.assignee.id"],
    "slackAppId": "slack-app-id",
    "workspaceId": "...",
    "organizationId": "..."
  }
}
```

### SlackSendChannelMessageAction

**Purpose:** Post messages to Slack channels.

```javascript
{
  "action": "SlackSendChannelMessageAction",
  "inputs": {
    "message": "New unassigned ticket requires attention: {{jp:$.trigger.output.ticket.title}}",
    "slackChannelId": "channel-id",
    "slackAppId": "slack-app-id",
    "slackIsEphemeral": false,  // true for messages only visible to one user
    "workspaceId": "...",
    "organizationId": "..."
  }
}
```

### Pattern: Conditional Notifications

Choose notification channel based on ticket state:

```javascript
// Check if ticket has an assignee
{
  "action": "IfElseAction",
  "inputs": {
    "filterGroups": [[{
      "field": "jp:$.loopStep.output.item.assigneeId",
      "value": null,
      "condition": "not_null"
    }]]
  }
}

// True branch: DM the assignee directly
{
  "action": "SlackSendDmMessageAction",
  "inputs": {
    "message": "Please review your stale ticket.",
    "slackUserIds": ["jp:$.loopStep.output.item.assigneeId"]
  }
}

// False branch: Alert the team channel
{
  "action": "SlackSendChannelMessageAction",
  "inputs": {
    "message": "Unassigned ticket needs attention.",
    "slackChannelId": "team-channel-id"
  }
}
```

### Multi-Channel Notification Strategy

| Scenario | Channel | Action |
|----------|---------|--------|
| Ticket has assignee | Slack DM | `SlackSendDmMessageAction` |
| No assignee | Slack Channel | `SlackSendChannelMessageAction` |
| External stakeholder | Email | `SendEmailAction` |
| Ticket comment (audit trail) | In-ticket | `RavTicketMessageAddAction` |

### Best Practices

1. **Prefer DMs for individual responsibility** - Direct accountability
2. **Use channels for team awareness** - When no specific owner exists
3. **Use email for external parties** - People outside your Slack workspace
4. **Always include context** - Ticket title, link, or relevant details in messages
5. **Avoid notification fatigue** - Only alert when action is truly needed

---

## Task Templates

### Overview

Task templates define reusable checklists that can be imported into tickets. They are ideal for standardized processes like onboarding, offboarding, and incident response.

### RavTicketImportTaskTemplateAction

**Purpose:** Import a predefined task template (checklist) into a ticket.

```javascript
{
  "action": "RavTicketImportTaskTemplateAction",
  "inputs": {
    "ticketId": "jp:$.trigger.output.ticketId",
    "taskTemplateId": "template-id",
    "workspaceId": "...",
    "organizationId": "..."
  }
}
```

### When to Use Task Templates

- **Onboarding** - Setup tasks (equipment, accounts, training)
- **Offboarding** - Cleanup tasks (revoke access, return equipment)
- **Incident Response** - Investigation steps and remediation checklist
- **Standard Operating Procedures** - Repeatable multi-step processes

### Best Practice: Import After Field Updates

Always update ticket custom fields BEFORE importing task templates. This ensures the template tasks can reference the correct ticket data.

```
Step 1: Extract data (AI prompt)
Step 2: Update ticket custom fields (RavTicketUpdateAction)
Step 3: Import task template (RavTicketImportTaskTemplateAction)
```

### Managing Task Templates

Use the following tools to manage task templates:
- `mcp__ravenna__taskTemplate__list` - List available templates
- `mcp__ravenna__taskTemplate__get` - Get template details
- `mcp__ravenna__taskTemplate__create` - Create new template
- `mcp__ravenna__taskTemplate__update` - Update existing template

---

## Step-by-Step Examples

### Example 1: Simple Auto-Tag Workflow

See original guide's Step-by-Step Example section (unchanged, still valid).

### Example 2: Approval-Based Access Request

**Goal:** Software access request requiring manager approval, then automated Okta provisioning

```javascript
// Step 1: Create workflow
const workflow = await create({ name: "Software Access with Approval" });

// Step 2: Add trigger
const trigger = await addStep({
  action: "RavTicketCreatedTrigger",
  inputs: {
    requestTypeIds: ["software-access-form-id"]
  }
});

// Step 3: Add approvers (from form field)
const addApprovers = await addStep({
  sourceId: trigger.id,
  action: "RavAddTicketApproversAction",
  inputs: {
    userIds: ["jp:$.{trigger.id}.output.ticket.requestType.{formId}.{approverField}.approverIds"],
    ticketId: "jp:$.{trigger.id}.output.ticketId"
  }
});

// Step 4: Wait 1s (ensures approvers are added)
const wait = await addStep({
  sourceId: addApprovers.id,
  action: "WaitAction",
  inputs: { duration: "1s" }
});

// Step 5: Wait for approval
const approval = await addStep({
  sourceId: wait.id,
  action: "WaitForApprovalAction",
  inputs: {
    duration: "3d",
    ticketId: "jp:$.{trigger.id}.output.ticketId"
  }
});

// Step 6: Fetch to find approval branches
const wf = await getWorkflow();
const groupId = wf.steps.find(s => s.id === approval.id).metadata.groupId;
const approved = wf.steps.find(s =>
  s.metadata.groupId === groupId &&
  (s.metadata.identifier === "center" || s.metadata.identifier === "center-placeholder")
);
const declined = wf.steps.find(s =>
  s.metadata.groupId === groupId &&
  (s.metadata.identifier === "left" || s.metadata.identifier === "left-placeholder")
);
const timeout = wf.steps.find(s =>
  s.metadata.groupId === groupId &&
  (s.metadata.identifier === "right" || s.metadata.identifier === "right-placeholder")
);

// Step 7: Handle approved branch
const addToOkta = await addStep({
  sourceId: approved.id,
  action: "OktaAddUserToGroupAction",
  inputs: {
    userIds: ["jp:$.{trigger.id}.output.ticket.requesterId"],
    oktaGroupIds: ["jp:$.{trigger.id}.output.ticket.accessLevel.userGroupIds"]
  }
});

await addStep({
  sourceId: addToOkta.id,
  action: "RavTicketMessageAddAction",
  inputs: {
    comment: "You've been granted access!",
    ticketId: "jp:$.{trigger.id}.output.ticketId"
  }
});

await addStep({
  action: "RavSetTicketStatusAction",
  inputs: {
    statusId: "done-status-id",
    ticketId: "jp:$.{trigger.id}.output.ticketId"
  }
});

// Step 8: Handle declined branch
await addStep({
  sourceId: declined.id,
  action: "RavTicketMessageAddAction",
  inputs: {
    comment: "Your request was declined.",
    ticketId: "jp:$.{trigger.id}.output.ticketId"
  }
});

await addStep({
  action: "RavSetTicketStatusAction",
  inputs: {
    statusId: "archived-status-id",
    ticketId: "jp:$.{trigger.id}.output.ticketId"
  }
});

// Step 9: Handle timeout branch
await addStep({
  sourceId: timeout.id,
  action: "RavTicketMessageAddAction",
  inputs: {
    comment: "Your request timed out. Please submit a new request.",
    ticketId: "jp:$.{trigger.id}.output.ticketId"
  }
});

await addStep({
  action: "RavSetTicketStatusAction",
  inputs: {
    statusId: "archived-status-id",
    ticketId: "jp:$.{trigger.id}.output.ticketId"
  }
});

// Step 10: Activate
await activate({ id: workflow.id });
```

---

## Common Action Types

### Trigger Actions

**RavTicketCreatedTrigger**
```javascript
{
  "action": "RavTicketCreatedTrigger",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "requestTypeIds": ["form-id"],  // Optional
    "filterGroups": [[...]]  // Optional
  }
}
```

**RavTicketFormSubmittedTrigger**
```javascript
{
  "action": "RavTicketFormSubmittedTrigger",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "formIds": ["form-id"],
    "requestTypeIds": ["form-id"]
  }
}
```

### Ticket Actions

**RavAddsTicketTagAction**
```javascript
{
  "action": "RavAddsTicketTagAction",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "ticketId": "jp:$.trigger.output.ticketId",
    "tagIds": ["tag-id-1", "tag-id-2"]
  }
}
```

**RavSetTicketStatusAction**
```javascript
{
  "action": "RavSetTicketStatusAction",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "ticketId": "jp:$.trigger.output.ticketId",
    "statusId": "status-id"  // Get from suggestions!
  }
}
```

**RavTicketMessageAddAction**
```javascript
{
  "action": "RavTicketMessageAddAction",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "ticketId": "jp:$.trigger.output.ticketId",
    "comment": "Message text with {{interpolation}}",
    "isPrivate": false,  // true for internal notes
    "filterGroups": [[...]]  // Optional: conditional execution
  }
}
```

**RavAddTicketApproversAction**
```javascript
{
  "action": "RavAddTicketApproversAction",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "ticketId": "jp:$.trigger.output.ticketId",
    "userIds": ["jp:$.trigger.output.ticket.managerIds"]
  }
}
```

**RavSetTicketAssigneeAction**
```javascript
{
  "action": "RavSetTicketAssigneeAction",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "ticketId": "jp:$.trigger.output.ticketId",
    "userId": "user-id",  // For User strategy
    "userIds": ["id1", "id2"],  // For Round Robin strategy
    "strategy": "User"  // or "Round Robin"
  }
}
```

### Wait Actions

**WaitAction**
```javascript
{
  "action": "WaitAction",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "duration": "1s"  // or "1m", "1h", "1d"
  }
}
```

**WaitForApprovalAction** (Creates 3 branches!)
```javascript
{
  "action": "WaitForApprovalAction",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "ticketId": "jp:$.trigger.output.ticketId",
    "duration": "3d",
    "approverIds": ["jp:$.trigger.output.ticket.approverIds"]  // Optional if added separately
  }
}
// Creates: center (approved), left (declined), right (timeout) placeholders
```

**WaitForMessageAction**
```javascript
{
  "action": "WaitForMessageAction",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "ticketId": "jp:$.trigger.output.ticketId",
    "duration": "3d",
    "userIds": ["jp:$.trigger.output.ticket.requesterId"]
  }
}
// Outputs: ticketMessage.message (the message content)
```

### Conditional Actions

**IfElseAction**
```javascript
{
  "action": "IfElseAction",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "filterGroups": [[{
      "field": "jp:$.trigger.output.ticket.fieldName",
      "value": "expected-value",
      "condition": "equals"
    }]]
  }
}
// Creates: left (true), right (false) placeholders
```

**AITicketConditionalAction**
```javascript
{
  "action": "AITicketConditionalAction",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "ticketId": "jp:$.trigger.output.ticketId",
    "description": "Clear question for AI to evaluate"
  }
}
// Creates: left (true), right (false) placeholders
```

**ai-prompt**
```javascript
{
  "action": "ai-prompt",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "prompt": "Context: {{jp:$.step.output.field}}\n\nQuestion: ...?"
  }
}
// Returns: isSuccess = true/false
```

### Integration Actions

**OktaAddUserToGroupAction**
```javascript
{
  "action": "OktaAddUserToGroupAction",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "userIds": ["jp:$.trigger.output.ticket.requesterId"],
    "oktaGroupIds": ["jp:$.trigger.output.ticket.accessLevel.userGroupIds"]
  }
}
```

**OktaResetMFAPasswordAction**
```javascript
{
  "action": "OktaResetMFAPasswordAction",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "userId": "jp:$.trigger.output.ticket.requesterId",
    "scope": "Password Only"  // or "MFA Only"
  }
}
```

**GoogleGetGroupInfoAction**
```javascript
{
  "action": "GoogleGetGroupInfoAction",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "googleGroupId": "jp:$.trigger.output.ticket.groupId",
    "googleGroupEmail": "{{jp:$.trigger.output.ticket.groupEmail}}"
  }
}
// Returns: googleGroupId, isSuccess
```

**GoogleUserInGroupAction**
```javascript
{
  "action": "GoogleUserInGroupAction",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "userId": "jp:$.trigger.output.ticket.requesterId",
    "googleGroupId": "jp:$.getGroupStep.output.googleGroupId"
  }
}
// Returns: isSuccess (true if user IS in group)
```

**GoogleAddUserToGroupAction / GoogleRemoveUserFromGroupAction**
```javascript
{
  "action": "GoogleAddUserToGroupAction",  // or GoogleRemoveUserFromGroupAction
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "userIds": ["jp:$.trigger.output.ticket.requesterId"],
    "googleGroupIds": ["jp:$.getGroupStep.output.googleGroupId"]
  }
}
```

### Control Flow Actions

**RavGotoAction** (Loop with budget)
```javascript
{
  "action": "RavGotoAction",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "stepId": "step-to-jump-to",
    "budget": 3  // Max iterations
  }
}
// Creates special "On Limit Reached" branch
```

**LoopAction** (Iterate over collections)
```javascript
{
  "action": "LoopAction",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "limit": 50,  // Maximum iterations
    "collection": ["jp:$.searchStep.output.ticketIds"]  // Array to loop over
  }
}
// Outputs: item (current), loop.size, loop.limit
```

**EndLoopAction** (Close a loop)
```javascript
{
  "action": "EndLoopAction",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "limit": "jp:$.loopStep.output.loop.limit"
  }
}
```

**RavSearchTicketsAction** (Search tickets with filters)
```javascript
{
  "action": "RavSearchTicketsAction",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "ticketFilter": [[
      {"field": "title", "value": "ONB_1", "condition": "contains"},
      {"field": "statusId", "value": ["done-id"], "condition": "not_in"}
    ]]
  }
}
// Outputs: ticketIds (array of matching tickets)
```

### Scheduled and Monitor Actions

**CronAction** (Scheduled trigger)
```javascript
{
  "action": "CronAction",
  "inputs": {
    "timezone": "UTC",
    "cronExpression": "59 23 * * *"  // Daily at 23:59 UTC
  }
}
```

**RavTicketMessageMonitor** (Wait for inactivity)
```javascript
{
  "action": "RavTicketMessageMonitor",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "duration": "10d",  // Wait for 10 days of NO activity
    "ticketId": "jp:$.trigger.output.ticket.id"
  }
}
```

**RavTicketMessageTrigger** (Trigger on any message)
```javascript
{
  "action": "RavTicketMessageTrigger",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "..."
  }
}
// Fires on ANY message sent to ANY ticket in the workspace
```

### Webhook Trigger

**ai-prompt-trigger** (Webhook with AI extraction)
```javascript
{
  "action": "ai-prompt-trigger",
  "inputs": {
    "prompt": "Extract the following values from the payload:\nuserEmail\nusername\nentitlementName",
    "directUrl": "https://core.ravenna.ai/api/workflows/run?token=...",
    "workspaceId": "...",
    "httpStatusCode": "202",
    "organizationId": "..."
  }
}
// Outputs: jp:$.trigger.output.outputs.{fieldName}
```

### Ticket Update Actions

**RavTicketUpdateAction** (Update ticket properties)
```javascript
{
  "action": "RavTicketUpdateAction",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "ticketId": "jp:$.trigger.output.ticketId",
    "title": "New title",        // Optional
    "statusId": "status-id",     // Optional
    "assigneeId": "user-id",     // Optional
    "dueAt": "2026-12-31",       // Optional
    "parentTicketId": "parent-id" // Optional: creates parent-child relationship
  }
}
```

**RavTicketUpdateAction - Custom Fields:**
```javascript
{
  "action": "RavTicketUpdateAction",
  "inputs": {
    "ticketId": "...",
    "request-type": {
      "formId": {
        "fieldId1": "value1",
        "fieldId2": "value2"
      }
    },
    "requestTypeId": "formId",
    "workspaceId": "...",
    "organizationId": "..."
  }
}
```

**RavTicketImportTaskTemplateAction** (Import checklist)
```javascript
{
  "action": "RavTicketImportTaskTemplateAction",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "ticketId": "jp:$.trigger.output.ticketId",
    "taskTemplateId": "template-id"
  }
}
```

### Messaging Actions

**SendEmailAction**
```javascript
{
  "action": "SendEmailAction",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "subject": "Email subject",
    "userIds": ["user-id-1", "user-id-2"],
    "ticketId": "jp:$.trigger.output.ticketId",
    "description": "Email body content",
    "emailAddresses": "external@email.com"  // Optional: external recipients
  }
}
```

**SlackSendDmMessageAction**
```javascript
{
  "action": "SlackSendDmMessageAction",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "message": "Direct message content",
    "slackUserIds": ["jp:$.trigger.output.ticket.assignee.id"],
    "slackAppId": "slack-app-id"
  }
}
```

**SlackSendChannelMessageAction**
```javascript
{
  "action": "SlackSendChannelMessageAction",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "message": "Channel message content",
    "slackChannelId": "channel-id",
    "slackAppId": "slack-app-id",
    "slackIsEphemeral": false
  }
}
```

### Google Workspace Actions

**GoogleCheckEmailAvailabilityAction**
```javascript
{
  "action": "GoogleCheckEmailAvailabilityAction",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "email": "desired-alias@domain.com"
  }
}
// Output: isSuccess = true if email is available
```

**GoogleCreateEmailAliasAction**
```javascript
{
  "action": "GoogleCreateEmailAliasAction",
  "inputs": {
    "workspaceId": "...",
    "organizationId": "...",
    "userId": "jp:$.trigger.output.ticket.requesterId",
    "aliasEmail": "alias@domain.com"
  }
}
```

---

## Troubleshooting

### Issue: "Multiple start steps" Error
**Cause:** Adding a step without `sourceId` creates a new root.

**Solution:** Always specify `sourceId` except for the initial trigger.

### Issue: Fields Not Interpolating
**Cause:** Using wrong reference format (e.g., `{{step.field}}` instead of `jp:$.step.output.field`).

**Solution:**
1. Get step with `suggestions: true`
2. Use exact `referenceId` from `inputsWithSuggestions`

### Issue: Conditional Not Working
**Cause:** Adding actions directly to conditional instead of to placeholder children.

**Solution:**
1. Fetch workflow after adding conditional
2. Find placeholder steps by `groupId` and `identifier`
3. Add your actions as children of these placeholders

### Issue: Approval Has No Timeout Branch
**Cause:** Not fetching workflow after adding WaitForApprovalAction.

**Solution:**
1. Fetch workflow after adding approval step
2. Find all 3 placeholders: center, left, right
3. Handle all 3 branches

### Issue: Loop Never Stops
**Cause:** RavGotoAction without budget or missing "On Limit Reached" handler.

**Solution:**
1. Always set `budget` parameter
2. Add step to handle limit reached case
3. Test the loop limit

### Issue: Wrong Status/Tag ID
**Cause:** Using hardcoded IDs from another workspace or old data.

**Solution:** Always get IDs dynamically from suggestions or list endpoints.

### Issue: Operation "Failed" But Actually Worked
**Cause:** Backend inconsistency between error response and actual state.

**Solution:** Always fetch the latest workflow state before assuming failure.

### Issue: filterGroups Not Working
**Cause:** Wrong field path or condition.

**Solution:**
1. Get step with suggestions to see available fields
2. Use exact field paths from suggestions
3. Test condition logic (equals, not_null, etc.)

### Issue: Integration Action Failing
**Cause:** Resource doesn't exist, user lacks permissions, or filterGroups preventing execution.

**Solution:**
1. Validate resource exists first (Get action)
2. Check filterGroups aren't blocking execution
3. Always handle `isSuccess = false` case

---

## Production Checklist

### Before Building
- [ ] Get workspace and organization IDs
- [ ] List available actions (`workflowConfig__listApps`)
- [ ] Identify required tags and get/create them
- [ ] Identify required statuses (workspace-specific!)
- [ ] Identify form IDs if using form triggers
- [ ] Map out workflow logic on paper/diagram

### During Building
- [ ] Create workflow in Draft state
- [ ] Add trigger step first (with optional filterGroups)
- [ ] **Fetch workflow after adding ANY conditional or wait action**
- [ ] Find placeholder steps by `groupId` and `identifier`
- [ ] Get field references from `suggestions` (set to true!)
- [ ] Use correct reference format: `jp:$.stepId.output.fieldName`
- [ ] Get status/tag/resource IDs from suggestions dynamically
- [ ] Handle ALL branches:
  - [ ] IfElse: left (true), right (false)
  - [ ] AIConditional: left (true), right (false)
  - [ ] WaitForApproval: center (approved), left (declined), right (timeout)
  - [ ] RavGoto: normal loop + On Limit Reached
- [ ] Add appropriate status transitions at workflow end
- [ ] Include error messages and escalation paths
- [ ] Use filterGroups for conditional execution where needed
- [ ] Add 1s wait after adding approvers

### After Building
- [ ] Connect before deleting when restructuring
- [ ] Verify workflow state after operations that return errors
- [ ] Do final verification fetch before activating
- [ ] Review all connections have proper criteria
- [ ] Verify all reference IDs are correct format
- [ ] Check all status IDs are from current workspace

### Before Activating
- [ ] Test workflow with a real test ticket
- [ ] Verify all branches execute correctly
- [ ] Check messages appear as expected
- [ ] Confirm status transitions work
- [ ] Validate error handling paths
- [ ] Document the workflow purpose and key decisions

### After Activating
- [ ] Monitor first few executions
- [ ] Check for any errors or unexpected behavior
- [ ] Verify notifications go to right people
- [ ] Confirm integrations work as expected
- [ ] Collect user feedback

---

## Key Takeaways

1. **🔴🔴🔴 THE GOLDEN RULE: ALWAYS VERIFY BEFORE AND AFTER** - Never make changes without getting suggestions first. Always verify after each update before proceeding. This prevents cascading errors across multiple steps.
2. **Always fetch after conditionals** - They create hidden placeholder steps
3. **Update placeholders directly, don't add children** - Use `updateStep` to replace PlaceholderAction with real actions. Cleaner structure!
4. **Use suggestions for references** - `jp:$` format is mandatory, get from suggestions
5. **CRITICAL: Use `.output` not `.input`** - When referencing other steps, use `.output`. Only the step itself sees its data as `.input`. Always fetch suggestions from the consuming step's perspective!
6. **Always prefer synthetic fields** - When suggestions show both direct and synthetic fields, use the synthetic one (e.g., `.manager.id` not `.managerId`)
7. **User mentions require `.userMention`** - The `{{@...}}` syntax ONLY works with fields ending in `.userMention`. For others (like managers), use HTML mention format.
8. **Text fields need `{{}}`, select fields don't** - Wrap text/textarea/richtexteditor fields in `{{jp:$...}}`, but use direct `jp:$...` for select/multiselect
9. **filterGroups are powerful** - Use for both trigger filtering AND conditional execution; multiple groups = OR logic
10. **Handle every branch** - Approved/Declined/Timeout, True/False, Limit Reached
11. **Status IDs vary by workspace** - Never hardcode, always get dynamically
12. **Wait 1s after adding approvers** - Ensures they're added before approval flow
13. **Always set budget on loops** - Prevent infinite loops (use LoopAction limit for collections)
14. **Don't trust error messages** - Verify actual state after operations
15. **Use AI for ambiguity** - Great for intent detection, confirmation checking, and date calculations
16. **Test before activating** - Create test ticket and watch execution
17. **Always search after monitors** - Ticket state may change during wait periods
18. **Use Loop limit: 1 for single results** - Common pattern for parent ticket lookup
19. **Import task templates after field updates** - Ensures templates can reference ticket data
20. **Conditional notifications** - DM assignee if exists, channel if not
21. **Multi-strategy search with fallback** - Try email, then personal email, then name, then escalate

---

## Conclusion

Building production-ready workflows in Ravenna requires understanding:
1. **The verification workflow** - ALWAYS verify field references before and after each update
2. The hidden complexity (automatic placeholder creation)
3. **Update placeholders directly instead of adding children** - Use `updateStep` for cleaner workflows
4. Correct field reference formats (`jp:$` with suggestions)
5. **CRITICAL distinction between `.input` and `.output`** - Always use `.output` when referencing other steps
6. **Synthetic field preference** - Use synthetic fields when available (`.manager.id` not `.managerId`)
7. **User mention requirements** - Only `.userMention` fields work with `{{@...}}`; use HTML format for others
8. **Text vs select field interpolation** - Wrap text fields in `{{}}`, use direct references for select fields
9. filterGroups for both filtering and conditional execution (AND within groups, OR between groups)
10. Proper error handling and escalation paths
11. Status management and appropriate transitions
12. Integration patterns (validate -> check -> modify)
13. Loop and search patterns for batch operations
14. Parent-child ticket relationships for complex workflows
15. Scheduled workflows (CronAction) for proactive operations
16. Monitoring patterns (RavTicketMessageMonitor) for stale ticket detection
17. Webhook integration (ai-prompt-trigger) for external system connectivity
18. Multi-channel notifications (email, Slack DM, Slack channel, in-ticket)
19. Task templates for standardized checklists

Follow these patterns from real production workflows and you'll build reliable, maintainable workflows that handle edge cases gracefully!

**Remember:** These patterns are proven in production at enterprise scale. When in doubt, refer back to the production examples!

---

## 🔴🔴🔴 FINAL REMINDER: THE VERIFICATION WORKFLOW

**Before you start ANY workflow building or fixing:**

```
┌─────────────────────────────────────────────────┐
│                                                 │
│   1. VERIFY → Get suggestions                   │
│   2. UPDATE → Use verified references           │
│   3. VERIFY → Confirm it worked                 │
│   4. PROCEED → Move to next step                │
│                                                 │
│   NEVER skip verification!                      │
│   NEVER batch multiple updates without checking!│
│   NEVER assume references are correct!          │
│                                                 │
└─────────────────────────────────────────────────┘
```

**This one habit will save you hours of debugging runtime errors.**
