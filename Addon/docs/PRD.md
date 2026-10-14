# Heizkalender Addon: Product Requirements Document (PRD)

## Inhalt

- [Zweck und Ziel](#zweck-und-ziel)
- [Zielgruppe](#zielgruppe)
- [Abgrenzung](#abgrenzung)
- [Funktionale Anforderungen](#funktionale-anforderungen)
- [Nicht-funktionale Anforderungen](#nicht-funktionale-anforderungen)
- [Seiten und ihre Funktion](#seiten-und-ihre-funktion)
- [Designprinzipien](#designprinzipien)

---

## Zweck und Ziel

Das Heizkalender Addon stellt eine browserbasierte Weboberfläche auf der CCU bereit, über die der laufende Betrieb des Heizkalenders beobachtet werden kann. Es ergänzt die bestehenden Heizkalender-Skripte (Skript 1 und Skript 2) um eine visuelle Statusanzeige, ohne selbst steuernd in die Heizungslogik einzugreifen.

Das Addon ist rein lesend: es zeigt Daten an, verändert aber keine Systemvariablen oder Programme.

---

## Zielgruppe

Administratoren und Nutzer einer HomeMatic CCU3 oder RaspberryMatic, die den Heizkalender betreiben und dessen Betrieb im Browser überwachen möchten, ohne die CCU-Weboberfläche oder den Windows-Installer zu benötigen.

---

## Abgrenzung

Das Addon:

- zeigt Daten an, schreibt aber nichts zurück auf die CCU
- ersetzt nicht den Windows-Installer (Einrichten und Ändern von Systemvariablen bleibt Aufgabe des Installers)
- erfordert keine Authentifizierung (setzt voraus, dass der Netzwerkzugang zur CCU ausreichend gesichert ist)
- läuft vollständig lokal auf der CCU, ohne externe Abhängigkeiten zur Laufzeit (Ausnahme: Update-Check ruft die GitHub Releases API ab)

---

## Funktionale Anforderungen

| Nr. | Anforderung |
| --- | ----------- |
| F1 | Raumübersicht: aktueller Heizstatus aller Räume, inkl. Ist-Temperatur, Luftfeuchte, nächster/aktueller Termin |
| F2 | Heizkurvenkontrolle: Auswertung archivierter Heizereignisse vom USB-Stick mit Filtermöglichkeit |
| F3 | HK-Log: Anzeige der archivierten Protokolleinträge vom USB-Stick, filterbar nach Quelle |
| F4 | Systemlog: Anzeige der letzten Einträge aus `/var/log/messages`, filterbar auf Heizkalender-Einträge |
| F5 | Systemvariablen: Übersicht aller HK-*-Systemvariablen mit Wert und Beschreibung, gruppiert nach Präfix |
| F6 | Grundeinstellungen: aufbereitete Darstellung von Logging-Flags, Kurveneinstellungen und Raumkonfigurationen |
| F7 | Update-Check: Vergleich der installierten Version mit dem neuesten GitHub-Release |
| F8 | Download: Einzelne HK-Log-Dateien vom USB-Stick herunterladen |

---

## Nicht-funktionale Anforderungen

| Nr. | Anforderung |
| --- | ----------- |
| NF1 | Laufzeitumgebung: CCU3-Originalfirmware (Tcl 8.2.3, Linux) |
| NF2 | Keine externen Laufzeitabhängigkeiten (kein Node.js, kein Python, kein zusätzlicher Daemon) |
| NF3 | Alle Seiten müssen ohne JavaScript funktionieren |
| NF4 | Responsive genug für gängige Desktop-Browser; kein spezielles Mobile-Layout erforderlich |
| NF5 | Ladezeit: Seiten ohne USB-Stick-Zugriff sollen in unter 2 Sekunden laden |
| NF6 | Zeichenkodierung: `Content-Type: text/html; charset=iso-8859-1` auf allen Seiten |

---

## Seiten und ihre Funktion

| Seite | Datei | Datenquelle |
| ----- | ----- | ----------- |
| Raumübersicht | `index.cgi` | ReGa-API: `HK1-Schaltliste`, `HK1-R-Liste`, `HK2-Aussentemperatur`, `HKG-Raum-*`, Thermostat-Kanäle |
| Heizkurvenkontrolle | `hkkurve.cgi` | USB-Stick: `HK-Log_*.log` (via `grep`) |
| HK-Log | `hklog.cgi` | USB-Stick: `HK-Log_*.log` |
| HK-Log-Download | `hklogdownload.cgi` | USB-Stick: `HK-Log_*.log` |
| Systemlog | `log.cgi` | `/var/log/messages` |
| Systemvariablen | `sysvars.cgi` | ReGa-API: alle `HK-*`-, `HK1-*`-, `HK2-*`-, `HKG-Raum-*`-Variablen |
| Grundeinstellungen | `hkconfig.cgi` | ReGa-API: Systemvariablen, Programme, Raumvariablen |
| Update-Check | `update_check.cgi` | GitHub Releases API + lokale `VERSION`-Datei |

---

## Designprinzipien

- **Einfachheit vor Vollständigkeit:** Lieber eine klare, übersichtliche Anzeige als eine vollständige Abbildung aller internen Daten.
- **Kein Schreiben:** Die Weboberfläche ist ein reines Beobachtungswerkzeug. Keine Formularfelder, keine PUT/POST-Aktionen auf die CCU.
- **Kein JavaScript:** Alle Seiten funktionieren mit reinem HTML. Interaktivität (Filter, Formulare) läuft serverseitig über GET-Parameter.
- **Einheitliches Erscheinungsbild:** Alle Seiten teilen dasselbe CSS (`heizkalender.css`) und dieselbe Navigationsleiste.
- **Keine externe Abhängigkeiten:** Kein CDN, keine externen Fonts, keine externen Icons.
