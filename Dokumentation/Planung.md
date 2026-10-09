# Planung einer Heizkalender-Installation

Diese Anleitung beschreibt die konzeptionelle Vorarbeit, bevor Hardware und Software
eingerichtet werden. Sie ist unabhängig vom Betriebssystem der Zentrale und von der
Art der Installation (`HeizkalenderInstallation.exe` oder manuell).

Der Heizkalender verbindet den Online-Kalender am einen Ende mit dem einzelnen
Heizkörperthermostat am anderen Ende.

## Schritte der Planung

1. **Bestandsaufnahme der Räume:** Für jeden Raum auflisten, wie viele
   Heizkörperventile vorhanden sind. Beispielgemeinde „Musterstadt": Saal
   (Fußbodenheizung mit 10 Stellmotoren), Gruppenraum (2 Heizkörper mit
   Wandthermostat), Foyer/Flur (2 Heizkörper mit Thermostatventilen), 2 WC-Räume
   (je 1 Heizkörper mit Thermostatventil).
2. **Kalender auswerten:** Prüfen, welche Veranstaltungen regelmäßig stattfinden
   und welche Räume in welcher Kombination beheizt werden sollen.
3. **Ressourcen und Heizgruppen festlegen:** In ChurchTools und ChurchDesk werden
   im Kalender „Ressourcen" hinterlegt (bei ICS/iCal eindeutige Namen im
   Veranstaltungstitel). In Musterstadt sind das Saal und Gruppenraum, nicht aber
   Foyer/Flur und WCs. Letztere werden über „Heizgruppen" mit den Ressourcen
   verknüpft, so dass sie bei Bedarf mitgeheizt werden, ohne selbst gebucht zu sein.
   Wichtig: Bei jeder heizpflichtigen Buchung muss mindestens eine Ressource gebucht
   sein, die dann in Heizgruppen übersetzt wird.

## Nomenklatur: Aktorengruppen und Heizgruppen

In der CCU sollten die Aktoren eines Raumes in **Aktorengruppen** zusammengefasst
werden. Davon zu unterscheiden sind die **Heizkalendergruppen (HKG)** oder kurz
„Heizgruppen": In ihnen werden gleichzeitig zu beheizende Aktorengruppen oder
Einzelaktoren zusammengefasst. Eine Heizgruppe kann Aktorengruppen einschließen,
umgekehrt nicht.

> [!IMPORTANT]
> Innerhalb der CCU dürfen keine Bezeichnungen doppelt auftreten. Kanäle, Aktoren,
> Aktorengruppen, Heizgruppen, Räume und Systemvariablen brauchen jeweils klar
> unterscheidbare Namen. Eine vorher festgelegte Nomenklatur erleichtert Zuordnung,
> Installation, Bedienung und Fehlersuche.

Beispiel Musterstadt (Benennung grundsätzlich frei, nur ohne Dopplungen):

| Kalender-Ressource (ID) | Heizgruppe | Aktorengruppe | Aktor | Kanal |
| :--- | :--- | :--- | :--- | :--- |
| Saal (1) | `HKG-Saal` | Saal | Saal-FT | `Saal-FT:1` |
| Gruppenraum (2) | `HKG-Gruppenr` | Gruppenraum | Gruppenr-WT | `Gruppenr-WT:1` |
| | | | Gruppenr-HT-1 | `Gruppenr-HT-1:1` |
| | | | Gruppenr-HT-2 | `Gruppenr-HT-2:1` |
| - | `HKG-Flur` | Flur | Flur-HT-1 | `Flur-HT-1:1` |
| | | | Flur-HT-2 | `Flur-HT-2:1` |
| - | `HKG-WC` | WC_D | WC_D-HT-1 | `WC_D-HT-1:1` |
| | | WC_H | WC_H-HT-1 | `WC_H-HT-1:1` |

Ressourcen und Aktorengruppen sind hier bewusst gleich benannt, damit Raumdaten in
beiden „Welten" (Kalender und CCU) dieselbe Bezeichnung tragen. Heizgruppen tragen
den Präfix `HKG-` (bei Nutzung der Init-Skripte automatisch vorgegeben). Die Aktoren
erhalten ein Funktionskürzel (in Musterstadt: FT = Fußbodenheizungssteuergerät,
WT = Wandthermostat, HT = Heizkörperthermostat) und der Kanal wird mit Doppelpunkt
angehängt.

## Weiter geht es

- Zugangsdaten des Kalenders beschaffen: [Kalender-Zugangsdaten ermitteln](Kalender-einrichten.md)
- Danach die eigentliche Einrichtung über die
  [`HeizkalenderInstallation.exe`](../HeizkalenderInstallation/Dokumentation/Readme.md).
