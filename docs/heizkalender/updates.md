# Updates

Neue Programmversionen führen evtl. zu der Einführung neuer Systemvariablen. Das bedeutet, dass die neuen Skripte nur mit diesen Variablen funktionieren können.

Das heißt, dass zur Nutzung einer neueren Programmversion und Ihrer Features, es nötig macht, dass das Anlegen neuer Systemvariablen nötig macht.

Andere Änderungen könnten auch spezielle Updates-Skripte benötigen.

Bitte lesen Sie unbedingt die Anmerkungen zu speziellen Updates, denn auch Änderungen in der Funktionsweise können Anpassungen an Ihrer Installation nötig machen.

Alle Software-Versionen werden immer durch ein Release Datum gekennzeichnet. In den Anmerkungen finden Sie also evtl. Anweisungen für *"Softwarestand vor dem yyyy-mm-dd"*.

Relevant sind entsprechend  

## Updates über `HeizkalenderInstallation.exe`

Der einfachste Weg für ein Update ist die Nutzung der `HeizkalenderInstallation.exe`. Dieses Programm führt alle Änderungen und auch das Anlegen der Systemvariablen oder Programme automatisch durch.

## Manuelle Updates

Hier müssen die neuen/geänderten Init-Skripte erneut ausgeführt werden.

Init-Skripte können ohne Gefahr neu ausgeführt werden. Änderungen am Skript-Typ1 sind selten.

Zur Sicherheit können Sie immer das `HK-Init-Skript 2+3.hsc` und das `HK-Init-Variablen Logging.hsc`ausführen.

**Kein Init-Skript überschreibt bestehende Variablen!**

## Anmerkungen zu speziellen Versionen

Die folgenden Anmerkungen betreffen ältere Versionen der Heizkalender Software:

### Softwarestand vor dem [2026-11-08]

Die Berechnung der Vorheizzeit hat sich geändert. Die Vorheizzeit wird nun exakt nach der bisher erreichten Ist- und Zieltemperatur erfolgt.

Bisher diese Vorheizzeit weniger stark geäürzt. D.h. ältere Softwareversionen berechneten eine bis zu 35% längere Vorheizzeit. 

Wenn also nun eine neue Softwareversion eingesetzt wird, kann es notwendig sein. Die Vorheizzeiten anzupassen und evtl. Raumfaktoren zu erhöhen oder im Extremfall die `HK2-Kurve`anzupassen.

