#!/bin/sh
set -eu

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo "Usage: $0 {both|us|ru} [xkb_options]" >&2
  exit 1
fi

layout="$1"
options="${2:-grp:alt_shift_toggle,grp_led:scroll}"

case "$layout" in
  both)
    exec setxkbmap -layout us,ru -option "$options"
    ;;
  us|ru)
    exec setxkbmap -layout "$layout" -option "$options"
    ;;
  *)
    echo "Usage: $0 {both|us|ru} [xkb_options]" >&2
    exit 1
    ;;
esac
