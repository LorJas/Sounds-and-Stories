#!/usr/bin/env bash
set -euo pipefail

# Pfad zur CSV
csv="/var/www/html/Sounds-and-Stories/data/book-exchange.csv"

# HTTP Header
printf "Content-Type: text/html\r\n\r\n"

cat <<'HTML'
<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8" />
  <title>Book Exchange – Übersicht</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    table { border-collapse: collapse; width: 100%; margin-top: 10px; }
    th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }
    th { background: #f2f2f2; }
    a { color: #0a66c2; text-decoration: none; }
    a:hover { text-decoration: underline; }
    .wrap { max-width: 1100px; margin: 0 auto; }
  </style>
</head>
<body>
<div class="wrap">
  <h1>📚 Book Exchange</h1>
  <p><a href="../book-exchange.html">Zurück zum Formular</a></p>

  <table>
HTML

# --- CSV lesen & Tabelle generieren ---

if [[ ! -f "$csv" ]]; then
  echo "<p><b>Fehler:</b> CSV-Datei nicht gefunden: $csv</p>"
  echo "</div></body></html>"
  exit 0
fi

# Header-Zeile lesen + CRLF entfernen
IFS= read -r header_line < "$csv" || true
header_line=${header_line//$'\r'/}

# Falls Datei leer ist
if [[ -z "${header_line:-}" ]]; then
  echo "<p><b>Hinweis:</b> Die CSV-Datei ist leer.</p>"
  echo "</div></body></html>"
  exit 0
fi

# Delimiter automatisch erkennen
delim=","
if [[ "$header_line" == *";"* ]]; then
  delim=";"
fi

# Header aufteilen
IFS="$delim" read -r -a header_cols <<< "$header_line"

# THEAD ausgeben
echo "<thead>"
echo "<tr>"
for col in "${header_cols[@]}"; do
  # kleine HTML-Sicherheit (minimale Escapes)
  col=${col//&/&amp;}
  col=${col//</&lt;}
  col=${col//>/&gt;}
  echo "<th>${col}</th>"
done
echo "</tr>"
echo "</thead>"

# TBODY ausgeben
echo "<tbody>"

# Ab Zeile 2 (ohne Header) lesen
tail -n +2 "$csv" | while IFS= read -r line; do
  # leere Zeilen skippen
  [[ -z "$line" ]] && continue

  # CRLF entfernen
  line=${line//$'\r'/}

  # Zeile in Spalten splitten
  IFS="$delim" read -r -a cols <<< "$line"

  echo "<tr>"
  for cell in "${cols[@]}"; do
    # minimale HTML-Escapes
    cell=${cell//&/&amp;}
    cell=${cell//</&lt;}
    cell=${cell//>/&gt;}
    echo "<td>${cell}</td>"
  done
  echo "</tr>"
done

echo "</tbody>"

cat <<'HTML'
  </table>
</div>
</body>
</html>
HTML
