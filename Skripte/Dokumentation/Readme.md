# Beschreibung der Skripte und Programme

Dieser Ordner enthält alle Hauptkomponenten für den Heizkalender. Ein Teil der Skripte dient nur der Initialisierung. Diese haben das Kürzel _Init_ im Namen.

Skripte mit dem Namenskürzel _Skript 1_ beschreiben die verschiedenen Methoden Termine für den Heizkalender auszulesen.

Das _Skript 2_ ist das Hauptskript zum Schalten der Heizung.

## HeizkalenderInstallation.exe

Die HeizkalenderInstallation.exe dient zur Installation und Einrichtung der verschiedenen Skriptvarianten.
Dieses Programm kann bestehende Installationen aktualisieren oder kann einfach neue Installationen erzeugen.

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
- HK-SystemProtokoll sichern

## Skripte zur Initialisierung

Die folgenden Variablen werden in allen Skripten vom Typ 1 und natürlich vom Schaltskript 2 verwendet.

| Variable | Bedeutung |
| :--------------- | :--------- |
| HK1-Schaltliste | Schaltlisten Einträge. Hier werden vom Skript die ermittelten und zu schaltenden Termine eingetragen |
| HK1-R-Liste | Raumliste der Churchdesk Ressourcen. Bestehende aus einer Id und optional gefolgt von einem Gleichheitszeichen mit dem Raumnamen als Text |
| HK2-HKG-Liste | Semikolon getrennte Liste der Raumvariablen. Zu jedem Eintrag der Ressourcen Liste HK1-R-Liste, der entsprechende Raum Eintrag. Jeder Ressource können mehrere Räume zugeordnet werden indem die einzelnen Räume durch ein + Zeichen getrennt werden. |

### HK-Init-Skript 1_ChurchDesk.hsc

Dieses Skript legt alle Systemvariablen an, die für den Zugriff auf ChruchDesk benötigt werden. Es spielt hier keine Rolle ob der Zugriff über die ChurchDesk API oder die ChurchDesk iCal Schnittstelle erfolgt.

| Variable | Bedeutung |
| :--------------- | :--------- |
| HK1-CD-OrganisationsId | ChurchDesk Id der Kirche oder Gemeinde |
| HK1-CD-Token | API-Token für den Zugriff auf die Pull-API von ChurchDesk. Dieses Token wird durch den Support von ChurchDesk vergeben. |

Werden diese beiden Variablen im Init-Skript korrekt ausgefüllt ermittelt das Skript alle Ressourcen, die in ChurchDesk angelegt wurden. Es werden dann entsprechende Raumvariablen erzeugt.

Dieses Skript wird für den Zugriff über die iCal oder API Schnittstelle benötigt.

### HK-Init-Skript 1_ChurchTools.hsc

Dieses Skript dient zum Anlegen aller Systemvariablen um Termine aus den Ressourcen der ChurchTools API zu lesen.

| Variable | Bedeutung |
| :--------------- | :--------- |
| HK1-CT-Gemeindename | Name der Gemeinde im ChurchTools URL. `xyz`.church.tools |
| HK1-CT-Token | Login Token für einen Benutzer in ChurchTools. Dieses Login-Token muss einmalig ermittelt werden. Der Benutzer benötigt ausschließlich lesenden Zugriff auf die Kalender und Ressourcen. |

Werden diese beiden Variablen im Init-Skript korrekt ausgefüllt ermittelt das Skript alle Ressourcen vom Typ `Raum`, die in ChurchTools angelegt wurden. Es werden dann entsprechende Raumvariablen erzeugt.

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

> [!WARNING]
> Das `RRULE` Schlüsselwort (Terminwiederholungen) wird nicht unterstützt.

### HK-Init-Skript 2.hsc

Dieses Skript legt alle Systemvariablen an, die für das Schalt-Skript benötigt werden.

| Variable | Bedeutung |
| :--------------- | :--------- |
| HK2-Grundtemperatur | Grundtemperatur für alle Räume außerhalb einer Heizphase |
| HK2-A.Temp.Grenze | Außentemperatur ab der kein Heizen mehr erfolgt |
| HK2-Aussentemperatur | Aktuelle Außentemperatur (wird durch Skript _HK-Außentemperatur-Open-Meteo.hsc_) gesetzt oder alternativ durch einen Außentemperatursensor. |
| HK2-Hand-Temp | Wenn `true` Vorrang einer manuell am Thermostat eingestellten Temperatur beim Ausschalten |
| HK2-Hand-Grundtemp | Wenn `true` aktiviert die Nachtschaltung. HK-Skript 2 prüft täglich zwischen 00:57 und 01:03 Uhr alle Räume und setzt sie auf Grundtemperatur, sofern kein aktiver Termin (Schaltzustand=1) vorliegt. Bei Heizräumen (HSFlag=H) wird die Solltemperatur am Thermostat gesetzt, bei Schaltaktoren (HSFlag=S/HS) wird der Aktor ausgeschaltet. Die Prüfung erfolgt direkt am Aktor, nicht nur in der Systemvariablen. |
| HK2-VorzeitAus | Globale Grundoffsetzeit in Minuten, um die vor Terminende ausgeschaltet wird. Wird nur bei Heizvorgängen angewendet, nicht bei reinem Schalten. Gegenstück zu HK2-Kurvenversatz (Einschalt-Offset). Default: 0 |
| HK2-Kurvenversatz | Globale Grundoffsetzeit in Minuten, um die vor Terminbeginn eingeschaltet wird. Wird nur bei Heizvorgängen angewendet, nicht bei reinem Schalten. Gegenstück zu HK2-VorzeitAus (Ausschalt-Offset). Default: 0 |
| HK2-Kurve | Heizkurve: 8 Vorlaufzeiten in Minuten zu den Außentemperatur-Stützpunkten −10, −5, 0, 8, 10, 12, 15, 17,5 °C (semikolongetrennt). Zwischen den Stützpunkten interpoliert HK-Skript 2 linear; der höchste Wert (bei tiefster Außentemperatur) ist die längste Vorheizzeit. Installtion-Default (konservativ): `162;130;100;59;50;41;30;20` (max. 162 min ≈ 2,7 h). Als Orientierungshilfe sind drei Beispielkurven bekannt (konservativ / mittel / großzügig); Details und eine vollständige Vergleichstabelle siehe [Anwenderhandbuch](../../Dokumentation/Anwenderhandbuch.md) und [Heizsteuerung-Vorheizzeit.md](Heizsteuerung-Vorheizzeit.md). |
| HK2-Log | Variable für das Schalt-Log (siehe Abschnitt _HK-Init-Variablen Logging.hsc_) |
| HK2-Logging | Flag das Logging vom Typ `HK2-Log` steuert (siehe Abschnitt _HK-Init-Variablen Logging.hsc_) |

### HK-Init-Variablen Logging.hsc

Dieses Skript legt alle Systemvariablen an, die für die Protokollierung über das Systemprotokoll benötigt werden.
Die Protokollierung erfolgt über die nachfolgenden Kategorien:

- Allgemeines Log. Einträge tragen den Namen _HK-Log_.
- Logging für die Skripte vom Typ 1. Hier werden die Zugriffe auf die Kalender protokolliert. Einträge tragen den Namen _HK1-Log_.
- Logging für das Skript vom Typ 2. Hier werden die Schaltvorgänge der Heizung protokolliert und auch alle Sonderfunktionen, wie das Rückstellen der Heizung auf Grundtemperatur oder das Abschalten der Heizung, wenn der betroffene Termin gelöscht wird.  Einträge tragen den Namen _HK2-Log_.
- Logging für die Heizkurvenkontrolle. Um die Heizkurve kontrollieren zu können, werden spezielle Einträge im Systemprotokoll verzeichnet: Start des Heizens, Erreichen der Zieltemperatur, Start des Termins, Ende der Heizphase, Ende des Termines. Protokolliert werden Außentemperatur (beim Start), aktuelle Temperatur, bisher erreichte maximale Temperatur.  Einträge tragen den Namen _HK-LogHeizkurvenkontrolle_.

| Variable | Bedeutung |
| :--------------- | :--------- |
| HK-Logging | Flag das Logging vom Typ `HK-Log` steuert |
| HK-Log | Variable um ein einfaches Log im System Protokoll zu erzeugen |
| HK1-Logging | Flag das Logging vom Typ `HK1-Log` steuert |
| HK1-Log | Variable um ein einfaches Log im System Protokoll zu erzeugen |
| HK2-Logging | Flag das Logging vom Typ `HK2-Log` steuert |
| HK2-Log | Variable um ein einfaches Log im System Protokoll zu erzeugen |
| HK-LoggingHeizkurvenkontrolle | Flag das Logging vom Typ `HK-LogHeizkurvenkontrolle` steuert |
| HK-LogHeizkurvenkontrolle | Variable um ein einfaches Log im System Protokoll zu erzeugen |
| HK-RäumeHeizkurvenkontrolle | Variable in der der Status für die Heizkurvenkontrolle mehrerer Räume verzeichnet wird |

## Skripte zum Einlesen der Termindaten aus diversen Quellen

Es wird für den Betrieb des Heizkalenders eine der nachfolgenden Datenquellen (ChurchTools, ChurchDesk, iCal, Google-Kalender) benötigt. Das entsprechende Skript sollte ca. alle 30 min laufen um die Termine für die nächsten Heizzyklen zu bestimmen.

Alle diese Skripte bedienen die Variable `HK1-Schaltliste`. In dieser Variable werden aktuelle Termine eingetragen, die durch das Schaltskript 2 berücksichtigt werden sollen.

### HK-Skript 1_ChurchDeskAPI.hsc

Skript für den Zugriff auf die internen Kalender in ChurchDesk über die ChurchDesk API.

> [!WARNING]
> Aktuell können nur öffentliche Termine über die ChurchDesk API gelesen werden. Ist ein Termin als privat oder nur für bestimmte Gruppen sichtbar, wird dieser Termin nicht für den Heizkalender berücksichtigt. Aktuell kann nur die ChurchDesk iCal Variante alle Termine lesen.

Benötigte Variablen: `HK1-CD-OrganisationsId`, `HK1-CD-Token`
Sowie die Variablen: `HK1-R-Liste`, `HK2-HKG-Liste`, `HK1-Schaltliste`, `HK1-Log`, `HK1-Logging`

### HK-Skript 1_ChurchDeskiCal.hsc

Skript für den Zugriff auf die internen Kalender in ChurchDesk über die ChurchDesk iCal Kalender der Ressourcen.

Benötigte Variablen: `HK1-CD-OrganisationsId`, `HK1-CD-Token`
Sowie die Variablen: `HK1-R-Liste`, `HK2-HKG-Liste`, `HK1-Schaltliste`, `HK1-Log`, `HK1-Logging`

### HK-Skript 1_ChurchTools.hsc

Skript für den Zugriff auf die internen Kalender in ChurchTools über die ChurchTools-API auf die Kalender der Ressourcen.

Benötigte Variablen: `HK1-CT-Gemeindename`, `HK1-CT-Token`
Sowie die Variablen: `HK1-R-Liste`, `HK2-HKG-Liste`, `HK1-Schaltliste`, `HK1-Log`, `HK1-Logging`

### HK-Skript 1_Google.hsc

Skript für den Zugriff auf einen Kalender in Google über die Google Calendar-API. Bei diesem Verfahren muss der Raumname mit einem vorangestellten #-Zeichen im Titel des Termines stehen. Es wird ein API-Key für die Google-Calendar-API benötigt. Der Google-Kalender selbst muss auch öffentlich sein.

Benötigte Variablen: `HK1-GK-API-Key`, `HK1-GK-Kalender-ID`
Sowie die Variablen: `HK1-R-Liste`, `HK2-HKG-Liste`, `HK1-Schaltliste`, `HK1-Log`, `HK1-Logging`

### HK-Skript 1_iCal.hsc

Skript für den Zugriff auf einen iCal-Kalender über eine URL. Bei diesem Verfahren muss der Raumname mit einem vorangestellten #-Zeichen im Titel des Termines stehen.

Benötigte Variablen: `HK1-ICS-Url`
Sowie die Variablen: `HK1-R-Liste`, `HK2-HKG-Liste`, `HK1-Schaltliste`, `HK1-Log`, `HK1-Logging`

## Schaltskript

Das Schaltskript ist das Herzstück der Heizkalender Software. Es muss zwingend alle 5 Minuten laufen. Das Skript schaltet die Heizthermostate ein und auch wieder aus.

## HK-Skript 2.hsc

Das Skript 2 ist das Hauptskript um die Thermostate zu schalten.

Benötigte Variablen: `HK1-R-Liste`, `HK1-Schaltliste`, `HK2-A.Temp.Grenze`, `HK2-Aussentemperatur`, `HK2-Grundtemperatur`, `HK2-HKG-Liste`, `HK2-Hand-Grundtemp`, `HK2-Hand-Temp`, `HK2-Kurve`, `HK2-Kurvenversatz`, `HK2-Log`, `HK2-Logging`, `HK2-VorzeitAus`
Sowie weitere Raum-Variablen `HKG-Raum-*`

### Nachtschaltung

Ist `HK2-Hand-Grundtemp` auf `true` gesetzt, führt HK-Skript 2 täglich zwischen 00:57 und 01:03 Uhr eine Nachtschaltung durch. Dabei werden alle Räume aus `HK2-HKG-Liste` geprüft. Räume mit einem aktiven Termin (Schaltzustand=1) werden übersprungen. Alle übrigen Räume werden auf Grundtemperatur gesetzt: bei Heizräumen (HSFlag=H) wird die Solltemperatur am Thermostat gesetzt, bei Schaltaktoren (HSFlag=S/HS) wird der Aktor ausgeschaltet. Die Prüfung und das Schalten erfolgen direkt am Aktor auf der CCU, nicht nur in der Systemvariablen. Die Nachtschaltung stellt damit sicher, dass keine Aktoren dauerhaft eingeschaltet bleiben, wenn ein Termin nicht sauber ausgeschaltet wurde.

### Schaltlistenprüfung

Bei jedem Skriptlauf (alle 5 Minuten) prüft HK-Skript 2 zusätzlich alle Räume aus `HK2-HKG-Liste`. Für jeden Raum mit Schaltzustand=1 (aktiv) wird geprüft, ob er in diesem Lauf tatsächlich einen gültigen Schaltlisteneintrag hatte. Fehlt ein solcher Eintrag, wurde der Termin offenbar gelöscht oder der Ausschaltpunkt wurde verpasst. Der Raum wird dann sofort zurückgesetzt: die Systemvariable wird auf Schaltzustand=0 gesetzt und der Aktor direkt ausgeschaltet (Heiztyp H: Solltemperatur auf Grundtemperatur; Schalttyp: Relais auf AUS). Die Schaltlistenprüfung ist das Gegenstück zur Nachtschaltung: sie greift sofort im laufenden Betrieb, die Nachtschaltung dient als nächtliche Generalabsicherung.

## Sonstige Skripte

Alle weiteren hier aufgeführten Skripte sind für den Betrieb des Heizkalenders dienlich.

### HK-Außentemperatur-Open-Meteo.hsc

Wenn kein Außenthermostat zur Verfügung steht, kann mit diesem Skript über die Geodaten der CCU und den Deutschen Wetterdienst (Open-Meteo API) eine Außentemperatur ermittelt werden. Das Skript verwendet nicht den aktuellen Momentanwert, sondern berechnet einen gleitenden Durchschnitt über ein konfigurierbares Zeitfenster aus Vergangenheit und Prognose.

Konfigurierbare Parameter (im variablen Bereich des Skripts):

| Parameter | Standard | Bedeutung |
| :--- | :--- | :--- |
| `stundenZurueck` | 18 | Stunden in die Vergangenheit (max. 48) |
| `stundenVoraus` | 6 | Stunden Prognose voraus (max. 24) |

Der Durchschnitt wird über das gesamte Fenster (`stundenZurueck + stundenVoraus`) gebildet. Empfehlung laut Kommentar im Skript: `18/6` für Fußbodenheizungen, `12/3` für Heizkörper.

Das Skript schreibt einen Log-Eintrag mit aktuellem Messwert, berechnetem Durchschnitt und dem verwendeten Zeitfenster, z.B.:

```text
Akt. Außentemperatur= 20.5°C / Durchsch. Außentemperatur= 14.8°C (Zeitfenster: -18h/+6h)
```

Dieses Skript sollte jede Stunde einmal laufen.

Das Skript trägt die berechnete Durchschnittstemperatur in die Variable `HK2-Aussentemperatur` ein.

### HK-Heizkurvenkontrolle.hsc

Dieses Skript erzeugt zusätzliche Einträge im Systemprotokoll mit dem die aktuellen Vorheizzeiten der Räume kontrolliert werden können.

Dabei werden die folgenden Informationen im Systemprotokoll aufgezeichnet:

- Start des Heizens
- Erreichen der Zieltemperatur
- Start des Termins
- Ende der Heizphase
- Ende des Termines

Protokolliert werden Außentemperatur (beim Start), aktuelle Temperatur, bisher erreichte maximale Temperatur.

Einträge tragen den Namen `HK-LogHeizkurvenkontrolle`.

### HK-SystemProtokoll sichern.hsc

Um über einen längeren Zeitraum die Systemprotokolle und damit auch die Heizkurven zu kontrollieren, ist es mit diesem Skript möglich das flüchtige Systemprotokoll auf einen USB Stick zu speichern.

Das Speichern des Protokolls erfolgt wochenweise. Üblicherweise werden maximal 10 Protokolle gespeichert bevor das älteste Protokoll gelöscht wird.
Dieses Skript sollte jeweils alle 23-87min laufen.

Beachten Sie, dass ein Neustart oder Stromausfall zum Verlust der Einträge im Systemprotokoll führen kann, die in diesem Zeitraum noch nicht wieder gespeichert wurden.

### HK-Test-Skript.hsc

Dies ist ein einfaches Testskript, das die aktuellen Einstellungen des Heizkalenders teilweise prüft und alle Daten ausgibt. Dieses Protokoll kann für den Support oder das eigene Archiv genutzt werden.
