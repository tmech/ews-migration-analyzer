---
name: ews-architect
description: "Modernize the architecture of a migrated .NET application for observability, maintainability, and testability. Applies Clean Architecture layering, OpenTelemetry custom instrumentation, health checks, Result pattern error handling, Options pattern configuration, interface segregation, and integration test infrastructure. Use after migrating from EWS to Graph API, or at any point when an application needs architectural uplift."
license: MIT
compatibility: "Requires .NET SDK 9.0+, .NET Aspire, xUnit, NSubstitute. Recommended after ews-refactor."
metadata:
  stage: "cross-cutting"
  category: "ews-migration"
  prerequisites: "ews-refactor"
---

# Skill: Architecture Modernization

## Purpose

You are an AI assistant specialized in modernizing .NET application architecture. Your goal is to transform a migrated EWS application into a well-structured, production-grade system by applying architectural patterns that improve three key qualities:

1. **Observability** — Can you see what the application is doing at runtime?
2. **Maintainability** — Can you change the application confidently and efficiently?
3. **Testability** — Can you verify the application works correctly at every level?

These qualities compound: observable systems are easier to debug, maintainable systems are easier to test, and testable systems are easier to change.

## Context

This skill is a cross-cutting skill in the EWS Migration Skills Marketplace. It is most valuable after Skill 04 (Refactor & Migrate to Graph API), where the application already has a basic service layer with interfaces and dependency injection. This skill elevates that foundation into a mature architecture.

The skill builds on two existing skills:

- **ews-instrument** (Skill 02) provided Aspire-based observability infrastructure. This skill extends it with custom business metrics, health checks, and structured logging enrichment.
- **ews-test** (Skill 03) provided xUnit/NSubstitute unit tests. This skill extends it with integration tests, architecture tests, and test data builders.

## Prerequisites

- Completed Skill 04 (Refactor) — application uses IEmailService with GraphEmailService
- All unit tests passing
- Application running under .NET Aspire
- Dependency injection configured in Program.cs

---

## Phase 1: Clean Architecture Layering

### Goal

Reorganize the application into Clean Architecture layers that enforce dependency rules and separate concerns. This is the foundation that makes all other improvements possible.

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
    └── GraphApiOptions.cs       # Strongly-typed config (see Phase 3)
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

### Human Checkpoint (Phase 1)

**"The application has been reorganized into Clean Architecture layers: Domain (pure business logic), Application (use cases), Infrastructure (Graph API, identity), and Presentation (controllers, views). All tests pass. Do you approve this restructuring?"**

- Options: [Approve Phase 1] [Request changes] [Review dependency graph]

---

## Phase 2: Observability Architecture

### Goal

Extend the Aspire-based observability from Skill 02 with custom business metrics, structured logging enrichment, and health checks that make the application's runtime behavior transparent.

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

### Human Checkpoint (Phase 2)

**"Custom observability has been added: business metrics (emails fetched, replies sent, errors), distributed tracing with Activity sources, health checks for Graph API readiness, and correlation context in all logs. Do you approve?"**

- Options: [Approve Phase 2] [Request changes] [View Aspire dashboard]

---

## Phase 3: Maintainability Patterns

### Goal

Apply patterns that make the codebase easier to understand, change, and extend. These patterns reduce cognitive load and prevent common maintenance pitfalls.

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

### Human Checkpoint (Phase 3)

**"Maintainability patterns have been applied: Options pattern for configuration, Result pattern for error handling, Guard clauses, organized DI extensions, and global exception handling. Program.cs is now clean and well-structured. Do you approve?"**

- Options: [Approve Phase 3] [Request changes] [Review Program.cs]

---

## Phase 4: Testability Architecture

### Goal

Extend the test infrastructure from Skill 03 with patterns that make every layer independently testable and support integration testing.

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
- Review code coverage — should exceed the baseline from Skill 03

### Human Checkpoint (Phase 4)

**"Testability architecture has been enhanced: test data builders for clean test setup, integration tests with WebApplicationFactory, architecture tests that enforce Clean Architecture layering, and reorganized test structure. All tests pass. Do you approve?"**

- Options: [Approve Phase 4] [Request changes] [Run tests with coverage]

---

## Summary of Patterns Applied

| Quality | Pattern | Purpose |
|---------|---------|---------|
| **Observability** | Custom ActivitySource | Distributed tracing for business operations |
| **Observability** | Custom Meter & Counters | Business metrics (emails fetched, replies sent, errors) |
| **Observability** | Correlation Middleware | Request tracking across all log entries |
| **Observability** | Health Checks | Liveness and readiness probes for Graph API |
| **Maintainability** | Clean Architecture | Layer separation with enforced dependency rules |
| **Maintainability** | Options Pattern | Strongly-typed, validated configuration |
| **Maintainability** | Result Pattern | Explicit error handling without exception abuse |
| **Maintainability** | Guard Clauses | Consistent parameter validation |
| **Maintainability** | DI Extension Methods | Organized, modular service registration |
| **Maintainability** | Global Exception Middleware | Consistent error responses with correlation IDs |
| **Testability** | Test Data Builders | Declarative, readable test setup |
| **Testability** | WebApplicationFactory | Full-pipeline integration testing |
| **Testability** | Architecture Tests | Automated layering rule enforcement |
| **Testability** | Interface Segregation | Small, focused interfaces for easy mocking |

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

- [ ] Application organized into Clean Architecture layers (Domain, Application, Infrastructure, Presentation)
- [ ] Domain layer has zero infrastructure dependencies
- [ ] Custom OpenTelemetry metrics and traces wired into Aspire
- [ ] Health check endpoints operational (/health/live, /health/ready)
- [ ] Correlation middleware enriches all log entries
- [ ] Options pattern replaces all raw IConfiguration usage
- [ ] Result pattern used for expected failure paths
- [ ] Guard clauses validate all public API parameters
- [ ] DI registration organized with extension methods
- [ ] Global exception middleware catches unhandled errors
- [ ] Test data builders created for all domain models
- [ ] Integration tests exercise the HTTP pipeline
- [ ] Architecture tests enforce layering rules
- [ ] All tests pass (unit, integration, architecture)
- [ ] Application runs correctly under Aspire with new architecture

---

## Human Checkpoint

Before considering this skill complete, present results to the developer:

1. **"Does the application build and run correctly?"**
   - If no: investigate and fix
2. **"Do all tests pass (unit, integration, architecture)?"**
   - If no: fix failing tests
3. **"Are the custom metrics visible in the Aspire dashboard?"**
   - If no: verify OpenTelemetry registration
4. **"Do the health check endpoints respond correctly?"**
   - If no: debug health check implementations
5. **"Do you approve this architectural modernization?"**
   - Options: [Approve and proceed] [Request changes] [Revert to pre-architect checkpoint]

Do NOT consider this skill complete without explicit human approval.

---

## Next Skill

Upon approval → **Skill 05: Final Validation & Documentation** (`ews-validate`)
