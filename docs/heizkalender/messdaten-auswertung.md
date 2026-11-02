# Messdaten-Auswertung

Die CCU3 zeichnet laufend Messwerte (Temperatur, Luftfeuchte etc.) auf und speichert
sie als Diagrammdaten. Diese Seite beschreibt, wie man die Messdaten exportiert und
extern auswertet — etwa um Vorheizzeiten zu kontrollieren, Heizkurven zu optimieren
oder Temperaturverläufe über längere Zeiträume zu analysieren.

## RRD4J-Diagrammdaten exportieren

Die CCU3 speichert Messwerte im RRD4J-Format unter
`/media/usb0/measurement/` (bei USB-Speicher) bzw. `/usr/local/sdcard/measurement/`.
Die `.rrd`-Dateien lassen sich mit dem enthaltenen Tool `DumpRRD.java` nach XML
konvertieren, um sie extern auszuwerten.

### Voraussetzungen

- Java Runtime auf dem auswertenden Rechner (nicht auf der CCU)
- Die Bibliothek [`rrd4j-3.10.jar`](https://mvnrepository.com/artifact/org.rrd4j/rrd4j/3.10) (oder neuer)
- Die `.rrd`-Dateien von der CCU kopieren (z.B. per SCP)

### Dateien von der CCU kopieren

```bash
scp -r root@192.168.2.130:/media/usb0/measurement/ logs/measurement/
```

### Nutzung

```bash
# rrd4j-3.10.jar und DumpRRD.java in dasselbe Verzeichnis wie die .rrd-Dateien legen
java -cp ./rrd4j-3.10.jar DumpRRD.java <eingabe.rrd> <ausgabe.xml>
```

Beispiel:

```bash
java -cp ./rrd4j-3.10.jar DumpRRD.java 22.rrd 22.xml
```

### XML-Struktur

Die exportierte XML-Datei enthält:

- **Data Sources (`<ds>`)**: Die Sensoren/Kanäle, z.B. `HEQ0105582:1_5` (Kanal 1, Datenpunkt 5)
- **Round Robin Archives (`<rra>`)**: Mehrere Archive pro Datei mit unterschiedlicher Auflösung:

| Auflösung | Typ | Zeitraum ca. |
|-----------|-----|-------------|
| 2,5 min (step×1) | AVERAGE, MAX, MIN | 3 Tage |
| 30 min (step×12) | AVERAGE, MAX, MIN | 31 Tage |
| 6 h (step×144) | AVERAGE, MAX, MIN | 1 Jahr |
| 24 h (step×576) | AVERAGE, MAX, MIN | 5 Jahre |

Zeitstempel in der XML-Datei sind **UTC**. Für die Anzeige in Lokalzeit (Europe/Berlin)
muss die Zeitzone berücksichtigt werden.

### Welche Datei enthält welche Sensoren?

Die Zuordnung Dateiname → Sensoren ergibt sich aus der Diagramm-Konfiguration auf der
CCU (Einstellungen → Diagramme). Die Dateinummer entspricht der internen Diagramm-ID.
