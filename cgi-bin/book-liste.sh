#!/usr/bin/env bash

CSV="/var/www/html/Sounds-and-Stories/data/book-exchange.csv"

printf "Content-Type: text/html\r\n\r\n"

cat <<HTML
<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <title>Book Exchange – Übersicht</title>
  <style>
    body { font-family: Arial, sans-serif; }
    table { border-collapse: collapse; width: 100%; margin-top: 1em; }
    th, td { border: 1px solid #ccc; padding: 6px; }
    th { background: #f0f0f0; }
  </style>
</head>
<body>

<h1>📚 Book Exchange</h1>
<a href="../book-exchange.html">Zurück zum Formular</a>

<table>
HTML

# CSV lesen
IFS= read -r header_line || true

header_line="${header_line//$'\r'/}"
header_line="${header_line//$'\t'/}"

header_line="${header_line//$'\n'/}"

IFS=',' read -r -a header_cols <<< "$header_line"

  while IFS=',' read -r autor titel genre zustand sprache email plz ort; do
    echo "<tr>"
    echo "<td>$autor</td>"
    echo "<td>$titel</td>"
    echo "<td>$genre</td>"
    echo "<td>$zustand</td>"
    echo "<td>$sprache</td>"
    echo "<td>$email</td>"
    echo "<td>$plz</td>"
    echo "<td>$ort</td>"
    echo "</tr>"
  done
} < "$CSV"

cat <<HTML
</table>

</body>
</html>
HTML
