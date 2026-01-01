#!/usr/bin/env bash
# CGI: Speichert Book-Exchange Einträge aus einem HTML-Formular in eine CSV-Datei.

set -euo pipefail

urldecode() {
  local data="${1//+/ }"
  printf '%b' "${data//%/\\x}"
}

get_field() {
  local key="$1"
  local raw
  raw="$(printf '%s' "$BODY" | tr '&' '\n' | awk -F= -v k="$key" '$1==k{print $2; exit}')"
  urldecode "${raw:-}"
}

# CSV-Quoting (Anführungszeichen verdoppeln)
csv_escape() {
  local s="$1"
  s="${s//\"/\"\"}"
  printf '"%s"' "$s"
}

CONTENT_LENGTH="${CONTENT_LENGTH:-0}"
BODY=""
if [[ "${REQUEST_METHOD:-}" == "POST" && "$CONTENT_LENGTH" -gt 0 ]]; then
  IFS= read -r -n "$CONTENT_LENGTH" BODY || true
fi

# Name-Attribute müssen zu euren Form-Inputs passen
author="$(get_field "author")"
title="$(get_field "book_title")"
genre="$(get_field "genre")"
condition="$(get_field "condition")"
language="$(get_field "language")"
contact="$(get_field "contact")"
shipping="$(get_field "shipping")"

DATA_DIR="$(cd "$(dirname "$0")/../data" && pwd)"
CSV_FILE="$DATA_DIR/book-exchange.csv"

# Header, falls Datei nicht existiert
if [[ ! -f "$CSV_FILE" ]]; then
  printf "Autor,Titel,Genre,Zustand,Sprache,E-Mail,Versandadresse\n" > "$CSV_FILE"
fi

printf "%s,%s,%s,%s,%s,%s,%s\n" \
  "$(csv_escape "$author")" \
  "$(csv_escape "$title")" \
  "$(csv_escape "$genre")" \
  "$(csv_escape "$condition")" \
  "$(csv_escape "$language")" \
  "$(csv_escape "$contact")" \
  "$(csv_escape "$shipping")" \
  >> "$CSV_FILE"

printf "Content-Type: text/html; charset=UTF-8\r\n\r\n"
cat <<HTML
<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <title>Buchangebot gespeichert</title>
</head>
<body>
  <h1>✅ Buchangebot gespeichert</h1>
  <p>Der Eintrag wurde in der CSV-Datei gespeichert.</p>
  <ul>
    <li><a href="../book-exchange.html">Zurück zum Formular</a></li>
    <li><a href="book-liste.sh">Buchangebote anzeigen</a></li>
  </ul>
</body>
</html>
HTML