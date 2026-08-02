#!/bin/bash
# Colors the iTerm2 tab to signal Claude Code session state.
#   flash  - solid light pink: Claude is waiting on you
#   done   - solid matcha green: Claude finished its turn
#   clear  - reset to the terminal default
#
# Hooks have their stdout captured by Claude Code, so escape sequences must be
# written to the session's tty device rather than to stdout.
#
# The colors are set statically (no animation): iTerm treats every OSC 6 tab
# color sequence as a session-profile mutation, so animating at even a modest
# frame rate pegs its main thread.

set -u

PINK_R=255;  PINK_G=182;  PINK_B=193

MATCHA_R=180; MATCHA_G=214; MATCHA_B=158

resolve_tty() {
  local pid=$$ t parent
  while [ "$pid" -gt 1 ]; do
    t=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')
    if [ -n "$t" ] && [ "$t" != "??" ]; then
      echo "/dev/$t"
      return 0
    fi
    parent=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
    [ -z "$parent" ] && break
    pid=$parent
  done
  return 1
}

TTY=$(resolve_tty) || exit 0
[ -w "$TTY" ] || exit 0

PIDFILE="/tmp/claude-tabcolor-$(basename "$TTY").pid"

set_color() {
  printf '\033]6;1;bg;red;brightness;%s\a\033]6;1;bg;green;brightness;%s\a\033]6;1;bg;blue;brightness;%s\a' \
    "$1" "$2" "$3" > "$TTY" 2>/dev/null
}

reset_color() {
  printf '\033]6;1;bg;*;default\a' > "$TTY" 2>/dev/null
}

# Kills any leftover fade loop from the old animated version of this script.
stop_flasher() {
  if [ -f "$PIDFILE" ]; then
    kill "$(cat "$PIDFILE")" 2>/dev/null
    rm -f "$PIDFILE"
  fi
}

case "${1:-}" in
  flash)
    stop_flasher
    set_color "$PINK_R" "$PINK_G" "$PINK_B"
    ;;
  done)
    stop_flasher
    set_color "$MATCHA_R" "$MATCHA_G" "$MATCHA_B"
    ;;
  clear)
    stop_flasher
    reset_color
    ;;
esac

exit 0
