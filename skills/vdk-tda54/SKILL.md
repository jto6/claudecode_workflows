---
name: vdk-tda54
description: "Guides Claude on operating the TDA54 VDK simulation: launching simulations,
  monitoring UART output, configuring boot/core reset via simprobe, and attaching TRACE32/GDB debuggers."
triggers:

  - "vdk"
  - "virtualizer"
  - "tda54 simulation"
  - "vpconfig"
  - "simulate tda54"
  - "run simulation"
  - "uart terminal"
  - "simout"
  - "trace32"
  - "boot configure"
python_deps: []
---

# VDK TDA54 Simulation Skill

The TDA54 VDK (Virtual Development Kit) is a Synopsys Virtualizer-based full-SoC simulation of
the TI TDA54 automotive SoC. It enables software development, integration testing, and debug
before hardware is available.

## Overview

The VDK runs inside a TI SDK Docker container and is accessed through the `tda54-build` shell
function. Virtualizer Studio (VS) is the GUI-based simulation IDE; it loads VP configuration
files that define the simulation topology.

### Workspace Path Conventions

VDK documentation uses `<Workspace>/TDA5_System/` as a placeholder. Actual paths for this
installation:

- **Host**: `/home/jon/dev/tijsdk/ti-sdk/workspace/<workspace_name>/`
  (e.g., `TDA_R8` for R8.0, `TDA5_R9` for R9.0)
- **Container**: `/work/ti-sdk/workspace/<workspace_name>/`

Throughout this skill, `<WS>` means `/work/ti-sdk/workspace/<workspace_name>` (the
container-side path). Additional documentation PDFs are at `<WS>/Documentation/pdf/`.

**Note**: UART monitor hierarchy paths like `/TDA5_System/TDA5_SoC/Periphs/UART_PHY` are
Virtualizer model-internal object paths, not filesystem paths.

## Container Invocation

All simulation commands run through the `tda54-build` wrapper, which invokes `_run_sdk_container`
for the TDA54 presil container. `tda54-build` is a zsh function defined in `.zshrc`; invoke it
via `zsh -i -c` from scripts (bare `bash` will not find the function).

The `vs` sub-command launches Virtualizer Studio (VS). Always supply:

- `--nointro` — skip the VS splash/welcome screen
- `-d <workspace-root>` — the workspace ROOT directory containing all project subdirs (e.g.
  `/work/ti-sdk/workspace`), **not** the project subdirectory itself
- `-r <path-to-vpconfig.vpcfg>` — the VP config to load
- `--simout <log-path>` — path for the Virtualizer system log (optional but useful)

```zsh
tda54-build vs --nointro -d /work/ti-sdk/workspace \
    -r <WS>/vpconfigs/tda54-vdk-linux/tda54-vdk-linux.vpcfg \
    --simout <WS>/bin/simout.txt
```

## VP Config Catalog

VP configuration (`.vpcfg`) files define the simulation topology. They live at
`<WS>/vpconfigs/<config-name>/<config-name>.vpcfg`.

Key available configurations:

| VP Config             | Description                                                |
|-----------------------|------------------------------------------------------------|
| tda54-vdk-linux       | Full system: A720 + boot/security processors, TI SDK Linux |
| Dhrystone_A720        | A720 bare-metal performance test                           |
| FreeRTOS_C7x_0_TDA4   | C7x FreeRTOS test                                          |
| miniaarchlinux_PF_M55 | Minimal Linux with M55 platform firmware                   |
| tda54-baremetal-*     | Core-specific bare-metal configs                           |

## Simulation Lifecycle

Start simulation (requires `DISPLAY` for VS GUI):

```zsh
tda54-build vs --nointro -d /work/ti-sdk/workspace \
    -r <WS>/vpconfigs/tda54-vdk-linux/tda54-vdk-linux.vpcfg \
    --simout <WS>/bin/simout.txt
```

Key operational details:

- **`initial_crunch` breakpoint**: VDK always starts in SUSPENDED state at this breakpoint.
  Before any code executes, you must resume: in the VS toolbar select
  **VDK Debug → Resume Simulation**. Without this step the simulation stays frozen.
- Virtualizer system log: `<WS>/bin/simout.txt` (simbrobe/peripheral model messages, not
  Linux console output)
- Monitor system log: `tail -f <WS>/bin/simout.txt`
- Linux/firmware console output appears in the **UART PHY terminal windows** in VS GUI (see
  UART Output Monitoring below), not in simout.txt
- Simulation controls: Run/Pause/Stop buttons in VS GUI, or via the built-in Python console

To stop and shut down:

1. **VDK Debug → Stop Simulation** — halts the running simulation
2. **File → Exit** — closes Virtualizer Studio and the VDK process

## UART Output Monitoring

Two main approaches:

**simout.txt** — captures Virtualizer system-level output (simbrobe/peripheral model messages,
not Linux/firmware console output):

```zsh
tail -f <WS>/bin/simout.txt
```

**UART PHY Terminals (GUI)** — each core has a UART_PHY component. To open automatically on
simulation start, navigate to VPConfig parameters: `Periphs → UART → <instance> → UART_PHY`,
then set:

- `TerminalAutoOpen = true`
- `TerminalName = "MyCore_UART"` (optional label)

**TCP redirect** — Set the `ENABLE_TCP_ON_PORT` SCML parameter (int, 4000–65535) on any
`UART_PHY` to open a TCP socket; any TCP client can connect and receive raw UART TX bytes.
Set `TCP_POLL_US = 0` for best performance. Also available: `EN_UART_TX_LOG_TO_FILE` (string)
dumps UART TX directly to a file with no TCP client needed.

### UART Monitor Hierarchy

These are Virtualizer model-internal object paths (not filesystem paths):

- Main UART (A720 A-core): `/TDA5_System/TDA5_SoC/Periphs/UART_PHY`
- R52Plus (boot processor): `/TDA5_System/TDA5_SoC/Periphs/UART_PHY_R52P_[0-3]`
- Multimedia M55: `/TDA5_System/TDA5_SoC/Periphs/UART_PHY_MM_M55_[0-4]`
- DM M55: `/TDA5_System/TDA5_SoC/Periphs/UART_PHY_DM_M55`
- ROT M55 (security processor): `/TDA5_System/TDA5_SoC/Periphs/UART_PHY_ROT_M55`
- AutoHSM M55: `/TDA5_System/TDA5_SoC/Periphs/UART_PHY_AutoHSM_M55`
- MCU Security UART: `MCU_Domain/Security/MCU_SEC_UART_PHY_0`
- MCU DM UART: `MCU_Domain/DM/DM-UART_PHY`
- MCU General UARTs: `MCU_Domain/Periphs/UART/DW_UART_PHY_[0-19]`

## Boot Configuration (Core Reset)

By default after MCU_POR, only ROT_M55, AutoHSM, and DM cores are out of reset. All other
cores (A720, R52Plus, Multimedia M55, C7x) are held in reset until explicitly released by the
mock boot code.

To bring cores out of reset, use the `boot_configure.py` simprobe script:

1. Add the boot code binary to VPConfig → Images → ROT → InitialIm:
   `<WS>/software/bootcode_M55/`
2. Add `${vpconfDir}/boot_configure.py` to VPConfig → Scripting → Begin of Simulation
3. Edit `boot_configure.py` to specify which cores to start and their reset vector addresses

Simprobe scripts location: `<WS>/vpconfigs/shared/simprobe_scripts/`

A template `boot_configure.py` is bundled with this skill (`simprobe_boot_template.py`).

Core names accepted by `bootcode_utils.configure_core_out_of_reset()`:

- `"Main_M55_0"`
- `"A720 Core0"` through `"A720 Core7"`
- `"C7x_0"` through `"C7x_3"`
- `"RTSS_0_R52_CORE0"`, `"RTSS_1_R52_CORE0"`, etc.

## Debug Interface

### TRACE32 (Lauterbach)

Primary debugger for A720, R52Plus, and M55 cores:

1. Configure the debug connection in VPConfig → Debug tab
2. Start the simulation in VS GUI
3. Launch TRACE32 and connect to the VDK debug interface port for the target core
4. Use standard TRACE32 PRACTICE scripts for ARM Cortex-A/R/M targets

### GDB Remote

VDK exposes a GDB server port for each core. Port assignments are in VPConfig → Debug tab.

```zsh
arm-none-eabi-gdb -ex "target remote :<port>" <elf-file>
```

### Python Console

The VS GUI includes a built-in Python interpreter (Console tab):

- Full API access to simulation objects, memory, and registers
- Run scripts: `vs.executeScript("path/to/script.py")`

## SSH into Linux Guest

Configure VIRTIO_ETHERNET in VPConfig parameters:

- `hostbridge_userNetworking = true`
- `hostbridge_userNetPorts = "8022=22"` (forwards host port 8022 → guest SSH port 22)

Then from a shell inside the container:

```zsh
ssh -o StrictHostKeyChecking=no -p 8022 root@127.0.0.1
```

## Headless Test Automation (vssh)

`vssh --vdk_test` is Virtualizer Studio's headless shell mode: it loads a VP config and runs a
Python test script **inside** the VS Python interpreter with `vpx` and `vpconfig` globals
injected. No X11 or GUI is needed. This is the recommended approach for CI/CD automation and
scripted command execution.

### vssh Invocation

```zsh
tda54-build vssh -d /work/ti-sdk/workspace \
    --vdk_test null,<vpconfig_name_or_path>,<test_script.py> \
    --pyout <python_log> \
    --logfile <vs_log> \
    --pyargs <script_args> --pyargs_end
```

Key flags:

- `-d <workspace_root>`: the workspace ROOT directory (containing project subdirs), e.g.
  `/work/ti-sdk/workspace` — NOT the project subdirectory itself
- `--vdk_test null,<vpconfig>,<script>`: `null` as the first field opens the vpconfig directly;
  `<vpconfig>` can be the config name (looked up in workspace) or a full path to a `.vpcfg` file
- `--pyout`: where to write the test script's stdout/stderr
- `--logfile`: where to write the Virtualizer system log (similar to simout.txt)
- `--pyargs ... --pyargs_end`: arguments forwarded to `sys.argv` of the test script

### Test Script Lifecycle

Test scripts subclass `vdk_test_infra.VDKTestBase`. The framework calls:

1. `before_test_run(vpconfig)` — configure the simulation (image paths, SCML overrides, etc.)
2. `test_run()` — run test logic; has full access to `vpx.*` globals
3. `after_test_run(vpconfig)` — cleanup

Key `vpx` globals available in `test_run()`:

- `vpx.continue_simulation()` — resume the sim (bypasses initial_crunch automatically)
- `vpx.wait_interrupted(wall_sec)` — wait for sim to pause/breakpoint (real wall-clock seconds)
- `vpx.interrupt()` — pause the simulation
- `vpx.stop_simulation()` / `vpx.kill_simulation()` — stop/kill cleanly
- `vpx.is_interrupted()` — True when sim is at a breakpoint
- `vpx.get_node(path)` → model node handle; call `.send_command(cmd)` to interact
- `vpx.create_breakpoint("at_notify", event)` → fires when event is notified
- `vpx.create_time_breakpoint(value, unit, is_relative)` → fires at a simulation time
- `vpx.create_checkpoint(path)` / `vpx.restore_checkpoint(path)` → snapshot save/restore
- `vpx.get_top_instance_name()` → returns the top-level system name (e.g., `"TDA5_System"`)

Key `vpconfig` methods available in `before_test_run(vpconfig)`:

- `vpconfig.set_parameter_value_override(component_path, group, key, value)` — override any
  SCML parameter at runtime; component path uses `/` separators (e.g.,
  `/TDA5_System/TDA5_SoC/Periphs/UART_PHY`)
- `vpconfig.create_image_spec(file, addr, type)` + `create_image_info(spec)` +
  `set_image_info(component, group, key, info)` — load binaries into memory at boot
- `vpconfig.set_auto_continue_initial_crunch(False)` — prevent auto-resume past initial_crunch

### UART Interaction in vssh Scripts

Use `vpx.get_node(uart_path).send_command()` to interact with UART_PHY from inside the script.
The automation team's `Uart` utility class (also inline in the bundled template) simplifies this:

```python
uart = Uart("/TDA5_System/TDA5_SoC/Periphs/UART_PHY")

# Push text into UART RX (host → SoC), adds CR+LF automatically
uart.push("root")

# Continue sim and wait for pattern in UART TX (SoC → host); returns True on match
uart.run_to_match("# ", pre_cmd="ls -la", timeout_wall_sec=60)
```

`run_to_match(pattern, pre_cmd, timeout_wall_sec)` pushes `pre_cmd` then resumes the sim and
waits up to `timeout_wall_sec` **real wall-clock seconds** for the pattern to appear.

### UART_PHY SCML Parameters for Automation

Set these in `before_test_run()` via `vpconfig.set_parameter_value_override()`:

```python
UART_PATH = "/TDA5_System/TDA5_SoC/Periphs/UART_PHY"

# Dump all UART TX output to a file (everything the SoC sends over UART)
vpconfig.set_parameter_value_override(
    UART_PATH, "SCML_PROPERTIES", "/EN_UART_TX_LOG_TO_FILE", "/tmp/uart_tx.log"
)
# Flush on every newline (0 = flush at newline; >0 = flush at buffer size)
vpconfig.set_parameter_value_override(
    UART_PATH, "SCML_PROPERTIES", "/EN_UART_TX_LOG_FLUSH_ON_BUF_SIZE", "0"
)
# Open TCP socket for external clients to read raw UART TX (port 4000–65535)
vpconfig.set_parameter_value_override(
    UART_PATH, "SCML_PROPERTIES", "/ENABLE_TCP_ON_PORT", "4001"
)
# TCP poll period — 0 for best performance
vpconfig.set_parameter_value_override(
    UART_PATH, "SCML_PROPERTIES", "/TCP_POLL_US", "0"
)
# Suppress GUI terminal (not needed in headless mode)
vpconfig.set_parameter_value_override(
    UART_PATH, "SCML_PROPERTIES", "/TerminalAutoOpen", "false"
)
```

### Bundled Template: vssh_linux_test.py

`vssh_linux_test.py` (bundled with this skill) boots Mini_AArch64_Linux to a root shell, runs
a list of commands, and captures all UART output to a log file. Copy it to the workspace:

```zsh
cp ~/.claude/skills/vdk-tda54/vssh_linux_test.py \
    /home/jon/dev/tijsdk/ti-sdk/workspace/TDA_R8/tests/
```

Then run (from host, `tda54-build` wraps the container invocation):

```zsh
tda54-build vssh -d /work/ti-sdk/workspace \
    --vdk_test null,Mini_AArch64_Linux,/work/ti-sdk/workspace/TDA_R8/tests/vssh_linux_test.py \
    --pyout /work/ti-sdk/workspace/TDA_R8/bin/sim_python.log \
    --logfile /work/ti-sdk/workspace/TDA_R8/bin/sim_vs.log \
    --pyargs \
        --commands "uname -a" "cat /proc/cpuinfo | head -20" "ls /proc" \
        --uart_log /work/ti-sdk/workspace/TDA_R8/bin/uart_tx.log \
        --boot_timeout 600 \
    --pyargs_end
```

After the run:

- `bin/sim_python.log` — test script output (PASS/FAIL markers from `report()`/`report_error()`)
- `bin/uart_tx.log` — raw UART TX log (everything the SoC sent: prompts, command echoes, output)
- `bin/sim_vs.log` — Virtualizer system log

## Programmatic UART Access (vpprobes)

The Synopsys vpprobes gRPC Python client allows scripts running outside the container to
interact with the simulation's UART monitors directly — sending commands and detecting
output patterns — without needing a terminal window.

### Critical Sequencing

**Resume the simulation BEFORE calling `rpc.connect()`.**

`rpc.connect()` triggers `Init_IO_Monitors` → `load_monitors()` inside the sim thread via
gRPC. If the sim is paused at `initial_crunch`, this gRPC handshake blocks indefinitely.
Always send F8 (Resume) in VS GUI first, then connect.

### Always Use `is_proxy=False`

When constructing a `UartPhyVpProbe`:

```python
uart = UartPhyVpProbe(rpc, "/TDA5_System/TDA5_SoC/Periphs/UART_PHY", None, is_proxy=False)
```

`is_proxy=False` (the default) sends `add_inst` to the io_mon server, which creates the
server-side monitor instance on the sim thread. This is **always required**.

Do NOT use `is_proxy=True`: STARTUP scripts (`uart_phy_io_monitor.py`) only register monitor
*types*, never instances. If `is_proxy=True` is passed, the server looks up the instance in
`_mSimIOMonObjs` → fails with `ERROR/INTERNAL` → NodeInterface terminates immediately.

### Timeout Values

`wait_for_string` and `wait_for_string_and_send_response` take a `(value, unit)` tuple for
the simulation-time timeout. The sim timer fires an `ERROR/TIMEOUT` response after that many
simulation-seconds.

Linux boot on TDA54 takes many real-time minutes. The sim runs at roughly 4× real time during
early boot (ROM/MCU phase). A safe timeout that outlasts any real-time watchdog:

```python
BOOT_TIMEOUT  = (100000, "s")   # 100000 sim-sec ≈ 7h at 4× — never fires before real watchdog
SHELL_TIMEOUT = (10000, "s")    # 10000 sim-sec ≈ 42 min at 4× — well past ls completion
```

### Minimal vpprobes Example

```python
import sys
sys.path.insert(0, "/opt/synopsys/SLS/linux/python3/lib/python3.10/site-packages")
sys.path.insert(0, "<WS>/bin/simulation/script_lib/GENERIC_TLM2/script_lib/auto_client")

from vpprobes import NodeInterface

# Minimal runner that connects vpprobes to the io_mon gRPC server
class MockRunner:
    class _backend:
        _debuggers = {}
        class _api:
            @staticmethod
            def using_proxy(): return False
    def __init__(self, port): self._port = port
    def get_session_starter_key(self): return ""
    def get_node_names(self): return ["local"]
    def _get_simtoken_entry(self, node, key):
        return self._port if key == "SimRemoteServerPort" else None
    def in_breakpoint_callback(self): return False
    def _add_callback(self, cb): pass
    def _remove_callback(self, cb): pass
    def get_debugger(self, name): return None

# port: found by grepping simout.txt for "created command server connection on http://localhost:<N>"
runner = MockRunner(port)
rpc = NodeInterface(runner, "local")
rpc.connect()     # sim MUST be running (past initial_crunch) before this call

from uart_phy_vpprobe import UartPhyVpProbe
uart = UartPhyVpProbe(rpc, "/TDA5_System/TDA5_SoC/Periphs/UART_PHY", None, is_proxy=False)

BOOT_TIMEOUT  = (100000, "s")
SHELL_TIMEOUT = (10000, "s")

# Wait for shell prompt, then send a command
uart.wait_for_string_and_send_response("# ", "ls -al\n", BOOT_TIMEOUT)
# Wait for next prompt (ls output is printed before the prompt)
result = uart.wait_for_string("# ", SHELL_TIMEOUT)
# NOTE: result is {'return_value': None} — vpprobes signals prompt detection,
# it does NOT capture the text between the command and the prompt.

rpc.terminate()
```

### io_mon gRPC Port

Find it by grepping simout.txt after the sim starts:

```bash
grep -o 'localhost:[0-9]*' <WS>/bin/simout.txt | grep -o '[0-9]*$' | head -1
```

### "IO_MONITORS: loading monitors" in simout.txt

This message is printed when `rpc.connect()` calls `Init_IO_Monitors` → `load_monitors()`.
It appears in simout.txt ONLY when a vpprobes client connects — not during the STARTUP phase.
Scripts that grep for it before the client connects will always time out.

## FileIO (VirtIO VBD)

VirtIO virtual block device maps a host directory into the simulated system, giving firmware
access to host files at runtime. Configure in VPConfig → Parameters → VIRTIO_BLK.

## Common Workflows

### Run a bare-metal test on A720

1. Identify the vpconfig path: `<WS>/vpconfigs/Dhrystone_A720/Dhrystone_A720.vpcfg`
2. Launch simulation:
   ```zsh
   tda54-build vs --nointro -d /work/ti-sdk/workspace \
       -r <WS>/vpconfigs/Dhrystone_A720/Dhrystone_A720.vpcfg \
       --simout <WS>/bin/simout.txt
   ```
3. In VS: **VDK Debug → Resume Simulation** to clear the `initial_crunch` breakpoint
4. Monitor system log: `tail -f <WS>/bin/simout.txt`

### Boot TI SDK Linux and monitor console output

1. Launch simulation:
   ```zsh
   tda54-build vs --nointro -d /work/ti-sdk/workspace \
       -r <WS>/vpconfigs/tda54-vdk-linux/tda54-vdk-linux.vpcfg \
       --simout <WS>/bin/simout.txt
   ```
2. In VS toolbar, select **VDK Debug → Resume Simulation** to clear the `initial_crunch`
   breakpoint and start execution
3. Linux kernel and shell output appears in the **`TDA5_System.TDA5_SoC.Periphs.UART_PHY`**
   terminal window in VS GUI (not in simout.txt)

### Attach TRACE32 to debug M55 firmware

1. Open VPConfig → Debug tab to find the M55 debug interface port
2. Launch the simulation in VS GUI and let it run
3. Launch TRACE32 and connect to the VDK debug port for the target M55 core
4. Load symbols and set breakpoints using PRACTICE scripts

### Generate a boot_configure.py for specific cores

1. Copy `simprobe_boot_template.py` (bundled with this skill) to your vpconfig directory
2. Uncomment or add `bootcode_utils.configure_core_out_of_reset("CoreName", vector_addr)` calls
3. Set each reset vector address to the firmware entry point for that core
4. Add the script path to VPConfig → Scripting → Begin of Simulation

### Check which UARTs are active for a given vpconfig

1. Open the vpconfig in Virtualizer Studio
2. Navigate to VPConfig parameters for each `UART_PHY` instance of interest
3. Check `TerminalAutoOpen` setting — `true` means the terminal opens on simulation start
4. For programmatic monitoring, use `ENABLE_TCP_ON_PORT` (TCP) or `EN_UART_TX_LOG_TO_FILE` (file)

### Run headless commands in Mini_AArch64_Linux via vssh

1. Copy the bundled template to the workspace:
   ```zsh
   cp ~/.claude/skills/vdk-tda54/vssh_linux_test.py \
       /home/jon/dev/tijsdk/ti-sdk/workspace/TDA_R8/tests/
   ```
2. Run from the host (no DISPLAY needed):
   ```zsh
   tda54-build vssh -d /work/ti-sdk/workspace \
       --vdk_test null,Mini_AArch64_Linux,/work/ti-sdk/workspace/TDA_R8/tests/vssh_linux_test.py \
       --pyout /work/ti-sdk/workspace/TDA_R8/bin/sim_python.log \
       --logfile /work/ti-sdk/workspace/TDA_R8/bin/sim_vs.log \
       --pyargs \
           --commands "uname -a" "cat /proc/version" \
           --uart_log /work/ti-sdk/workspace/TDA_R8/bin/uart_tx.log \
           --boot_timeout 600 \
       --pyargs_end
   ```
3. Check results:
   - `bin/sim_python.log` — PASS/FAIL markers
   - `bin/uart_tx.log` — full UART output (prompts + command output)
