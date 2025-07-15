#!/bin/sh

# Устанавливаем параметры для тачпада
# xinput set-prop 9 "Synaptics Scrolling Distance" -300 -30

# Завершаем предыдущие запущенные экземпляры polybar
pkill polybar

greenclip daemon &

# Запускаем polybar
polybar example &

# Запускаем i3
exec i3
