#!/usr/bin/env bash
# ~/.config/polybar/launch.sh
set -euo pipefail

export XCURSOR_THEME=phinger-cursors-dark
export XCURSOR_SIZE=24
# Kill polybar and orphaned plugin scripts from previous runs
pkill -x polybar || true
pkill -f 'polybar_' || true

# Wait until polybar processes are actually dead (up to 3s)
for _ in $(seq 1 30); do
  pgrep -x polybar >/dev/null || break
  sleep 0.1
done

# Force-kill anything that survived SIGTERM
pkill -9 -x polybar 2>/dev/null || true
pkill -9 -f 'polybar_' 2>/dev/null || true

# вычисляем ширину активного режима экрана, чтобы убрать по 10px слева и справа
if command -v xrandr >/dev/null; then
  if current_mode=$(xrandr | awk '/\*/ {print $1; exit}'); then
    if [[ $current_mode =~ ^([0-9]+)x ]]; then
      monitor_width=${BASH_REMATCH[1]}
      if (( monitor_width > 20 )); then
        export POLYBAR_WIDTH=$((monitor_width - 20))
      fi
    fi
  fi
fi

declare -a ordered=()
if command -v xrandr >/dev/null; then
  while IFS= read -r line; do
    ordered+=("$line")
  done < <(
    xrandr --listactivemonitors 2>/dev/null | awk 'NR > 1 {
      if (match($3, /\+([0-9]+)\+([0-9]+)/, pos)) {
        printf "%08d %s\n", pos[1], $4
      }
    }' | sort -n
  )
fi

start_bar() {
  local monitor="$1"
  local bar_name="$2"
  if [[ -n "${monitor}" ]]; then
    MONITOR="${monitor}" polybar "${bar_name}" >/tmp/polybar-"${bar_name}".log 2>&1 &
  else
    polybar "${bar_name}" >/tmp/polybar-"${bar_name}".log 2>&1 &
  fi
}

if ((${#ordered[@]} == 0)); then
  start_bar "${MONITOR:-}" left
  exit 0
fi

left_monitor="${ordered[0]##* }"
right_monitor=""
if ((${#ordered[@]} >= 2)); then
  right_monitor="${ordered[1]##* }"
fi

start_bar "${left_monitor}" left
if [[ -n "${right_monitor}" && "${right_monitor}" != "${left_monitor}" ]]; then
  start_bar "${right_monitor}" right
fi

exit 0
