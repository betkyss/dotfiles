#!/usr/bin/env bash

source "$(dirname "$0")"/config.sh

HISTORY_FILE="$HOME/.config/rofi/launchers/calc_history.txt"
THEME="$HOME/.config/rofi/launchers/${LAUNCHER_TYPE}/${LAUNCHER_STYLE}.rasi"

# Бесконечный цикл для постоянной работы калькулятора
while true; do
    # Показываем историю (в обратном порядке) и поле для ввода в одном окне
    input=$( (tac "$HISTORY_FILE" 2>/dev/null) | rofi \
        -dmenu \
        -p "Calc >" \
        -theme "$THEME")

    # Если пользователь нажал Esc или оставил поле пустым, выходим
    if [[ -z "$input" ]]; then
        exit 0
    fi

    # Проверяем, является ли ввод существующей записью в истории
    if grep -qFx "$input" "$HISTORY_FILE"; then
        # Это запись из истории. Извлекаем результат (все после " = ")
        result_to_copy=$(echo "$input" | sed 's/.* = //')
        
        # Молча копируем в буфер обмена
        echo -n "$result_to_copy" | xclip -selection clipboard
        
        # Сразу выходим
        exit 0
    else
        # Это новое выражение. Вычисляем его.
        result=$(qalc -t "$input")

        # Проверяем, что вычисление прошло успешно
        if [[ -n "$result" && ! "$result" =~ "error" ]]; then
            # Формируем запись для истории
            history_entry="$input = $result"
            # Добавляем ее в файл истории
            echo "$history_entry" >> "$HISTORY_FILE"
            # Цикл начнется заново, и rofi откроется с обновленной историей
        else
            # Если qalc вернул ошибку, показываем ее
            rofi -e "Ошибка: Неверное выражение" -theme "$THEME"
            # После закрытия окна с ошибкой цикл также начнется заново
        fi
    fi
done
