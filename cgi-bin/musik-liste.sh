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
function esc(s,    t){
  t=s
  gsub(/&/, "\\&amp;", t)
  gsub(/</, "\\&lt;", t)
  gsub(/>/, "\\&gt;", t)
  gsub(/"/, "\\&quot;", t)
  return t
}
function tag(block, name,    re, m){
  re = "<" name ">[^<]*</" name ">"
  if (match(block, re)) {
    m = substr(block, RSTART, RLENGTH)
    sub("^<" name ">", "", m)
    sub("</" name ">$", "", m)
    return m
  }
  return ""
}
BEGIN{
  xml=""
  while ((getline line < file) > 0) xml = xml line "\n"

  print "<div class=\"table-wrap\">"
  print "<table class=\"data-table\">"
  print "<thead><tr><th>Song</th><th>Künstler/in</th><th>Stimmung</th><th>Situation</th><th>Notizen</th></tr></thead><tbody>"

  n = split(xml, parts, "<Musikmoment>")
  count=0
  for (i=2; i<=n; i++){
    block = parts[i]
    sub("</Musikmoment>.*$", "", block)

    song = tag(block, "Song")
    kuen = tag(block, "Kuenstler")
    stim = tag(block, "Stimmung")
    sit  = tag(block, "Situation")
    not  = tag(block, "Notizen")

    if (song=="" && kuen=="" && stim=="" && sit=="" && not=="") continue

    print "<tr>"
    print "<td>" esc(song) "</td>"
    print "<td>" esc(kuen) "</td>"
    print "<td>" esc(stim) "</td>"
    print "<td>" esc(sit) "</td>"
    print "<td>" esc(not) "</td>"
    print "</tr>"
    count++
  }

  if (count==0){
    print "<tr><td colspan=\"5\"><i>Keine Einträge gefunden.</i></td></tr>"
  }

  print "</tbody></table></div>"
}
' 2>/dev/null

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
