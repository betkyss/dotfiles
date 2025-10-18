#!/usr/bin/env bash
# ~/.config/polybar/launch.sh
export XCURSOR_THEME=phinger-cursors-dark
export XCURSOR_SIZE=24
pkill -x polybar
sleep 0.5

# вычисляем ширину активного режима экрана, чтобы убрать по 10px слева и справа
if command -v xrandr >/dev/null; then
  current_mode=$(xrandr | awk '/\*/ {print $1; exit}')
  if [[ $current_mode =~ ^([0-9]+)x ]]; then
    monitor_width=${BASH_REMATCH[1]}
    if (( monitor_width > 20 )); then
      export POLYBAR_WIDTH=$((monitor_width - 20))
    fi
  fi
fi

polybar example &
