# Optimierungsanleitung – HK2-Heizkennlinie und Raumparameter

## 1. Ziel und Grundsätze

Ziel ist, die Heizzeiten so zu optimieren, dass ein Raum seine individuelle Wohlfühltemperatur möglichst zuverlässig erreicht. **Wohlfühlen hat Vorrang vor Energiesparen.**

Der gewünschte Zeitpunkt liegt zwischen **45 Minuten vor und 15 Minuten nach Terminbeginn**.

Dabei gilt:
- Komfort und Wohlbefinden haben Vorrang vor Energieeinsparung.
- Ein verspätetes Erreichen der Wohlfühltemperatur ist ungünstiger als ein etwas zu frühes Erreichen.
- Eine ausreichende Vorheizreserve darf nicht vorschnell zugunsten einer möglichen Energieeinsparung reduziert werden.
- Änderungen erfolgen schrittweise und konservativ.
- Eine geringe Datenmenge schränkt die Aussagekraft ein, verhindert aber keine erste vorsichtige Analyse.
- Die Auswertung erfolgt wöchentlich, auch wenn einzelne Räume nur wenige Heizvorgänge aufweisen.

Die Optimierung soll unterscheiden, ob Abweichungen durch die globale HK2-Heizkennlinie oder durch individuelle Raumeinstellungen verursacht werden.

## 2. Eingabedaten und Datenbasis

Die Auswertung erfolgt anhand von drei gemeinsam bereitgestellten Quellen:

1. Diese Optimierungsanleitung.
2. Das separate Dokument **„Eingabedaten zur HK2-Auswertung“** mit den vollständigen Parametern und Testläufen.
3. Die Heizkalender-Logs des auszuwertenden Zeitraums.

Das Eingabedokument enthält für jeden Testlauf einen vollständigen Parametersatz. Frühere Testläufe bleiben unverändert. Dadurch können Änderungen zwischen zwei Testläufen nachvollzogen werden.

Zusätzlich sind – soweit verfügbar – folgende Angaben zu berücksichtigen:
- Scriptversion und Installationsdatum.
- Änderungen an der Konfiguration innerhalb eines Testzeitraums.
- Betriebsart des Raumes, insbesondere Heizen, Heizen und Schalten oder reines Schalten.
- Zuordnung des verwendeten Temperatursensors zum Raum.
- Globale und raumbezogene Abschaltvorgaben.

Fehlen diese Angaben, ist dies als Einschränkung der Auswertung zu kennzeichnen.

### 2.1 Bedeutung der Logereignisse

Die Logs können folgende Ereignisse enthalten:

- `Heizbeginn`
- `Zieltemperatur`
- `Heizende`
- `Terminbeginn`
- `Terminende`
- `Raumtemperatur`
- `Termin entfernt`

Die Ereignisse haben unterschiedliche Aussagekraft:

- `Heizbeginn` dokumentiert den vom Heizkalender ermittelten Heizbeginn. Es ist kein unmittelbarer Nachweis, dass ein Aktor tatsächlich geschaltet oder Wärme abgegeben hat.
- `Zieltemperatur` dokumentiert die Erkennung der Zieltemperatur durch das Script. Der Zeitpunkt ist nicht zwingend identisch mit dem exakten physikalischen Überschreiten der Temperatur.
- `Heizende` dokumentiert das vom Heizkalender ermittelte Heizende.
- `Raumtemperatur`-Einträge zeigen den Temperaturverlauf. Sie sind keine eigenständigen Heizvorgänge.
- `Termin entfernt` kennzeichnet einen Vorgang, der bei der Bewertung entsprechend berücksichtigt werden muss.

Die `Heizbeginn`-Zeile enthält keinen Maximaltemperaturwert.

Wenn ein `Zieltemperatur`-Ereignis vorhanden ist, ist dieses für die Bewertung des Erreichens der Zieltemperatur maßgeblich.

### 2.2 Außentemperatur

Die Außentemperatur kann beispielsweise in folgender Form erscheinen:

`7,2 [Akt: 4,8] °C`

Der erste Wert ist für die Berechnung der Heizkurve maßgeblich, sofern er dem vom Script verwendeten Mittelwert entspricht. Der aktuelle Wert in eckigen Klammern dient als zusätzliche Information.

Bei der Interpretation ist zu berücksichtigen, dass die Außentemperatur zeitlich gemittelt sein kann und deshalb vom aktuellen Wetterwert abweicht.

### 2.3 Datenqualität

Vor der Auswertung prüfen:

- Sind alle benötigten Ereignisse vorhanden?
- Liegt ausreichend Vorlauf vor dem betrachteten Termin?
- Sind die Raumtemperaturdaten plausibel?
- Gibt es erkennbare CCU-Neustarts oder Sensorfehler?
- Wurden Räume oder Konfigurationen während des Zeitraums verändert?
- Sind Zeitstempel und Zeitzone plausibel, insbesondere bei Sommerzeitwechseln?

Bei Diagramm- oder XML-Exporten ist auf die korrekte Interpretation von UTC-Zeitstempeln und lokaler Zeit zu achten.

Fehlende oder unplausible Daten dürfen nicht durch Annahmen ersetzt werden. Sie sind als Einschränkung oder Ausschlussgrund auszuweisen.

### 2.4 Auswertung der System- und Raumvariablen

Die globalen Werte und Raumparameter werden direkt aus den im Eingabeformular übernommenen Zeilen der Testskriptausgabe gelesen.

| Systemvariable | Bedeutung |
|---|---|
| `HK2-A.Temp.Grenze` | Außentemperaturgrenze für den Heizbetrieb in °C. |
| `HK2-Grundtemperatur` | Globale Grundtemperatur GT in °C. |
| `HK2-Kurve` | Acht durch Semikolon getrennte Vorheizzeiten in Minuten für die Außentemperaturen -10; -5; 0; 8; 10; 12; 15; 17,5 °C in genau dieser Reihenfolge (siehe Abschnitt 3.1). |
| `HK2-Kurvenanpassung` | Dimensionsloser Faktor c zur Berechnung des relativen Heizbedarfs (siehe Abschnitt 3.2). |
| `HK2-Kurvenversatz` | Globaler Zeitversatz tVersatz in Minuten. |
| `HK2-VorzeitAus` | Globale Abschaltzeit vor Terminende in Minuten. |
| `HK2-HKG-Liste` | Zuordnung der Raumvariablen zu den Kalenderressourcen. Semikolon trennt die Ressourcengruppen; Pluszeichen verbindet die gemeinsam geschalteten Räume einer Ressourcengruppe. Ein Raum kann mehreren Ressourcengruppen zugeordnet sein. |

Die Referenz-Wohlfühltemperatur der HK2-Kurve wird separat angegeben.

Die Raumvariablen haben folgenden Aufbau:

`HKG-Raum-<Name>=Status;Modus;Gerätebauart;ZT[/GT];tRaum[*FRaum[*Mindest]];Nachlaufzeit;Aktoren...`

- Status: momentaner Schaltstatus, kein dauerhafter Optimierungsparameter.
- Modus: H = Heizen, HS = Heizen und Schalten, S = Schalten, V = Variable.
- Gerätebauart: Typ der verwendeten Geräte; daraus allein lässt sich die tatsächliche Temperaturquelle nicht sicher ableiten.
- ZT: individuelle Wohlfühltemperatur; ohne optionales GT gilt die globale Grundtemperatur.
- tRaum: feste Vorheizzeit in Minuten; ohne optionalen FRaum gilt 1,0.
- Mindest: optionale Mindestvorheizzeit in Minuten; fehlt der Wert, ist keine individuelle Mindestvorheizzeit angegeben.
- Nachlaufzeit: raumbezogener Zeitparameter für das Heizende; die Abschaltvorgaben gemäß Heizkalender berücksichtigen.
- Aktoren: zugeordnete Geräte bzw. Heizgruppen.

Raumvariablen ohne Zuordnung in `HK2-HKG-Liste` nicht allein aufgrund ihrer Existenz als aktive Kalenderheizräume behandeln. Fehlende oder nicht eindeutig interpretierbare Angaben kennzeichnen. Ergänzende Raumeigenschaften und Temperaturquellen aus Abschnitt D des Eingabeformulars berücksichtigen.

## 3. Berechnungslogik des Heizkalenders

Die Berechnung der Vorheizzeit erfolgt grundsätzlich nach folgender Formel:

`t = (tHK2 * FRaum + tRaum + tVersatz) * FHeizbedarf`

Anschließend wird die Mindestvorheizzeit berücksichtigt:

`t_eff = max(t, Mindest)`

Dabei gilt:

- `tHK2`: aus der globalen HK2-Heizkurve interpolierte Zeit.
- `FRaum`: individueller Raumfaktor.
- `tRaum`: individuelle feste Vorheizzeit.
- `tVersatz`: zusätzlicher Zeitversatz.
- `FHeizbedarf`: Korrekturfaktor abhängig vom aktuellen Heizbedarf.
- `Mindest`: individuelle Mindestvorheizzeit.

### 3.1 HK2-Heizkurve

Die HK2-Kurve besteht aus acht Zeitwerten für folgende Außentemperaturen:

`-10; -5; 0; 8; 10; 12; 15; 17,5 °C`

Zwischen den Stützstellen wird linear interpoliert. Außerhalb des Stützstellenbereichs wird das jeweilige Endsegment extrapoliert.

Negative Ergebnisse werden auf null begrenzt.

### 3.2 Heizbedarf

Der Heizbedarf wird über die relative Temperaturdifferenz bestimmt:

`x = (IST - GT) / (ZT - GT)`

Dabei gilt:
- IST wird nach oben auf ZT begrenzt.
- Eine Begrenzung nach unten erfolgt nicht.
- Wenn GT und ZT identisch sind, wird `x = 1` gesetzt.

Der Faktor wird mit `c` berechnet:

Für `x < 0,5`:

`FHeizbedarf = 1 - c * x`

Für `x >= 0,5`:

`FHeizbedarf = (2 - c) * (1 - x)`

Der Faktor `c` steuert die Stärke der Heizbedarfsanpassung.

### 3.3 Mindestvorheizzeit

Die Mindestvorheizzeit begrenzt die berechnete Vorheizzeit nach unten.

Wenn die Mindestvorheizzeit wirksam wird, lässt sich aus dem betreffenden Heizvorgang keine verlässliche Aussage über die erforderliche HK2-Kurvenzeit ableiten.

Solche Vorgänge sind deshalb von der Rückrechnung der Heizkurve auszuschließen.

## 4. Testläufe und zeitliche Zuordnung

Für jeden Heizvorgang muss der Parametersatz verwendet werden, der zum Zeitpunkt des Vorgangs tatsächlich gültig war.

Die Testläufe im Eingabedokument bilden die zeitliche Historie ab.

Bei Änderungen innerhalb eines Testlaufs ist der betroffene Zeitraum zu kennzeichnen. Ein Heizvorgang darf nicht mit einem Parametersatz ausgewertet werden, der erst später gültig wurde.

Auch Scriptversion und Konfigurationsänderungen sind zu berücksichtigen. Bei einem Versionswechsel ist zu prüfen, ob sich die Berechnungs- oder Protokollierungslogik geändert hat.

## 5. Bewertung einzelner Heizvorgänge

Für jeden Heizvorgang sind zunächst folgende Zeitpunkte zu bestimmen:

- Heizbeginn
- Erreichen der Zieltemperatur
- Terminbeginn
- gegebenenfalls Heizende

Die Zeitdifferenz zum Terminbeginn wird aus den Logwerten ermittelt.

Die Zieltemperatur soll im Zeitfenster von 45 Minuten vor bis 15 Minuten nach Terminbeginn erreicht werden.

### 5.1 Gegenprobe der berechneten Vorheizzeit

Für jeden Vorgang wird geprüft, ob der dokumentierte Heizbeginn zur rechnerisch ermittelten Vorheizzeit passt.

Dazu wird die effektive Vorheizzeit `t_eff` anhand des zum Heizbeginn gültigen Parametersatzes sowie der dort dokumentierten IST- und Außentemperatur berechnet.

Verglichen wird:

`-Δ(Heizbeginn)` mit `t_eff`

Eine Abweichung von mehr als 10 Minuten ist auffällig.

Bei einer nicht plausiblen Gegenprobe darf der Vorgang nicht für die Rückrechnung der Heizkurve verwendet werden. Er wird dennoch in der Auswertung aufgeführt und die Abweichung erläutert.

Wenn die Mindestvorheizzeit wirksam war, ist der Vorgang ebenfalls von der Rückrechnung auszuschließen.

### 5.2 Ausschluss von Vorgängen

Von der Rückrechnung der HK2-Kurve sind insbesondere auszuschließen:

- IST-Temperatur beim Heizbeginn bereits mindestens auf Zieltemperatur.
- IST-Temperatur gleich null oder erkennbarer Sensor-/CCU-Fehler.
- Termin wurde entfernt.
- Gegenprobe ist nicht plausibel.
- Mindestvorheizzeit war wirksam.
- Sonderzieltemperatur weicht von der regulären Wohlfühltemperatur ab.
- Parameter oder Betriebsbedingungen sind nicht eindeutig zuzuordnen.

Ausgeschlossene Vorgänge bleiben in der Ergebnisübersicht sichtbar. Der Ausschlussgrund ist anzugeben.

Ein Vorgang, bei dem die Zieltemperatur bis zum Terminende nicht erreicht wurde, ist als zu kurz beheizt zu bewerten. Die genaue fehlende Vorheizzeit lässt sich daraus nicht sicher ableiten. Er darf deshalb nicht ohne Weiteres in die Rückrechnung einfließen.

## 6. Rückrechnung der erforderlichen Heizzeit

Für Vorgänge mit plausibler Gegenprobe und erreichter Zieltemperatur wird die tatsächlich benötigte Heizdauer ermittelt.

`T = Δ(Zieltemperatur) - Δ(Heizbeginn)`

Mit dem gewünschten Vorlauf `R` vor Terminbeginn ergibt sich:

`t_need = T + R`

Dabei ist `R` im Standardfall 45 Minuten.

Die benötigte HK2-Kurvenzeit wird rückgerechnet:

`tHK2_need = (t_need / FHeizbedarf - tRaum - tVersatz) / FRaum`

Die Abweichung zur bisherigen effektiven Vorheizzeit lautet:

`d = t_need - t_eff`

Ein positives `d` bedeutet, dass mehr Vorheizzeit benötigt wurde. Ein negatives `d` bedeutet, dass die Zieltemperatur früher als gewünscht erreicht wurde.

Die Rückrechnung ist nur so belastbar wie die zugrunde liegenden Messwerte und Annahmen. Insbesondere sind die Sensorposition, die thermische Trägheit und die tatsächliche Wärmeabgabe zu berücksichtigen.

## 7. Auswertung nach Räumen und Außentemperatur

Die Ergebnisse werden sowohl nach Räumen als auch nach Außentemperaturbereichen ausgewertet.

Für jeden Raum sind mindestens anzugeben:
- Anzahl der erfassten Vorgänge.
- Anzahl der für die Rückrechnung geeigneten Vorgänge.
- Anzahl und Gründe ausgeschlossener Vorgänge.
- Median der Zeitabweichung.
- Streuung und auffällige Einzelwerte.
- Anteil der Vorgänge im gewünschten Zeitfenster.

Ein Bestand von fünf geeigneten Vorgängen ist eine Orientierung für belastbare statistische Aussagen. Er ist keine Voraussetzung für eine wöchentliche erste Analyse.

Bei wenigen Vorgängen sind die Ergebnisse ausdrücklich als vorläufig zu kennzeichnen. Kleine, vorsichtige Korrekturen sind trotzdem möglich, wenn die Richtung der Abweichung eindeutig ist.

### 7.1 Erkennen gemeinsamer Effekte

Eine globale Anpassung der HK2-Kurve ist nur sinnvoll, wenn sich ein gemeinsamer Effekt über mehrere Räume zeigt.

Als Orientierung gilt:
- Mindestens 75 % der Räume mit mindestens fünf geeigneten Vorgängen zeigen dieselbe Abweichungsrichtung.
- Der Median der raumbezogenen Mediane liegt betragsmäßig über acht Minuten.

Diese Schwellenwerte sind Orientierungshilfen und keine starren Voraussetzungen für eine erste wöchentliche Analyse.

Einzelne Räume mit deutlich abweichendem Verhalten sind als Ausreißer zu kennzeichnen. Als auffällig gelten beispielsweise Abweichungen von mehr als 10 % oder acht Minuten gegenüber dem Median der übrigen Räume.

Wenn kein gemeinsamer Effekt erkennbar ist, sollen keine globalen Änderungen an der HK2-Kurve vorgenommen werden.

## 8. Optimierung der HK2-Kurve

Bei einem nachgewiesenen gemeinsamen Effekt wird zuerst die globale HK2-Kurve betrachtet.

Die Korrektur erfolgt anhand der rückgerechneten benötigten Kurvenzeiten. Dabei sind die Ergebnisse nach Außentemperaturbereichen zusammenzufassen.

Grundsätze:
- Robuste Kennwerte, insbesondere Mediane, verwenden.
- Keine Überreaktion auf einzelne Vorgänge.
- Die Kurve muss mit steigender Außentemperatur monoton fallen oder gleich bleiben.
- Keine unnötigen Knicke oder Sprünge erzeugen.
- Die Änderung je Stützstelle und Optimierungsrunde grundsätzlich auf höchstens 20 % begrenzen.
- Bei geringer Datenbasis kleinere Änderungen bevorzugen.

Die HK2-Kurve wird nur geändert, wenn die Daten einen gemeinsamen Effekt ausreichend stützen.

## 9. Optimierung der Raumparameter

Wenn kein gemeinsamer Effekt über die Räume erkennbar ist, werden die individuellen Raumparameter geprüft.

### 9.1 Feste Vorheizzeit und Raumfaktor

Die individuelle Raumkurve lässt sich als Gerade auffassen:

- Der **Raumfaktor `FRaum` bestimmt die Steigung** der Geraden. Ein größerer Faktor macht sie steiler, ein kleinerer Faktor flacher.
- Die **feste Vorheizzeit `tRaum` verschiebt die Gerade parallel** nach oben oder unten.

Beide Parameter beschreiben somit unterschiedliche Eigenschaften derselben individuellen Raumkurve. Die KI soll sie bei ausreichender Datenbasis **gemeinsam anhand der Messpunkte beurteilen und bestimmen**. Eine starre Reihenfolge – zuerst die feste Vorheizzeit oder zuerst den Raumfaktor zu ändern – ist nicht vorzugeben.

Die Abweichung `d` wird um den Heizbedarfsfaktor bereinigt:

`d_adj = d / FHeizbedarf`

Für die Auswertung wird `d_adj` gegen die bisherige Kurvenzeit `tHK2 * FRaum_alt` betrachtet. Bei ausreichender Datenbasis kann eine lineare Regression verwendet werden:

`d_adj = a + b * (tHK2 * FRaum_alt)`

Daraus ergeben sich als Orientierung:

- Änderung der festen Vorheizzeit: `ΔtRaum = a`
- Neuer Raumfaktor: `FRaum_neu = FRaum_alt * (1 + b)`

Die Interpretation folgt aus der Berechnungsformel: `a` beschreibt den annähernd konstanten Zeitversatz; `b` beschreibt die proportionale Änderung der bisherigen, faktorabhängigen Kurvenzeit. Positive Werte bedeuten, dass mehr Vorheizzeit benötigt wird.

Die gemeinsame Schätzung ist nur belastbar, wenn genügend geeignete Messpunkte über einen ausreichend breiten Bereich der berechneten HK2-Zeiten bzw. Außentemperaturen vorliegen. Bei wenigen Messpunkten oder einem engen Temperaturbereich können Steigung und parallele Verschiebung nicht zuverlässig voneinander getrennt werden.

In diesem Fall darf die KI keine scheinbar genaue gemeinsame Anpassung erzwingen. Sie soll die Unsicherheit benennen und entweder zunächst keine Änderung empfehlen oder – wenn die Richtung einer Korrektur eindeutig und komfortorientiert ist – eine kleine, ausdrücklich vorläufige Anpassung vorschlagen. Eine ausreichende Vorheizreserve ist dabei nicht vorschnell abzubauen.

### 9.2 Mindestvorheizzeit

Die Mindestvorheizzeit wird nur angepasst, wenn sie bei mehreren Vorgängen tatsächlich wirksam wurde und das Ergebnis wiederholt außerhalb des gewünschten Zeitfensters lag.

### 9.3 Grund- und Wohlfühltemperatur

Grundtemperatur und Wohlfühltemperatur sind Komfort- und Energievorgaben.

Sie lassen sich aus den Vorheizzeiten allein nicht zuverlässig optimieren. Die Kurve bezieht sich auf die Differenz zwischen Ziel- und Grundtemperatur.

Diese Werte werden deshalb grundsätzlich als vorgegeben behandelt. Auffällige Fälle sind zu melden, beispielsweise Räume, die dauerhaft unter der Grundtemperatur oder trotz ausreichender Heizzeit unter der Wohlfühltemperatur bleiben.

Eine Änderung erfordert eine gesonderte Betrachtung und gegebenenfalls einen gezielten Heizversuch.

## 10. Weitere Parameter und Betriebsbedingungen

### 10.1 Faktor c

Der Parameter `c` wird nur geändert, wenn die verbleibenden Abweichungen systematisch mit dem relativen Heizbedarf `x` zusammenhängen.

Eine Änderung darf nicht dazu dienen, einzelne Ausreißer auszugleichen.

### 10.2 Zeitversatz tVersatz

`tVersatz` bleibt unverändert. Er wird bei der Berechnung berücksichtigt, ist aber kein regulärer Optimierungsparameter dieser Auswertung.

### 10.3 Abschaltzeiten

Globale und raumbezogene Abschaltvorgaben können das beobachtete Heizverhalten beeinflussen.

Insbesondere eine vorzeitige Heizabschaltung kann dazu führen, dass die Zieltemperatur vor Terminbeginn wieder unterschritten wird oder der Raum die Zieltemperatur nicht ausreichend lange hält.

Solche Vorgänge sind bei der Bewertung gesondert zu kennzeichnen. Eine Änderung der Vorheizkurve ist nicht automatisch die richtige Reaktion auf ein Abschaltproblem.

### 10.4 Betriebsart und Temperaturquelle

Heizvorgänge mit unterschiedlichen Betriebsarten oder unterschiedlichen Temperaturquellen dürfen nicht unkritisch zusammengefasst werden.

Bei der Auswertung ist zu prüfen, ob ein Raum tatsächlich beheizt wird und welcher Sensor die maßgebliche Raumtemperatur liefert.

Unterschiede sind bei der Interpretation und gegebenenfalls bei der Bildung von Gruppen zu berücksichtigen.

## 11. Gewünschte Ausgabe

Die Auswertung soll übersichtlich und nachvollziehbar sein.

Sie enthält:

1. **Datenbasis**
   - Auswertungszeitraum.
   - Verwendeter Parametersatz und Scriptversion.
   - Anzahl der Vorgänge insgesamt und je Raum.
   - Geeignete und ausgeschlossene Vorgänge mit Gründen.
   - Einschränkungen der Datenqualität.

2. **Einzelereignisse**
   - Raum und Termin.
   - Heizbeginn und Zieltemperaturzeitpunkt.
   - Abweichung zum gewünschten Zeitfenster.
   - Gegenprobe.
   - Ausschlussgrund, falls zutreffend.

3. **Raumbewertung**
   - Bewertung je Raum und Außentemperaturbereich.
   - Gemeinsame Effekte und Ausreißer.
   - Vorläufigkeit bei geringer Datenbasis.

4. **Optimierungsvorschläge**
   - HK2-Kurve, sofern ein gemeinsamer Effekt vorliegt.
   - Raumparameter, sofern individuelle Abweichungen vorliegen.
   - Bewertung von `c`, Mindestvorheizzeit und Abschaltvorgaben.
   - Keine Änderung von `tVersatz`.

5. **Konkrete neue Werte**
   - HK2-Kurve als Semikolon-getrennte Werteliste.
   - Raumparameter mit Raumnamen.
   - Änderungen gegenüber dem vorherigen Testlauf.

6. **Erwartete Wirkung und Unsicherheit**
   - Welche Verbesserung wird erwartet?
   - Welche Räume und Temperaturbereiche sind betroffen?
   - Wie belastbar ist die Empfehlung?

## 12. Allgemeine Regeln

- Keine Parameteränderung ohne nachvollziehbare Begründung.
- Wohlfühlen hat Vorrang vor Energiesparen.
- Eine ausreichende Vorheizreserve nicht vorschnell reduzieren; ein etwas zu frühes Erreichen der Wohlfühltemperatur ist einem verspäteten Erreichen vorzuziehen.
- Bei Unsicherheit kleinere Änderungen bevorzugen.
- Eine geringe Datenbasis ist kein Grund, eine wöchentliche Analyse auszulassen.
- Änderungen an globalen Parametern nur bei nachgewiesenem gemeinsamen Effekt.
- Individuelle Abweichungen möglichst über die gemeinsame Beurteilung von Raumfaktor (Steigung) und fester Vorheizzeit (parallele Verschiebung) korrigieren.
- Grund- und Wohlfühltemperaturen nicht aus Vorheizdaten ableiten.
- Frühere Testläufe und Parameterstände nicht nachträglich überschreiben.
- Technische Besonderheiten sind anhand der tatsächlich eingesetzten Scriptversion zu beurteilen und nicht ungeprüft zu verallgemeinern.