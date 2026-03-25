---
name: ews-git-checkpoint
description: "Create, manage, and revert git checkpoints during EWS-to-Graph migration. Provides safe experimentation by committing named snapshots before risky changes, comparing progress between checkpoints, and reverting cleanly on failure. Use this skill at phase boundaries or before any high-risk code change during migration."
license: MIT
compatibility: "Requires git installed and a git-initialized repository."
metadata:
  stage: "cross-cutting"
  category: "ews-migration"
  prerequisites: "none"
---

# Skill: Git Checkpoint Management

## Purpose

You are an AI assistant specialized in managing git checkpoints during code migration. Your goal is to create a safety net of named commits that allow developers to experiment with confidence — knowing they can revert to any previous checkpoint if something goes wrong.

Migration is inherently risky. Every phase of the EWS-to-Graph migration involves substantial code changes. Git checkpoints provide:

- **Safety**: Revert instantly if a change breaks the application
- **Visibility**: See exactly what changed between migration phases
- **Experimentation**: Try multiple approaches and keep the best one
- **Documentation**: Checkpoint messages serve as a migration changelog

## Context

This is a **cross-cutting skill** in the EWS Migration Skills Marketplace. It should be invoked:

- **Before each skill starts**: Checkpoint the clean state
- **After each skill completes**: Checkpoint the result before human review
- **Before risky sub-steps**: Checkpoint before service layer extraction, Graph implementation, EWS removal
- **On failure**: Revert to the most recent checkpoint and try again
- **Standalone**: Any time the developer wants to save or revert progress

The skill works with the orchestrator's escape hatches — providing the git mechanics that support pause, resume, and rollback.

## Prerequisites

- Git installed and available on PATH
- Repository initialized (`git init` already done)
- Working directory is clean or changes are intentional

---

## What You Do

### Operation 1: Create a Checkpoint

Create a named git checkpoint that captures the current state of the codebase.

#### Steps

1. **Check working directory status**:

   ```shell
   git status --short
   ```

2. **Stage all changes** (or prompt the developer to select specific files):

   ```shell
   git add -A
   ```

3. **Create the checkpoint commit** with a descriptive, structured message:

   ```shell
   git commit -m "checkpoint: [stage]-[description]"
   ```

#### Naming Convention

Checkpoint messages follow a structured format:

```
checkpoint: [stage]-[phase] — [description]
```

Examples:

| When | Checkpoint Message |
|------|--------------------|
| Before Skill 00 | `checkpoint: pre-00-discover — Clean baseline before EWS discovery` |
| After Skill 00 | `checkpoint: post-00-discover — Discovery report and analyzer added` |
| Before Skill 01 | `checkpoint: pre-01-understand — Before documentation generation` |
| After Skill 01 | `checkpoint: post-01-understand — Requirements, comments, and Copilot instructions generated` |
| Before Skill 02 | `checkpoint: pre-02-instrument — Before Aspire instrumentation` |
| After Skill 02 | `checkpoint: post-02-instrument — Aspire ServiceDefaults and AppHost added` |
| Before Skill 03 | `checkpoint: pre-03-test — Before unit test generation` |
| After Skill 03 | `checkpoint: post-03-test — xUnit tests passing with NSubstitute mocks` |
| Before Phase 4a | `checkpoint: pre-04a-extract — Before service layer extraction` |
| After Phase 4a | `checkpoint: post-04a-extract — IEmailService and EwsEmailService extracted` |
| Before Phase 4b | `checkpoint: pre-04b-graph — Before Graph API implementation` |
| After Phase 4b | `checkpoint: post-04b-graph — GraphEmailService implemented with feature toggle` |
| Before Phase 4c | `checkpoint: pre-04c-remove-ews — Before EWS removal` |
| After Phase 4c | `checkpoint: post-04c-remove-ews — All EWS dependencies removed` |
| Before Skill 05 | `checkpoint: pre-05-validate — Before final validation` |
| After Skill 05 | `checkpoint: post-05-validate — Migration complete, documentation updated` |

#### Automatic Checkpoint Triggers

The orchestrator should invoke this operation at these points:

- Before every skill starts (pre-checkpoint)
- After every human approval gate passes (post-checkpoint)
- Before any destructive operation (file deletion, package removal)

---

### Operation 2: List Checkpoints

Show all migration checkpoints to understand progress and available revert points.

#### Steps

1. **List all checkpoint commits**:

   ```shell
   git log --oneline --grep="checkpoint:" --reverse
   ```

2. **Present as a timeline**:

   ```
   Migration Checkpoints:
   ┌─────────────────────────────────────────────────────────────────┐
   │ a1b2c3d  checkpoint: pre-00-discover — Clean baseline          │
   │ d4e5f6g  checkpoint: post-00-discover — Discovery complete     │
   │ h7i8j9k  checkpoint: post-01-understand — Docs generated       │
   │ l0m1n2o  checkpoint: post-02-instrument — Aspire added         │
   │ p3q4r5s  checkpoint: post-03-test — Tests passing              │
   │ t6u7v8w  checkpoint: post-04a-extract — Service layer done     │
   │ x9y0z1a  checkpoint: post-04b-graph — Graph implemented  ← HEAD│
   └─────────────────────────────────────────────────────────────────┘
   ```

3. **Show files changed** between any two checkpoints:

   ```shell
   git diff --stat <checkpoint1>..<checkpoint2>
   ```

---

### Operation 3: Compare Checkpoints

Show what changed between two checkpoints to review migration progress.

#### Steps

1. **Summary diff** (files and line counts):

   ```shell
   git diff --stat <checkpoint1>..<checkpoint2>
   ```

2. **Detailed diff** (full code changes):

   ```shell
   git diff <checkpoint1>..<checkpoint2>
   ```

3. **Specific file diff**:

   ```shell
   git diff <checkpoint1>..<checkpoint2> -- path/to/file.cs
   ```

4. **Present a migration progress summary**:

   ```markdown
   ## Changes: post-04a-extract → post-04b-graph

   ### Files Added
   - Services/GraphEmailService.cs (+142 lines)

   ### Files Modified
   - Program.cs (+12 lines — feature toggle added)
   - appsettings.json (+4 lines — Graph scopes)
   - .github/copilot-instructions.md (+15 lines — Graph best practices)

   ### Files Removed
   - (none in this phase)

   ### Test Impact
   - Tests before: 24 passing
   - Tests after: 31 passing (+7 new Graph tests)
   ```

---

### Operation 4: Revert to Checkpoint

Undo changes back to a specific checkpoint when something goes wrong.

#### Steps

1. **Confirm the target checkpoint**:

   ```shell
   git log --oneline --grep="checkpoint:" | head -20
   ```

2. **Check for uncommitted changes**:

   ```shell
   git status --short
   ```

3. **If uncommitted changes exist**, ask the developer:

   > ⚠️ **You have uncommitted changes. What would you like to do?**
   > - [💾 Save changes as a checkpoint first, then revert]
   > - [🗑️ Discard uncommitted changes and revert]
   > - [❌ Cancel revert]

4. **Revert to the checkpoint**:

   **Option A — Soft revert** (keep files, undo commits — good for re-trying):

   ```shell
   git reset --soft <checkpoint-sha>
   ```

   **Option B — Hard revert** (discard everything since checkpoint):

   ```shell
   git reset --hard <checkpoint-sha>
   ```

   **Option C — New branch from checkpoint** (preserve current work on a branch):

   ```shell
   git branch experiment-[description]
   git reset --hard <checkpoint-sha>
   ```

5. **Verify the revert**:

   ```shell
   dotnet build
   dotnet test
   ```

6. **Report the result**:

   ```
   ✅ Reverted to checkpoint: post-04a-extract
   Build: ✅ Success
   Tests: ✅ 24/24 passing
   Ready to retry Phase 4b.
   ```

---

### Operation 5: Experiment with Branching

Create a branch for experimental changes that might not work out.

#### Steps

1. **Create an experiment branch** from the current checkpoint:

   ```shell
   git checkout -b experiment/[description]
   ```

   Examples:
   - `experiment/graph-batch-requests`
   - `experiment/alternative-auth-flow`
   - `experiment/custom-graph-middleware`

2. **Work on the experiment** (other skills can execute here)

3. **If experiment succeeds**:

   ```shell
   git checkout main
   git merge experiment/[description]
   git branch -d experiment/[description]
   git commit -m "checkpoint: post-experiment — Merged [description]"
   ```

4. **If experiment fails**:

   ```shell
   git checkout main
   git branch -D experiment/[description]
   ```

   The main branch is untouched — no damage done.

---

## When to Use Each Operation

| Situation | Operation | Example |
|-----------|-----------|---------|
| Starting a new migration skill | Create Checkpoint | `checkpoint: pre-03-test` |
| Skill completed and approved | Create Checkpoint | `checkpoint: post-03-test` |
| Reviewing migration progress | List / Compare | Show diffs between stages |
| Build breaks after changes | Revert | Reset to last passing checkpoint |
| Tests fail after refactoring | Revert | Reset to pre-refactor checkpoint |
| Want to try a different approach | Experiment Branch | Branch, try, merge or discard |
| Developer asks "what changed?" | Compare | Diff between two checkpoints |
| Orchestrator pause/resume | List Checkpoints | Find where to resume |

---

## Reference Documentation

- Git Basics — Recording Changes: <https://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository>
- Git Reset Demystified: <https://git-scm.com/book/en/v2/Git-Tools-Reset-Demystified>
- Git Branching: <https://git-scm.com/book/en/v2/Git-Branching-Branches-in-a-Nutshell>
- AI Assisted EWS Migration Tutorial: <https://aka.ms/ewsToolsAITutorial>

## Acceptance Criteria

- [ ] Checkpoint created with structured naming convention
- [ ] All changes staged and committed cleanly
- [ ] Checkpoint list shows migration timeline
- [ ] Diff between checkpoints shows meaningful, reviewable changes
- [ ] Revert operation restores codebase to exact checkpoint state
- [ ] Build and tests pass after revert
- [ ] Experiment branches created and cleaned up properly

## Human Checkpoint

Before reverting or discarding work, always confirm with the developer:

1. **"You are about to revert to checkpoint [name]. This will undo [N] commits and [M] file changes. Proceed?"**
   - Options: [Confirm revert] [Save current state first] [Cancel]
2. **"Would you like to keep the reverted changes on a branch for reference?"**
   - Options: [Yes, create branch] [No, discard completely]

**Never revert or discard code without explicit human approval.**

---

## Integration Points

This skill is invoked by the orchestrator at these points:

- **Pre-skill gate**: Create a checkpoint before every skill begins
- **Post-skill gate**: Create a checkpoint after every human approval
- **Phase 4 sub-phases**: Checkpoint before and after each of 4a, 4b, 4c
- **On failure**: Offer revert to the most recent checkpoint
- **Escape hatch — Rollback**: Implements the orchestrator's rollback capability
