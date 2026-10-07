# Tools

Dieser Ordner enthält optionale Zusatz-Skripte rund um den Heizkalender. Sie sind
für den Betrieb nicht zwingend nötig, erleichtern aber Diagnose, Wartung und
Auswertung. 

Diese Skripte können als eigenes Programm in der CCU installiert werden.

## Wartung und Betrieb

| Skript | Zweck |
| :--- | :--- |
| `Tool-CloudMatic Diagramm Daten sichern` | Mit diesem Skript lassen sich aufgezeichnete CloudMatic Daten in entsprechenden Textdateien für eine spätere Auswertung archivieren.<br>Nutzung macht nur Sinn, wenn CloudMatic Diagramm Daten über einen längeren Zeitpunkt ausgewertet werden sollen. |
| `Tool-Heizgruppen Modus zurücksetzen` | Setzt den Modus aller `HmIP-HEATING`-Heizgruppen auf Manuell oder Auto. Die Heizgruppe überträgt den Modus automatisch auf die zugehörigen Thermostate. Dieses Programm dient speziell dazu das versehentliche Umschalten von Thermostaten in einen anderen Modus rückgängig zu machen. Hier können auch spezielle Ausnahmen definiert werden.<br>Das Programm sollte Nachts einmal laufen. |
| `Tool-Gestörte Kommunikation beheben` | Behebt Kommunikationsstörungen (UNREACH) und überträgt ausstehende Konfigurationsdaten (CONFIG_PENDING) an Geräte. Eignet sich als nächtliches Wartungsprogramm.<br>Das Programm sollte stündlich einmal laufen. |
| `Tool-Servicemeldungen automatisch bestätigen` | Bestätigt Servicemeldungen der CCU automatisch. Eignet sich als automatisches Wartungsprogramm.<br>Für die Installation des Programmes sollte folgender Trigger verwendet werden:<br>Wenn "Systemzustand" "Servicemeldungen" im Wertebereich "größer als" 0 bei Aktualisierung auslösen |
| `Tool-Uptime loggen` | Protokolliert die Laufzeit der CCU.<br>Das Programm sollte alle 3h einmal laufen. |

Im Dateikopf der Programme finden sich weitere Informationen und Hinweise.

Die folgenden Programme sollten zusätzlich installiert werden, um einen vollkommen unbeaufsichtigten Betrieb zu ermöglichen:<br>
`Tool-Heizgruppen Modus zurücksetzen`<br>
`Tool-Gestörte Kommunikation beheben`<br>
`Tool-Servicemeldungen automatisch bestätigen`

## Sonstige Hilfsmittel

Weitere Werkzeuge für seltene oder umgebungsspezifische Aufgaben:

| Skript | Zweck |
| :--- | :--- |
| `Tool-WakeOnLAN BeamerPC` | Beispiel Programm mit dem man einen oder mehrere Rechner über ein Skript aufwecken kann. Dieses Programm könnte zum Beispiel über die CloudMatic angestoßen werden.|

> [!WARNING]
`Tool-Reboot` startet die CCU neu. Das Skript muss unbedingt mit einem zeitlichen Trigger versehen werden. Geschieht dies nicht, dann kann dies zu einem endlosen Reboot der CCU führen.
In Zeile 19 wurde aus Sicherheitsgründen auch ein zusätzlicher `quit` Befehl eingebaut um eine versehentliche Nutzung auszuschließen. Der `quit` Befehl muss entfernt werden um diese Skripte zu benutzen.