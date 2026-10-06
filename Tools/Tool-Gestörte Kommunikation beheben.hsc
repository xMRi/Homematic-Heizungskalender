!// Gestörte Kommunikation beheben
!//================================================================================================
!// Stand:    06.10.2026
!// Autor:    Martin Richter    (heizkalender@m-ri.de) http://blog.m-ri.de/
!// Projekt:  Helmut Diedrichs  (helmut@diedrichs.de) https://diedrichs.de
!//------------------------------------------------------------------------------------------------
!// Copyright (C) 2026 Martin Richter (xMRi-Software)
!// Dieser Teil des Heizkalenders ist freie Software und wird unter der GNU General Public License
!// Version 3 (GPLv3) oder neuer veröffentlicht.
!// Es besteht keinerlei Garantie oder Haftung. Nutzung auf eigene Verantwortung.
!//================================================================================================
!//
!// Best practice: 
!//   Das Programm sollte stündlich einmal laufen.

!// MRi: 2026-10-06 Best practive ergänzt.
!// TT:  2026-10-04 Block fuer "Konfigurationsdaten stehen zur Uebertragung an" ergaenzt
!//
!//Eingabe eines Namens Präfix
!//Dies ist nur erforderlich wenn die Namensvorgabe beim erstellen den Systemvariablen geändert wurde.
!//Wird hier ein Präfix eingeben so muss dieser in allen Skripten auch angegeben werden.
string vrp="";

!//Logging in "Log" mit 1 zwingend einschalten oder mit 0 Ausschalten
boolean log=0;
!// Debug Ausgabe ein oder aus
boolean debug=false;

!//#######---Ende Variabler Bereich---#############################################################
!//Im Folgenden Hier keine Veränderungen vornehmen!

var logObj=dom.GetObject(vrp+"HK-Log");
var loggingObj=dom.GetObject(vrp+"HK-Logging");

!// Prüfe logging erwartet wird
if ((!log) && loggingObj){
  if (loggingObj.State()!=0){
    log = true;
  }
}

!// Logging auschalten, wenn keine Variable vorhanden
if (!logObj){
  log = false;
}

! HomeMatic-Script
! "KOMMUNIKATION GESTöRT" BEHEBEN
! http://www.christian-luetgens.de/homematic/hardware/funkstoerungen/servicemeldungen/Servicemeldungen.htm

string itemID;
string address;
string name;
object aldp_obj;
string channel;
string neuerLog;
string neuerLogCfg;
var x;
integer max=5;
integer maxCfg=5;

foreach(itemID, dom.GetObject(ID_DEVICES).EnumUsedIDs()) {
  address = dom.GetObject(itemID).Address();
  name = dom.GetObject(itemID).Name();
  aldp_obj = dom.GetObject("AL-" # address # ":0.UNREACH");
  if (aldp_obj) {
    !// if(debug){WriteLine("UNREACH: " # name # " = " # aldp_obj.Value());}
    if (aldp_obj.Value()) {
      !// if(debug){WriteLine("  -> Kommunikationstest wird ausgefuehrt");}
      foreach (channel, dom.GetObject(itemID).Channels().EnumUsedIDs()) {
        !// Test Lesen vom Channel
        if (max > 0) {
          if(log){
            neuerLog = "Kommunikationstest:" # name # " Objekt: " # aldp_obj # " Adresse: " # address;
            if (logObj.State()!=neuerLog){
              if(debug){WriteLine("Log: " # neuerLog);}
              logObj.State(neuerLog);
            }
          }
          x = dom.GetObject(channel).State();
          max = max - 1;
        }
      }
    }
  }
}

!// Geräte mit ausstehenden Konfigurationsdaten (CONFIG_PENDING) anstoßen
foreach(itemID, dom.GetObject(ID_DEVICES).EnumUsedIDs()) {
  address = dom.GetObject(itemID).Address();
  name = dom.GetObject(itemID).Name();
  aldp_obj = dom.GetObject("AL-" # address # ":0.CONFIG_PENDING");
  if (aldp_obj) {
    !// if(debug){WriteLine("CONFIG_PENDING: " # name # " = " # aldp_obj.Value());}
    if (aldp_obj.Value()) {
      !// if(debug){WriteLine("  -> Konfigurationsuebertragung wird angestossen");}
      foreach (channel, dom.GetObject(itemID).Channels().EnumUsedIDs()) {
        if (maxCfg > 0) {
          if(log){
            neuerLogCfg = "Konfigurationsuebertragung:" # name # " Adresse: " # address;
            if (logObj.State()!=neuerLogCfg){
              if(debug){WriteLine("Log: " # neuerLogCfg);}
              logObj.State(neuerLogCfg);
            }
          }
          x = dom.GetObject(channel).State();
          maxCfg = maxCfg - 1;
        }
      }
    }
  }
}
