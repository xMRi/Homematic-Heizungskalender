# Raumtemperaturfilter der Heizkurvenanzeige

Ausführen mit Python 3 und lokalem `tclsh`, ohne zusätzliche Python-Pakete:

```sh
python3 -B Tests/Addon-Heizkurven-Raumtemperatur/test_filter.py
```

Der Test ermittelt seine Quellen anhand des eigenen Dateipfads und ist unabhängig vom Arbeitsverzeichnis. Er führt die vollständige echte `hkkurve.cgi` unverändert aus. Synthetische Logdaten stehen inline in der Testquelle; temporäre Dateien entstehen ausschließlich unter `build/` und werden anschließend entfernt.

Der Tcl-Harness initialisiert die benötigten Uhrzeitformate vor Installation der Sicherheitsmocks; dabei darf Tcl seine lokale Standardbibliothek lesen. `HOME` zeigt auf das temporäre Testverzeichnis unter `build/`, nicht auf das Benutzerverzeichnis. Anschließend ersetzt er `load`, ReGa, Uhrzeit, Dateisuche und `exec grep`. Der grep-Aufruf liefert ausschließlich synthetische Daten. Alle `open`-Aufrufe der CGI sind gesperrt, auch der optionale VERSION-Zugriff. Es werden keine CCU-Dateien gelesen und keine Betriebssystem- oder Sensorbefehle ausgeführt. Die feste Uhrzeit ist der 23.11.2026 um 12:00 UTC.

Geprüft werden Standardzustand, aktivierte Checkbox, ungültige Flagwerte, Formularreihenfolge und Auswahlzustand, moderne und bereits unterstützte alte Raumformate, kombinierte Raum-/Zeit-/Ereignisfilter, die 24-Stunden-Grenze, unveränderte andere Ereignisse sowie vorhandenes HTML-Escaping von Raumnamen und Fehlertexten. Nur das exakte Ereignis `Raumtemperatur` darf ausgeblendet werden.

Die Tests sind lokale Ausgabeprüfungen mit Mocks, kein CCU-Laufzeitnachweis und kein Nachweis der Tcl-8.2.3-Kompatibilität. Sie prüfen weder echte grep-Dateizugriffe noch Sensorwerte, Funkverhalten, Browserdarstellung oder die CCU-Zeichenkodierung.
