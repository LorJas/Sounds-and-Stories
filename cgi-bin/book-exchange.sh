#!/usr/bin/env bash
# CGI-Skript: Nimmt Formulardaten (POST) entgegen und speichert sie als neuen Eintrag in einer CSV-Datei.
# Zweck: Persistente Speicherung von Buchangeboten und spätere Darstellung über ein separates CGI-Skript.

set -euo pipefail

# URL-Decoding für application/x-www-form-urlencoded
urldecode() {
  local data="${1//+/ }"
  printf '%b' "${data//%/\\x}"
}

# Extrahiert ein Feld aus dem POST-Body anhand des Keys (name-Attribut im HTML-Formular)
get_field() {
  local key="$1"
  local raw
  raw="$(printf '%s' "$BODY" | tr '&' '\n' | awk -F= -v k="$key" '$1==k{print $2; exit}')"
  urldecode "${raw:-}"
}

# CSV-Quoting:
# - Doppelte Anführungszeichen werden verdoppelt
# - Das Feld wird in "..." eingeschlossen
csv_escape() {
  local s="$1"
  s="${s//\"/\"\"}"
  printf '"%s"' "$s"
}

# --- POST-Body lesen
CONTENT_LENGTH="${CONTENT_LENGTH:-0}"
BODY=""
if [[ "${REQUEST_METHOD:-}" == "POST" && "$CONTENT_LENGTH" -gt 0 ]]; then
  IFS= read -r -n "$CONTENT_LENGTH" BODY || true
fi

# --- Felder aus dem Formular (müssen zu den name="..." Attributen passen)
author="$(get_field "author")"
title="$(get_field "book_title")"
genre="$(get_field "genre")"
condition="$(get_field "condition")"
language="$(get_field "language")"
contact="$(get_field "contact")"
shipping="$(get_field "shipping")"

# --- Pfade
DATA_DIR="$(cd "$(dirname "$0")/../data" && pwd)"
CSV_FILE="$DATA_DIR/book-exchange.csv"

# --- Falls CSV nicht existiert, Headerzeile anlegen (sprechenede Spaltennamen)
if [[ ! -f "$CSV_FILE" ]]; then
  printf "Autor,Titel,Genre,Zustand,Sprache,E-Mail,Versandadresse\n" > "$CSV_FILE"
fi

# --- Neuen Datensatz ans Ende anhängen
printf "%s,%s,%s,%s,%s,%s,%s\n" \
  "$(csv_escape "$author")" \
  "$(csv_escape "$title")" \
  "$(csv_escape "$genre")" \
  "$(csv_escape "$condition")" \
  "$(csv_escape "$language")" \
  "$(csv_escape "$contact")" \
  "$(csv_escape "$shipping")" \
  >> "$CSV_FILE"

# --- HTML-Response
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