---
name: ews-code-review
description: "Multi-model code review for EWS-to-Graph migration changes. Reviews each commit using three independent AI models (Claude Opus 4.6, Gemini 3 Pro, Claude Sonnet 4.5) in parallel, then synthesizes findings to surface only the most pressing concerns — bugs, security issues, and logic errors that multiple models agree on. Use after any migration skill to catch issues before human approval."
license: MIT
compatibility: "Requires git, and an agent runtime that supports multi-model task dispatch (e.g., GitHub Copilot CLI with model parameter)."
metadata:
  stage: "cross-cutting"
  category: "ews-migration"
  prerequisites: "none"
---

# Skill: Multi-Model Code Review

## Purpose

You are an AI assistant specialized in reviewing code changes made during EWS-to-Graph migration. Your goal is to catch bugs, security vulnerabilities, and logic errors before they reach production — by running three independent AI models in parallel and synthesizing their findings into a single, high-signal review.

### Why Multi-Model?

Single-model reviews have blind spots. Different models catch different classes of issues:

- **Claude Opus 4.6** — Deep reasoning about complex logic, architectural concerns, subtle correctness issues
- **Gemini 3 Pro** — Strong at identifying patterns, API misuse, and cross-referencing documentation
- **Claude Sonnet 4.5** — Fast, practical catch of common bugs, null reference risks, and security anti-patterns

By running all three in parallel and intersecting their findings, you get:

- **Higher signal**: Issues flagged by 2+ models are almost certainly real problems
- **Lower noise**: Style opinions and trivial nitpicks that only one model mentions are filtered out
- **Broader coverage**: Each model's unique strengths compensate for others' blind spots

## Context

This is a **cross-cutting skill** in the EWS Migration Skills Marketplace. It should be invoked:

- **After each migration skill completes**: Review the diff since the last checkpoint before human approval
- **After Phase 4a/4b/4c**: Critical review of service layer extraction, Graph implementation, and EWS removal
- **Before final validation**: Comprehensive review of the full migration diff
- **On demand**: Any time the developer wants a thorough review of recent changes

The skill works with `ews-git-checkpoint` — reviewing the diff between the pre- and post-checkpoint for each skill.

## Prerequisites

- Git repository with committed changes to review
- At least one commit or checkpoint to diff against
- Agent runtime with multi-model support (models: `claude-opus-4.6`, `gemini-3-pro-preview`, `claude-sonnet-4.5`)

---

## What You Do

### Step 1: Identify the Review Scope

Determine which commits to review:

**Option A — Review since last checkpoint** (most common during orchestrated migration):

```shell
# Find the most recent checkpoint
git log --oneline --grep="checkpoint:" -1

# Get the diff since that checkpoint
git diff <checkpoint-sha>..HEAD --stat
```

**Option B — Review a specific commit**:

```shell
git show <commit-sha> --stat
```

**Option C — Review a range of commits** (e.g., an entire skill's changes):

```shell
git log --oneline <start-sha>..<end-sha>
git diff <start-sha>..<end-sha> --stat
```

**Option D — Review staged/unstaged changes** (before committing):

```shell
git diff --stat           # unstaged
git diff --cached --stat  # staged
```

Present the scope to the developer:

```
📋 Code Review Scope
━━━━━━━━━━━━━━━━━━━
Commits: <start>..<end> (N commits)
Files changed: M
Lines added: +X
Lines removed: -Y

Proceed with multi-model review?
```

### Step 2: Dispatch Parallel Reviews

Launch three independent code-review agents, one per model, all in parallel. Each agent receives the same context:

1. The full diff to review
2. The migration context (which skill/phase produced these changes)
3. Review focus areas specific to the current migration stage

**Review prompt template** (sent to each model):

```
Review these code changes from the EWS-to-Graph API migration.

Migration stage: [current stage, e.g., "Phase 4b — Graph API Implementation"]
Changes since: [checkpoint name]

Focus on these areas (in priority order):
1. BUGS: Null references, unhandled exceptions, logic errors, race conditions
2. SECURITY: Token handling, credential exposure, permission scope issues, injection risks
3. CORRECTNESS: Graph API misuse, wrong endpoints, missing error handling for Graph-specific failures (429 throttling, 401 token expiry, ServiceException)
4. DATA LOSS: Missing null checks on Graph API responses, incorrect property mappings from EWS to Graph models
5. REGRESSION: Changes that could break existing functionality validated by unit tests

Do NOT comment on:
- Code style, formatting, or naming conventions
- Missing documentation or comments
- Test coverage gaps (unless a test is actively wrong)
- Minor refactoring suggestions

Only report issues that genuinely matter — bugs, security problems, or logic errors that could cause runtime failures.

For each issue found, provide:
- Severity: CRITICAL / HIGH / MEDIUM
- File and line(s) affected
- What the problem is (1-2 sentences)
- Suggested fix (code snippet if possible)
```

**Dispatch commands** (all three launched simultaneously):

```
Agent 1: code-review agent, model: claude-opus-4.6
Agent 2: code-review agent, model: gemini-3-pro-preview
Agent 3: code-review agent, model: claude-sonnet-4.5
```

### Step 3: Collect and Correlate Results

After all three agents complete, collect their findings and correlate:

1. **Parse each model's output** into structured findings:
   - Severity (CRITICAL / HIGH / MEDIUM)
   - File + line range
   - Issue description
   - Suggested fix

2. **Correlate findings across models** by matching on file + approximate line range + issue category:

   | Finding | Opus 4.6 | Gemini 3 Pro | Sonnet 4.5 | Consensus |
   |---------|----------|--------------|------------|-----------|
   | Null ref in GraphEmailService.cs:45 | ✅ HIGH | ✅ HIGH | ✅ MEDIUM | **3/3 — HIGH** |
   | Missing 429 retry in SendReplyAsync | ✅ MEDIUM | ❌ | ✅ MEDIUM | **2/3 — MEDIUM** |
   | Token scope too broad | ❌ | ✅ HIGH | ❌ | 1/3 — Review |

3. **Classify by consensus**:
   - **3/3 models agree**: Almost certainly a real issue — present as top priority
   - **2/3 models agree**: Likely a real issue — present for review
   - **1/3 only**: May be a false positive — present as "additional consideration" only if severity is CRITICAL

### Step 4: Present the Synthesized Review

Generate a review report ordered by consensus strength and severity:

```markdown
# Code Review Report

## Review Scope
- **Commits**: a1b2c3d..f4e5d6c (3 commits)
- **Migration Stage**: Phase 4b — Graph API Implementation
- **Files Reviewed**: 5
- **Models Used**: Claude Opus 4.6, Gemini 3 Pro, Claude Sonnet 4.5

## 🔴 Critical Issues (address before proceeding)

### 1. Null reference when Graph API returns empty message list
**Consensus: 3/3 models** | Severity: HIGH
**File**: `Services/GraphEmailService.cs`, lines 42-48

**Problem**: `messages.Value` is accessed without null check. Graph API returns `null` for `Value` when the mailbox is empty, causing `NullReferenceException`.

**Fix**:
​```csharp
// Before
var emails = messages.Value.Select(m => MapToEmailMessage(m)).ToList();

// After
var emails = messages.Value?.Select(m => MapToEmailMessage(m)).ToList()
    ?? new List<EmailMessage>();
​```

**Flagged by**: Opus 4.6 (HIGH), Gemini 3 Pro (HIGH), Sonnet 4.5 (MEDIUM)

---

### 2. Missing retry logic for Graph API throttling (HTTP 429)
**Consensus: 2/3 models** | Severity: MEDIUM
**File**: `Services/GraphEmailService.cs`, lines 60-75

**Problem**: `SendReplyAsync` does not handle `ServiceException` with status 429. Graph API throttles aggressively and the SDK's default retry may not be configured.

**Fix**: Ensure `GraphServiceClient` is configured with retry handler, or add explicit retry logic.

**Flagged by**: Opus 4.6 (MEDIUM), Sonnet 4.5 (MEDIUM)

---

## 🟡 Additional Considerations

### 3. Token scope may be broader than needed
**Consensus: 1/3 models** | Severity: HIGH (single model)
**File**: `appsettings.json`, line 8

**Note**: Only Gemini 3 Pro flagged this. Review if `Mail.ReadWrite` is needed or if `Mail.Read` suffices for read-only operations.

**Flagged by**: Gemini 3 Pro (HIGH)

---

## ✅ Summary
| Severity | Count | Consensus |
|----------|-------|-----------|
| Critical/High (3/3) | 1 | Unanimous — fix required |
| Medium (2/3) | 1 | Majority — recommended fix |
| Single-model flags | 1 | For consideration |

**Recommendation**: Address issues #1 and #2 before proceeding to the next migration phase.
```

### Step 5: Human Review Gate

Present the synthesized review to the developer:

1. **"The multi-model code review found [N] issues. [X] have unanimous consensus, [Y] have majority consensus. Please review the report above."**

2. For each critical/high consensus issue, ask:

   > **Issue #1: [description]. Do you want to:**
   > - [🔧 Fix now]
   > - [📌 Acknowledge and defer]
   > - [❌ Dismiss (false positive)]

3. After all issues are addressed:

   > **"All review findings have been addressed. Proceed to the human approval gate?"**
   > - [✅ Yes, proceed to approval]
   > - [🔄 Re-run review after fixes]

---

## Migration-Stage-Specific Review Focus

The review prompt is customized based on the current migration stage:

| Stage | Additional Focus Areas |
|-------|----------------------|
| **Skill 01 (Understand)** | Documentation accuracy, requirements completeness |
| **Skill 02 (Instrument)** | Aspire configuration correctness, service defaults wiring |
| **Skill 03 (Test)** | Test correctness, mock setup accuracy, assertion validity |
| **Phase 4a (Extract)** | Interface completeness, DI registration, controller decoupling |
| **Phase 4b (Graph)** | Graph SDK usage, token scopes, error handling, property mapping |
| **Phase 4c (Remove EWS)** | Residual EWS references, broken imports, orphaned config |
| **Skill 05 (Validate)** | Documentation consistency, report accuracy |

---

## Model Selection Rationale

The three models were chosen for complementary strengths:

| Model | Strength | Best At Finding |
|-------|----------|-----------------|
| **Claude Opus 4.6** | Deep reasoning, architectural analysis | Subtle logic errors, design flaws, complex interaction bugs |
| **Gemini 3 Pro** | Pattern recognition, documentation cross-reference | API misuse, configuration errors, known anti-patterns |
| **Claude Sonnet 4.5** | Fast practical analysis, common bug patterns | Null refs, missing error handling, security basics, edge cases |

### Substituting Models

If a model is unavailable, substitute with the closest alternative:

- Opus 4.6 unavailable → use `claude-opus-4.5` or `gpt-5.1-codex`
- Gemini 3 Pro unavailable → use `gpt-5.2` or `gpt-4.1`
- Sonnet 4.5 unavailable → use `claude-sonnet-4` or `gpt-5.4-mini`

The key principle is **model diversity** — using models from different providers with different architectures maximizes the chance of catching different classes of issues.

---

## Reference Documentation

- GitHub Copilot CLI Code Review: Agent `code-review` type with `model` parameter override
- EWS to Graph API Mappings: <https://aka.ms/ews2graphMap>
- Graph API Error Handling: <https://learn.microsoft.com/en-us/graph/errors>
- Graph API Throttling: <https://learn.microsoft.com/en-us/graph/throttling>
- AI Assisted EWS Migration Tutorial: <https://aka.ms/ewsToolsAITutorial>

## Acceptance Criteria

- [ ] Three independent code-review agents dispatched in parallel (one per model)
- [ ] All three agents complete and return findings
- [ ] Findings correlated across models by file, line range, and issue category
- [ ] Consensus classification applied (3/3, 2/3, 1/3)
- [ ] Synthesized report generated with issues ordered by consensus and severity
- [ ] Critical/high consensus issues presented individually with fix/defer/dismiss options
- [ ] Developer reviews and addresses all findings before proceeding
- [ ] If fixes applied: re-review confirms issues resolved (optional)

## Human Checkpoint

The code review itself IS a human checkpoint — every finding is presented for human decision. The skill does not auto-fix anything.

After review completion:

1. **"All [N] findings have been reviewed. [X] fixed, [Y] deferred, [Z] dismissed."**
2. **"Do you approve the code changes?"**
   - Options: [Approve changes] [Request re-review] [Revert to checkpoint]

**Never auto-approve code changes. The developer must explicitly approve.**

---

## Integration Points

This skill is invoked by the orchestrator:

- **Post-skill gate**: After each skill completes, before human approval — review the checkpoint diff
- **Phase 4 sub-phases**: Critical review after each of 4a, 4b, 4c
- **On demand**: Developer can request a review at any time
- **After fixes**: Re-run review to confirm issues are resolved
