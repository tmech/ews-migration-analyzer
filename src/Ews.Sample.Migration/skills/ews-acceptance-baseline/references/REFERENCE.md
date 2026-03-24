# Reference Documentation — Acceptance-Test Baseline

## Playwright MCP Browser Tools

When running within an agent environment that has Playwright MCP tools, use these for the acceptance walkthrough:

| Tool | Use Case |
|------|----------|
| `browser_navigate` | Navigate to app URLs (`/Mail`, `/Mail/Reply?id=...`) |
| `browser_snapshot` | Capture accessibility tree for structural assertions |
| `browser_click` | Click email rows, Reply buttons, Send/Cancel actions |
| `browser_type` | Fill reply body text field |
| `browser_fill_form` | Fill multiple form fields at once |
| `browser_take_screenshot` | Capture visual evidence (baseline + verification) |
| `browser_console_messages` | Check for JavaScript errors (level: "error") |
| `browser_network_requests` | Verify API call success, detect EWS vs Graph calls |
| `browser_wait_for` | Wait for dynamic content to load |

## Common Playwright Patterns

### Navigate and Verify Page Title

```
browser_navigate → {AppUrl}/Mail
browser_snapshot → check page title in accessibility tree
```

### Assert Table Structure

From `browser_snapshot` output, verify:
- `<table>` element present
- `<thead>` with expected column headers (Subject, From, Date, Actions)
- `<tbody>` with at least one `<tr>` (data rows)

### Click an Element by Role

```
browser_click → ref: link with text "Reply" in the first table row
```

### Assert Form Fields

From `browser_snapshot` output, verify:
- Textbox fields present with expected labels (To, Subject, Body)
- Readonly attribute on To field
- Submit button present ("Send Reply")
- Cancel link present

### Check Console Errors

```
browser_console_messages → level: "error"
```

Expected: empty list. Any errors indicate a regression.

### Check Network Requests

```
browser_network_requests → includeStatic: false
```

Review for:
- Any responses with status ≥ 400 (client/server errors)
- Post-migration: Graph API calls present (`graph.microsoft.com`)
- Post-migration: EWS calls absent (`outlook.office365.com/EWS`)

### Capture Screenshots

```
browser_take_screenshot → type: "png", filename: "baseline-inbox.png"
```

Use consistent naming for baseline/verification comparison:
- Baseline: `baseline-{flow}.png`
- Verification: `verify-{flow}.png`

## Baseline Fingerprint Assertions

The following structural assertions should hold before AND after migration. They are independent of the backend API:

### Page Structure

| Page | Assertion | How to Check |
|------|-----------|--------------|
| Inbox | Title contains "Mailbox" | `browser_snapshot` → page title |
| Inbox | Email table with Subject, From, Date columns | `browser_snapshot` → table headers |
| Inbox | At least 1 email row | `browser_snapshot` → table body rows |
| Inbox | Reply action per row | `browser_snapshot` → link/button in each row |
| Reply | Title contains "Reply" | `browser_snapshot` → page title |
| Reply | To field (readonly, pre-filled) | `browser_snapshot` → textbox attributes |
| Reply | Subject field with "RE:" prefix | `browser_snapshot` → textbox value |
| Reply | Body field with quoted text | `browser_snapshot` → textarea content |
| Reply | Send and Cancel actions | `browser_snapshot` → button + link |

### Behavioral

| Behavior | Assertion | How to Check |
|----------|-----------|--------------|
| Send reply | Redirects to inbox | `browser_snapshot` → URL + page title |
| Send reply | Success message visible | `browser_snapshot` → alert element |
| Invalid ID | No stack trace | `browser_snapshot` → no exception text |
| Invalid ID | Graceful error | `browser_snapshot` → error message or redirect |
| Auth required | Redirects to login | `browser_navigate` → URL changes to login.microsoftonline.com |

### Health

| Check | Assertion | How to Check |
|-------|-----------|--------------|
| Console | Zero JS errors | `browser_console_messages` level: "error" → empty |
| Network | Zero 4xx/5xx | `browser_network_requests` → no status ≥ 400 |

## Comparison Strategy

When comparing baseline to post-migration:

1. **Structural match**: Same page elements, form fields, table columns exist
2. **Behavioral match**: Same user flows produce same outcomes (redirects, messages)
3. **Health match**: Same zero-error state for console and network
4. **Backend shift**: Network traffic shows Graph API calls instead of EWS calls

**Acceptable differences** post-migration:
- Different internal IDs in URLs (Graph IDs differ from EWS IDs)
- Slightly different email body quoting format
- Additional Graph-specific network requests (token refresh, etc.)
- Performance differences (Graph may be faster or slower)

**Unacceptable differences** (regressions):
- Missing page elements (table, form fields, buttons)
- New JavaScript console errors
- New HTTP 4xx/5xx errors
- Broken navigation (pages that loaded before now fail)
- Missing functionality (Reply button gone, form submission fails)

## EWS Migration

- **AI Assisted EWS Migration Tutorial**: <https://aka.ms/ewsToolsAITutorial>
- **Graph Mail API Overview**: <https://learn.microsoft.com/en-us/graph/api/resources/mail-api-overview>
