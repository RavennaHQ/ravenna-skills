# Debug Ravenna Workflows Skill

Debug and test Ravenna workflows by manually triggering them with custom payloads and analyzing execution results. Essential for workflow development, troubleshooting production issues, and validating logic before deployment.

## Usage

This skill teaches you how to:
1. **Manually trigger workflows** with custom test data
2. **Monitor execution** and check status
3. **Analyze step-by-step results** to identify issues
4. **Debug failures** using audit events and outputs
5. **Iterate quickly** on workflow logic

## Prerequisites

- Active MCP connection to `plugin:ravenna:ravenna`
- Workflow ID you want to debug
- Basic understanding of your workflow's expected inputs

---

## Instructions for Claude

When this skill is invoked, help the user debug Ravenna workflows using the MCP tools.

### Step 1: Ensure MCP Connection

Before starting, verify MCP tools are available.

**If tools are unavailable:**

```bash
# User should run these commands:
/reload-plugins
/mcp
# Then select: plugin:ravenna:ravenna
```

**Common MCP issues:**
- `Invalid authorization token` → Check `RAVENNA_API_KEY` environment variable
- Tools suddenly disappear → Use `/reload-plugins` then `/mcp`
- Tool calls failing → Reconnect via `/mcp` command

### Step 2: Find the Workflow

**If user knows the workflow ID:**
- Use it directly: `wf_XXXXXXXXXX`

**If user needs to find it:**

```typescript
// List all workflows
mcp__plugin_ravenna_ravenna__workflow__list({
  workspaceId: "workspace_id_here"  // User provides
})
```

Look for workflow by name or description in the results.

### Step 3: Trigger the Workflow

Use `workflow__trigger` to manually execute the workflow with test data:

```typescript
mcp__plugin_ravenna_ravenna__workflow__trigger({
  workflowId: "wf_XXXXXXXXXX",
  body: {
    // Your test payload here
    event_type: "alert_created",
    alert: {
      id: "test_incident_123"
    }
  }
})
```

**Key points:**
- `body` accepts any JSON structure
- Structure must match what workflow expects
- Use realistic test data, not just "test" values
- Can include nested objects, arrays, etc.

**Response:**
```json
{
  "runId": "ravenna_lo_webhook_tr_XXXXX"
}
```

**Save this `runId`** - you'll need it to check results!

### Step 4: Wait for Completion

Workflows typically complete in 2-5 seconds. Wait before checking:

```bash
sleep 3  # Wait 3 seconds
```

For complex workflows with many steps or external API calls, wait longer (5-10 seconds).

### Step 5: Get Workflow Run Details

Retrieve complete execution details:

```typescript
mcp__plugin_ravenna_ravenna__workflow__getWorkflowRun({
  id: "ravenna_lo_webhook_tr_XXXXX"  // runId from trigger
})
```

This returns a detailed object with:
- Overall run status
- All executed steps
- Inputs and outputs for each step
- Audit events and error messages
- Workflow version used

### Step 6: Analyze the Results

#### 6.1 Check Overall Status

```json
{
  "id": "ravenna_lo_webhook_tr_XXXXX",
  "status": "completed",    // ✓ Success
  "status": "failed",       // ✗ Error occurred
  "status": "running",      // ⏳ Still executing
  "workflowId": "wf_...",
  "workflowVersionId": "wfv_...",
  "steps": [...]
}
```

**If status is "running":**
- Wait longer and check again
- Some workflows take time

**If status is "failed":**
- Proceed to step analysis to find which step failed

#### 6.2 Analyze Each Step

The `steps[]` array contains detailed information for every step:

```json
{
  "id": "step_result_XXXXX",
  "stepId": "step_0417084337201_siw",
  "status": "completed" | "failed" | "skipped",
  "inputs": { /* Configured input parameters */ },
  "outputs": { /* Step results */ },
  "inferredInputs": { /* Actual values used at runtime */ },
  "auditEvents": [ /* Execution logs and errors */ ]
}
```

**Critical fields for debugging:**

**1. `status` field:**
- `completed` - Step ran successfully ✓
- `failed` - Step encountered an error ✗
- `skipped` - Conditional logic bypassed this step ⊘

**2. `inferredInputs` (MOST IMPORTANT):**
Shows the **actual data** that reached the step at runtime:

```json
"inferredInputs": {
  "body": {
    "event_type": "alert_created",
    "alert": { "id": "test_incident_123" }
  },
  "runId": "ravenna_lo_webhook_tr_XXXXX",
  "ticketId": "cmo38xjk9000d5yxqozp0cqwa"
}
```

**Why this matters:**
- Shows if your test payload reached the step correctly
- Reveals data transformation issues
- Shows values passed from previous steps
- First place to check when debugging "why didn't this work?"

**Common issues revealed by inferredInputs:**
- `body: {}` → Payload wasn't passed correctly
- Missing expected fields → Previous step didn't output what you expected
- Wrong data type → String instead of number, etc.

**3. `outputs.output`:**
Shows what the step returned:

```json
"outputs": {
  "output": {
    "incidentId": "postgres_down_12:00",
    "isAlertCreated": true,
    "ticketId": "cmo38xjk9000d5yxqazp0cqwa"
  }
}
```

**Use this to:**
- Verify step produced expected results
- Check if data flows to next step correctly
- Validate business logic

**4. `auditEvents` (for errors):**
Contains detailed execution logs:

```json
"auditEvents": [{
  "entityType": "workflow",
  "event": "workflow_step_failed",
  "message": "Cannot read property 'id' of undefined",
  "level": "error",
  "data": {
    "error": "TypeError: Cannot read property 'id' of undefined at line 42",
    "stack": "..."
  }
}]
```

**Use this to:**
- Find exact error messages
- Get stack traces for code action failures
- Understand why a step failed

#### 6.3 Common Debugging Patterns

**Pattern 1: Find which step failed**

```typescript
// Look through steps array
for (const step of run.steps) {
  if (step.status === "failed") {
    console.log(`Failed step: ${step.stepId}`)
    console.log(`Error:`, step.auditEvents)
  }
}
```

**Pattern 2: Trace data flow**

```typescript
// Check what data each step received
run.steps.forEach((step, index) => {
  console.log(`Step ${index + 1}:`, step.title || step.stepId)
  console.log(`  Inputs:`, step.inferredInputs)
  console.log(`  Outputs:`, step.outputs)
})
```

**Pattern 3: Verify payload structure**

```typescript
// Check if your test data reached the workflow
const firstStep = run.steps[0]
console.log(`Payload received:`, firstStep.inferredInputs.body)

// Compare with what you sent
// Expected: { event_type: "alert_created", alert: {...} }
// Actual: ???
```

**Pattern 4: Check conditional logic**

```typescript
// Find skipped steps
const skippedSteps = run.steps.filter(s => s.status === "skipped")

console.log(`Skipped ${skippedSteps.length} steps`)

// Check previous step's output to see why
// Likely a conditional branch wasn't satisfied
```

### Step 7: Debug Common Issues

#### Issue 1: Empty Payload

**Symptom:**
```json
"inferredInputs": {
  "body": {}  // Empty!
}
```

**Causes:**
- Payload not passed in trigger call
- Workflow version doesn't accept manual triggers
- Data structure mismatch

**Solution:**
1. Verify trigger call includes `body` parameter
2. Check workflow version ID - may need to update workflow
3. Try different payload structure

#### Issue 2: Step Unexpectedly Skipped

**Symptom:**
```json
{
  "stepId": "step_send_notification",
  "status": "skipped"
}
```

**Causes:**
- Conditional logic not satisfied
- Filter groups on connection didn't match
- Previous step's output doesn't meet criteria

**Solution:**
1. Check the workflow's connection criteria (filter groups)
2. Look at previous step's output
3. Adjust test payload to satisfy conditions
4. Example: If condition checks `severity === "critical"`, ensure payload includes that

#### Issue 3: Code Action Failed

**Symptom:**
```json
{
  "status": "failed",
  "auditEvents": [{
    "message": "Error: Missing required parameter: apiKey",
    "level": "error"
  }]
}
```

**Causes:**
- Required input parameter missing
- Wrong parameter type (string vs number)
- Code action has a bug

**Solution:**
1. Read error message in auditEvents
2. Check inferredInputs - are all required params present?
3. Verify parameter types match code action's schema
4. Test code action in isolation if possible

#### Issue 4: Wrong Workflow Version

**Symptom:**
Expected step doesn't appear in run.steps array

**Cause:**
Workflow has multiple versions, triggered an old version

**Solution:**
1. Check `workflowVersionId` in response
2. Compare with current workflow version
3. Publish/activate correct workflow version
4. Trigger again

#### Issue 5: Data Not Flowing Between Steps

**Symptom:**
Step 2 should receive data from Step 1, but doesn't

**Example:**
```json
// Step 1 output
"outputs": { "ticketId": "abc123" }

// Step 2 input (WRONG)
"inferredInputs": { "ticketId": undefined }
```

**Causes:**
- Step 2 input uses wrong JSONPath expression
- Step 1 output structure unexpected
- Workflow configuration issue

**Solution:**
1. Verify Step 1 actually outputs the expected field
2. Check Step 2's input configuration (JSONPath like `jp:$.step1.output.ticketId`)
3. Adjust workflow connections if needed

### Step 8: Iterate and Retest

Once you've identified the issue:

1. **Fix the problem:**
   - Update workflow logic
   - Adjust test payload
   - Fix code action
   - Correct input parameters

2. **Trigger again:**
   ```typescript
   mcp__plugin_ravenna_ravenna__workflow__trigger({
     workflowId: "wf_XXXXXXXXXX",
     body: { /* updated payload */ }
   })
   ```

3. **Verify fix:**
   - Check new run status
   - Verify problematic step now succeeds
   - Confirm expected outputs

4. **Test edge cases:**
   - Try different payloads
   - Test error conditions
   - Validate all branches

### Step 9: Document Findings

Provide clear summary to user:

**For successful debugging:**

```
✅ Issue identified and fixed!

Problem: Step "Create Ticket" was receiving undefined incident_id
Cause: Payload used "id" but workflow expected "incident_id"
Fix: Updated payload structure

Test results:
- Run ID: ravenna_lo_webhook_tr_XXXXX
- Status: completed
- All steps executed successfully
- Ticket created: HDE-152
```

**For identified issues:**

```
🔍 Debugging analysis:

Issue: Workflow failing at step 2 "Parse Alert Data"
Error: "Cannot read property 'severity' of undefined"

Root cause:
- Step expects payload.alert.severity
- But payload only has payload.severity
- Missing nested "alert" object

Recommended fix:
- Update workflow to read from payload.severity directly
- OR adjust webhook sender to nest data under "alert" key

Test payload for verification:
{
  "alert": {
    "severity": "critical",
    "id": "test_123"
  }
}
```

---

## Example Workflows

### Example 1: Basic Debugging

**User:** "My workflow wf_i1Al2SFwZZ isn't working"

**Steps:**

1. **Trigger with test data:**
```typescript
mcp__plugin_ravenna_ravenna__workflow__trigger({
  workflowId: "wf_i1Al2SFwZZ",
  body: {
    event_type: "alert_created",
    alert: { id: "debug_test_1" }
  }
})
// Returns: { runId: "ravenna_lo_webhook_tr_abc" }
```

2. **Wait and retrieve:**
```bash
sleep 3
```
```typescript
mcp__plugin_ravenna_ravenna__workflow__getWorkflowRun({
  id: "ravenna_lo_webhook_tr_abc"
})
```

3. **Analyze:**
- Status: `completed` ✓
- Step 1 (AI Prompt): `completed` ✓
- Step 2 (Create Ticket): `failed` ✗

4. **Find error:**
```json
{
  "stepId": "step_create_ticket",
  "status": "failed",
  "auditEvents": [{
    "message": "Missing required field: title"
  }]
}
```

5. **Check inputs:**
```json
"inferredInputs": {
  "title": "",  // Empty!
  "description": "...",
  "priority": "high"
}
```

6. **Root cause:**
Title is empty because it's supposed to come from Step 1's output, but Step 1 didn't output it correctly.

7. **Fix:**
Update Step 1 to output title field, or provide static title in Step 2 configuration.

### Example 2: Testing Different Scenarios

**User:** "Test workflow with critical, warning, and info alerts"

**Test 1 - Critical:**
```typescript
mcp__plugin_ravenna_ravenna__workflow__trigger({
  workflowId: "wf_i1Al2SFwZZ",
  body: {
    severity: "critical",
    incident_id: "db_outage"
  }
})
```

**Result:** Ticket created with URGENT priority ✓

**Test 2 - Warning:**
```typescript
mcp__plugin_ravenna_ravenna__workflow__trigger({
  workflowId: "wf_i1Al2SFwZZ",
  body: {
    severity: "warning",
    incident_id: "high_cpu"
  }
})
```

**Result:** Ticket created with MEDIUM priority ✓

**Test 3 - Info:**
```typescript
mcp__plugin_ravenna_ravenna__workflow__trigger({
  workflowId: "wf_i1Al2SFwZZ",
  body: {
    severity: "info",
    incident_id: "deployment"
  }
})
```

**Result:** No ticket created (step skipped by conditional) ✓

**Summary:** Workflow correctly routes based on severity.

### Example 3: Debugging Data Flow

**User:** "Data isn't flowing from AI step to Create Ticket step"

**Trigger:**
```typescript
mcp__plugin_ravenna_ravenna__workflow__trigger({
  workflowId: "wf_i1Al2SFwZZ",
  body: {
    event_type: "private_alert.alert_created_v1",
    private_alert: {
      alert_created_v1: { id: "postgres_down_12:00" }
    }
  }
})
```

**Analyze Step 1 (AI Prompt):**
```json
{
  "stepId": "step_ai_parse",
  "status": "completed",
  "outputs": {
    "output": {
      "outputs": {
        "incidentId": "postgres_down_12:00",
        "isAlertCreated": true
      }
    }
  }
}
```

**Analyze Step 2 (Create Ticket):**
```json
{
  "stepId": "step_create_ticket",
  "inferredInputs": {
    "title": "HALP - postgres_down_12:00",  // ✓ Correct!
    "description": "",
    "priority": "URGENT"
  },
  "status": "completed"
}
```

**Finding:** Data IS flowing correctly! Title includes incident ID from Step 1.

**User's issue was a misunderstanding.** Show them the inferredInputs proving data flow works.

---

## Best Practices

### 1. Start Simple
- Use minimal test payloads first
- Add complexity incrementally
- Isolate variables

### 2. Check Every Step
- Don't just look at overall status
- Examine each step individually
- Trace data through the entire flow

### 3. Read inferredInputs First
- This shows actual runtime data
- Reveals 90% of issues immediately
- Don't assume data structure—verify it

### 4. Use Realistic Test Data
- Don't use "test", "foo", "bar"
- Use realistic IDs, names, values
- Include edge cases (empty strings, nulls, large numbers)

### 5. Test All Branches
- Workflows often have conditional logic
- Test each possible path
- Verify skip conditions work correctly

### 6. Save Working Payloads
- Document test cases that work
- Maintain regression test suite
- Reuse payloads when retesting

### 7. Iterate Quickly
- Fix one thing at a time
- Test immediately after each change
- Don't accumulate multiple changes

---

## Quick Reference

### Essential MCP Tools

```typescript
// List workflows
mcp__plugin_ravenna_ravenna__workflow__list({
  workspaceId: "workspace_id"
})

// Trigger workflow
mcp__plugin_ravenna_ravenna__workflow__trigger({
  workflowId: "wf_XXXXX",
  body: { /* test data */ }
})

// Get run details
mcp__plugin_ravenna_ravenna__workflow__getWorkflowRun({
  id: "ravenna_lo_webhook_tr_XXXXX"
})
```

### Key Response Fields

```typescript
// Overall run
{
  status: "completed" | "failed" | "running",
  workflowId: "wf_...",
  workflowVersionId: "wfv_...",
  steps: [...]
}

// Individual step
{
  status: "completed" | "failed" | "skipped",
  inferredInputs: { /* ACTUAL runtime data */ },
  outputs: { /* Step results */ },
  auditEvents: [ /* Logs and errors */ ]
}
```

### Debugging Checklist

- [ ] MCP connection active
- [ ] Workflow ID correct
- [ ] Test payload matches expected structure
- [ ] Waited for completion (3-5 seconds)
- [ ] Checked overall status
- [ ] Examined each step's status
- [ ] Reviewed inferredInputs for data issues
- [ ] Read auditEvents for error messages
- [ ] Verified workflow version is current
- [ ] Tested fix with new run

---

## Summary

This skill enables effective workflow debugging using Ravenna's MCP tools. The core debugging loop:

1. **Trigger** workflow with test data
2. **Wait** for completion
3. **Retrieve** detailed run results
4. **Analyze** step-by-step execution
5. **Identify** root cause via inferredInputs and auditEvents
6. **Fix** the issue
7. **Retest** to verify

**Key insight:** The `inferredInputs` field shows actual runtime data and reveals most issues immediately. Always check this first when debugging.

**Pro tip:** Test workflows manually before deploying to production. Catch issues early when they're easy to fix.
