#!/bin/bash

echo "4111111111111111"
./credit_card_task.sh 4111111111111111 # Валиден
echo ""

echo "5467929858074128"
./credit_card_task.sh 5467929858074128 # Валиден
echo ""

echo "2201382000000021"
./credit_card_task.sh 2201382000000021 # Валиден
echo ""

echo "1111111111111111"
./credit_card_task.sh 1111111111111111 # Не валиден
echo ""

echo "1234567890123456"
./credit_card_task.sh 1234567890123456 # Не валиден
echo ""

echo "123456789012345" # 15 цифр
./credit_card_task.sh 123456789012345 # Неверный формат
echo ""

echo "123456789012345a" # Символ вместо цифры
./credit_card_task.sh 123456789012345a # Неверный формат
echo ""

echo "Вызов без аргументов"
./credit_card_task.sh # Использование ...
echo ""
