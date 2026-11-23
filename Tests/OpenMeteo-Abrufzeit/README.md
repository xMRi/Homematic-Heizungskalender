# R06: Open-Meteo-Abrufzeit

## Lokale Quelltextprüfung

Ab Projektstamm: `python3 Tests/OpenMeteo-Abrufzeit/test_source.py`

Die Prüfung liest das echte HSC-Skript und kontrolliert Schreibreihenfolge,
Objektprüfungen, Präfix, einmalige Zeitstempel-Schreibstelle und die vorhandenen
Fehlerzweige. Sie führt weder HSC noch HTTP-Anfragen aus. Sie ist kein Nachweis
für ReGa-Laufzeitverhalten oder einen erfolgreichen produktiven Abruf.

## Vertrag

`vrp # "HK2-Aussentemperatur-Abrufzeit"` ist eine optionale, manuell angelegte
Systemvariable vom Typ Zeichenkette mit leerem Startwert. Ihr Inhalt ist das lokale
CCU-Datum mit Uhrzeit im Format `YYYY-MM-DD HH:MM:SS` nach dem Schreiben der berechneten
Durchschnittstemperatur, nicht der Messzeitpunkt des Wetteranbieters.
Ein identischer Temperaturwert verhindert die Aktualisierung nicht.
Das Addon erwartet dieselbe lokale CCU-Zeitzone für ReGa und Tcl. Unixsekunden
und andere Altformate werden nicht unterstützt. Die doppelte lokale Stunde beim
Sommerzeitwechsel ist nicht eindeutig einem Unixzeitpunkt zuzuordnen.
Lokale Tests verwenden kontrolliert `TZ=UTC`; sie sichern keine Datumswerte
außerhalb des auf der CCU unterstützten Zeitbereichs zu.
Fehlt die optionale Variable, bleibt die Temperaturberechnung aktiv; vorhandenes
Logging beziehungsweise DEBUG meldet den fehlenden Zeitstempel.

Erfolg bedeutet hier: vorhandener Parser-Erfolgszweig mit `n!=0`, vorhandenes
Temperaturziel und ausgeführter `State(temp)`-Aufruf. Es gibt keine zusätzliche
Prüfung des Schreib-Rückgabewertes oder Funkzustands. Insbesondere prüft der
bestehende Parser `null` und andere ungültige Temperaturtokens nicht vollständig.
Diese Begrenzung bleibt unverändert; der Zeitstempel ist kein Gütesiegel für die
gesamte Antwort oder die Sensormessung. Fehlende Geokoordinaten, erkannte
Abruffehler, `n==0` und fehlendes Temperaturziel schreiben keinen Zeitstempel.

## Manuelle HSC-Prüfung, ausschließlich isolierte Testumgebung

Noch nicht ausgeführt. Keine Prüfung auf der produktiven Heizungssteuerung.
Eine separate CCU3/RaspberryMatic-Testumgebung ohne Aktorprogramme verwenden.
Eine Testkopie des Skripts mit eigenem Präfix `R06-Test-` und DEBUG=1 verwenden.
Nur dort Temperaturziel als Zahl und optionale Abrufzeit als Zeichenkette
anlegen. Eine kontrollierte Antwort durch einen lokalen Ersatz für die
`system.Exec(command, &stemp, &error)`-Zeile in der Testkopie einsetzen.
Eine Erfolgsvorgabe enthält mindestens 72 numerische Einträge mit Wert 10
im Array `"temperature_2m":[...]`, damit jedes Stundenfenster abgedeckt ist.

1. Abrufzeit leer: Erfolgsvorgabe ausführen. Durchschnitt ist 10,0 Grad;
   Abrufzeit entspricht `YYYY-MM-DD HH:MM:SS` und liegt zwischen den unmittelbar
   vor und nach Ausführung auf der Test-CCU gelesenen lokalen Datum-/Zeitwerten
   (außerhalb einer Zeitumstellung prüfen).
2. Nach mindestens einer Sekunde dieselbe Vorgabe erneut ausführen:
   Temperatur bleibt gleich, Zeitstempel steigt.
3. Abrufzeitvariable entfernen: Temperatur wird weiterhin geschrieben;
   DEBUG meldet fehlende optionale Variable, keine automatische Anlage.
4. Temperaturziel entfernen, Abrufzeit mit bekanntem Wert setzen:
   Wert bleibt unverändert, DEBUG meldet fehlendes Ziel.
5. Temperaturziel wieder anlegen, Abrufzeit mit bekanntem Wert setzen:
   Antwort ohne Temperaturarray beziehungsweise ohne schließende Arrayklammer
   vorgeben. Nach vorhandenen Wiederholungen bleibt Abrufzeit unverändert.
6. Antwort mit leerem Temperaturarray vorgeben: `n==0`, vorhandene
   Wiederholungen, Abrufzeit unverändert.
7. In der Testkopie `lat` leer setzen: Geokoordinaten-Abbruch, Abrufzeit
   unverändert, kein Abruf.
8. Alle Testvariablen tragen ausschließlich den Testpräfix; gleichnamige
   Variablen ohne Präfix dürfen in dieser Umgebung nicht verändert werden.

Ergebnisse mit Antwortvorgabe, CCU-/ReGa-Version, Uhrzeit, vorherigen/nachherigen
Variablenwerten und DEBUG-Ausgabe protokollieren. Die lokale Quelltextprüfung
ersetzt diese noch ausstehenden Laufzeitprüfungen nicht.
