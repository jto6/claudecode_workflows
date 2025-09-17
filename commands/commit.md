# Interactive Atomic Commit Workflow - /commit

Execute an interactive, atomic commit workflow with comprehensive analysis and user approval at each stage.

## Usage
```
/commit           # Interactive mode with approvals
/commit -y        # Auto-approve mode (skip interactive prompts)
```

## Commit Convention

**Subject Line Format:** `<subsystem>: one-line summary`

**Full Commit Structure:**
```
<subsystem>: one-line summary

Detailed explanation of the changes in the commit body:
- What was changed and why
- Key implementation details
- Any important context or decisions
- Breaking changes or migration notes if applicable
```

**Subject Line Examples:**
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
- **Bug fixes** - Each bug fix should be in a separate commit, unless they are interdependent and the fixes cannot be separated.

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
```

**Interactive Mode:** Present choices for user selection:
1. ✅ Proceed with this commit plan
2. 🚀 Proceed with this commit plan (no further approvals needed)
3. 🔄 Modify the plan
4. ❌ Abort commit process

**Auto-Approve Mode (-y):** Skip this approval step and proceed directly to execution.

## Phase 1.5: Pre-Commit Test Environment Verification

**Before starting any commits**, verify the test environment:

### Test Environment Check
- **MANDATORY**: Verify that the full test suite can run successfully
- Check for test dependencies and activate environments (venv, etc.)
- Run a quick test to ensure the test framework works: `pytest --version`, `npm test --help`, etc.  
- **If tests cannot run**: Set up the environment completely before proceeding with any commits
- **Report test environment status** to user before starting commits

This prevents discovering test issues mid-commit and ensures quality control from the start.

## Phase 2: Per-Commit Execution Loop

For each approved commit, execute this loop:

### 1. Test Coverage Analysis
- Check for new/modified functionality that needs tests
- Verify regression test coverage for bug fixes  
- Report missing test coverage (informational, don't block)
- Look for existing test files and test patterns in the codebase

### 2. Run Full Test Suite
**CRITICAL: This step is MANDATORY and cannot be skipped**

#### 2.1 Test Environment Setup
- **First**: Check if test dependencies are available
- **If missing dependencies**: Set up the test environment before proceeding
  - Look for `venv/`, `node_modules/`, or similar dependency directories  
  - Check for `requirements.txt`, `package.json`, or similar dependency files
  - Run setup commands: `source venv/bin/activate`, `npm install`, etc.
  - **NEVER proceed with commits until tests can run**

#### 2.2 Test Execution
- Identify the project's test command (pytest, npm test, make test, etc.)
- **Always run the full test suite** - not just basic tests
- Execute all tests and report results in detail
- **BLOCK commit if ANY tests fail** - do not proceed under any circumstances
- **BLOCK commit if tests cannot run due to missing dependencies** 
- Only continue to next step if ALL tests pass

#### 2.3 Test Failure Handling
- If tests fail, **immediately stop the commit process**
- Report exactly which tests failed and why
- Ask user how to proceed:
  - Fix the failing tests first
  - Abort the commit process
  - **NEVER ignore or skip failing tests**

### 3. Interactive Review Process
- Stage only the files for this specific commit
- Generate commit message following the convention (with subject and detailed body)
- Show the staged changes summary
- Present commit message for review
- **Interactive Mode:** Present choices for user selection:
  1. Accept this commit
  2. Modify and retry this commit
  3. Skip this commit
  4. Abort remaining commits
- **Auto-Approve Mode (-y or option 2 from plan approval):** Skip individual commit approval and proceed directly

### 4. Handle User Decision
Based on user selection from plan approval:
- **Option 1 (Proceed with plan)**: Execute each commit with individual approval prompts
- **Option 2 (Proceed without further approvals)**: Execute all commits automatically without individual approval prompts
- **Option 3 (Modify plan)**: Allow user to modify the commit plan
- **Option 4 (Abort)**: Stop the commit process completely

Based on individual commit approval (when in interactive mode):
- **Option 1 (Accept)**: Create the commit and continue to next commit
- **Option 2 (Modify)**: Allow user to modify files and retry this commit
- **Option 3 (Skip)**: Leave previous commits intact, move to next commit in plan
- **Option 4 (Abort)**: Stop the commit process, leave previous commits intact

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

**Before starting, check if `-y` flag was provided:**
- **Interactive Mode (default):** Follow all approval steps, including plan approval and individual commit approvals
- **Auto-Approve Mode (-y):** Skip plan approval and individual commit approvals, but still show the plan and commit details

**Plan Approval Options:**
- **Option 1:** Proceed with individual approval for each commit
- **Option 2:** Proceed without further approvals (equivalent to auto-approve mode for remaining commits)
- **Option 3:** Modify the plan
- **Option 4:** Abort the process

1. **Always start with Phase 1** - full analysis and planning
2. **MANDATORY: Verify test environment works** before any commits (Phase 1.5)
3. **Interactive Mode:** Wait for user approval before executing any commits
4. **Auto-Approve Mode (-y or option 2):** Show plan but proceed without approval prompts
5. **NEVER commit without running full test suite** - this is non-negotiable (applies to all modes)
6. **Interactive Mode (option 1):** Stop and request approval for each individual commit
7. **Auto-Approve Mode (-y or option 2):** Show commit details but proceed without individual approvals
8. **Preserve partial progress** - if a later commit is rejected, earlier commits remain
9. **Use parallel tool calls** for efficiency where appropriate
10. **Be thorough but respectful** of user time and preferences

### Critical Quality Gates
- ❌ **DO NOT commit if tests fail**
- ❌ **DO NOT commit if tests cannot run**  
- ❌ **DO NOT skip or rationalize around test failures**
- ✅ **DO ensure every commit passes the full test suite**

Execute this workflow to create clean, atomic, well-tested commits with full user control.
