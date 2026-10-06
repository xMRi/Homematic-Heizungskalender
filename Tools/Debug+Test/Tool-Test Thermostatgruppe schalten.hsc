!// Test: Homematic-Heizgruppe direkt schalten und Datenpunkt auslesen
!//================================================================================================
!// Stand:    03.10.2026
!// Autor:    Thomas Tatzel
!// Projekt:  Helmut Diedrichs  (helmut@diedrichs.de) https://diedrichs.de
!//------------------------------------------------------------------------------------------------
!// Copyright (C) 2026 Martin Richter (xMRi-Software)
!// Dieser Teil des Heizkalenders ist freie Software und wird unter der GNU General Public License
!// Version 3 (GPLv3) oder neuer veröffentlicht.
!// Es besteht keinerlei Garantie oder Haftung. Nutzung auf eigene Verantwortung.
!//================================================================================================
!//
!// Skript zum direkten Testen einer Homematic-Heizgruppe (HmIP-HEATING), unabhaengig
!// vom Heizkalender. Liest den aktuellen Solltemperatur-Datenpunkt aus, schreibt
!// eine neue Solltemperatur und liest danach nochmals aus.
!//
!// Aktor-Adresse und Zieltemperatur im variablen Bereich anpassen.

!// Adresse der Heizgruppe (Kanal 1), z.B. "EG-Eltern-Kind-Raum INT0000001:1"
string AktorName = "EG-Eltern-Kind-Raum INT0000001:1";

!// Zieltemperatur zum Einschalten (Wohlfuehltemperatur)
real TempEin = 21.0;

!// Grundtemperatur zum Ausschalten (0.0 = nur lesen, nicht schalten)
!// Auf 0.0 setzen um nur den aktuellen Wert auszulesen ohne zu schalten
real TempAus = 0.0;

!//#######---Ende Variabler Bereich---#############################################################

string Param = "SET_POINT_TEMPERATURE";

WriteLine("___________________________________________________________________________");
WriteLine("Test Thermostatgruppe: " # AktorName);
WriteLine("Datenpunkt:            " # Param);
WriteLine("___________________________________________________________________________");

object objAktor = dom.GetObject(AktorName);
if (!objAktor) {
  WriteLine("FEHLER: Aktor \"" # AktorName # "\" nicht gefunden!");
  quit;
}
WriteLine("Aktor gefunden: " # objAktor.Name());

object objDP = objAktor.DPByHssDP(Param);
if (!objDP) {
  WriteLine("FEHLER: Datenpunkt \"" # Param # "\" nicht vorhanden!");
  quit;
}

real IstVorher = objDP.State().ToFloat();
WriteLine("SET_POINT_TEMPERATURE vorher: " # IstVorher.ToString(1) # " °C");

if (TempEin > 0.0) {
  objDP.State(TempEin);
  WriteLine("Schreibe Solltemperatur:      " # TempEin.ToString(1) # " °C");

  real IstNachher = objDP.State().ToFloat();
  WriteLine("SET_POINT_TEMPERATURE nachher: " # IstNachher.ToString(1) # " °C");

  if (IstNachher == TempEin) {
    WriteLine("OK: Wert sofort bestaetigt.");
  } else {
    WriteLine("Hinweis: Ruecklesewert noch " # IstNachher.ToString(1) # " °C - bei Funk-Geraeten normal (CCU sendet asynchron).");
    WriteLine("Bitte Solltemperatur am Thermostat-Display pruefen.");
  }
}

if (TempAus > 0.0) {
  WriteLine("___________________________________________________________________________");
  WriteLine("Rueckstellung auf: " # TempAus.ToString(1) # " °C");
  objDP.State(TempAus);
  WriteLine("SET_POINT_TEMPERATURE nach Rueckstellung: " # objDP.State().ToFloat().ToString(1) # " °C");
}

WriteLine("___________________________________________________________________________");
WriteLine("Fertig.");
