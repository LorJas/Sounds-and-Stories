#!/usr/bin/env bash
# CGI-Skript: Nimmt Formulardaten (POST) entgegen und speichert sie als neuen Eintrag in einer XML-Datei.
# Redirect danach zurück auf ../musik.html#saved

set -euo pipefail
umask 002

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$BASE_DIR/data"
XML_FILE="$DATA_DIR/musikmomente.xml"

# POST-Daten lesen
read -r POST_DATA

# Hilfsfunktion zum URL-Decoding
urldecode() {
  local data=${1//+/ }
  printf '%b' "${data//%/\\x}"
}

# Werte extrahieren
get_value() {
  echo "$POST_DATA" | tr '&' '\n' | grep "^$1=" | cut -d= -f2- | urldecode
}

SONG="$(get_value song)"
ARTIST="$(get_value artist)"
MOOD="$(get_value mood)"
SITUATION="$(get_value situation)"
NOTES="$(get_value notes)"

# Leere Pflichtfelder abfangen
if [[ -z "$SONG" || -z "$ARTIST" ]]; then
  printf "Status: 303 See Other\r\n"
  printf "Location: ../musik.html\r\n\r\n"
  exit 0
fi

# XML-Datei initialisieren, falls sie noch nicht existiert
if [[ ! -f "$XML_FILE" ]]; then
  cat > "$XML_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Musikmomente>
</Musikmomente>
EOF
fi

# neuen Musikmoment einfügen (vor schliessendem Root-Tag)
TMP_FILE="$(mktemp)"

awk -v song="$SONG" \
    -v artist="$ARTIST" \
    -v mood="$MOOD" \
    -v situation="$SITUATION" \
    -v notes="$NOTES" '
/<\/Musikmomente>/ {
  print "  <Musikmoment>"
  print "    <Song>" song "</Song>"
  print "    <Kuenstler>" artist "</Kuenstler>"
  print "    <Stimmung>" mood "</Stimmung>"
  print "    <Situation>" situation "</Situation>"
  print "    <Notizen>" notes "</Notizen>"
  print "  </Musikmoment>"
}
{ print }
' "$XML_FILE" > "$TMP_FILE"

mv "$TMP_FILE" "$XML_FILE"
chmod 664 "$XML_FILE"

# Redirect zurück zur Musik-Seite mit Erfolgshinweis
printf "Status: 303 See Other\r\n"
printf "Location: ../musik.html#saved\r\n\r\n"
