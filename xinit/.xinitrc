#!/bin/sh

# sxhkd &
# exec bspwm &

# Завершаем все предыдущие запущенные компоненты
# pkill xfce4-session
# Запускаем xfce
# exec startxfce4
# exec dwm 
exec i3 & 
exec polybar
# exec polybar --config ~/.config/polybar/config
