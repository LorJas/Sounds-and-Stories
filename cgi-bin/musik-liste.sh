#!/usr/bin/env bash
set -euo pipefail

# --- Pfade
DATA_DIR="$(cd "$(dirname "$0")/../data" && pwd)"
CSV_FILE="$DATA_DIR/book-exchange.csv"

# --- HTTP Header
printf "Content-Type: text/html; charset=UTF-8\r\n\r\n"

cat <<'HTML'
<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <title>Book Exchange – Übersicht</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body { font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif; margin: 24px; }
    h1 { margin: 0 0 12px 0; }
    a { color: inherit; }
    .topbar { display:flex; align-items:center; gap:16px; margin-bottom: 14px; }
    .hint { color:#444; margin: 0 0 18px 0; }
    .table-wrapper { overflow-x: auto; border: 1px solid #ddd; border-radius: 10px; }
    table { border-collapse: collapse; width: 100%; min-width: 900px; }
    th, td { padding: 10px 12px; border-bottom: 1px solid #eee; vertical-align: top; text-align: left; }
    thead th { background: #f6f6f6; border-bottom: 1px solid #ddd; }
    tr:hover td { background: #fafafa; }
    .empty { padding: 14px; }
  </style>
</head>
<body>
  <div class="topbar">
    <h1>📚 Book Exchange</h1>
    <a href="../book-exchange.html">Zurück zum Formular</a>
  </div>
  <p class="hint">Hier siehst du alle eingereichten Buchangebote aus der CSV-Datei.</p>
HTML

# --- Falls CSV fehlt oder leer
if [[ ! -f "$CSV_FILE" ]] || [[ ! -s "$CSV_FILE" ]]; then
  cat <<'HTML'
  <div class="table-wrapper">
    <div class="empty">Noch keine Einträge vorhanden.</div>
  </div>
</body>
</html>
HTML
  exit 0
fi

# --- Tabelle starten
cat <<'HTML'
  <div class="table-wrapper">
    <table>
      <thead>
HTML

# --- Header-Zeile lesen und als <th> ausgeben
# (Header hat keine Quotes, aber wir behandeln ihn trotzdem robust)
{
  IFS= read -r header_line || true
  # header_line z.B.: Autor,Titel,Genre,Zustand,Sprache,E-Mail,Versandadresse

  echo "<tr>"
  IFS=',' read -r -a header_cols <<< "$header_line"
  for col in "${header_cols[@]}"; do
    # Quotes entfernen + HTML minimal entschärfen
    col="${col//\"/}"
    col="${col//&/&amp;}"
    col="${col//</&lt;}"
    col="${col//>/&gt;}"
    echo "<th>$col</th>"
  done
  echo "</tr>"

  cat <<'HTML'
      </thead>
      <tbody>
HTML

  # --- Datenzeilen lesen (7 Spalten!)
  # CSV wird von deinem book-exchange.sh so geschrieben:
  # "Autor","Titel","Genre","Zustand","Sprache","E-Mail","Versandadresse"
  while IFS=',' read -r autor titel genre zustand sprache email adresse; do
    # Leere Zeilen überspringen
    [[ -z "${autor}${titel}${genre}${zustand}${sprache}${email}${adresse}" ]] && continue

    # Quotes entfernen
    autor="${autor//\"/}"
    titel="${titel//\"/}"
    genre="${genre//\"/}"
    zustand="${zustand//\"/}"
    sprache="${sprache//\"/}"
    email="${email//\"/}"
    adresse="${adresse//\"/}"

    # HTML-Escaping (einfach, aber ausreichend für dein Projekt)
    for v in autor titel genre zustand sprache email adresse; do
      eval "$v=\"\${$v//&/&amp;}\""
      eval "$v=\"\${$v//</&lt;}\""
      eval "$v=\"\${$v//>/&gt;}\""
    done

    echo "<tr>"
    echo "<td>$autor</td>"
    echo "<td>$titel</td>"
    echo "<td>$genre</td>"
    echo "<td>$zustand</td>"
    echo "<td>$sprache</td>"
    echo "<td>$email</td>"
    echo "<td>$adresse</td>"
    echo "</tr>"
  done
} < "$CSV_FILE"

# --- Tabelle/Seite schließen
cat <<'HTML'
      </tbody>
    </table>
  </div>
</body>
</html>
HTML
