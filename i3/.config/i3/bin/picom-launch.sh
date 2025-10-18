#!/usr/bin/env bash
set -euo pipefail

# Robust picom launcher for i3
# - Kills any existing instance
# - Tries GLX backend first (matches config)
# - Falls back to Xrender without blur if GLX fails

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/picom/picom.conf"
LOGDIR="${XDG_CACHE_HOME:-$HOME/.cache}"
LOGFILE="$LOGDIR/picom.log"

mkdir -p "$LOGDIR"

# Stop any running instance gracefully
pkill -x picom 2>/dev/null || true
for _ in {1..20}; do
  pgrep -x picom >/dev/null || break
  sleep 0.1
done

# Try GLX first (preferred for dual_kawase & animations)
if picom \
  --config "$CONFIG" \
  --backend glx \
  --log-level warn \
  --log-file "$LOGFILE" \
  --daemon; then
  exit 0
fi

# Fallback: Xrender without blur for maximum compatibility
picom \
  --config "$CONFIG" \
  --backend xrender \
  --blur-method none \
  --log-level warn \
  --log-file "$LOGFILE" \
  --daemon

