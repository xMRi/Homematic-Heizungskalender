# Updates

Neue Skriptstände können zusätzliche Systemvariablen oder besondere Updateskripte benötigen. Beachten Sie vor dem Update die Hinweise zum jeweiligen Stand: Pflichtvariablen müssen vorhanden sein; optionale Variablen werden nur für die beschriebenen Zusatzfunktionen benötigt.

Die Heizskripte tragen einen Datumsstand im Dateiheader. Verwenden Sie die Skripte eines kompatiblen Release-Standes gemeinsam. Das Addon besitzt dagegen eine eigenständige Versionsnummer in `Addon/src/VERSION`; diese ist nicht mit dem Skriptdatum gleichzusetzen.

Sichern Sie vor Änderungen die CCU-Konfiguration und notieren Sie individuelle Einstellungen.

## Updates über `HeizkalenderInstallation.exe`

Der Installer aktualisiert die unterstützten Skripte, Systemvariablen und Programme anhand seiner einkompilierten Metaskripte. Die separat gepflegten manuellen Init-Skripte sind nicht seine Datenquelle. Prüfen Sie daher, ob der verwendete Installerstand die benötigten Anpassungen bereits enthält. Siehe [Installer-Anleitung](../heizkalender-installation/readme.md).

## Manuelle Updates

Prüfen Sie die zum Zielstand gehörenden Skripte und Einrichtungshinweise. Führen Sie erforderliche Init-Skripte gezielt aus, etwa `HK-Init-Skript 2+3.hsc`, das Init-Skript der gewählten Kalenderquelle oder `HK-Init-Variablen Logging.hsc`.

`HK-Init-Skript 2+3.hsc` legt fehlende Variablen an und lässt bereits vorhandene Objekte unverändert. Es korrigiert damit keine bestehenden falschen Typen oder Werte. Prüfen Sie vor der Ausführung insbesondere den konfigurierten Präfix und die Variablennamen; eine pauschale Zusage gefahrloser Ausführung gilt nicht.

Die optionale Wetterabrufzeitvariable kann manuell eingerichtet werden, siehe [Abrufzeit einrichten](../skripte/readme.md#hk2-aussentemperatur-abrufzeit). Ihr Fehlen verhindert die normale Heizberechnung nicht.

## Anmerkungen zu speziellen Versionen

Die folgenden Anmerkungen betreffen ältere Versionen der Heizkalender Software:

### Softwarestand vor dem [2026-11-08]

Mit diesem Stand wurde die Anpassung der Vorheizzeit an Ist- und Zieltemperatur geändert. Der damalige Updatehinweis nannte für ältere Stände eine bis zu 35 Prozent längere Vorheizzeit; das ist keine allgemeine Zusage für heutige Berechnungen.

Nach einem solchen Wechsel kann eine Überprüfung der raumbezogenen Vorheizzeiten, Faktoren und `HK2-Kurve` nötig sein. Beobachten Sie die tatsächlichen Heizvorgänge, statt die Parameter pauschal zu erhöhen. Die aktuelle Berechnung einschließlich Mindestvorlaufzeit beschreibt die [Vorheizzeit-Dokumentation](heizsteuerung-vorheizzeit.md).
