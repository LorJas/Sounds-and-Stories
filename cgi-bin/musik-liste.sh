#!/usr/bin/env bash
set -euo pipefail

XML_FILE="/var/www/html/Sounds-and-Stories/data/musikmomente.xml"

printf "Content-Type: text/html; charset=UTF-8\r\n\r\n"

cat <<'HTML'
<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Musikmomente – Übersicht</title>
  <link rel="stylesheet" href="../css/style.css">
</head>
<body>
  <header class="site-header">
    <div class="header-inner">
      <div class="brand">
        <a href="../index.html" class="brand-title">Sounds &amp; Stories</a>
      </div>
    </div>
  </header>

  <main class="container">
    <section class="section">
      <div class="section-header">
        <h1 class="section-title">🎵 Gespeicherte Musikmomente</h1>
      </div>

      <div class="card">
        <div class="card-content">
HTML

if [[ ! -f "$XML_FILE" ]]; then
  echo "<p><b>Fehler:</b> XML-Datei nicht gefunden: ${XML_FILE}</p>"
  echo "        </div></div></section></main></body></html>"
  exit 0
fi

# Einfaches XML-Parsing (für eure fixe Struktur)
gawk -v file="$XML_FILE" '
function html_escape(s,    t) {
  t = s
  gsub(/&/, "\\&amp;", t)
  gsub(/</, "\\&lt;", t)
  gsub(/>/, "\\&gt;", t)
  gsub(/"/, "\\&quot;", t)
  return t
}
function gettag(block, tag,    re, m) {
  re = "<" tag ">[^<]*</" tag ">"
  if (match(block, re)) {
    m = substr(block, RSTART, RLENGTH)
    gsub("^<" tag ">", "", m)
    gsub("</" tag ">$", "", m)
    return m
  }
  return ""
}
BEGIN {
  # Datei komplett lesen
  xml = ""
  while ((getline line < file) > 0) xml = xml line "\n"

  # Musikmoment-Blöcke splitten
  n = split(xml, parts, "<Musikmoment>")
  print "<div class=\"table-wrap\">"
  print "<table class=\"data-table\">"
  print "<thead><tr><th>Song</th><th>Künstler</th><th>Stimmung</th><th>Situation</th><th>Notizen</th></tr></thead><tbody>"

  count = 0
  for (i=2; i<=n; i++) {
    block = parts[i]
    sub("</Musikmoment>.*$", "", block)

    song = gettag(block, "Song")
    kuenstler = gettag(block, "Kuenstler")
    stimmung = gettag(block, "Stimmung")
    situation = gettag(block, "Situation")
    notizen = gettag(block, "Notizen")

    if (song kuenstler stimmung situation notizen == "") continue

    print "<tr>"
    print "<td>" html_escape(song) "</td>"
    print "<td>" html_escape(kuenstler) "</td>"
    print "<td>" html_escape(stimmung) "</td>"
    print "<td>" html_escape(situation) "</td>"
    print "<td>" html_escape(notizen) "</td>"
    print "</tr>"
    count++
  }

  if (count == 0) {
    print "<tr><td colspan=\"5\"><i>Keine Einträge vorhanden.</i></td></tr>"
  }

  print "</tbody></table></div>"
}
' 2>/dev/null

cat <<'HTML'
        </div>
      </div>

      <p class="list-link" style="margin-top:1rem;">
        <a href="../musik.html">← zurück zum Formular</a>
      </p>

      <p class="card-text" style="margin-top:0.5rem;">
        (Optional für Dozent: <a href="../data/musikmomente.xml" target="_blank" rel="noopener">XML-Datei direkt öffnen</a>)
      </p>
    </section>
  </main>
</body>
</html>
HTML
