# Interactive Atomic Commit Workflow - /commit

Execute an interactive, atomic commit workflow with comprehensive analysis and user approval at each stage.

## Commit Convention

Use format: `<subsystem>: one-line summary`

Examples:
- `timer: add automatic break transition with alarm`
- `gui: implement dark/light theme switching`
- `audio: add system sound file browser support`
- `tracking: add Google Drive database synchronization`
- `sync: implement leader election for multi-workstation deployment`

## Phase 1: Change Analysis & Commit Planning

### 1. Analyze All Changes
Run these commands in parallel:
- `git status` - Show all staged and unstaged changes
- `git diff` - Show unstaged changes
- `git diff --staged` - Show already staged changes
- `git log --oneline -5` - Show recent commit history for context

### 2. Group Changes Logically
Analyze all changes and group them by:
- **Feature/functionality** - Related feature additions or modifications
- **Subsystem** - Changes to specific modules or components
- **Dependencies** - Related dependency updates or configuration changes
- **Documentation** - README, docs, or comment updates

### 3. Propose Atomic Commit Structure
Create a plan showing:
- Clear logical boundaries between commits
- File lists for each proposed commit
- Descriptive commit messages following convention
- Dependencies between commits (if any)

### 4. Present Plan and Wait for Approval
Show the complete commit plan with:
```
📦 Proposed commit structure:

Commit 1: "<subsystem>: <summary>"
Files: file1.py, file2.js

Commit 2: "<subsystem>: <summary>"  
Files: file3.md, file4.json

Proceed with this commit plan? [y/n]
```

**STOP HERE** - Wait for explicit user approval before proceeding.

## Phase 2: Per-Commit Execution Loop

For each approved commit, execute this loop:

### 1. Test Coverage Analysis
- Check for new/modified functionality that needs tests
- Verify regression test coverage for bug fixes  
- Report missing test coverage (informational, don't block)
- Look for existing test files and test patterns in the codebase

### 2. Run Full Test Suite
- Identify and run the project's test command (npm test, pytest, make test, etc.)
- Execute all tests and report results
- **BLOCK commit if any tests fail** - do not proceed
- If tests pass, continue to next step

### 3. Interactive Review Process
- Stage only the files for this specific commit
- Generate commit message following the convention
- Show the staged changes summary
- Present commit message for review
- **Request explicit approval**: "Accept this commit? [y/n]"

### 4. Handle User Decision
- **If accepted**: Create the commit and continue to next commit
- **If rejected**: Leave previous commits intact, ask how to proceed:
  - Modify files and retry this commit
  - Skip this commit  
  - Abort remaining commits

### 5. Post-Commit Verification
- Show commit details with `git log -1 --stat`
- Continue to next commit in the plan

## Security and Quality Checks

For each commit, verify:
- No secrets, API keys, or sensitive data
- No overly permissive file permissions
- Proper input validation for new code
- Reasonable commit size and scope

## Final Steps

After all commits:
- Show summary of all commits created
- Suggest next steps (push, create PR, etc.)
- Note any follow-up tasks or test coverage gaps

## Instructions

1. **Always start with Phase 1** - full analysis and planning
2. **Wait for user approval** before executing any commits
3. **Stop and request approval** for each individual commit
4. **Preserve partial progress** - if a later commit is rejected, earlier commits remain
5. **Use parallel tool calls** for efficiency where appropriate
6. **Be thorough but respectful** of user time and preferences

Execute this workflow to create clean, atomic, well-tested commits with full user control.