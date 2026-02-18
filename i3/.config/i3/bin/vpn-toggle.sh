#!/bin/bash
set -euo pipefail

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/i3/vpn-toggle.conf"

VPN_TYPE="wg" # wg or xray
WG_INTERFACE="arch-vpn"
XRAY_PROFILE=""
XRAY_SERVER_IP=""
XRAY_TUN_IFACE="xray0"
WAN_IFACE="wlp2s0"
WAN_GW="192.168.1.1"

if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  . "$CONFIG_FILE"
else
  echo "Config file not found: $CONFIG_FILE" >&2
  echo "Create it with at least: XRAY_PROFILE and XRAY_SERVER_IP" >&2
  exit 1
fi

if [[ "$VPN_TYPE" == "xray" ]]; then
  if [[ -z "$XRAY_PROFILE" ]]; then
    echo "XRAY_PROFILE is not set. Define it in $CONFIG_FILE" >&2
    exit 1
  fi
  if [[ -z "$XRAY_SERVER_IP" ]]; then
    echo "XRAY_SERVER_IP is not set. Define it in $CONFIG_FILE" >&2
    exit 1
  fi
fi

case "$VPN_TYPE" in
  wg)
    SERVICE="wg-quick@${WG_INTERFACE}.service"
    ;;
  xray)
    SERVICE="xray@${XRAY_PROFILE}.service"
    ;;
  *)
    echo "Unknown VPN_TYPE: $VPN_TYPE" >&2
    exit 1
    ;;
esac

SUDO="/usr/bin/sudo -n"
IP_BIN="/usr/bin/ip"

command_status=0

route_prepare() {
  if ! $SUDO "$IP_BIN" route replace "${XRAY_SERVER_IP}/32" via "$WAN_GW" dev "$WAN_IFACE"; then
    command_status=$?
  fi
}

route_enable() {
  local tries=20
  while (( tries > 0 )); do
    if "$IP_BIN" link show dev "$XRAY_TUN_IFACE" >/dev/null 2>&1; then
      break
    fi
    tries=$((tries - 1))
    sleep 0.1
  done
  if ! "$IP_BIN" link show dev "$XRAY_TUN_IFACE" >/dev/null 2>&1; then
    echo "TUN interface not found: $XRAY_TUN_IFACE" >&2
    command_status=1
    return
  fi
  if ! $SUDO "$IP_BIN" route replace default dev "$XRAY_TUN_IFACE"; then
    command_status=$?
  fi
}

route_down() {
  if ! $SUDO "$IP_BIN" route replace default via "$WAN_GW" dev "$WAN_IFACE"; then
    command_status=$?
  fi
  if ! $SUDO "$IP_BIN" route del "${XRAY_SERVER_IP}/32" via "$WAN_GW" dev "$WAN_IFACE"; then
    true
  fi
}

if /bin/systemctl is-active --quiet "$SERVICE"; then
    if [[ "$VPN_TYPE" == "xray" ]]; then
        route_down
    fi
    if ! $SUDO /bin/systemctl stop "$SERVICE"; then
        command_status=$?
    fi
else
    if [[ "$VPN_TYPE" == "xray" ]]; then
        route_prepare
    fi
    if ! $SUDO /bin/systemctl start "$SERVICE"; then
        command_status=$?
    fi
    if [[ "$VPN_TYPE" == "xray" ]]; then
        route_enable
    fi
fi

exit $command_status
