#!/usr/bin/env bash
set -euo pipefail

# Usage: wallpaper-slideshow.sh [DIR] [INTERVAL_SECONDS] [MODE]
# Defaults: DIR="$HOME/Media/Images/Wallpapers", INTERVAL=900, MODE=fill
# Example: wallpaper-slideshow.sh ~/Media/Images/Wallpapers 300 fill

DIR="${1:-$HOME/Media/Images/Wallpapers}"
INTERVAL="${2:-900}"
MODE="${3:-fill}"

if ! command -v feh >/dev/null 2>&1; then
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "i3 wallpaper" "feh is not installed"
  fi
  echo "[wallpaper-slideshow] feh is not installed" >&2
  exit 1
fi

case "$MODE" in
  fill)   BGFLAG="--bg-fill" ;;
  scale)  BGFLAG="--bg-scale" ;;
  max)    BGFLAG="--bg-max" ;;
  center) BGFLAG="--bg-center" ;;
  tile)   BGFLAG="--bg-tile" ;;
  *)      BGFLAG="--bg-fill" ;;
esac

# Single-instance guard (fast reload-safe)
LOCKDIR="${XDG_RUNTIME_DIR:-/tmp}"
LOCKFILE="$LOCKDIR/i3-wallpaper-slideshow.lock"
if command -v flock >/dev/null 2>&1; then
  exec 9>"$LOCKFILE" || true
  if ! flock -n 9; then
    exit 0
  fi
fi

# Sanity checks
if [ ! -d "$DIR" ]; then
  [ -t 1 ] && echo "[wallpaper-slideshow] directory not found: $DIR" >&2
  exit 1
fi

IMG_COUNT=$(find "$DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.bmp" \) | wc -l | tr -d ' ')
if [ "${IMG_COUNT:-0}" -lt 1 ]; then
  [ -t 1 ] && echo "[wallpaper-slideshow] no images found in $DIR" >&2
  exit 1
fi

if [ -t 1 ]; then
  echo "[wallpaper-slideshow] dir='$DIR' interval='${INTERVAL}s' mode='$MODE'"
fi

# Initial set
feh --no-fehbg "$BGFLAG" --randomize --recursive "$DIR" || true

# Loop
while sleep "$INTERVAL"; do
  feh --no-fehbg "$BGFLAG" --randomize --recursive "$DIR" || true
done

