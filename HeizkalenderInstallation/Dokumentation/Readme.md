> [!NOTE]
> Diese Datei ist im Markdown-Format geschrieben. Wird sie in einem normalen Texteditor geöffnet, sind darin Formatierungszeichen (z. B. `#`, `**`, `|`) sichtbar. Mit allen Formatierungen können Sie die Datei online ansehen unter:
> <https://github.com/xMRi/Homematic-Heizungskalender/blob/main/Skripte/Readme.md>

# `HeizkalenderInstallation.exe`

Die `HeizkalenderInstallation.exe` ist ein Tool zur Erstellung von Heizkalendern für die Homematic auf Basis von Daten aus ChurchTools, ChurchDesk, iCal oder Google Kalender.

Sie ermöglicht die Neuinstallation sowie Updates bestehender Installationen und bietet eine benutzerfreundliche Oberfläche zur Konfiguration der Heizkalender. Außerdem unterstützt sie die Generierung von Skripten und der notwendigen Systemvariablen, die in der Homematic CCU oder ähnlichen Systemen verwendet werden können.

Dabei legt die `HeizkalenderInstallation.exe` alle für den Betrieb des Heizkalenders erforderlichen Programme und Systemvariablen an. Einzig die Geräte müssen angemeldet und nach Möglichkeit in Heizgruppen zusammengefasst werden.

Bei der Nutzung von ChurchTools/ChurchDesk werden bei Bedarf auch alle Raumvariablen automatisch erzeugt und zugewiesen.

## Inhalt

- [Systemvoraussetzungen](#systemvoraussetzungen)
- [Vorsichtsmaßnahmen](#Vorsichtsmaßnahmen)
- [Vorbereiten der CCU](#vorbereiten-der-ccu)
- [Kurzanleitung](#kurzanleitung)
  - [Neuinstallation](#neuinstallation)
  - [Parameter ändern oder Update installieren](#parameter-ändern-oder-update-installieren)
  - [Anpassung der Raumliste](#anpassung-der-raumliste)
- [Beschreibung der `HeizkalenderInstallation.exe`](#beschreibung-der-heizkalenderinstallationexe)
  - [Eigenschaftsseite *Verbinden mit der CCU*](#eigenschaftsseite-verbinden-mit-der-ccu)
  - [Einrichten einer neuen Installation](#einrichten-einer-neuen-installation)
  - [Nach dem Verbindungsaufbau mit der CCU](#nach-dem-verbindungsaufbau-mit-der-ccu)
  - [Eigenschaftsseite *Programme / Skripte*](#eigenschaftsseite-programme--skripte)
  - [Eigenschaftsseite *Einstellungen*](#eigenschaftsseite-einstellungen)
  - [Eigenschaftsseite *Kalenderzuordnung*](#eigenschaftsseite-kalenderzuordnung)
  - [Eigenschaftsseite *Räume*](#eigenschaftsseite-räume)
  - [Eigenschaftsseite *Systemvariablen*](#eigenschaftsseite-systemvariablen)
- [Speichern der Einstellungen](#speichern-der-einstellungen)
  - [Abbrechen der Installation](#abbrechen-der-installation)
- [Logdateien der `HeizkalenderInstallation.exe`](#logdateien-der-heizkalenderinstallationexe)
- [Zugriff von außerhalb mit dem `HeizkalenderInstallation.exe`](#zugriff-von-außerhalb-mit-dem-heizkalenderinstallationexe)

## Systemvoraussetzungen

- Betriebssystem: Windows
- Die CCU muss in den Sicherheitseinstellungen den Zugriff auf die Remote Homematic-Script API erlauben. Dabei muss entweder ein eingeschränkter Zugriff auf die benötigten Funktionen oder ein Vollzugriff gewährt werden, damit die `HeizkalenderInstallation.exe` die notwendigen Skripte und Variablen erstellen kann.
- Ein Administrator-Benutzer und das zugehörige Kennwort müssen bekannt sein.
- Alle Skripte, die installiert werden sollen, müssen im Programmverzeichnis der `HeizkalenderInstallation.exe` liegen. Die Namen sind vorgegeben und dürfen nicht verändert werden. Es können weitere Tool-Skripte hinzugefügt werden. Diese werden ebenfalls installiert und später aktualisiert, solange die entsprechenden Dateien im Verzeichnis der `HeizkalenderInstallation.exe` liegen.
- Um auf Ressourcen und externe Kalender zugreifen zu können, muss der Rechner mit dem Internet verbunden sein.
- Eine lauffähige Kopie der `HeizkalenderInstallation.exe` liegt im Skripte-Verzeichnis.

## Vorsichtsmaßnahmen

> [!WARNING]
> Viele Änderungen, die durch die `HeizkalenderInstallation.exe` vorgenommen werden, können nicht rückgängig gemacht werden. Dazu gehört das Anlegen, Überschreiben und Löschen von Programmen, Skripten und Systemvariablen auf der CCU. Auch das erneute Einlesen der Raumliste, das Löschen von Kalendereinträgen oder Räumen und der Wechsel der Terminquelle können Einstellungen und Zuordnungen unwiderruflich verändern.
>
> **Erstellen Sie deshalb vor jeder Installation, jedem Update und jeder größeren Änderung ein aktuelles Backup der CCU, um bei Problemen den letzten funktionierenden Stand wiederherstellen zu können.**
>
> Die Nutzung der `HeizkalenderInstallation.exe` und der zugehörigen Skripte erfolgt auf eigene Gefahr. Für Schäden oder Datenverluste wird keine Haftung übernommen.

## Vorbereiten der CCU

Damit die `HeizkalenderInstallation.exe` ausgeführt werden kann, muss der Zugriff auf die Homematic-Script-API freigeschaltet werden. Dies geschieht in der Homematic-WebUI unter *Einstellungen → Firewall konfigurieren → Remote Homematic-Script API*. Dort wird entweder *Vollzugriff* eingestellt:

![CCU-Zugriff: Vollzugriff](Bilder/CCU-Zugriff-1.png)

Oder es wird *Eingeschränkter Zugriff* erteilt und die IP-Adresse des Rechners, von dem aus zugegriffen wird, freigegeben:

![CCU-Zugriff: Eingeschränkter Zugriff](Bilder/CCU-Zugriff-2.png)

Freigegebene IP-Adresse für den Zugriff:

![CCU-Zugriff: Freigegebene IP-Adresse](Bilder/CCU-Zugriff-3.png)

## Kurzanleitung

Die Kurzanleitung zeigt, welche Schritte bei einer Neuinstallation, einem Update oder einer Korrektur der Einstellungen durchgeführt werden müssen.

### Neuinstallation

Außer der `HeizkalenderInstallation.exe` sind keine weiteren Programme oder Skripte auszuführen. Sie wird direkt auf eine „leere“, frische CCU angewendet. Die entsprechenden Geräte sollten angelernt und in Heizgruppen zusammengefasst sein.

1. CCU vorbereiten (es sollten keine HK-Skripte oder -Variablen vorhanden sein)
1. Geräte und Heizgruppen einrichten
1. `HeizkalenderInstallation.exe` starten
1. Verbindungsdaten angeben
1. **Verbinden mit der CCU** anklicken
1. Ressourcenquelle auswählen (ChurchTools/ChurchDesk/iCal/Google)
1. **Ressourcen / Räume einlesen** anklicken
1. Einstellungen vornehmen
1. **OK** anklicken

### Parameter ändern oder Update installieren

Für ein Update oder das Ändern der aktuellen Parameter starten Sie die `HeizkalenderInstallation.exe` und nehmen anschließend die gewünschten Änderungen vor. Sind neuere Skripte oder Module vorhanden, werden diese automatisch aktualisiert.

1. `HeizkalenderInstallation.exe` starten
1. **Verbinden mit der CCU** anklicken
1. Anpassungen durchführen
1. **OK** anklicken

### Anpassung der Raumliste

> [!WARNING]
> Die Raumliste sollte nur dann neu eingelesen werden, wenn sich die Räume oder die Anzahl der zu verwaltenden Ressourcen ändern. Andernfalls können Einstellungen verloren gehen.

1. `HeizkalenderInstallation.exe` starten
1. **Verbinden mit der CCU** anklicken
1. **Ressourcen / Räume einlesen** anklicken und die angezeigten Fragen und Warnungen beantworten
1. Anpassungen durchführen
1. **OK** anklicken

## Beschreibung der `HeizkalenderInstallation.exe`

Im Folgenden werden die einzelnen Seiten der `HeizkalenderInstallation.exe` beschrieben.

Greundsätzlich kann die *Eigenschaftseite Vwerbindung zur CCU* nicht verlassen werden, solange keine Verbindung erfolgreich hergestellt wurde.


Die Eigenschaftseiten *Programme, Einstellungen, Kalenderzuordnungen, Räume* und *Systemvariablen* werden im nachfolgenden beschrieben.

### Eigenschaftsseite *Verbinden mit der CCU*

Der Startbildschirm enthält wichtige Informationen über die `HeizkalenderInstallation.exe`. Hier finden sich die aktuelle Version des Heizkalenders und der aktuelle Stand der Skripte, die installiert werden können.

![Mit CCU verbinden](Bilder/HKI-Verbinden.png)

Über den Schalter **Info über...** können der genaue Softwarestand und die Lizenz der `HeizkalenderInstallation.exe` angezeigt werden. Außerdem lässt sich ein Browserfenster mit dem GitHub-Projekt öffnen, um gegebenenfalls eine neue Programmversion herunterzuladen.

![Info über](Bilder/HKI-InfoÜber.png)

#### Verbinden mit der CCU

Im ersten Schritt muss eine Verbindung zur CCU aufgebaut werden, bevor weitere Einstellungen vorgenommen werden können.

1. Geben Sie die Ziel-IP der CCU an.
2. Geben Sie einen Benutzernamen an, der administrativen Zugriff auf die CCU hat.
3. Geben Sie das passende Kennwort an.
4. Geben Sie optional einen Prefix für Variablen und Skripte an (siehe Hinweis unten).
5. Klicken Sie auf den Schalter **Verbinden mit der CCU**.

> [!NOTE]
> Das Feld **Prefix** bleibt im Allgemeinen leer. Wird ein Prefix angegeben, erhalten alle Skripte, Programme und Variablen des Heizkalenders diesen Prefix im Namen vorangestellt.
>
> Damit lassen sich mehrere Installationen parallel testen oder eine Installation von bereits bestehenden Systemvariablen oder Programmen abgrenzen. Wird die bestehende Installation einer CCU ausgelesen, wird erwartet, dass alle bisher genutzten Variablen und Programme diesen Prefix verwenden.

> [!CAUTION]
> Wird der Prefix falsch verwendet, können Skripte und Variablen mehrfach installiert werden. Das kann zu Fehlfunktionen und zu einer Überlastung der CCU führen. Sollen mehrere Installationen parallel getestet werden, achten Sie darauf, dass immer nur ein Satz Programme aktiviert ist.
>
> **Nutzen Sie dieses Feld nur, wenn Sie sich über die Folgen im Klaren sind!**

#### Fehler beim Verbindungsaufbau

Ist keine Verbindung zur CCU möglich, weil die Verbindungsdaten (IP, Benutzername und Kennwort) nicht stimmen, erhalten Sie eine Fehlermeldung:

![Keine Verbindung](Bilder/HKI-Verbindungsfehler.png)

> [!NOTE]
> Konnte eine Verbindung hergestellt werden, werden die aktuellen Verbindungsinformationen in der Registry des aktuellen Benutzers gespeichert. Beim Neustart der `HeizkalenderInstallation.exe` sind die Felder **IP-Adresse**, **Benutzername**, **Kennwort** und **Prefix** dann bereits ausgefüllt.

### Einrichten einer neuen Installation

Ist bisher keine Installation auf der CCU vorhanden, erhalten Sie diese Meldung:

![Neue Installation](Bilder/HKI-NeueInstallation1.png)

#### Auswahl der Ressourcen-/Terminquelle

Wählen Sie die gewünschte Quelle für Ihre Termine (ChurchTools, ChurchDesk, iCal, Google):

![Neue Installation: Ressourcenquelle](Bilder/HKI-NeueInstallation2.png)

Beachten Sie, dass die Terminquelle auch nachträglich geändert werden kann. Die entsprechenden Skripte werden in diesem Fall geändert und überschrieben, und die Verbindungsdaten müssen angepasst werden.

Für jede Heizkalender-Variante sind unterschiedliche Informationen zum Auslesen/Aktualisieren der Ressourcen und Kalender notwendig. Diese werden nachfolgend beschrieben.

![Neue Installation: Angaben zur Terminquelle](Bilder/HKI-NeueInstallation3.png)

##### Verbindungsdaten angeben – ChurchDesk

Die benötigten Zugangsdaten für ChurchDesk sind bei den Varianten API und iCal identisch.

![ChurchDesk-iCal-Zugangsdaten](Bilder/HKI-ModusCDiCal.png)

![ChurchDesk-API-Zugangsdaten](Bilder/HKI-ModusCDAPI.png)

##### Verbindungsdaten angeben – ChurchTools

![ChurchTools-Zugangsdaten](Bilder/HKI-ModusCT.png)

##### Verbindungsdaten angeben – iCal

![iCal-Zugangsdaten](Bilder/HKI-ModusiCal.png)

##### Verbindungsdaten angeben – Google

![Google-Zugangsdaten](Bilder/HKI-ModusGoogle.png)

### Nach dem Verbindungsaufbau mit der CCU

Bei einer bestehenden, eingerichteten CCU erhalten Sie eine Anzeige über den Verbindungsstatus und die Art der genutzten Ressourcen, wie in der folgenden Abbildung zu sehen ist.

![Verbunden mit der CCU](Bilder/HKI-Verbunden.png)

#### Wechsel zu einer anderen Ressourcen-Variante

<!-- TODO: Dokumentation oder Screenshot einfügen -->

### Eigenschaftsseite *Programme / Skripte*

Über diese Seite der `HeizkalenderInstallation.exe` werden alle installierten Programme angezeigt. Liegt für ein Programm ein Update vor, wird dies in der Informationsspalte angezeigt. Außerdem werden der aktuelle Programmstand und der Stand des Updates angezeigt, sofern vorhanden.

Die Programme mit den folgenden Namen sind reserviert und werden von der `HeizkalenderInstallation.exe` automatisch berücksichtigt. Sie müssen im Programmverzeichnis der `HeizkalenderInstallation.exe` liegen:

- `HK-Außentemperatur-Open-Meteo.hsc`
- `HK-Heizkurvenkontrolle.hsc`
- `HK-Skript 1.hsc`
- `HK-Skript 2.hsc`
- `HK-Systemprotokoll sichern.hsc`

Liegen im Installationsverzeichnis der `HeizkalenderInstallation.exe` auch Dateien mit dem Namen `Tool-*.hsc`, werden gleichnamige Programme in der CCU bei Bedarf ebenfalls aktualisiert. Das normale Installationspaket enthält keine Tools; diese befinden sich im separaten Ordner [Tools](../Tools).

![Übersicht der Programme](Bilder/HKI-Programme.png)

#### Änderungen in Skripten anzeigen

Ist das optionale Programm [WinMerge](https://winmerge.org) installiert, startet ein Klick auf den Schalter **Änderungen...** oder ein Doppelklick auf eines der Programme den Vergleich. Damit lassen sich die Änderungen zwischen altem und neuem Programmstand anzeigen und vergleichen.

### Eigenschaftsseite *Einstellungen*

Die Einstellungen auf dieser Seite beeinflussen das Grundverhalten des Heizkalenders.

![Allgemeine Einstellungen](Bilder/HKI-Einstellungen.png)

#### Protokollierung im Systemprotokoll

Um die Funktionsweise des Heizkalenders transparent zu machen, wird das Systemprotokoll benutzt. Die Protokollierung kann dabei sehr granular aktiviert werden.

- **Allgemeine Protokollierung der Heizkalenderfunktionen**<br>
  Diese Funktion umfasst die Protokollierung allgemeiner Skripte, wie zum Beispiel die Außentemperaturermittlung. Über diese Option kann die Protokollierung ein- und ausgeschaltet werden.
  <br>
  Dieser Wert wird in der Variable `HK-Logging` gespeichert.

- **Protokollierung für Skript 1**<br>
  Das `HK-Skript 1` dient dazu, die Termine aus den verschiedenen Terminquellen (ChurchDesk, ChurchTools, Google, iCal) einzulesen. Über diese Option kann die Protokollierung ein- und ausgeschaltet werden.<br>
  Dieser Wert wird in der Variable `HK1-Logging` gespeichert.

- **Protokollierung für Skript 2**<br>
  Das `HK-Skript 2` führt anhand der gelesenen Termine die eigentlichen Schaltvorgänge für die Heizungssteuerung durch. Über diese Option kann die Protokollierung ein- und ausgeschaltet werden.
  <br>
  Dieser Wert wird in der Variable `HK2-Logging` gespeichert.

- **Protokollierung für die Heizkurvenkontrolle**<br>
  Das spezielle Skript `HK-Heizkurvenkontrolle` analysiert die aktuellen Heiztemperaturen. Mit den Einträgen dieses Protokolls lässt sich die Heizkurve optimieren oder grundsätzlich prüfen, ob die eingestellte Heizkurve funktioniert.<br>
  Dieser Wert wird in der Variable `HK-LoggingHeizkurvenkontrolle` gespeichert.

Beachten Sie, dass das Systemprotokoll nicht unendlich lang ist. Um das Heizverhalten über einen längeren Zeitraum beobachten zu können, sollten Sie einen USB-Stick einstecken und das Skript `HK-Systemprotokoll sichern` aktivieren. Dieses Skript speichert ältere Einträge des Systemprotokolls zyklisch auf dem USB-Stick. Ist kein USB-Stick eingesteckt, hat das Programm keine Wirkung.

#### Rückstellungsverhalten

- **Alle Räume Nachts um 01:00 Uhr auf Grundtemperatur zurückgestellt werden**<br>
  Ist diese Funktion aktiviert, kontrolliert `HK-Skript 2` nachts um 01:00 Uhr (genauer: täglich zwischen 00:57 und 01:03 Uhr), ob ein Heizkörper noch auf Heizen steht, also nicht auf die Grundtemperatur gestellt wurde. Das betrifft alle Räume ohne aktiven Termin. Ist dies der Fall, wird der Heizkörper bzw. die Heizgruppe auf die Raumgrundtemperatur zurückgesetzt.<br>
  Dieser Wert wird in der Variable `HK2-Hand-Grundtemp` gespeichert.<br>
  Details zur Nachtschaltung finden sich im [Anwenderhandbuch](../Dokumentation/Anwenderhandbuch.md).
  <br>
  **Diese Option sollte immer eingeschaltet werden.**
- **Am Ende eines Termines eine manuell eingestellte/abweichende Temperatur für den Raum beibehalten**<br>
  Ist diese Option ausgeschaltet, wird nach Ablauf des Heizintervalls immer auf die Grundtemperatur des Raumes zurückgestellt. Ist die Option eingeschaltet und wird während eines Heizintervalls die Temperatur eines Raumes manuell am Thermostat geändert, bleibt diese Temperatur nach Ablauf der Heizphase erhalten, d. h. die Heizung wird nicht abgestellt. Spätestens bei eingeschalteter **Rückstellung auf Grundtemperatur** (s. o.) wird jedoch die Grundtemperatur wieder eingestellt.<br>
  Dieser Wert wird in der Variable `HK2-Hand-Temp` gespeichert.<br>
  **Diese Option sollte immer ausgeschaltet werden.**

#### Temperatureinstellungen

- **Grundtemperatur für alle Räume, wenn kein Heizvorgang läuft**<br>
  Die Grundtemperatur ist die Temperatur, die eingestellt wird, wenn für einen Raum keine Heizphase eingestellt wurde. Sie kann bei Bedarf in den Einstellungen eines Raumes individuell festgelegt werden.<br>
  Dieser Wert wird in der Variable `HK2-Grundtemperatur` gespeichert.

- **Außentemperaturgrenze, ab der kein Heizvorgang mehr ausgeführt werden soll**<br>
  Hier wird die Temperatur eingestellt, ab der grundsätzlich nicht mehr geheizt wird. Liegt die durchschnittliche Außentemperatur über diesem Wert, wird kein Heizvorgang mehr gestartet.<br>
  Dieser Wert wird in der Variable `HK2-A.Temp.Grenze` gespeichert.

##### Heizkurve / Vorheizzeiten bei entsprechenden Außentemperaturen

Bei der Heizkurve werden die Vorheizzeiten in Minuten zu den Außentemperaturen eingegeben.

Diese Werte sollten bei der Installation an das eigene Gebäude angepasst werden. Eine ausführliche Erklärung der Berechnung mit Beispielrechnungen findet sich im Artikel [Heizsteuerung-Vorheizzeit](Dokumentation/Heizsteuerung-Vorheizzeit.md).

Als Orientierungshilfe gibt es drei Beispielkurven:

| Kurventyp | −10 °C | −5 °C | 0 °C | 8 °C | 10 °C | 12 °C | 15 °C | 17,5 °C | Einsatz |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | :--- |
| Konservativ (Default) | 162 | 130 | 100 | 59 | 50 | 41 | 30 | 20 | Gut gedämmte Gebäude |
| Mittel | 220 | 180 | 144 | 95 | 85 | 75 | 61 | 50 | Typische Gemeindegebäude |
| Großzügig | 451 | 370 | 297 | 196 | 174 | 154 | 125 | 103 | Träge Heizsysteme / Fußbodenheizung |

**Diese Werte sollten für jedes Gebäude mithilfe des Skripts `HK-Heizkurvenkontrolle` angepasst werden.**

Diese Werte werden in der Variable `HK2-Kurve` gespeichert.

### Eigenschaftsseite *Kalenderzuordnung*

Über die **Kalenderzuordnung** werden einem Kalender (einer Ressource bzw. einem Raum aus ChurchDesk/ChurchTools) ein oder mehrere Räume zugeordnet. Die vorhandenen Kalender werden von der `HeizkalenderInstallation.exe` bei manchen Verbindungen automatisch ermittelt.

In dieser Übersicht werden die Ressourcen-IDs und die Namen der entsprechenden Kalender/Räume angezeigt.

![Kalenderzuordnung](Bilder/HKI-Kalenderzuordnung.png)

Wird eine Ressource eingelesen, für die keine zu steuernden Thermostate oder Aktoren existieren (weil sie zum Beispiel einen Beamer oder ein Fahrzeug darstellt), kann sie über den Schalter **Löschen...** entfernt werden. Das sorgt für mehr Übersicht im Heizkalender. Beim Löschen eines Kalendereintrags gehen allerdings alle zugeordneten Räume verloren. Eine gelöschte Ressource wird erneut angelegt, wenn die Funktion **Ressourcen / Räume einlesen** ausgelöst wird.

Mit einem Doppelklick auf den Kalendereintrag oder über die Funktion **Ändern...** öffnet sich ein Dialog, in dem diesem Kalender ein oder mehrere Räume aus dem Heizkalender zugeordnet werden können.

Diese Werte werden in der Variable `HK1-R-Liste` gespeichert.

#### Raumzuordnung zu den Ressourcen/Kalendern

Über diesen Dialog können Sie einem Kalender (Raum/Ressource) einen oder mehrere Räume zuordnen.

Die Zuordnung mehrerer Räume ist sinnvoll, wenn zum Beispiel bei der Nutzung eines Saales grundsätzlich auch Foyer und WCs beheizt werden sollen. Sonst müssten auch Foyer und WCs als eigene Ressourcen verwaltet und gebucht werden, was oft nicht praktikabel ist. Räume können beliebig oft beliebigen Kalendereinträgen zugeordnet werden. So lassen sich zum Beispiel WCs und Foyer immer beheizen, wenn ein bestimmter anderer Raum gebucht wurde.

![Raumzuordnung zu den Kalenderressourcen](Bilder/HKI-Raumzuordnung.png)

Wird einem Kalendereintrag kein Raum zugeordnet, erfolgt auch keine Schaltung für diesen Kalender.

Diese Zuordnung wird in der Variable `HK2-HKG-Liste` gespeichert.

### Eigenschaftsseite *Räume*

Auf der Eigenschaftsseite *Räume* werden die aktuellen Räume angezeigt, die im Heizkalender benutzt werden. Alle hier aufgeführten Räume können einem oder mehreren Kalendereinträgen/Ressourcen zugeordnet werden (siehe Eigenschaftsseite *Kalenderzuordnung*).

![Übersicht der Räume](Bilder/HKI-Räume.png)

Über die Funktion **Löschen...** kann ein Raum aus dem Heizkalender entfernt werden. Alle Raumzuordnungen und Einstellungen des Raumes werden dabei aus dem System entfernt.

Über die Funktion **Neu...** kann ein neuer Raum angelegt werden. Bei der ersten Verbindung zu ChurchDesk/ChurchTools legt die `HeizkalenderInstallation.exe` für jede Kalenderressource eine Raumvariable an. Räume wie die genannten Beispiele Foyer/WCs müssen manuell angelegt werden.

Über die Funktion **Ändern...** oder einen Doppelklick auf den Raum können die Einstellungen eines Raumes geändert werden.

Für jeden Raum wird eine eigene Raumvariable `HKG-Raum-<Name>` angelegt, die die entsprechenden Einstellungen enthält. Wird ein Raum gelöscht, wird auch die Variable entfernt.

#### Eigenschaften von Räumen

In diesem Dialog legen Sie die individuellen Eigenschaften eines Raumes sowie die Zuordnung der Aktoren, Thermostate bzw. Heizgruppen fest.

![Raum-Eigenschaften](Bilder/HKI-Raum.png)

- **Name**<br>
  Das Feld Name bestimmt, welche Variable `HKG-Raum-<Name>` zum Speichern der Informationen verwendet wird. Der Name wird außerdem intern in der `HeizkalenderInstallation.exe` bei der *Kalenderzuordnung* verwendet.

- **Modus**<br>
  Es gibt drei verschiedene Modi zum Ansteuern der Thermostate oder Aktoren eines Raumes. Weitere Informationen finden Sie im Abschnitt *Modus*. Üblicherweise wird *Heizen* zur Steuerung von Thermostaten und *Schalten* zur Steuerung von Aktoren (zum Beispiel einer Außenbeleuchtung oder Lüftungsanlage) benutzt. Der Modus *Heizen+Schalten* ist ein spezieller Modus, mit dem eine Heizungsanlage mit eigener Temperatursteuerung geregelt werden kann.

- **Wohlfühltemperatur**<br>
  Diese Temperatur ist die Zieltemperatur, die bei einem Termin für diesen Raum erreicht werden soll. Da jeder Raum seine eigene Zieltemperatur hat, kann zum Beispiel ein Gruppenraum auf 20 °C und ein WC auf 18 °C vorbelegt werden.<br>
  Im Modus *Schalten* wird dieser Wert nicht verwendet.

- **Abweichende Grundtemperatur**<br>
  Dies ist die Temperatur, die für diesen Raum außerhalb der Heizzeiten eingestellt sein soll. Der Wert ist mit dem Wert aus den Einstellungen vorbelegt und lässt sich für jeden Raum individuell ändern. So kann zum Beispiel ein Raum weniger stark abgesenkt werden, als es in einer Installation normalerweise üblich ist.

- **Vorzeitiger Heiz-/Schaltbeginn**<br>
  Mit diesem Wert kann der Heiz-/Schaltbeginn grundsätzlich vorverlegt werden, zusätzlich zu der Zeit, die sich aus Außentemperatur, Heizkurve und Temperaturdifferenz zur Zieltemperatur ergibt.<br>
  Im Modus *Schalten* wird keine Vorheizzeit berechnet. Der Wert kann aber trotzdem genutzt werden, um zum Beispiel eine Außenbeleuchtung 30 min früher einzuschalten.<br>
  Ein positiver Wert verschiebt den Einschaltpunkt nach vorne, ein negativer Wert verschiebt ihn zeitlich nach hinten.

- **Vorzeitiges Heiz-/Schaltende**<br>
  Mit diesem Wert kann das Heiz-/Schaltende grundsätzlich vorverlegt werden.<br>
  Es kann sinnvoll sein, das Heizen eines Raumes bereits 30 min vor dem Ende des Termins zu beenden oder die Außenbeleuchtung 30 min über das Ende eines Termins hinaus eingeschaltet zu lassen.<br>
  Ein positiver Wert verschiebt den Ausschaltpunkt nach vorne, ein negativer Wert verschiebt ihn zeitlich nach hinten.

- **Faktor Heizkurve**<br>
  Im Modus *Heizen* wird aus der eingestellten Heizkurve, der Außentemperatur und der aktuellen Raumtemperatur eine Vorheizzeit berechnet. Für Räume mit vielen Außenwänden oder einem trägen Heizsystem (Fußbodenheizung) kann es nützlich sein, die Vorheizzeit mit einem Faktor zu vergrößern. Für eine Fußbodenheizung kann der Faktor 3,5 eine gute Voreinstellung sein. Bei innen liegenden Räumen lässt sich die Vorheizzeit zum Beispiel mit dem Faktor 0,5 halbieren.<br>
  Im Modus *Schalten* wird dieser Wert nicht verwendet.<br>
  Erlaubt sind Werte zwischen 0,2 und 5. Das entspricht minimal 20 % und maximal dem Fünffachen der errechneten Vorheizzeit.

##### Modus

Der Modus legt fest, wie die Thermostate oder Aktoren des Raumes angesteuert werden.

![Auswahl des Modus](Bilder/HKI-Modus.png)

Es stehen die folgenden Modis zur Verfügung:

- H = Heizen <br>
Dies ist der Standardmodus für den Heizkalender. Dieser wird benutzt um Thermostate oder Heizgruppen anzusteuern. In diesem Modus werden auch Vorheizzeiten berücksichtigt, die Anhand der Außentemperatur, der aktuellen Raumtemperatur und der Zieltemperatur berechnet werden.<br>
Entsprechend können in diesem Modus nur Geräte und Aktoren mit Datenpunkten zugeordnet werden, die dem Typ "Heizung" zugeordnet sind.
- HS = Heizen+Schalten <br>
Dieser Modus ist ein spezieller Modus, der über den ersten Aktor/Temperatursensor eine Temperaturermittlung ausführen kann. Alle weiteren Aktoren müssen Schaltaktoren sein. In diesem Modus werden auch Vorheizzeiten berücksichtigt, die Anhand der Außentemperatur, der aktuellen Raumtemperatur und der Zieltemperatur berechnet werden.<br>
Dieser Modus kann dazu verwendet werden, eine Heizung anzuschalten, deren Steuerung über ein eigenes Thermostat erfolgt. Dies kann eine z.B. Luftheizung sein. Der erste Aktor kann, aber muss nicht definiert sein. Ist er nicht definiert wird entweder die Außentemperatur oder die Grundtemperatur verwendet.
- S = Schalten <br>
In diesem Modus können alle Schaltaktoren gesteuert werden. Vorheizzeiten werden hier nicht angewendet.<br>
Entsprechend können in diesem Modus nur Geräte und Aktoren mit Schaltdatendatenpunkten zugeordnet werden. Damit lässt sich zum Beispiel eine Außenbeleuchtung steuern.

##### Geräteauswahl (Thermostate/Sensoren/Schaltaktoren)

###### Modus Heizen

Wurde der Modus **Heizen** gewählt lassen sich nur entsprechende Aktoren/Thermostate oder Heizgruppen auswählen.

Bei den Geräten ist es möglich mehere Aktoren durch Semikolon getrennt anzugeben. Es ist aber dringend empfehlenswert mehrere Thermostate zu einem Raum in einer Heizgruppe zusammen zu fassen. Der Modus, dass hier mehrere Aktoren/Thermostate angegeben werden können wurde nur aus Gründen der Rückwärtskompatibilität erhalten.

Heizgruppen erleichtern die Verwaltung und reduzieren den Schaltaufwand.

![Zuordnung im Modus Heizen](Bilder/HKI-HeizenAktoren.png)

###### Modus Schalten

Wurde der Modus **Schalten** gewählt lassen sich nur entsprechende Aktoren auswählen, die über einen Datenpunkt Ein/Aus verfügen.

![Zuordnung im Modus Schalten](Bilder/HKI-SchaltenAktoren.png)

Der Gerätetyp steht in diesem Fall immer auf *SW = Sonstiges*.

###### Modus Heizen+Schalten

Im Modus **Heizen+Schalten** werden im ersten Feld ein Temperatursensor ausgewählt und im zweiten Feld ein Schaltaktor, der wie beim Modus Schalten einen Datenpunkt Ein/Aus verfügt.

![Zuordnung im Modus Heizen+Schalten](Bilder/HKI-HeizenSchaltenAktoren.png)

Der Gerätetyp steht in diesem Fall immer auf *SW = Sonstiges*.

##### Gerätetyp

Der Gerätetyp wird benötigt um den entsprechenden Datenpunkt für die Steuerung eines Homematic Gerätes zu bestimmen. Dedr Gerätetyp wird nur im Modus Heizen benötigt. In allen anderen Fällen steht er auf *SW = Sonstiges*.

![Auswahl des Gerätetyps](Bilder/HKI-GeräteTyp.png)

Wenn das Gerät ausgewählt wurde, wird wird der entsprechende Gerätetyp überlicherweise automatisch ermittelt und eingestellt.

Der Gerätetyp bestimmt, welcher Datenpunkt des Thermostates angesprochen wird. Die konkrete Kanalnummer legt der Administrator bei der Aktor-Zuordnung selbst fest (als Teil der Aktor-Adresse); die Spalte „Kanal" nennt den dabei üblichen Kanal. Die Kanalnummer ist nur in der CCU relevant; der Name des Datenpunktes ist entscheidend:

| Kennung | Kanal | Gerätetyp | Datenpunkt |
| :--- | :--- | :--- | :--- |
| `IP` | 1 | IP-Thermostate (z.B. BWTH_V1/V2, TRV-/V1–V4, WTH-/2\_V1) | `SET_POINT_TEMPERATURE` |
| `RT` | 4 | Klassik HM-CC-RT-DN | `SET_TEMPERATURE` |
| `TC` | 2 | Klassik HM-CC-TC | `SETPOINT` |
| `IT` | 2 | Klassik HM-TC-IT-WM-W-EU | `SET_TEMPERATURE` |
| `SW` | 1 (oder 1+2) | Schalt-Aktoren (z.B. HM-LC-Sw1-FM, HM-LC-Sw2-FM) | `STATE` |

##### Gerätetest

Wurde ein Gerät und der korrekte Gerätetyp ausgewählt, kann über den Schalter **Test...** geprüft werden ob die Datenpunkte angesprochen werden können.

Bei einem erfolgreichen Test werden aktuelle Raumtemperatur und eingestellte Solltemperatur bei einem Thermostat ermittelt.

![Gerätetest](Bilder/HKI_Gerätetest.png)

Bei einem fehlgeschlagenem oder auch nur teilweise fehlgeschlagenem Test wird ein entsprechende Nachricht angezeigt, welcher Datenpunkt einen Fehler meldet.

![Fehler bei Gerätetest](Bilder/HKI_GerätetestFehler.png)

### Eigenschaftsseite *Systemvariablen*

Auf der Eigenschaftsseite *Systemvariablen* werden alle aktuellen Systemvariablen angezeigt. In den Einstellungen verwendet die `HeizkalenderInstallation.exe` immer nur die reinen Raumnamen; intern in den Skripten werden Prefixe verwendet. So wird für jeden Raum der Prefix *HKG-Raum-* benutzt. Die Systemvariablen für die Räume müssen daher mit dem entsprechenden Prefix gesucht werden.

Auf dieser Seite können keine Änderungen direkt durchgeführt werden. Diese Seite dient zur Kontrolle der Änderungen, die das Installatinsprogramm vornimmt.

![Übersicht der Systemvariablen](Bilder/HKI-Systemvariablen.png)

Es werden alle Systemvariablen mit ihrem Inhalt angezeigt, außerdem der Status, ob die Variable verändert wurde. Alle Änderungen in den Einstellungen, den Raumparametern und den Kalenderzuordnungen führen letztlich dazu, dass Systemvariablen angepasst werden. Änderungen an den Raumeinstellungen lassen sich daher sofort in den Änderungen der entsprechenden Systemvariablen nachverfolgen.

Durch einen Doppelklick auf eine Systemvariable oder auf den Schalter **Änderungen...** können Sie die Änderungen kontrollieren, die durch das Speichern der Daten durchgeführt werden.

#### Änderungsinformationen zu einer Systemvariablen

Dieser Dialog zeigt den aktuellen Status einer Systemvariablen: die interne ID, den Typ und den Namen sowie den alten und den neuen Inhalt. Außerdem werden der Status (Geändert/Unverändert) und die Angabe angezeigt, ob die Variable im Systemprotokoll protokolliert wird.

![Änderungsinformationen der Systemvariablen](Bilder/HKI-SystemvariablenÄnderungen.png)

## Speichern der Einstellungen

Die Einstellungen werden gespeichert, indem Sie im Hauptdialog auf den Schalter **OK** klicken.

- Sind Programme vorhanden, die aktualisiert oder installiert werden müssen wird automatisch auf die Änderungen hingewiesen, wenn die *Eigenschaftsseite Programme/Skripte* bisher nicht kontrolliert wurde.<br>
![Geänderte Programme](Bilder/HKI-ProgrammeGeändert.png)<br>
Nach Betätigen des **OK**-Schalters wird die Eigenschaftseite zur Kontrolle aufgerufen.

- Wurden neue Räume eingelesen und die *Eigenschaftsseite Kalenderzuordnung* bisher nicht kontrolliert, wird auf die Änderungen hingewiesen um eine Kontrolle zu ermöglichen.<br>
![Geänderte Raumliste](Bilder/HKI-RaumListeGeändert.png)<br>
Nach Betätigen des **OK**-Schalters wird die Eigenschaftseite zur Kontrolle aufgerufen.

- Wurden Systemvariablen geändert oder angepasst und die *Eigenschaftsseite Systemvariablen* bisher nicht kontrolliert, wird auf die Änderungen hingewiesen um eine Kontrolle zu ermöglichen.<br>
![Geänderte Systemvariablen](Bilder/HKI-SystemvariablenGeändert.png)<br>
Nach Betätigen des **OK**-Schalters wird die Eigenschaftseite zur Kontrolle aufgerufen.

Wurden alle Einstellungen kontrolliert erfolgt vor dem Update der CCU die folgende Frage:<br>
![Änderungen speichern](Bilder/HKI-ÄnderungenSpeichern2.png)

Wird diese Frage mit **Ja** beantwortet, erfolgt ein Update der CCU.Beachten Sie, dass viele der Änderungen, insbesondere bei Änderungen der Kalenderquelle oder dem Aktualisieren der Raumliste, nicht rückgängig gemacht werden können.<br>
Halten Sie aus diesem Grund immer ein aktuelle Backup bereit.

Wird die Frage mit **Nein** beantwortet kehrt man in das Installationsprogramm zurück und kann weitere Korrekturen oder Änderungen vornehmen.

Wenn die Daten erfolgreich gespeichert werden wird dies durch die folgende Meldung bestätigt.<br>
![Änderungen gespeichert](Bilder/HKI_Gespeichert.png)

**Wird nun der **OK**-Schalter betätigt wird die `HeizkalenderInstallation.exe` automatisch beendet.**

**Um weitere Änderungen vorzunehmen, starten Sie die `HeizkalenderInstallation.exe` erneut.**

### Abbrechen der Installation

Wird versucht das Programm durch Anklicken von **Abbrechen** zu beenden und wurden Änderungen vorgenommen oder stehen Aktualisierungen/Updates für Programme oder Skripte an, dann erfolgt immer die Frage, ob das Programm dennoch beendet werden soll.

![Rückfrage beim Abbrechen](Bilder/HKI-ÄnderungenSpeichern.png)

Wird diese Frage mit **Ja** beantwortet gehen alle Änderungen verloren und das Installationsprogramm wird beendet.

Wird die Frage mit **Nein** beantwortet, kann man weiterhin Änderungen vornehmen. Das Programm wird nicht verlassen.

## Logdateien der `HeizkalenderInstallation.exe`

Die folgenden Log-Dateien werden bei Programmstart direkt erzeugt. Sie dienen keinem internen technische Zweck und können bei der Fehlerursache und beim evtl. Korrekturen oder Fehlerbehebungen helfen.

Die Ausgabe der Log-Dateien erfolgt automatisch im zugehörigen Ordner für temporäre Dateien von Windows (Envirnment Variable %TMP%(.<br>
Üblicherweise heiß dieser Ordner *C:\Users\<Benutzername>\AppData\Local\Temp*. Der Ordner kann einfach geöffnet werden in dem man in der Adressenleiste des Explorers *%TMP%* eingibt un die Eigabetaste drückt.

**Folgenden Logdateien werden beim Start des Installatinsprogramms erzeugt**
- `HeizkalenderInstallation_Devices.log`<br>
Diese Datei enthält eine Liste der auf der CCU installierten Geräte. Für jedes Gerät wird eine Ausgabezeile erzeugt.
- `HeizkalenderInstallation_Programs.log`<br>
Alle installierten Programme werden heruntergeladen und in dieser Protokolldatei gespeichert. Für jedes Gerät wird eine Ausgabezeile erzeugt. Zeielnschaltungen innerhalb des Programmes werden durch ein %0A ersetzt. Auch bestimmte Sonderzeichen werden auf diese Weise substituiert.
- `HeizkalenderInstallation_SysVars.log`<br>
Bei Programmstart werden alle Systemvariablen, deren Inhalt und Typ in dieser Datei ausgegeben.

**Folgenden Logdateien werden beim Beenden des Installatinsprogramms erzeugt, wenn die CCU aktualisiert wird**

- `HeizkalenderInstallation_update.log`<br>
Alle Änderungen, die der Installer per Skript an der CCU vornimmt werden in diesem Update-Protokoll verzeichnet. Sollte es zu Problemen bei einem Update kommen, kann man über diese Datei nachvollziehen welche Änderungen das Installationsprogramm über das Skript-Interface durchgeführt hat.




## Zugriff von außerhalb mit dem `HeizkalenderInstallation.exe`

Der Zugriff auf die CCU mit dem Installationsprogramm kann nicht über die CloudMatic erfolgen. Man benötigt in jedem Fall einen direkten Netzwerkzugriff auf die CCU über Port 8181.

Mit einer modernen FRITZ!Box ab FRITZ!OS Version 7.50 kann dieser Zugriff einfach über WireGuard erfolgen.

Auf er Webseite von ELV findet sich dazu folgende [Anleitung](
https://ch.elv.com/elvwissen/elvprojekte/sicherheit/fernzugriff-auf-die-CCU-webui-und-hcu-web-per-wireguard-fritzbox/) zur Installation von WireGuard und dem Zugriff auf eine CCU.<br>
Auch ein passendes [Erklärvideo](https://www.youtube.com/watch?v=j7wpmiuKrxY) steht auf YouTube zur Verfügung.

