# HomeMatic-Heizungskalender

> [!NOTE]
> Diese Datei ist im Markdown-Format geschrieben. Wenn Sie sie in einem normalen Texteditor
> öffnen, sind darin Formatierungszeichen (z. B. `#`, `**`, `|`) sichtbar.
> Mit allen Formatierungen können Sie sie online ansehen unter:
> <https://xmri.github.io/Homematic-Heizungskalender/>  
> Das gesamte GitHub-Projekt findet sich unter:  
> <https://github.com/xMRi/Homematic-Heizungskalender>

Der **Heizkalender** ermöglicht die automatische, termingesteuerte Regelung von Heizkörpern und
Raumthermostaten in Homematic und OpenCCU auf Basis von Google Kalender, iCal, ChurchTools oder ChurchDesk.  
Das Projekt umfasst die zentralen Steuerungs-Skripte (intern gesteuert über Systemvariablen), ergänzende
Hilfs-Tools sowie eine eigene Installations- und Update-Software.

## Allgemeines

Der Heizkalender geht auf eine Idee von Helmut W. Diedrichs zurück und wurde erstmals 2019 in der Stadtmission 
Arheilgen angewendet. Lukas Helduser entwickelte 2023 auf der Basis von Homematic das Heizkalender-Programm für die 
Allgemeinheit, einschließlich verschiedener Varianten. Vielen Dank an die bisherigen Anwender für ihre 
Verbesserungsvorschläge, insbesondere an die Pilotgemeinden. Dieser Code wurde im Rahmen der 
Heizkalender-Implementierung der Baptisten-Gemeinde Hanau von Martin Richter stark optimiert und erweitert.  
Weiterer Dank gilt Thomas Tatzel für sein Addin und weitreichende Verbesserungen am Projekt.

Das Heizkalender-Team freut sich, dass Sie den kostenlosen Heizkalender anwenden und damit einen
Beitrag zum Umweltschutz leisten. Es wäre schön, wenn Sie uns Ihre Nutzung per E-Mail mitteilen:
<info@heizkalender.de>

So können wir einen Überblick über die Nutzung gewinnen und Sie bei Änderungen informieren. Bitte
berichten auch Sie über Ihre Erfahrungen mit dem Heizkalender.

## Inhalt des Releases

Das Release umfasst alle Dateien aus dem Ordner `Skripte` sowie die jeweils bereitgestellten Tools,
das Installations- und Updateprogramm `HeizkalenderInstallation.exe` und das Heizkalender-Addon. Das 
Addon ist immer Teil des Releases.

## Erste Schritte

Lesen Sie vor der Installation die Dokumentation des Installationsprogramms. Fertigen Sie vor Änderungen an
der CCU-Konfiguration ein vollständiges Backup an. Nutzen Sie für die Installation nach Möglichkeit das
Installationsprogramm `HeizkalenderInstallation.exe` und prüfen Sie die erstellten oder geänderten Skripte
und Konfigurationen vor dem Einsatz in einem produktiven System.

## Installationsprogramm `HeizkalenderInstallation.exe`

Benutzen Sie nach Möglichkeit das Installationsprogramm `HeizkalenderInstallation.exe`, das sich zusammen
mit den Skripten in diesem Verzeichnis befindet. Das Programm ist eine Windows-Anwendung und läuft auf
aktuellen Windows-Systemen.

Dieses Programm unterstützt bei Neuinstallationen, Updates und Änderungen von Parametern in bestehenden
Installationen.

Die Dokumentation für das Installationsprogramm befindet sich hier:
<https://xmri.github.io/Homematic-Heizungskalender/heizkalender-installation/readme/>

## Heizkalender-Addon

Das Heizkalender-Addon liefert auf einfache Weise wichtige Informationen rund um den Heizkalender. Die
neueste Addon-Version befindet sich ebenfalls in diesem Verzeichnis. Das Addon wird wie andere Zusatzsoftware
auf der CCU über *Einstellungen -> Systemsteuerung -> Zusatzsoftware* installiert.

## Skripte

Dieser Ordner enthält alle Hauptskripte für den Heizkalender.
Eine vollständige Beschreibung der einzelnen Skripte in diesem Ordner finden Sie unter:
<https://xmri.github.io/Homematic-Heizungskalender/skripte/readme>

## Tools

Eine Sammlung nützlicher Tools finden Sie im GitHub-Repository unter:
<https://github.com/xMRi/Homematic-Heizungskalender/tree/main/Tools>

Die dazugehörige Dokumentation finden Sie unter:
<https://xmri.github.io/Homematic-Heizungskalender/tools/readme>

## Versionierung

Es gibt in diesem Projekt keine Versionsnummern in den Skripten. Der Stand jedes Skripts ist am Datum im Kopf 
des Skripts erkennbar. Zusammengehörige Skripte finden Sie in einem Release mit demselben Stand-Datum
(siehe Versions-Label auf GitHub). Auch ein Release wird das Datum als Bezeichnung und Identifikation für Die
Version verwendet. Das neueste Release finden Sie unter:
<https://github.com/xMRi/Homematic-Heizungskalender/releases>

## Hilfe und Rückmeldungen

Bei Fragen und Rückmeldungen zu Ihren Erfahrungen mit dem Heizkalender können Sie sich per E-Mail an das
Heizkalender-Team wenden: <info@heizkalender.de>. Fehler können Sie im GitHub-Issue-Tracker melden:
<https://github.com/xMRi/Homematic-Heizungskalender/issues>.

## Lizenz

Die `HeizkalenderInstallation.exe` ist freie Software.

- Copyright (C) 2026 Martin Richter (xMRi-Software)
- Weitere Teile Copyright (C) 2026 Team Heizkalender:
  Lukas Helduser, Martin Richter (xMRi-Software), Helmut Diedrichs

Einzelheiten finden Sie in den Kopfzeilen der Skripte und Quelltexte.

Dieses Programm wird unter den Bedingungen der
**GNU General Public License, Version 3 (GPLv3),**
oder – nach Ihrer Wahl – jeder späteren Version veröffentlicht.

Sie dürfen das Programm verwenden, verändern und weiterverbreiten,
sofern alle abgeleiteten Werke ebenfalls unter der GPL lizenziert
werden und der Quellcode verfügbar bleibt.

Dieses Programm wird OHNE JEGLICHE GEWÄHRLEISTUNG bereitgestellt,
auch ohne die implizite Gewährleistung der Marktfähigkeit oder
Eignung für einen bestimmten Zweck.

Der vollständige Lizenztext befindet sich in der Datei `LICENSE` oder ist unter
folgender Adresse abrufbar:
<https://www.gnu.org/licenses/>

## Hinweis zur Nutzung mit Homematic-, CCU- und IoT-Systemen

Diese Software wurde zur unterstützenden Konfiguration und Verwaltung zeitbasierter
Heizungssteuerungen entwickelt, insbesondere im Umfeld von Homematic-, CCU- und vergleichbaren
IoT-Systemen.

Die `HeizkalenderInstallation.exe` steht in keiner Verbindung zur
eQ-3 AG oder anderen Herstellern von Smart-Home-Komponenten.

Die Software:

- ersetzt keine sicherheitsrelevanten Schutzmechanismen
- greift nicht eigenständig in Regelungs- oder Notfallfunktionen ein
- übernimmt keine Überwachung von Temperatur-, Frost- oder Sicherheitsgrenzwerten

Skripte, Programme oder Konfigurationen, die durch diese Software erstellt oder verändert werden,
sollten vor dem Einsatz in produktiven Systemen sorgfältig geprüft werden.

Der Autor übernimmt keine Haftung für Schäden an:

- Homematic-Zentralen (CCU, RaspberryMatic, debmatic)
- Aktoren, Sensoren oder Heizungsanlagen
- angebundenen IoT- oder Smart-Home-Systemen

Die Nutzung erfolgt ausschließlich auf eigene Verantwortung. Vor jeder Änderung wird dringend empfohlen,
ein vollständiges Backup der CCU-Konfiguration anzufertigen.

