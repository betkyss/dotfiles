# ~/.config/polybar/launch.sh
#!/usr/bin/env bash
pkill -x polybar
sleep 0.5
polybar example &
