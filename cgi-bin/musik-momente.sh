#!/usr/bin/env bash
# CGI-Skript: Nimmt Formulardaten (POST) entgegen und speichert sie als neuen Eintrag in einer XML-Datei.
# Zweck: Persistente Speicherung von Musikmomenten und spätere Darstellung über ein separates CGI-Skript.

set -euo pipefail

# URL-Decoding für application/x-www-form-urlencoded:
# - "+" wird zu Leerzeichen
# - "%xx" wird zu den entsprechenden Zeichen
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

# Minimales XML-Escaping, damit Sonderzeichen in XML gültig bleiben
xml_escape() {
  local s="$1"
  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  s="${s//\"/&quot;}"
  s="${s//\'/&apos;}"
  printf '%s' "$s"
}

# --- POST-Body lesen (bei GET ist BODY leer)
CONTENT_LENGTH="${CONTENT_LENGTH:-0}"
BODY=""
if [[ "${REQUEST_METHOD:-}" == "POST" && "$CONTENT_LENGTH" -gt 0 ]]; then
  IFS= read -r -n "$CONTENT_LENGTH" BODY || true
fi

# --- Felder aus dem Formular (müssen zu den name="..." Attributen passen)
song="$(get_field "song")"
artist="$(get_field "artist")"
mood="$(get_field "mood")"
situation="$(get_field "situation")"
notes="$(get_field "notes")"

# Sonderzeichen für XML absichern
song="$(xml_escape "$song")"
artist="$(xml_escape "$artist")"
mood="$(xml_escape "$mood")"
situation="$(xml_escape "$situation")"
notes="$(xml_escape "$notes")"

# --- Pfade (data/ liegt eine Ebene über cgi-bin/)
DATA_DIR="$(cd "$(dirname "$0")/../data" && pwd)"
XML_FILE="$DATA_DIR/musikmomente.xml"

# --- Falls XML-Datei noch nicht existiert, Initialstruktur erzeugen
if [[ ! -f "$XML_FILE" ]]; then
  cat > "$XML_FILE" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<Musikmomente>
  <Titel>Songwünsche für den Wohnzimmer-Konzertabend</Titel>
</Musikmomente>
XML
fi

# --- Neuen <Musikmoment>-Block vor dem schliessenden Root-Tag einfügen
# Lösung mit awk: zuverlässig für unsere kontrollierte XML-Struktur.
tmp="$(mktemp)"
awk -v song="$song" -v artist="$artist" -v mood="$mood" -v situation="$situation" -v notes="$notes" '
/<\/Musikmomente>/{
  print "  <Musikmoment>"
  print "    <Song>" song "</Song>"
  print "    <Kuenstler>" artist "</Kuenstler>"
  print "    <Stimmung>" mood "</Stimmung>"
  print "    <Situation>" situation "</Situation>"
  print "    <Notizen>" notes "</Notizen>"
  print "  </Musikmoment>"
}
{ print }
' "$XML_FILE" > "$tmp"
mv "$tmp" "$XML_FILE"

# --- Redirect zurück zur normalen HTML-Seite
printf "Status: 303 See Other\r\n"
printf "Location: ../musik.html?saved=1\r\n\r\n"
exit 0
