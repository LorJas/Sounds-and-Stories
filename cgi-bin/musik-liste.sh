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
  <title>Gespeicherte Musikmomente</title>
  <link rel="stylesheet" href="../css/style.css">
</head>
<body>
  <header class="site-header">
    <div class="header-inner">
      <div class="brand">
        <a href="../index.html" class="brand-title">Sounds &amp; Stories</a>
      </div>
      <nav class="nav">
        <ul class="nav-list">
          <li><a href="../book-exchange.html" class="nav-link">Book Exchange</a></li>
          <li><a href="../musik.html" class="nav-link nav-link--active">Musik als Ruhepunkt</a></li>
          <li><a href="../impressum.html" class="nav-link">Impressum</a></li>
        </ul>
      </nav>
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

gawk -v file="$XML_FILE" '
function html_escape(s,    t) {
  t = s
  gsub(/&/, "\\&amp;", t)
  gsub(/</, "\\&lt;", t)
  gsub(/>/, "\\&gt;", t)
  gsub(/"/, "\\&quot;", t)
  return t
}

# tag aus block holen, case-insensitive, inkl. umlaut-tags
function gettag_ci(block, tag,    b, t, re, m) {
  b = block
  t = tag
  re = "<[[:space:]]*" t "[[:space:]]*>[^<]*</[[:space:]]*" t "[[:space:]]*>"
  if (match(b, re)) {
    m = substr(b, RSTART, RLENGTH)
    sub("^<[[:space:]]*" t "[[:space:]]*>", "", m)
    sub("</[[:space:]]*" t "[[:space:]]*>$", "", m)
    return m
  }
  return ""
}

# versucht mehrere tag-varianten der reihe nach
function first_nonempty(block, a1,a2,a3,a4,a5,    v) {
  v = a1; if (v != "") return v
  v = a2; if (v != "") return v
  v = a3; if (v != "") return v
  v = a4; if (v != "") return v
  v = a5; if (v != "") return v
  return ""
}

BEGIN {
  xml = ""
  while ((getline line < file) > 0) xml = xml line "\n"

  # case-insensitive arbeiten: wir behalten original für values, aber fürs splitten nehmen wir auch lowercase.
  lower = tolower(xml)

  # musikmoment-tags finden (unterstützt <Musikmoment> / <musikmoment>)
  # wir splitten auf beide Varianten, indem wir im lower-string splitten und dann im original mit index nachziehen.
  # einfacher: wir suchen in original mit regex, aber IGNORECASE.
  IGNORECASE = 1

  print "<div class=\"table-wrap\">"
  print "<table class=\"data-table\">"
  print "<thead><tr><th>Song</th><th>Künstler/in</th><th>Stimmung</th><th>Situation</th><th>Notizen</th></tr></thead><tbody>"

  count = 0

  # alle <...musikmoment...> Blöcke iterieren
  pos = 1
  while (match(substr(xml, pos), /<musikmoment[[:space:]]*>/)) {
    start = pos + RSTART - 1
    # ende suchen
    rest = substr(xml, start)
    if (!match(rest, /<\/musikmoment[[:space:]]*>/)) break
    end = start + RSTART + RLENGTH - 2

    block = substr(xml, start, end - start + 1)

    # tags extrahieren (mehrere Varianten)
    song = first_nonempty(block,
      gettag_ci(block, "Song"),
      gettag_ci(block, "Songtitel"),
      gettag_ci(block, "Titel"),
      gettag_ci(block, "Title"),
      ""
    )

    artist = first_nonempty(block,
      gettag_ci(block, "Künstler"),
      gettag_ci(block, "Kuenstler"),
      gettag_ci(block, "KünstlerIn"),
      gettag_ci(block, "Artist"),
      ""
    )

    mood = first_nonempty(block,
      gettag_ci(block, "Stimmung"),
      gettag_ci(block, "Mood"),
      "",
      "",
      ""
    )

    situation = first_nonempty(block,
      gettag_ci(block, "Situation"),
      gettag_ci(block, "Kontext"),
      "",
      "",
      ""
    )

    notes = first_nonempty(block,
      gettag_ci(block, "Notizen"),
      gettag_ci(block, "Notiz"),
      gettag_ci(block, "Notes"),
      "",
      ""
    )

    # nur rows drucke, wenn mind. song oder artist gefüllt ist
    if (song != "" || artist != "") {
      print "<tr>"
      print "<td>" html_escape(song) "</td>"
      print "<td>" html_escape(artist) "</td>"
      print "<td>" html_escape(mood) "</td>"
      print "<td>" html_escape(situation) "</td>"
      print "<td>" html_escape(notes) "</td>"
      print "</tr>"
      count++
    }

    pos = end + 1
  }

  if (count == 0) {
    print "<tr><td colspan=\"5\"><i>Keine Einträge gefunden. (XML-Tags stimmen evtl. nicht überein.)</i></td></tr>"
  }

  print "</tbody></table></div>"
}
' 2>/dev/null

cat <<'HTML'
        </div>
      </div>

      <p class="list-link" style="margin-top:1rem;">
        <a href="../musik.html">← zurück</a>
      </p>
    </section>
  </main>
</body>
</html>
HTML
