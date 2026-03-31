"""
VDK Linux Headless Test Script — vssh --vdk_test compatible

Boots the TDA54 Mini_AArch64_Linux VP config to a root shell, runs a list of
shell commands, and logs all UART TX output (everything the SoC sends) to a
file for post-run inspection.

Usage — pass these after --pyargs in the vssh invocation:

    --commands <cmd> [<cmd> ...]   Shell commands to run inside the Linux guest
    --boot_timeout <sec>           Wall-clock seconds to wait for login (default: 600)
    --cmd_timeout <sec>            Wall-clock seconds per command (default: 120)
    --uart_log <path>              UART TX log file path (default: /tmp/vdk_uart_tx.log)
    --login_prompt <str>           Login prompt string (default: "mini-aarch64 login:")
    --shell_prompt <str>           Shell prompt string (default: "# ")
    --stop_on_fail                 Stop simulation immediately on first command timeout

Example vssh invocation (run via tda54-build inside the container):

    VPCFG=/work/ti-sdk/workspace/TDA_R8/vpconfigs/Mini_AArch64_Linux/Mini_AArch64_Linux.vpcfg
    SCRIPT=/work/ti-sdk/workspace/TDA_R8/tests/vssh_linux_test.py
    tda54-build vssh -d /work/ti-sdk/workspace \\
        --vdk_test "null,${VPCFG},${SCRIPT}" \\
        --pyout /work/ti-sdk/workspace/TDA_R8/bin/sim_python.log \\
        --logfile /work/ti-sdk/workspace/TDA_R8/bin/sim_vs.log \\
        --pyargs \\
            vssh_linux_test.py \\
            --commands "uname -a" "cat /proc/cpuinfo | head -20" "ls /proc" \\
            --uart_log /work/ti-sdk/workspace/TDA_R8/bin/uart_tx.log \\
            --boot_timeout 600 \\
        --pyargs_end

IMPORTANT: vssh puts --pyargs tokens verbatim into sys.argv with no script name prepended.
The first --pyargs token (vssh_linux_test.py above) is sys.argv[0]; parse_args() reads from
sys.argv[1:]. Omitting this causes parse_args() to consume the first flag as the program name.

The vpconfig must be an absolute path when using null as the project; bare name lookup only
works when a real project directory name is given as the --vdk_test first field.

The --pyout log shows PASS/FAIL markers from report()/report_error().
The --uart_log file captures all raw UART TX bytes (everything the SoC sent).

UART_PHY path: /TDA5_System/TDA5_SoC/Periphs/UART_PHY
  Configured via before_test_run() vpconfig overrides:
    EN_UART_TX_LOG_TO_FILE   — path to write raw UART TX log
    EN_UART_TX_LOG_FLUSH_ON_BUF_SIZE = 0  — flush on every newline
    TerminalAutoOpen = false — suppress GUI terminal in headless mode
"""

import vdk_test_infra
import argparse
import os
import sys

# Default UART_PHY component path for Mini_AArch64_Linux (A720 main console)
UART_PATH = "/TDA5_System/TDA5_SoC/Periphs/UART_PHY"


class Uart:
    """
    Minimal UART_PHY interaction utility for vssh test scripts.

    Wraps vpx.get_node(path).send_command() to push text into UART RX
    and wait for patterns in UART TX using VDK breakpoints.
    """

    def __init__(self, path):
        self.uart = vpx.get_node(path)

    def push(self, msg):
        """Inject text into UART RX (host → SoC), appending CR+LF."""
        return self.uart.send_command('push "%s\r\n"' % msg)

    def send_command(self, cmd):
        """Send a raw SCML command to the UART_PHY model."""
        return self.uart.send_command(cmd)

    def run_to_match(self, match_string, pre_cmd=None, timeout_wall_sec=120):
        """
        Continue simulation and wait for match_string to appear in UART TX.

        Optionally pushes pre_cmd into UART RX before continuing.
        Returns True if the match was hit before the wall-clock timeout.
        The timeout is real wall-clock seconds (not simulation time).
        """
        assert vpx.is_interrupted(), "Simulation must be interrupted before run_to_match"

        event = self.send_command('add_match_event "%s"' % match_string)
        bp = vpx.create_breakpoint("at_notify", event)

        if pre_cmd is not None:
            self.push(pre_cmd)

        vpx.continue_simulation()

        success = False
        try:
            vpx.wait_interrupted(timeout_wall_sec)
            if bp.is_hit():
                success = True
        except Exception:
            vpx.interrupt()

        bp.remove()
        self.send_command('remove_match_event "%s"' % match_string)
        return success


class VdkLinuxTest(vdk_test_infra.VDKTestBase):
    """
    VDKTestBase subclass: boots Mini_AArch64_Linux and runs shell commands.

    Lifecycle called by vdk_test_infra:
      before_test_run(vpconfig) → test_run() → after_test_run(vpconfig)
    """

    def before_test_run(self, vpconfig):
        """Parse args and configure UART_PHY SCML parameters."""
        parser = argparse.ArgumentParser(
            description="VDK Linux headless test — run commands in sim"
        )
        parser.add_argument(
            "--commands", nargs="+", default=[],
            help="Shell commands to run in the Linux guest (space-separated list)"
        )
        parser.add_argument(
            "--boot_timeout", type=int, default=600,
            help="Wall-clock seconds to wait for the login prompt (default: 600)"
        )
        parser.add_argument(
            "--cmd_timeout", type=int, default=120,
            help="Wall-clock seconds per command (default: 120)"
        )
        parser.add_argument(
            "--uart_log", default="/tmp/vdk_uart_tx.log",
            help="Path for UART TX log file (default: /tmp/vdk_uart_tx.log)"
        )
        parser.add_argument(
            "--login_prompt", default="mini-aarch64 login:",
            help="String that signals the login prompt (default: 'mini-aarch64 login:')"
        )
        parser.add_argument(
            "--shell_prompt", default="# ",
            help="Shell prompt string to match after each command (default: '# ')"
        )
        parser.add_argument(
            "--stop_on_fail", action="store_true",
            help="Stop simulation immediately on first command timeout"
        )
        args = parser.parse_args()

        self.commands = args.commands
        self.boot_timeout = args.boot_timeout
        self.cmd_timeout = args.cmd_timeout
        self.uart_log = args.uart_log
        self.login_prompt = args.login_prompt
        self.shell_prompt = args.shell_prompt
        self.stop_on_fail = args.stop_on_fail

        # Dump all UART TX bytes (SoC→host) to a file for post-run inspection.
        # EN_UART_TX_LOG_TO_FILE captures raw terminal output including prompts,
        # command echoes, and command output — everything the SoC sent over UART.
        vpconfig.set_parameter_value_override(
            UART_PATH, "SCML_PROPERTIES", "/EN_UART_TX_LOG_TO_FILE", self.uart_log
        )
        # Flush on every newline (EN_UART_TX_LOG_FLUSH_ON_BUF_SIZE = 0).
        vpconfig.set_parameter_value_override(
            UART_PATH, "SCML_PROPERTIES", "/EN_UART_TX_LOG_FLUSH_ON_BUF_SIZE", "0"
        )
        # Suppress the GUI terminal window — unnecessary in headless mode.
        vpconfig.set_parameter_value_override(
            UART_PATH, "SCML_PROPERTIES", "/TerminalAutoOpen", "false"
        )

        self.report(f"UART TX log path: {self.uart_log}")
        self.report(f"Commands to run: {self.commands}")
        self.report(f"Boot timeout: {self.boot_timeout}s, command timeout: {self.cmd_timeout}s")

    def test_run(self):
        """Boot Linux, log in as root, run all commands, stop simulation."""
        uart = Uart(UART_PATH)

        # --- Wait for login prompt ---
        self.report(f"Waiting for login prompt: '{self.login_prompt}' "
                    f"(timeout={self.boot_timeout}s)...")
        if not uart.run_to_match(self.login_prompt, timeout_wall_sec=self.boot_timeout):
            self.report_error("FAIL: timed out waiting for login prompt")
            self._stop()
            return
        self.report("Reached login prompt")

        # --- Log in as root ---
        if not uart.run_to_match(self.shell_prompt, pre_cmd="root", timeout_wall_sec=30):
            self.report_error("FAIL: root login timed out")
            self._stop()
            return
        self.report("Logged in as root")

        # --- Run commands ---
        failed = False
        for i, cmd in enumerate(self.commands):
            self.report(f"[{i + 1}/{len(self.commands)}] $ {cmd}")
            if not uart.run_to_match(self.shell_prompt, pre_cmd=cmd,
                                     timeout_wall_sec=self.cmd_timeout):
                self.report_error(f"FAIL: command timed out: {cmd}")
                failed = True
                if self.stop_on_fail:
                    self._stop()
                    return

        if failed:
            self.report_error(f"FAIL: one or more commands timed out. "
                              f"UART log: {self.uart_log}")
        else:
            self.report(f"PASS: all {len(self.commands)} command(s) completed. "
                        f"UART log: {self.uart_log}")

        self._stop()

    def after_test_run(self, vpconfig):
        self.report("Test run complete.")

    def _stop(self):
        """Stop or kill the simulation cleanly."""
        try:
            vpx.stop_simulation()
        except Exception:
            vpx.kill_simulation()
