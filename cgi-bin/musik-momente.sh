#!/usr/bin/env bash
# CGI-Skript: Nimmt Formulardaten (POST) entgegen und speichert sie als neuen Eintrag in einer XML-Datei.
# Redirect danach zurück auf ../musik.html#saved

set -euo pipefail

# URL-Decoding (application/x-www-form-urlencoded)
urldecode() {
  local data="${1//+/ }"
  printf '%b' "${data//%/\\x}"
}

# Feld aus POST-Body anhand Key (name="...") extrahieren
get_field() {
  local key="$1"
  local raw
  raw="$(printf '%s' "$BODY" | tr '&' '\n' | awk -F= -v k="$key" '$1==k{print $2; exit}')"
  urldecode "${raw:-}"
}

# XML-Escaping (Minimalset)
xml_escape() {
  local s="$1"
  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  s="${s//\"/&quot;}"
  s="${s//\'/&apos;}"
  printf '%s' "$s"
}

# POST-Body lesen
CONTENT_LENGTH="${CONTENT_LENGTH:-0}"
BODY=""

if [[ "${REQUEST_METHOD:-}" == "POST" && "$CONTENT_LENGTH" -gt 0 ]]; then
  IFS= read -r -n "$CONTENT_LENGTH" BODY || true
fi

# Felder (müssen zu name="..." in musik.html passen)
song="$(get_field "song")"
artist="$(get_field "artist")"
mood="$(get_field "mood")"
situation="$(get_field "situation")"
notes="$(get_field "notes")"

song="$(xml_escape "$song")"
artist="$(xml_escape "$artist")"
mood="$(xml_escape "$mood")"
situation="$(xml_escape "$situation")"
notes="$(xml_escape "$notes")"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="$(cd "$SCRIPT_DIR/../data" && pwd)"
XML_FILE="$DATA_DIR/musikmomente.xml"

TMP_FILE="$(mktemp "$DATA_DIR/.musikmomente.xml.XXXXXX")"

if [[ ! -f "$XML_FILE" ]]; then
  cat > "$XML_FILE" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<Musikmomente>
  <Titel>Songwünsche für den Wohnzimmer-Konzertabend</Titel>
</Musikmomente>
XML
fi

awk -v song="$song" -v artist="$artist" -v mood="$mood" -v situation="$situation" -v notes="$notes" '
BEGIN { inserted=0 }
{
  # Beim schliessenden Root-Tag: vorher neuen Block einfügen (nur 1x)
  if ($0 ~ /<\/Musikmomente>/ && inserted==0) {
    print "  <Musikmoment>"
    print "    <Song>" song "</Song>"
    print "    <Kuenstler>" artist "</Kuenstler>"
    print "    <Stimmung>" mood "</Stimmung>"
    print "    <Situation>" situation "</Situation>"
    print "    <Notizen>" notes "</Notizen>"
    print "  </Musikmoment>"
    inserted=1
  }
  print $0
}
' "$XML_FILE" > "$TMP_FILE"

mv -f "$TMP_FILE" "$XML_FILE"

# Redirect zurück zur normalen HTML-Seite mit Anchor #saved
printf "Status: 303 See Other\r\n"
printf "Location: ../musik.html#saved\r\n\r\n"
exit 0
