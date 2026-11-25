# Termindetails der Raumübersicht

Vom Projektstamm, ohne zusätzliche Bibliotheken (Python 3, lokales Tcl und Node.js erforderlich):

```sh
python3 Tests/Addon-index-Termine/test_index.py
node Tests/Addon-index-Termine/test_index.js
node --check Tests/Addon-index-Termine/test_index.js
python3 -c 'import ast; from pathlib import Path; ast.parse(Path("Tests/Addon-index-Termine/test_index.py").read_text())'
```

Python führt die echte `index.cgi` mit einem Tcl-Stub für `load`, ReGa und die aktuelle Uhrzeit aus. UTC und der 25.11.2026 um 12:00 Uhr sind fest vorgegeben. Die zwölf HTML-Fälle umfassen keine Räume sowie null, einen und mehrere Termine in bis zu zwei Räumen, jeweils mit und ohne `HK2-Schaltzeiten`. Der HTMLParser prüft offene Termindetails, chronologische Reihenfolge einschließlich abgelaufener Termine, die markierte Checkbox im Termin-Spaltenkopf und die externe Skripteinbindung. Das Label „Alle aufklappen“ bleibt ohne JavaScript verborgen; der Titel „Termin“ bleibt vorhanden. Die globale Checkbox erscheint nur bei Mehrfachterminen, nicht je Raumzeile. Es gibt keinen separaten Filterfeldsatz.

Node führt die echte `index.js` mit `assert` und `vm` aus. Der minimale DOM-Mock bildet ausschließlich verwendete Attribute, Selektoren, Checkboxzustände und Ereignislistener ab. Alle offenen Details markieren die Checkbox, alle geschlossenen demarkieren sie. Bei gemischten Details gilt `checked=false` und `indeterminate=true`; die nächste Aktivierung öffnet alle. Vor einem ausdrücklich ausgelösten `change` wird der native Checkboxwechsel synthetisch nachgebildet. Auch Detail-Toggle-Ereignisse werden ausdrücklich ausgelöst; Browser-Ereigniswarteschlange, Rendering, CSS, Barrierefreiheit und Netzabruf werden nicht simuliert. Neuinitialisierung erfolgt mit einem neuen serverseitig offenen DOM, ohne Speicher-API.

Sechs zusätzliche HTML-Fälle prüfen die Reihenfolge Temperaturinformation, Raumtabelle und gegebenenfalls Erklärung zu „Vorlauf“ und „Heizen ab“. Temperaturinformation (`p.hk-hint`) oberhalb der Tabelle und Erklärung (`div.hk-hint`) unterhalb bleiben getrennte Elemente. Ohne Räume steht die Temperaturinformation vor der Leermeldung, ohne Vorlauf-Erklärung. Varianten ohne Wetter und nur mit Abrufhinweis sind eingeschlossen. Die früheren Elemente `hk-index-controls` und `hk-termine-filter` dürfen nicht mehr vorkommen. Die bestehende Zwölf-Fälle-Matrix prüft diese Struktur ebenfalls.

Dies sind lokale Tcl-/DOM-Mocktests, kein Nachweis für Tcl 8.2.3, die CCU oder einen echten Browser. Die Tests prüfen die HTML-Struktur, nicht CSS oder einen Browserrenderer. Responsiver Umbruch bleibt einer gesonderten Layout-Quelltextprüfung vorbehalten; auch diese ist kein echter Browsernachweis. Keine produktiven Schreibzugriffe.
