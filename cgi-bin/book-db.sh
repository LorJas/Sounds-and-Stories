#!/usr/bin/env bash
set -euo pipefail

CSV_FILE="../data/book-exchange.csv"
printf "Content-Type: text/html; charset=UTF-8\r\n\r\n"

escape_html() {
  echo "$1" | sed \
    -e 's/&/\&amp;/g' \
    -e 's/</\&lt;/g' \
    -e 's/>/\&gt;/g' \
    -e 's/"/\&quot;/g' \
    -e "s/'/\&#39;/g"
}

cat <<'HTML'
<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Book Exchange – Datenbank (intern)</title>
  <link rel="stylesheet" href="../css/style.css">
</head>
<body>
  <header class="site-header">
    <div class="header-inner">
      <div class="brand">
        <span class="brand-title">Sounds &amp; Stories</span>
      </div>
    </div>
  </header>

  <main class="page">
    <section class="section">
      <h1 class="section-title">📚 Datenbank (intern)</h1>
      <p class="section-subtitle">Alle eingetragenen Felder (inkl. Kontakt & Adresse).</p>

      <div class="card">
        <div class="table-wrap">
          <table class="data-table">
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

if [[ ! -f "$CSV_FILE" ]]; then
  echo '<tr><td colspan="7"><i>Noch keine Einträge vorhanden.</i></td></tr>'
else
  tail -n +2 "$CSV_FILE" | while IFS= read -r line; do
    [[ -z "${line// /}" ]] && continue

    clean="${line%\"}"
    clean="${clean#\"}"
    IFS='","' read -r author title genre condition language contact shipping <<< "$clean"

    author="$(escape_html "${author:-}")"
    title="$(escape_html "${title:-}")"
    genre="$(escape_html "${genre:-}")"
    condition="$(escape_html "${condition:-}")"
    language="$(escape_html "${language:-}")"
    contact="$(escape_html "${contact:-}")"
    shipping="$(escape_html "${shipping:-}")"

    echo "<tr><td>$author</td><td>$title</td><td>$genre</td><td>$condition</td><td>$language</td><td>$contact</td><td>$shipping</td></tr>"
  done
fi

cat <<'HTML'
            </tbody>
          </table>
        </div>
      </div>

      <p class="list-link" style="margin-top:12px;">
        <a href="../book-exchange.html">← zurück</a>
      </p>
    </section>
  </main>
</body>
</html>
HTML
