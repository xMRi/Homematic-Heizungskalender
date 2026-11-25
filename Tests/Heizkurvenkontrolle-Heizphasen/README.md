# Heizphasen der Heizkurvenkontrolle

Vom Projektstamm ausführen:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 Tests/Heizkurvenkontrolle-Heizphasen/test_heizphasen.py
git diff --check -- 'Skripte/HK-Heizkurvenkontrolle.hsc' Tests/Heizkurvenkontrolle-Heizphasen/
```

Die unittest-Fälle ohne zusätzliche Python-Abhängigkeiten übersetzen ausschließlich die beiden markierten neuen HSC-Blöcke in einen kleinen Python-Mock. Zeiten sind numerische Testwerte, keine echten ReGa-Zeitkonvertierungen. Die Sammlung je Raum wird als Referenzmodell geprüft und durch Quelltextprüfungen an die tatsächliche Sammlung angebunden. Speicherformat, Deklarationen, unveränderte Terminauswahl und stündlicher Logblock werden durch Quelltextprüfungen abgesichert. Die SHA256-Vergleichswerte der unveränderten Regionen stammen aus Commit `bd8a91f`; der Vergleich ignoriert ausschließlich nachgestellte Leerzeichen und Tabulatoren jeder Zeile. Der Test benötigt zur Laufzeit kein Git. Bestehende Logereignisse werden nicht als vollständiger Skriptlauf ausgeführt.

Dies ist kein ReGa- oder CCU-Laufzeittest. Es gibt keine CCU-Schreibzugriffe. Optional lädt `HEIZPHASEN_SOURCE` eine alternative lokale Quelldatei, etwa für einen Baseline-Rot-Nachweis gegen `git show bd8a91f:Skripte/HK-Heizkurvenkontrolle.hsc`.
