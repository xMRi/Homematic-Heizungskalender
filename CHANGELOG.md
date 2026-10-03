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

### Hinzugefügt

- `Tools/Tool-Test Thermostatgruppe schalten.hsc` (neu): schreibt eine Solltemperatur
  direkt auf eine Homematic-Heizgruppe (`HmIP-HEATING`) und liest den Datenpunkt
  `SET_POINT_TEMPERATURE` vorher und nachher aus.
- `Tools/Tool-Test Thermostatgruppe auslesen.hsc` (neu): liest alle relevanten
  Datenpunkte einer Heizgruppe aus (`SET_POINT_TEMPERATURE`, `ACTUAL_TEMPERATURE`,
  `CONTROL_MODE`, `LEVEL`, `SET_POINT_MODE`).

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
