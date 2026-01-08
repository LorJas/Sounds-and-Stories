#!/usr/bin/env bash
set -euo pipefail
umask 002

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$BASE_DIR/data"
XML_FILE="$DATA_DIR/musikmomente.xml"

POST_DATA=""
if [[ "${REQUEST_METHOD:-}" == "POST" ]]; then
  read -r -n "${CONTENT_LENGTH:-0}" POST_DATA || true
fi

urldecode() {
  local data=${1//+/ }
  printf '%b' "${data//%/\\x}"
}

get_value() {
  echo "$POST_DATA" | tr '&' '\n' | grep -m1 "^$1=" | cut -d= -f2- | urldecode
}

xml_escape() {
  echo -n "$1" | sed \
    -e 's/&/\&amp;/g' \
    -e 's/</\&lt;/g' \
    -e 's/>/\&gt;/g' \
    -e "s/'/\&apos;/g" \
    -e 's/"/\&quot;/g'
}

SONG="$(get_value song)"
ARTIST="$(get_value artist)"
MOOD="$(get_value mood)"
SITUATION="$(get_value situation)"
NOTES="$(get_value notes)"

if [[ -z "$SONG" || -z "$ARTIST" ]]; then
  printf "Status: 303 See Other\r\n"
  printf "Location: ../musik.html#error\r\n\r\n"
  exit 0
fi

mkdir -p "$DATA_DIR"

if [[ ! -f "$XML_FILE" ]]; then
  cat > "$XML_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Musikmomente>
  <Titel>Songwünsche für den Wohnzimmer-Konzertabend</Titel>
</Musikmomente>
EOF
fi

# Escape vor dem Einfügen
SONG_E="$(xml_escape "$SONG")"
ARTIST_E="$(xml_escape "$ARTIST")"
MOOD_E="$(xml_escape "$MOOD")"
SITUATION_E="$(xml_escape "$SITUATION")"
NOTES_E="$(xml_escape "$NOTES")"

TMP_FILE="$(mktemp)"

awk -v song="$SONG_E" \
    -v artist="$ARTIST_E" \
    -v mood="$MOOD_E" \
    -v situation="$SITUATION_E" \
    -v notes="$NOTES_E" '
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

# Nur URL updaten + saved anzeigen
printf "Status: 303 See Other\r\n"
printf "Location: ../musik.html#saved\r\n\r\n"
