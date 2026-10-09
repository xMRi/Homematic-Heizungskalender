# Changelog

Alle nennenswerten Änderungen an diesem Projekt werden in dieser Datei
dokumentiert.

Das Format orientiert sich an [Keep a Changelog](https://keepachangelog.com/de/1.1.0/).
Anstelle von SemVer-Versionsnummern verwendet dieses Projekt **Datums-Stände**
(passend zu den `vJJJJ-MM-TT`-Git-Tags) — alle Skripte eines Standes gehören
zusammen und müssen gemeinsam eingespielt werden.

Diese Datei **ergänzt** die Changelog-Blöcke in den Datei-Headern (`!// MRi:` /
`!// TT:`); diese bleiben erhalten und sind die feinste Änderungsebene.

## [Unveröffentlicht]

## [2026-10-09]

### Behoben

- Unter Umständen wurde bei einem Abbruch des Installers nicht gewarnt, dass Daten geändert wurden.
- Beim Speichern kam unter Umständen eine falsche Meldung über eine geänderte Raumliste

### Hinzugefügt

- Logo im Haupt-Readme eingefügt
- Erweiterung der Dokumentation für den Installer
- Doku um neue Bilder und texte angereichert.
- In einigen Dialogen Des Insatllers werden Felder jetzt fett hervorgehoben.

### Geändert
- Installer *About Dialog* zeigt jetzt auch einen Link auf das GitHub Projekt


## [2026-10-06]

### Geändert

- Aufteilung der Skripte im Tools Ordner in Programme und Debug+Test Code
- `Best practice` ergänzt in einigen Skripten
- Sicherheits Code quit in gefährlichen Skripten eingebaut um versehentliche Nutzung zu 
  verhindern.
- Anpassung der Dokumentation

## [2026-10-05]

### Behoben

- `HK-Skript 2`: Luftfeuchte-Auslesen unterstützt jetzt auch klassische Thermostate
  mit Datenpunkt `ACTUAL_HUMIDITY` (z.B. HM-TC-IT-WM-W-EU). Bisher wurde nur
  `HUMIDITY` (HmIP-Geräte) geprüft; Geräte ohne Feuchtigkeitssensor bleiben
  unverändert.

### Hinzugefügt

- `Dokumentation/Anwenderhandbuch.md`: Neuer Unterabschnitt „Räume mit mehreren
  Heizkörperthermostaten (Homematic-Heizgruppe)" unter den unterstützten Geräten:
  Einrichtung einer CCU-Heizgruppe (`HmIP-HEATING`), manueller Modus via
  `Tool-Heizgruppen Modus zurücksetzen`, Konfiguration im Heizkalender (Heiztyp IP,
  Kanal 1 der Gruppenadresse), Empfehlung zum separaten Schaltaktor-CCU-Programm.
- `Dokumentation/Anwenderhandbuch.md`: Neuer Abschnitt „Wie der Heizkalender
  funktioniert" mit detailliertem Mermaid-Architekturdiagramm (alle Systemvariablen
  als Boxen) und Einsparpotential-Erklärung.
- `Dokumentation/Anwenderhandbuch.md`: Einleitung um Zielgruppe und Kurzbeschreibung
  des Projekts erweitert (sporadisch genutzte Gebäude: Gemeindegebäude, Hotels,
  Ferienwohnungen).
- `Dokumentation/Anwenderhandbuch.md`: Neuer Abschnitt „Voraussetzungen" mit
  Kalender-Zugangsarten (API vs. iCal), Homematic-Hardware, CCU-Optionen und
  optionalen Apps.
- `Dokumentation/Anwenderhandbuch.md`: Neuer Abschnitt „Unterstützte
  Homematic-Geräte" mit Tabelle der Kennungen (IP/RT/TC/IT/SW), Kanäle und
  Datenpunkte.
- `Dokumentation/Anwenderhandbuch.md`: Neuer Abschnitt „Format der
  Übergabevariablen HK1-Schaltliste" mit Feldbeschreibung und Beispielen.
- `Dokumentation/Anwenderhandbuch.md`: Neuer Abschnitt „Warum Homematic?" mit
  den 7 Argumenten für das System.
- `Dokumentation/Anwenderhandbuch.md`: Neuer Abschnitt „Namenskonvention" (Verbot
  doppelter Namen in der CCU, eindeutige Raumbezeichnung je Kalenderquelle).
- `Dokumentation/Anwenderhandbuch.md`: Neuer Abschnitt „Rückstellung am Terminende"
  mit Erklärung von `HK2-Hand-Temp` und `HK2-Hand-Grundtemp`.
- `Dokumentation/Anwenderhandbuch.md`: Hinweis zum gleitenden 36h-Mittelwert der
  Außentemperatur im Abschnitt Vorheizzeit.
- Link auf die Projekt-Homepage <https://heizkalender.de/> in `Readme.md`
  (Abschnitt „Allgemeines") und `Dokumentation/Anwenderhandbuch.md` (Einleitung).

### Geändert

- `Dokumentation/Anwenderhandbuch.md`: Schritt 3 im Heizgruppen-Abschnitt korrigiert:
  Das Tool setzt den Modus auf der Gruppenadresse; die Heizgruppe überträgt ihn
  automatisch auf alle Thermostate. Sonderfall nach Firmware-Update mit Verweis auf
  `Tool-Heizgruppen eTRV Modus setzen.hsc` ergänzt (Feedback Martin).
- `Dokumentation/Anwenderhandbuch.md`: Hinweis ergänzt, dass die Kanalnummer nur
  in der CCU3 relevant ist und der Datenpunkt-Name entscheidend ist (Feedback Martin).
- `Skripte/HK-Skript 2.hsc`: Kommentare für TC (HM-CC-TC) und IT (HM-TC-IT-WM-W-EU)
  von Kanal 4 auf Kanal 2 korrigiert (laut alter Doku und Bestätigung durch Martin).
- `Dokumentation/Anwenderhandbuch.md`: Systemarchitektur-Diagramm durch die
  verallgemeinerte Fassung aus `Readme.md` ersetzt (Kalenderquelle generisch statt
  nur ChurchTools).
- `Dokumentation/Anwenderhandbuch.md`: Gültige Grenzen des Raumvariablen-`*Faktor`
  von „0.25 bis 3" auf die tatsächlichen Code-Werte „0.20 bis 5.0" korrigiert.
- `Dokumentation/Anwenderhandbuch.md`: Gerätetabelle mit Hinweis ergänzt, dass der
  Admin die Aktor-Zuordnung inklusive Kanal selbst festlegt (Kanäle RT=4, TC=2, IT=2
  gemäß Olafs Handbuch und den PDF-Vorlagen).
- `Dokumentation/Anwenderhandbuch.md`: Neuer Abschnitt „Die richtige Grundtemperatur:
  Heizversuch" (aus Olafs Handbuch v0.4 übernommen).
- `Dokumentation/Anwenderhandbuch.md`: Neuer Abschnitt „Globale Einstellungen
  (Systemvariablen für Skript 2)" mit Empfehlwerten (aus Olafs Handbuch v0.4).
- `Dokumentation/Planung.md` (neu): Planung der Struktur und Nomenklatur
  (Aktorengruppen/Heizgruppen mit Beispieltabelle), aus Olafs Handbuch v0.4.
- `Dokumentation/Kalender-einrichten.md` (neu): Ermittlung der Kalender-Zugangsdaten
  (ChurchTools, ChurchDesk; Google/iCal als Platzhalter), aus Olafs Handbuch v0.4.
  Beide neuen Dokumente in `Readme.md` und `Anwenderhandbuch.md` referenziert.
### Hinzugefügt

- `Tools/Tool-Test Thermostatgruppe schalten.hsc` (neu): schreibt eine Solltemperatur
  direkt auf eine Homematic-Heizgruppe (`HmIP-HEATING`) und liest den Datenpunkt
  `SET_POINT_TEMPERATURE` vorher und nachher aus.
- `Tools/Tool-Test Thermostatgruppe auslesen.hsc` (neu): liest alle relevanten
  Datenpunkte einer Heizgruppe aus (`SET_POINT_TEMPERATURE`, `ACTUAL_TEMPERATURE`,
  `CONTROL_MODE`, `LEVEL`, `SET_POINT_MODE`).

### Geändert

- `Tools/Tool-Test Thermostatgruppe auslesen.hsc`: Einzelthermostate (HmIP-eTRV-2)
  werden jetzt zusätzlich zur Heizgruppe ausgelesen. Zugriff per Seriennummer
  (CCU-interne Suche), Ausgabe von `CONTROL_MODE`, `SET_POINT_MODE`, `LOW_BAT`
  und `RSSI_DEVICE` je Thermostat.
- `Tools/Tool-Heizgruppen Modus zurücksetzen.hsc`: Einzelthermostate in Heizgruppen
  werden jetzt ebenfalls auf den gewünschten Modus gesetzt. Bisher wurden nur die
  Heizgruppen-Datenpunkte geschrieben; die Mitglied-Thermostate fielen nach dem
  nächsten CCU-Neustart oder Zyklus auf Auto zurück.
- `Tools/Tool-Heizgruppen Modus zurücksetzen.hsc`: Tippfehler und englische
  Debug-Ausgaben korrigiert. Log-Einträge kennzeichnen jetzt, dass ein Befehl
  gesendet wurde (SET_POINT_MODE wird erst nach dem nächsten Funk-Zyklus aktualisiert).
- `Tools/Readme.md`: Beschreibung von `Tool-Heizgruppen Modus zurücksetzen` aktualisiert;
  `Tool-Test Thermostatgruppe auslesen` und `Tool-Test Thermostatgruppe schalten` ergänzt.
- `Tools/Tool-Gestörte Kommunikation beheben.hsc`: Neuer Block für ausstehende
  Konfigurationsdaten (CONFIG_PENDING): Geräte mit gesetztem Flag werden ebenfalls
  angestoßen. Log-Eintrag und Debug-Ausgabe ergänzt. Beschreibung in `Tools/Readme.md`
  aktualisiert.
- `Skripte/HK-Außentemperatur-Open-Meteo.hsc`: Log-Eintrag erweitert: zeigt jetzt
  aktuellen Messwert, gleitenden Durchschnitt mit °C und das verwendete Zeitfenster
  (z.B. `Akt. Außentemperatur= 18.2°C / Durchsch. Außentemperatur= 14.6°C (Zeitfenster: -18h/+6h)`).
  Tippfehler in Kommentaren korrigiert; `+` durch `#` in DEBUG-Ausgaben ersetzt.
- `Skripte/HK-Init-Skript 2.hsc`: Beschreibung von `HK2-Aussentemperatur` präzisiert
  (war: „Zu verwendende Außentemperatur"; jetzt: „Außentemperatur für Vorheizzeit-Berechnung
  (gleitender Durchschnitt)").
- `Skripte/Dokumentation/Readme.md`: Abschnitt `HK-Außentemperatur-Open-Meteo` überarbeitet:
  veraltete 36h-Angabe korrigiert, Zeitfenster-Parameter tabellarisch dokumentiert,
  Log-Format als Beispiel ergänzt.

### Behoben

- `Skripte/HK-Test-Skript.hsc`: Modus `HS` (Heizen+Schalten) wurde als
  `UNBEKANNT!!! FEHLER!!!` ausgegeben. Fix: `HS` wird jetzt korrekt als
  `Heizen+Schalten` angezeigt.

## [2026-10-03]

### Geändert

- `HK-Skript 2`: Nachtschaltungs-Log um „bereits korrekt"-Meldung pro Aktor ergänzt
  (Schalttyp: Zustand bereits korrekt). Da die Nachtschaltung nur einmal pro Nacht
  läuft, ist der Zustand der Aktoren jetzt vollständig im Log nachvollziehbar.
- `HK-Skript 2`: Nachtschaltungs-Log vollständig überarbeitet: Raumnamen-Präfix ergänzt
  (konsistent zur Hauptschleife); eine Log-Meldung pro Gruppe statt pro Einzelraum;
  bei Multi-Raum-Gruppen `(inkl. Raum2, Raum3)`

### Dokumentation

- `Skripte/Dokumentation/Readme.md`, `Dokumentation/Anwenderhandbuch.md`: Nachtschaltung
  und Schaltlistenprüfung dokumentiert (Aktivierung, Zeitfenster, Verhalten für
  Heizräume und Schaltaktoren, Zweck als Absicherung gegen dauerhaft eingeschaltete Aktoren).

## [2026-10-02]

### Geändert

- `HK-Skript 2`: Log-Text bei fehlendem Temperatursensor verständlicher formuliert.
  Statt der internen HomeMatic-Syntax `GT.Max(AT)` steht jetzt
  `Raumtemp.-Schaetzwert=X°C (Max aus Grundtemp./Aussentemp.)`.
- `Dokumentation/Anwenderhandbuch.md`: Heizkurven-Abschnitt um eine
  Vergleichstabelle mit drei Beispielkurven (konservativ / mittel / großzügig)
  und einem Hinweis zum Raumvariablen-`*Faktor` erweitert.
- `Skripte/Dokumentation/Heizsteuerung-Vorheizzeit.md`: Fußnote benennt die
  Beispieltabelle jetzt explizit als großzügige Kurve
  (`451;370;297;196;174;154;125;103`).
- `Skripte/Dokumentation/Readme.md`: Beschreibung von `HK2-Kurve` nennt jetzt
  alle drei Kurventypen statt nur Default und ein Produktivbeispiel.

### Entfernt

- `HeizkalenderInstallation/res/SYSVAR-Init.txt`: veraltete, unreferenzierte
  erste Vorlage der Systemvariablen-Initialisierung entfernt.
- `TODO.md`: Offene-Punkte-Datei entfernt. Der HK2-Kurve-Punkt ist durch die
  Doku-Erweiterung adressiert; der Installer-Doku-Punkt bleibt vorerst offen.

## [2026-10-01]

### Hinzugefügt

- Werkzeuge zum Reproduzieren und Diagnostizieren des Duplikat-Bugs
  (`Tests/Test-Duplikatcheck-Bug.hsc`, `Tools/Tool-Diagnose Raumzuordnung
  ChurchTools.hsc`, `Tests/churchtools.http`).

### Geändert

- Alle fünf Skript-1-Varianten nutzen jetzt einheitlich 12h Vorlauf (`zeitVorlauf`);
  die vier 8h-Varianten (ChurchDeskAPI, ChurchDeskiCal, Google, iCal) wurden auf
  12h angehoben. Die bisherige Divergenz (ChurchTools 12h, Rest 8h) ist aufgelöst.
- `HK-Skript 2`: Fallback-Raumtemperatur bei fehlendem Sensor von `GT` auf
  `GT.Max(AT)` geändert. Bei milder Außentemperatur wird die Vorheizzeit dadurch
  kürzer als die volle Kurvenzeit, statt immer 100% zu verwenden.
- `HK-Skript 2`: Log-Text bei fehlendem Temperatursensor korrigiert: zeigt jetzt
  den tatsächlich verwendeten Wert `GT.Max(AT)` statt fest „Grundtemperatur GT".
  Betrifft beide Fälle (kein Aktor zugeordnet, Aktor ohne Temperatur-Datenpunkt).
- `HK-Skript 2`: Stand-Datum im Header von `30.10.2026` (Tippfehler) auf
  `01.10.2026` korrigiert.
- Vergangenheits-Check in `HK-Skript 1_ChurchTools` von `<=` auf `<`
  vereinheitlicht (1-Sekunden-Divergenz am Nachlaufende entfernt, jetzt alle
  Skript-1-Varianten gleich).
- Log-Format der Raumnamen bereinigt: Normalfall `Name(ID)` statt
  `Name (ID)-Name`, Multiraum-Zusatz nur bei Bedarf; betrifft `HK-Skript 2`,
  `HK-Heizkurvenkontrolle` und alle Skript-1-Varianten.
- Kommentarblock zum Zeitfenster in allen fünf Skript-1-Varianten vereinheitlicht
  (Haltezeit-Semantik, kein Heiz-Nachlauf erklärt).
- Dokumentation (`Skripte/Dokumentation/Readme.md`) um eine ausführlichere
  `HK2-Kurve`-Erklärung erweitert.

### Behoben

- False-Positive im Duplikat-Check: Eine einstellige Ressource-ID (z.B. `1`)
  wurde fälschlich als Teil einer mehrstelligen ID (z.B. `11`) erkannt und der
  Termin übersprungen — kein Heizen, kein Log. Fix: Semikolon-Präfix verankert
  die Suche an Eintraggrenzen. Betrifft alle fünf Skript-1-Varianten.

## [2026-09-22]

### Hinzugefügt

- Konsistenzprüfung in `HK-Skript 1_ChurchTools`: warnt im Log, wenn benötigte
  Systemvariablen fehlen (nur Warnung, kein Abbruch).
- Test-Tools für Raumvariablen (`Tools/`): auslesen, einzelnes Feld setzen, alle
  `HKG-Raum-*` als Markdown-Tabelle ausgeben.
- `DUP:`- und `DIVERGENZ:`-Marker an bekannten Code-Dubletten bzw. Unterschieden
  der Skript-1-Varianten (reine Dokumentation).

### Geändert

- Logging in `HK-Skript 2`: Meldungen im Ausschalt-Block erhalten den
  Raumname-Präfix, konsistent zu den übrigen Schaltmeldungen.

### Behoben

- Header-Versionskorrektur `HK-Skript 2`: `HKP-S2-3.2.1` → `3.3.1`.
- Tippfehler- und Label-Korrekturen im `HK-Test-Skript` (u.a. `Chruchtools` →
  `Churchtools`).

## [2026-09-21]

### Hinzugefügt

- Räume ohne Temperatursensor werden in der `HK-Heizkurvenkontrolle` nicht mehr
  stumm übersprungen: Log-Eintrag im Systemprotokoll, auf einmal pro Heizphase
  begrenzt.
- Neues Tool „Log des Heizkalenders ausgeben": durchsucht die USB-Logdateien
  nach konfigurierbarem Suchbegriff und gibt die letzten Einträge aus.

### Geändert

- Logging in `HK-Skript 2` um Raumnamen erweitert; AT/GT/IST-Zeile mit
  Bezeichnung, °C und einheitlichen Nachkommastellen.
- Robustheit in `HK-Außentemperatur-Open-Meteo`: `pos<0`-Prüfungen nach den
  `Find()`-Aufrufen, redundante Konversionen entfernt.

### Behoben

- Nachtschaltung in `HK-Skript 2`: `objDP.State(0)` schrieb versehentlich den
  Wert AUS und lieferte zugleich `true` zurück. Fix: `State(0)` → `State()` (nur
  lesen). CCU-verifiziert.
- Drei RRULE-Bugs in `HK-Skript 1_iCal`: Tippfehler `DAYLY` → `DAILY`;
  `iMaxCount=0`-Default brach ohne `COUNT=` sofort ab (Fix: Sentinel 9999);
  `UNTIL` wurde nicht gelesen (Datum nun korrekt aus RRULE geparst).
- `HK-Heizkurvenkontrolle`: `HSFlag` von `boolean` auf `string` (korrekte
  `H`/`S`/`HS`-Vergleiche); `strTemp`-Shadowing im DEBUG-Block behoben.
- Init-Skripte: `iPos>=0`-Guard vor `Substr` (ChurchTools); `color`-Guard
  `iPos>=0` statt `iPos&&` (ChurchDesk — verfehlte sonst Position 0 und -1).
- Nullpointer-Zugriff im Installer (`ScriptEngine`): Verbindungskontext wird vor
  dem Nullsetzen gesichert.
- Fehlerprüfung beim Parsen der Raumnamen (`HK-Init-Skript 1_ChurchDesk`/
  `_ChurchTools`): geprüft wurde `iPos` statt `iPosEnd`, wodurch die
  Fehlerbehandlung nie griff.
- Kaputte Umlaute (`U+FFFD`) in `ScriptEngine.cpp`/`.h` repariert; Debug-Ausgabe
  in `HK-Heizkurvenkontrolle` deaktiviert (`DEBUG=1` → `0`).
- Rechtschreib- und Grammatikkorrekturen in Skript-Kommentaren und `Readme.md`.

## [Ältere Stände — 2025-01 bis 2026-08]

Zusammenfassung der früheren Entwicklung; Details in den Datei-Header-Changelogs
und den Git-Tags (`git tag -l`, von `v2025-01-16` bis `v2026-08-10`):

- Erststruktur des Heizkalenders mit getrennten Skript-1-Varianten (ChurchTools,
  ChurchDesk API/iCal, Google, iCal) und zentralem Schaltskript `HK-Skript 2`.
- Multi-Raum-Variante: einer Ressource lassen sich mehrere Räume zuordnen.
- „Heizen mit Schalten": Schaltliste um den Heiz-/Schalt-Parameter erweitert.
- Sonderbefehle in Termintexten (`#EIN#`, `#AUS#`, `#GT#`, `#NS#`, `#NH#`,
  `#RESET#`, `#<Zahl><Text>#`).
- RRULE-Unterstützung (Terminwiederholungen) in der iCal-Variante.
- Logging über Systemvariablen (`HK1-Log`/`HK1-Logging`, `HK2-Log`/`HK2-Logging`)
  und die Heizkurvenkontrolle im Systemprotokoll.
- Automatisches Anlegen zusätzlicher Räume und Übernahme der Ressourcen-
  Klartextnamen in die `HK1-R-Liste`.
