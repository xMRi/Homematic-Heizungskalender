# Heizsteuerung — Vorheizzeit-Logik

Dieses Dokument erklärt, wie das Hauptskript `HK-Skript 2` den Einschaltzeitpunkt der Heizung
berechnet. Es geht dabei nicht um eine Vorlauftemperatur, sondern um eine **ereignisgesteuerte
Zeitsteuerung**: Das Skript berechnet, wie viele Minuten vor einem Termin die Heizung eingeschaltet
werden muss, damit der Raum pünktlich die gewünschte Temperatur erreicht.

## Verarbeitungskette

```txt
Kalender-Skript 1  -->  Schaltliste (HK1-Schaltliste)  -->  Hauptskript 2
                                                                    |
Außentemperatur-Skript  -->  HK2-A.Temp  ------------------------>  |
                                                                    v
                                                           Einschaltzeitpunkt
                                                           berechnen + schalten
```

Das Skript 2 läuft alle **5 Minuten** und trifft die Heizentscheidung jedes Mal neu:

- Liegt der berechnete Einschaltzeitpunkt in der Vergangenheit?
- Liegt der Ausschaltzeitpunkt (Terminende) noch in der Zukunft?
- Ist die aktuelle Außentemperatur unter der konfigurierten Grenze?

Erst wenn alle drei Bedingungen erfüllt sind, wird die Heizung eingeschaltet.

## Systemvariablen (Konfiguration)

| Variable | Bedeutung | Beispielwert |
| :--- | :--- | :--- |
| `HK2-Grundtemperatur` | Absenktemperatur wenn nicht geheizt wird | 10,0 °C |
| `HK2-A.Temp.Grenze` | Heizen wird gestoppt wenn Außentemperatur ≥ Grenze | 19,0 °C |
| `HK2-A.Temp` | Aktuelle Außentemperatur (von Außentemperatur-Skript) | 8,0 °C |
| `HK2-Kurve` | Vorheizzeit-Kurve: 8 Werte für 8 Außentemperatur-Stützpunkte | siehe unten |
| `HK2-VorzeitAus` | Globaler Grund-Offset zum vorzeitigen Ausschalten (Minuten); gilt nur für echte Heizvorgänge, nicht für reine Schaltrelais | 0 min |

## Die Vorheizzeit-Kurve

Die Kurve besteht aus **8 Stützpunkten**, die die volle Vorheizzeit (bei unbeheiztem Raum)
für verschiedene Außentemperaturen angeben. Zwischen den Stützpunkten wird **linear interpoliert**.
Für Außentemperaturen über 17,5 °C extrapoliert das Skript über den letzten Abschnitt hinaus
(begrenzt auf mindestens 0 Minuten).

| # | Außentemperatur | Volle Vorheizzeit | (in h:min) |
| :---: | ---: | ---: | ---: |
| 1 | −10 °C | 451 min | 7 h 31 min |
| 2 | −5 °C | 370 min | 6 h 10 min |
| 3 | 0 °C | 297 min | 4 h 57 min |
| 4 | 8 °C | 196 min | 3 h 16 min |
| 5 | 10 °C | 174 min | 2 h 54 min |
| 6 | 12 °C | 154 min | 2 h 34 min |
| 7 | 15 °C | 125 min | 2 h 05 min |
| 8 | 17,5 °C | 103 min | 1 h 43 min |

_Diese Werte entsprechen der großzügigen Beispielkonfiguration (`451;370;297;196;174;154;125;103`). Bei der Installation werden sie individuell gesetzt._

## Die Berechnungsformel

Die tatsächliche Vorheizzeit ergibt sich aus dem Kurvenwert multipliziert mit einem
**Korrekturfaktor**, der die aktuelle Raumtemperatur berücksichtigt:

```txt
Vorheizzeit = Kurvenwert(Außentemperatur) × Korrekturfaktor

Korrekturfaktor = 1 − 0,6 × ( (Raumtemperatur − Grundtemperatur) / (Wohlfühltemperatur − Grundtemperatur) )
                              └─ Raumtemperatur wird auf max. Wohlfühltemperatur begrenzt ─┘

Minimum: 0,20 (20 %) — es wird immer mindestens 20 % der Kurvenzeit vorgeheizt
```

**Bedeutung der Parameter:**

| Parameter | Bedeutung |
| :--- | :--- |
| Raumtemperatur | Aktuelle Temperatur laut Thermostat im Raum |
| Grundtemperatur | Absenktemperatur (`HK2-Grundtemperatur`), z. B. 10 °C |
| Wohlfühltemperatur | Gewünschte Zieltemperatur laut Schaltliste, z. B. 20 °C |
| Faktor 0,6 | Fixer Anpassungsfaktor (im Skript hardcodiert) |

**Beispielrechnungen:**

| Raumtemperatur | Korrekturfaktor | Vorheizzeit bei 8 °C Außentemp. (196 min) |
| ---: | ---: | ---: |
| 10 °C (= Grundtemperatur) | 1,00 (100 %) | 196 min (3 h 16 min) |
| 15 °C | 0,70 (70 %) | 137 min (2 h 17 min) |
| 18 °C | 0,52 (52 %) | 102 min (1 h 42 min) |
| 20 °C (= Wohlfühltemperatur) | 0,40 (40 %) | 78 min (1 h 18 min) |
| ≥ 20 °C (wärmer als Ziel) | 0,40 (40 %, gedeckelt) | 78 min (1 h 18 min) |

## Die zwei Anteile der Einschaltverschiebung

Der tatsächliche Einschaltzeitpunkt verschiebt sich durch **zwei** getrennt
berechnete Offsets, die beide vom Terminbeginn abgezogen werden:

| Anteil | Herkunft | Verhalten |
| :--- | :--- | :--- |
| **Fester/raum-individueller Offset** | Feld „Vorheizzeit" der Raumvariablen (optional mit `*Faktor`) plus globaler `HK2-Kurvenversatz` | Fester Minutenwert, unabhängig von der Außentemperatur |
| **Temperaturabhängiger Offset** | Kurvenwert aus `HK2-Kurve` (siehe oben), skaliert mit dem Raumtemperatur-Korrekturfaktor | Hängt von Außen- und Raumtemperatur ab |

Beide Anteile werden addiert. Der globale `HK2-Kurvenversatz` wirkt dabei als
Gegenstück zu `HK2-VorzeitAus` (Ausschalt-Offset) und wird **nur bei echten
Heizvorgängen** berücksichtigt, nicht bei reinem Schalten (Modus `S`).

## Sonderfälle

### Außentemperatur-Grenze (harter Schalter)

Ist die aktuelle Außentemperatur **größer oder gleich** der konfigurierten Grenze (`HK2-A.Temp.Grenze`),
wird die Heizung unabhängig von Termin und Raumtemperatur **nicht eingeschaltet** bzw. sofort
**ausgeschaltet**. Diese Prüfung erfolgt bei jedem 5-Minuten-Lauf neu — ändert sich die
Außentemperatur während eines Termins, reagiert das Skript entsprechend.

Systemprotokoll-Eintrag: _„Heizen abgebrochen Aussentemperatur 21,0 °C größer Grenzwert 19,0 °C“_

### Raum wärmer als Wohlfühltemperatur (40-%-Deckelung)

Ist der Raum bereits wärmer als die gewünschte Wohlfühltemperatur, wird die Raumtemperatur
in der Formel auf die Wohlfühltemperatur **begrenzt**. Der Korrekturfaktor sinkt damit auf
sein Minimum von **0,40 (40 %)**. So wird bei einem bereits warmen Raum immer noch ein
Mindest-Vorlauf sichergestellt — wichtig bei trägen Heizsystemen wie Fußbodenheizungen.

### Kein Thermostat im Raum (Fallback auf Grundtemperatur)

Ist für einen Raum kein Thermostat konfiguriert, kennt das Skript die aktuelle Raumtemperatur
nicht. In diesem Fall wird die **Grundtemperatur** als Raumtemperatur angenommen.

Konsequenz: Der Zähler der Formel wird 0, der Korrekturfaktor beträgt **1,00 (100 %)**,
es wird immer die volle Kurvenzeit vorgeheizt. Dies ist der sicherste Fallback,
führt aber bei niedrig konfigurierter Grundtemperatur zu sehr langen Vorlaufzeiten.

### Übertemperatur im Raum (Modus HS)

Im Modus **HS** (erster Aktor = Thermostat als Temperatursensor, weitere Aktoren = Schaltrelais)
liest das Skript die Raumtemperatur vom Thermostat — nutzt sie aber **ausschließlich** für
die Vorheizzeit-Berechnung (Korrekturfaktor). Die Schaltrelais werden anschließend
**hart ein- bzw. ausgeschaltet**, ohne Rücksicht auf die aktuelle Raumtemperatur.

Das Skript hat keine „Raum zu warm → Relais aus“-Logik. **Sind zum Beispiel durch viele Gäste
bereits 24 °C im Saal erreicht, schalten die Heizrelais trotzdem ein.**

Der einzige Schutz gegen unnötiges Heizen in diesem Fall:

- Die **Außentemperatur-Grenze**: Ist es draußen ≥ 19 °C, wird gar nicht geheizt.
- Das **vorzeitige Heizende**: Die Heizung schaltet bereits 30 min vor Terminende ab.
- Die **Vorheizzeit-Deckelung**: Bei 24 °C wird der Korrekturfaktor auf 0,40 (40 %) begrenzt —
  die Relais schalten also später ein als bei einem kalten Raum, aber sie schalten dennoch ein.

| Modus | Schutz bei Übertemperatur im Raum |
| :--- | :--- |
| **H** (Thermostat) | ✔ Thermostat regelt selbst — Ventil bleibt bei Übertemp. geschlossen |
| **S** (reines Relais) | ✖ Kein Schutz — kein Temperatursensor vorhanden |
| **HS** (Thermostat + Relais) | ⚠ Thermostat misst, aber Relais schalten trotzdem ein |

## Vorzeitiges Heiz-/Schaltende

Neben dem Einschaltzeitpunkt kann das Skript die Heizung auch **vor dem Terminende** abschalten.
Dafür gibt es zwei Offsets in Minuten, die beide vom Terminende abgezogen werden:

| Offset | Konfiguration | Aktueller Wert |
| :--- | :--- | :--- |
| **Raum-individuell** | In der `HeizkalenderInstallation.exe` pro Raum (Feld „Vorzeit Aus“) | 30 min (alle Räume) |
| **Global** | Systemvariable `HK2-VorzeitAus` | 0 min |

```txt
Ausschaltzeitpunkt = Terminende − (Raum-Offset + globaler Grund-Offset)

Beispiel Saal:       Terminende 22:00 − 30 min = 21:30
Beispiel Kellerbüro: Terminende 18:00 − 30 min = 17:30
```

**Hinweise:**

- Der raum-individuelle Offset gilt unabhängig von der Außentemperatur.
- Der globale Offset (`HK2-VorzeitAus`) wird **nur bei echten Heizvorgängen** berücksichtigt, nicht bei reinen Schaltrelais.
- Zweck: Die Wärmeträgheit hält den Komfort bis Terminende aufrecht, obwohl die Heizung früher abschaltet. Spart Energie.

## Use Cases

Die folgenden drei Beispiele zeigen das Zusammenspiel aller Faktoren an einem konkreten Tag.

**Gemeinsame Rahmenbedingungen:**

| Parameter | Wert |
| :--- | :--- |
| Grundtemperatur | 10,0 °C |
| Außentemperatur-Grenze | 19,0 °C |
| Wohlfühltemperatur | 20,0 °C |
| Vorheizzeit-Kurve bei 8 °C | 196 min |
| Vorheizzeit-Kurve bei 18,6 °C (interpoliert) | 93 min |

**Außentemperatur-Verlauf des Tages:**

- Morgens: 8 °C
- Ab ca. 13:42 Uhr: ≥ 19 °C (Grenze überschritten)
- 14:00 Uhr: 21 °C
- 18:00 Uhr: 20 °C
- 19:00 Uhr: 18,6 °C

### Use Case 1 — Saal (mit Thermostat, Termin 19:00–22:00)

| Parameter | Wert |
| :--- | :--- |
| Raumtemperatur | 21,1 °C (Thermostat) |
| Außentemperatur um 19:00 Uhr | 18,6 °C |
| Heizen erlaubt? | Ja (18,6 °C < 19 °C) |
| Raumtemperatur in Formel | 20,0 °C (auf Wohlfühltemperatur gedeckelt) |
| Korrekturfaktor | 1 − 0,6 × ((20−10)/(20−10)) = **0,40** |
| Kurvenwert bei 18,6 °C | ~93 min (interpoliert) |
| Vorheizzeit | 0,40 × 93 ≈ **37 min** |
| Einschaltzeitpunkt | ~18:23 Uhr |
| Ausschaltzeitpunkt | 21:30 Uhr (22:00 − 30 min) |

```txt
Zeitachse:
  ~18:23  Heizung EIN
   19:00  Termin beginnt
   21:30  Heizung AUS (Terminende 22:00 − 30 min)
   22:00  Termin endet
```

Der Raum ist bereits überwarm (21,1 °C). Die Formel begrenzt auf 20 °C → Minimalfaktor 40 %.

```mermaid
flowchart TD
    Start["Termin Saal 19:00-22:00<br/>Pruefung um 19:00 Uhr"] --> AT{"Aussentemp. 18,6 C<br/>groesser/gleich Grenze 19 C?"}
    AT -->|"Nein (18,6 kleiner 19)"| Faktor["Raumtemp. 21,1 C<br/>auf 20 C gedeckelt<br/>Korrekturfaktor = 0,40"]
    AT -->|"Ja"| Aus1["Heizung bleibt aus"]
    Faktor --> VZ["Vorheizzeit = 0,40 x 93 min = ca. 37 min<br/>Einschaltzeitpunkt ca. 18:23 Uhr"]
    VZ --> Ein["Heizung EIN ca. 18:23 Uhr"]
    Ein --> AusZeit["Heizung AUS 21:30 Uhr<br/>(Terminende 22:00 minus 30 min)"]
```

Da es um 19:00 Uhr mit 18,6 °C knapp unter der Außentemperatur-Grenze liegt, wird geheizt.
Das vorzeitige Schaltende (−30 min) schaltet die Heizung um 21:30 ab — die Wärmeträgheit hält den Komfort bis 22:00 aufrecht.

### Use Case 2 — Bistro (mit Thermostat, Termin 15:00–18:00)

| Parameter | Wert |
| :--- | :--- |
| Raumtemperatur um 14:00 Uhr | 20,4 °C (Thermostat) |
| Außentemperatur um ~13:42 Uhr | ≥ 19 °C |
| Außentemperatur um 14:00 Uhr | 21 °C |
| Heizen erlaubt? | **Nein** (Außentemp. ≥ Grenze bereits zum Vorheiz-Zeitpunkt) |
| Korrekturfaktor | — (wird nicht berechnet) |
| Vorheizzeit | **0 min** |
| Einschaltzeitpunkt | **entfällt** |

```txt
Zeitachse:
  ~13:42  Rechnerischer Vorheiz-Start — ABER Außentemp. bereits >= 19 °C
   15:00  Termin beginnt — Heizung bleibt aus
   18:00  Termin endet
```

Obwohl rechnerisch ~78 Minuten Vorheizzeit benötigt würden (0,40 × 196 min),
verhindert die Außentemperatur-Grenze das Heizen vollständig.
Das Systemprotokoll vermerkt:
_„Heizen abgebrochen Aussentemperatur 21,0 °C größer Grenzwert 19,0 °C“_

```mermaid
flowchart TD
    Start["Termin Bistro 15:00-18:00<br/>Rechnerischer Vorheiz-Start ca. 13:42 Uhr"] --> AT{"Aussentemp. um 13:42 Uhr<br/>groesser/gleich Grenze 19 C?"}
    AT -->|"Ja (bereits >= 19 C)"| Aus["Heizung bleibt aus<br/>Vorheizzeit = 0 min"]
    AT -->|"Nein"| Rechnung["(wuerde rechnen:<br/>0,40 x 196 min = ca. 78 min)"]
    Aus --> Log["Protokoll: Heizen abgebrochen<br/>Aussentemp. 21,0 C groesser Grenzwert 19,0 C"]
```

### Use Case 3 — Kellerbüro (ohne Thermostat, Termin 08:00–18:00)

| Parameter | Wert |
| :--- | :--- |
| Raumtemperatur (real) | 18–19 °C (aber kein Thermostat konfiguriert) |
| Raumtemperatur in Formel | **10 °C** (Fallback = Grundtemperatur) |
| Außentemperatur morgens | 8 °C |
| Außentemperatur ab ~13:42 | ≥ 19 °C |
| Heizen erlaubt? | Ja (morgens), ab ~13:42 Uhr Nein |
| Korrekturfaktor | 1 − 0,6 × ((10−10)/(20−10)) = **1,00** |
| Kurvenwert bei 8 °C | 196 min |
| Vorheizzeit | 1,00 × 196 = **196 min (3 h 16 min)** |
| Einschaltzeitpunkt | ~04:44 Uhr |
| Ausschaltzeitpunkt | 17:30 Uhr (18:00 − 30 min) — irrelevant, Heizstopp bereits ab ~14:00 |

```txt
Zeitachse:
  ~04:44  Heizung EIN (volle Vorheizzeit wegen Fallback auf Grundtemperatur)
   08:00  Termin beginnt
  ~14:00  Außentemp. >= 19 °C → Heizung AUS (obwohl Termin noch läuft)
   17:30  Heizung AUS (Terminende 18:00 − 30 min) — hier bereits durch Außentemp.-Grenze ab ~14:00 gestoppt
   18:00  Termin endet
```

Ohne Thermostat kennt das Skript die echte Raumtemperatur nicht.
Der Fallback auf die Grundtemperatur (10 °C) ergibt Korrekturfaktor 1,00 → volle Kurvenzeit.
Die niedrig konfigurierte Grundtemperatur führt hier zu einem sehr frühen Einschaltzeitpunkt.
Das vorzeitige Schaltende (−30 min) wäre 17:30 Uhr — irrelevant, da der Außentemp.-Grenzwert bereits ab ~14:00 stoppt.
⚠ Hinweis: Auch bei real 18–19 °C Raumtemperatur rechnet das Skript ohne Thermostat stets mit der Grundtemperatur (10 °C).

```mermaid
flowchart TD
    Start["Termin Kellerbuero 08:00-18:00<br/>kein Thermostat konfiguriert"] --> FB["Fallback: Raumtemp. = Grundtemp. 10 C<br/>Korrekturfaktor = 1,00"]
    FB --> VZ["Vorheizzeit = 1,00 x 196 min = 196 min<br/>Einschaltzeitpunkt ca. 04:44 Uhr"]
    VZ --> Ein["Heizung EIN ca. 04:44 Uhr (morgens 8 C)"]
    Ein --> Lauf{"Aussentemp. im Verlauf<br/>groesser/gleich Grenze 19 C?"}
    Lauf -->|"ab ca. 14:00 Uhr: Ja"| AusAT["Heizung AUS ca. 14:00 Uhr<br/>(obwohl Termin noch laeuft)"]
    Lauf -->|"vormittags: Nein"| Weiter["Heizung bleibt an"]
```

## Gegenüberstellung der Use Cases

| | Saal | Bistro | Kellerbüro |
| :--- | :--- | :--- | :--- |
| Termin | 19:00–22:00 | 15:00–18:00 | 08:00–18:00 |
| Thermostat | Ja | Ja | **Nein** |
| Raumtemperatur | 21,1 °C | 20,4 °C | 18–19 °C (real, unbekannt) |
| Raumtemperatur in Formel | 20,0 °C (gedeckelt) | — | 10,0 °C (Fallback) |
| Außentemp. zum Vorheiz-Start | 18,6 °C um 19:00 | ≥ 19 °C um ~13:42 | 8 °C um ~04:44 |
| Heizen erlaubt? | **Ja** | **Nein** | **Ja** / ab ~14:00 Nein |
| Korrekturfaktor | 0,40 | — | 1,00 |
| Vorheiz-Anteil | 40 % | 0 % | 100 % |
| Kurvenwert | ~93 min (bei 18,6 °C) | — | 196 min (bei 8 °C) |
| Vorheizzeit | **~37 min** | **—** | **196 min** |
| Einschaltzeitpunkt | ~18:23 Uhr | entfällt | ~04:44 Uhr |
| Vorzeitiges Heizende (−30 min) | 21:30 Uhr | — | 17:30 Uhr (überholt durch Außentemp.-Stop ~14:00) |
