#!/usr/bin/env bash
set -euo pipefail

CSV_FILE="/var/www/html/Sounds-and-Stories/data/book-exchange.csv"
DATA_DIR="/var/www/html/Sounds-and-Stories/data"
CSV_FILE="$DATA_DIR/book-exchange.csv"

printf "Content-Type: text/html; charset=UTF-8\r\n\r\n"

cat <<'HTML'
<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Book Exchange – Übersicht</title>
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
        <h1 class="section-title">📚 Aktuelle Buchangebote</h1>
      </div>

      <div class="card">
        <div class="card-content">
HTML

if [[ ! -f "$CSV_FILE" ]]; then
  echo "<p><b>Fehler:</b> CSV-Datei nicht gefunden: ${CSV_FILE}</p>"
  echo "        </div></div></section></main></body></html>"
  exit 0
fi

# Robust CSV parsing (quoted fields + delimiter , oder ;)
gawk -v file="$CSV_FILE" '
function html_escape(s,    t) {
  t = s
  gsub(/&/, "\\&amp;", t)
  gsub(/</, "\\&lt;", t)
  gsub(/>/, "\\&gt;", t)
  gsub(/"/, "\\&quot;", t)
  return t
}

# CSV split mit Quotes: unterstützt Kommas/Delimiter innerhalb von ""
function csv_split(line, arr, delim,    i, c, inq, field, n) {
  n = 0; field = ""; inq = 0
  for (i = 1; i <= length(line); i++) {
    c = substr(line, i, 1)
    if (c == "\"") {
      # "" داخل quotes = escaped quote
      if (inq && substr(line, i+1, 1) == "\"") { field = field "\""; i++ }
      else { inq = !inq }
    } else if (!inq && c == delim) {
      arr[++n] = field
      field = ""
    } else {
      field = field c
    }
  }
  arr[++n] = field
  return n
}

BEGIN {
  # Delimiter automatisch erkennen anhand Header
  if ((getline header < file) <= 0) {
    print "<p><b>Hinweis:</b> Die CSV-Datei ist leer.</p>"
    exit
  }
  sub(/\r$/, "", header)

  delim = ","
  if (index(header, ";") > 0) delim = ";"

  hn = csv_split(header, h, delim)

  print "<div class=\"table-wrap\">"
  print "<table class=\"data-table\">"
  print "<thead><tr>"
  for (i=1; i<=hn; i++) print "<th>" html_escape(h[i]) "</th>"
  print "</tr></thead><tbody>"

  rowcount = 0
  while ((getline line < file) > 0) {
    sub(/\r$/, "", line)
    if (line ~ /^[[:space:]]*$/) continue

    rn = csv_split(line, r, delim)

    print "<tr>"
    for (i=1; i<=hn; i++) {
      val = (i<=rn ? r[i] : "")
      print "<td>" html_escape(val) "</td>"
    }
    print "</tr>"
    rowcount++
  }

  if (rowcount == 0) {
    print "<tr><td colspan=\"" hn "\"><i>Keine Einträge vorhanden.</i></td></tr>"
  }

  print "</tbody></table></div>"
}
' 2>/dev/null

cat <<'HTML'
        </div>
      </div>

      <p class="list-link" style="margin-top:1rem;">
        <a href="../book-exchange.html">← zurück zum Formular</a>
      </p>
    </section>
  </main>
  <style>
    body { font-family: Arial, sans-serif; margin: 24px; }
    a { display:inline-block; margin-bottom: 12px; }
    table { border-collapse: collapse; width: 100%; max-width: 1100px; }
    th, td { border: 1px solid #ddd; padding: 10px; vertical-align: top; }
    th { text-align: left; background: #f6f6f6; }
    tr:nth-child(even) td { background: #fafafa; }
  </style>
</head>
<body>
  <h1>📚 Book Exchange</h1>
  <a href="../book-exchange.html">Zurück zum Formular</a>

  <table>
    <thead>
      <tr>
        <th>Autor</th>
        <th>Titel</th>
        <th>Genre</th>
        <th>Zustand</th>
        <th>Sprache</th>
        <th>E-Mail</th>
        <th>Versandadresse</th>
      </tr>
    </thead>
    <tbody>
HTML

# CSV robust lesen (mit Python csv-Modul -> kann Quotes + Kommas korrekt)
python3 - <<PY
import csv, html, os, sys

path = "$CSV_FILE"
if not os.path.exists(path):
    print('<tr><td colspan="7">Keine CSV-Datei gefunden.</td></tr>')
    sys.exit(0)

with open(path, newline='', encoding='utf-8') as f:
    r = csv.reader(f)
    # Header überspringen
    try:
        next(r)
    except StopIteration:
        print('<tr><td colspan="7">CSV ist leer.</td></tr>')
        sys.exit(0)

    any_row = False
    for row in r:
        if not row:
            continue
        any_row = True

        # Falls jemand Kommas/Quotes drin hat, csv.reader handled das korrekt.
        # Wir erwarten 7 Felder. Wenn mehr/weniger -> zusammenfassen/auffüllen.
        if len(row) < 7:
            row = row + [""]*(7-len(row))
        elif len(row) > 7:
            # alles ab Feld 7 in die Adresse packen
            row = row[:6] + [",".join(row[6:])]

        row = [html.escape(x) for x in row]
        print("<tr>" + "".join(f"<td>{x}</td>" for x in row) + "</tr>")

    if not any_row:
        print('<tr><td colspan="7">Noch keine Einträge vorhanden.</td></tr>')
PY

cat <<'HTML'
    </tbody>
  </table>
</body>
</html>
HTML
