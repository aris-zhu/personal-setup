#!/bin/bash
# Colors the iTerm2 tab to signal Claude Code session state.
#   flash  - slow fade in/out in light pink: Claude is waiting on you
#   done   - solid matcha green: Claude finished its turn
#   clear  - reset to the terminal default
#
# Hooks have their stdout captured by Claude Code, so escape sequences must be
# written to the session's tty device rather than to stdout.

set -u

# Fade runs between a dim base and full pink. The base is a dark neutral so the
# pulse reads as a glow rather than a blink against a dark theme.
BASE_R=38;   BASE_G=40;   BASE_B=44
PINK_R=255;  PINK_G=182;  PINK_B=193

MATCHA_R=180; MATCHA_G=214; MATCHA_B=158

STEPS=28        # frames per half-cycle
FRAME=0.055     # seconds per frame -> ~1.5s in, ~1.5s out
MAX_MINUTES=30  # stop pulsing eventually if nobody comes back

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

# Blend base -> pink at position $1, given as permille (0..1000), eased with a
# smoothstep so the pulse lingers at the extremes instead of ramping linearly.
fade_to() {
  local x=$1 s r g b
  s=$(( (3 * x * x) / 1000 - (2 * x * x * x) / 1000000 ))
  r=$(( BASE_R + ((PINK_R - BASE_R) * s) / 1000 ))
  g=$(( BASE_G + ((PINK_G - BASE_G) * s) / 1000 ))
  b=$(( BASE_B + ((PINK_B - BASE_B) * s) / 1000 ))
  set_color "$r" "$g" "$b"
}

stop_flasher() {
  if [ -f "$PIDFILE" ]; then
    kill "$(cat "$PIDFILE")" 2>/dev/null
    rm -f "$PIDFILE"
  fi
}

case "${1:-}" in
  flash)
    stop_flasher
    (
      trap 'reset_color; exit 0' TERM INT
      cycle_secs=$(echo "2 * $STEPS * $FRAME" | bc)
      cycles=$(echo "$MAX_MINUTES * 60 / $cycle_secs" | bc)
      for _ in $(seq 1 "$cycles"); do
        [ -w "$TTY" ] || break
        for i in $(seq 0 "$STEPS"); do          # fade in
          fade_to $(( i * 1000 / STEPS ))
          sleep "$FRAME"
        done
        for i in $(seq "$STEPS" -1 0); do       # fade out
          fade_to $(( i * 1000 / STEPS ))
          sleep "$FRAME"
        done
      done
      reset_color
      rm -f "$PIDFILE"
    ) &
    echo $! > "$PIDFILE"
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
