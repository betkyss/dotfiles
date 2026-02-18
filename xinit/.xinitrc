#!/bin/sh
export XDG_SESSION_TYPE=x11
export XCURSOR_SIZE=24
export XCURSOR_THEME=phinger-cursors-dark
# Передаём переменные окружения systemd-user (по желанию)
[ -f ~/.Xresources ] && xrdb -merge ~/.Xresources
systemctl --user import-environment DISPLAY XAUTHORITY XCURSOR_THEME XCURSOR_SIZE

# Запускаем CopyQ-демон под X
copyq --start-server &
# Запускаем i3
# exec startxfce4
exec i3
