# Beschreibung der Skripte und Programme

Dieser Ordner enthält alle Hauptkomponenten für den Heizkalender. Ein Teil der Skripte dient nur der Initialisierung. Diese haben das Kürzel _Init_ im Namen.

Skripte mit dem Namenskürzel _Skript 1_ beschreiben die verschiedenen Methoden Termine für den Heizkalender auszulesen.  
Das _Skript 2_ ist das Hauptskript zum Berechnen der Schaltzeiten.  
Das _Skript 3_ ist das Hauptskript zum Schalten der Heizung.

## HeizkalenderInstallation.exe

Die HeizkalenderInstallation.exe dient zur Installation und Einrichtung der verschiedenen Skriptvarianten. Dieses Programm kann bestehende Installationen aktualisieren oder kann einfach neue Installationen erzeugen.

Das Programm legt dazu die notwendigen Skripte und Systemvariablen an. Die notwendigen passenden Skripte müssen dazu im Programmverzeichnis liegen.
Die folgenden Skripte werden dabei zwingend benötigt und müssen im Programmverzeichnis liegen, auch wenn diese evtl. nicht benutzt werden:

- HK-Außentemperatur-Open-Meteo
- HK-Heizkurvenkontrolle
- HK-Skript 1_ChurchDeskAPI
- HK-Skript 1_ChurchDeskiCal
- HK-Skript 1_ChurchTools
- HK-Skript 1_Google
- HK-Skript 1_iCal
- HK-Skript 2
- HK-Skript 3
- HK-SystemProtokoll sichern

Die komplette [Dokumentation für die `HeizkalenderInstallation.exe`](../heizkalender-installation/readme.md) ist hier zu finden.

## Skripte zur Initialisierung

> [!WARNING]
> __Wenn die `HeizkalenderInstallation.exe` verwendet wird, müssen die nachfolgenden Skripte für die Installation nicht benutzt werden!__
>
> _Die Dokumentation dient nur zur Erklärung der Skript-Grundlagen und wenn es notwendig sein sollte, dass eine manuelle Installation erfolgen muss._

Die folgenden Variablen werden in allen Skripten vom Typ 1 und natürlich vom Berechnungsskript 2 verwendet.

| Variable | Bedeutung |
| :--------------- | :--------- |
| HK1-Schaltliste | Schaltlisten Einträge. Hier werden vom Skript die ermittelten und zu schaltenden Termine eingetragen |
| HK1-R-Liste | Raumliste der Churchdesk Ressourcen. Bestehende aus einer Id und optional gefolgt von einem Gleichheitszeichen mit dem Raumnamen als Text |
| HK2-HKG-Liste | Semikolon getrennte Liste der Raum-Systemvariablen. Zu jedem Eintrag der Ressourcen Liste HK1-R-Liste, der entsprechende Raum Eintrag. Jeder Ressource können mehrere Räume zugeordnet werden indem die einzelnen Räume durch ein + Zeichen getrennt werden. |
| HK1-Vorlaufzeit | Optional. Zeithorizont für die Terminabfrage in Minuten (wie weit in die Zukunft soll geschaut werden). Default: 720 (12 Stunden). Wird die Variable nicht angelegt, bleibt der Defaultwert aktiv. Maximum: 1380 (23 Stunden). |

### HK-Init-Skript 1_ChurchDesk.hsc

Dieses Skript legt alle Systemvariablen an, die für den Zugriff auf ChruchDesk benötigt werden. Es spielt hier keine Rolle ob der Zugriff über die ChurchDesk API oder die ChurchDesk iCal Schnittstelle erfolgt.

| Variable | Bedeutung |
| :--------------- | :--------- |
| HK1-CD-OrganisationsId | ChurchDesk Id der Kirche oder Gemeinde |
| HK1-CD-Token | API-Token für den Zugriff auf die Pull-API von ChurchDesk. Dieses Token wird durch den Support von ChurchDesk vergeben. |

Werden diese beiden Variablen im Init-Skript korrekt ausgefüllt ermittelt das Skript alle Ressourcen, die in ChurchDesk angelegt wurden. Es werden dann entsprechende Raum-Systemvariablen erzeugt.

Dieses Skript wird für den Zugriff über die iCal oder API Schnittstelle benötigt.

### HK-Init-Skript 1_ChurchTools.hsc

Dieses Skript dient zum Anlegen aller Systemvariablen um Termine aus den Ressourcen der ChurchTools API zu lesen.

| Variable | Bedeutung |
| :--------------- | :--------- |
| HK1-CT-Gemeindename | Name der Gemeinde im ChurchTools URL. `xyz`.church.tools |
| HK1-CT-Token | Login Token für einen Benutzer in ChurchTools. Dieses Login-Token muss einmalig ermittelt werden. Der Benutzer benötigt ausschließlich lesenden Zugriff auf die Kalender und Ressourcen. |

Werden diese beiden Variablen im Init-Skript korrekt ausgefüllt ermittelt das Skript alle Ressourcen vom Typ `Raum`, die in ChurchTools angelegt wurden. Es werden dann entsprechende Raum-Systemvariablen erzeugt.

### HK-Init-Skript 1_Google.hsc

Dieses Skript legt alle Systemvariablen an, die für den Zugriff auf die Google Calendar API verwendet werden.

| Variable | Bedeutung |
| :--------------- | :--------- |
| HK1-GK-API-Key | Google API-Key für den Zugriff auf die Google-Calendar-API. |
| HK1-GK-Kalender-ID | Id, des öffentlichen Kalenders in Google |

### HK-Init-Skript 1_iCal.hsc

Dieses Skript legt alle Systemvariablen an, die für den Zugriff auf einen beliebigen iCal-Kalender benötigt werden.

| Variable | Bedeutung |
| :--------------- | :--------- |
| HK1-ICS-Url | URL des iCal Kalenders |

__Nicht unterstützt werden: BYMONTH, BYMONTHDAY, BYYEARDAY, BYWEEKNO, BYSETPOS, BYHOUR, BYMINUTE, BYSECOND!__

### HK-Init-Skript 2+3.hsc

Dieses Skript legt alle Systemvariablen an, die für das Berechnungs- und das SchaltSkript benötigt werden.

- `HK-Skript 2` berechnet die Schaltzeiten aus `HK1-Schaltliste` und speichert diese in `HK2-Schaltliste`
- `HK-Skript 3` Nutzt die Schaltzeiten aus `HK2-Schaltliste` schaltet die Aktoren entsprechend.

| Variable | Bedeutung |
| :--------------- | :--------- |
| HK2-Grundtemperatur | Grundtemperatur für alle Räume außerhalb einer Heizphase |
| HK2-A.Temp.Grenze | Außentemperatur ab der kein Heizen mehr erfolgt |
| HK2-Aussentemperatur | Gleitende Durchschnitts-Außentemperatur über das konfigurierte Zeitfenster. Wird durch Skript _HK-Außentemperatur-Open-Meteo.hsc_ gesetzt oder alternativ durch einen Außentemperatursensor. |
| HK2-Aussentemperatur-Aktuell | Optional. Momentaner Außentemperaturwert der letzten vollen Stunde (kein Durchschnitt). Wird vom AT-Skript geschrieben, nur wenn die Variable vorhanden ist. Dient zur Anzeige und als Diagnosewert. |
| HK2-Aussentemperatur-Abrufzeit | Optional. Zeitpunkt des letzten erfolgreichen Open-Meteo-Abrufs als Unixsekunden in einer Zeichenkette. Wird auch bei unveränderter Temperatur aktualisiert; dient der Aktualitätsanzeige im Addon. Manuell anlegen, siehe Abschnitt zum Außentemperatur-Skript. |
| HK2-Hand-Temp | Wenn `true` Vorrang einer manuell am Thermostat eingestellten Temperatur beim Ausschalten |
| HK2-Hand-Grundtemp | Wenn `true` aktiviert die Nachtschaltung. `HK-Skript 3` prüft täglich zwischen 00:57 und 01:03 Uhr alle Räume und setzt sie auf Grundtemperatur, sofern kein aktiver Termin (Schaltzustand=1) vorliegt. Bei Heizräumen (HSFlag=H) wird die Solltemperatur am Thermostat gesetzt, bei Schaltaktoren (HSFlag=S/HS) wird der Aktor ausgeschaltet. Die Prüfung erfolgt direkt am Aktor, nicht nur in der Systemvariablen. |
| HK2-VorzeitAus | Globale Grundoffsetzeit in Minuten, um die vor Terminende ausgeschaltet wird. Wird nur bei Heizvorgängen angewendet, nicht bei reinem Schalten. Gegenstück zu HK2-Kurvenversatz (Einschalt-Offset). Default: 0 |
| HK2-Kurvenversatz | Globale Grundoffsetzeit in Minuten, um die vor Terminbeginn eingeschaltet wird. Wird nur bei Heizvorgängen angewendet, nicht bei reinem Schalten. Gegenstück zu HK2-VorzeitAus (Ausschalt-Offset). Default: 0 |
| HK2-Kurve | Heizkurve: 8 Vorlaufzeiten in Minuten zu den Außentemperatur-Stützpunkten −10, −5, 0, 8, 10, 12, 15, 17,5 °C (semikolongetrennt). Zwischen den Stützpunkten interpoliert `HK-Skript 2` linear; der höchste Wert (bei tiefster Außentemperatur) ist die längste Vorheizzeit. Installation-Default (konservativ): `162;130;100;59;50;41;30;20` (max. 162 min ≈ 2,7 h). Als Orientierungshilfe sind drei Beispielkurven bekannt (konservativ / mittel / großzügig); Details und eine vollständige Vergleichstabelle siehe [Anwenderhandbuch](../heizkalender/anwenderhandbuch.md) und [../heizkalender/heizsteuerung-vorheizzeit.md](../heizkalender/heizsteuerung-vorheizzeit.md). |
| HK2-Kurvenanpassung | Optional. Faktor k für das Zwei-Geraden-Modell der Vorheizzeit-Berechnung (0.3..1.0). Steuert die Stärke der Reduzierung der Vorlaufzeit bei bereits vorgeheizten Räumen: 1.0 = lineare Gerade (maximale Reduzierung), 0.8 = Sicherheitskurve (Vorgabe), 0.6 = empfohlen für Brennwertkessel mit schwerer Bausubstanz und schwachen Heizkörpern. Fehlt die Variable, wird automatisch 0.8 verwendet. Werte außerhalb 0.3..1.0 werden auf diesen Bereich begrenzt. |
| HK2-Schaltliste |  Hier werden von `HK-Skript 2` errechneten Schaltzeiten eingetragen, die von dann vom Schaltskript `HK-Skript 3` verwendet werden |
| HK2-Schaltzeiten | Wird von `HK-Skript 2` am Ende jedes Laufs geschrieben (optional, nur wenn die Variable vorhanden ist). Enthält die berechneten Schaltzeiten aller Räume des letzten Skriptlaufs. Format: `RaumVarName;VorlaufMin;HeizenAb;TerminAb;TerminBis;NachlaufMin~...` (Einträge durch `~` getrennt). Bei Multi-Raum-Zuordnungen ein Eintrag pro Raum mit individueller Vorheizzeit. Dient zur Anzeige im Addon. Nicht manuell setzen. |

### HK-Init-Variablen Logging.hsc

Dieses Skript legt alle Systemvariablen an, die für die Protokollierung über das Systemprotokoll benötigt werden.
Die Protokollierung erfolgt über die nachfolgenden Kategorien:

- Allgemeines Log. Einträge tragen den Namen _HK-Log_.
- Logging für die Skripte vom Typ 1. Hier werden die Zugriffe auf die Kalender protokolliert. Einträge tragen den Namen _HK1-Log_.
- Logging für das Skript vom Typ 2. Hier werden die Berechnungen der Schaltzeiten protokolliert. Einträge tragen den Namen _HK2-Log_.
- Logging für das Skript vom Typ 3. Hier werden die Schaltvorgänge der Heizung protokolliert und auch alle Sonderfunktionen, wie das Rückstellen der Heizung auf Grundtemperatur oder das Abschalten der Heizung, wenn der betroffene Termin gelöscht wird.  Einträge tragen den Namen _HK3-Log_.
- Logging für die Heizkurvenkontrolle. Um die Heizkurve kontrollieren zu können, werden spezielle Einträge im Systemprotokoll verzeichnet: Start des Heizens, Erreichen der Zieltemperatur, Start des Termins, Ende der Heizphase, Ende des Termines. Protokolliert werden Außentemperatur (beim Start), aktuelle Temperatur, bisher erreichte maximale Temperatur.  Einträge tragen den Namen _HK-LogHeizkurvenkontrolle_.

| Variable | Bedeutung |
| :--------------- | :--------- |
| HK-Logging | Flag das Logging vom Typ `HK-Log` steuert |
| HK-Log | Variable um ein einfaches Log im System Protokoll zu erzeugen |
| HK1-Logging | Flag das Logging vom Typ `HK1-Log` steuert |
| HK1-Log | Variable um ein einfaches Log im System Protokoll zu erzeugen |
| HK2-Logging | Flag das Logging vom Typ `HK2-Log` steuert |
| HK2-Log | Variable um ein einfaches Log im System Protokoll zu erzeugen |
| HK3-Logging | Flag das Logging vom Typ `HK2-Log` steuert |
| HK3-Log | Variable um ein einfaches Log im System Protokoll zu erzeugen |
| HK-LoggingHeizkurvenkontrolle | Flag das Logging vom Typ `HK-LogHeizkurvenkontrolle` steuert |
| HK-LogHeizkurvenkontrolle | Variable um ein einfaches Log im System Protokoll zu erzeugen |
| HK-RäumeHeizkurvenkontrolle | Variable in der der Status für die Heizkurvenkontrolle mehrerer Räume verzeichnet wird |

## Skripte zum Einlesen der Termindaten aus diversen Quellen

> [!WARNING]
> __Wenn die `HeizkalenderInstallation.exe` verwendet wird, müssen die nachfolgenden Skripte für die Installation nicht installiert werden! Das Installationsprogramm führt alle notwendigen Operationen durch.__
>
> _Die Dokumentation dient nur zur Erklärung der Skript-Grundlagen und wenn es notwendig sein sollte, dass eine manuelle Installation erfolgen muss._

Es wird für den Betrieb des Heizkalenders eine der nachfolgenden Datenquellen (ChurchTools, ChurchDesk, iCal, Google-Kalender) benötigt. Das entsprechende Skript sollte ca. alle 30 min laufen um die Termine für die nächsten Heizzyklen zu bestimmen.

Alle diese Skripte bedienen die Variable `HK1-Schaltliste`. In dieser Variable werden aktuelle Termine eingetragen, die durch das Berechnungsskript 2 berücksichtigt werden sollen.

### HK-Skript 1_ChurchDeskAPI.hsc

Skript für den Zugriff auf die internen Kalender in ChurchDesk über die ChurchDesk API.

> [!WARNING]
> Aktuell können nur öffentliche Termine über die ChurchDesk API gelesen werden. Ist ein Termin als privat oder nur für bestimmte Gruppen sichtbar, wird dieser Termin nicht für den Heizkalender berücksichtigt. Aktuell kann nur die ChurchDesk iCal Variante alle Termine lesen.

Benötigte Variablen: `HK1-CD-OrganisationsId`, `HK1-CD-Token`
Sowie die Variablen: `HK1-R-Liste`, `HK2-HKG-Liste`, `HK1-Schaltliste`, `HK1-Log`, `HK1-Logging`
Optional: `HK1-Vorlaufzeit`

### HK-Skript 1_ChurchDeskiCal.hsc

Skript für den Zugriff auf die internen Kalender in ChurchDesk über die ChurchDesk iCal Kalender der Ressourcen.

Der HTTPS-Abruf deaktiviert die Zertifikatsprüfung von `wget` nicht. Die CCU benötigt einen passenden Zertifikatsbestand und eine kompatible TLS-Version. Bei einem Zertifikatsfehler gibt es keinen Rückfall auf eine ungeprüfte Verbindung. Nach fünf erfolglosen Abrufversuchen wird die Ressource übersprungen; bei aktiviertem Logging warnt `HK1-Log` vor möglicherweise fehlenden Terminen in der neu aufgebauten Schaltliste. Die Zertifikatsprüfung behebt kein Problem mit einer vom Server nicht mehr unterstützten TLS-Version.

Benötigte Variablen: `HK1-CD-OrganisationsId`, `HK1-CD-Token`
Sowie die Variablen: `HK1-R-Liste`, `HK2-HKG-Liste`, `HK1-Schaltliste`, `HK1-Log`, `HK1-Logging`
Optional: `HK1-Vorlaufzeit`

### HK-Skript 1_ChurchTools.hsc

Skript für den Zugriff auf die internen Kalender in ChurchTools über die ChurchTools-API auf die Kalender der Ressourcen.

Benötigte Variablen: `HK1-CT-Gemeindename`, `HK1-CT-Token`
Sowie die Variablen: `HK1-R-Liste`, `HK2-HKG-Liste`, `HK1-Schaltliste`, `HK1-Log`, `HK1-Logging`
Optional: `HK1-Vorlaufzeit`

### HK-Skript 1_Google.hsc

Skript für den Zugriff auf einen Kalender in Google über die Google Calendar-API. Bei diesem Verfahren muss der Raumname mit einem vorangestellten #-Zeichen im Titel des Termines stehen. Es wird ein API-Key für die Google-Calendar-API benötigt. Der Google-Kalender selbst muss auch öffentlich sein.

Der Abruf umfasst heute 00:00 Uhr bis übermorgen 00:00 Uhr in der lokalen CCU-Zeitzone. Längere konfigurierte Vor- oder Nachläufe erweitern diese Grenzen. Beide Grenzen enthalten ihren jeweils gültigen Zeitzonenversatz, auch bei einem Sommerzeitwechsel. Die anschließende lokale Auswahl nach Vor- und Nachlauf bleibt bestehen.

Pro Abruf werden höchstens 2500 Termine angefordert. Liefert Google ein `nextPageToken`, wird eine Fehlermeldung ausgegeben und bei aktiviertem Logging protokolliert. Die gelieferte Ergebnisseite wird wie bisher verarbeitet und die `HK1-Schaltliste` daraus aktualisiert. Weitere Ergebnisseiten werden nicht abgerufen. Termine auf diesen Seiten können deshalb fehlen, auch wenn weniger als 2500 Termine geliefert wurden. Dieses Verhalten wird aus Kompatibilitätsgründen beibehalten.

Benötigte Variablen: `HK1-GK-API-Key`, `HK1-GK-Kalender-ID`
Sowie die Variablen: `HK1-R-Liste`, `HK2-HKG-Liste`, `HK1-Schaltliste`, `HK1-Log`, `HK1-Logging`
Optional: `HK1-Vorlaufzeit`

### HK-Skript 1_iCal.hsc

Skript für den Zugriff auf einen iCal-Kalender über eine URL. Bei diesem Verfahren muss der Raumname mit einem vorangestellten #-Zeichen im Titel des Termines stehen.

Benötigte Variablen: `HK1-ICS-Url`
Sowie die Variablen: `HK1-R-Liste`, `HK2-HKG-Liste`, `HK1-Schaltliste`, `HK1-Log`, `HK1-Logging`
Optional: `HK1-Vorlaufzeit`

Die vorhandene RRULE-Verarbeitung bleibt auf einfache tägliche, wöchentliche, monatliche und jährliche Serien begrenzt. Die gezielten Korrekturen ersetzen den Parser nicht:

- `WEEKLY` ohne `BYDAY` behält den Wochentag des Serienbeginns; `INTERVAL=2` bedeutet alle zwei Wochen. Mit einer Wochentagsliste wie `BYDAY=MO,TH` werden nur die zum Intervall gehörenden Serienwochen berücksichtigt. Wochenbeginn ist Montag; `WKST` wird nicht zusätzlich unterstützt.
- `MONTHLY` mit einem einzelnen Positions-Wochentag wie `2MO`, `-1MO` oder `3TU` verwendet die entsprechende Monatsposition. Ein nicht vorhandener fünfter Wochentag wird in diesem Zweig übersprungen, nicht auf einen anderen Tag gekürzt. Die inklusive UNTIL-Grenze wird auch nach Berechnung des Monatstags berücksichtigt.
- Die vorhandene COUNT-Verarbeitung zählt gültige Kandidaten; die Korrektur ist keine vollständige RFC-Prüfung der Kombination von Serienbeginn, BYDAY und COUNT.
- DAILY und WEEKLY im vom bisherigen Parser lokal interpretierten TZID-Zweig führen das Kalenderdatum fort und setzen die ursprüngliche lokale Uhrzeit wieder ein. UTC- und Floating-Zweige behalten den bisherigen festen Sekundenfortschritt.

Die Auswertung von `DTSTART`, `DTEND` und `UNTIL` bleibt wie im Upstream-Skript. Ein benannter TZID-Wert wird nicht durch eine neue Zeitzonendatenbank umgerechnet; die verwendete lokale Zeit muss zur CCU passen. Ohne TZID bleibt die bisherige Umrechnung mit dem aktuellen Zeitversatz erhalten. Insbesondere UTC- und Floating-Serien können dadurch bei unterschiedlichen Sommer-/Winterzeitphasen verschoben sein. Diese Einschränkung wurde nicht durch einen neuen Datumsparser beseitigt.

Verwenden Sie positive Wiederholungsintervalle und nur die beschriebenen einfachen Regelkombinationen. Es gibt keine neue umfassende Eingabevalidierung, keine zusätzliche Kandidatengrenze und kein neues Vorspulen alter Serien. Ungültige Intervalle und weitere unbekannte oder kombinierte RRULE-Angaben können weiterhin falsch verarbeitet werden. Reine Datumswerte, DURATION, fremde Zeitzonen, BYDAY-Listen bei MONTHLY und weitere Parameter sind nicht zuverlässig vollständig unterstützt; sie werden nicht durch eine neue einheitliche Prüfschicht abgefangen.

Bei MONTHLY ohne Positions-BYDAY sowie YEARLY bleiben die bestehenden Einschränkungen bei nicht vorhandenen Monatstagen und Schaltjahren erhalten. Es wird nicht zugesagt, dass eine Serie vom 31. eines Monats oder vom 29. Februar vollständig RFC-gemäß fortgesetzt wird. Auch Ausnahmen (`EXDATE`), zusätzliche Vorkommen (`RDATE`), verschobene Einzeltermine (`RECURRENCE-ID`) und gefaltete Zeilen sind nicht vollständig abgedeckt. Die Dauer bleibt eine feste Sekundenzahl; pro Event und Lauf wird nur das erste passende Vorkommen ausgegeben.

**Prüfstand:** Der kleinere Korrekturumfang wird anhand gezielter lokaler Quell- und Referenzprüfungen unter `Tests/Skript1_iCal-Wiederholungen/` geprüft. Die früheren zehn isolierten CCU-Fälle gehörten zur inzwischen zurückgenommenen größeren Engine und sind kein Laufzeitnachweis dieser kleineren Fassung. Eine vollständige CCU-, Kalender- oder RFC-Abnahme wird nicht behauptet. Mehrdeutige beziehungsweise nicht existierende lokale Uhrzeiten während der Zeitumstellung bleiben ungeprüft.

## Schaltskript

> [!WARNING]
> __Wenn die `HeizkalenderInstallation.exe` verwendet wird, müssen die nachfolgenden Skripte für die Installation nicht installiert werden! Das Installationsprogramm führt alle notwendigen Operationen durch.__
>
> _Die Dokumentation dient nur zur Erklärung der Skript-Grundlagen und wenn es notwendig sein sollte, dass eine manuelle Installation erfolgen muss._

Das Schaltskript ist das Herzstück der Heizkalender Software. Es muss zwingend alle 5 Minuten laufen. Das Skript schaltet die Heizthermostate ein und auch wieder aus.

## HK-Skript 2.hsc

Das Skript 2 ist ein Hauptskript um eigentlichen Schaltzeiten zu berechnen.

Benötigte Variablen: `HK1-R-Liste`, `HK1-Schaltliste`, `HK2-Aussentemperatur`, `HK2-Grundtemperatur`, `HK2-HKG-Liste`, `HK2-Kurve`, `HK2-Kurvenversatz`, `HK2-Log`, `HK2-Logging`, `HK2-VorzeitAus`. Optional (wird beschrieben falls vorhanden): `HK2-Kurvenanpassung`, `HK2-Schaltzeiten`
Sowie weitere Raum-Variablen `HKG-Raum-*`

## HK-Skript 3.hsc

Das Skript 3 ist ein Hauptskript um die Thermostate zu schalten.

Temperatur-Sondervorgaben aus `HK2-Schaltliste` werden mit Nachkommastellen übernommen und an die Thermostate weitergegeben, beispielsweise 21,5 °C statt 21 °C.

Benötigte Variablen: `HK2-Schaltliste`, `HK2-A.Temp.Grenze`, `HK2-Aussentemperatur`, `HK2-Grundtemperatur`, `HK2-HKG-Liste`, `HK2-Hand-Grundtemp`, `HK2-Hand-Temp`, `HK3-Log`, `HK3-Logging`. Optional (wird beschrieben falls vorhanden): `HK2-Schaltzeiten`
Sowie weitere Raum-Variablen `HKG-Raum-*`

### Nachtschaltung

Ist `HK2-Hand-Grundtemp` auf `true` gesetzt, führt `HK-Skript 3` täglich zwischen 00:57 und 01:03 Uhr eine Nachtschaltung durch. Dabei werden alle Räume aus `HK2-HKG-Liste` geprüft. Räume mit einem aktiven Termin (Schaltzustand=1) werden übersprungen. Alle übrigen Räume werden auf Grundtemperatur gesetzt: bei Heizräumen (HSFlag=H) wird die Solltemperatur am Thermostat gesetzt, bei Schaltaktoren (HSFlag=S/HS) wird der Aktor ausgeschaltet. Die Prüfung und das Schalten erfolgen direkt am Aktor auf der CCU, nicht nur in der Systemvariablen. Die Nachtschaltung stellt damit sicher, dass keine Aktoren dauerhaft eingeschaltet bleiben, wenn ein Termin nicht sauber ausgeschaltet wurde.

### Schaltlistenprüfung

Bei jedem Skriptlauf (alle 5 Minuten) prüft `HK-Skript 3` zusätzlich alle Räume aus `HK2-HKG-Liste`. Für jeden Raum mit Schaltzustand=1 (aktiv) wird geprüft, ob er in diesem Lauf tatsächlich einen gültigen Schaltlisteneintrag hatte. Fehlt ein solcher Eintrag, wurde der Termin offenbar gelöscht oder der Ausschaltpunkt wurde verpasst. Der Raum wird dann sofort zurückgesetzt: die Systemvariable wird auf Schaltzustand=0 gesetzt und der Aktor direkt ausgeschaltet (Heiztyp H: Solltemperatur auf Grundtemperatur; Schalttyp: Relais auf AUS). Die Schaltlistenprüfung ist das Gegenstück zur Nachtschaltung: sie greift sofort im laufenden Betrieb, die Nachtschaltung dient als nächtliche Generalabsicherung.

## Sonstige Skripte

> [!WARNING]
> __Wenn die `HeizkalenderInstallation.exe` verwendet wird, müssen die nachfolgenden Skripte für die Installation nicht installiert werden! Das Installationsprogramm führt alle notwendigen Operationen durch.__
>
> _Die Dokumentation dient nur zur Erklärung der Skript-Grundlagen und wenn es notwendig sein sollte, dass eine manuelle Installation erfolgen muss._

Alle weiteren hier aufgeführten Skripte sind für den Betrieb des Heizkalenders dienlich.

### HK-Außentemperatur-Open-Meteo.hsc

Wenn kein Außenthermostat zur Verfügung steht, kann mit diesem Skript über die Geodaten der CCU und den [Deutschen Wetterdienst (DWD ICON-D2 über die Open-Meteo API)](https://open-meteo.com/en/docs/dwd-api) eine Außentemperatur ermittelt werden. Das Skript verwendet nicht den aktuellen Momentanwert, sondern berechnet einen gleitenden Durchschnitt über ein konfigurierbares Zeitfenster aus Vergangenheit und Prognose.

Konfigurierbare Parameter (im variablen Bereich des Skripts):

| Parameter | Standard | Bedeutung |
| :--- | :--- | :--- |
| `stundenZurueck` | 18 | Stunden in die Vergangenheit (max. 24) |
| `stundenVoraus` | 6 | Stunden Prognose voraus (max. 24) |

Der Durchschnitt wird über das gesamte Fenster (`stundenZurueck + stundenVoraus`) gebildet. Empfehlung laut Kommentar im Skript: `18/6` für Fußbodenheizungen, `12/3` für Heizkörper.

Das Skript schreibt einen Log-Eintrag mit aktuellem Messwert, Durchschnitt und dem verwendeten Zeitfenster, z.B.:

```text
Akt. AT= 4.2°C / Durchschn. AT= 6.1°C (Fenster: -18h/+6h)
```

Dieses Skript sollte jede Stunde einmal laufen.

Das Skript schreibt folgende Variablen:

| Variable | Bedeutung |
| :--- | :--- |
| `HK2-Aussentemperatur` | Gleitender Durchschnitt über das Zeitfenster, bei erfolgreicher Berechnung in die vorhandene Zielvariable geschrieben |
| `HK2-Aussentemperatur-Aktuell` | Momentanwert der letzten vollen Stunde (nur wenn die Variable vorhanden ist) |
| `HK2-Aussentemperatur-Abrufzeit` | Letzter erfolgreicher Abruf mit geschriebenem Durchschnitt, Unixsekunden als Zeichenkette (nur wenn die Variable vorhanden ist) |

`HK2-Aussentemperatur-Aktuell` ist eine optionale Variable: Das Skript schreibt sie nur, wenn sie auf der CCU bereits angelegt ist. Sie kann mit `HK-Init-Skript 2+3.hsc` angelegt werden.

#### HK2-Aussentemperatur-Abrufzeit

Die optionale Variable hat den Typ **Zeichenkette** und einen leeren Startwert; die Archivierung ist standardmäßig ausgeschaltet. Sie ist in `Skripte/HK-Init-Skript 2+3.hsc` enthalten. Das Init-Skript legt sie bei manueller Ausführung an, sofern sie noch fehlt, und lässt bereits vorhandene Variablen unverändert. Der Windows-Installer bleibt unverändert; die Anpassung muss mit der Installerpflege abgestimmt werden.

Alternativ kann die Variable in der CCU-WebUI unter **Einstellungen > Systemvariable** mit dem Namen `HK2-Aussentemperatur-Abrufzeit`, dem Typ **Zeichenkette** und zunächst leerem Inhalt angelegt werden. Bei einem konfigurierten Skriptpräfix dieses dem Namen voranstellen.

Nach erfolgreicher Berechnung und Schreiben von `HK2-Aussentemperatur` setzt das Open-Meteo-Skript die Abrufzeit auf die aktuellen Unixsekunden, auch wenn sich die Temperatur nicht geändert hat. Fehlerhafte Abrufe verändern die Abrufzeit nicht. Sie bezeichnet den erfolgreichen Abruf, nicht den Erstellungszeitpunkt der Wetterprognose. Die Variable nicht mit einem formatierten Datum befüllen; die lesbare Darstellung erfolgt im Addon. Bei einer alternativen Temperaturquelle ist der Zeitstempel keine Aktualitätsaussage für deren Messwerte.

Die Addon-Raumübersicht zeigt den letzten erfolgreichen Abruf und einen Warnhinweis, wenn dieser mehr als drei Stunden zurückliegt. Fehlt ein gültiger Zeitstempel, ist die Aktualität unbekannt. Diese Überwachung verändert weder die Vorheizberechnung noch das Ersatzverhalten bei Wetterausfall.


### HK-Heizkurvenkontrolle.hsc

Dieses Skript erzeugt zusätzliche Einträge im Systemprotokoll mit dem die aktuellen Vorheizzeiten der Räume kontrolliert werden können.

Dabei werden die folgenden Informationen im Systemprotokoll aufgezeichnet:

- Start des Heizens
- Erreichen der Zieltemperatur
- Start des Termins
- Ende der Heizphase
- Ende des Termines

Protokolliert werden die effektive Außentemperatur (beim Start), aktuelle Raumtemperatur, bisher erreichte maximale Raumtemperatur.

Ist die optionale Systemvariable `HK2-Aussentemperatur-Aktuell` vorhanden, wird die AT im erweiterten Format geloggt:

```
AT: 4.1 (akt=8.8)
```

Der Wert vor der Klammer ist der Durchschnitt, der für die VLZ-Berechnung verwendet wird. In der Klammer steht die aktuelle Temperatur. Ohne die optionale Variable wird nur der Durchschnitt geloggt (`AT: 4.1`).

Einträge tragen den Namen `HK-LogHeizkurvenkontrolle`.

### HK-SystemProtokoll sichern.hsc

Um über einen längeren Zeitraum die Systemprotokolle und damit auch die Heizkurven zu kontrollieren, ist es mit diesem Skript möglich das flüchtige Systemprotokoll auf einen USB Stick zu speichern.

Das Speichern des Protokolls erfolgt wochenweise. Üblicherweise werden maximal 30 Protokolle gespeichert bevor das älteste Protokoll gelöscht wird.
Dieses Skript sollte jeweils alle 23-87min laufen.

Bei einem Schreibfehler gibt das Skript den betroffenen Dateinamen und die Fehlerausgabe aus und bricht sofort ab. Bereits teilweise geschriebene Daten werden dabei nicht zurückgesetzt. Fehlermeldungen werden zusätzlich per `logger` als `user.err` ins syslog (`/var/log/messages`) geschrieben. Der erfolgreiche Abschluss erscheint dort als `user.info`-Eintrag (`HK-Protokollsicherung: Alles fertig`).

Sonderzeichen in Dateinamen und Fehlerausgaben werden für den Syslog-Aufruf maskiert, damit insbesondere Apostrophe die Übertragung der Fehlermeldung nicht verhindern.

Beachten Sie, dass ein Neustart oder Stromausfall zum Verlust der Einträge im Systemprotokoll führen kann, die in diesem Zeitraum noch nicht wieder gespeichert wurden.

### HK-Test-Skript.hsc

Dies ist ein einfaches Testskript, das die aktuellen Einstellungen des Heizkalenders teilweise prüft und alle Daten ausgibt. Dieses Protokoll kann für den Support oder das eigene Archiv genutzt werden.
