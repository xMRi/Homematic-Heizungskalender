!// Test: Homematic-Heizgruppe Datenpunkte auslesen
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
!// Liest alle relevanten Datenpunkte einer Homematic-Heizgruppe (HmIP-HEATING) aus.
!// Zeigt Solltemperatur, Isttemperatur, Modus und Ventilstellung.

!// Adresse der Heizgruppe (Kanal 1)
string AktorName = "EG-Eltern-Kind-Raum INT0000001:1";

!//#######---Ende Variabler Bereich---#############################################################

WriteLine("___________________________________________________________________________");
WriteLine("Auslesen Thermostatgruppe: " # AktorName);
WriteLine("___________________________________________________________________________");

object objAktor = dom.GetObject(AktorName);
if (!objAktor) {
  WriteLine("FEHLER: Aktor \"" # AktorName # "\" nicht gefunden!");
  quit;
}
WriteLine("Aktor gefunden: " # objAktor.Name());
WriteLine("");

string dpName;
object objDP;

!// Solltemperatur (vom Heizkalender oder Wochenprogramm geschrieben)
objDP = objAktor.DPByHssDP("SET_POINT_TEMPERATURE");
if (objDP) { WriteLine("SET_POINT_TEMPERATURE (Soll):  " # objDP.State().ToFloat().ToString(1) # " °C"); }
else       { WriteLine("SET_POINT_TEMPERATURE: nicht vorhanden"); }

!// Isttemperatur (Sensor)
objDP = objAktor.DPByHssDP("ACTUAL_TEMPERATURE");
if (objDP) { WriteLine("ACTUAL_TEMPERATURE (Ist):      " # objDP.State().ToFloat().ToString(1) # " °C"); }
else       { WriteLine("ACTUAL_TEMPERATURE: nicht vorhanden"); }

!// Steuermodus: 0=Auto, 1=Manuell, 2=Urlaub
objDP = objAktor.DPByHssDP("CONTROL_MODE");
if (objDP) {
  integer mode = objDP.State().ToInteger();
  string modeText = "unbekannt";
  if (mode==0) { modeText = "Auto (Wochenprogramm)"; }
  elseif (mode==1) { modeText = "Manuell (Heizkalender-Modus)"; }
  elseif (mode==2) { modeText = "Urlaub"; }
  WriteLine("CONTROL_MODE (Modus):          " # mode.ToString() # " = " # modeText);
}
else { WriteLine("CONTROL_MODE: nicht vorhanden"); }

!// Ventilstellung (falls verfuegbar)
objDP = objAktor.DPByHssDP("LEVEL");
if (objDP) { WriteLine("LEVEL (Ventilstellung):        " # (objDP.State().ToFloat()*100.0).ToString(0) # " %"); }

!// SET_POINT_MODE (alternativer Modus-Datenpunkt bei manchen Geraeten)
objDP = objAktor.DPByHssDP("SET_POINT_MODE");
if (objDP) { WriteLine("SET_POINT_MODE:                " # objDP.State().ToInteger().ToString()); }

WriteLine("___________________________________________________________________________");
WriteLine("Fertig.");
