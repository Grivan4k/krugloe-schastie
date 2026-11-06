#!/bin/bash
# Запуск Vanessa Automation для тестов конфигурации «Круглое счастье» (Linux).
#
# Использование:
#   ./run_va.sh <каталог_базы> <vanessa-automation-single.epf>          – открыть VA, сценарии загружены
#   ./run_va.sh <каталог_базы> <vanessa-automation-single.epf> auto     – выполнить все сценарии и закрыть VA
#
# Пример:
#   ./run_va.sh ~/1c/КруглоеСчастье ~/va/vanessa-automation-single.epf
#
# Менеджер тестирования запускается под пользователем «Администратор» (пароль 123),
# клиенты тестирования – под пользователями из сценариев (Каменская Д.В., Иванова М.С.).

set -e
BASE="$1"; EPF="$2"; MODE="${3:-ui}"
if [ -z "$BASE" ] || [ -z "$EPF" ]; then
  sed -n '2,12p' "$0"; exit 1
fi
DIR="$(cd "$(dirname "$0")" && pwd)"
BASE="$(cd "$BASE" && pwd)"
EPF="$(cd "$(dirname "$EPF")" && pwd)/$(basename "$EPF")"

# каталог платформы: последняя установленная 8.5, иначе последняя 8.x
PLATFORM="${PLATFORM:-$(ls -d /opt/1cv8/x86_64/8.5.* 2>/dev/null | sort -V | tail -1)}"
[ -z "$PLATFORM" ] && PLATFORM="$(ls -d /opt/1cv8/x86_64/8.* 2>/dev/null | sort -V | tail -1)"
CLIENT="$PLATFORM/1cv8c"
if [ ! -x "$CLIENT" ]; then
  echo "Не найден тонкий клиент 1cv8c. Укажите каталог платформы: PLATFORM=/opt/1cv8/x86_64/8.5.x.xxxx $0 ..."; exit 1
fi

OUT="$DIR/out"; mkdir -p "$OUT"
cat > "$OUT/VAParams.json" <<JSON
{
  "Lang": "ru",
  "КаталогФич": "$DIR/features",
  "КаталогПроекта": "$DIR",
  "ДелатьЛогВыполненияСценариевВТекстовыйФайл": true,
  "ИмяФайлаЛогВыполненияСценариев": "$OUT/log.txt",
  "ВыгружатьСтатусВыполненияСценариевВФайл": true,
  "ПутьКФайлуДляВыгрузкиСтатусаВыполненияСценариев": "$OUT/status.txt",
  "ЗакрытьTestClientПослеЗапускаСценариев": true,
  "ОпределятьРеальныйПортНаКоторомЗапустилсяКлиентТестирования": true
}
JSON

PARAMS="VAParams=$OUT/VAParams.json"
[ "$MODE" = "auto" ] && PARAMS="StartFeaturePlayer;QuietInstallVanessaExt;$PARAMS"

echo "Платформа: $CLIENT"
echo "База:      $BASE"
echo "Сценарии:  $DIR/features"
"$CLIENT" /IBConnectionString "File=\"$BASE\";" /N"Администратор" /P"123" /TestManager \
  /DisableStartupDialogs /Execute "$EPF" /C"$PARAMS"

if [ "$MODE" = "auto" ]; then
  echo "Лог выполнения: $OUT/log.txt"
  [ -f "$OUT/status.txt" ] && echo "Статус (0 – все сценарии пройдены): $(cat "$OUT/status.txt")"
fi
