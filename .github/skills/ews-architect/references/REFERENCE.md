# Architecture Modernization — Reference Documentation

## Microsoft Documentation

### Clean Architecture & Application Design

- [Architect Modern Web Applications with ASP.NET Core](https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/) — Microsoft's canonical guide to Clean Architecture in .NET, including layering, dependency inversion, and domain-driven design.
- [Common Web Application Architectures](https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures) — Comparison of monolithic, N-layer, and Clean Architecture patterns.
- [Architectural Principles](https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/architectural-principles) — SOLID, separation of concerns, DRY, and encapsulation in .NET.

### Observability & Telemetry

- [.NET Observability with OpenTelemetry](https://learn.microsoft.com/en-us/dotnet/core/diagnostics/observability-with-otel) — Official guide to adding OpenTelemetry traces, metrics, and logs to .NET applications.
- [System.Diagnostics.ActivitySource](https://learn.microsoft.com/en-us/dotnet/core/diagnostics/distributed-tracing-instrumentation-walkthroughs) — Creating custom distributed traces with ActivitySource.
- [System.Diagnostics.Metrics](https://learn.microsoft.com/en-us/dotnet/core/diagnostics/metrics-instrumentation) — Creating custom metrics with Meter, Counter, and Histogram.
- [Health Checks in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/health-checks) — Implementing liveness and readiness probes.
- [.NET Aspire Overview](https://learn.microsoft.com/en-us/dotnet/aspire/get-started/aspire-overview) — Dashboard-driven observability for .NET cloud-native applications.

### Configuration & Options

- [Options Pattern in .NET](https://learn.microsoft.com/en-us/dotnet/core/extensions/options) — Strongly-typed configuration binding with IOptions, IOptionsSnapshot, and IOptionsMonitor.
- [Configuration in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/configuration) — Configuration sources, providers, and the configuration hierarchy.

### Testing

- [Integration Tests in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/test/integration-tests) — Using WebApplicationFactory for full-pipeline integration testing.
- [Unit Testing Best Practices](https://learn.microsoft.com/en-us/dotnet/core/testing/unit-testing-best-practices) — Naming conventions, AAA pattern, and test isolation.
- [Unit Testing with xUnit](https://learn.microsoft.com/en-us/dotnet/core/testing/unit-testing-with-dotnet-test) — xUnit framework reference for .NET.
- [NSubstitute Documentation](https://nsubstitute.github.io/) — Mocking framework for creating test doubles.

### Dependency Injection

- [Dependency Injection in .NET](https://learn.microsoft.com/en-us/dotnet/core/extensions/dependency-injection) — Built-in DI container, service lifetimes, and best practices.
- [Dependency Injection in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/dependency-injection) — Registering services, scoped vs transient vs singleton.

### Error Handling

- [Handle Errors in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/error-handling) — Exception handling middleware, Problem Details, and error pages.

## EWS Migration Context

- [Deprecation of EWS in Exchange Online](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/deprecation-of-ews-exchange-online) — Official deprecation announcement and migration timeline.
- [EWS to Graph API Mappings](https://aka.ms/ews2graphMap) — Operation-level mapping from EWS to Microsoft Graph.
- [EWS Migration Tools](https://aka.ms/ewsTools) — Code analyzers, usage reports, and migration guides.
- [AI Assisted EWS Migration Tutorial](https://aka.ms/ewsToolsAITutorial) — Step-by-step tutorial using Copilot for EWS migration.
- [Midnight Blizzard Security Incident](https://aka.ms/mblizz) — The security incident that elevated EWS migration urgency.

## Design Patterns Referenced

| Pattern | Purpose | Key Benefit |
|---------|---------|-------------|
| Clean Architecture | Layer separation with dependency inversion | Domain logic is portable and testable |
| Options Pattern | Strongly-typed configuration | Compile-time safety, validation on startup |
| Result Pattern | Explicit error handling | No hidden control flow via exceptions |
| Builder Pattern (tests) | Declarative test data construction | Readable, maintainable test setup |
| Guard Clauses | Parameter validation | Fail-fast with clear error messages |
| Middleware Pipeline | Cross-cutting concerns | Separation of infrastructure from business logic |
| Interface Segregation | Small, focused interfaces | Easy to mock, easy to understand |
| Dependency Injection | Loose coupling | Swappable implementations, testable components |
