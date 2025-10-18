#!/usr/bin/env bash

THEME="$HOME/.config/rofi/config/wifi.rasi"
PROMPT="Wi-Fi"
LOG_FILE="$HOME/.config/rofi/launchers/.wifi_menu_debug"

log_msg() {
  local message=$1
  printf '%s | %s\n' "$(date '+%F %T')" "$message" >>"$LOG_FILE"
}

show_popup() {
  local message=$1
  if ! rofi -theme "$THEME" -e "$message" >/dev/null; then
    if command -v notify-send >/dev/null 2>&1; then
      notify-send "Wi-Fi" "$message"
    fi
  fi
}

error_popup() {
  local message=$1
  log_msg "ERROR: $message"
  show_popup "$message"
}

info_popup() {
  local message=$1
  log_msg "INFO: $message"
  show_popup "$message"
}

if ! command -v nmcli >/dev/null 2>&1; then
  error_popup "Команда nmcli не найдена"
  exit 1
fi

if [[ $(nmcli radio wifi 2>/dev/null) == "disabled" ]]; then
  error_popup "Wi-Fi выключен (nmcli radio wifi on)"
  exit 1
fi

wifi_scan() {
  nmcli --terse --fields ACTIVE,SSID,SIGNAL,SECURITY device wifi list 2>/dev/null
}

mapfile -t wifi_raw < <(wifi_scan)

if [[ ${#wifi_raw[@]} -eq 0 ]]; then
  nmcli dev wifi rescan >/dev/null 2>&1
  sleep 1
  mapfile -t wifi_raw < <(wifi_scan)
fi

if [[ ${#wifi_raw[@]} -eq 0 ]]; then
  error_popup "Сети не найдены"
  exit 1
fi

format_line() {
  local active="$1" ssid="$2" signal="$3" security="$4"

  [[ -z "$ssid" ]] && ssid="(скрытая сеть)"
  [[ -z "$signal" || "$signal" == "--" ]] && signal="0"
  [[ -z "$security" || "$security" == "--" ]] && security="Открытая"

  local status=""
  [[ "$active" == "yes" ]] && status="  [подключено]"

  printf '%s  [%s%%]  %s%s' "$ssid" "$signal" "$security" "$status"
}

separator=':'
options_active=()
raw_active=()
options_other=()
raw_other=()

for line in "${wifi_raw[@]}"; do
  IFS="$separator" read -r active ssid signal security <<<"$line"
  formatted="$(format_line "$active" "$ssid" "$signal" "$security")"
  if [[ "$active" == "yes" ]]; then
    options_active+=("$formatted")
    raw_active+=("$line")
  else
    options_other+=("$formatted")
    raw_other+=("$line")
  fi
done

if [[ ${#options_active[@]} -gt 0 ]]; then
  options=("${options_active[@]}" "${options_other[@]}")
  ordered_raw=("${raw_active[@]}" "${raw_other[@]}")
  selected_row=0
else
  options=("${options_other[@]}")
  ordered_raw=("${raw_other[@]}")
  selected_row=0
fi

selection=$(printf '%s\n' "${options[@]}" | rofi -dmenu -theme "$THEME" -p "$PROMPT" -selected-row "$selected_row" -format i)
exit_code=$?

if [[ $exit_code -ne 0 || -z "$selection" || "$selection" == "-1" ]]; then
  exit 0
fi

choice_line="${ordered_raw[$selection]}"
IFS="$separator" read -r active ssid signal security <<<"$choice_line"

if [[ "$active" == "yes" ]]; then
  info_popup "Уже подключено к '$ssid'"
  exit 0
fi

connect_cmd=(nmcli dev wifi connect "$ssid")

if [[ -n "$security" && "$security" != "--" && "$security" != "Открытая" ]]; then
  password=$(rofi -dmenu -theme "$THEME" -p "Пароль $ssid" -password)

  if [[ -z "$password" ]]; then
    exit 0
  fi

  connect_cmd+=(password "$password")
  log_msg "Connecting to '$ssid' with provided password"
else
  log_msg "Connecting to open network '$ssid'"
fi

if output="$(${connect_cmd[@]} 2>&1)"; then
  log_msg "SUCCESS: $output"
  info_popup "Подключено к '$ssid'"
  exec "$0"
else
  log_msg "FAIL: $output"
  error_popup "Ошибка: $output"
fi
