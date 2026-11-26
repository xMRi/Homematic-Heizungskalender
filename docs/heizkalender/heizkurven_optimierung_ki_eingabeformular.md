# Eingabedaten zur HK2-Heizkurve und raumspezifische Vorheizparameter

Dieses Dokument enthält die Parameterstände und Auswertungszeiträume für die einzelnen Testläufe.

Es wird zusammen mit der **Optimierungsanleitung** und den zugehörigen Heizkalender-Logs eingereicht.

Jeder Testlauf enthält einen vollständigen Parametersatz. Frühere Testläufe bleiben unverändert, damit Änderungen zwischen den Testläufen nachvollziehbar sind.

Die für die Abschnitte B und C benötigten System- und Raumvariablen können mit dem [HK-Test-Skript](https://github.com/xMRi/Homematic-Heizungskalender/raw/refs/heads/main/Skripte/HK-Test-Skript.hsc) aus dem Projekt Homematic Heizungskalender ermittelt werden. Dazu das Skript auf der CCU ausführen und die benötigten Variablen aus dem letzten Teil der Testausgabe unverändert übernehmen. Keine Zugangsdaten übernehmen.

---

## Testlauf 1 [Datum]

### A – Auswertungszeitraum

- Von: [Datum]
- Bis: [Datum]

### B – Globale Standardwerte

- Scriptversion: [Version]
- Installationsdatum: [Datum]
- Referenz-Wohlfühltemperatur der HK2-Kurve ZT: [°C]

Folgende Systemvariablen aus der Ausgabe des Testskripts unverändert übernehmen:

```text
HK2-A.Temp.Grenze=
HK2-Grundtemperatur=
HK2-Kurve=
HK2-Kurvenanpassung=
HK2-Kurvenversatz=
HK2-VorzeitAus=
HK2-HKG-Liste=
```

### C – Raumparameter

Alle Zeilen beginnend mit `HKG-Raum-` aus dem letzten Teil der Testausgabe unverändert übernehmen, einschließlich der nicht zugeordneten Räume.

```text
[Hier Raumvariablen einfügen]
```

Keine vollständige Testausgabe übernehmen: Sie kann Zugangsdaten enthalten.

### D – Ergänzende Angaben

Besondere Raumeigenschaften, Heizungsart, maßgebliche Temperaturquelle und sonstige relevante Betriebsbedingungen, soweit bekannt. Unbekannte Angaben entsprechend kennzeichnen.

| Raum | Ergänzende Angaben |
|---|---|
| [Raumname] | [Angaben] |

---

## Testlauf 2 [Datum]

### A – Auswertungszeitraum

- Von: [Datum]
- Bis: [Datum]

### B – Globale Standardwerte

- Scriptversion: [Version]
- Installationsdatum: [Datum]
- Referenz-Wohlfühltemperatur der HK2-Kurve ZT: [°C]

Folgende Systemvariablen aus der Ausgabe des Testskripts unverändert übernehmen:

```text
HK2-A.Temp.Grenze=
HK2-Grundtemperatur=
HK2-Kurve=
HK2-Kurvenanpassung=
HK2-Kurvenversatz=
HK2-VorzeitAus=
HK2-HKG-Liste=
```

### C – Raumparameter

Alle Zeilen beginnend mit `HKG-Raum-` aus dem letzten Teil der Testausgabe unverändert übernehmen, einschließlich der nicht zugeordneten Räume.

```text
[Hier Raumvariablen einfügen]
```

Keine vollständige Testausgabe übernehmen: Sie kann Zugangsdaten enthalten.

### D – Ergänzende Angaben

Besondere Raumeigenschaften, Heizungsart, maßgebliche Temperaturquelle und sonstige relevante Betriebsbedingungen, soweit bekannt. Unbekannte Angaben entsprechend kennzeichnen.

| Raum | Ergänzende Angaben |
|---|---|
| [Raumname] | [Angaben] |

---

## Weitere Testläufe

Für jeden weiteren Testlauf wird der vollständige Block A, B, C und D mit fortlaufender Nummerierung ergänzt.

Die Angaben eines früheren Testlaufs werden nicht überschrieben. So bleibt die zeitliche Zuordnung der Parameter zu den Heizvorgängen erhalten.

## Änderungen zwischen den Testläufen

Die Änderungen der Parameter ergeben sich aus den dokumentierten Parametersätzen der aufeinanderfolgenden Testläufe.

Bei Bedarf können hier die Gründe für einzelne Änderungen, Abweichungen von den Empfehlungen der KI oder besondere Beobachtungen dokumentiert werden.

| Testlauf | Parameter / Raum | Änderung | Begründung / Bemerkung |
|---|---|---|---|
| [Nr.] | [Parameter / Raum] | [Alt → Neu] | [Begründung] |

Diese Angaben sind freiwillig. Die KI berücksichtigt sie bei der weiteren Analyse, sofern sie für die Bewertung und Optimierung relevant sind.