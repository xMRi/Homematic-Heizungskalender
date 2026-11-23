# Gezielte Monats-/Wochenkorrektur

Die aktive Prüfung betrifft ausschließlich den kleinen Patch auf Upstream `183a7a40`. Die frühere umfassende Engine und ihre Tests sind lokal unter `build/r04-minimal-sicherung-2026-11-22-*` gesichert. Frühere CCU-Protokolle prüfen diese neue Fassung nicht.

Für den Quellvergleich wird Git und der öffentlich verfügbare Upstream-Commit `183a7a40` in der Repository-Historie benötigt. Ein flacher Checkout ohne diesen Commit muss vor der Prüfung um die benötigte Historie ergänzt werden; private Stashes oder Hilfsdateien sind nicht erforderlich.

```sh
python3 Tests/Skript1_iCal-Wiederholungen/test_reference.py
```

Die stdlib-Referenzrechnung prüft Monatspositionen aller Wochentage, fehlende fünfte Positionen, Dezember/Januar, COUNT auf gültigen Kandidaten, inklusive UNTIL und Wochenintervalle. Zusätzlich werden unveränderte Datums-/RRULE-Parserbereiche direkt mit Upstream verglichen, Änderungen auf die beauftragten Stellen beschränkt und Klammern geprüft. Dies ist keine HSC-Ausführung.

`build/isolated-parser.hsc` wird aus der tatsächlichen produktiven RRULE-Schleife generiert und nicht versioniert. Nur konstante Eingaben, keine Systemvariablen, Aktoren oder HTTP-Aufrufe. Erwartung: zweiter Montag 09.02.2026 10:00 Uhr, Treffer und COUNT 1. Ausführung auf einer CCU benötigt eigene Freigabe und wurde nicht vorgenommen. `versatzGMT=3600` ist ein fester Testwert, kein ermittelter Zonenwert. Datums-/Format- und lokale ToTime-Semantik bleiben CCU-Abnahmeannahmen.

Nur der bisher lokale TZID-Pfad erhält den Kalenderfortschritt. UTC/Floating und deren bisherige Umrechnung mit aktuellem GMT-Versatz bleiben unverändert, einschließlich bekannter fachlicher Abweichungen. Die Regressionstests prüfen dort ausschließlich Unverändertheit, keine RFC-Korrektheit. WKST, unbekannte Schlüssel, DATE, DURATION, ungültige Intervalle, ursprüngliche Zähl-/Startgrenzen, allgemeine Monats-/Jahresfortschritte und mehrdeutige lokale Uhrzeiten werden nicht neu korrigiert. Die vorhandenen DST-gap/fold-Fixtures bleiben reine offene Testeingaben ohne verbindlichen Epoch-Sollwert.
