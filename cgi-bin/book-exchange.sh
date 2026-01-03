#!/usr/bin/env bash
# CGI Script: Book Exchange -> CSV speichern

set -euo pipefail

# 1) POST-Daten einlesen
POSTDATA=""
if [ "${REQUEST_METHOD:-}" = "POST" ]; then
  read -r -n "${CONTENT_LENGTH:-0}" POSTDATA || true
fi

# 2) URL-Decoding
urldecode() {
  local data="${1//+/ }"
  printf '%b' "${data//%/\\x}"
}

get_param() {
  echo "$POSTDATA" | tr '&' '\n' | awk -F= -v k="$1" '$1==k {print substr($0, index($0,$2)); exit}'
}

# 3) Formular-Felder lesen
author="$(urldecode "$(get_param author)")"
title="$(urldecode "$(get_param title)")"
genre="$(urldecode "$(get_param genre)")"
condition="$(urldecode "$(get_param condition)")"
language="$(urldecode "$(get_param language)")"
contact="$(urldecode "$(get_param contact)")"
shipping="$(urldecode "$(get_param shipping)")"

# 4) Minimal-Sanitizing für CSV
sanitize() {
  echo "$1" | tr '\r\n' ' ' | sed 's/"/""/g'
}

author="$(sanitize "$author")"
title="$(sanitize "$title")"
genre="$(sanitize "$genre")"
condition="$(sanitize "$condition")"
language="$(sanitize "$language")"
contact="$(sanitize "$contact")"
shipping="$(sanitize "$shipping")"

# 5) Pflichtfelder prüfen
if [ -z "$author" ] || [ -z "$title" ] || [ -z "$genre" ] || \
   [ -z "$condition" ] || [ -z "$language" ] || \
   [ -z "$contact" ] || [ -z "$shipping" ]; then
  printf "Status: 303 See Other\r\n"
  printf "Location: ../book-exchange.html#error\r\n\r\n"
  exit 0
fi

# 6) CSV speichern
CSV_FILE="../data/book-exchange.csv"
mkdir -p "$(dirname "$CSV_FILE")"

# Header falls Datei neu
if [ ! -f "$CSV_FILE" ]; then
  echo '"author","title","genre","condition","language","contact","shipping"' > "$CSV_FILE"
fi

# Datensatz anhängen
echo "\"$author\",\"$title\",\"$genre\",\"$condition\",\"$language\",\"$contact\",\"$shipping\"" >> "$CSV_FILE"

# 7) Redirect zurück zum Formular
printf "Status: 303 See Other\r\n"
printf "Location: ../book-exchange.html#saved\r\n\r\n"
exit 0
