# Google-Abruffenster

Vom Projektstamm ausführen:

```sh
python3 Tests/Skript1_Google-Abruffenster/test_abruffenster.py
```

Voraussetzungen: Python 3.9 oder neuer mit Standardbibliothek `zoneinfo` und lokal verfügbaren IANA-Zeitzonendaten für `Europe/Berlin`. Fehlende Zeitzonendaten führen zu einem Testfehler. Keine zusätzlichen Python-Pakete oder Git-Metadaten erforderlich.

Der Test findet die produktive HSC-Datei relativ zur eigenen Datei im vollständigen Quellbaum, unabhängig vom aktuellen Arbeitsverzeichnis.

## Umfang und Grenzen

- Fünf Quellstrukturprüfungen: Deklarationen und Initialisierungsreihenfolge, negative Ausschaltverschiebungen im Raumverbund, Tagesgrenzen und Erweiterung um eine Sekunde, Zeitzonenoffset je Grenze mit `%2B`-Kodierung sowie Hinweis auf Teilseiten ohne Abbruch oder Seiteniterator im Hinweisblock. Die vorhandene Terminiteration und Schaltlistenveröffentlichung werden auf ihr Vorhandensein geprüft, nicht vollständig simuliert.
- Fünf Python-Referenzfälle: normales Zweitagesfenster, 90 Minuten Nachlauf über Mitternacht, langer Vorlauf sowie Sommerzeitbeginn und Sommerzeitende mit unterschiedlichen Offsets an den Grenzen.

Das Referenzmodell verwendet UTC-Sekundenarithmetik und lokale Tagesgrenzen. Die Quellprüfungen binden es an die vorhandenen HSC-Ausdrücke, tolerieren aber keine beliebigen gleichwertigen Umformulierungen. Bei Änderungen am Algorithmus müssen Modell und Quellprüfungen gemeinsam geprüft werden.

Dies ist kein HSC-Interpreter, kein CCU-Laufzeittest und kein Google-API-Test. Insbesondere sind die Zielplattformsemantik von `ToTime`, `Format("%z")` und Operatorauswertung sowie die tatsächliche API-Antwortverarbeitung damit nicht nachgewiesen. Der Test liest ausschließlich die lokale Quelle und verändert keine Heizungsdaten.
