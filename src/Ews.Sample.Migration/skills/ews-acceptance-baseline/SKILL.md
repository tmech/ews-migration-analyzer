---
name: ews-acceptance-baseline
description: "Capture a Playwright acceptance-test baseline of the running web application before migration begins. Walks every identifiable user flow (inbox, reply, error handling), records page structure, screenshots, network health, and console state as the 'golden' baseline. After migration, re-runs the identical walkthrough to confirm zero functional regressions. Use early (Stage 00/01) to lock in baseline behavior and again at Stage 05 to verify the migrated app."
license: MIT
compatibility: "Requires a running instance of the web application and an agent environment with Playwright MCP browser tools (browser_navigate, browser_snapshot, browser_click, etc.)."
metadata:
  stage: "cross-cutting"
  category: "ews-migration"
  prerequisites: "none"
---

# Skill: Acceptance-Test Baseline with Playwright

## Purpose

You are an AI assistant that builds a lightweight, automated acceptance test for a web application **before any migration work begins**. The test walks every major user-facing flow in the browser, captures evidence of correct behavior, and produces a reusable walkthrough script. After migration, you re-run the exact same walkthrough and compare results to confirm nothing is broken.

### Why Up Front?

Unit tests validate internal contracts; acceptance tests validate **what the user actually sees**. Capturing the baseline early means:

- The acceptance walkthrough is defined against the *known-good* app — not reverse-engineered from requirements later
- The same walkthrough becomes the **migration finish line** — if the post-migration app passes the same checks, it works
- Regressions in rendering, routing, authentication, or JavaScript are caught immediately — things unit tests cannot cover

## Context

This is a **cross-cutting skill** in the EWS Migration Skills Marketplace. It is invoked:

- **Stage 00 / 01 — Capture baseline**: Run against the original EWS-backed application to record golden behavior
- **Phase 4b — Graph implementation**: Optionally re-run to verify the app works with Graph
- **Phase 4c — EWS removal**: Re-run to verify the app works without EWS
- **Stage 05 — Final validation**: Re-run as the definitive acceptance gate before sign-off

The skill complements `ews-webapp-validate` (which provides ad-hoc validation at any point) by establishing a **deterministic, repeatable baseline** that can be diffed against post-migration state.

## Prerequisites

- Application running and accessible at a known URL (e.g., `https://localhost:7020`)
- Agent environment with Playwright MCP browser tools available
- User authenticated (or test credentials available) — the skill will prompt for manual login if needed

---

## What You Do

### Phase A — Capture Baseline (invoke early, before migration)

#### Step 1: Discover the Application

Before automating, understand what to test:

1. **Read `requirements.md`** (if available from Skill 01) to identify documented use cases
2. **Read the controller(s)** to identify all routable actions and their HTTP methods
3. **Read the views** to identify page structure, forms, and interactive elements
4. **Produce a flow inventory** — a list of every user-facing flow to walk:

```markdown
## Flow Inventory

| ID | Flow | Route | Method | Key Assertions |
|----|------|-------|--------|----------------|
| F1 | View inbox | /Mail | GET | Page title "Mailbox", email table with rows, Subject/From/Date columns |
| F2 | Reply to email | /Mail/Reply?id={id} | GET | Reply form with To (readonly), Subject (RE: prefix), Body (quoted) |
| F3 | Send reply | /Mail/SendReply | POST | Redirect to inbox, success alert visible |
| F4 | Error — invalid ID | /Mail/Reply?id=invalid | GET | Graceful handling, no stack trace, redirect or error message |
| F5 | Authentication | / | GET | Redirect to login.microsoftonline.com (or app loads if already authed) |
```

Present the flow inventory to the developer:

> **"I identified [N] user flows to baseline. Review the list above — should I add, remove, or modify any flows before capturing?"**

**Do NOT proceed without developer confirmation of the flow inventory.**

#### Step 2: Walk Each Flow and Capture Baseline

For each flow in the inventory, execute the walkthrough using agent browser tools:

##### F1 — View Inbox (Primary Flow)

```
1. browser_navigate → {AppUrl}/Mail
2. browser_snapshot → Capture accessibility tree
3. Assertions:
   - Page title contains "Mailbox" or app name
   - A <table> element is present with thead columns: Subject, From, Date, Actions
   - At least one <tr> in <tbody> (email rows exist)
   - Each row has a "Reply" link/button
4. browser_console_messages(level: "error") → Record any JS errors (expect: none)
5. browser_network_requests → Record all requests, flag any 4xx/5xx (expect: none)
6. browser_take_screenshot → Save as "baseline-inbox.png"
```

Record the baseline evidence:

```markdown
### F1 — View Inbox — BASELINE
- **URL**: /Mail
- **Title**: "Mailbox - Contoso Mail"
- **Table columns**: Subject | From | Date | Actions
- **Email rows**: [N] rows displayed
- **Reply buttons**: [N] (one per row)
- **Console errors**: 0
- **Network errors**: 0
- **Screenshot**: baseline-inbox.png
```

##### F2 — Reply to Email

```
1. From the inbox, click the first "Reply" link:
   browser_click → first Reply button/link in the table
2. browser_snapshot → Capture reply form
3. Assertions:
   - Page title contains "Reply"
   - Form fields present: To (readonly, pre-filled), Subject (RE: prefix), Body (quoted original)
   - "Send Reply" submit button present
   - "Cancel" link present
4. browser_console_messages(level: "error") → Expect: none
5. browser_network_requests → Flag any 4xx/5xx (expect: none)
6. browser_take_screenshot → Save as "baseline-reply-form.png"
```

Record:

```markdown
### F2 — Reply to Email — BASELINE
- **URL**: /Mail/Reply?id={captured-id}
- **To field**: {sender address}, readonly
- **Subject field**: "RE: {original subject}"
- **Body field**: Contains quoted original message
- **Send button**: Present
- **Cancel link**: Present
- **Console errors**: 0
- **Network errors**: 0
- **Screenshot**: baseline-reply-form.png
```

##### F3 — Send Reply (Optional — Destructive)

> ⚠️ **This flow actually sends an email.** Ask the developer before executing:
>
> **"Flow F3 sends a real reply email. Should I:"**
> - [✅ Execute with a test reply body — I have a test mailbox]
> - [📸 Capture the form state only — skip actual send]
> - [⏭️ Skip this flow entirely]

If approved:

```
1. From the reply form (F2), fill the Body field:
   browser_type → ref: Body textarea, text: "[ACCEPTANCE TEST] Baseline verification — please ignore"
2. browser_take_screenshot → Save as "baseline-reply-filled.png"
3. browser_click → "Send Reply" button
4. browser_snapshot → Capture result page
5. Assertions:
   - Redirected back to /Mail (inbox)
   - Success alert visible ("Reply sent successfully!")
   - No error alerts
6. browser_take_screenshot → Save as "baseline-reply-success.png"
```

##### F4 — Error Handling

```
1. browser_navigate → {AppUrl}/Mail/Reply?id=invalid-id-12345
2. browser_snapshot → Capture error response
3. Assertions:
   - No unhandled exception / stack trace visible
   - Either: error message displayed, OR redirect to inbox with error alert
   - HTTP status is not 500
4. browser_console_messages(level: "error") → Record (some errors may be expected)
5. browser_take_screenshot → Save as "baseline-error-handling.png"
```

##### F5 — Authentication Check

```
1. browser_navigate → {AppUrl}/ (root)
2. browser_snapshot → Capture initial state
3. Assertions:
   - If not authenticated: URL redirects to login.microsoftonline.com
   - If authenticated: App loads with user identity visible
4. browser_take_screenshot → Save as "baseline-auth.png"
```

#### Step 3: Generate the Baseline Report

Produce `acceptance-baseline.md` in the project root:

```markdown
# Acceptance-Test Baseline Report

## Application: [Name]
## Captured: [Date/Time]
## Application URL: [URL]
## API Backend: EWS (pre-migration)

## Flow Inventory

| ID | Flow | Status | Console Errors | Network Errors |
|----|------|--------|----------------|----------------|
| F1 | View Inbox | ✅ Baseline captured | 0 | 0 |
| F2 | Reply to Email | ✅ Baseline captured | 0 | 0 |
| F3 | Send Reply | ✅ Baseline captured | 0 | 0 |
| F4 | Error Handling | ✅ Baseline captured | 0 | 0 |
| F5 | Authentication | ✅ Baseline captured | 0 | 0 |

## Detailed Baselines

### F1 — View Inbox
[recorded evidence from Step 2]

### F2 — Reply to Email
[recorded evidence from Step 2]

...

## Screenshots
- baseline-inbox.png
- baseline-reply-form.png
- baseline-reply-filled.png
- baseline-reply-success.png
- baseline-error-handling.png
- baseline-auth.png

## Baseline Fingerprint

Structural assertions that MUST hold after migration:

1. Inbox page renders a table with columns: Subject, From, Date, Actions
2. Each email row has a Reply action
3. Reply form has fields: To (readonly), Subject, Body
4. Reply form has Send and Cancel actions
5. Sending a reply redirects to inbox with success feedback
6. Invalid email IDs are handled gracefully (no stack trace)
7. Unauthenticated access redirects to login provider
8. Zero JavaScript console errors on all pages
9. Zero HTTP 4xx/5xx errors during normal flows
```

#### Step 4: Generate the Reusable Walkthrough Script

Produce `acceptance-walkthrough.md` — a step-by-step script that can be re-executed by the agent at any future point:

```markdown
# Acceptance Walkthrough Script

## How to Use
Re-run this script against the running application to verify acceptance criteria.
Compare results against `acceptance-baseline.md` to detect regressions.

## Prerequisites
- Application running at {AppUrl}
- User authenticated
- Agent has Playwright MCP browser tools

## Steps

### 1. Inbox Validation
- Navigate to {AppUrl}/Mail
- Take snapshot
- Assert: page title contains "Mailbox"
- Assert: table exists with columns Subject, From, Date, Actions
- Assert: at least 1 email row in table body
- Assert: each row has a Reply link
- Check console errors (expect: 0)
- Check network errors (expect: 0)
- Screenshot: inbox.png

### 2. Reply Form Validation
- Click first Reply link in inbox table
- Take snapshot
- Assert: page title contains "Reply"
- Assert: To field is present and readonly
- Assert: Subject field contains "RE:" prefix
- Assert: Body field contains quoted original text
- Assert: Send Reply button present
- Assert: Cancel link present
- Check console errors (expect: 0)
- Check network errors (expect: 0)
- Screenshot: reply-form.png

### 3. Send Reply Validation (if approved)
- Type test message in Body field
- Click Send Reply
- Take snapshot
- Assert: redirected to /Mail
- Assert: success message visible
- Assert: no error messages
- Screenshot: reply-success.png

### 4. Error Handling Validation
- Navigate to {AppUrl}/Mail/Reply?id=invalid-id-12345
- Take snapshot
- Assert: no stack trace visible
- Assert: graceful error (message or redirect)
- Screenshot: error-handling.png

### 5. Authentication Validation
- Navigate to {AppUrl}/
- Take snapshot
- Assert: redirects to login OR shows authenticated app
- Screenshot: auth.png
```

Commit both files with the `ews-git-checkpoint` skill:

```
checkpoint: post-acceptance-baseline — Playwright acceptance baseline captured for [N] user flows
```

---

### Phase B — Verify Post-Migration (invoke after migration)

#### Step 1: Re-Run the Walkthrough

1. Load `acceptance-walkthrough.md` from the project
2. Execute every step in the walkthrough script against the migrated application
3. Capture the same evidence (snapshots, screenshots, console/network state)

#### Step 2: Compare Against Baseline

For each flow, compare the post-migration result against `acceptance-baseline.md`:

| Check | Baseline | Post-Migration | Status |
|-------|----------|----------------|--------|
| **F1 — Inbox** | | | |
| Page title | "Mailbox - Contoso Mail" | "Mailbox - Contoso Mail" | ✅ Match |
| Table columns | Subject, From, Date, Actions | Subject, From, Date, Actions | ✅ Match |
| Email rows | ≥ 1 | ≥ 1 | ✅ Match |
| Reply links | Present | Present | ✅ Match |
| Console errors | 0 | 0 | ✅ Match |
| Network errors | 0 | 0 | ✅ Match |
| **F2 — Reply Form** | | | |
| To field (readonly) | ✅ | ✅ | ✅ Match |
| Subject (RE: prefix) | ✅ | ✅ | ✅ Match |
| Body (quoted) | ✅ | ✅ | ✅ Match |
| Console errors | 0 | 0 | ✅ Match |
| **F4 — Error Handling** | | | |
| Graceful handling | ✅ | ✅ | ✅ Match |
| No stack trace | ✅ | ✅ | ✅ Match |

**New checks for post-migration only:**

| Check | Expected | Actual | Status |
|-------|----------|--------|--------|
| Graph API calls in network traffic | Present | ? | ✅ / ❌ |
| EWS calls in network traffic | Absent | ? | ✅ / ❌ |

#### Step 3: Generate Comparison Report

Produce `acceptance-verification.md`:

```markdown
# Acceptance-Test Verification Report

## Application: [Name]
## Verified: [Date/Time]
## Application URL: [URL]
## API Backend: Graph API (post-migration)
## Baseline Captured: [Baseline Date]

## Results Summary

| Flow | Baseline | Post-Migration | Verdict |
|------|----------|----------------|---------|
| F1 — View Inbox | ✅ Pass | ✅ Pass | ✅ No regression |
| F2 — Reply Form | ✅ Pass | ✅ Pass | ✅ No regression |
| F3 — Send Reply | ✅ Pass | ✅ Pass | ✅ No regression |
| F4 — Error Handling | ✅ Pass | ✅ Pass | ✅ No regression |
| F5 — Authentication | ✅ Pass | ✅ Pass | ✅ No regression |

## Migration-Specific Checks

| Check | Status |
|-------|--------|
| Graph API calls detected | ✅ Yes |
| EWS calls detected | ✅ None (expected) |
| New console errors | ✅ None |
| New network errors | ✅ None |

## Screenshot Comparison
| Flow | Baseline | Post-Migration |
|------|----------|----------------|
| Inbox | baseline-inbox.png | verify-inbox.png |
| Reply | baseline-reply-form.png | verify-reply-form.png |
| Error | baseline-error-handling.png | verify-error-handling.png |

## Verdict: ✅ PASS — Application behavior unchanged after migration
```

#### Step 4: Present Results

> **"Acceptance verification complete. [N/N] flows passed with no regressions. Graph API calls confirmed, zero EWS calls detected."**
>
> **"Do you approve the acceptance test results?"**
> - [✅ Approve — app works correctly after migration]
> - [🔍 Investigate a specific flow]
> - [🔄 Re-run verification]
> - [⏪ Revert to checkpoint — migration broke something]

**Do NOT mark verification as passed without explicit human approval.**

---

## Adapting to Other Applications

The flow inventory in Step 1 is application-specific. For apps other than the Contoso Mail sample:

1. **Read the controllers/routes** to identify all user-facing endpoints
2. **Read the views/templates** to identify forms, tables, and interactive elements
3. **Read `requirements.md`** (if available) to identify documented use cases
4. **Build a flow inventory** covering:
   - Every page the user can navigate to
   - Every form the user can submit
   - Every list/table the user can view
   - Key error scenarios (invalid input, missing data)
   - Authentication/authorization boundaries

The walkthrough script format is generic — it works for any web application regardless of the backend API.

---

## Reference Documentation

- Playwright MCP Browser Tools: See [references/REFERENCE.md](references/REFERENCE.md)
- AI Assisted EWS Migration Tutorial: <https://aka.ms/ewsToolsAITutorial>

---

## Acceptance Criteria

- [ ] Flow inventory produced and confirmed by developer
- [ ] Every flow walked with Playwright browser tools
- [ ] Baseline evidence captured (snapshots, screenshots, console/network state)
- [ ] `acceptance-baseline.md` generated with structural fingerprint
- [ ] `acceptance-walkthrough.md` generated as reusable script
- [ ] Baseline committed via `ews-git-checkpoint`
- [ ] (Post-migration) Walkthrough re-executed against migrated app
- [ ] (Post-migration) Comparison report shows zero regressions
- [ ] (Post-migration) Graph API calls confirmed, EWS calls absent
- [ ] Human approval obtained for both baseline capture and post-migration verification

---

## Human Checkpoint

### At Baseline Capture

1. **"I identified [N] user flows. Review the flow inventory — should I add, remove, or modify any?"**
   - Options: [Approve flows] [Add a flow] [Remove a flow] [Modify a flow]
2. **"Baseline captured for all [N] flows. Review the baseline report and screenshots."**
   - Options: [Approve baseline] [Re-capture a flow] [Add more flows]

### At Post-Migration Verification

1. **"Verification complete. [N/N] flows passed. Review the comparison report."**
   - Options: [Approve — no regressions] [Investigate failures] [Re-run] [Revert to checkpoint]

**Never skip human approval at either checkpoint.**

---

## Integration Points

This skill is invoked by the orchestrator at these points:

- **After Skill 00 or 01** (early): Capture the acceptance baseline while the app is in its original EWS state
- **Phase 4b** (optional): Re-run walkthrough after Graph API implementation
- **Phase 4c** (recommended): Re-run walkthrough after EWS removal
- **Stage 05 Step 3** (required): Definitive acceptance verification as part of final sign-off
