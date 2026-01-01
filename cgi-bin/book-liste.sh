#!/usr/bin/env bash
# CGI: Liest die Book-Exchange CSV und stellt die Einträge als HTML-Tabelle dar.

set -euo pipefail

DATA_DIR="$(cd "$(dirname "$0")/../data" && pwd)"
CSV_FILE="$DATA_DIR/book-exchange.csv"

printf "Content-Type: text/html; charset=UTF-8\r\n\r\n"
cat <<'HTML'
<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <title>Book Exchange – Liste</title>
  <style>
    body{font-family:Arial, sans-serif; max-width:1100px; margin:24px auto; line-height:1.5}
    table{border-collapse:collapse; width:100%}
    th,td{border:1px solid #ddd; padding:10px; vertical-align:top}
    th{background:#f5f5f5; text-align:left}
    a{color:#0645ad}
  </style>
</head>
<body>
  <h1>📚 Book Exchange</h1>
  <p><a href="../book-exchange.html">Zurück zum Formular</a></p>
HTML

if [[ ! -f "$CSV_FILE" ]]; then
  echo "<p><strong>Keine CSV-Datei gefunden.</strong> Bitte zuerst einen Eintrag speichern.</p>"
  echo "</body></html>"
  exit 0
fi

echo "<table>"
# Header und Zeilen ausgeben (CSV ist bei uns einfach, mit Quotes; daher: rudimentär)
# Für eure Abgabe reicht das, da ihr das CSV selbst erzeugt.
awk -v FPAT='([^,]*)|(\"([^\"]|\"\")*\")' '
  NR==1 {
    print "<tr>"
    for (i=1; i<=NF; i++) {
      gsub(/^"|"$/, "", $i)
      gsub(/""/, "\"", $i)
      print "<th>" $i "</th>"
    }
    print "</tr>"
    next
  }
  {
    print "<tr>"
    for (i=1; i<=NF; i++) {
      cell=$i
      gsub(/^"|"$/, "", cell)
      gsub(/""/, "\"", cell)
      print "<td>" cell "</td>"
    }
    print "</tr>"
  }
' "$CSV_FILE"
echo "</table>"

echo "</body></html>"