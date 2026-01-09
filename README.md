# Sounds & Stories – Semesterarbeit

Unser GLIN-Projekt enthält eine statische Website (HTML/CSS) sowie serverseitige Datenverarbeitung über CGI (Bash).

## Funktionen
- Musikmomente: Formular -> CGI -> Speicherung in `data/musikmomente.xml`
- Book Exchange: Formular -> CGI -> Speicherung in `data/book-exchange.csv`
- Anzeige: XML/CSV werden über separate CGI-Skripte als HTML dargestellt

## Ordnerstruktur (relevant)
- `cgi-bin/` enthält die Bash-CGI-Skripte
- `data/` enthält die persistierten XML/CSV-Dateien

## Hinweis zur Ausführung
GitHub Pages unterstützt nur statische Inhalte. CGI-Skripte (Bash) können dort nicht ausgeführt werden.
Für die Ausführung wird ein Apache-Webserver mit CGI-Unterstützung benötigt (z. B. FHGR Ausbildungsserver).

## CGI-Skripte
- Speichern:
  - `cgi-bin/musik-momente.sh`
  - `cgi-bin/book-exchange.sh`
- Anzeigen:
  - `cgi-bin/musik-liste.sh`
  - `cgi-bin/book-liste.sh`

## Server-Rechte (falls SSH/Terminal verfügbar)
```bash
chmod 755 cgi-bin/*.sh
chmod 775 data
chmod 664 data/book-exchange.csv
