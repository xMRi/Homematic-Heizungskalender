!// Servicemeldungen automatisch bestätigen
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
!//   Für die Installation des Programmes sollte folgender Trigger verwendet werden
!//     Wenn "Systemzustand" "Servicemeldungen" im Wertebereich "größer als" 0 bei Aktualisierung auslösen
!//  

!// MRi: 2026-10-06 Best practive ergänzt.

!//Eingabe eines Namens Präfix
!//Dies ist nur erforderlich wenn die Namensvorgabe beim erstellen den Systemvariablen geändert wurde.
!//Wird hier ein Präfix eingeben so muss dieser in allen Skripten auch angegeben werden.
string vrp="";

!//Logging in "Log" mit 1 zwingend einschalten oder mit 0 Ausschalten
boolean log=0;

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

if(log){
  logObj.State("Beginn Servicemeldungen automatisch bestätigen");
}

foreach(itemID, dom.GetObject(ID_DEVICES).EnumUsedIDs()) {
  address = dom.GetObject(itemID).Address();
  name = dom.GetObject(itemID).Name();
  aldp_obj = dom.GetObject("AL-" # address # ":0.STICKY_UNREACH");
  if (aldp_obj) {
    if (aldp_obj.Value()) {
      aldp_obj.AlReceipt();
      if(log){
        logObj.State("Kommunikationsstörung:" # name # " Objekt: " # aldp_obj # " Adresse: "# address);
      }
    }
  }
}

if(log){
  logObj.State("Ende Servicemeldungen automatisch bestätigen");
}

!  Ende des Scripts
