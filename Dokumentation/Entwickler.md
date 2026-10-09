# Entwickler-Dokumentation

Diese Seite richtet sich an Mitwirkende, die am Code des Heizkalenders arbeiten:
an den HomeMatic-Skripten oder am Windows-Installations-Programm.

## Architektur-Überblick

Der Heizkalender besteht aus zwei Teilen:

1. **HomeMatic-Skripte** (`.hsc`-Dateien), die direkt auf der CCU laufen.
2. **HeizkalenderInstallation**, eine Windows-MFC-Anwendung (C++/Win32) zum
   Einrichten und Aktualisieren der Skripte und Systemvariablen auf der CCU.

Die Skripte kommunizieren ausschließlich über **Systemvariablen** auf der CCU.
Der Laufzeit-Ablauf:

1. Eine **Skript-1-Variante** liest Termine aus einer externen Quelle
   (ChurchTools, ChurchDesk, iCal oder Google) und schreibt sie in die
   Systemvariable `HK1-Schaltliste`.
2. **HK-Skript 2** läuft alle 5 Minuten, liest `HK1-Schaltliste` und schaltet die
   Thermostate entsprechend.

Es wird immer nur eine Skript-1-Variante eingesetzt. Alle Skripte eines
Release-Standes gehören zusammen und müssen gemeinsam eingespielt werden.

## Skript-Syntax (HomeMatic HSC)

- Kommentarzeichen ist `!`. Für die Editor-Syntaxhervorhebung wird zusätzlich ein
  C-Kommentar gesetzt, daher die kombinierte Form `!//`.
- Stringverkettung erfolgt mit `#` statt `+`.
- `break` und `continue` werden unterstützt (CCU3/RaspberryMatic, nicht CCU2).
- Sonderbefehle in Termintexten: `#EIN#`, `#AUS#`, `#RESET#`, `#GT#`, `#NS#`,
  `#NH#`, `#<Zahl><Text>#` (siehe
  [Anwenderhandbuch](Anwenderhandbuch.md#sonderbefehle-in-terminen)).

Die Dateiendung `.hsc` ist eine bewusste Wahl (siehe
[Skripte/Readme.md](../Skripte/Readme.md)); historisch wurde `.c` verwendet.

## Build der `HeizkalenderInstallation.exe` (Windows, Visual Studio)

Das Installations-Projekt liegt in `HeizkalenderInstallation/`:

- Projektdatei: `HeizkalenderInstallation.vcxproj`
- Solution: `HeizkalenderInstallation.slnx`
- Zielplattform: Windows 10+, Win32/x64, MFC Unicode
- Konfigurationen: Debug/Release × Win32/x64

Es gibt keine Makefiles oder Build-Skripte für macOS/Linux; die `HeizkalenderInstallation.exe` ist
rein Windows-seitig.

Wichtige Klassen:

- `CPropertySheet` + `CPageBase`-Ableitungen: mehrseitiger Wizard (Connect, Räume,
  Ressourcen, Systemvariablen)
- `CScriptEngine`: führt HomeMatic-Skripte auf der CCU aus (HTTP POST)
- `CWGetEngine`: HTTP-Client (WinINet)
- `CData` / `TDataList<>`: Modell für Systemvariablen und Skripteinträge

## Versionierung

Es gibt keine Versionsnummern in den Dateinamen. Der Stand jedes Skriptes steht
als Datum im Datei-Header (`!// Stand:`). Kompatible Skripte finden sich immer in
einem GitHub-Release mit demselben Datums-Tag (`vJJJJ-MM-TT`).

Die Änderungshistorie über alle Stände hinweg steht im zentralen
[CHANGELOG.md](../CHANGELOG.md).

## Änderungs-Workflow

Wird eine `.hsc`-Datei (oder `HeizkalenderInstallation.exe`-Quelle) inhaltlich geändert, gehören dazu
immer die folgenden Schritte:

1. **Stand aktualisieren:** Datum in der `!// Stand:`-Zeile im Datei-Header auf das
   aktuelle Datum setzen.
2. **Changelog im Header fortschreiben:** Neuen `!// MRi: JJJJ-MM-TT`-Eintrag ganz
   oben in den Changelog-Block des Headers einfügen (neueste Einträge oben). Kurz
   beschreiben, *was* und *warum* geändert wurde.
3. **Zentrales [CHANGELOG.md](../CHANGELOG.md) fortschreiben:** Eintrag unter dem
   passenden Datums-Stand ergänzen (Keep-a-Changelog-Format, Kategorien
   Hinzugefügt/Geändert/Behoben/Entfernt).
4. **Dokumentation prüfen:** Neue oder umbenannte Systemvariablen müssen in der
   [Skript-Referenz](../Skripte/Dokumentation/Readme.md) erscheinen.
5. **`HeizkalenderInstallation.exe` anpassen (nur bei neuen/geänderten Systemvariablen):** Die 
   `HeizkalenderInstallation.exe`
   liest die Systemvariablen NICHT aus den `.hsc`-Dateien, sondern legt sie über
   eigene, fest einkompilierte Meta-Skripte an
   (`HeizkalenderInstallation/res/SYSVARS_Init_*.hsc` sowie `SYSVARS-Init.hsc` /
   `SYSVARS-InitValues.txt`). Wird eine neue Systemvariable eingeführt, umbenannt
   oder ihr Default geändert, muss sie dort von Hand ergänzt werden, sonst legt
   die `HeizkalenderInstallation.exe` sie nicht an.

**Konsistenz-Hinweis Systemvariablen:** Werden Variablen in den
`HK-Init-Skript 1_*.hsc` über die parallelen Arrays (`nm`/`be`/`tp`/`vl`/`vu`/`wr`/`pr`)
angelegt, muss jeder neue Eintrag in ALLEN Arrays an gleicher Index-Position
stehen. Beschreibungstexte (`be`) dürfen KEIN Semikolon enthalten, da es als
Array-Trenner interpretiert wird.
