<img src="Logos\HK-Logo mit Titel (200px).png" align="right" alt="Heizkalender-Logo">

[![Release](https://img.shields.io/github/v/release/xMRi/Homematic-Heizungskalender?label=Release)](https://github.com/xMRi/Homematic-Heizungskalender/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/xMRi/Homematic-Heizungskalender/total?label=Downloads)](https://github.com/xMRi/Homematic-Heizungskalender/releases)
[![Dokumentation](https://img.shields.io/badge/Dokumentation-xmri.github.io-4f46e5?logo=materialformkdocs&logoColor=white)](https://xmri.github.io/Homematic-Heizungskalender/)

# HomeMatic-Heizungskalender

Der HomeMatic-Heizungskalender dient zur Steuerung der Homematic über ChurchTool, ChurchDesk, iCal oder Google.
Er umfasst Skripte, Tools und eine Installations- und Update-Software. Die Skripte werden intern über Systemvariablen gesteuert.

## Allgemeines

Der Heizkalender ist eine Idee von Helmut W. Diedrichs und wurde erstmals 2019 in der
Stadtmission Arheilgen angewendet. Lukas Helduser entwickelte 2023 auf der Basis der Homematic
das Heizkalender-Programm für die Allgemeinheit, inkl. Varianten.
Dank an die seitherigen Anwender für ihre Verbesserungsvorschläge, insbesondere an die Pilot-
Gemeinden. Dieser Code wurde im Rahmen der Heizkalender-Implementierung der Baptisten Gemeinde
Hanau von Martin Richter stark optimiert und erweitert.

Das Heizkalender-Team freut sich, dass Sie den kostenlosen Heizkalender anwenden und somit einen
Beitrag zum Umweltschutz leisten. Es wäre schön, wenn Sie die Nutzung per E-Mail anzeigen an: <info@heizkalender.de>

Weitere Informationen, Varianten (neben Homematic auch Home Assistant und FRITZ!Box),
Anleitungen und ein Blog finden sich auf der Projekt-Homepage <https://heizkalender.de/>.

Dadurch ergäbe sich eine Übersicht und die Möglichkeit auf Änderungen hinzuweisen. Bitte
berichten auch Sie über Ihre Erfahrung mit dem Heizkalender.

## Dokumentation

Auch als responsive Website mit Suchfunktion: [https://xmri.github.io/Homematic-Heizungskalender/](https://xmri.github.io/Homematic-Heizungskalender/)

### Für Anwender

- [Anwenderhandbuch](/docs/heizkalender/anwenderhandbuch.md): Sonderbefehle, Raumvariablen, Vorheizzeit im laufenden Betrieb.
- [Planung](/docs/heizkalender/planung.md): Struktur planen, Nomenklatur für Aktoren- und Heizgruppen (vor der Installation).
- [Kalender-Zugangsdaten ermitteln](/docs/heizkalender/kalender-einrichten.md): Token/IDs für ChurchTools, ChurchDesk usw. beschaffen.
- [Einrichtung der CCU](/docs/heizkalender/ccu-einrichten.md): Einrichtung der CCU und Installation der Aktoren/Thermostate
- [Heizkalender-Installation Anleitung](/docs/heizkalender-installation/readme.md): Einrichtung und Updates auf der CCU.
- [Heizkalender Addon](/docs/addon/anwenderhandbuch.md): Installation und Seiten-Übersicht des CCU-Addons zur Anzeige von Räumen, Protokollen und Heizkurvenkontrolle.
- [Skript-Referenz](/docs/skripte/readme.md): alle Skripte und Systemvariablen im Detail.
- [Heizsteuerung und Vorheizzeit](/docs/heizkalender/heizsteuerung-vorheizzeit.md): Berechnung der Vorheizzeit mit Beispielen.
- [Tools](/docs/tools/readme.md): optionale Zusatz-Skripte für Diagnose, Logging und Wartung.
- [Hinweise zu Updates](/docs/heizkalender/updates.md) 


### Für Entwickler

- [Entwickler-Dokumentation](/docs/heizkalender/entwickler.md): Skript-Syntax, `HeizkalenderInstallation.exe`-Build, Versionierung, Beitrag-Workflow.
- [Addon-Entwicklerdokumentation](/docs/addon/entwickler.md): Aufbau des CCU-Addons, CGI-Seiten, Paketformat, Tcl-8.2-Besonderheiten.
- [CHANGELOG](/CHANGELOG.md): zentrale Änderungshistorie (Datums-Stände).

### Archiv (historische Dokumente)

- [Neue Funktionen 2026](/docs/archiv/Neue-Funktionen-2026.md): historisches Release-Begleitdokument.
- [Handbuch-ENTWURF04-20260228.pdf](/docs/archiv/Handbuch-ENTWURF04-20260228.pdf): früher Handbuch-Entwurf (PDF).
- [Handbuch-ENTWURF01-20260110.pdf](/docs/archiv/Handbuch-ENTWURF01-20260110.pdf): früher Handbuch-Entwurf (PDF).
- [HK-Anleitung V3.1.1.pdf](/Backup-Originale/3.2.1/HK-Anleitung%20V3.1.1.pdf): ältere Anleitung (PDF, im Ordner der Original-Skripte).
- [Backup-Originale](/Backup-Originale): Historische Original-Skripte, nur zur Referenz.

## Ordner-Konvention

| Ordner | Inhalt |
| :--- | :--- |
| [`docs/`](/docs) | Zentrale Dokumentation (MkDocs). Alle Handbücher, Skript-Referenz, Addon-Doku, Archiv. |
| [`Skripte/`](/Skripte) | Release-Ordner: die `.hsc`-Kern-Skripte (Skript-1-Varianten, Skript 2, Init-Skripte, HK-Test-Skript, Heizkurvenkontrolle, Außentemperatur, Protokoll-Sicherung), eine lauffähige Kopie der `HeizkalenderInstallation.exe` sowie die mitgelieferte Skript-Referenz. So ist ein GitHub-Release direkt nutzbar. |
| [`Tools/`](/Tools) | Optionale Zusatzwerkzeuge (Diagnose, Logging, Wartung). |
| [`Tests/`](/Tests) | Entwickler-Testfälle, nicht für den Produktivbetrieb. |
| [`HeizkalenderInstallation/`](/HeizkalenderInstallation) | Windows-Installationsprogramm-Quellcode (C++/MFC) und dessen Doku. Die gebaute `.exe` liegt als Kopie in `Skripte/`. Doku: [Heizkalender-Installation](/docs/heizkalender-installation/readme.md) |
| [`Addon/`](/Addon) | CCU-Addon (Weboberfläche): Tcl-CGI-Seiten, rc.d-Service-Skript und Installationsskript. Wird als `heizkalender-addon.tar.gz` paketiert und über die CCU-Zusatzsoftware installiert. Doku: [Anwender](/docs/addon/anwenderhandbuch.md), [Entwickler](/docs/addon/entwickler.md). |
| [`Backup-Originale/`](/Backup-Originale) | Historische Original-Skripte/Anleitungen, nur zur Referenz. |

Das `HK-Test-Skript.hsc` liegt bewusst unter `Skripte/`, wird aber von der
`HeizkalenderInstallation.exe` **nicht** installiert (es steht nicht auf dessen fest einkompilierter
Skript-Liste). Es ist nur zum manuellen Ausführen per „Skript testen" auf der CCU gedacht und gibt die
aktuelle Konfiguration zu Diagnose-/Support-Zwecken aus.

## Skripte

Die Skripte sind das Kernstück des Heizkalenders. Sie umfassen 3 Gruppen.

1. **Skript 1:** Einlesen von Terminen aus unterschiedlichen Quellen (Google, iCal, ChurchDesk iCal/API und ChurchTools). Pro Quelle gibt es eine eigene Variante (`HK-Skript 1_ChurchTools`, `HK-Skript 1_Google` usw.); es wird immer nur eine eingesetzt. Die eingelesenen Termine landen in der Systemvariablen `HK1-Schaltliste`.
2. **Skript 2:** Berechnet die Schalt- und Heizzeiten (`HK-Skript 2`). Es liest `HK1-Schaltliste` und berücksichtigt die Raumparameter und Vorheizzeiten. Diese Daten landen in der `HK2-Schaltliste`. Es bedient auch einige Hilfsmittel zur Überwachung.
3. **Skript 3:** Schalten der Thermostate (`HK-Skript 3`). Es liest `HK2-Schaltliste` und schaltet die Heizung entsprechend.
4. Diverse andere optionale Hilfsmittel.

Die Systemvariablen folgen diesem Namensschema: `HK1-` für Skript 1 (Termineinlesen), `HK2-` für Skript 2 (Berechnen),`HK3- für Skript 3 (Schalten)` und `HKG-Raum-*` für die einzelnen Räume.

Intern gesteuert werden die Skripte durch Systemvariablen, die das Verhalten der Skripte kontrollieren. Die Skripte selbst sind auf allen Installationen austauschbar.

### Zusammenspiel der Komponenten (Beispiel ChurchTools)

Die `HeizkalenderInstallation.exe` richtet die Programme (Skripte) und Systemvariablen auf der CCU ein
und hält sie bei Konfigurationsänderungen oder Updates aktuell. Die Skripte laufen danach unabhängig
voneinander in ihren eigenen Intervallen und kommunizieren ausschließlich über Systemvariablen.

```mermaid
flowchart TD
    OpenMeteo["HK-Außentemperatur-Open-Meteo<br/>(stündlich)"] -->|"schreibt Außentemperatur"| ATVar[("HK2-Aussentemperatur")]

    CT["ChurchTools-Kalender"] -->|"Termine"| Skript1["HK-Skript 1_ChurchTools<br/>(alle 30 Minuten)"]
    Skript1 -->|"schreibt Termine"| Schaltliste1[("HK1-Schaltliste")]
    Skript2 -->|"schreibt Schaltzeiten"| Schaltliste2[("HK2-Schaltliste")]

    Schaltliste1 --> Skript2["HK-Skript 2<br/>Berechnet<br/>(alle 5 Minuten)"]
    Schaltliste2 --> Skript3["HK-Skript 3<br/>Schaltet<br/>(alle 5 Minuten)"]
    ATVar --> Skript2
    Raumtemp["Raumtemperatur<br/>(Thermostat-Sensor)"] --> Skript2
    SysVar --> Skript2
    SysVar --> Skript3
    Skript3 -->|"berechnet Vorlaufzeit,<br/>heizt bzw. schaltet"| Thermostate["Thermostate / Aktoren"]

    Installationsprogramm["HeizkalenderInstallation.exe<br/>(bei Installation, Konfiguration<br/>und Updates)"]
    Installationsprogramm -->|"richtet ein und aktualisiert"| Programme[("Programme<br/>HK-Skript 1, HK-Skript 2, HK-Skript 3,HK*")]
    Installationsprogramm -->|"richtet ein und aktualisiert"| SysVar[("Systemvariablen<br/>HK1-*, HK2-*, HKG-Raum-*")]
```

Ablauf im Detail:

1. **Bei Installation/Konfiguration/Updates:** Die `HeizkalenderInstallation.exe` richtet die Programme (HK-Skript 1, HK-Skript 2, HK-Skript 3 und weitere HK-Skripte) sowie die Systemvariablen auf der CCU ein und hält sie aktuell.
2. **Stündlich:** `HK-Außentemperatur-Open-Meteo` aktualisiert die Außentemperatur in `HK2-Aussentemperatur`.
3. **Alle 30 Minuten:** `HK-Skript 1_ChurchTools` liest die ChurchTools-Termine und schreibt sie in `HK1-Schaltliste`.
4. **Alle 5 Minuten:** `HK-Skript 2` berechnet aus der Schaltliste (Skript 1), der Außentemperatur, den Systemvariablen und der aktuellen Raumtemperatur die Vorlaufzeiten.
5. **Alle 5 Minuten:** `HK-Skript 3` nimmt die berechneten Werte aus `HK-Skript 2` und heizt bzw. schaltet die Räume entsprechend.

Die Hauptskripte und eine ausführbare Version der HeizkalenderInstallation findet sich [hier](/Skripte).
Eine Zusammenfassung der Skripte und eine Beschreibung ist [hier](/docs/skripte/readme.md) zu finden.
Die Tools und weitere Beispielskripte finden sich [hier](/Tools).
Eine Zusammenfassung der Tools und eine Beschreibung ist [hier](/docs/tools/readme.md) zu finden.

## Heizkalender-Installation

Die `HeizkalenderInstallation.exe` ist ein Tool zur Einrichtung und Updates der Heizkalender Software auf einer CCU.
Dieses Installationsprogramm ermöglicht die Neuinstallation oder auch Updates bestehender Installationen. Auch wenn Sie wenig Erfahrung mit Homematic haben, können Sie die Einrichtung bequem über die Programmoberfläche vornehmen. Das Installationsprogramm bietet eine benutzerfreundliche Oberfläche zur Konfiguration der Heizkalender, Einstellungen und Räume. Es unterstützt die Generierung von Skripten und notwendigen Systemvariablen, die in der HomeMatic CCU oder ähnlichen Systemen verwendet werden können.

[Weitere Informationen und eine Anleitung finden sich hier.](/docs/heizkalender-installation/readme.md)

### Systemvoraussetzungen für die Heizkalender-Installation

- Betriebssystem: Windows 10 oder höher
- Die CCU muss in den Sicherheitseinstellungen den Zugriff auf die Remote Homematic-Script API erlauben. Hier muss entweder ein eingeschränkter Zugriff auf die benötigten Funktionen oder ein vollständiger Zugriff gewährt werden, damit die `HeizkalenderInstallation.exe` die notwendigen Skripte und Variablen erstellen kann.
- Ein Administrator-Benutzer und das zugehörige Kennwort müssen bekannt sein.  
    Alternativ kann der Zugriff auch über den  CloudMatic Fernzugriff erfolgen oder eine VPN-Lösung wie WireGuard.
- Alle Skripte, die installiert werden sollen, müssen im Programmverzeichnis der `HeizkalenderInstallation.exe` liegen. Die Namen sind vorgegeben und dürfen nicht verändert werden. Es können aber weitere Tool-Skripte hinzugefügt werden, die dann ebenfalls aktualisiert werden.
- Um auf Ressourcen und externe Kalender zugreifen zu können, muss der Rechner mit dem Internet verbunden sein.
- Eine lauffähige Kopie der `HeizkalenderInstallation.exe` liegt im Skripte-Verzeichnis.

## Lizenz

Die `HeizkalenderInstallation.exe` ist freie Software.

- Copyright (C) 2026 by Martin Richter (xMRi-Software)

- Weitere Teile Copyright (C) 2026 by Team Heizkalender:
Lukas Helduser, Martin Richter (xMRi-Software), Helmut Diedrichs

Im Detail ist dies in den Köpfen der Skripte und Sourcecodes zu lesen.

Dieses Programm wird unter den Bedingungen der
**GNU General Public License Version 3 (GPLv3)**
oder – nach Ihrer Wahl – jeder späteren Version veröffentlicht.

Sie dürfen das Programm verwenden, verändern und weiterverbreiten,
sofern alle abgeleiteten Werke ebenfalls unter der GPL lizenziert
werden und der Quellcode verfügbar bleibt.

Dieses Programm wird OHNE JEGLICHE GEWÄHRLEISTUNG bereitgestellt,
auch ohne die implizite Gewährleistung der Marktfähigkeit oder
Eignung für einen bestimmten Zweck.

Der vollständige Text der Lizenz ist in der Datei [`LICENSE`](/LICENSE) enthalten oder unter folgender Adresse abrufbar:
<https://www.gnu.org/licenses/>

## Hinweis zur Nutzung mit Homematic / CCU / IoT-Systemen

Diese Software wurde für die unterstützende Konfiguration und
Verwaltung von zeitbasierten Heizungssteuerungen entwickelt,
insbesondere im Umfeld von Homematic-, CCU- und vergleichbaren
IoT-Systemen.

Die `HeizkalenderInstallation.exe` steht in keiner Verbindung zur
eQ-3 AG oder anderen Herstellern von Smart-Home-Komponenten.

Die Software:

- ersetzt keine sicherheitsrelevanten Schutzmechanismen
- greift nicht eigenständig in Regelungs- oder Notfallfunktionen ein
- übernimmt keine Überwachung von Temperatur-, Frost- oder
  Sicherheitsgrenzwerten

Skripte, Programme oder Konfigurationen, die durch diese Software
erstellt oder verändert werden, sollten vor dem Einsatz in
produktiven Systemen sorgfältig geprüft werden.

Der Autor übernimmt keine Haftung für Schäden an:

- Homematic-Zentralen (CCU, RaspberryMatic, debmatic)
- Aktoren, Sensoren oder Heizungsanlagen
- angebundenen IoT- oder Smart-Home-Systemen

Die Nutzung erfolgt ausschließlich auf eigene Verantwortung.
Vor jeder Änderung wird dringend empfohlen, ein vollständiges
Backup der CCU-Konfiguration anzufertigen.

## Mitarbeit/Contribution

Das ist ein offenes Projekt. Wir freuen uns über jegliche Mitarbeit. Information dazu findest in der [CONTRIBUTING.md](/CONTRIBUTING.md).

Wir bitten Fehler, Verbesserungen und Ideen entsprechend über [Issues](https://github.com/xMRi/Homematic-Heizungskalender/issues) einzureichen.

## Änderungen am Projekt / Homepage

Im [`CHANGELOG`](/CHANGELOG.md) werden alle nennenswerten Änderungen an diesem Projekt dokumentiert.
