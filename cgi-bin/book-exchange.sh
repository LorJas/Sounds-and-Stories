#!/usr/bin/env bash
# CGI-Skript: nimmt application/x-www-form-urlencoded POST-Daten entgegen
# und speichert sie sicher in einer CSV-Datei.
set -euo pipefail

# Konfiguration
MAX_CONTENT_LENGTH=65536          # z.B. 64 KiB maximaler POST-Body
DATA_DIR_REL="../data"
CSV_FILENAME="book-exchange.csv"
CSV_PERMS=0640
DIR_PERMS=0750

# Fehler-Handler: gibt kontrollierte HTTP-Antwort zurück
error() {
  local status="${1:-500}"
  local message="${2:-Fehler}"
  printf "Status: %s\r\nContent-Type: text/plain; charset=UTF-8\r\n\r\n" "$status"
  printf "%s\n" "$message"
  exit 0
}
trap 'error 500 "Interner Serverfehler"' ERR

# --- Hilfsfunktionen

# Robustes URL-decode. Falls python3 vorhanden ist, nutze urllib (sicherer).
urldecode() {
  local encoded="$1"
  if command -v python3 >/dev/null 2>&1; then
    python3 - <<PY - "$encoded"
import sys, urllib.parse
print(urllib.parse.unquote_plus(sys.argv[1]))
PY
  else
    # Bash-Fallback: ersetzt + durch space, wandelt %HH. Validiert Hex-Codes.
    local data="${encoded//+/ }"
    # sichere Konversion: nur gültige %HH ersetzen, ungültige %-Sequenzen entfernen
    printf '%s' "$data" | sed -E 's/%([0-9A-Fa-f]{2})/\\x\1/g' | xargs -0 printf '%b' 2>/dev/null || printf '%s' "$data"
  fi
}

# Get field: findet das erste name=value-Paar in BODY; behandelt '=' im Wert korrekt.
get_field() {
  local key="$1"
  local pair val k
  # BODY ist global
  while IFS= read -r pair; do
    # split nur an erstem '='
    k="${pair%%=*}"
    val="${pair#*=}"
    if [[ "$k" == "$key" ]]; then
      urldecode "$val"
      return
    fi
  done < <(printf '%s' "$BODY" | tr '&' '\n')
  printf ''  # leer wenn nicht vorhanden
}

# CSV-Escape: doppelte Anführungszeichen verdoppeln und Feld in "..." einschließen
csv_escape() {
  local s="$1"
  s="${s//\"/\"\"}"
  printf '"%s"' "$s"
}

# Schutz gegen CSV/Excel-Formel-Injection:
# falls Feld mit =, +, -, @ beginnt, prefixe mit ' (einzelnes hochkomma)
csv_sanitize_formula() {
  local s="$1"
  case "${s:0:1}" in
    '='|'+'|'-'|'@')
      printf "'%s" "$s"
      ;;
    *)
      printf '%s' "$s"
      ;;
  esac
}

# --- POST-Body lesen & Basics prüfen
CONTENT_LENGTH="${CONTENT_LENGTH:-0}"
CONTENT_TYPE="${CONTENT_TYPE:-}"

if [[ "${REQUEST_METHOD:-}" != "POST" ]]; then
  error 405 "Nur POST unterstützt"
fi

# Content-Type prüfen
if [[ "$CONTENT_TYPE" != application/x-www-form-urlencoded* ]]; then
  error 415 "Unsupported Media Type: Erwarte application/x-www-form-urlencoded"
fi

# Länge prüfen
if ! [[ "$CONTENT_LENGTH" =~ ^[0-9]+$ ]]; then
  error 400 "Ungültige Content-Length"
fi
if (( CONTENT_LENGTH > MAX_CONTENT_LENGTH )); then
  error 413 "Request zu groß"
fi

BODY=""
if [[ "$CONTENT_LENGTH" -gt 0 ]]; then
  # Sicheres Lesen -- read mit -n liest genau CONTENT_LENGTH Bytes
  IFS= read -r -n "$CONTENT_LENGTH" BODY || true
fi

# --- Felder (Name-Attribute müssen mit Formular übereinstimmen)
author="$(get_field "author")"
title="$(get_field "book_title")"
genre="$(get_field "genre")"
condition="$(get_field "condition")"
language="$(get_field "language")"
contact="$(get_field "contact")"
shipping="$(get_field "shipping")"

# Optionale einfache Validierungen / Längenlimits (verhindert sehr lange Felder)
max_field_len=2000
for var in author title genre condition language contact shipping; do
  val="${!var}"
  if [[ "${#val}" -gt "${max_field_len}" ]]; then
    error 400 "Feld $var zu lang"
  fi
done

# einfache E-Mail-Prüfung (falls contact als E-Mail erwartet wird)
if [[ -n "$contact" && ! "$contact" =~ ^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+ ]]; then
  # nicht zwingend Fehler, aber warnen / alternativ ablehnen:
  # error 400 "Ungültige E-Mail"
  true
fi

# --- Pfade / Datei anlegen
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$(cd "$SCRIPT_DIR/$DATA_DIR_REL" 2>/dev/null && pwd || true)"
if [[ -z "$DATA_DIR" || ! -d "$DATA_DIR" ]]; then
  mkdir -p "$SCRIPT_DIR/$DATA_DIR_REL"
  chmod "$DIR_PERMS" "$SCRIPT_DIR/$DATA_DIR_REL"
  DATA_DIR="$(cd "$SCRIPT_DIR/$DATA_DIR_REL" && pwd)"
fi

CSV_FILE="$DATA_DIR/$CSV_FILENAME"

# Falls CSV nicht existiert, Headerzeile anlegen
if [[ ! -f "$CSV_FILE" ]]; then
  printf "Autor,Titel,Genre,Zustand,Sprache,E-Mail,Versandadresse\n" > "$CSV_FILE"
  chmod "$CSV_PERMS" "$CSV_FILE"
fi

# --- CSV-Zeile zusammensetzen
# Vorher Formula-Injection verhindern und korrekt escapen
a="$(csv_sanitize_formula "$author")"
t="$(csv_sanitize_formula "$title")"
g="$(csv_sanitize_formula "$genre")"
c="$(csv_sanitize_formula "$condition")"
l="$(csv_sanitize_formula "$language")"
e="$(csv_sanitize_formula "$contact")"
s="$(csv_sanitize_formula "$shipping")"

line="$(csv_escape "$a"),$(csv_escape "$t"),$(csv_escape "$g"),$(csv_escape "$c"),$(csv_escape "$l"),$(csv_escape "$e"),$(csv_escape "$s")"

# --- Atomar & mit Lock anhängen
# Versuche flock (falls vorhanden) auf Dateideskriptor 3
exec 3>>"$CSV_FILE"
if command -v flock >/dev/null 2>&1; then
  flock -x 3
  printf '%s\n' "$line" >&3
  flock -u 3
else
  # Fallback: einfacher Append (meistens atomic für einzelne write calls,
  # aber weniger sicher bei parallelen Prozessen)
  printf '%s\n' "$line" >&3
fi
exec 3>&-

# --- HTML-Response (Erfolg)
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
# --- Redirect zurück zur normalen HTML-Seite
printf "Status: 303 See Other\r\n"
printf "Location: ../book-exchange.html?saved=1\r\n\r\n"
exit 0
