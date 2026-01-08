#!/usr/bin/env bash
set -euo pipefail
umask 002

POSTDATA=""
if [ "${REQUEST_METHOD:-}" = "POST" ]; then
  read -r -n "${CONTENT_LENGTH:-0}" POSTDATA || true
fi

urldecode() {
  local data="${1//+/ }"
  printf '%b' "${data//%/\\x}"
}

get_param() {
  echo "$POSTDATA" | tr '&' '\n' | awk -F= -v k="$1" '$1==k {print substr($0, index($0,$2)); exit}'
}

sanitize() {
  echo "$1" | tr '\r\n' ' ' | sed 's/"/""/g'
}

author="$(sanitize "$(urldecode "$(get_param author)")")"
title="$(sanitize "$(urldecode "$(get_param book_title)")")"
genre="$(sanitize "$(urldecode "$(get_param genre)")")"
condition="$(sanitize "$(urldecode "$(get_param condition)")")"
language="$(sanitize "$(urldecode "$(get_param language)")")"
contact="$(sanitize "$(urldecode "$(get_param contact)")")"
shipping="$(sanitize "$(urldecode "$(get_param shipping)")")"

if [ -z "$author" ] || [ -z "$title" ] || [ -z "$genre" ] || \
   [ -z "$condition" ] || [ -z "$language" ] || \
   [ -z "$contact" ] || [ -z "$shipping" ]; then
  printf "Status: 303 See Other\r\n"
  printf "Location: ../book-exchange.html#error\r\n\r\n"
  exit 0
fi

CSV_FILE="../data/book-exchange.csv"
mkdir -p "$(dirname "$CSV_FILE")"

# Header nur wenn Datei nicht existiert oder leer ist
if [ ! -s "$CSV_FILE" ]; then
  echo 'Autor,Title,Genre,Zustand,Sprache,E-Mail,Versandadresse' > "$CSV_FILE"
fi

echo "\"$author\",\"$title\",\"$genre\",\"$condition\",\"$language\",\"$contact\",\"$shipping\"" >> "$CSV_FILE"

printf "Status: 303 See Other\r\n"
printf "Location: ../book-exchange.html#saved\r\n\r\n"
