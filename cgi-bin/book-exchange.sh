#!/usr/bin/env bash
# CGI-Skript: nimmt application/x-www-form-urlencoded POST-Daten
# Book Exchange: Formular -> CSV speichern (CGI Bash)
set -euo pipefail

# 1) POST Body einlesen
POSTDATA=""
if [[ "${REQUEST_METHOD:-}" == "POST" ]]; then
  read -r -n "${CONTENT_LENGTH:-0}" POSTDATA || true
fi

# 2) URL-Decoding
urldecode() {
  local data="${1//+/ }"
  printf '%b' "${data//%/\\x}"
}

# 3) Parameter aus POSTDATA holen
get_param() {
  # usage: get_param "fieldname"
  echo "$POSTDATA" | tr '&' '\n' | awk -F= -v key="$1" '$1==key {print substr($0, index($0,$2)); exit}'
}

# 4) Felder lesen (müend zu "name=" im HTML passen!)
author_raw="$(get_param "author")"
title_raw="$(get_param "title")"
genre_raw="$(get_param "genre")"
condition_raw="$(get_param "condition")"
language_raw="$(get_param "language")"
contact_raw="$(get_param "contact")"
shipping_raw="$(get_param "shipping")"

author="$(urldecode "${author_raw:-}")"
title="$(urldecode "${title_raw:-}")"
genre="$(urldecode "${genre_raw:-}")"
condition="$(urldecode "${condition_raw:-}")"
language="$(urldecode "${language_raw:-}")"
contact="$(urldecode "${contact_raw:-}")"
shipping="$(urldecode "${shipping_raw:-}")"

# 5) Minimal-Sanitizing für CSV
sanitize() {
  # Zeilenumbrüche weg + Semikolon ersetzen (Semikolon = Trennzeichen)
  echo "$1" | tr '\r\n' ' ' | sed 's/;/,/g'
}

author="$(sanitize "$author")"
title="$(sanitize "$title")"
genre="$(sanitize "$genre")"
condition="$(sanitize "$condition")"
language="$(sanitize "$language")"
contact="$(sanitize "$contact")"
shipping="$(sanitize "$shipping")"

# 6) Pflichtfelder prüfen -> Redirect auf error (ohni HTML-Body!)
if [[ -z "$author" || -z "$title" || -z "$genre" || -z "$condition" || -z "$language" || -z "$contact" || -z "$shipping" ]]; then
  printf "Status: 303 See Other\r\n"
  printf "Location: ../book-exchange.html#error\r\n\r\n"
  exit 0
fi

# 7) CSV Pfad (relativ zum CGI, also: Projekt/data/)
CSV_FILE="../data/book-exchange.csv"

# Ordner anlegen falls fehlt
mkdir -p "$(dirname "$CSV_FILE")"

# Header schreiben falls Datei neu
if [[ ! -f "$CSV_FILE" ]]; then
  echo "author,title,genre,condition,language,contact,shipping" > "$CSV_FILE"
fi

# 8) Datensatz speichern (CSV mit Komma)
# WICHTIG: Wenn du Kommas im Text hast, wirds sauberer mit Quotes.
# Wir quoten alles:
echo "\"$author\",\"$title\",\"$genre\",\"$condition\",\"$language\",\"$contact\",\"$shipping\"" >> "$CSV_FILE"

# 9) Redirect zurück zur Book-Seite mit #saved (zeigt Message per CSS :target)
printf "Status: 303 See Other\r\n"
printf "Location: ../book-exchange.html#saved\r\n\r\n"
exit 0
