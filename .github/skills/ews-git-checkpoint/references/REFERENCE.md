# Reference Documentation — Git Checkpoint Management

## Git Documentation

- **Git Basics — Recording Changes**: <https://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository>
- **Git Reset Demystified**: <https://git-scm.com/book/en/v2/Git-Tools-Reset-Demystified>
- **Git Branching**: <https://git-scm.com/book/en/v2/Git-Branching-Branches-in-a-Nutshell>
- **Git Diff**: <https://git-scm.com/docs/git-diff>
- **Git Log**: <https://git-scm.com/docs/git-log>
- **Git Stash**: <https://git-scm.com/docs/git-stash>

## Checkpoint Naming Convention

```
checkpoint: [stage]-[phase] — [description]
```

### Standard Checkpoints

| Checkpoint Message | When Used |
|--------------------|-----------|
| `checkpoint: pre-00-discover` | Before Skill 00 starts |
| `checkpoint: post-00-discover` | After Skill 00 approved |
| `checkpoint: pre-01-understand` | Before Skill 01 starts |
| `checkpoint: post-01-understand` | After Skill 01 approved |
| `checkpoint: pre-02-instrument` | Before Skill 02 starts |
| `checkpoint: post-02-instrument` | After Skill 02 approved |
| `checkpoint: pre-03-test` | Before Skill 03 starts |
| `checkpoint: post-03-test` | After Skill 03 approved |
| `checkpoint: pre-04a-extract` | Before Phase 4a |
| `checkpoint: post-04a-extract` | After Phase 4a approved |
| `checkpoint: pre-04b-graph` | Before Phase 4b |
| `checkpoint: post-04b-graph` | After Phase 4b approved |
| `checkpoint: pre-04c-remove-ews` | Before Phase 4c |
| `checkpoint: post-04c-remove-ews` | After Phase 4c approved |
| `checkpoint: pre-05-validate` | Before Skill 05 starts |
| `checkpoint: post-05-validate` | After migration complete |

## Git Commands Quick Reference

### Create Checkpoint

```shell
git add -A
git commit -m "checkpoint: post-03-test — xUnit tests passing with NSubstitute mocks"
```

### List Checkpoints

```shell
git log --oneline --grep="checkpoint:" --reverse
```

### Compare Checkpoints

```shell
# Summary
git diff --stat <sha1>..<sha2>

# Full diff
git diff <sha1>..<sha2>

# Specific file
git diff <sha1>..<sha2> -- path/to/file.cs
```

### Revert to Checkpoint

```shell
# Soft reset (keep changes staged)
git reset --soft <sha>

# Hard reset (discard all changes)
git reset --hard <sha>

# Save current work on a branch first
git branch experiment-backup
git reset --hard <sha>
```

### Experiment Branch

```shell
# Create
git checkout -b experiment/graph-batch-requests

# Merge if successful
git checkout main
git merge experiment/graph-batch-requests
git branch -d experiment/graph-batch-requests

# Discard if failed
git checkout main
git branch -D experiment/graph-batch-requests
```

## Safety Practices

1. **Always checkpoint before destructive operations** (file deletion, package removal)
2. **Never force-push** checkpoint history — it's the migration audit trail
3. **Use soft reset** when you want to redo a phase with the same changes staged
4. **Use hard reset** when you want to completely start over from a checkpoint
5. **Use experiment branches** when trying something uncertain — keeps main branch clean

## EWS Migration

- **AI Assisted EWS Migration Tutorial**: <https://aka.ms/ewsToolsAITutorial>
