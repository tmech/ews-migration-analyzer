# Reference Documentation — Web Application Validation

## Playwright for .NET

- **Playwright .NET Documentation**: <https://playwright.dev/dotnet/>
- **Getting Started with Playwright .NET**: <https://playwright.dev/dotnet/docs/intro>
- **NUnit Integration**: <https://playwright.dev/dotnet/docs/test-runners>
- **Playwright Assertions**: <https://playwright.dev/dotnet/docs/test-assertions>
- **Page Object Model Pattern**: <https://playwright.dev/dotnet/docs/pom>
- **Authentication in Tests**: <https://playwright.dev/dotnet/docs/auth>
- **Network Interception**: <https://playwright.dev/dotnet/docs/network>

## NuGet Packages

| Package | Purpose |
|---------|---------|
| `Microsoft.Playwright` | Core Playwright library for .NET |
| `Microsoft.Playwright.NUnit` | NUnit integration for Playwright tests |

## Common Playwright Patterns

### Page Navigation and Assertion

```csharp
await Page.GotoAsync("https://localhost:7020/Mail");
await Expect(Page).ToHaveTitleAsync(new Regex("Mail"));
```

### Waiting for Dynamic Content

```csharp
// Wait for email list to load
await Page.WaitForSelectorAsync(".email-row");

// Wait for network idle (all API calls complete)
await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);
```

### Screenshot Capture

```csharp
await Page.ScreenshotAsync(new PageScreenshotOptions
{
    Path = "screenshot-inbox.png",
    FullPage = true
});
```

### Network Monitoring

```csharp
var responses = new List<IResponse>();
Page.Response += (_, response) => responses.Add(response);

await Page.GotoAsync(url);

// Check for errors
var errors = responses.Where(r => r.Status >= 400).ToList();
Assert.That(errors, Is.Empty);
```

### Console Error Monitoring

```csharp
var consoleErrors = new List<string>();
Page.Console += (_, msg) =>
{
    if (msg.Type == "error")
        consoleErrors.Add(msg.Text);
};
```

## Agent Browser Tools (MCP)

When running within an agent that has Playwright MCP tools:

| Tool | Use Case |
|------|----------|
| `browser_navigate` | Navigate to app URL |
| `browser_snapshot` | Capture accessibility tree for assertions |
| `browser_click` | Click email items, buttons, links |
| `browser_fill_form` | Fill reply form fields |
| `browser_take_screenshot` | Capture visual evidence |
| `browser_console_messages` | Check for JS errors |
| `browser_network_requests` | Verify API call success |

## EWS Migration

- **AI Assisted EWS Migration Tutorial**: <https://aka.ms/ewsToolsAITutorial>
- **Graph Mail API Overview**: <https://learn.microsoft.com/en-us/graph/api/resources/mail-api-overview>
