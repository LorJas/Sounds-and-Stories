#!/usr/bin/env bash
# CGI: Speichert Musikmomente aus einem HTML-Formular in eine XML-Datei.

set -euo pipefail

# --- URL-Decoding (application/x-www-form-urlencoded)
urldecode() {
  local data="${1//+/ }"
  printf '%b' "${data//%/\\x}"
}

# --- Feld aus POST-Body holen
get_field() {
  local key="$1"
  local raw
  raw="$(printf '%s' "$BODY" | tr '&' '\n' | awk -F= -v k="$key" '$1==k{print $2; exit}')"
  urldecode "${raw:-}"
}

# --- Minimal XML escaping
xml_escape() {
  local s="$1"
  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  s="${s//\"/&quot;}"
  s="${s//\'/&apos;}"
  printf '%s' "$s"
}

# --- POST body lesen
CONTENT_LENGTH="${CONTENT_LENGTH:-0}"
BODY=""
if [[ "${REQUEST_METHOD:-}" == "POST" && "$CONTENT_LENGTH" -gt 0 ]]; then
  IFS= read -r -n "$CONTENT_LENGTH" BODY || true
fi

# --- Felder (Name-Attribute müssen zu euren Form-Inputs passen)
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

# --- Pfade
DATA_DIR="$(cd "$(dirname "$0")/../data" && pwd)"
XML_FILE="$DATA_DIR/musikmomente.xml"

# --- XML initialisieren, falls Datei noch nicht existiert
if [[ ! -f "$XML_FILE" ]]; then
  cat > "$XML_FILE" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<Musikmomente>
  <Titel>Songwünsche für den Wohnzimmer-Konzertabend</Titel>
</Musikmomente>
XML
fi

# --- Eintrag vor </Musikmomente> einfügen
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

# --- HTML Response
printf "Content-Type: text/html; charset=UTF-8\r\n\r\n"
cat <<HTML
<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <title>Musikmoment gespeichert</title>
</head>
<body>
  <h1>✅ Musikmoment gespeichert</h1>
  <p>Der Eintrag wurde in der XML-Datei gespeichert.</p>
  <ul>
    <li><a href="../musik.html">Zurück zum Formular</a></li>
    <li><a href="musik-liste.sh">Musikmomente anzeigen</a></li>
  </ul>
</body>
</html>
HTML