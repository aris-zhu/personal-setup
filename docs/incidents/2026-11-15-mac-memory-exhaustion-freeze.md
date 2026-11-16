# 2026-11-15: Mac froze from memory exhaustion

*Source of truth for the fix: `~/personal-ws/heat-guard` (commit `79f2000`); see [Keeping the Mac responsive](../../coding-environment.md#keeping-the-mac-responsive--heat-guard).*

## What happened

At about 10:53 PST the Mac (M5 Pro, 24 GB RAM) stopped responding and was force-restarted. The
machine was back up at 10:55:17.

- No kernel panic or watchdog report exists (`/Library/Logs/DiagnosticReports` has neither a
  `.panic` nor a reset report). The unified log simply stops at 10:54:31 with no shutdown
  sequence. This was a hang followed by a forced power-off, not a crash.
- Disk was not the cause: 81 GB was free, so swap could still grow.

## Cause

Memory had been overcommitted for days. heat-guard had logged `memory-thrash` every day since
Nov 5, with 14–22 GB of swap in use. Its last snapshot before the freeze (08:45) listed:

| Group | Footprint |
|---|---|
| ~77 Claude Code processes | 23 GB |
| ~176 node processes (mostly per-session MCP servers) | 10.5 GB |
| iTerm | 9.9 GB |
| ~63 Playwright "Google Chrome for Testing" processes | 4.5 GB |
| Firefox | 4.3 GB |

That is about 52 GB of footprint on 24 GB of RAM, with swap at 20 of 21 GB.

## Timeline (PST)

| Time | Event |
|---|---|
| 10:47 | Zoom launched |
| 10:50 | Firefox opened about 16 new content processes |
| 10:51:12 | jetsam began idle-exiting background daemons once a second |
| 10:51:40 | Kernel memory pressure reached "warn" (WebKit clients logged pressure events) |
| 10:52 | Sessions started up in a burst: 85 `git` and 109 `security` process launches in one minute |
| 10:52:33 | duetexpertd received the memory pressure warning |
| 10:53 | WindowServer logging fell from about 17k lines/min to under 700: the UI had stalled |
| 10:53–10:54 | watchdogd's 30 s check-ins slipped (10:53:03, then 10:53:59) |
| 10:54:31 | Last log line |
| 10:55:17 | Boot |

The Nov 6 14:13 reboot came 26 minutes after a logged memory-thrash event at 13:47. Those logs
have rotated out, so the same cause there is likely but unconfirmed.

## Why heat-guard did not prevent it

- N-thrash only notifies. It had sent a notification about once an hour for days.
- K-mem only kills a test/dev tree whose own footprint exceeds RAM. No single tree came close.
- Agents are never touched, and agents plus their MCP servers were most of the load.

## What changed

- **K-pressure.** Each pass and each 10 s re-check reads `kern.memorystatus_vm_pressure_level`,
  `kern.memorystatus_level` and `vm.swapusage`:
  - **high** (swap ≥ 0.6 × RAM): kill orphaned Playwright/Puppeteer browser trees at least
    10 minutes old. Crashpad handlers are skipped.
  - **critical** (pressure ≥ warn, or ≤ 12% free): also kill the single largest test/dev tree
    (at least 200 MB) on each re-check until pressure clears. Notify with the top apps and the
    Claude process count, throttled to once every 10 minutes.
  - A tree is eligible only if every member is a known dev runtime, test tool, wrapper or dev
    browser. Agents, their ancestors, throttleExempt matches, user apps and the guard are never
    selected.
- **Memory gate.** The Claude Code hook blocks whole-suite test commands while the stage is high
  or critical. The stage is written to the load file as `memoryStage`.
- **Executable names from `ps -o comm=`.** argv0 is now read as one intact field instead of being
  guessed from the space-joined command line. The guess remains only as a fail-safe fallback: any
  plausible name that is an agent protects the process, and every plausible name must be a
  runtime before a process can be killed.
- **Existing rules hardened** (bugs found in review):
  - User apps are never classed as test/dev from argument text. Preview opening
    `.../pytest report.pdf` was a test before.
  - K-mem and orphan-shell kills notify instead of killing when the tree contains an agent, an
    agent's ancestor or a user app.
  - The kill path refuses to signal a process that has exec'd into an agent.
  - The gate no longer blocks `pytest --version`, `--help` and similar.
  - K-mem still kills a throttleExempt server that grows past the RAM limit, because a server that
    size is what freezes the Mac.

Review history: four independent GPT-6 Astra reviews found eight Critical issues and several
Important ones. All were fixed, with a regression test each (146 tests in the touched files).

## Still open

- heat-guard can shed only about 5 GB of dev load. The structural load is the number of
  concurrent sessions (about 0.7 GB each with their MCP servers) plus iTerm (about 10 GB). Closing
  idle sessions and restarting iTerm now and then matters more than any guard rule.
- At critical, the largest dev tree can be a live session's `playwright-mcp`. Killing it breaks
  that session's browser tool, which was accepted as better than a freeze.
- After a forced restart, macOS relaunches any Playwright browser that was open (PID 747 here, with
  no owner). K-pressure now removes it once swap is high.

## Diagnosing the next one

1. Check `/Library/Logs/DiagnosticReports` for `.panic` or `JetsamEvent-*.ips`. With neither, it
   was a hang.
2. Run `tail ~/Library/Logs/heat-guard.log` and look for `memory-thrash` or `pressure` events.
3. Search `/usr/bin/log show --start <last 20 min> --style compact` for `JETSAM_REASON` and
   `memory pressure`, and count WindowServer lines per minute to find when the UI stalled.
