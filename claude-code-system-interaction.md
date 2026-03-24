# How Claude Code Interacts With Your System

A deep dive into the architecture that lets Claude Code go beyond chat — reading, writing, compiling, and iterating on real systems.

## The Fundamental Model: Tool Use

At its core, Claude Code is still a large language model producing text. The critical difference from a chatbot is the **tool-use protocol** sitting between the model and your terminal.

Here's what actually happens on every turn:

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CONVERSATION LOOP                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                    │
│  1. You type a message (or a tool result arrives)                  │
│                                                                    │
│  2. The Claude Code client sends the full conversation             │
│     context to the Claude API, including:                          │
│       - System prompt (instructions, CLAUDE.md, etc.)              │
│       - Conversation history                                       │
│       - Tool definitions (JSON schemas for each tool)              │
│                                                                    │
│  3. Claude generates a response that may contain:                  │
│       - Plain text (shown to you)                                  │
│       - One or more TOOL CALLS (structured JSON)                   │
│                                                                    │
│  4. The Claude Code client intercepts tool calls and:              │
│       - Checks permissions (auto-allow or prompts you)             │
│       - Executes the tool locally on YOUR machine                  │
│       - Captures the result                                        │
│                                                                    │
│  5. The tool result is appended to the conversation                │
│     and sent back to Claude (go to step 2)                         │
│                                                                    │
│  6. When Claude produces only text (no tool calls),                │
│     the turn ends and you see the output                           │
│                                                                    │
└─────────────────────────────────────────────────────────────────────┘
```

The key insight: **I never "see" your filesystem directly.** I produce a structured tool call like `{"tool": "Read", "file_path": "/home/jon/main.c"}`, the client executes it, and I receive the file contents as text in my next context window. From my perspective, it's all text in, text out — but the client bridges that gap to your real system.

## The Tools: My Interface to Your Machine

Each tool is defined by a JSON schema that tells me what parameters it accepts. I can only interact with your system through these tools — I cannot execute arbitrary actions outside of them.

### Core Tool Categories

| Category          | Tools                        | What They Do                                    |
|-------------------|------------------------------|-------------------------------------------------|
| **File Reading**  | `Read`, `Glob`, `Grep`      | Find and read files without side effects        |
| **File Writing**  | `Write`, `Edit`              | Create or modify files                          |
| **Shell Access**  | `Bash`                       | Run any shell command — this is the big one     |
| **Web Access**    | `WebFetch`, `WebSearch`      | Retrieve URLs or search the web                 |
| **Delegation**    | `Agent`                      | Spawn sub-agents for parallel/complex work      |
| **User Comms**    | `AskUserQuestion`           | Explicitly ask you something                    |

### The Bash Tool Is the Universal Adapter

The `Bash` tool is what makes Claude Code fundamentally different from a code-completion assistant. Through it, I can run **any command your shell can run**:

- Compilers: `gcc`, `arm-none-eabi-gcc`, `rustc`, `cargo build`
- Build systems: `make`, `cmake`, `ninja`, `platformio`
- Flashing tools: `openocd`, `st-flash`, `esptool.py`, `probe-rs`
- Serial monitors: `picocom`, `minicom`, reading `/dev/ttyUSB0`
- Test runners: `pytest`, `cargo test`, `ctest`
- Version control: `git`
- Package managers: `apt`, `pip`, `npm`, `cargo`
- Literally anything else in your `$PATH`

This is why setting up your toolchain properly is the single most important thing you can do to make me effective.

## The Permission Model

You control what I can do. There are three layers:

### 1. Permission Modes

Claude Code has permission modes that determine how much latitude I get:

- **Default**: I can read files freely, but must ask before writing files or running commands
- **Auto-approve**: Certain categories of actions are pre-approved (configurable)
- **Trust settings in CLAUDE.md / settings**: Fine-grained allow/deny lists for specific commands

### 2. Per-Tool Prompting

When I try to use a tool that isn't pre-approved, you see a prompt like:

```
Claude wants to run: make -C build flash
Allow? [y/n/always]
```

Choosing "always" adds it to your allow list for the session or permanently.

### 3. Settings File Configuration

In `.claude/settings.json` (or the project-level equivalent), you can pre-approve patterns:

```json
{
  "permissions": {
    "allow": [
      "Bash(make *)",
      "Bash(arm-none-eabi-gcc *)",
      "Bash(openocd *)",
      "Bash(picocom *)",
      "Read(*)",
      "Write(src/*)"
    ]
  }
}
```

This is how you eliminate the permission prompts that would break an autonomous loop.

## The Refinement Loop: How Autonomous Iteration Works

When I'm working on a task, I naturally operate in a loop because of how the tool protocol works. Here's the conceptual flow for an embedded development task:

```
┌──────────────────────────────────────────────────────────────────┐
│                    AUTONOMOUS REFINEMENT LOOP                    │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────┐    ┌───────────┐    ┌──────────┐    ┌──────────┐  │
│  │  Write /  │───▶│  Compile  │───▶│  Flash   │───▶│ Observe  │  │
│  │  Edit     │    │  (Bash)   │    │  (Bash)  │    │  Output  │  │
│  │  Code     │    │           │    │          │    │  (Bash)  │  │
│  └──────────┘    └───────────┘    └──────────┘    └──────────┘  │
│       ▲                                                │         │
│       │            ┌──────────┐                        │         │
│       └────────────│ Analyze  │◀───────────────────────┘         │
│                    │ Results  │                                   │
│                    └──────────┘                                   │
│                                                                  │
│  Each arrow is a tool call → tool result → next tool call.       │
│  I keep looping until the goal is met or I hit a blocker.        │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

Each box is a tool call. The result of each call comes back to me as text, and I decide what to do next. There is **no magic** — it's the same generate-text → execute-tool → read-result cycle, repeated.

The reason this works without your intervention is that I can:

1. **Read compiler errors** (they're just text in the Bash result)
2. **Understand what went wrong** (that's what the LLM is good at)
3. **Edit the code to fix it** (via the Edit tool)
4. **Try again** (another Bash call)

## What You Need to Provide for Full Autonomy

For me to work in a fully autonomous loop on an embedded target (or any non-trivial system), you need to give me:

### 1. A Working Toolchain (Already Installed)

I can't install system packages without `sudo` (and you probably don't want me to). Make sure the cross-compiler, flasher, and monitor tools are in `$PATH`.

```bash
# Verify before starting a session:
which arm-none-eabi-gcc    # or your target's compiler
which openocd              # or your flasher
which picocom              # or your serial monitor
```

### 2. Pre-Approved Permissions

Add your build/flash/monitor commands to your settings so the loop doesn't block on permission prompts:

```json
{
  "permissions": {
    "allow": [
      "Bash(make *)",
      "Bash(cmake *)",
      "Bash(arm-none-eabi-* *)",
      "Bash(openocd *)",
      "Bash(st-flash *)",
      "Bash(picocom *)",
      "Bash(cat /dev/ttyUSB*)",
      "Read(*)",
      "Edit(*)",
      "Write(src/*)",
      "Write(include/*)"
    ]
  }
}
```

### 3. A CLAUDE.md With Project Context

Tell me how to build, flash, and test. I can figure out a lot from Makefiles, but explicit instructions eliminate guesswork:

```markdown
# CLAUDE.md

## Build
Run `make` in the project root. Cross-compiler is arm-none-eabi-gcc.
Output binary is `build/firmware.elf`.

## Flash
Run `make flash` to program the STM32F4 via ST-Link.
OpenOCD config is at `openocd.cfg`.

## Test / Observe
Serial output is on /dev/ttyUSB0 at 115200 baud.
To capture output: `timeout 5 cat /dev/ttyUSB0`
The firmware prints "PASS" or "FAIL" followed by details.

## Success Criteria
The program should print "ALL TESTS PASSED" on the serial console.
```

### 4. Observable Success/Failure Criteria

This is the most critical piece. I need a way to **programmatically determine** if the code works. Examples:

- Serial output containing a specific string (`PASS` / `FAIL`)
- An exit code from a test harness
- A log file I can read
- A GPIO state I can query via a script

Without observable criteria, I can't close the loop — I'd have to ask you "did it work?"

## Tutorial Examples

### Example 1: Basic Compile-Fix Loop (Native)

This demonstrates the simplest autonomous loop. No special hardware needed.

**Setup — create a CLAUDE.md:**

```markdown
# CLAUDE.md

## Build
gcc -Wall -Werror -o build/app src/main.c

## Test
./build/app
Expected exit code: 0
Expected stdout: contains "result: 42"
```

**Your prompt:**

> Write a C program in src/main.c that computes the 42nd element of a
> custom sequence (details...). Build it, run it, and iterate until
> the output matches the expected result.

**What happens internally (my tool calls):**

```
Turn 1:  Write(src/main.c, ...)           → file created
Turn 2:  Bash("gcc -Wall -Werror ...")     → compiler errors (maybe)
Turn 3:  Edit(src/main.c, fix errors)      → file updated
Turn 4:  Bash("gcc -Wall -Werror ...")     → success
Turn 5:  Bash("./build/app")              → "result: 37" (wrong)
Turn 6:  Read(src/main.c) + think          → found the bug
Turn 7:  Edit(src/main.c, fix logic)       → file updated
Turn 8:  Bash("gcc ... && ./build/app")    → "result: 42" ✓
Turn 9:  Text output to you: "Done. The program computes..."
```

Each turn is a round-trip: I generate a tool call, the client executes it, I see the result, I decide the next action.

### Example 2: Cross-Compilation for an Embedded Target

**Setup — CLAUDE.md:**

```markdown
# CLAUDE.md

## Project
STM32F401 bare-metal project. Blink an LED on PA5 at exactly 2 Hz.

## Toolchain
- Compiler: arm-none-eabi-gcc (in PATH)
- Build: `make` in project root
- Flash: `make flash` (uses openocd)

## Observe
Serial debug output on /dev/ttyACM0 at 115200.
Capture with: `timeout 10 cat /dev/ttyACM0`
Firmware prints timer tick count every 500ms.

## Success
Output shows exactly 4 ticks in 2 seconds (2 Hz toggle = 4 edges).
```

**Your prompt:**

> Implement the LED blinker per the CLAUDE.md spec. Compile, flash,
> and verify the timing via serial output. Fix and retry if needed.

**What happens:**

```
Turn 1:  Read Makefile, linker script, existing source
Turn 2:  Write/Edit source files
Turn 3:  Bash("make")                    → check for errors
Turn 4:  Bash("make flash")              → flash to board
Turn 5:  Bash("timeout 10 cat /dev/ttyACM0")  → read serial
Turn 6:  Analyze: seeing 8 ticks in 2s (too fast, 4 Hz not 2 Hz)
Turn 7:  Edit source (fix prescaler)
Turn 8:  Bash("make && make flash")
Turn 9:  Bash("timeout 10 cat /dev/ttyACM0")  → 4 ticks in 2s ✓
Turn 10: Text: "Fixed. The prescaler was set to..."
```

### Example 3: Setting Up a Test Harness Script

Sometimes the "observe" step is complex. You can write a helper script that I invoke, which simplifies my job:

```bash
#!/bin/bash
# test_firmware.sh — run by Claude Code to validate firmware behavior

set -e

echo "Flashing..."
make flash 2>&1

echo "Capturing serial output for 5 seconds..."
OUTPUT=$(timeout 5 cat /dev/ttyUSB0)

echo "--- RAW OUTPUT ---"
echo "$OUTPUT"
echo "--- END OUTPUT ---"

# Check criteria
if echo "$OUTPUT" | grep -q "ALL TESTS PASSED"; then
    echo "VERDICT: PASS"
    exit 0
else
    echo "VERDICT: FAIL"
    exit 1
fi
```

Then in CLAUDE.md:

```markdown
## Test
Run `./test_firmware.sh`
Exit code 0 = success, non-zero = failure.
Full serial output is printed for debugging.
```

Now my loop is simplified to: edit → `make` → `./test_firmware.sh` → read result → repeat if FAIL.

### Example 4: Using an Agent for Parallel Investigation

When debugging a complex issue, I can spawn sub-agents to investigate in parallel:

```
Main context:
  "The SPI driver isn't working. Let me investigate in parallel."

  Agent 1 (Explore): "Search the codebase for SPI initialization"
  Agent 2 (Explore): "Check the datasheet notes in docs/ for SPI clock config"
  Agent 3 (Bash):    "make && ./test_firmware.sh" (try current state)

  All three return results → I synthesize and make an informed fix
```

This is why the `Agent` tool exists — it lets me do multiple things at once without losing my main thread of reasoning.

## Practical Limits and Gotchas

### Context Window

My context window is large but finite. In long iterative sessions:

- Earlier tool results get compressed/summarized automatically
- Very long compiler outputs or serial logs can consume significant context
- **Mitigation**: Pipe verbose output through `head -50` or `tail -20`, or use the test harness pattern to produce concise PASS/FAIL verdicts

### Timeouts

Bash commands have a default 2-minute timeout (configurable up to 10 minutes). If your build or flash process takes longer:

- Use `timeout` parameter on the Bash tool (up to 600000ms)
- For very long operations, run in background and check later

### Interactive Commands

I **cannot** interact with programs that require real-time keyboard input (like a full `minicom` session or `gdb` in interactive mode). I can only:

- Send a command and read the output
- Use non-interactive alternatives (`timeout 5 cat /dev/ttyUSB0` instead of `minicom`)
- Use batch-mode debuggers (`gdb -batch -ex "commands..."`)
- Use `expect` scripts for tools that require interactive input

### Hardware State

I have no way to know hardware state beyond what software tools report. If the board is unplugged, the debugger is disconnected, or the serial port has changed names, I'll see an error and can report it — but I can't fix a physical problem.

### Permission Interruptions

Every time I hit a permission prompt and you have to approve, the autonomous loop breaks. Pre-approve everything you're comfortable with via settings to maintain flow.

## Summary: The Recipe for Autonomous Claude Code

1. **Install and verify your toolchain** — everything must work from the command line
2. **Pre-approve permissions** — eliminate interactive prompts for build/flash/test commands
3. **Write a clear CLAUDE.md** — document build, flash, test, and success criteria
4. **Make success/failure observable** — a script that exits 0/1 is ideal
5. **Constrain serial/debug capture** — use `timeout` and `head`/`tail` to keep output manageable
6. **Provide the goal clearly** — tell me what "done" looks like

With these in place, you can give me a goal and I will iterate through write → build → flash → test → analyze → fix cycles until the goal is met or I hit a problem I can't solve on my own (at which point I'll tell you what's blocking me).
