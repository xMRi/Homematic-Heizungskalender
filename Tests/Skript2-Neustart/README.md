# Neustart und Temperaturwert 0°C

## Lokale Prüfungen

Vom Projektstamm, ohne zusätzliche Abhängigkeiten:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 Tests/Skript2-Neustart/pruefung.py
PYTHONDONTWRITEBYTECODE=1 python3 Tests/Skript2-Neustart/isoliert.py
git diff --check -- 'Skripte/HK-Skript 2.hsc' Tests/Skript2-Neustart/
```

`pruefung.py` prüft den Quelltext statisch und ein ausdrücklich separates Python-Referenzmodell. Es führt kein HSC aus. Quellnachweise: sechs einzigartige Laufzeitvariablen, keine Zeichenschleife und Konvertierung nur bei vorhandenem ersten Leerzeichenfeld ohne stderr. Fälle: Grenze 3599/3600 Sekunden, alte Einträge davor/danach, sofort nutzbare Messwerte einschließlich negativer Temperaturen, fehlendes Feld, leere/nichtpositive Laufzeit und stderr, einmaliges Lesen pro Lauf, GT oberhalb/unterhalb AT, Schätzwerte null/negativ, Außentemperaturgrenze und Sensorerholung vor beziehungsweise nach Heizbeginn.

Das Modell verwendet nur reguläre numerische Kerneltexte sowie die definierten Fehler- und Leerfälle. Python-`float` bildet HSC-`ToFloat` für beliebig beschädigte Zahlenstrings nicht nach. Deren Ablehnung wird weder behauptet noch getestet; die produktive Zeichenprüfung wurde bewusst entfernt.

`isoliert.py` extrahiert Deklarationen und den echten 0°C-Zweig aus Skript 2 nach `build/neustart-isoliert.hsc`. Das nicht versionierte `build/` wird bei Bedarf angelegt, sodass der Generator auch in einem frischen Snapshot funktioniert. Nur zwei Anpassungen am Zweig: Protokollausgaben verwenden `WriteLine`, der Betriebssystemaufruf verwendet Fake-stdout/stderr und einen Lesezähler. Alle Eingaben sind lokale Variablen. Zwei Wiederholungen je Fall zeigen die Zwischenspeicherung, alte Einträge werden unverändert angehängt. Bei Warten oder Übernahme fehlt `NORMALE-FORTSETZUNG`; bei Ersatzberechnung erscheint der Schätzwert. `LESEZAHL` muss null bei vorhandenem Eintrag oder Messwert sein, sonst eins. Dies ist eine vorbereitete HSC-Prüfvorlage, kein lokal ausgeführter HSC-Test.


## Grenzen und Sicherheit

Kein CCU-Zugriff während dieser Prüfungen. Keine produktiven Objekte, Systemvariablen oder Aktoren in die Vorlage einsetzen; weder Neustarts noch Sensorfehler an der laufenden Heizung experimentell erzeugen. Eine spätere isolierte HSC-Ausführung erfordert gesonderte Freigabe und darf ausschließlich diese Fake-/WriteLine-Vorlage verwenden.

Die Vorlage prüft weder Sensorzugriffe noch die vollständige Vorheizberechnung, ATG oder den vorgezogenen Bestandsschutz begonnener Heizphasen. Diese bleiben bestehender Produktivcode, ihre Entscheidungswirkung wird nur statisch beziehungsweise im Referenzmodell geprüft. Syntax und Laufzeit auf Tcl sind hier nicht relevant; Python-Erfolg ist kein CCU-/ReGa-Kompatibilitätsnachweis. Kernellaufzeit erkennt keinen alleinigen ReGa-Neustart. Auch reale 0°C werden absichtlich als fehlender Messwert behandelt. Unlesbare Laufzeit bleibt ein Wartefall ohne Ersatzberechnung.
