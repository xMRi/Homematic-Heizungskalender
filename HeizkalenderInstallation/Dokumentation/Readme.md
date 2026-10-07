# Heizkalender-Installation

Die Heizkalender-Installation ist ein Tool zur Erstellung von Heizkalendern für die HomeMatic, basierend auf Daten aus ChurchTools, ChurchDesk, iCal oder Google Kalender.

Sie ermöglicht die Neuinstallation sowie Updates bestehender Installationen. Sie bietet eine benutzerfreundliche Oberfläche zur Konfiguration der Heizkalender und unterstützt die Generierung von Skripten und notwendigen Systemvariablen, die in der HomeMatic CCU oder ähnlichen Systemen verwendet werden können.

## Systemvoraussetzungen

- Betriebssystem: Windows
- Die CCU muss in den Sicherheitseinstellungen den Zugriff auf die Remote Homematic-Script API erlauben. Dabei muss entweder ein eingeschränkter Zugriff auf die benötigten Funktionen oder ein vollständiger Zugriff gewährt werden, damit die Heizkalender-Installation die notwendigen Skripte und Variablen erstellen kann.
- Ein Administrator-Benutzer und das zugehörige Kennwort müssen bekannt sein.
- Alle Skripte, die installiert werden sollen, müssen im Programmverzeichnis der Heizkalender-Installation liegen. Die Namen sind vorgegeben und dürfen nicht verändert werden. Es können aber weitere Tool-Skripte hinzugefügt werden, die dann ebenfalls aktualisiert werden.
- Wurden Tool-Skripte mit installiert, können diese auch aktualisiert werden, sofern die entsprechenden Dateien im Verzeichnis der Heizkalender-Installation liegen.
- Um auf Ressourcen und externe Kalender zugreifen zu können, muss der Rechner mit dem Internet verbunden sein.
- Eine lauffähige Kopie der Heizkalender-Installation liegt im Skripte-Verzeichnis.

### Vorbereiten der CCU

Damit die Heizkalender-Installation ausgeführt werden kann, muss der Zugriff auf die Homematic-Script-API freigeschaltet werden. Dies geschieht in der HomeMatic-WebUI unter *Einstellungen → Firewall konfigurieren → Remote Homematic-Script API*. Dort wird entweder *Vollzugriff* eingestellt:

![CCU-Zugriff: Vollzugriff](Bilder/CCU-Zugriff-1.png)

Oder es wird *Eingeschränkter Zugriff* erteilt und die IP-Adresse des Rechners, von dem aus zugegriffen wird, freigegeben:

![CCU-Zugriff: Eingeschränkter Zugriff](Bilder/CCU-Zugriff-2.png)

Freigegebene IP-Adresse für den Zugriff:

![CCU-Zugriff: Freigegebene IP-Adresse](Bilder/CCU-Zugriff-3.png)

## Kurzanleitung

Die Kurzanleitung zeigt, welche Schritte bei einer Neuinstallation, einem Update oder einer Korrektur der Einstellungen durchgeführt werden müssen.

### Neuinstallation

Außer der Heizkalender-Installation sind keine weiteren Programme oder Skripte auszuführen. Sie wird direkt auf eine „leere“, frische CCU3 angewendet. Die entsprechenden Geräte sollten angelernt und in Heizgruppen zusammengefasst sein.

1. CCU3 vorbereiten (es sollten keine HK-Skripte oder -Variablen vorhanden sein)
2. Geräte und Heizgruppen einrichten
3. Heizkalender-Installation starten
4. Verbindungsdaten angeben
5. **Verbinden** anklicken
6. Ressourcenquelle auswählen (ChurchTools/ChurchDesk/iCal)
7. **Ressourcen / Räume einlesen** anklicken
8. Einstellungen vornehmen
9. **OK** anklicken

### Parameter ändern oder Update installieren

Für ein Update oder das Ändern der aktuellen Parameter wird die Heizkalender-Installation gestartet; anschließend können die gewünschten Änderungen vorgenommen werden. Sind neuere Skripte oder Module vorhanden, werden diese automatisch aktualisiert.

1. Heizkalender-Installation starten
2. **Verbinden** anklicken
3. Anpassungen durchführen
4. **OK** anklicken

### Anpassung der Raumliste

> [!WARNING]
> Die Raumliste sollte nur dann neu eingelesen werden, wenn sich die Raumliste oder die Anzahl der zu verwaltenden Ressourcen ändert.
> Andernfalls kann es zu Datenverlust oder zum Verlust der aktuellen Einstellungen kommen.

1. Heizkalender-Installation starten
2. **Verbinden** anklicken
3. **Ressourcen / Räume einlesen** anklicken und die angezeigten Fragen und Warnungen beantworten
4. Anpassungen durchführen
5. **OK** anklicken

## Beschreibung der Heizkalender-Installation

Im Folgenden werden die einzelnen Seiten der Heizkalender-Installation beschrieben.

### Startbildschirm 

Der Startbildschirm enthält wichtige Informationen über die Heizkalender-Installation.<br>
Hier findet sich die aktuelle Version des Heizkalenders und der aktuelle Stand der Skripte, die installiert werden können.

![Mit CCU verbinden](Bilder/HKI-Verbinden.png)

Über den Schalter **Info über...** kann der genaue Softwarestand und die Lizenz der Heizkalender-Installation angezeigt werden.
Es ist auch möglich eine Browser Fenster auf das aktuelle GitHub Projekt zu öffnen um evtl. eine neue Programmversion zu laden.

![Info Über](Bilder/HKI-InfoÜber.png)

### Verbinden mit der CCU

Im ersten Schritt muss eine Verbindung zur CCU aufgebaut werden, bevor weitere Einstellungen vorgenommen werden können.

1. Geben Sie die Ziel-IP der CCU an.
2. Geben Sie einen Benutzernamen an, der administrativen Zugriff auf die CCU hat.
3. Geben Sie das passende Kennwort an.
4. Geben Sie optional einen Prefix für Variablen und Skripte an (siehe Hinweis unten).
5. Klicken Sie auf den Button `Verbinden mit der CCU`.

> [!NOTE]
> Das Feld **Prefix** bleibt im Allgemeinen leer. Es dient dazu, mehrere Installationen parallel zu testen oder eine Installation von bestehenden Systemvariablen abzugrenzen.
> Wird ein Prefix angegeben, erhalten alle Variablen und Programme diesen Prefix im Namen vorangestellt.
> Wird eine bestehende CCU ausgelesen, wird auch erwartet, dass alle genutzten Variablen und Programme diesen Prefix enthalten.
>
> **ACHTUNG**<br>
> Wird die Funktion des Prefixes falsch verwendet, dann ist es möglich, das Skripte und Variablen mehrfach installiert werden.
> Dies kann zu Fehlfunktionen und einer Überlastung der CCU3 führen.
>
> **Nutzen Sie dieses Feld nur, wenn Sie sich über die Folgen im Klaren sind!**

### Fehler beim Verbindungsaufbau 

Ist keine Verbindung zur CCU möglich, weil die Verbindungsinformationen nicht stimmen, oder die Verbindungsdaten (IP, Benutzername und Kennwort) nicht stimmen erhalten Sie eine Fehlermeldung:

![Keine Verbindung](Bilder/HKI-Verbindungsfehler.png)

> [!NOTE]
> Konnte eine Verbindung hergestellt werden, werden die aktuellen Verbindungsinformationen in der Registry des aktuellen Benutzers gespeichert.
> Beim Neustart der Heizkalender-Installation sind die Felder **IP-Adresse**, **Benutzername**, **Kennwort** und **Prefix** dann bereits ausgefüllt.

### Einrichten einer neuen Heizkalender-Installation

Ist bisher keine Installation auf der CCU vorhanden, erhalten Sie diese Meldung:

![Neue Installation](Bilder/HKI-NeueInstallation1.png)

#### Auswahl der Ressourcen-/Terminquelle

Wählen Sie die gewünschte Quelle für Ihre Termine (ChurchTools, ChurchDesk, iCal, Google-API):

![Neue Installation: Ressourcenquelle](Bilder/HKI-NeueInstallation2.png)

Beachten Sie, das auch nachträglich die Auswahl der Terminquelle geändert werden kann, die entsprechenden Skripte werden in dem Fall geändert und überschrieben. Die Verbindungsdaten müssen dann angepasst werden.

Für jede Heizkalender-Variante sind unterschiedliche Informationen zum Auslesen/Aktualisieren der Ressourcen und Kalender notwendig. Diese werden nachfolgend beschrieben.

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

- [ ] Dokumentation oder Screenshot einfügen

### Programme / Skripte

![Übersicht der Programme](Bilder/HKI-Programme.png)

#### Änderungen in Skripten anzeigen

- [ ] Dokumentation oder Screenshot einfügen

### Allgemeine Einstellungen des Heizkalenders

Bei der Heizkurve werden die Vorlaufzeiten in Minuten zu den Außentemperaturen eingegeben.

Über die Option **Rückstellverhalten** wird die Nachtschaltungslogik aktiviert (Systemvariable `HK2-Hand-Grundtemp`). Ist diese Option aktiv, setzt HK-Skript 2 täglich zwischen 00:57 und 01:03 Uhr alle Räume ohne aktiven Termin auf Grundtemperatur zurück. Details zur Nachtschaltung finden sich im [Anwenderhandbuch](../../Dokumentation/Anwenderhandbuch.md).

![Allgemeine Einstellungen](Bilder/HKI-Einstellungen.png)

### Ressourcen-Kalenderzuordnung

![Kalenderzuordnung](Bilder/HKI-Kalenderzuordnung.png)

#### Raumzuordnung zu den Ressourcen/Kalendern

![Raumzuordnung zu den Kalenderressourcen](Bilder/HKI-Raumzuordnung.png)

### Räume

![Übersicht der Räume](Bilder/HKI-Räume.png)

#### Eigenschaften von Räumen

![Raum-Eigenschaften](Bilder/HKI-Raum.png)

### Systemvariablen

![Übersicht der Systemvariablen](Bilder/HKI-Systemvariablen.png)

#### Änderungsinformationen

![Änderungsinformationen der Systemvariablen](Bilder/HKI-SystemvariablenÄnderungen.png)

## Speichern der Einstellungen

Das Speichern der Einstellungen erfolgt durch das Anklicken des **OK**-Schalters im Hauptdialog.


Um weitere Änderungen vorzunehmen starten Sie die Heizkalender-Installation erneut.

### Abbrechen der Heizkalender-Installation

Wenn Sie 
