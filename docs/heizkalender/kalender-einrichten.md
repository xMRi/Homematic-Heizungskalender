# Kalender-Zugangsdaten ermitteln

Diese Anleitung beschreibt, wie die Zugangsdaten des jeweiligen Kalenders beschafft
werden. Sie ist unabhängig von der Art der Installation (`HeizkalenderInstallation.exe` oder
manuell) und wird vor dem Eintragen der Daten benötigt.

Notieren Sie die Daten (z.B. im Planungsdatenblatt); Token und API-Keys speichern Sie
am besten in einer einfachen Textdatei zum späteren Einfügen.

## ChurchTools

Der Heizkalender braucht einen Benutzer mit lesendem Zugriff auf Kalender und
Ressourcen Ihrer ChurchTools-Domain.

1. **Subdomain ermitteln:** Der Teil der URL vor `.church.tools`. Bei
   `https://musterstadt.church.tools` also `musterstadt`.
2. **Benutzer anlegen:** Unter „Personen → Neue Person erstellen" einen Benutzer
   anlegen, dessen Name klar auf die Heizungssteuerung hinweist (z.B.
   „HomeMatic-Heizung"). Ein Passwort vergeben und notieren.
3. **Rechte geben:** Diesem Benutzer die Rechte zum Einsehen der Kalender und der
   Ressourcen erteilen.
4. **Login-Token holen:** Von ChurchTools abmelden, als der neue Benutzer anmelden,
   den Kontakt öffnen, unter Berechtigungen den „Login-Token" kopieren und speichern.
5. **Ressourcen ermitteln:** Unter „Raumbelegung/Ressourcen → Stammdaten" die
   Ressourcennamen und Ressourcen-IDs notieren. Musterstadt nutzt „Saal" (ID 1) und
   „Gruppenraum" (ID 2).

## ChurchDesk

Sie benötigen Ihre **OrganisationsId** sowie einen **Pull-API-Key**, den Sie vom
ChurchDesk-Support erhalten (beschrieben in der [ChurchDesk-Dokumentation](https://docs.churchdesk.com/reference/#/Churchscreen)). Beides
notieren bzw. den Key in einer Textdatei speichern.

## Google-Kalender und ICS/iCal

Die Ermittlung der Zugangsdaten (API-Key bzw. Kalender-URL) ist noch nicht
dokumentiert. Grundsätzlich gilt: Bei Google wird ein API-Key und die Kalender-ID
benötigt, bei ICS/iCal die öffentliche URL des Kalenders. In beiden Fällen muss der
Raumname mit vorangestelltem `#` eindeutig im Termintitel stehen.

Das generische iCal-Skript behält seinen vorhandenen Parser. Gezielt korrigiert werden einfache monatliche Wochentagspositionen wie `2MO` oder `-1MO`, Wochenintervalle mit BYDAY und eindeutige lokale Tages-/Wochenzeiten im vorhandenen TZID-Zweig. Ein nicht vorhandener fünfter Monatswochentag wird in diesem Zweig übersprungen. Die bestehende Monats-/Jahresfortschreibung ohne Positions-BYDAY hat weiterhin Einschränkungen bei Monatsenden und Schaltjahren.

Wöchentliche Serien ohne `BYDAY` wiederholen sich am Wochentag des Serienbeginns. Mit `BYDAY=MO,TH;INTERVAL=2` gelten Montag und Donnerstag nur in jeder zweiten Serienwoche, mit Montag als Wochenbeginn. `WKST` wird nicht zusätzlich verarbeitet.

Die bisherige Datums- und Zeitzoneninterpretation bleibt unverändert. Der lokale Kalenderfortschritt betrifft nur den vom vorhandenen Parser als lokal behandelten TZID-Zweig. UTC-/Floating-Umrechnung, fremde Zeitzonen, reine Datumswerte und weitere Parameter werden nicht durch einen neuen Parser abgesichert und bleiben eingeschränkt.

**Wichtig:** Die lokalen Prüfungen beziehen sich auf diesen kleineren Korrekturumfang. Frühere isolierte CCU-Tests der größeren Engine sind keine Abnahme dieser Fassung. Ausnahmen (`EXDATE`), zusätzliche Termine (`RDATE`), verschobene Einzeltermine (`RECURRENCE-ID`) und gefaltete Zeilen werden nicht vollständig verarbeitet. Es handelt sich nicht um vollständige iCal-Unterstützung. Den genauen Umfang, Grenzen und Prüfstand beschreibt die [Skript-Dokumentation](../skripte/readme.md#hk-skript-1_icalhsc).

## Weiter geht es

- Vorab die Struktur planen: [Planung](planung.md)
- Danach die [Einrichtung der CCU](ccu-einrichten.md)
