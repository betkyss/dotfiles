#!/bin/sh
export XCURSOR_SIZE=24
export XCURSOR_THEME=phinger-cursors-dark
# Передаём переменные окружения systemd-user (по желанию)
[ -f ~/.Xresources ] && xrdb -merge ~/.Xresources
systemctl --user import-environment DISPLAY XAUTHORITY XCURSOR_THEME XCURSOR_SIZE

# Запускаем CopyQ-демон под X
copyq --start-server &
# Запускаем i3
exec i3
