---
name: ews-architect
description: "Modernize the architecture of a .NET application for observability, maintainability, and testability. Begins by producing a spec/PRD that documents use cases and non-functional requirements, then derives architectural decisions and a test safety net directly from that spec BEFORE making any structural changes. Applies Clean Architecture layering, OpenTelemetry instrumentation, health checks, Result pattern, and Options pattern — each traceable to a spec requirement. Use after migrating from EWS to Graph API, or at any point when an application needs architectural uplift."
license: MIT
compatibility: "Requires .NET SDK 9.0+, .NET Aspire, xUnit, NSubstitute. Recommended after ews-refactor."
metadata:
  stage: "cross-cutting"
  category: "ews-migration"
  prerequisites: "ews-refactor"
---

# Skill: Architecture Modernization

## Purpose

You are an AI assistant specialized in modernizing .NET application architecture through a **spec-driven** approach. Your goal is to transform a migrated EWS application into a well-structured, production-grade system by:

1. **Documenting** what the application does today — producing a spec/PRD with use cases, non-functional requirements, and quality attribute scenarios
2. **Testing** the documented behavior — creating a regression safety net *before* any structural changes
3. **Architecting** for three key qualities — making every pattern choice traceable to a spec requirement:
   - **Observability** — NFRs define what must be visible at runtime → drives OpenTelemetry, health checks, structured logging
   - **Maintainability** — Use case complexity drives layer separation → drives Clean Architecture, Options pattern, Result pattern
   - **Testability** — Acceptance criteria define what must be verified → drives integration tests, architecture tests, test data builders

The spec is the connective tissue: every architectural decision traces back to a documented requirement, and every test traces back to a documented use case.

## Context

This skill is a cross-cutting skill in the EWS Migration Skills Marketplace. It is most valuable after Skill 04 (Refactor & Migrate to Graph API), where the application already has a basic service layer with interfaces and dependency injection. This skill elevates that foundation into a mature architecture.

The skill follows a deliberate sequence — **understand → test → restructure**:

1. **Phase 1** produces the spec that drives all subsequent decisions
2. **Phase 2** locks in current behavior with tests *before any code changes*
3. **Phases 3–6** apply architectural patterns, each referencing the spec requirements they satisfy

The skill builds on two existing skills:

- **ews-understand** (Skill 01) may have produced an initial `requirements.md`. Phase 1 of this skill extends it with non-functional requirements, quality attribute scenarios, and architectural decision records.
- **ews-test** (Skill 03) may have produced unit tests. Phase 2 of this skill verifies coverage against the spec's use cases and fills gaps before restructuring begins.

## Prerequisites

- Completed Skill 04 (Refactor) — application uses IEmailService with GraphEmailService
- All unit tests passing
- Application running under .NET Aspire
- Dependency injection configured in Program.cs

---

## Phase 1: Spec & Architectural Decision Record

### Goal

Produce a living specification that documents what the application does (use cases), what qualities it must exhibit (non-functional requirements), and which architectural patterns will achieve those qualities (architectural decisions). This spec becomes the single source of truth that drives every subsequent phase.

### Why Spec First

Legacy applications often lack documentation, and teams modernize by pattern-shopping — "let's add Clean Architecture" — without connecting patterns to actual needs. A spec-driven approach ensures:

- Every pattern has a *reason* traceable to a requirement
- Tests verify *documented behavior*, not assumed behavior
- The team can review architectural decisions before code changes begin
- Future maintainers understand *why* the architecture looks the way it does

### Steps

#### 1. Analyze Current Application Behavior

Walk through the entire codebase and document every user-facing capability:

- Open each controller/page and trace the request flow end-to-end
- Identify all entry points (routes, endpoints, background tasks)
- Document the data flow: user input → service call → external API → response
- Note error handling behavior: what happens when things fail?
- Note authentication/authorization requirements per use case

**Copilot prompt**: `Analyze all controllers, services, and views in this application. For each user-facing action, document the complete request flow including input validation, service calls, external API interactions, error handling, and the response returned to the user.`

#### 2. Produce the Spec/PRD

Create or update `architecture-spec.md` in the project root with this structure:

```markdown
# Architecture Modernization Spec

## 1. Application Overview
[Brief description, tech stack, current architecture diagram]

## 2. Use Cases

### UC-1: View Inbox
- **Actor**: Authenticated M365 user
- **Trigger**: Navigate to /Mail
- **Preconditions**: User is authenticated with valid token
- **Main Flow**:
  1. Controller receives request
  2. Service fetches top N emails via Graph API
  3. Emails mapped to view models
  4. View renders email list
- **Alternative Flows**:
  - Token expired → redirect to login
  - Graph API unreachable → error page with retry option
- **Acceptance Criteria**:
  - AC-1.1: Inbox displays up to 10 emails sorted by date descending
  - AC-1.2: Each email shows subject, sender, date, and read status
  - AC-1.3: Unread emails are visually distinct
- **Architectural Implications**:
  - Needs retry/resilience for Graph API calls → **ADR-3: Resilience patterns**
  - Must track fetch latency for SLA monitoring → **ADR-2: Custom metrics**

### UC-2: View Email Detail
...

### UC-3: Reply to Email
...

## 3. Non-Functional Requirements

### NFR-1: Observability
- **Requirement**: Operations team must be able to monitor email operation success rates, latencies, and error counts in real-time
- **Quality Attribute Scenario**: When a Graph API call fails, the operations team can identify the failure within 60 seconds through dashboard alerts, correlate it to a specific user request via correlation ID, and find the full trace in the Aspire dashboard
- **Architectural Decisions**: ADR-2 (Custom metrics), ADR-4 (Correlation context), ADR-5 (Health checks)

### NFR-2: Maintainability
- **Requirement**: A developer unfamiliar with the codebase should be able to add a new email operation (e.g., forward) by implementing a single interface method and registering it, without modifying existing code
- **Quality Attribute Scenario**: Adding a "forward email" feature requires changes only in the Infrastructure layer (new Graph API call) and Application layer (new use case method), with zero changes to the Domain layer or Presentation layer
- **Architectural Decisions**: ADR-1 (Clean Architecture), ADR-6 (Options pattern), ADR-7 (Result pattern)

### NFR-3: Testability
- **Requirement**: Every use case must be verifiable through automated tests without calling external APIs. Architectural layering rules must be enforced by automated tests.
- **Quality Attribute Scenario**: When a developer modifies GraphEmailService, they can run the full test suite in under 30 seconds and get clear pass/fail for every use case
- **Architectural Decisions**: ADR-1 (Clean Architecture), ADR-8 (Integration test infrastructure)

### NFR-4: Reliability
- **Requirement**: The application must degrade gracefully when the Graph API is unavailable and recover automatically when it returns
- **Quality Attribute Scenario**: When Graph API returns 503 for 5 minutes, the health check endpoint reports unhealthy, the application shows a user-friendly error, and normal operation resumes within 30 seconds of Graph API recovery
- **Architectural Decisions**: ADR-3 (Resilience patterns), ADR-5 (Health checks)

## 4. Architectural Decision Records

### ADR-1: Clean Architecture Layering
- **Status**: Proposed
- **Context**: The application mixes presentation, business logic, and infrastructure concerns. NFR-2 requires isolated layers so new features only touch relevant layers. NFR-3 requires domain logic testable without infrastructure.
- **Decision**: Organize into Domain (models, interfaces, errors), Application (use case orchestration), Infrastructure (Graph API, identity), and Presentation (controllers, views) layers with strict dependency rules — inner layers never reference outer layers.
- **Consequences**: More files and folders, but each change is localized and testable. New developers can navigate by layer.
- **Traces to**: NFR-2 (Maintainability), NFR-3 (Testability), UC-1 through UC-N (all use cases benefit)

### ADR-2: Custom OpenTelemetry Metrics
- **Status**: Proposed
- **Context**: NFR-1 requires real-time monitoring of business operations. Infrastructure-level metrics from Aspire show HTTP request counts but not domain-specific metrics like "emails fetched" or "replies sent".
- **Decision**: Create a dedicated `MailTelemetry` class with custom `Meter`, `Counter`, and `Histogram` instruments registered with the Aspire OpenTelemetry pipeline.
- **Consequences**: Operations team gets business-level dashboards. Small overhead per operation (~microseconds).
- **Traces to**: NFR-1 (Observability), UC-1 (fetch count metric), UC-3 (reply count metric)

### ADR-3: Resilience Patterns
- **Status**: Proposed
- **Context**: NFR-4 requires graceful degradation when Graph API is unavailable. UC-1 and UC-3 both call Graph API and must handle failures without crashing.
- **Decision**: Use Polly resilience policies (retry with exponential backoff, circuit breaker) wrapped around Graph API calls. Surface failures through the Result pattern (ADR-7) rather than unhandled exceptions.
- **Consequences**: Transient failures are retried automatically. Sustained failures trip the circuit breaker and return user-friendly errors.
- **Traces to**: NFR-4 (Reliability), NFR-1 (Observability — failed calls are metered), UC-1, UC-3

### ADR-4: Correlation Context Middleware
- **Status**: Proposed
- **Context**: NFR-1 requires correlating log entries across a single user request. When debugging a failed email fetch, the operations team needs to find all related log entries.
- **Decision**: Add middleware that propagates a correlation ID through all log entries via `ILogger.BeginScope`, either from an incoming `X-Correlation-ID` header or from the current `Activity.Id`.
- **Consequences**: Every log entry includes `CorrelationId` and `UserEmail`. Debugging multi-step operations becomes a single search.
- **Traces to**: NFR-1 (Observability)

### ADR-5: Health Check Endpoints
- **Status**: Proposed
- **Context**: NFR-4 requires the application to report its health status. Container orchestrators and load balancers need liveness and readiness probes.
- **Decision**: Implement `/health/live` (self-check) and `/health/ready` (Graph API reachability) endpoints using ASP.NET Core health checks.
- **Consequences**: Infrastructure can route traffic away from unhealthy instances. Operations team gets real-time dependency health status.
- **Traces to**: NFR-4 (Reliability), NFR-1 (Observability)

### ADR-6: Options Pattern for Configuration
- **Status**: Proposed
- **Context**: NFR-2 requires easy-to-change configuration. Raw `IConfiguration.GetValue` calls are scattered, untyped, and not validated at startup.
- **Decision**: Replace all configuration access with strongly-typed Options classes using `IOptions<T>`, bound via `AddOptions<T>().BindConfiguration()` with `ValidateDataAnnotations()` and `ValidateOnStart()`.
- **Consequences**: Configuration errors caught at startup, not at runtime. Refactoring config keys is a single-class change.
- **Traces to**: NFR-2 (Maintainability)

### ADR-7: Result Pattern for Error Handling
- **Status**: Proposed
- **Context**: Use cases have expected failure paths (email not found, invalid input, API unavailable) that are currently handled via exceptions. NFR-2 requires explicit error handling. NFR-3 requires error paths to be testable.
- **Decision**: Introduce a `Result<T>` type for application service methods. Expected failures return `Result.Failure(error)` instead of throwing. Unexpected failures (bugs) still throw exceptions and are caught by global exception middleware.
- **Consequences**: Error paths are explicit in method signatures, testable, and documented. Controller logic uses `result.Match()` for clean handling.
- **Traces to**: NFR-2 (Maintainability), NFR-3 (Testability), UC-2 (email not found), UC-3 (send failure)

### ADR-8: Integration Test Infrastructure
- **Status**: Proposed
- **Context**: NFR-3 requires full-pipeline testing without external APIs. Unit tests verify individual classes but miss middleware, DI wiring, and routing issues.
- **Decision**: Use `WebApplicationFactory<Program>` with `ConfigureTestServices` to replace real services with test doubles. Test each use case's HTTP flow end-to-end.
- **Consequences**: Catches integration issues (wrong DI lifetime, missing middleware, routing errors) that unit tests miss. Tests run fast (~seconds) because no real APIs are called.
- **Traces to**: NFR-3 (Testability), UC-1 through UC-N (all use cases get integration tests)
```

**Copilot prompt**: `Analyze the application and generate an architecture-spec.md with all use cases (including main flows, alternative flows, and acceptance criteria), non-functional requirements for observability/maintainability/testability/reliability, and architectural decision records that trace each pattern choice back to specific requirements and use cases.`

#### 3. Review and Validate with the Developer

The spec is a *communication tool* — it must be reviewed before driving implementation:

- Walk through each use case: are any missing? Are the acceptance criteria correct?
- Walk through each NFR: do the quality attribute scenarios match the team's expectations?
- Walk through each ADR: does the team agree with the pattern choices? Are there constraints (e.g., no additional NuGet packages) that change a decision?

#### 4. Create a Traceability Matrix

Add a traceability matrix at the end of the spec that maps every requirement to its implementing phase, pattern, and test:

```markdown
## 5. Traceability Matrix

| Requirement | Phase | Pattern | Verified By |
|-------------|-------|---------|-------------|
| UC-1: View Inbox | Phase 3 | IMailService.GetInboxAsync | Unit: MailServiceTests.GetInbox_*, Integration: MailControllerIntegrationTests.GetIndex_* |
| UC-2: View Email Detail | Phase 3 | IMailService.GetEmailAsync | Unit: MailServiceTests.GetEmail_*, Integration: MailControllerIntegrationTests.GetDetail_* |
| UC-3: Reply to Email | Phase 3 | IMailService.SendReplyAsync | Unit: MailServiceTests.SendReply_*, Integration: MailControllerIntegrationTests.PostReply_* |
| NFR-1: Observability | Phase 4 | MailTelemetry, CorrelationMiddleware | Integration: HealthCheckTests, Manual: Aspire dashboard review |
| NFR-2: Maintainability | Phase 3, 5 | Clean Architecture, Options, Result | Architecture: ArchitectureTests.DomainLayer_*, ArchitectureTests.Controllers_* |
| NFR-3: Testability | Phase 2, 6 | WebApplicationFactory, Builders | Meta: all tests passing, coverage > baseline |
| NFR-4: Reliability | Phase 4, 5 | Health checks, Polly, GlobalExceptionMiddleware | Integration: HealthCheckTests, Unit: ResilienceTests |
```

### Human Checkpoint (Phase 1)

**"The architecture spec has been produced with [N] use cases, [N] non-functional requirements, and [N] architectural decision records. Each ADR traces to specific requirements and use cases. Do you approve this spec as the foundation for all subsequent phases?"**

- Options: [Approve Phase 1] [Request changes to use cases] [Request changes to ADRs] [Add missing requirements]

**Do NOT proceed to Phase 2 without explicit approval — the spec drives everything that follows.**

---

## Phase 2: Test Safety Net

### Goal

Create a comprehensive regression test suite derived directly from the spec's use cases and acceptance criteria. These tests lock in current behavior *before any structural changes begin*. Every test traces to a specific use case or acceptance criterion in the spec.

### Why Test Before Restructuring

Architectural refactoring is inherently risky — you're changing *how* code is organized without changing *what* it does. Without tests:

- You can't tell if a refactoring broke something until a user reports it
- You spend more time manually testing than you saved by modernizing
- The team loses confidence and stops refactoring

Tests derived from the spec create a contract: "the application must continue to satisfy these documented behaviors regardless of how the internals change."

### Steps

#### 1. Create Test Project (if not exists)

If a test project does not already exist from Skill 03 (`ews-test`):

1. Create project: `dotnet new xunit -n [ProjectName].Tests`
2. Add NuGet packages: `NSubstitute`, `NSubstitute.Analyzers.CSharp`, `Microsoft.NET.Test.Sdk`, `coverlet.collector`
3. Add project reference to the main application
4. Add to solution: `dotnet sln add [ProjectName].Tests/[ProjectName].Tests.csproj`

If a test project already exists, verify it is up to date and all existing tests pass: `dotnet test`

#### 2. Generate Use Case Tests from Spec

For each use case in the spec, generate tests that verify:

- **Main flow**: The happy path works as documented
- **Alternative flows**: Each documented alternative flow is handled correctly
- **Acceptance criteria**: Each AC-X.Y has at least one test

Name tests to trace back to the spec:

```csharp
// Traces to: UC-1 (View Inbox), AC-1.1
[Fact]
public async Task UC1_ViewInbox_ReturnsUpTo10EmailsSortedByDateDescending()
{
    // Arrange
    var mockService = Substitute.For<IEmailService>();
    mockService.GetInboxEmailsAsync(Arg.Any<string>(), Arg.Any<int>())
        .Returns(CreateTestEmails(10));
    var controller = new MailController(mockService, mockLogger);
    SetupAuthenticatedUser(controller, "user@contoso.com");

    // Act
    var result = await controller.Index();

    // Assert
    var viewResult = Assert.IsType<ViewResult>(result);
    var model = Assert.IsAssignableFrom<IList<EmailMessage>>(viewResult.Model);
    Assert.Equal(10, model.Count);
    Assert.True(model.SequenceEqual(model.OrderByDescending(e => e.DateTimeReceived)));
}

// Traces to: UC-1 (View Inbox), Alternative Flow: Graph API unreachable
[Fact]
public async Task UC1_ViewInbox_WhenGraphApiUnavailable_ReturnsErrorView()
{
    // Arrange
    var mockService = Substitute.For<IEmailService>();
    mockService.GetInboxEmailsAsync(Arg.Any<string>(), Arg.Any<int>())
        .ThrowsAsync(new ServiceException("Graph API unavailable"));

    // Act & Assert
    var result = await controller.Index();
    // Verify error handling behavior
}

// Traces to: UC-2 (View Email Detail), AC-2.1
[Fact]
public async Task UC2_ViewEmailDetail_WithValidId_ReturnsEmailWithFullBody()
{
    // ...
}

// Traces to: UC-3 (Reply to Email), Alternative Flow: invalid input
[Theory]
[InlineData(null)]
[InlineData("")]
[InlineData("   ")]
public async Task UC3_ReplyToEmail_WithInvalidId_ReturnsBadRequest(string id)
{
    // ...
}
```

**Copilot prompt**: `Using the use cases and acceptance criteria in architecture-spec.md, generate xUnit unit tests for every main flow, alternative flow, and acceptance criterion. Name each test to trace back to its use case (e.g., UC1_ViewInbox_*). Use NSubstitute for mocking.`

#### 3. Generate NFR Smoke Tests

Create lightweight tests that will verify non-functional requirements once the architecture is in place. These start as placeholders and are filled in during later phases:

```csharp
// Traces to: NFR-1 (Observability) — will be implemented in Phase 4
// Placeholder: verify health check endpoints exist after Phase 4
[Fact(Skip = "Enable after Phase 4: Observability Architecture")]
public async Task NFR1_HealthCheckEndpoint_ReturnsHealthy() { }

// Traces to: NFR-2 (Maintainability) — will be implemented in Phase 3
// Placeholder: verify clean architecture layering after Phase 3
[Fact(Skip = "Enable after Phase 3: Clean Architecture Layering")]
public async Task NFR2_DomainLayer_HasNoInfrastructureDependencies() { }

// Traces to: NFR-3 (Testability) — will be implemented in Phase 6
[Fact(Skip = "Enable after Phase 6: Testability Architecture")]
public async Task NFR3_AllUseCases_HaveIntegrationTests() { }
```

#### 4. Run Tests and Establish Baseline

1. Run all tests: `dotnet test`
2. Fix any failures — every test must pass against the *current* codebase
3. Run with coverage: `dotnet test --collect:"XPlat Code Coverage"`
4. Record baseline:
   - Total test count
   - Pass rate (must be 100%)
   - Code coverage percentage
   - Coverage gaps (document as expected or actionable)
5. Document baseline in `architecture-spec.md` under a new section:

```markdown
## 6. Test Baseline (Pre-Modernization)

- **Test count**: [N] (of which [M] are placeholders for later phases)
- **Pass rate**: 100%
- **Code coverage**: [X]%
- **Coverage gaps**: [list expected gaps like auth flows, external API calls]
- **Date established**: [date]
```

#### 5. Validate Spec-to-Test Traceability

Review the traceability matrix from Phase 1 and confirm:

- Every UC-X has at least one test with `UCX_` prefix
- Every AC-X.Y has at least one test
- Every alternative flow has at least one test
- NFR placeholder tests exist for each NFR

### Human Checkpoint (Phase 2)

**"A test safety net has been established with [N] tests, all passing. Tests are derived from the spec's use cases and acceptance criteria. Code coverage baseline is [X]%. Do you approve this test suite as the regression guard for architectural changes?"**

- Options: [Approve Phase 2] [Request more tests for specific use cases] [Review coverage gaps]

**Do NOT proceed to Phase 3 without explicit approval — these tests are the safety net for all restructuring.**

---

## Phase 3: Clean Architecture Layering

### Goal

Reorganize the application into Clean Architecture layers that enforce dependency rules and separate concerns. This is the foundation that makes all other improvements possible.

### Spec Traceability

This phase implements:

- **ADR-1**: Clean Architecture Layering → satisfies **NFR-2** (Maintainability), **NFR-3** (Testability)

### Why Clean Architecture

Legacy EWS applications typically have a "Big Ball of Mud" architecture where controllers directly call Exchange APIs, business logic is mixed with presentation concerns, and configuration is scattered. Clean Architecture inverts dependencies so the domain is at the center and infrastructure is on the outside — making the core logic portable, testable, and resilient to external API changes (exactly the problem that triggered the EWS migration).

### Steps

#### 1. Define Domain Layer

Create a `Domain/` folder (or separate project) for pure business concepts with no framework dependencies:

```
Domain/
├── Models/
│   ├── EmailMessage.cs          # Already exists from Skill 04
│   ├── EmailReplyModel.cs       # Already exists from Skill 04
│   └── EmailAttachment.cs       # If applicable
├── Interfaces/
│   └── IEmailService.cs         # Already exists from Skill 04
├── Errors/
│   ├── DomainError.cs           # Base error type
│   ├── EmailNotFoundError.cs
│   └── SendFailedError.cs
└── ValueObjects/
    └── EmailAddress.cs          # Strongly-typed email address
```

**Key rule**: The Domain layer has **zero** NuGet package dependencies and **zero** `using` statements referencing ASP.NET, Graph SDK, or any infrastructure.

**Copilot prompt**: `Refactor the Models folder into a Domain layer following Clean Architecture. The domain should have no dependencies on ASP.NET, Microsoft.Graph, or any infrastructure packages. Create value objects for EmailAddress and domain error types.`

#### 2. Define Application Layer

Create an `Application/` folder for use-case orchestration:

```
Application/
├── Services/
│   └── MailService.cs           # Orchestrates use cases
├── DTOs/
│   ├── InboxRequest.cs
│   └── ReplyRequest.cs
└── Interfaces/
    ├── IMailService.cs          # Application-level interface
    └── ICurrentUserAccessor.cs  # Abstracts HttpContext user
```

The Application layer depends only on the Domain layer. It coordinates workflows and maps between DTOs and domain models.

```csharp
public class MailService : IMailService
{
    private readonly IEmailService _emailService;
    private readonly ICurrentUserAccessor _currentUser;
    private readonly ILogger<MailService> _logger;

    public MailService(
        IEmailService emailService,
        ICurrentUserAccessor currentUser,
        ILogger<MailService> logger)
    {
        _emailService = emailService;
        _currentUser = currentUser;
        _logger = logger;
    }

    public async Task<Result<IList<EmailMessage>>> GetInboxAsync(int count = 10)
    {
        var userEmail = _currentUser.GetEmail();
        if (string.IsNullOrWhiteSpace(userEmail))
            return Result<IList<EmailMessage>>.Failure(new DomainError("User email not available"));

        try
        {
            var emails = await _emailService.GetInboxEmailsAsync(userEmail, count);
            return Result<IList<EmailMessage>>.Success(emails);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to retrieve inbox for {UserEmail}", userEmail);
            return Result<IList<EmailMessage>>.Failure(new DomainError("Failed to retrieve inbox"));
        }
    }
}
```

#### 3. Define Infrastructure Layer

The Infrastructure layer contains all external dependencies:

```
Infrastructure/
├── Email/
│   └── GraphEmailService.cs     # Already exists — move here
├── Identity/
│   └── HttpContextUserAccessor.cs
└── Configuration/
    └── GraphApiOptions.cs       # Strongly-typed config (see Phase 5)
```

#### 4. Refactor the Presentation Layer

The web project becomes a thin Presentation layer:

```
Contoso.Mail.Web/
├── Controllers/
│   └── MailController.cs        # Delegates to IMailService
├── Views/
├── Program.cs                   # DI composition root
└── appsettings.json
```

The controller becomes minimal:

```csharp
public class MailController : Controller
{
    private readonly IMailService _mailService;

    public MailController(IMailService mailService)
    {
        _mailService = mailService;
    }

    public async Task<IActionResult> Index()
    {
        var result = await _mailService.GetInboxAsync();
        if (!result.IsSuccess)
            return Problem(result.Error.Message);

        return View(result.Value);
    }
}
```

#### 5. Validate Layering

- Build the solution — should compile without errors
- Run all existing tests — they should still pass
- Verify no circular dependencies between layers
- Verify the Domain layer has zero infrastructure imports

### Human Checkpoint (Phase 3)

**"The application has been reorganized into Clean Architecture layers (ADR-1): Domain (pure business logic), Application (use cases), Infrastructure (Graph API, identity), and Presentation (controllers, views). All tests from Phase 2 still pass. Do you approve this restructuring?"**

- Options: [Approve Phase 3] [Request changes] [Review dependency graph]

---

## Phase 4: Observability Architecture

### Goal

Extend the Aspire-based observability from Skill 02 with custom business metrics, structured logging enrichment, and health checks that make the application's runtime behavior transparent.

### Spec Traceability

This phase implements:

- **ADR-2**: Custom OpenTelemetry Metrics → satisfies **NFR-1** (Observability)
- **ADR-4**: Correlation Context Middleware → satisfies **NFR-1** (Observability)
- **ADR-5**: Health Check Endpoints → satisfies **NFR-4** (Reliability), **NFR-1** (Observability)

### Why This Matters

Aspire provides infrastructure-level telemetry (HTTP requests, dependency calls). But to understand what the application is *doing* — how many emails are fetched, how often replies fail, whether the Graph API is healthy — you need custom instrumentation tied to your domain.

### Steps

#### 1. Add Custom Activity Source for Distributed Tracing

Create domain-specific trace activities:

```csharp
public static class MailTelemetry
{
    public static readonly string ServiceName = "Contoso.Mail";
    public static readonly ActivitySource ActivitySource = new(ServiceName);

    public static readonly Meter Meter = new(ServiceName);

    // Counters
    public static readonly Counter<long> EmailsFetched =
        Meter.CreateCounter<long>("mail.emails.fetched", "emails", "Number of emails fetched from inbox");
    public static readonly Counter<long> RepliesSent =
        Meter.CreateCounter<long>("mail.replies.sent", "replies", "Number of replies sent");
    public static readonly Counter<long> OperationErrors =
        Meter.CreateCounter<long>("mail.operations.errors", "errors", "Number of failed mail operations");

    // Histograms
    public static readonly Histogram<double> FetchDuration =
        Meter.CreateHistogram<double>("mail.fetch.duration", "ms", "Duration of inbox fetch operations");
}
```

#### 2. Instrument the Application Layer

Add tracing and metrics to service methods:

```csharp
public async Task<Result<IList<EmailMessage>>> GetInboxAsync(int count = 10)
{
    using var activity = MailTelemetry.ActivitySource.StartActivity("GetInbox");
    activity?.SetTag("mail.requested_count", count);
    var sw = Stopwatch.StartNew();

    try
    {
        var emails = await _emailService.GetInboxEmailsAsync(userEmail, count);
        activity?.SetTag("mail.actual_count", emails.Count);
        MailTelemetry.EmailsFetched.Add(emails.Count);
        return Result<IList<EmailMessage>>.Success(emails);
    }
    catch (Exception ex)
    {
        activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
        MailTelemetry.OperationErrors.Add(1, new("operation", "get_inbox"));
        throw;
    }
    finally
    {
        MailTelemetry.FetchDuration.Record(sw.Elapsed.TotalMilliseconds);
    }
}
```

**Copilot prompt**: `Add OpenTelemetry custom metrics and Activity tracing to the MailService class. Track email fetch counts, reply counts, error counts, and operation durations.`

#### 3. Add Structured Logging Enrichment

Create a middleware that enriches all log entries with correlation context:

```csharp
public class CorrelationMiddleware
{
    private readonly RequestDelegate _next;

    public CorrelationMiddleware(RequestDelegate next) => _next = next;

    public async Task InvokeAsync(HttpContext context)
    {
        var correlationId = context.Request.Headers["X-Correlation-ID"].FirstOrDefault()
            ?? Activity.Current?.Id
            ?? Guid.NewGuid().ToString();

        using (context.RequestServices.GetRequiredService<ILogger<CorrelationMiddleware>>()
            .BeginScope(new Dictionary<string, object>
            {
                ["CorrelationId"] = correlationId,
                ["UserEmail"] = context.User?.FindFirst("preferred_username")?.Value ?? "anonymous"
            }))
        {
            context.Response.Headers["X-Correlation-ID"] = correlationId;
            await _next(context);
        }
    }
}
```

#### 4. Add Health Checks

Register health checks for all critical dependencies:

```csharp
// In Program.cs
builder.Services.AddHealthChecks()
    .AddCheck<GraphApiHealthCheck>("graph-api", tags: new[] { "ready" })
    .AddCheck("self", () => HealthCheckResult.Healthy(), tags: new[] { "live" });

// Map endpoints
app.MapHealthChecks("/health/live", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("live")
});
app.MapHealthChecks("/health/ready", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready"),
    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse
});
```

Create the Graph API health check:

```csharp
public class GraphApiHealthCheck : IHealthCheck
{
    private readonly GraphServiceClient _graphClient;

    public GraphApiHealthCheck(GraphServiceClient graphClient)
        => _graphClient = graphClient;

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            await _graphClient.Me.GetAsync(config =>
                config.QueryParameters.Select = new[] { "id" },
                cancellationToken);
            return HealthCheckResult.Healthy("Graph API is reachable");
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("Graph API is unreachable", ex);
        }
    }
}
```

#### 5. Register Telemetry in Aspire

Update the AppHost and ServiceDefaults to wire up custom metrics and traces:

```csharp
// In ServiceDefaults
builder.Services.AddOpenTelemetry()
    .WithTracing(tracing => tracing.AddSource(MailTelemetry.ServiceName))
    .WithMetrics(metrics => metrics.AddMeter(MailTelemetry.ServiceName));
```

#### 6. Validate Observability

- Run the application under Aspire
- Verify custom traces appear in the Aspire dashboard Traces tab
- Verify custom metrics appear in the Metrics tab
- Verify health check endpoints return correct status
- Verify correlation IDs propagate through log entries

### Human Checkpoint (Phase 4)

**"Custom observability has been added per ADR-2, ADR-4, and ADR-5: business metrics (emails fetched, replies sent, errors), distributed tracing with Activity sources, health checks for Graph API readiness, and correlation context in all logs. All Phase 2 tests still pass. Enable the NFR-1 placeholder tests now. Do you approve?"**

- Options: [Approve Phase 4] [Request changes] [View Aspire dashboard]

---

## Phase 5: Maintainability Patterns

### Goal

Apply patterns that make the codebase easier to understand, change, and extend. These patterns reduce cognitive load and prevent common maintenance pitfalls.

### Spec Traceability

This phase implements:

- **ADR-6**: Options Pattern for Configuration → satisfies **NFR-2** (Maintainability)
- **ADR-7**: Result Pattern for Error Handling → satisfies **NFR-2** (Maintainability), **NFR-3** (Testability)
- **ADR-3**: Resilience Patterns → satisfies **NFR-4** (Reliability)

### Steps

#### 1. Options Pattern for Configuration

Replace raw `IConfiguration` access with strongly-typed options:

```csharp
public class GraphApiOptions
{
    public const string SectionName = "MicrosoftGraph";

    public string BaseUrl { get; set; } = "https://graph.microsoft.com/v1.0";
    public string Scopes { get; set; } = string.Empty;
    public int MaxRetries { get; set; } = 3;
    public int TimeoutSeconds { get; set; } = 30;
    public int DefaultMailCount { get; set; } = 10;
}
```

Register with validation:

```csharp
builder.Services.AddOptions<GraphApiOptions>()
    .BindConfiguration(GraphApiOptions.SectionName)
    .ValidateDataAnnotations()
    .ValidateOnStart();
```

Use `IOptions<GraphApiOptions>` in services instead of `IConfiguration`.

**Copilot prompt**: `Replace all IConfiguration.GetValue and IConfiguration.GetSection calls with strongly-typed Options pattern classes. Add data annotation validation.`

#### 2. Result Pattern for Error Handling

Create a Result type for explicit error handling without exceptions for expected failures:

```csharp
public class Result<T>
{
    public bool IsSuccess { get; }
    public T? Value { get; }
    public DomainError? Error { get; }

    private Result(T value) { IsSuccess = true; Value = value; }
    private Result(DomainError error) { IsSuccess = false; Error = error; }

    public static Result<T> Success(T value) => new(value);
    public static Result<T> Failure(DomainError error) => new(error);

    public TResult Match<TResult>(
        Func<T, TResult> onSuccess,
        Func<DomainError, TResult> onFailure)
        => IsSuccess ? onSuccess(Value!) : onFailure(Error!);
}

public record DomainError(string Message, string? Code = null);
```

Use in application services:

```csharp
public async Task<Result<EmailMessage>> GetEmailAsync(string emailId)
{
    if (string.IsNullOrWhiteSpace(emailId))
        return Result<EmailMessage>.Failure(new DomainError("Email ID is required", "INVALID_ID"));

    var email = await _emailService.GetEmailByIdAsync(emailId, _currentUser.GetEmail());
    if (email is null)
        return Result<EmailMessage>.Failure(new DomainError("Email not found", "NOT_FOUND"));

    return Result<EmailMessage>.Success(email);
}
```

#### 3. Guard Clauses for Parameter Validation

Create guard helpers for consistent validation:

```csharp
public static class Guard
{
    public static string AgainstNullOrWhiteSpace(string? value, string parameterName)
    {
        if (string.IsNullOrWhiteSpace(value))
            throw new ArgumentException($"{parameterName} cannot be null or empty", parameterName);
        return value;
    }

    public static T AgainstNull<T>(T? value, string parameterName) where T : class
    {
        return value ?? throw new ArgumentNullException(parameterName);
    }

    public static int AgainstNegativeOrZero(int value, string parameterName)
    {
        if (value <= 0)
            throw new ArgumentOutOfRangeException(parameterName, $"{parameterName} must be positive");
        return value;
    }
}
```

#### 4. Extension Methods for DI Organization

Organize service registration into focused extension methods:

```csharp
public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddMailDomain(this IServiceCollection services)
    {
        services.AddScoped<IMailService, MailService>();
        services.AddScoped<ICurrentUserAccessor, HttpContextUserAccessor>();
        return services;
    }

    public static IServiceCollection AddMailInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.AddOptions<GraphApiOptions>()
            .BindConfiguration(GraphApiOptions.SectionName)
            .ValidateDataAnnotations()
            .ValidateOnStart();

        services.AddMicrosoftGraph(configuration.GetSection("MicrosoftGraph"));
        services.AddScoped<IEmailService, GraphEmailService>();
        return services;
    }

    public static IServiceCollection AddMailObservability(this IServiceCollection services)
    {
        services.AddHealthChecks()
            .AddCheck<GraphApiHealthCheck>("graph-api", tags: new[] { "ready" })
            .AddCheck("self", () => HealthCheckResult.Healthy(), tags: new[] { "live" });

        return services;
    }
}
```

This makes `Program.cs` clean and readable:

```csharp
builder.Services
    .AddMailDomain()
    .AddMailInfrastructure(builder.Configuration)
    .AddMailObservability();
```

#### 5. Global Exception Handling Middleware

Add a middleware that catches unhandled exceptions and produces consistent error responses with correlation IDs:

```csharp
public class GlobalExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionMiddleware> _logger;

    public GlobalExceptionMiddleware(RequestDelegate next, ILogger<GlobalExceptionMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception processing {Method} {Path}",
                context.Request.Method, context.Request.Path);

            MailTelemetry.OperationErrors.Add(1, new("type", "unhandled"));

            context.Response.StatusCode = StatusCodes.Status500InternalServerError;
            await context.Response.WriteAsJsonAsync(new
            {
                error = "An unexpected error occurred",
                correlationId = Activity.Current?.Id
            });
        }
    }
}
```

#### 6. Validate Maintainability

- Build — zero errors, zero warnings
- Run all tests
- Review `Program.cs` — should be concise and well-organized
- Verify Options validation fires on startup with bad config
- Verify exception middleware catches unhandled errors

### Human Checkpoint (Phase 5)

**"Maintainability patterns have been applied per ADR-6, ADR-7, and ADR-3: Options pattern for configuration, Result pattern for error handling, Guard clauses, organized DI extensions, and global exception handling. Program.cs is now clean and well-structured. All Phase 2 tests still pass. Do you approve?"**

- Options: [Approve Phase 5] [Request changes] [Review Program.cs]

---

## Phase 6: Testability Architecture

### Goal

Extend the test safety net from Phase 2 with patterns that make every layer independently testable and support integration testing. Enable all NFR placeholder tests created in Phase 2.

### Spec Traceability

This phase implements:

- **ADR-8**: Integration Test Infrastructure → satisfies **NFR-3** (Testability)
- **ADR-1**: Clean Architecture Layering (verification) → satisfies **NFR-2** (Maintainability), **NFR-3** (Testability)

### Steps

#### 1. Test Data Builders

Create builders for constructing test data declaratively:

```csharp
public class EmailMessageBuilder
{
    private string _id = Guid.NewGuid().ToString();
    private string _subject = "Test Subject";
    private string _from = "sender@contoso.com";
    private DateTime _received = DateTime.UtcNow;
    private bool _isRead = false;

    public EmailMessageBuilder WithSubject(string subject) { _subject = subject; return this; }
    public EmailMessageBuilder WithFrom(string from) { _from = from; return this; }
    public EmailMessageBuilder AsRead() { _isRead = true; return this; }
    public EmailMessageBuilder ReceivedAt(DateTime received) { _received = received; return this; }

    public EmailMessage Build() => new()
    {
        Id = _id,
        Subject = _subject,
        From = _from,
        DateTimeReceived = _received,
        IsRead = _isRead,
    };

    public static implicit operator EmailMessage(EmailMessageBuilder builder) => builder.Build();
}
```

Usage in tests:

```csharp
var email = new EmailMessageBuilder()
    .WithSubject("Quarterly Report")
    .WithFrom("cfo@contoso.com")
    .AsRead()
    .Build();
```

**Copilot prompt**: `Create test data builders for EmailMessage and EmailReplyModel following the Builder pattern. Each builder should have fluent methods for all properties and a Build() method.`

#### 2. Integration Tests with WebApplicationFactory

Create integration tests that exercise the full HTTP pipeline:

```csharp
public class MailControllerIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public MailControllerIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureTestServices(services =>
            {
                // Replace real services with test doubles
                services.AddScoped<IEmailService>(_ => CreateMockEmailService());
                services.AddScoped<ICurrentUserAccessor>(_ => CreateMockUserAccessor());
            });
        });
    }

    [Fact]
    public async Task GetIndex_ReturnsSuccessAndContainsEmails()
    {
        var client = _factory.CreateClient();

        var response = await client.GetAsync("/Mail");

        response.EnsureSuccessStatusCode();
        var content = await response.Content.ReadAsStringAsync();
        Assert.Contains("Quarterly Report", content);
    }

    [Fact]
    public async Task HealthCheck_Live_ReturnsHealthy()
    {
        var client = _factory.CreateClient();

        var response = await client.GetAsync("/health/live");

        response.EnsureSuccessStatusCode();
    }
}
```

#### 3. Architecture Tests

Add tests that enforce architectural rules — ensuring the Clean Architecture layering is maintained as the codebase evolves:

```csharp
public class ArchitectureTests
{
    [Fact]
    public void DomainLayer_ShouldNotReference_InfrastructureOrPresentation()
    {
        var domainTypes = GetTypesInNamespace("Contoso.Mail.Domain");

        foreach (var type in domainTypes)
        {
            var references = type.Assembly.GetReferencedAssemblies();
            Assert.DoesNotContain(references,
                r => r.Name!.Contains("Microsoft.Graph"));
            Assert.DoesNotContain(references,
                r => r.Name!.Contains("Microsoft.AspNetCore"));
        }
    }

    [Fact]
    public void Controllers_ShouldNotDepend_OnEmailServiceDirectly()
    {
        var controllerTypes = GetTypesInNamespace("Contoso.Mail.Web.Controllers")
            .Where(t => t.Name.EndsWith("Controller"));

        foreach (var controller in controllerTypes)
        {
            var constructorParams = controller.GetConstructors()
                .SelectMany(c => c.GetParameters())
                .Select(p => p.ParameterType);

            Assert.DoesNotContain(constructorParams,
                t => t == typeof(IEmailService));
        }
    }

    [Fact]
    public void AllServices_ShouldBeRegistered_InDI()
    {
        var factory = new WebApplicationFactory<Program>();
        using var scope = factory.Services.CreateScope();

        Assert.NotNull(scope.ServiceProvider.GetService<IMailService>());
        Assert.NotNull(scope.ServiceProvider.GetService<IEmailService>());
        Assert.NotNull(scope.ServiceProvider.GetService<ICurrentUserAccessor>());
    }
}
```

#### 4. Test Organization

Reorganize tests to mirror the architecture:

```
Contoso.Mail.Web.Tests/
├── Unit/
│   ├── Domain/
│   │   └── ValueObjects/
│   │       └── EmailAddressTests.cs
│   ├── Application/
│   │   └── Services/
│   │       └── MailServiceTests.cs
│   └── Infrastructure/
│       └── Email/
│           └── GraphEmailServiceTests.cs
├── Integration/
│   ├── Controllers/
│   │   └── MailControllerIntegrationTests.cs
│   └── HealthChecks/
│       └── HealthCheckTests.cs
├── Architecture/
│   └── ArchitectureTests.cs
├── Builders/
│   ├── EmailMessageBuilder.cs
│   └── EmailReplyModelBuilder.cs
└── TestHelpers/
    └── TestWebApplicationFactory.cs
```

#### 5. Validate Testability

- Run all tests: `dotnet test`
- Verify unit tests run fast (< 5 seconds total)
- Verify integration tests exercise the HTTP pipeline
- Verify architecture tests catch layering violations
- Review code coverage — should exceed the baseline established in Phase 2

### Human Checkpoint (Phase 6)

**"Testability architecture has been enhanced per ADR-8: test data builders for clean test setup, integration tests with WebApplicationFactory, architecture tests that enforce Clean Architecture layering (ADR-1), and reorganized test structure. All NFR placeholder tests from Phase 2 are now enabled and passing. Do you approve?"**

- Options: [Approve Phase 6] [Request changes] [Run tests with coverage]

---

## Summary of Patterns Applied

| Phase | Quality | Pattern | Spec Traceability |
|-------|---------|---------|-------------------|
| **Phase 1** | Foundation | Spec/PRD with Use Cases | Drives all subsequent decisions |
| **Phase 1** | Foundation | Architectural Decision Records | ADR-1 through ADR-8 trace to NFR-1 through NFR-4 |
| **Phase 1** | Foundation | Traceability Matrix | Maps requirements → phases → patterns → tests |
| **Phase 2** | Testability | Use Case Regression Tests | UC-1 through UC-N acceptance criteria |
| **Phase 2** | Testability | NFR Placeholder Tests | NFR-1 through NFR-4 (enabled in Phase 6) |
| **Phase 3** | Maintainability | Clean Architecture Layers | ADR-1 → NFR-2, NFR-3 |
| **Phase 4** | Observability | Custom ActivitySource | ADR-2 → NFR-1 |
| **Phase 4** | Observability | Custom Meter & Counters | ADR-2 → NFR-1, UC-1, UC-3 |
| **Phase 4** | Observability | Correlation Middleware | ADR-4 → NFR-1 |
| **Phase 4** | Observability | Health Checks | ADR-5 → NFR-4, NFR-1 |
| **Phase 5** | Maintainability | Options Pattern | ADR-6 → NFR-2 |
| **Phase 5** | Maintainability | Result Pattern | ADR-7 → NFR-2, NFR-3 |
| **Phase 5** | Maintainability | Guard Clauses | NFR-2 |
| **Phase 5** | Maintainability | DI Extension Methods | NFR-2 |
| **Phase 5** | Maintainability | Global Exception Middleware | ADR-3 → NFR-4 |
| **Phase 6** | Testability | Test Data Builders | NFR-3 |
| **Phase 6** | Testability | WebApplicationFactory | ADR-8 → NFR-3 |
| **Phase 6** | Testability | Architecture Tests | ADR-1 → NFR-2, NFR-3 |
| **Phase 6** | Testability | Interface Segregation | NFR-3 |

---

## Reference Documentation

- Clean Architecture in .NET: <https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/>
- OpenTelemetry .NET: <https://learn.microsoft.com/en-us/dotnet/core/diagnostics/observability-with-otel>
- Health Checks in ASP.NET Core: <https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/health-checks>
- Options Pattern in .NET: <https://learn.microsoft.com/en-us/dotnet/core/extensions/options>
- Integration Tests with WebApplicationFactory: <https://learn.microsoft.com/en-us/aspnet/core/test/integration-tests>
- AI Assisted EWS Migration Tutorial: <https://aka.ms/ewsToolsAITutorial>

---

## Acceptance Criteria

### Phase 1: Spec & Architectural Decision Record
- [ ] `architecture-spec.md` exists with all use cases, acceptance criteria, and alternative flows
- [ ] Non-functional requirements documented with quality attribute scenarios
- [ ] Architectural Decision Records (ADR-1 through ADR-8) trace to specific requirements
- [ ] Traceability matrix maps every requirement to phases, patterns, and tests
- [ ] Developer has reviewed and approved the spec

### Phase 2: Test Safety Net
- [ ] Test project exists with xUnit and NSubstitute
- [ ] Every use case has tests named with `UCN_` prefix
- [ ] Every acceptance criterion has at least one test
- [ ] NFR placeholder tests created (skipped, enabled in later phases)
- [ ] All tests pass (100% pass rate)
- [ ] Code coverage baseline documented in spec

### Phase 3: Clean Architecture Layering
- [ ] Application organized into Domain, Application, Infrastructure, Presentation layers
- [ ] Domain layer has zero infrastructure dependencies
- [ ] All Phase 2 tests still pass after restructuring

### Phase 4: Observability Architecture
- [ ] Custom OpenTelemetry metrics and traces wired into Aspire
- [ ] Health check endpoints operational (/health/live, /health/ready)
- [ ] Correlation middleware enriches all log entries
- [ ] NFR-1 placeholder tests enabled and passing

### Phase 5: Maintainability Patterns
- [ ] Options pattern replaces all raw IConfiguration usage
- [ ] Result pattern used for expected failure paths
- [ ] Guard clauses validate all public API parameters
- [ ] DI registration organized with extension methods
- [ ] Global exception middleware catches unhandled errors

### Phase 6: Testability Architecture
- [ ] Test data builders created for all domain models
- [ ] Integration tests exercise the HTTP pipeline
- [ ] Architecture tests enforce layering rules
- [ ] All NFR placeholder tests enabled and passing
- [ ] Code coverage exceeds Phase 2 baseline
- [ ] All tests pass (unit, integration, architecture)
- [ ] Application runs correctly under Aspire with new architecture

---

## Human Checkpoint

Before considering this skill complete, present results to the developer:

1. **"Does the architecture-spec.md accurately describe all use cases and requirements?"**
   - If no: update the spec and re-validate traceability
2. **"Does the application build and run correctly?"**
   - If no: investigate and fix
3. **"Do all tests pass (unit, integration, architecture)?"**
   - If no: fix failing tests
4. **"Are all NFR placeholder tests from Phase 2 now enabled and passing?"**
   - If no: identify which NFRs are not yet satisfied
5. **"Are the custom metrics visible in the Aspire dashboard?"**
   - If no: verify OpenTelemetry registration
6. **"Do the health check endpoints respond correctly?"**
   - If no: debug health check implementations
7. **"Does every architectural pattern trace back to a spec requirement?"**
   - If no: update the traceability matrix
8. **"Do you approve this architectural modernization?"**
   - Options: [Approve and proceed] [Request changes] [Revert to pre-architect checkpoint]

Do NOT consider this skill complete without explicit human approval.

---

## Next Skill

Upon approval → **Skill 05: Final Validation & Documentation** (`ews-validate`)
