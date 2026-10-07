!// Test: Homematic-Heizgruppe und Einzelthermostate auslesen
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
!// TT:  2026-10-03 Einzelthermostate (HmIP-eTRV-2) zusätzlich zur Heizgruppe auslesen
!// TT:  2026-10-03 Erstellt: Heizgruppe (HmIP-HEATING) Datenpunkte auslesen

!// Adresse der Heizgruppe (Kanal 1)
string GruppenName = "EG-Eltern-Kind-Raum INT0000001:1";

!// Adressen der einzelnen HmIP-eTRV-2 Thermostate in der Gruppe (Kanal 1)
string Thermostat1 = "00395F29AA8AD7:1";
string Thermostat2 = "00395F29AB6773:1";

!//#######---Ende Variabler Bereich---#############################################################

object objAktor;
object objDP;
object devObj;
object chanObj;
integer tIdx;
integer mode;
string AktorName;
string batText;
string suchAddr;
string suchKanal;
string gefunden;
string devId;
string chanId;
string modeText;

!//===========================================================================
!// Heizgruppe auslesen
!//===========================================================================
WriteLine("___________________________________________________________________________");
WriteLine("Heizgruppe: " # GruppenName);
WriteLine("___________________________________________________________________________");

objAktor = dom.GetObject(GruppenName);
if (!objAktor) {
  WriteLine("FEHLER: Heizgruppe \"" # GruppenName # "\" nicht gefunden!");
} else {
  WriteLine("Name: " # objAktor.Name());
  WriteLine("");

  !// Solltemperatur
  objDP = objAktor.DPByHssDP("SET_POINT_TEMPERATURE");
  if (objDP) { WriteLine("SET_POINT_TEMPERATURE (Soll):  " # objDP.State().ToFloat().ToString(1) # " °C"); }
  else       { WriteLine("SET_POINT_TEMPERATURE:         nicht vorhanden"); }

  !// Isttemperatur
  objDP = objAktor.DPByHssDP("ACTUAL_TEMPERATURE");
  if (objDP) { WriteLine("ACTUAL_TEMPERATURE (Ist):      " # objDP.State().ToFloat().ToString(1) # " °C"); }
  else       { WriteLine("ACTUAL_TEMPERATURE:            nicht vorhanden"); }

  !// Luftfeuchte (nur bei Geraeten mit Sensor)
  objDP = objAktor.DPByHssDP("HUMIDITY");
  if (objDP) { WriteLine("HUMIDITY (Luftfeuchte):        " # objDP.State().ToInteger().ToString() # " %"); }

  !// Steuermodus: 0=Auto, 1=Manuell, 2=Urlaub
  objDP = objAktor.DPByHssDP("CONTROL_MODE");
  if (objDP) {
    mode = objDP.State().ToInteger();
    modeText = "unbekannt";
    if (mode==0)      { modeText = "Auto (Wochenprogramm)"; }
    elseif (mode==1)  { modeText = "Manuell (Heizkalender-Modus)"; }
    elseif (mode==2)  { modeText = "Urlaub"; }
    WriteLine("CONTROL_MODE (Modus):          " # mode.ToString() # " = " # modeText);
  }
  else { WriteLine("CONTROL_MODE:                  nicht vorhanden"); }

  !// Ventilstellung (Durchschnitt der Gruppe)
  objDP = objAktor.DPByHssDP("LEVEL");
  if (objDP) { WriteLine("LEVEL (Ventilstellung):        " # (objDP.State().ToFloat()*100.0).ToString(0) # " %"); }

  !// SET_POINT_MODE
  objDP = objAktor.DPByHssDP("SET_POINT_MODE");
  if (objDP) { WriteLine("SET_POINT_MODE:                " # objDP.State().ToInteger().ToString()); }
}

!//===========================================================================
!// Einzelthermostate auslesen
!// Zugriff per CCU-internem Namen: HmIP-RF.<Seriennummer>:<Kanal>
!//===========================================================================
tIdx = 1;
while (tIdx <= 2) {
  if (tIdx==1) { AktorName = Thermostat1; }
  else         { AktorName = Thermostat2; }

  WriteLine("");
  WriteLine("___________________________________________________________________________");
  WriteLine("Thermostat " # tIdx.ToString() # ": " # AktorName);
  WriteLine("___________________________________________________________________________");

  !// Suche nach Kanal mit passender Adresse (Seriennummer ohne Interface-Praefix)
  suchAddr = AktorName.StrValueByIndex(":",0);
  suchKanal = AktorName.StrValueByIndex(":",1);
  gefunden = "";
  foreach(devId, dom.GetObject(ID_DEVICES).EnumIDs()) {
    devObj = dom.GetObject(devId);
    if (!devObj) { continue; }
    if (devObj.Address().EndsWith(suchAddr)) {
      gefunden = devObj.Name() # " (Adresse: " # devObj.Address() # ")";
      foreach(chanId, devObj.Channels().EnumIDs()) {
        chanObj = dom.GetObject(chanId);
        if (!chanObj) { continue; }
        if (chanObj.Address().EndsWith(suchAddr # ":" # suchKanal)) {
          objAktor = chanObj;
          break;
        }
      }
      break;
    }
  }
  if (!objAktor) {
    WriteLine("FEHLER: Thermostat \"" # AktorName # "\" nicht gefunden!");
    if (gefunden != "") { WriteLine("Geraet gefunden aber Kanal nicht: " # gefunden); }
    tIdx = tIdx + 1;
    continue;
  }
  WriteLine("Name: " # objAktor.Name() # " (intern: " # objAktor.Address() # ")");
  WriteLine("");

  !// Solltemperatur
  objDP = objAktor.DPByHssDP("SET_POINT_TEMPERATURE");
  if (objDP) { WriteLine("SET_POINT_TEMPERATURE (Soll):  " # objDP.State().ToFloat().ToString(1) # " °C"); }
  else       { WriteLine("SET_POINT_TEMPERATURE:         nicht vorhanden"); }

  !// Isttemperatur
  objDP = objAktor.DPByHssDP("ACTUAL_TEMPERATURE");
  if (objDP) { WriteLine("ACTUAL_TEMPERATURE (Ist):      " # objDP.State().ToFloat().ToString(1) # " °C"); }
  else       { WriteLine("ACTUAL_TEMPERATURE:            nicht vorhanden"); }

  !// Luftfeuchte (HmIP-eTRV-2 hat keinen Sensor, trotzdem prüfen)
  objDP = objAktor.DPByHssDP("HUMIDITY");
  if (objDP) { WriteLine("HUMIDITY (Luftfeuchte):        " # objDP.State().ToInteger().ToString() # " %"); }

  !// Steuermodus: 0=Auto, 1=Manuell, 2=Urlaub
  objDP = objAktor.DPByHssDP("CONTROL_MODE");
  if (objDP) {
    mode = objDP.State().ToInteger();
    modeText = "unbekannt";
    if (mode==0)      { modeText = "Auto (Wochenprogramm)"; }
    elseif (mode==1)  { modeText = "Manuell (Heizkalender-Modus)"; }
    elseif (mode==2)  { modeText = "Urlaub"; }
    WriteLine("CONTROL_MODE (Modus):          " # mode.ToString() # " = " # modeText);
  }
  else { WriteLine("CONTROL_MODE:                  nicht vorhanden"); }

  !// SET_POINT_MODE (tatsaechlicher Geraetezustand, 1=Manuell fuer Heizkalender noetig)
  objDP = objAktor.DPByHssDP("SET_POINT_MODE");
  if (objDP) {
    mode = objDP.State().ToInteger();
    modeText = "unbekannt";
    if (mode==0)      { modeText = "Auto"; }
    elseif (mode==1)  { modeText = "Manuell (fuer Heizkalender korrekt)"; }
    elseif (mode==2)  { modeText = "Urlaub"; }
    WriteLine("SET_POINT_MODE (Zustand):      " # mode.ToString() # " = " # modeText);
  }

  !// Ventilstellung
  objDP = objAktor.DPByHssDP("VALVE_STATE");
  if (objDP) { WriteLine("VALVE_STATE (Ventilstellung):  " # objDP.State().ToInteger().ToString() # " %"); }
  else {
    objDP = objAktor.DPByHssDP("LEVEL");
    if (objDP) { WriteLine("LEVEL (Ventilstellung):        " # (objDP.State().ToFloat()*100.0).ToString(0) # " %"); }
    else       { WriteLine("VALVE_STATE/LEVEL:             nicht vorhanden"); }
  }

  !// Batteriestatus und RSSI (meist auf Kanal 0, nicht Kanal 1)
  !// Kanal 0 desselben Geraets per Suche finden
  chanObj = "";
  foreach(devId, dom.GetObject(ID_DEVICES).EnumIDs()) {
    devObj = dom.GetObject(devId);
    if (!devObj) { continue; }
    if (devObj.Address().EndsWith(suchAddr)) {
      foreach(chanId, devObj.Channels().EnumIDs()) {
        chanObj = dom.GetObject(chanId);
        if (chanObj && chanObj.Address().EndsWith(suchAddr # ":0")) { break; }
        chanObj = "";
      }
      break;
    }
  }
  objDP = objAktor.DPByHssDP("LOW_BAT");
  if (!objDP && chanObj) { objDP = chanObj.DPByHssDP("LOW_BAT"); }
  if (objDP) {
    batText = "OK";
    if (objDP.State()) { batText = "NIEDRIG!"; }
    WriteLine("LOW_BAT (Batterie):            " # batText);
  } else { WriteLine("LOW_BAT:                       nicht vorhanden"); }

  objDP = objAktor.DPByHssDP("RSSI_DEVICE");
  if (!objDP && chanObj) { objDP = chanObj.DPByHssDP("RSSI_DEVICE"); }
  if (objDP) { WriteLine("RSSI_DEVICE (Empfang):         " # objDP.State().ToInteger().ToString() # " dBm"); }
  else       { WriteLine("RSSI_DEVICE:                   nicht vorhanden"); }

  tIdx = tIdx + 1;
}

WriteLine("");
WriteLine("___________________________________________________________________________");
WriteLine("Fertig.");
