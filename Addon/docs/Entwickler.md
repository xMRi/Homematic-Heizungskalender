# Heizkalender Addon: Entwicklerdokumentation

## Inhalt

- [Überblick](#überblick)
- [Verzeichnisstruktur](#verzeichnisstruktur)
- [Paketformat und Installation](#paketformat-und-installation)
- [rc.d-Script](#rcd-script)
- [CGI-Seiten](#cgi-seiten)
- [CSS und Assets](#css-und-assets)
- [Update-Check](#update-check)
- [Entwicklungsworkflow](#entwicklungsworkflow)
- [Technische Besonderheiten (CCU3 / Tcl 8.2)](#technische-besonderheiten-ccu3--tcl-82)

---

## Überblick

Das Heizkalender Addon ist ein reines Weboberflächen-Addon ohne eigenen Daemon. Es liefert CGI-Scripte, die auf der CCU laufen und Daten über die HomeMatic ReGa-API sowie direkt aus dem Dateisystem lesen.

Die Oberfläche ist grundlegend responsiv gestaltet (Navigation bricht um, Tabellen scrollen horizontal). Eine vollständige Optimierung für Mobilgeräte ist nicht angestrebt, da die breiten Datentabellen auf kleinen Displays immer eine horizontale Scrollmöglichkeit erfordern.

Referenz für das allgemeine CCU-Addon-Format: [ccu-addon-howto](https://github.com/homematic-community/ccu-addon-howto)

---

## Verzeichnisstruktur

```txt
Addon/
  build.sh                         Build-Skript
  src/
    VERSION                        Versionsnummer (z.B. 0.1.0)
    update_script                  Installations-/Update-Script (Shell)
    rc.d/
      heizkalender                 rc.d-Script (start/stop/info/uninstall)
    heizkalender/
      www/
        index.cgi                  Raumübersicht
        hkkurve.cgi                Heizkurvenkontrolle
        hklog.cgi                  HK-Log (USB-Stick-Archiv)
        hklogdownload.cgi          HK-Log-Datei-Download
        syslog.cgi                 Systemlog (/var/log/messages)
        sysvars.cgi                Systemvariablen-Übersicht
        hkconfig.cgi               Grundeinstellungen
        update_check.cgi           Update-Check (GitHub Releases API)
        heizkalender.css           Eigenes Stylesheet
        hk-logo-300.png            Logo (Navigation)
        hk-logo-50.png             Logo (CCU-Zusatzsoftware-Seite)
  docs/
    Entwickler.md                  Diese Datei
    Anwenderhandbuch.md            Anwender-Dokumentation
    DEVELOPMENT_STANDARDS.md       Entwicklungsstandards
  build/                           Ausgabeverzeichnis (per .gitignore ausgeschlossen)
```

**Auf der CCU** wird das Addon unter `/usr/local/addons/heizkalender/` installiert. Die Webinhalte sind über einen Symlink unter `/usr/local/etc/config/addons/www/heizkalender` erreichbar und damit im Browser unter `/addons/heizkalender/` verfügbar.

---

## Paketformat und Installation

Das Installationspaket ist ein tar.gz-Archiv mit dem Namen `heizkalender-addon-<Version>.tar.gz` (z.B. `heizkalender-addon-0.3.0.tar.gz`).

**Paketstruktur:**

```txt
heizkalender-addon-<Version>.tar.gz
├── VERSION
├── update_script
├── heizkalender/
│   └── www/
│       ├── index.cgi
│       ├── hkkurve.cgi
│       ├── hklog.cgi
│       ├── hklogdownload.cgi
│       ├── syslog.cgi
│       ├── sysvars.cgi
│       ├── hkconfig.cgi
│       ├── update_check.cgi
│       ├── heizkalender.css
│       ├── hk-logo-300.png
│       ├── hk-logo-50.png
│       └── (Favicons und App-Icons)
└── rc.d/
    └── heizkalender
```

**Archiv erstellen** (aus dem Projektverzeichnis):

```bash
./Addon/build.sh
```

Das Skript liest die Version aus `Addon/src/VERSION` und legt das Archiv unter `Addon/build/heizkalender-addon-<Version>.tar.gz` ab. Das `build/`-Verzeichnis ist per `.gitignore` vom Repository ausgeschlossen.

Das Archiv enthält im Root `VERSION`, `update_script` und die Verzeichnisse `heizkalender/` und `rc.d/`.

**Ablauf bei Installation/Update durch die CCU:**

1. CCU entpackt das Archiv nach `/usr/local/tmp/` und ruft `update_script HM-RASPBERRYMATIC` auf.
2. Das Script legt `/usr/local/addons/heizkalender/` an und kopiert die Dateien.
3. Es setzt den Symlink für die Webinhalte und trägt das Addon in `hm_addons.cfg` ein.
4. Bei Neuinstallation: Exit-Code `10` (CCU startet neu). Bei Update: Exit-Code `0`.

Da das Addon keinen Daemon hat, entfällt das Starten und Stoppen eines Service.

---

## rc.d-Script

Das rc.d-Script liegt unter `Addon/rc.d/heizkalender` und wird bei der Installation nach `/usr/local/etc/config/rc.d/heizkalender` verlinkt.

Da das Addon keinen eigenen Daemon hat, implementiert das Script nur die Pflicht-Kommandos:

| Kommando | Verhalten |
| -------- | --------- |
| `info` (oder kein Argument) | Gibt Name, Version, Info-HTML und Config-URL aus; aktualisiert `hm_addons.cfg` |
| `uninstall` | Entfernt Symlinks, Addon-Verzeichnis und Eintrag aus `hm_addons.cfg` |
| alle anderen | Exit 1 |

**`info`-Ausgabe (Key-Value-Format):**

```txt
Name: Heizkalender
Version: <VERSION>
Info: <HTML-Infotext mit Logo>
Config-Url: /addons/heizkalender/index.cgi
Update: /addons/heizkalender/update_check.cgi
Operations: uninstall
```

Das `Info:`-Feld enthält HTML, das die CCU auf der Seite **Einstellungen > Zusatzsoftware** darstellt. Es enthält das Logo (`hk-logo-50.png`), den Addon-Namen als `<b>` und einen Link zur GitHub-Projektseite. Das Logo wird dabei über einen relativen Pfad (`../addons/heizkalender/hk-logo-50.png`) eingebunden, weil die Zusatzsoftware-Seite selbst nicht unter `/addons/` liegt.

Die `hm_addons.cfg`-Aktualisierung im `info`-Zweig erfolgt über ein eingebettetes Tcl-Script, das Tcl 8.2-kompatibel ist (kein `dict`).

**Tooltip auf der CCU-Systemsteuerungsseite:** Unter *Startseite > Einstellungen > Systemsteuerung* zeigt die CCU beim Überfahren des Addon-Buttons einen Tooltip. Der Text wird über das Feld `CONFIG_DESCRIPTION` in `hm_addons.cfg` gesteuert. Das rc.d-Script schreibt dort eine HTML-`<ul>`-Liste mit den Seitennamen:

```tcl
set tooltip {<li>Raumübersicht</li><li>Heizkurve</li>...}
set addons($id) "... CONFIG_DESCRIPTION {de {$tooltip} en {$tooltip}} ..."
```

**Bekannter CCU-Bug (`<h1>`-Element):** Die CCU generiert auf der Systemsteuerungsseite für jeden Addon-Eintrag ein `<h1>`-Element, das den Addon-Namen enthalten soll. In der Praxis bleibt das Element leer, obwohl `CONFIG_NAME` korrekt gesetzt ist. Das ist ein CCU-seitiger Darstellungsfehler, der sich nicht über das Addon beeinflussen lässt.

---

## CGI-Seiten

Alle CGI-Scripte sind in Tcl geschrieben und laufen unter `/bin/tclsh` (Tcl 8.2.3 auf CCU3-Originalfirmware).

### index.cgi: Raumübersicht

Liest über die ReGa-API:

- `HK1-Schaltliste`: Aktuelle Schaltzeitpunkte
- `HK1-R-Liste`: Ressourcen-ID-zu-Name-Mapping
- `HK2-Aussentemperatur`: Außentemperatur (gleitender Mittelwert)
- Alle `HKG-Raum-*`-Variablen: Raumkonfigurationen; Feld 0 enthält den aktuellen Heizstatus (0 = nicht heizend, 1 = heizt)
- Ist-Temperaturen und Luftfeuchtigkeit direkt von den zugeordneten Thermostat-Kanälen

Schaltlisten-Zeitstempel (`JJJJ-MM-TT HH:MM:SS`) werden mit einer eigenen `parse_ts`-Prozedur in Unix-Timestamps umgewandelt, da `clock scan` in Tcl 8.2 kein ISO-Datumsformat versteht (nur US-Format `MM/DD/JJJJ HH:MM:SS`).

### hkkurve.cgi: Heizkurvenkontrolle

Liest Logdateien vom USB-Stick (`/media/usb1/HK-Log_*.log`) per `grep`. Die Ereignisse werden nach Zeitstempel aufsteigend sortiert (`lsort -index 1`).

Die Seite lädt erst Daten, wenn der Nutzer auf **Anzeigen** geklickt hat (Parameter `submitted=1`), um unnötige Dateizugriffe beim ersten Aufruf zu vermeiden.

**Log-Format (geschrieben von `HK-Heizkurvenkontrolle.hsc`):**

Jede Zeile in der Logdatei hat den Tab-getrennten Aufbau:

```text
YYYY-MM-DD HH:MM:SS \t HK-LogHeizkurvenkontrolle \t <Nachricht>
```

Die `<Nachricht>` hat je nach Ereignistyp eines der folgenden Formate:

```text
Name(ID) Heizbeginn: <delta>min, Ist: <ist>, Ziel: <ziel>, AT: <at>
Name(ID) Heizende: <delta>min, Ist: <ist>, Ziel: <ziel>, Max.: <max>
Name(ID) Zieltemperatur: <delta>min, Ist: <ist>, Ziel: <ziel>, Max.: <max>
Name(ID) Terminbeginn: <delta>min, Ist: <ist>, Ziel: <ziel>, Max.: <max>
Name(ID) Terminende: <delta>min, Ist: <ist>, Ziel: <ziel>, Max.: <max>
Name(ID): Kein Temperatur-Sensor konfiguriert (Feld 6 leer) - ...
Name(ID): Temperatur-Sensor <Kanalname> existiert nicht - ...
```

| Platzhalter | Bedeutung |
| ----------- | --------- |
| `Name(ID)` | Raumname mit Ressourcen-ID, z.B. `EG-Saal(5)` |
| `<delta>` | Minuten relativ zum Terminbeginn (negativ = vor, positiv = nach); mit führendem `+` wenn positiv |
| `<ist>` | Ist-Temperatur zum Zeitpunkt des Ereignisses (1 Dezimalstelle) |
| `<ziel>` | Ziel-/Wohlfühltemperatur des Raums (1 Dezimalstelle) |
| `<at>` | Außentemperatur (nur bei Heizbeginn) |
| `<max>` | Maximale gemessene Temperatur in dieser Heizphase (alle außer Heizbeginn) |

Fehler-Zeilen (kein Sensor) haben statt Leerzeichen vor dem Ereignis einen Doppelpunkt: `Name(ID): ...`. Der Parser in `hkkurve.cgi` erkennt dieses Muster und ordnet sie als Ereignistyp `Fehler` ein.

**Herkunft der Namen im Log:**

Alle Skripte arbeiten ausschließlich mit Kalender-Ressourcennamen, nicht mit CCU-internen Bezeichnungen. Die Verbindung zwischen den Systemvariablen und dem Log-Format:

- `HK1-R-Liste` enthält `ID=Kalendername`, z.B. `11=EG-Eltern-Kind-Raum`
- `HK2-HKG-Liste` enthält die zugehörigen CCU-Raumvariablen, z.B. `HKG-Raum-EG-Eltern-Kind-Raum+HKG-Raum-UG-Büro`
- Die Namen in `HK2-HKG-Liste` (ohne Präfix `HKG-Raum-`) sind identisch mit den Kalender-Ressourcennamen aus `HK1-R-Liste`

Daraus ergibt sich das Log-Format:

- **Normalfall** (ein Raum pro Ressource): `EG-Eltern-Kind-Raum(11)` — Raumname und Ressourcenname sind identisch, kein Suffix
- **Gruppenfall** (mehrere Räume per `+` verbunden): `EG-Eltern-Kind-Raum(11)-UG-Büro` — der zweite Raum der Gruppe wird als Suffix angehängt; `UG-Büro` ist dabei ebenfalls ein eigenständiger Eintrag in `HK1-R-Liste`

Der Dropdown in `hkkurve.cgi` verwendet `HK1-R-Liste` als Quelle. Eine Substring-Suche auf den gewählten Namen findet damit sowohl den Normalfall (`UG-Büro(22)`) als auch alle Gruppeneinträge, in denen dieser Raum vorkommt (`EG-Eltern-Kind-Raum(11)-UG-Büro`).

### hksyslog.cgi: HK-Log

Liest direkt aus Logdateien auf dem USB-Stick. Kein ReGa-Aufruf. Die Seite zeigt die letzten N Zeilen der gewählten Datei (tail-Prinzip).

Zeitstempel im Log haben das Format `JJJJ-MM-TT HH:MM:SS` (aus der CCU-Historiendatenbank, geschrieben von `HK-SystemProtokoll sichern.hsc`).

### hklogdownload.cgi: HK-Log-Download

Liefert eine Logdatei vom USB-Stick als Download (`Content-Disposition: attachment`). Wird von `hksyslog.cgi` über den **Download**-Link aufgerufen. Der Dateiname wird als Query-Parameter übergeben; das Script prüft, dass der Pfad innerhalb des Log-Verzeichnisses bleibt (kein Directory Traversal).

### syslog.cgi: Systemlog

Liest `/var/log/messages` direkt. Kein ReGa-Aufruf. Zeitstempel im Linux-Syslog-Format (`Mmm DD HH:MM:SS`). Zeigt die letzten N Zeilen (tail-Prinzip, älteste oben).

**Abgrenzung zum CCU-Systemprotokoll:** Die CCU-Weboberfläche unter *Startseite > Status und Bedienung > Systemprotokoll* zeigt eine andere Datenquelle: das ReGa-interne Ereignisprotokoll (Programmausführungen, Gerätekommunikation, Alarme). Diese Daten liegen in der ReGaHss-Datenbank und sind über die ReGa-API abfragbar (z.B. `dom.GetObject(ID_SYSTEMLOG)`), nicht über `/var/log/messages`. Eine Einbindung dieses Protokolls in `syslog.cgi` wäre möglich, wurde aber bisher nicht umgesetzt.

### sysvars.cgi: Systemvariablen

Liest alle `HK-*`-, `HK1-*`-, `HK2-*`- und `HKG-Raum-*`-Variablen über die ReGa-API. Rein lesend.

### hkconfig.cgi: Grundeinstellungen

Zeigt Logging-Flags, Kurveneinstellungen und eine Raumübersicht in aufbereiteter Form. Rein lesend.

### update_check.cgi: Update-Check

Ruft die GitHub Releases API ab und vergleicht die aktuelle `VERSION`-Datei mit dem neuesten Release-Tag. Gibt das Ergebnis als JSON zurück, das die CCU-Weboberfläche auswertet.

---

## CSS und Assets

`heizkalender.css` enthält das gesamte eigene Styling. Es ergänzt das CCU-eigene Stylesheet, lädt dieses aber nicht mehr ein (der frühere Link auf `/config/style.css` wurde entfernt, da die CCU die Datei mit falschem MIME-Typ ausliefert).

Klassen-Übersicht (Auswahl):

| Klasse | Verwendung |
| ------ | ---------- |
| `.hk-nav` | Navigationsleiste oben |
| `.hk-hint` | Blauer Infoblock (Hinweise) |
| `.hk-table` | Basis-Tabellenklasse |
| `.hk-log-table` | Log-Tabellen (monospace, automatische Spaltenbreiten) |
| `.hk-schaltliste-table` | Raumübersichts-Tabelle |
| `.hk-kurve-table` | Heizkurvenkontrolle-Tabelle |
| `.hk-log-error/hk1/hk2/hk` | Zeilenfärbung in Log-Tabellen |
| `.hk-kurve-heizbeginn` etc. | Zeilenfärbung in Heizkurven-Tabelle |

**Tooltips:** Spaltenüberschriften mit erklärungsbedürftigem Inhalt erhalten ein `title`-Attribut direkt am `<th>`-Element. Der Text erscheint beim Überfahren mit der Maus als Browser-nativer Tooltip. Kein JavaScript erforderlich.

**Logos:** Die eingebundenen Logo-Dateien stammen aus dem Verzeichnis `Logos/` im Projektroot. Dort liegen vorgerenderte PNGs in verschiedenen Größen. Für das Addon werden zwei Größen verwendet:

| Datei | Verwendung | Quelle |
| ----- | ---------- | ------ |
| `hk-logo-300.png` | Navigationsleiste in der Weboberfläche | `Logos/HK-Logo (300px).png` |
| `hk-logo-50.png` | Zusatzsoftware-Seite der CCU (im `Info:`-Feld des rc.d-Scripts) | `Logos/HK-Logo (50px).png` |

---

## Update-Check

`update_check.cgi` prüft auf neue Releases, indem es die `VERSION`-Datei direkt aus dem GitHub-Repository liest:

```txt
https://raw.githubusercontent.com/xMRi/Homematic-Heizungskalender/main/Addon/src/VERSION
```

Das entspricht dem Vorbild von `hm-watchdog`. Kein JSON-Parsing, kein fester Asset-Name. Beim Download-Befehl leitet das Script auf die GitHub-Releases-Seite weiter; der Nutzer lädt das passende Asset dort selbst herunter.

---

## Entwicklungsworkflow

Einzelne Dateien für schnelle Tests direkt auf die CCU übertragen:

```bash
scp Addon/src/heizkalender/www/index.cgi root@<CCU-IP>:/usr/local/addons/heizkalender/www/
```

Vollständiges Paket bauen (aus dem Projektverzeichnis):

```bash
./Addon/build.sh
```

Das Paket landet in `Addon/build/heizkalender-addon-<Version>.tar.gz`.

### Versionierung und Release-Prozess

Das Addon verwendet ein eigenes Versionierungsschema, unabhängig von den Datums-Tags der Skripte:

- Die Versionsnummer steht in `Addon/src/VERSION` (z.B. `0.5.0`).
- Git-Tags für Addon-Releases haben das Format `addon-v<Version>` (z.B. `addon-v0.5.0`). Tag nur in den eigenen Fork pushen (`git push fork addon-v<Version>`), nicht nach `origin`.
- Skript-Releases verwenden weiterhin Datums-Tags (`v2026-10-12`).

Release-Prozess:

1. `Addon/src/VERSION` auf die neue Version setzen.
2. `./Addon/build.sh` ausführen (legt Paket in `Addon/build/` ab).
3. Änderungen committen und pushen.
4. Tag setzen und in den Fork pushen: `git tag addon-v<Version> && git push fork addon-v<Version>`.
5. GitHub-Release mit dem Versions-Tag anlegen und `Addon/build/heizkalender-addon-<Version>.tar.gz` als Asset anhängen.

---

## Technische Besonderheiten (CCU3 / Tcl 8.2)

Verbindliche Regeln für alle CGI-Scripte (Tcl-8.2-Einschränkungen, Zeichenkodierung, HTML-Ausgabe, CSS-Konventionen, entschiedene Design-Fragen): siehe [DEVELOPMENT_STANDARDS.md](DEVELOPMENT_STANDARDS.md).

**ReGa-API:** Scripte mit `rega_script` ausführen, Rückgabe mit `extract_stdout` auswerten. Geschweifte Klammern in der Rückgabe erfordern eine manuelle Tiefenzählung (kein regulärer Ausdruck).

**Keine Authentifizierung:** Die CGI-Seiten prüfen keine Session-ID. Das Addon setzt voraus, dass der Zugriff auf das Netzwerk der CCU bereits ausreichend gesichert ist.
