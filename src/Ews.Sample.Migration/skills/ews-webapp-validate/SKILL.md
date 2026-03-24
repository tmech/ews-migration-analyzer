---
name: ews-webapp-validate
description: "Validate a running web application using Playwright browser automation during or after EWS-to-Graph migration. Launches the app, navigates key pages, verifies email list rendering, reply form behavior, error handling, and Graph API integration. Use this skill during refactoring (Phase 4b/4c) or final validation (Stage 05) to catch regressions automatically."
license: MIT
compatibility: "Requires .NET SDK 9.0+, Playwright for .NET (Microsoft.Playwright NuGet package), and a running instance of the web application under test."
metadata:
  stage: "cross-cutting"
  category: "ews-migration"
  prerequisites: "ews-instrument"
---

# Skill: Web Application Validation with Playwright

## Purpose

You are an AI assistant specialized in validating web applications using Playwright browser automation. Your goal is to verify that the EWS-to-Graph migration has not broken any user-facing functionality by automating browser interactions against the running application.

Manual testing is error-prone and slow. Playwright enables repeatable, automated validation of all use cases documented in `requirements.md` — catching regressions that unit tests alone cannot detect (rendering issues, authentication flows, JavaScript errors, HTTP failures).

## Context

This is a **cross-cutting skill** in the EWS Migration Skills Marketplace. It can be invoked:

- **During Phase 4b** (Implement Graph API): Validate the app works with the Graph API feature toggle enabled
- **During Phase 4c** (Remove EWS): Confirm the app still works after EWS removal
- **During Stage 05** (Final Validation): Comprehensive end-to-end runtime validation
- **Standalone**: Any time the developer wants to validate the running web app

The skill works alongside the Aspire dashboard (Skill 02) — Playwright validates the user experience while Aspire monitors the backend telemetry.

## Prerequisites

- Application running (preferably under Aspire from Skill 02)
- Application URL known (e.g., `https://localhost:7020` or from Aspire dashboard)
- `requirements.md` available (from Skill 01) documenting use cases to validate
- User credentials available for authenticated testing (or test account configured)

---

## What You Do

### Step 1: Set Up Playwright

If Playwright is not already installed in the solution:

1. **Add a Playwright test project** (or add to the existing test project):

   ```shell
   dotnet new nunit -n [ProjectName].PlaywrightTests
   dotnet add [ProjectName].PlaywrightTests package Microsoft.Playwright.NUnit
   dotnet sln add [ProjectName].PlaywrightTests/[ProjectName].PlaywrightTests.csproj
   ```

2. **Install Playwright browsers**:

   ```shell
   pwsh bin/Debug/net9.0/playwright.ps1 install
   ```

3. **Add project to solution** and verify it builds:

   ```shell
   dotnet build [ProjectName].PlaywrightTests
   ```

> **Note**: If the agent environment has a Playwright MCP tool or browser automation capability available, use it directly instead of creating a test project. The goal is browser validation, not test infrastructure.

### Step 2: Validate Authentication Flow

Create a validation that verifies the login flow:

1. Navigate to the application URL
2. Verify redirect to the Microsoft login page (or Entra ID)
3. If test credentials are available:
   - Complete the sign-in flow
   - Verify redirect back to the application
   - Verify the user identity is displayed
4. If test credentials are NOT available:
   - Verify the redirect URL is correct
   - Ask the developer to complete authentication manually
   - Continue validation after manual login

```csharp
[Test]
public async Task Authentication_RedirectsToLogin_AndReturnsToApp()
{
    await Page.GotoAsync(AppUrl);

    // Should redirect to Microsoft login
    await Expect(Page).ToHaveURLAsync(new Regex(@"login\.microsoftonline\.com"));

    // After manual or automated login, should return to app
    // ... (credentials-dependent)
}
```

### Step 3: Validate Email List (Inbox)

Verify the primary use case — viewing inbox emails:

1. Navigate to the inbox/home page (after authentication)
2. Verify the page loads without errors
3. Check that email items are rendered:
   - Subject lines visible
   - Sender names/addresses visible
   - Dates displayed
   - Read/unread status indicated
4. Verify no JavaScript console errors
5. Verify no HTTP 4xx/5xx responses in network traffic

```csharp
[Test]
public async Task Inbox_DisplaysEmailList_WithExpectedFields()
{
    await Page.GotoAsync($"{AppUrl}/Mail");

    // Wait for emails to load
    await Page.WaitForSelectorAsync("[data-testid='email-item'], .email-row, tr");

    // Verify at least one email is displayed
    var emailItems = await Page.QuerySelectorAllAsync("[data-testid='email-item'], .email-row, tbody tr");
    Assert.That(emailItems.Count, Is.GreaterThan(0), "No emails displayed in inbox");

    // Verify no console errors
    var consoleErrors = new List<string>();
    Page.Console += (_, msg) => { if (msg.Type == "error") consoleErrors.Add(msg.Text); };
    Assert.That(consoleErrors, Is.Empty, $"Console errors found: {string.Join(", ", consoleErrors)}");
}
```

### Step 4: Validate Email Detail View

Verify viewing a single email:

1. Click on the first email in the list
2. Verify the detail view loads
3. Check that email fields are populated:
   - Full subject
   - Sender with display name
   - Date/time
   - Email body content
   - To/CC recipients
4. Verify the Reply button/link is present

### Step 5: Validate Reply Flow

Verify the reply-to-email use case:

1. From an email detail view, click Reply
2. Verify the reply form appears with:
   - Pre-filled recipient (original sender)
   - Pre-filled subject with "RE:" prefix
   - Original email body quoted
   - Empty reply body field
3. Enter test reply text
4. Submit the reply form
5. Verify success feedback (redirect, flash message, or confirmation)
6. Check for HTTP errors in network traffic

### Step 6: Validate Error Handling

Test common error scenarios:

1. **Invalid email ID**: Navigate to `/Mail/Details/invalid-id-12345`
   - Verify graceful error handling (not a stack trace)
2. **Network monitoring**: Check Aspire dashboard for:
   - All Graph API calls returning 200/201
   - No 401/403 errors (token issues)
   - No 429 errors (throttling)
   - No 500 errors (server failures)

### Step 7: Capture Validation Evidence

Generate validation artifacts:

1. **Screenshots**: Capture screenshots of each validated page
   - `screenshot-inbox.png`
   - `screenshot-email-detail.png`
   - `screenshot-reply-form.png`
   - `screenshot-reply-success.png`
2. **Network log**: Export relevant network requests (especially Graph API calls)
3. **Console log**: Capture any browser console warnings/errors
4. **Validation report**: Generate a summary markdown file

```markdown
# Web Application Validation Report

## Application URL: [URL]
## Validated: [Date/Time]
## API Backend: [EWS / Graph API]

### Use Case Results
| Use Case | Status | Notes |
|----------|--------|-------|
| Authentication | ✅ Pass | Redirects to Entra ID, returns to app |
| View Inbox | ✅ Pass | [N] emails displayed correctly |
| View Email Detail | ✅ Pass | All fields populated |
| Reply to Email | ✅ Pass | Reply sent successfully |
| Error Handling | ✅ Pass | Invalid IDs handled gracefully |

### Network Summary
- Total API calls: [N]
- Successful (2xx): [N]
- Client errors (4xx): [N]
- Server errors (5xx): [N]
- Graph API calls detected: [Yes/No]
- EWS calls detected: [Yes/No]

### Screenshots
- [Links to captured screenshots]

### Console Errors
- [None / List of errors]
```

---

## Using Agent Browser Tools (Alternative)

If running within an agent environment that has Playwright MCP or browser automation tools:

1. Use `browser_navigate` to navigate to the application URL
2. Use `browser_snapshot` to capture page state at each step
3. Use `browser_click` to interact with email items, reply buttons, etc.
4. Use `browser_take_screenshot` to capture evidence
5. Use `browser_console_messages` to check for JavaScript errors
6. Use `browser_network_requests` to verify API call success

This approach requires no test project setup and provides immediate feedback.

---

## Reference Documentation

- Playwright for .NET: <https://playwright.dev/dotnet/>
- Playwright NUnit Integration: <https://playwright.dev/dotnet/docs/test-runners>
- Playwright Assertions: <https://playwright.dev/dotnet/docs/test-assertions>
- AI Assisted EWS Migration Tutorial: <https://aka.ms/ewsToolsAITutorial>

## Acceptance Criteria

- [ ] Application is running and accessible at a known URL
- [ ] Authentication flow validated (redirect + return)
- [ ] Inbox email list loads with visible email items
- [ ] Email detail view displays all expected fields
- [ ] Reply form pre-fills correctly and submission succeeds
- [ ] No unhandled JavaScript errors in browser console
- [ ] No HTTP 4xx/5xx errors in network traffic
- [ ] Screenshots captured as validation evidence
- [ ] Validation report generated
- [ ] If post-migration: Graph API calls confirmed in network traffic (no EWS calls)

## Human Checkpoint

Present the validation report and screenshots to the developer:

1. **"Does the application work correctly in the browser?"**
   - If no: investigate failures using Aspire dashboard and Playwright output
2. **"Are all use cases from requirements.md validated?"**
   - If no: identify missing use cases and add validation steps
3. **"Are you satisfied with the validation evidence?"**
   - Options: [Approve validation] [Re-run with more scenarios] [Investigate failures]

Do NOT mark validation as complete without explicit human approval.

---

## Integration Points

This skill is invoked by the orchestrator at these points:

- **Phase 4b checkpoint**: After Graph API implementation, validate the app works with `UseGraphApi: true`
- **Phase 4c checkpoint**: After EWS removal, validate the app works without any EWS code
- **Stage 05 Step 3**: Runtime validation of all use cases as part of final sign-off
