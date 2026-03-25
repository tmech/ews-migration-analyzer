# Reference Documentation — Multi-Model Code Review

## Code Review Methodology

### Consensus-Based Review

The multi-model approach uses **consensus voting** to filter signal from noise:

| Consensus | Meaning | Action |
|-----------|---------|--------|
| 3/3 models agree | Almost certainly a real issue | Fix before proceeding |
| 2/3 models agree | Likely a real issue | Recommended fix |
| 1/3 model only | Possible false positive | Review only if CRITICAL severity |

### Severity Levels

| Severity | Definition | Examples |
|----------|------------|---------|
| **CRITICAL** | Will cause runtime failure or data loss | Null reference, unhandled exception, data corruption |
| **HIGH** | Security vulnerability or significant bug | Token exposure, missing auth check, wrong API endpoint |
| **MEDIUM** | Could cause issues under specific conditions | Missing retry logic, edge case not handled, incorrect error message |

### What NOT to Flag

- Code style, formatting, naming conventions
- Missing documentation or comments
- Test coverage gaps (unless a test is actively wrong)
- Minor refactoring suggestions
- Performance micro-optimizations

## Models

### Primary Configuration

| Model | ID | Provider | Role |
|-------|----|----------|------|
| Claude Opus 4.6 | `claude-opus-4.6` | Anthropic | Deep reasoning, architecture |
| Gemini 3 Pro | `gemini-3-pro-preview` | Google | Pattern recognition, API validation |
| Claude Sonnet 4.5 | `claude-sonnet-4.5` | Anthropic | Fast practical bug detection |

### Fallback Models

| Primary | Fallback 1 | Fallback 2 |
|---------|------------|------------|
| `claude-opus-4.6` | `claude-opus-4.5` | `gpt-5.1-codex` |
| `gemini-3-pro-preview` | `gpt-5.2` | `gpt-4.1` |
| `claude-sonnet-4.5` | `claude-sonnet-4` | `gpt-5.4-mini` |

## Migration-Specific Review Checklist

### Graph API Integration (Phase 4b)

- [ ] `GraphServiceClient` configured with correct scopes
- [ ] `$select` used to limit returned properties (performance)
- [ ] `$top` used to limit result set size
- [ ] `ServiceException` handled for Graph API errors
- [ ] HTTP 429 throttling handled with retry
- [ ] HTTP 401/403 handled gracefully (token refresh, re-auth prompt)
- [ ] Null checks on all Graph API response properties
- [ ] Property mapping from Graph `Message` to domain `EmailMessage` is complete
- [ ] No hardcoded URLs — use SDK methods

### EWS Removal (Phase 4c)

- [ ] Zero references to `Microsoft.Exchange.WebServices.*` namespaces
- [ ] No orphaned EWS NuGet packages in `.csproj` files
- [ ] No leftover EWS configuration in `appsettings.json`
- [ ] Feature toggle (`UseGraphApi`) removed — Graph is the only path
- [ ] No dead code paths that referenced EWS types
- [ ] Using statements cleaned up

### Service Layer (Phase 4a)

- [ ] `IEmailService` interface covers all email operations
- [ ] Controller depends only on `IEmailService` (no EWS/Graph types)
- [ ] DI registration is correct (`AddScoped`, not `AddSingleton` for auth-dependent services)
- [ ] Domain model (`EmailMessage`) has no dependency on EWS or Graph types
- [ ] Error handling preserved during extraction

## EWS Migration Documentation

- **EWS to Graph API Mappings**: <https://aka.ms/ews2graphMap>
- **Graph API Error Handling**: <https://learn.microsoft.com/en-us/graph/errors>
- **Graph API Throttling**: <https://learn.microsoft.com/en-us/graph/throttling>
- **Graph SDK Best Practices**: <https://learn.microsoft.com/en-us/graph/sdks/sdks-overview>
- **AI Assisted EWS Migration Tutorial**: <https://aka.ms/ewsToolsAITutorial>
- **Midnight Blizzard Incident**: <https://aka.ms/mblizz>

## Git Integration

### Review Scope Commands

```shell
# Review since last checkpoint
git log --oneline --grep="checkpoint:" -1
git diff <checkpoint-sha>..HEAD

# Review a specific commit
git show <sha> --stat

# Review a commit range
git diff <start>..<end>

# Review staged changes
git diff --cached
```

### After Fixes

```shell
# Verify fixes compile
dotnet build

# Verify fixes don't break tests
dotnet test

# Re-run review to confirm resolution
# (invoke ews-code-review skill again)
```
