#!/bin/bash

set -euo pipefail

BOT_CHAR=""
PLAYER_CHAR=""
# Инициализация игрового поля - массив из 9 пустых строк.
BOARD=()
for ((i = 0; i < 9; i++)); do
  BOARD+=(" ")
done

# Проверка аргументов на корректность.
# Функция проверяет, что передан ровно один аргумент - либо -x, либо -o.
check_args() {
  if (( $# != 1 )) || [[ "$1" != "-x" && "$1" != "-o" ]]; then
    echo "Использование: $0 [-x|-o]"
    echo "-x: играть за крестики. -o: играть за нолики."
    exit 1
  fi
}

# Назначение символов для игрока и бота.
set_chars() {
  if [[ "$1" == "-o" ]]; then
    BOT_CHAR="X"
    PLAYER_CHAR="O"
  else
    BOT_CHAR="O"
    PLAYER_CHAR="X"
  fi
}

# Отрисовка игрового поля.
# Функция отрисует текущее состояние, а также покажет номера клеток для ходов.
draw_board() {
  clear
  echo "-------------"
  echo "| ${BOARD[0]} | ${BOARD[1]} | ${BOARD[2]} |"
  echo "|---|---|---|"
  echo "| ${BOARD[3]} | ${BOARD[4]} | ${BOARD[5]} |"
  echo "|---|---|---|"
  echo "| ${BOARD[6]} | ${BOARD[7]} | ${BOARD[8]} |"
  echo "-------------"
  echo ""
  echo "Позиции клеток:"
  echo "-------------"
  echo "| 1 | 2 | 3 |"
  echo "|---|---|---|"
  echo "| 4 | 5 | 6 |"
  echo "|---|---|---|"
  echo "| 7 | 8 | 9 |"
  echo "-------------"
  echo ""
  echo "Вы играете за: $PLAYER_CHAR"
  echo "Бот играет за: $BOT_CHAR"
  echo ""
}

# Проверка наличия победной комбинации для заданного символа.
check_win() {
  local char="$1"
  local win_combinations=("0 1 2" "3 4 5" "6 7 8" "0 3 6" "1 4 7" "2 5 8" "0 4 8" "2 4 6")  # Победные комбинации - последовательности индексов клеток

  for combination in "${win_combinations[@]}"; do
    read -r a b c <<< "$combination"
    if [[ "${BOARD[$a]}" == "$char" ]] &&
       [[ "${BOARD[$b]}" == "$char" ]] &&
       [[ "${BOARD[$c]}" == "$char" ]]; then
      return 0
    fi
  done
  return 1
}

# Проверка ничьи.
# Предполагается, что эта функция вызывается после check_win.
# Проверяет, заполнено ли все поле.
check_draw() {
  for cell in "${BOARD[@]}"; do
    if [[ "$cell" == " " ]]; then
      return 1
    fi
  done
  return 0
}

# Ход игрока.
# Запрашивает ввод, пока не будет введен корректный ход.
# Корректным считается ввод числа от 1 до 9, соответствующего пустой клетке.
human_move() {
  local move
  while true; do
    read -rp "Ваш ход (введите номер клетки 1-9): " move

    if ! [[ "$move" =~ ^[1-9]$ ]]; then
      echo "Введите число от 1 до 9"
      continue
    fi

    local pos=$((move - 1))
    if [[ "${BOARD[$pos]}" != " " ]]; then
      echo "Эта клетка уже занята"
      continue
    fi

    BOARD[$pos]="$PLAYER_CHAR"
    break
  done
}

# Ход бота.
# Алгоритм:
# 1) Проверить, может ли бот выиграть в этот ход. Если да, сделать ход.
# 2) Проверить, может ли игрок выиграть в следующий ход. Если да, то заблокировать победу игрока.
# 3) Занять центр, если он свободен.
# 4) Пытаться занять углы (случайный из свободных).
# 5) Занять любую свободную клетку.
computer_move() {
  local move

  move=$(find_winning_move "$BOT_CHAR")
  if (( move >= 0 )); then
    BOARD[$move]="$BOT_CHAR"
    return
  fi

  move=$(find_winning_move "$PLAYER_CHAR")
  if (( move >= 0 )); then
    BOARD[$move]="$BOT_CHAR"
    return
  fi

  if [[ "${BOARD[4]}" == " " ]]; then
    BOARD[4]="$BOT_CHAR"
    return
  fi

  local corners=(0 2 6 8)
  local shuf_corners
  mapfile -t shuf_corners < <(shuf -e "${corners[@]}")
  for corner in "${shuf_corners[@]}"; do
    if [[ "${BOARD[$corner]}" == " " ]]; then
      BOARD[$corner]="$BOT_CHAR"
      return
    fi
  done

  for ((i = 0; i < ${#BOARD[@]}; i++)); do
    if [[ "${BOARD[$i]}" == " " ]]; then
      BOARD[$i]="$BOT_CHAR"
      return
    fi
  done
}

# Поиск выигрышного хода для заданного символа.
# Если такой ход существует, возвращает индекс клетки. Иначе возвращает -1.
find_winning_move() {
  local char="$1"

  for ((i = 0; i < ${#BOARD[@]}; i++)); do
    if [[ "${BOARD[$i]}" == " " ]]; then
      BOARD[$i]="$char"

      if check_win "$char"; then
        BOARD[$i]=" "
        echo "$i"
        return
      fi

      BOARD[$i]=" "
    fi
  done

  echo "-1"
}

# Проверка состояния игры после хода.
# Проверяет, есть ли победитель или ничья, и выводит соответствующее сообщение.
check_game_state() {
  local char="$1"
  local win_message="$2"

  if check_win "$char"; then
    draw_board
    echo "$win_message"
    exit 0
  fi

  if check_draw; then
    draw_board
    echo "Ничья!"
    exit 0
  fi
}

# Основной игровой цикл.
# Чередует ходы игрока и бота, проверяет состояние игры после каждого хода.
# Крестики ходят первыми.
play() {
  local current_player
  if [[ "$BOT_CHAR" == "X" ]]; then
    current_player="computer"
  else
    current_player="human"
  fi

  while true; do
    draw_board

    if [[ "$current_player" == "human" ]]; then
      human_move
      check_game_state "$PLAYER_CHAR" "Вы победили!"
      current_player="computer"
    else
      computer_move
      check_game_state "$BOT_CHAR" "Бот победил!"
      current_player="human"
    fi
  done
}

check_args "$@"
set_chars "$1"
play
exit 0
