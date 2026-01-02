#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
XML_FILE="$BASE_DIR/data/musikmomente.xml"

printf "Content-Type: text/html; charset=UTF-8\r\n\r\n"

cat <<'HTML'
<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Gespeicherte Musikmomente</title>
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
        <h1 class="section-title">Gespeicherte Musikmomente</h1>
      </div>

      <div class="card">
        <div class="card-content">
HTML

if [[ ! -f "$XML_FILE" ]]; then
  echo "<p><b>Fehler:</b> XML-Datei nicht gefunden: ${XML_FILE}</p>"
  echo "        </div></div></section></main></body></html>"
  exit 0
fi

awk -v file="$XML_FILE" '
BEGIN {
  # Ganze Datei in Records splitten: jeder Musikmoment ist 1 Record
  RS = "<Musikmoment>"
  FS = "\n"
}
function esc(s, t) {
  t = s
  gsub(/&/, "\\&amp;", t)
  gsub(/</, "\\&lt;", t)
  gsub(/>/, "\\&gt;", t)
  gsub(/"/, "\\&quot;", t)
  return t
}
function gettag(rec, name,   re, m) {
  re = "<" name ">[^<]*</" name ">"
  if (match(rec, re)) {
    m = substr(rec, RSTART, RLENGTH)
    sub("^<" name ">", "", m)
    sub("</" name ">$", "", m)
    return m
  }
  return ""
}
BEGINFILE { }
{
  # Skip root header-Teil (vor em erste Musikmoment)
  if (NR == 1) next

  song = gettag($0, "Song")
  art  = gettag($0, "Kuenstler")
  mood = gettag($0, "Stimmung")
  sit  = gettag($0, "Situation")
  note = gettag($0, "Notizen")

  # nur wenn mind. Song oder Künstler drin isch
  if (song != "" || art != "") {
    if (count == 0) {
      print "<div class=\"table-wrap\">"
      print "<table class=\"data-table\">"
      print "<thead><tr><th>Song</th><th>Künstler/in</th><th>Stimmung</th><th>Situation</th><th>Notizen</th></tr></thead><tbody>"
    }
    print "<tr><td>" esc(song) "</td><td>" esc(art) "</td><td>" esc(mood) "</td><td>" esc(sit) "</td><td>" esc(note) "</td></tr>"
    count++
  }
}
ENDFILE {
  if (count == 0) {
    print "<p><i>Keine Einträge gefunden.</i></p>"
  } else {
    print "</tbody></table></div>"
  }
}
' "$XML_FILE"

cat <<'HTML'
        </div>
      </div>

      <p class="list-link" style="margin-top:1rem;">
        <a href="../musik.html">← zurück zu Musik als Ruhepunkt</a>
      </p>
    </section>
  </main>
</body>
</html>
HTML
