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
  <title>Book Exchange – Öffentlich</title>
  <link rel="stylesheet" href="../css/style.css">
</head>
<body>
  <main class="page">
    <section class="section">
      <div class="card">
        <div class="table-wrap">
          <table class="data-table">
            <thead>
              <tr>
                <th>Autor</th>
                <th>Titel</th>
                <th>Genre</th>
                <th>Sprache</th>
              </tr>
            </thead>
            <tbody>
HTML

if [[ ! -f "$CSV_FILE" ]]; then
  echo '<tr><td colspan="4"><i>Noch keine Einträge vorhanden.</i></td></tr>'
else
  tail -n +2 "$CSV_FILE" | while IFS= read -r line; do
    [[ -z "${line// /}" ]] && continue

    clean="${line%\"}"
    clean="${clean#\"}"
    IFS='","' read -r author title genre condition language contact shipping <<< "$clean"

    author="$(escape_html "${author:-}")"
    title="$(escape_html "${title:-}")"
    genre="$(escape_html "${genre:-}")"
    language="$(escape_html "${language:-}")"

    echo "<tr><td>$author</td><td>$title</td><td>$genre</td><td>$language</td></tr>"
  done
fi

cat <<'HTML'
            </tbody>
          </table>
        </div>
      </div>
    </section>
  </main>
</body>
</html>
HTML
