#!/bin/sh
# Передаём переменные окружения systemd-user (по желанию)
systemctl --user import-environment DISPLAY XAUTHORITY

# Запускаем CopyQ-демон под X
copyq --start-server &
# Запускаем i3
exec i3
