#!/bin/bash
set -euo pipefail

INTERFACE="arch-vpn"
SERVICE="wg-quick@${INTERFACE}.service"

SUDO="/usr/bin/sudo -n"

command_status=0

if /bin/systemctl is-active --quiet "$SERVICE"; then
    if ! $SUDO /bin/systemctl stop "$SERVICE"; then
        command_status=$?
    fi
else
    if ! $SUDO /bin/systemctl start "$SERVICE"; then
        command_status=$?
    fi
fi

exit $command_status
