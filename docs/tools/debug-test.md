# Tools/Debug+Test

Dieser Ordner enthält optionale Zusatz-Skripte rund um den Heizkalender. Sie sind
für den Betrieb nicht zwingend nötig, erleichtern aber Diagnose, Wartung und
Auswertung.

**Diese Skripte werden im Allgemeinden auf der CCU manuell per „Skript testen" ausgeführt.**

## Logging und Auswertung

| Skript | Zweck |
| :--- | :--- |
| `Tool-Log des Heizkalenders ausgeben` | Gibt das Systemprotokoll des Heizkalenders (HK-Log/HK1-Log/HK2-Log) aus. |
| `Tool-Log der Heizkurvenkontrolle ausgeben` | Gibt die Protokolleinträge der Heizkurvenkontrolle aus (Start/Ziel/Ende der Heizphasen). |
| `Tool-Raumvariablen als Tabelle` | Listet alle `HKG-Raum-*`-Variablen als Markdown-Tabelle auf. |

## Diagnose

| Skript | Zweck |
| :--- | :--- |
| `Tool-Diagnose Raumzuordnung ChurchTools` | Prüft die Zuordnung von ChurchTools-Ressourcen zu Raumvariablen. |
| `Tool-Diagnose Geraetereferenzen` | Prüft die in den Raumvariablen referenzierten Aktoren/Geräte. |

## Wartung und Betrieb

| Skript | Zweck |
| :--- | :--- |
| `Tool-Heizgruppen eTRV Modus setzen` | Sonderfall: setzt `CONTROL_MODE` direkt auf allen `HmIP-eTRV`-Einzelthermostaten, nicht auf der Gruppenadresse. Nur nötig wenn ein Thermostat nach einem Firmware-Update den Gruppenmodus nicht übernommen hat. |
| `Tool-HMIPServer Neustart` | Startet den HMIPServer (Java-Prozess) neu. Nötig nach dem Anlegen, Umbenennen oder Löschen von Diagrammen, da sonst ein interner Fehler (RRD already closed) dazu führt, dass Diagramme keine Daten mehr anzeigen. Kann auch als zeitgesteuertes CCU-Programm (z.B. nächtlich) eingesetzt werden. |

## CloudMatic-Diagramme

Skripte zum Sichern, Dumpen und Wiederherstellen der CloudMatic-Diagrammdaten:
`Tool-CloudMatic Diagramm Daten sichern`, `Tool-CloudMatic Diagramm-Dump`,
`Tool-CloudMatic Diagramm-Load`.

## Sonstige Hilfsmittel

`Sammlung-Hilfs-Skripte` enthält einige hilfreiche Skript Snippets.

Weitere Werkzeuge für seltene oder umgebungsspezifische Aufgaben sowie eine Sammlung von
Test-Skripten:

- `Tool-Test Raumvariable auslesen`
- `Tool-Test Raumvariable setzen`
- `Test-Temperatur Verschiebung berechnen`
- `Tool-Test Thermostatgruppe auslesen`
- `Tool-Test Thermostatgruppe schalten`

> [!WARNING]
> Die Skripte `Tool-Alle Systemvariablen löschen` und `Tool-Alle Systemvariablen und Programme löschen` entfernen unwiderruflich Daten aus der CCU.<br>
> Diese Skripte sollten nur mit Bedacht und nach einem Backup verwenden werden. Sie dienen dazu Testmaschinen zu säubern oder zu bereinigen, ohne die Gerätezuordnungen zu beeinflussen.<br>
> **Diese Programme sind wirklich nur mit äußerster Vorsicht und Expertenwissen zu benutzen.**<br>
> Um eine versehentliche Nutzung zu verhindern wurde der `quit`-Befehl am Anfang der Skripte ergänzt. Dieser muss vor der Ausführung bewusst entfernt werden.
