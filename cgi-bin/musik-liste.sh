#!/usr/bin/env bash
# CGI: Liest die Musikmomente-XML und stellt die Einträge als HTML dar.

set -euo pipefail

DATA_DIR="$(cd "$(dirname "$0")/../data" && pwd)"
XML_FILE="$DATA_DIR/musikmomente.xml"

printf "Content-Type: text/html; charset=UTF-8\r\n\r\n"
cat <<'HTML'
<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <title>Musikmomente – Liste</title>
  <style>
    body{font-family:Arial, sans-serif; max-width:900px; margin:24px auto; line-height:1.5}
    .card{border:1px solid #ddd; border-radius:10px; padding:14px 16px; margin:12px 0}
    .meta{color:#444; font-size:0.95em}
    a{color:#0645ad}
  </style>
</head>
<body>
  <h1>🎵 Musikmomente</h1>
  <p><a href="../musik.html">Zurück zum Formular</a></p>
HTML

if [[ ! -f "$XML_FILE" ]]; then
  echo "<p><strong>Keine XML-Datei gefunden.</strong> Bitte zuerst einen Eintrag speichern.</p>"
  echo "</body></html>"
  exit 0
fi

# sehr einfache XML-Auswertung (für strukturierte, eigene XML ok)
# Wir suchen jeweils die Tags in Reihenfolge und bauen daraus HTML-Karten.
awk '
  BEGIN { FS=""; song=""; artist=""; mood=""; situation=""; notes=""; in=0 }
  /<Musikmoment>/ { in=1 }
  /<\/Musikmoment>/ {
    if (in==1) {
      print "<div class=\"card\">"
      print "  <h2>" song "</h2>"
      print "  <div class=\"meta\"><strong>Künstler:</strong> " artist "</div>"
      print "  <div class=\"meta\"><strong>Stimmung:</strong> " mood "</div>"
      print "  <div class=\"meta\"><strong>Situation:</strong> " situation "</div>"
      if (notes != "") print "  <p>" notes "</p>"
      print "</div>"
    }
    song=""; artist=""; mood=""; situation=""; notes=""; in=0
  }
  {
    line=$0
    if (line ~ /<Song>/)      { sub(/.*<Song>/,"",line); sub(/<\/Song>.*/,"",line); song=line }
    if (line ~ /<Kuenstler>/) { sub(/.*<Kuenstler>/,"",line); sub(/<\/Kuenstler>.*/,"",line); artist=line }
    if (line ~ /<Stimmung>/)  { sub(/.*<Stimmung>/,"",line); sub(/<\/Stimmung>.*/,"",line); mood=line }
    if (line ~ /<Situation>/) { sub(/.*<Situation>/,"",line); sub(/<\/Situation>.*/,"",line); situation=line }
    if (line ~ /<Notizen>/)   { sub(/.*<Notizen>/,"",line); sub(/<\/Notizen>.*/,"",line); notes=line }
  }
' "$XML_FILE"

echo "</body></html>"