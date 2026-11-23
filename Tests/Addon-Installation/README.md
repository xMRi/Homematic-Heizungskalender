# Addon: Paketbau und Installationsfehler

Vom Projektstamm aus:

```sh
sh -n Addon/build.sh && sh -n Addon/src/update_script
python3 Tests/Addon-Installation/test_installation.py
git diff --check -- Addon/build.sh Addon/src/update_script Tests/Addon-Installation/
```

Die Prüfung verwendet ausschließlich frisch angelegte `build/addon-installation-test-*`-Bereiche. Installationsziele werden in einer Kopie des Skripts ersetzt. Mount, Logger und Sync sind vollständig simuliert; die Dateibefehle werden aufgezeichnet und gezielt mit Fehlern belegt. Es erfolgen keine CCU-Zugriffe und keine Schreibzugriffe auf reale `/usr/local`-Ziele.

Geprüft werden:

- Erfolgreiche Installation ohne vorhandene rc.d-Datei und Updates mit leerem Webverzeichnis oder bestehendem Symlink: immer Exit 0, vollständige Dateien, Rechte, korrektes Linkziel, alte eigene Webdateien entfernt.
- Jeder Aufruf von mkdir, chmod, cp sowie rm, ln, readlink, sync und beide Mount-Aufrufe mit Fehler: Exit 1 und `logger -t heizkalender-addon` mit `Installation fehlgeschlagen:`.
- Erfolgreicher ln-Aufruf mit falschem Linkziel wird nicht als Erfolg gewertet.
- Fremdes nichtleeres Webverzeichnis bleibt erhalten; Fehler beim Entfernen eines leeren Verzeichnisses wird erkannt.
- Web-Kopierfehler nach Entfernen der alten eigenen Webdateien: bewusst kein Rollback, Fehlermeldung mit Hinweis auf manuelle Reparatur.
- Echter Paketbau aus aktuellen Quellen sowie isolierter Paketbau mit macOS-Metadaten, fremdem Verzeichnis-Symlink und shasum-Fallback. Alle tatsächlich archivierten regulären Dateien sind im sortierten Manifest enthalten, das Manifest nicht in sich selbst oder dauerhaft in src.
- Hashprüfung des entpackten Pakets erfolgreich; manipulierte und fehlende VERSION abgewiesen. GNU sha256sum verwendet `-sc`, auf macOS wird bei fehlendem Statusschalter die gleichwertige Prüfung `shasum -a 256 -sc` verwendet.

Das echte Paket bleibt unter `Addon/build/`. Die isolierten Testbereiche werden ausschließlich nach Prüfung von Elternverzeichnis, Präfix und Symlinkstatus entfernt. Dies ist kein CCU-Laufzeittest und kein Original-CCU3-Integritätsnachweis: OpenCCU prüft das Manifest vor update_script; update_script enthält bewusst keine zusätzliche Hashprüfung. Fehlgeschlagene Live-Kopien benötigen die vom Nutzer akzeptierte manuelle Wiederherstellung.
