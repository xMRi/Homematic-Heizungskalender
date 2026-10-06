!// Einzelthermostate einer HmIP-Heizgruppe direkt auf Manuell- oder Auto-Modus setzen
!//================================================================================================
!// Stand:    05.10.2026
!// Autor:    Thomas Tatzel
!// Projekt:  Helmut Diedrichs  (helmut@diedrichs.de) https://diedrichs.de
!//------------------------------------------------------------------------------------------------
!// Copyright (C) 2026 Thomas Tatzel
!// Dieser Teil des Heizkalenders ist freie Software und wird unter der GNU General Public License
!// Version 3 (GPLv3) oder neuer veröffentlicht.
!// Es besteht keinerlei Garantie oder Haftung. Nutzung auf eigene Verantwortung.
!//================================================================================================
!//
!// Sonderfall-Tool: setzt CONTROL_MODE direkt auf den HmIP-eTRV-Einzelthermostaten,
!// nicht auf der Gruppenadresse.
!//
!// Hintergrund: Im Normalfall uebertraegt die HmIP-HEATING-Heizgruppe ihren Modus automatisch
!// auf alle zugehoerigen Thermostate. In seltenen Faellen (z.B. nach einem Firmware-Update)
!// kann ein Thermostat den Gruppenmodus nicht uebernehmen. Dieses Skript korrigiert das,
!// indem es CONTROL_MODE direkt auf allen HmIP-eTRV-Geraeten setzt.
!//
!// Normaler Betrieb: Verwende stattdessen "Tool-Heizgruppen Modus zuruecksetzen.hsc", das
!// nur die Gruppenadresse beschreibt.
!//
!// TT:  2026-10-05 Neu: Sonderfall Einzelthermostat-Modus nach Firmware-Update
!//================================================================================================
!//
!// Konfiguration:
!// automode=true  -> setzt alle eTRV auf Auto-Modus   (CONTROL_MODE=0)
!// automode=false -> setzt alle eTRV auf Manuell-Modus (CONTROL_MODE=1)

string vrp="";

!// true = Auto-Modus (CONTROL_MODE=0), false = Manuell-Modus (CONTROL_MODE=1)
boolean automode                = false;
!// Debug Ausgabe ein oder aus
boolean debug                   = false;

!// Logging in "Log" mit 1 zwingend einschalten oder mit -1 zwingend Ausschalten
!// Mit 0 wird die Einstellung aus der HKx-Logging uebernommen
integer log=0;

!//#######---Ende Variabler Bereich---#############################################################
!//Im Folgenden Hier keine Veraenderungen vornehmen!

integer tvstate;

var logObj=dom.GetObject(vrp+"HK-Log");
var loggingObj=dom.GetObject(vrp+"HK-Logging");

!// Prüfe ob logging erwartet wird
if (log<0) {
  log = false;
} elseif (log==0) {
  if (loggingObj && loggingObj.State()){
    log = true;
  }
} else {
  log = true;
}

!// Logging zwingend ausschalten, wenn keine Variable vorhanden ist
if (!logObj){
  log = false;
}

!// Ausführung: ab hier nichts mehr verändern

if(debug){WriteLine("Automode:"#automode);}
string deviceid;
foreach(deviceid, dom.GetObject(ID_DEVICES).EnumUsedIDs())
{
  var device = dom.GetObject(deviceid);
  if(debug){WriteLine("Device:"#device#" HssType="#device.HssType()#" (id:"#deviceid#")");}

  if(device.HssType().StartsWith("HmIP-eTRV"))
  {
    string tvchanid;
    foreach(tvchanid, device.Channels().EnumUsedIDs())
    {
      var tvchan = dom.GetObject(tvchanid);
      if(debug){WriteLine("\t eTRV Channel:"#tvchan#" HssType="#tvchan.HssType()#" (id:"#tvchanid#")");}
      if("HEATING_CLIMATECONTROL_TRANSCEIVER" == tvchan.HssType())
      {
        var     tviface  = dom.GetObject(tvchan.Interface());
        var     tvdp     = tviface # "." # tvchan.Address();
        if(debug){WriteLine("\t  Datapoint:"#tvdp);}
        !// SET_POINT_MODE wird erst nach dem naechsten Funk-Zyklus des eTRV aktualisiert.
        !// Der angezeigte Wert kann daher noch den Zustand vor dem letzten Schreibbefehl zeigen.
        tvstate = dom.GetObject(tvdp # ".SET_POINT_MODE").Value();
        if(debug){WriteLine("\t  SET_POINT_MODE=" # tvstate # " automode=" # automode);}
        if(!automode && 1!=tvstate)
        {
          dom.GetObject(tvdp # ".CONTROL_MODE").State(1);
          if(debug){WriteLine("\t  Einzelthermostat: Befehl Manuell gesendet");}
          if(log){logObj.State("Moduskorrektur Einzelthermostat:" # device # " Befehl \"Manuell\" gesendet");}
        }
        elseif(automode && 0!=tvstate)
        {
          dom.GetObject(tvdp # ".CONTROL_MODE").State(0);
          if(debug){WriteLine("\t  Einzelthermostat: Befehl Auto gesendet");}
          if(log){logObj.State("Moduskorrektur Einzelthermostat:" # device # " Befehl \"Auto\" gesendet");}
        }
        break;
      }
    }
  }
}
