!// Skript 3 für das Schalten der Heizgruppen
!//================================================================================================
!// Stand:    02.11.2026
!// Autoren:  Lukas Helduser    (Youtube: https://www.youtube.com/LukasvandeHaag)
!//           Martin Richter    (heizkalender@m-ri.de) http://blog.m-ri.de/
!// Projekt:  Helmut Diedrichs  (helmut@diedrichs.de) https://diedrichs.de
!//------------------------------------------------------------------------------------------------
!// Copyright (C) 2026 by Team Heizkalender:
!//   Lukas Helduser, Martin Richter (xMRi-Software), Helmut Diedrichs
!// Dieser Teil des Heizkalenders ist freie Software und wird unter der GNU General Public License
!// Version 3 (GPLv3) oder neuer veröffentlicht.
!// Es besteht keinerlei Garantie oder Haftung. Nutzung auf eigene Verantwortung.
!//================================================================================================
!//
!// Der Code basiert in großen Teilen auf der Datei:
!//  HKP-S2-3.3.1  Skript2 Schalten_Heizkalender V2.13.7.c
!// Der ursprüngliche Code wurde geschrieben von:
!//   Lukas Helduser (Youtube: https://www.youtube.com/LukasvandeHaag)
!// Ich (MRi) habe diesen Code dann erweitert, korrigiert und verbessert um sie an die Nutzung in
!// meiner Gemeinde anzupassen.
!//
!// Skript sollte alle 5min laufen
!//
!// MRi: 2026-11-03 Aufteilung Skript2 Termine vorbereiten, Skript 3 Schalten
!// MRi: 2026-11-02 Alte Changelogs entfernt
!// TT:  2026-10-29 AT-Guard: Klammern um !isHeizModus ergänzt — HM-Script hat keine Operatorrangfolge
!// TT:  2026-10-29 AT-Guard: Whitelist (H/HS) statt Blacklist (S) — Modus V wurde bei AT>=ATG nie geschaltet (#69)
!// TT:  2026-10-25 HK2-Schaltzeiten: Schlüssel von ResID auf Raumvariablenname (RVN) umgestellt.
!//                 Behebt falsche Vorlaufzeit-Anzeige bei Multi-Raum-Zuordnungen.
!// MRi: 2026-10-21 Zieltemperatur in Log ergänzt.
!// MRi: 2026-10-19 Neuen Modus "V" für das setzen einer Variable eingebaut
!// TT:  2026-10-19 HK2-Schaltzeiten: berechnete Vorlauf-, Nachlauf und Schaltzeiten pro Ressource;
!//                 am Ende des Skriptlaufs in Systemvariable schreiben (falls vorhanden).
!//                 Variable leeren wenn Schaltliste leer ist

!//Eingabe eines Namens Präfix
!//Dies ist nur erforderlich wenn die Namensvorgabe beim erstellen den Systemvariablen geändert wurde.
!//Wird hier ein Präfix eingeben so muss dieser in allen Skripten auch angegeben werden.
string vrp="";

!//Debug Ausgaben Ein und Aus schalten. 0 = Aus, 1 = Ein
boolean DEBUG=1;

!// Logging in "Log" mit 1 zwingend einschalten oder mit -1 zwingend Ausschalten
!// Mit 0 wird die Einstellunge aus der HKx-Logging übernommen
integer log=0;

!//#######---Ende Variabler Bereich---#############################################################
!//Im Folgenden Hier keine Veränderungen vornehmen!

!//-------------------------------------------------------------
!// Schaltparameter Varablen

!// IP- Thermostate-Aktoren-Gerätetyp (Kanal 1)
!//   BWTH_V1, BWTH_V2, TRVB_V1, TRV-C_V1, TRV, TRV-V1, TRV-V2, TRV-V3, TRV-V4, C_V2, WTH-2_V1, WTH-2_V2, WTH2_V3, WTH-BV1, WTH_V1, WT-V1
string AGFParamIP="SET_POINT_TEMPERATURE";

!// RT- Kennung Kanal Klassik-Thermostate-Aktoren-Gerätetyp (Kanal 4)
!//   HM-CC-RT-DN HM-CC-RT-DN
string AGFParamRT="SET_TEMPERATURE";

!// TC- Kennung Kanal Klassik-Thermostate-Aktoren-Gerätetyp (Kanal 2)
!//   HM-CC-TC
string AGFParamTC="SETPOINT";

!// IT- Kennung Kanal Klassik-Thermostate-Aktoren-Gerätetyp (Kanal 2)
!//   HM-TC-IT-WM-W-EU
string AGFParamIT="SET_TEMPERATURE";

!// SW- Kennung Kanal Klassik-Schalter-Aktoren-Gerätetyp (Kanal 1 bzw. 2)
!//   HM-LC-Sw1-FM HM-LC-Sw1PBU-FM, HM-LC-Sw2-FM, HM-ES-PMSw1-DR HM-LC-Sw1-PCB
!// Kennung Kanal IP-Schalter-Aktoren-Gerätetyp (Kanal 1)
!//   SW  Noch unerprobt
string AGFParamSW="STATE";

!//-------------------------------------------------------------
integer NOW=system.Date().ToTime().ToInteger();
string SListe=dom.GetObject(vrp # "HK2-Schaltliste").State();
string VarNamen=dom.GetObject(vrp # "HK2-HKG-Liste").State();
real ATG=dom.GetObject(vrp # "HK2-A.Temp.Grenze").State().ToFloat();
boolean Flag_Hand_Temp=dom.GetObject(vrp # "HK2-Hand-Temp").State();
boolean Flag_Hand_Grundtemp=dom.GetObject(vrp # "HK2-Hand-Grundtemp").State();
real AT=dom.GetObject(vrp # "HK2-Aussentemperatur").State().ToFloat();
real GTStandard=dom.GetObject(vrp # "HK2-Grundtemperatur").State().ToFloat();
real GT=GTStandard;
string AktAktor;
string AktorenListe;
object objAktor;
object objDP;
string AGF;
string AGFParam;
string Param;
integer iPos;
integer iEntry;

!// Logging vorbereiten
var logObj=dom.GetObject(vrp # "HK3-Log");
var loggingObj=dom.GetObject(vrp # "HK3-Logging");

!// Prüfe ob logging erwartet wird
if (log<0) {
  !// Zwingend kein logging
  log = false;
} elseif (log==0) {
!// Einstellung der Logging Variable prüfen
  if (loggingObj && loggingObj.State()!=0){
    log = true;
  }
} else {
  !// Logging einschalten
  log = true;
}

!// Logging zwingend ausschalten, wenn keine Variable vorhanden ist
if (!logObj){
  log = false;
}

if(log){logObj.State("Beginn Schaltskriptlauf=========================");}
WriteLine("Beginn Schaltskriptlauf");
if(SListe!=""){
  !// Log nur, wenn es auch was zu tun gibt
  !if(log) {logObj.State("Vollständige Raumliste: " # VarNamen);}
  if(DEBUG)  {WriteLine("Vollständige Raumliste: " # VarNamen);}
}

!// Beginn aussere Schleife------------------------------------------
!// Element von der Schaltliste nehmen und die dazu gehörige Raumvariablen suchen.
!// Wird die Raumvariable nicht gefunden wird der Eintrag übersprungen. Wir sammeln auch
!// alle Räume die wir Schalten. Um evtl. Räume zu finden, die noch die im Heizzustand sind
!// aber eigentlich keinen Schaltlisten Eintrag mehr haben. (Passiert wenn ein AUS Zeitpunkt
!// verpasst wird).

!// In dieser Variable sammeln wir Räume, die wie einschalten
string  RVNListeAn;

!// Schleife über die Schaltliste
string SLEintrag;
if(DEBUG){WriteLine("SListe=" # SListe);}
foreach(SLEintrag,SListe.Split("#")){
  if(DEBUG){WriteLine("SLEintrag=" # SLEintrag);}

  !// Listenelement auslesen
  !// Parameter für aktuellen Schaltvorgang. 
  string  RVN     = SLEintrag.StrValueByIndex(";",0);
  integer SDFlag  = SLEintrag.StrValueByIndex(";",4).ToInteger();
  real    RTemp   = SLEintrag.StrValueByIndex(";",5).ToFloat();
  integer EIN     = SLEintrag.StrValueByIndex(";",6).ToTime().ToInteger();
  integer AUS     = SLEintrag.StrValueByIndex(";",7).ToTime().ToInteger();

  !// Erzeuge einen Namen ohne prefixe
  string RVNName = RVN.Replace(vrp#"HKG-Raum-","");

  !// Anzeigename fürs Log. 
  string RaumLogName = RVNName;  
  if(DEBUG){WriteLine("RVN=" # RVN);}
  string RVI=dom.GetObject(RVN).State();
  if(DEBUG){WriteLine("RVI=" # RVI);}

  if(log){logObj.State(RaumLogName # " Raumvariable: " # RVN # "=" # RVI);}
  
  !// Raum Parameter bestimmen
  !// Aktoren, Heizen oder Schalten oder beides
  !// Grundtemperatur individuell bestimmen
  string HSFlag = RVI.StrValueByIndex(";",1);
  GT = RVI.StrValueByIndex(";",3).StrValueByIndex("/",1).ToFloat();
  if(GT==0){
    GT=GTStandard;
  }

  !// Schaltparameter bestimmen
  AGF = RVI.StrValueByIndex(";",2);
  AGFParam = "AGFParam"#AGF.ToUpper();
  Param = AGFParamIP;
  if (system.IsVar(AGFParam)){
    Param = system.GetVar(AGFParam);
  }
  if (HSFlag!="H"){
    Param="STATE";
  }
  
  !// DUP: AktorenListe-Block (Referenz-Implementierung). Identisch bei Z.806, Z.932
  !//      und in HK-Test-Skript.hsc. Aenderungen an allen Stellen nachziehen.
  !// AktorenListe aufbauen. Das ist alles ab der siebte Eintrag der Raumliste. Das dient dazu
  !// Die Liste für spätere Schaltvorgänge bereit zu halten. Der alte Code hat damit gerechnet
  !// Das ein Aktorname eine Mindestlänge hatte.
  iPos = 0;
  iEntry = 1;
  integer iMaxEntry=6;
  if (HSFlag=="HS"){
    !// Im Modus Heizen/Schalten ist der erste Aktor ein Thermostat, alle weitere Aktoren
    !// sind Schaltaktoren. Mit dem Thermostat können wir nichts Schalten. Es dient nur als Datenquelle.
    !// Deshalb überspringen wir das.
    iMaxEntry = iMaxEntry+1;
  }
  AktorenListe = "";
  while (iPos<RVI.Length()) {
    if (iEntry>iMaxEntry){
      AktorenListe = AktorenListe # RVI.Substr(iPos,1);
    } elseif (RVI.Substr(iPos,1)==";"){
      iEntry=iEntry+1;
    }
    iPos = iPos+1;
  }

  !// Protokolleintrag mit Zeit erzeugen
  string strTemp = " Schalten - ";    
  if (HSFlag=="H"){
    strTemp = " Heizen -"; 
  }elseif (HSFlag=="HS"){
    strTemp = " Heizen / Schalten-"; 
  } elseif (HSFlag=="V"){
    strTemp = " Variable setzen - ";
  } 
  if(log) {logObj.State(RaumLogName # strTemp # " " # EIN.ToTime().Format("%X").Substr(0,5) # "-" # AUS.ToTime().Format("%X").Substr(0,5));}
  if(DEBUG)  {WriteLine(RaumLogName # strTemp # " " # EIN.ToTime().Format("%X").Substr(0,5) # "-" # AUS.ToTime().Format("%X").Substr(0,5));}
  
  !// Dauerschaltstatus anzeigen, wenn es den gibt.
  !// 0=Aus, 1=Ein, 2=Dauer AUS, 3=Dauer EIN
  integer aktuellerSchaltZustand = RVI.StrValueByIndex(";",0).ToInteger();
  if(aktuellerSchaltZustand==0){
    if(log){logObj.State(RaumLogName # " befindet sich im Schaltzustand AUS!");}
    if(DEBUG) {WriteLine(RaumLogName # " befindet sich im Schaltzustand AUS!");}
  }elseif (aktuellerSchaltZustand==1){
    if(log){logObj.State(RaumLogName # " befindet sich im Schaltzustand EIN!");}
    if(DEBUG) {WriteLine(RaumLogName # " befindet sich im Schaltzustand EIN!");}
  }elseif(aktuellerSchaltZustand==2){
    if(log){logObj.State(RaumLogName # " befindet sich im Schaltzustand Dauer-AUS!");}
    if(DEBUG) {WriteLine(RaumLogName # " befindet sich im Schaltzustand Dauer-AUS!");}
  }elseif (aktuellerSchaltZustand==3){
    if(log){logObj.State(RaumLogName # " befindet sich im Schaltzustand Dauer-EIN!");}
    if(DEBUG) {WriteLine(RaumLogName # " befindet sich im Schaltzustand Dauer-EIN!");}
  }

  !// Verhindern dass Ausschaltpunkt vor Einschaltpunkt liegt
  if(AUS<=EIN){
    !// Durch das überspringen des Raumes hier, wird ein Raum evtl. ausgeschaltet, weil er nicht mehr
    !// als zu heizen gilt.
    if(log) {logObj.State(RaumLogName # " Einschaltzeit liegt nach Ausschaltzeit");}
    if(DEBUG)  {WriteLine(RaumLogName # " Einschaltzeit liegt nach Ausschaltzeit");}
    continue;
  }

  !// Das Schalten der Sonderbefehle erfolgt (wie das Ausschalten) nur einmal in dem Moment in dem der Schalt Zyklus den
  !// Einschaltpunkt erreicht. Der Einschaltzeitpunkt wird 160sec in Zukunft und Vergangenheit (320sec) geprüft. Damit wird
  !// ein 5min (300sec) Interval abgedeckt.
  !// Das Skript sollte alle 5m,in laufen. Der Ausschaltpunkt der Sonderbefehle hat keine Wirkung.

  !// Sonderbefehl: Ausschalten generell (Status 1/3 ==> 2)
  !// Geht nur, wenn wir heizen oder im Dauer-Ein sind.
  if(SDFlag==-1){
    if(aktuellerSchaltZustand!=2){
      if (((EIN-160)<NOW) && ((EIN+160)>NOW)){
        foreach(AktAktor,AktorenListe.Split(";")){
          objAktor = dom.GetObject(AktAktor);
          if (AktAktor && objAktor){
            if (HSFlag=="V"){
              !// VARIABLE. Hier ist der Datenpunkt identisch mit dem Aktor/Variablen-Objekt
              objDP = objAktor;
              Param="VARIABLE";
            }else{
              !// Datenpunkt bestimmen
              objDP = objAktor.DPByHssDP(Param);
            }
            if (objDP){
              if(HSFlag=="H"){
                !// HEIZEN
                objDP.State(GT);
                if(log){logObj.State(AktAktor # " - Dauerhaft ausschalten auf Temp.: " # GT.ToString(1));}
                if(DEBUG) {WriteLine(AktAktor # " - Dauerhaft ausschalten auf Temp.: " # GT.ToString(1));}
              }else{
              !// SCHALTEN/VARIABLE
                objDP.State(0);
                if(log){logObj.State(AktAktor # " - Dauerhaft ausschalten. Parameter:" # Param);}
                if(DEBUG) {WriteLine(AktAktor # " - Dauerhaft ausschalten. Parameter:" # Param);}
              }
            }else{
              if(log){logObj.State("Datenpunkt " # Param # " nicht vorhanden!");}
              if(DEBUG) {WriteLine("Datenpunkt " # Param # " nicht vorhanden!");}
            }
          }else{
            if(log){logObj.State(RaumLogName # ": " # AktAktor # " Objekt existiert nicht!");}
            if(DEBUG) {WriteLine(RaumLogName # ": " # AktAktor # " Objekt existiert nicht!");}
          }
        }
        dom.GetObject(RVN).State("2;" # RVI.Substr(2,RVI.Length()-2));
        continue;
      }
    }else{
!       if(log){logObj.State(RaumLogName # " ist dauerhaft ausgeschaltet");}
!       if(DEBUG) {WriteLine(RaumLogName # " ist dauerhaft ausgeschaltet");}
    }
  }

  !// Sonderbefehl: Einschalten generell (Status 1/2 ==> 3)
  !// Geht nur wenn wir nicht heizen, oder im Dauer-Aus sind
  if(SDFlag==-2){
    if(aktuellerSchaltZustand!=3){
      if (((EIN-160)<NOW) && ((EIN+160)>NOW)){
        foreach(AktAktor,AktorenListe.Split(";")){
          objAktor = dom.GetObject(AktAktor);
          if (AktAktor && objAktor){
            if (HSFlag=="V"){
              !// VARIABLE. Hier ist der Datenpunkt identisch mit dem Aktor/Variablen-Objekt
              objDP = objAktor;
              Param="VARIABLE";
            }else{
              !// Datenpunkt bestimmen
              objDP = objAktor.DPByHssDP(Param);
            }
            if (objDP){
              if(HSFlag=="H"){
                !// HEIZEN
                objDP.State(RTemp);
                if(log){logObj.State(AktAktor # " - Dauerhaft einschalten auf Temp.: " # RTemp.ToString(1));}
                if(DEBUG) {WriteLine(AktAktor # " - Dauerhaft einschalten auf Temp.: " # RTemp.ToString(1));}
              }else{
                !// SCHALTEN / VARIABLE
                objDP.State(1);
                if(log){logObj.State(AktAktor # " - Dauerhaft einschalten. Parameter:" # Param);}
                if(DEBUG) {WriteLine(AktAktor # " - Dauerhaft einschalten. Parameter:" # Param);}
              }
            }else{
              if(log){logObj.State("Datenpunkt " # Param # " nicht vorhanden!");}
              if(DEBUG) {WriteLine("Datenpunkt " # Param # " nicht vorhanden!");}
            }
          }else{
            if(log){logObj.State(RaumLogName # ": " # AktAktor # " Objekt existiert nicht!");}
            if(DEBUG) {WriteLine(RaumLogName # ": " # AktAktor # " Objekt existiert nicht!");}
          }
        }
        dom.GetObject(RVN).State("3;" # RVI.Substr(2,RVI.Length()-2));
        continue;
      }
    }else{
!        if(log){logObj.State(RaumLogName # " ist dauerhaft eingeschaltet");}
!        if(DEBUG) {WriteLine(RaumLogName # " ist dauerhaft eingeschaltet");}
    }
  }

  !// Sonderbefehl: Rückstellung (Status 2/3 ==> 0)
  !// Rückstellen erlauben wir nur bei Dauer-Ein, oder Dauer-Aus
  if(SDFlag==-3){
    if((aktuellerSchaltZustand==2) || (aktuellerSchaltZustand==3)){
      if (((EIN-160)<NOW) && ((EIN+160)>NOW)){
        foreach(AktAktor,AktorenListe.Split(";")){
          objAktor = dom.GetObject(AktAktor);
          if (AktAktor && objAktor){
            if (HSFlag=="V"){
              !// VARIABLE. Hier ist der Datenpunkt identisch mit dem Aktor/Variablen-Objekt
              objDP = objAktor;
              Param="VARIABLE";
            }else{
              !// Datenpunkt bestimmen
              objDP = objAktor.DPByHssDP(Param);
            }
            if (objDP){
              if(HSFlag=="H"){
                !// HEIZEN
                objDP.State(GT);
                if(log){logObj.State(AktAktor # " - Rückstellung aus dauerhafter Schaltung Ein/Aus auf Grundtemperatur: " # GT.ToString(1));}
                if(DEBUG) {WriteLine(AktAktor # " - Rückstellung aus dauerhafter Schaltung Ein/Aus auf Grundtemperatur: " # GT.ToString(1));}
              }else{
                !// SCHALTEN / VARIABLE
                objDP.State(0);
                if(log){logObj.State(AktAktor # " - Rückstellung aus dauerhafter Schaltung auf AUS. Parameter:" # Param);}
                if(DEBUG) {WriteLine(AktAktor # " - Rückstellung aus dauerhafter Schaltung auf AUS. Parameter:" # Param);}
              }
            }else{
              if(log){logObj.State("Datenpunkt " # Param # " nicht vorhanden!");}
              if(DEBUG) {WriteLine("Datenpunkt " # Param # " nicht vorhanden!");}
            }
          }else{
            if(log){logObj.State(RaumLogName # ": " # AktAktor # " Objekt existiert nicht!");}
            if(DEBUG) {WriteLine(RaumLogName # ": " # AktAktor # " Objekt existiert nicht!");}
          }
        }
        dom.GetObject(RVN).State("0;" # RVI.Substr(2,RVI.Length()-2));
        continue;
      }
    }else{
!        if(log){logObj.State(RaumLogName # " ist bereits in einem normalen Schaltzustand");}
!        if(DEBUG) {WriteLine(RaumLogName # " ist bereits in einem normalen Schaltzustand");}
    }
  }

  !//Ausschalten (Status ==> 0)
  !//Liegt der Ausschaltzeitpunkt des aktuellen Schaltlistenelement in der Vergangenheit dann Raumvariable durchgehen und Aktoren auf Grundtemp bringen WENN Heizung
  !//noch nicht ausgeschaltet ist.
  if(SDFlag>=0){
    !// Nur wenn der Ausschaltzeitpunkt erreicht wurde, schalten wir
    if(((AUS-160)<NOW) && ((AUS+160)>NOW)){
      !// Aber auch nur wenn er aktuell an ist, sonst müssen wir nicht ausschalten
      if(aktuellerSchaltZustand==1){
        foreach(AktAktor,AktorenListe.Split(";")){
          objAktor = dom.GetObject(AktAktor);
          if (AktAktor && objAktor){
            if (HSFlag=="V"){
              !// VARIABLE. Hier ist der Datenpunkt identisch mit dem Aktor/Variablen-Objekt
              objDP = objAktor;
              Param="VARIABLE";
            }else{
              !// Datenpunkt bestimmen
              objDP = objAktor.DPByHssDP(Param);
            }
            if (objDP){
              if(HSFlag=="H"){
                !// HEIZEN
                if(Flag_Hand_Temp!=false){
                  real istTemperatur = objDP.State();
                  if(istTemperatur==RTemp){
                    objDP.State(GT);
                    if(log) {logObj.State(RaumLogName # " " # AktAktor # " Ausschalten (mit Funktion Reglervorrang) - Ist: " # istTemperatur.ToString(1) # " Neu: " # GT.ToString(1) #" Parameter: " # Param);}
                    if(DEBUG)  {WriteLine(RaumLogName # " " # AktAktor # " Ausschalten (mit Funktion Reglervorrang) - Ist: " # istTemperatur.ToString(1) # " Neu: " # GT.ToString(1) #" Parameter: " # Param);}
                  }else{
                    if(log){logObj.State(RaumLogName # " " # AktAktor # " Reglervorrang bei AUS - Regler händisch verstellt auf Temp.: " # istTemperatur.ToString(1));}
                  }
                }else{
                  objDP.State(GT);
                  if(log) {logObj.State(RaumLogName # " " # AktAktor # " Ausschalten (ohne Funktion Reglervorrang) auf Temp.: " # GT.ToString(1) # " Parameter: " # Param);}
                  if(DEBUG)  {WriteLine(RaumLogName # " " # AktAktor # " Ausschalten (ohne Funktion Reglervorrang) auf Temp.: " # GT.ToString(1) # " Parameter: " # Param);}
                }
              }else{
                !// SCHALTEN / VARIABLE
                objDP.State(0);
                if(log) {logObj.State(RaumLogName # " " # AktAktor # " Ausschalten. Parameter: " # Param);}
                if(DEBUG)  {WriteLine(RaumLogName # " " # AktAktor # " Ausschalten. Parameter: " # Param);}
              }
            }else{
              if(log){logObj.State(RaumLogName # " Datenpunkt " # Param # " nicht vorhanden!");}
              if(DEBUG) {WriteLine(RaumLogName # " Datenpunkt " # Param # " nicht vorhanden!");}
            }
          }else{
            if(log){logObj.State(RaumLogName # ": " # AktAktor # " Objekt existiert nicht!");}
            if(DEBUG) {WriteLine(RaumLogName # ": " # AktAktor # " Objekt existiert nicht!");}
          }
        }
        dom.GetObject(RVN).State("0;" # RVI.Substr(2,RVI.Length()-2));
        continue;
      }
    }
  }

  !//Einschalten (Status ==> 1)
  !//Liegt der Einschaltzeitpunkt in der Vergangenheit UND Ausschaltzeitpunkt in der Zukunft Heizung einschalten WENN diese noch nicht eingeschaltet ist.
  if(SDFlag>=0){
    !// Sollte die Außentemperatur über unserem Schwellenwert liegen, Heizen wir nicht.
    !// Nur die Heizmodi (H/HS) sind temperaturabhängig — Schalten (S) und Variable (V)
    !// werden immer ausgeführt, unabhängig von der Außentemperatur.
    boolean isHeizModus = ((HSFlag=="H") || (HSFlag=="HS"));
    if((!isHeizModus) || (AT<ATG)){
      !// Und wir schalten nur ein wenn die Einschaltzeit mehr als 5min beträgt
      if(((EIN+300)<AUS) && (EIN<=NOW) && (AUS>NOW)){
        !// Da wir die Heizung einschalten, setzen wir den Raum in die Heizliste
        if (RVNListeAn.Find(RVN # ";")<0){
          RVNListeAn=RVNListeAn # RVN # ";";
        }
        !// Wir schalten aber nur, wenn er noch nicht geschaltet ist
        if(aktuellerSchaltZustand==0){
          foreach(AktAktor,AktorenListe.Split(";")){
            objAktor = dom.GetObject(AktAktor);
            if (objAktor){
              if (HSFlag=="V"){
                !// VARIABLE. Hier ist der Datenpunkt identisch mit dem Aktor/Variablen-Objekt
                objDP = objAktor;
                Param="VARIABLE";
              }else{
                !// Datenpunkt bestimmen
                objDP = objAktor.DPByHssDP(Param);
              }
              if (objDP){
                if(HSFlag=="H"){
                  !// HEIZEN
                  if(Flag_Hand_Temp!=false){
                    real istTemperatur = objDP.State();
                    if(istTemperatur==GT){
                      objDP.State(RTemp);
                      if(log) {logObj.State(AktAktor # " - Einschalten (mit Funktion Reglervorrang) - Ist: " # istTemperatur.ToString(1) # " Neu: " # RTemp.ToString(1) #" Parameter: " # Param);}
                      if(DEBUG)  {WriteLine(AktAktor # " - Einschalten (mit Funktion Reglervorrang) - Ist: " # istTemperatur.ToString(1) # " Neu: " # RTemp.ToString(1) #" Parameter: " # Param);}
                    }else{
                      if(log){logObj.State(AktAktor # " - Reglervorrang bei EIN (Regeler händisch verstellt auf Temp.: " # istTemperatur.ToString(1));}
                      if(DEBUG) {WriteLine(AktAktor # " - Reglervorrang bei EIN (Regeler händisch verstellt auf Temp.: " # istTemperatur.ToString(1));}
                    }
                  }else{
                    objDP.State(RTemp);
                    if(log) {logObj.State(AktAktor # " - Einschalten (ohne Funktion Reglervorrang) auf Temp.: " # RTemp.ToString(1) # " Parameter: " # Param);}
                    if(DEBUG)  {WriteLine(AktAktor # " - Einschalten (ohne Funktion Reglervorrang) auf Temp.: " # RTemp.ToString(1) # " Parameter: " # Param);}
                  }
                }else{
                  !// SCHALTEN / VARIABLE
                  objDP.State(1);
                  if(log) {logObj.State(AktAktor # " - Einschalten. Parameter:" # Param);}
                  if(DEBUG)  {WriteLine(AktAktor # " - Einschalten. Parameter:" # Param);}
                }
              }else{
                if(log){logObj.State("Datenpunkt " # Param # " nicht vorhanden!");}
                if(DEBUG) {WriteLine("Datenpunkt " # Param # " nicht vorhanden!");}
              }
            }else{
              if(log){logObj.State(RaumLogName # ": " # AktAktor # " Objekt existiert nicht!");}
              if(DEBUG) {WriteLine(RaumLogName # ": " # AktAktor # " Objekt existiert nicht!");}
            }
          }
          dom.GetObject(RVN).State("1;" # RVI.Substr(2,RVI.Length()-2));
          continue;
        }
      }
    }else{
        if(log){logObj.State(RaumLogName # " Heizen abgebrochen Aussentemperatur " # AT.ToString(1) # "°C größer Grenzwert " # ATG.ToString(1) # "°C");}
        if(DEBUG) {WriteLine(RaumLogName # " Heizen abgebrochen Aussentemperatur " # AT.ToString(1) # "°C größer Grenzwert " # ATG.ToString(1) # "°C");}
    }
  }
}
!// Ende äußere Schleife---------------------------------------------

!// Nachtschaltung---------------------------------------------------

!// Code für Prüfung der Nachschaltung immer zwischen 00:57 und 01:03 Uhr!
!// Die Nachtschaltung kontrolliert nur die Zustände 0,2,3. Ist noch ein normaler
!// Schaltzustand vorhanden, gehen wir davon aus, dass es einen Schaltlisten Eintrag gibt.

if((Flag_Hand_Grundtemp!=false) && (NOW.ToTime().Format("%H%M")>="0057") && (NOW.ToTime().Format("%H%M")<="0103")){
  if(log){logObj.State("Beginn Nachtabschaltung-------------------------");}
  if(DEBUG) {WriteLine("Beginn Nachtabschaltung");}

  string GepruefteGereate = ";";
  string RVNListe=VarNamen;
  RVNListe = RVNListe.Replace("+",";");
  !// Laufe über alle Räume
  foreach(RVN,RVNListe.Split(";")) {
    !// Es ist möglich, dass eine Ressource keine Zuordnung hat
    if (!RVN){
      continue;
    }

    !// Gerät evtl. schon geprüft?
    if (GepruefteGereate.Contains(";" # RVN # ";")){
      continue;
    }
	GepruefteGereate = GepruefteGereate # ";";

    !// Loggen
    RaumLogName = RVN.Replace(vrp#"HKG-Raum-","");
    if(log){logObj.State(RaumLogName # ": Nachtschaltung prüfen");}
    if(DEBUG) {WriteLine(RaumLogName # ": Nachtschaltung prüfen");}

    !// Raum Parameter bestimmen
    RVI = dom.GetObject(RVN).State();
    HSFlag = RVI.StrValueByIndex(";",1);
    AGF = RVI.StrValueByIndex(";",2);

    !// Schaltparameter bestimmen
    AGFParam = "AGFParam"#AGF.ToUpper();
    Param = AGFParamIP;
    if (system.IsVar(AGFParam)){
      Param = system.GetVar(AGFParam);
    }
    if (HSFlag!="H"){
      Param="STATE";
    }

    !// Heizung oder Schaltung in jedem Fall zurücksetzen.
    !// Wir schalten auch aus, wenn der Raum auf heizen steht. Sollten wir in einem Heizzyklus sein
    !// wird die  nächste EINSCHALTEN Prüfung wieder schalten.
    aktuellerSchaltZustand = RVI.StrValueByIndex(";",0).ToInteger();

    !// AuchSchaltzustände wie Dauer EIN und Dauer AUS werden geprüft
    !// 0=Aus, 1=Ein, 2=Dauer AUS, 3=Dauer EIN
    !// Wir stellen die Wunschtemperaturen ein.

    !// Haben wir Schaltzustand 1 (eingeschaltet), gehen wir davon aus, dass wir noch
    !// einn Schaltbefehl ausführen und lassen den Eintrag.
    if (aktuellerSchaltZustand!=1){
      !// Bestimme den passenden Zustand für 0=Aus, 2=Dauer AUS, 3=Dauer EIN
      integer sollZustand = 1;
      if ((aktuellerSchaltZustand==0) || (aktuellerSchaltZustand==3)){
        !// Grundtemperatur individuell bestimmen
        GT=RVI.StrValueByIndex(";",3).StrValueByIndex("/",1).ToFloat();
        if(GT==0){
          GT=GTStandard;
        }
        RTemp = GT;
        sollZustand = 0;
      }

      !// DUP: AktorenListe-Block, siehe Referenz oben. Aenderungen dort mitziehen.
      !// AktorenListe aufbauen.
      iPos = 0;
      iEntry = 1;
      integer iMaxEntry=6;
      if (HSFlag=="HS"){
        !// Im Modus Heizen/Schalten ist der erste Aktor ein Thermostat, alle weitere Aktoren
        !// sind Schaltaktoren. Mit dem Thermostat können wir nichts Schalten. Es dient nur als Datenquelle.
        !// Deshalb überspringen wir das.
        iMaxEntry = iMaxEntry+1;
      }
      AktorenListe = "";
      while (iPos<RVI.Length()) {
        if (iEntry>iMaxEntry){
          AktorenListe = AktorenListe # RVI.Substr(iPos,1);
        } elseif (RVI.Substr(iPos,1)==";"){
          iEntry=iEntry+1;
        }
        iPos = iPos+1;
      }

      !// Aktoren schalten
      foreach(AktAktor,AktorenListe.Split(";")){
        objAktor = dom.GetObject(AktAktor);
        if (objAktor){
          if (HSFlag=="V"){
            !// VARIABLE. Hier ist der Datenpunkt identisch mit dem Aktor/Variablen-Objekt
            objDP = objAktor;
            Param="VARIABLE";
          }else{
            !// Datenpunkt bestimmen
            objDP = objAktor.DPByHssDP(Param);
          }
          if (objDP){
            if(HSFlag=="H"){
              !// HEIZEN
              real istTemperatur = objDP.State();
              if(istTemperatur==RTemp){
                !// Heiztemperatur immer setzen. Es könnte eine Gruppe sein, die teilweise verstellt ist.
                objDP.State(RTemp);
                if(log){logObj.State(RaumLogName # ": " # AktAktor # " Nachtschaltung für \"" #
                                     ("Aus;Ein;Dauer-Aus;Dauer-Ein").StrValueByIndex(";",aktuellerSchaltZustand) #
                                     "\" bereits gesetzt auf Temp.: " # RTemp.ToString(1));}
                if(DEBUG) {WriteLine(RaumLogName # ": " # AktAktor # " Nachtschaltung für \"" #
                                     ("Aus;Ein;Dauer-Aus;Dauer-Ein").StrValueByIndex(";",aktuellerSchaltZustand) #
                                     "\" bereits gesetzt auf Temp.: " # RTemp.ToString(1));}
              }else{
                objDP.State(RTemp);
                if(log){logObj.State(RaumLogName # ": " # AktAktor # " Nachtschaltung setzen für \"" #
                        ("Aus;Ein;Dauer-Aus;Dauer-Ein").StrValueByIndex(";",aktuellerSchaltZustand) #
                        "\" - Ist: " # istTemperatur.ToString(1) # " Soll: " # RTemp.ToString(1) # " Parameter: " # Param);}
                if(DEBUG) {WriteLine(RaumLogName # ": " # AktAktor # " Nachtschaltung setzen für \"" #
                        ("Aus;Ein;Dauer-Aus;Dauer-Ein").StrValueByIndex(";",aktuellerSchaltZustand) #
                        "\" - Ist: " # istTemperatur.ToString(1) # " Soll: " # RTemp.ToString(1) # " Parameter: " # Param);}
              }
            }else{
              !// SCHALTEN / VARIABLE
              !// State() ohne Argument = Zustand lesen. State(0) würde das Relais auf AUS setzen!
              !// Auf CCU3 (HMW-IO-12-Sw7-DR) verifiziert: State(0) schaltet den Kanal aus UND
              !// liefert als Rückgabe true - der frühere Code (State(0)!=0) schaltete also aus
              !// und setzte zugleich einen falschen Ist-Zustand.
              boolean istZustand = objDP.State()!=0;
              if (istZustand!=(sollZustand!=0)){
                objDP.State(sollZustand);
                if(log){logObj.State(RaumLogName # ": " # AktAktor # " Nachtschaltung setzen für \"" #
                        ("Aus;Ein;Dauer-Aus;Dauer-Ein").StrValueByIndex(";",aktuellerSchaltZustand) #
                        "\" - Ist: " # ("aus;ein").StrValueByIndex(";",istZustand.ToInteger()) # " Soll: " # ("aus;ein").StrValueByIndex(";",sollZustand) # ". Parameter: " # Param);}
                if(DEBUG) {WriteLine(RaumLogName # ": " # AktAktor # " Nachtschaltung setzen für \"" #
                        ("Aus;Ein;Dauer-Aus;Dauer-Ein").StrValueByIndex(";",aktuellerSchaltZustand) #
                        "\" - Ist: " # ("aus;ein").StrValueByIndex(";",istZustand.ToInteger()) # " Soll: " # ("aus;ein").StrValueByIndex(";",sollZustand) # ". Parameter: " # Param);}
              }else{
                if(log){logObj.State(RaumLogName # ": " # AktAktor # " Nachtschaltung bereits korrekt: Zustand=" # ("aus;ein").StrValueByIndex(";",istZustand.ToInteger()));}
                if(DEBUG) {WriteLine(RaumLogName # ": " # AktAktor # " Nachtschaltung bereits korrekt: Zustand=" # ("aus;ein").StrValueByIndex(";",istZustand.ToInteger()));}
              }
            }
          }else{
            if(log){logObj.State(RaumLogName # ": Datenpunkt " # Param # " nicht vorhanden!");}
            if(DEBUG) {WriteLine(RaumLogName # ": Datenpunkt " # Param # " nicht vorhanden!");}
          }
        }else{
          if(log){logObj.State(RaumLogName # ": " # AktAktor # " Objekt existiert nicht!");}
          if(DEBUG) {WriteLine(RaumLogName # ": " # AktAktor # " Objekt existiert nicht!");}
        }
      }

      !// Eintrag in die geprüfte liste übernehmen
      GepruefteGereate = GepruefteGereate # RVN # ";";
    }
  }
  if(log){logObj.State("Ende Nachtabschaltung-------------------------");}
  if(DEBUG) {WriteLine("Ende Nachtabschaltung");}
}

!// Schaltlistenprüfung----------------------------------------------

!// Code für die Prüfung Schaltliste. Alle Räume, die jetzt beheizt werden müssen auch
!// in der RVNListeAn enthalten sein.
string RVNListe = VarNamen;
!// Wandle die Raumliste um, sodass auch die multiRaumVariante berücksichtigt wird
RVNListe=RVNListe.Replace("+",";");

!// Ausgabe für Schallistenprüfung
if(DEBUG) {WriteLine("RVNListeAn:" # RVNListeAn);}

!// Laufe über alle Räume und prüfe ob die sich im "An"-zustand befinden
foreach(RVN,RVNListe.Split(";")) {
  !// Es ist möglich, dass eine Ressource keine Zuordnung hat
  if (!RVN){
    continue;
  }
  !// Anzeigename fuers Log. In dieser Schleife (oberste Ebene) steht kein Ressourcen-
  !// name zur Verfuegung, daher nur der Raumname ohne Praefix.
  string RaumLogName = RVN.Replace(vrp#"HKG-Raum-","");
  !// Raum Parameter bestimmen
  RVI = dom.GetObject(RVN).State();
  HSFlag = RVI.StrValueByIndex(";",1);
  AGF = RVI.StrValueByIndex(";",2);

  !// Schaltparameter bestimmen
  AGFParam = "AGFParam"#AGF.ToUpper();
  Param = AGFParamIP;
  if (system.IsVar(AGFParam)){
    Param = system.GetVar(AGFParam);
  }
  if (HSFlag!="H"){
    Param="STATE";
  }

  !// Grundtemperatur individuell bestimmen
  GT=RVI.StrValueByIndex(";",3).StrValueByIndex("/",1).ToFloat();
  if(GT==0){
    GT=GTStandard;
  }

  !// Heizung oder Schaltung zurücksetzen, wenn diese sich immer noch im Heizen-/Schaltenzustand
  !// befindet und nicht in der Liste der beheizten/geschalteten Räume enthalten ist. Evtl. wurde
  !// ein Ausschaltpunkt versäumt oder der Termin wurde entfernt.
  aktuellerSchaltZustand = RVI.StrValueByIndex(";",0).ToInteger();
  if((RVNListeAn.Find(RVN # ";")<0) && (aktuellerSchaltZustand==1)){
    !// Reset der Heizvariablen von 1 auf 0. Da die Heizliste leer ist, sollte der Eintrag
    !// in der Raumliste auch auf 0 stehen.
    dom.GetObject(RVN).State("0;" # RVI.Substr(2,RVI.Length()-2));
    if(log){logObj.State("Kein Schaltlisten Eintrag vorhanden für " # RVN # "! Heizung/Schaltung wird ausgeschaltet!");}
    if(DEBUG) {WriteLine("Kein Schaltlisten Eintrag vorhanden für " # RVN # "! Heizung/Schaltung wird ausgeschaltet!");}

    !// DUP: AktorenListe-Block, siehe Referenz oben. Aenderungen dort mitziehen.
    !// AktorenListe aufbauen.
    iPos = 0;
    iEntry = 1;
    integer iMaxEntry=6;
    if (HSFlag=="HS"){
      !// Im Modus Heizen/Schalten ist der erste Aktor ein Thermostat, alle weitere Aktoren
      !// sind Schaltaktoren. Mit dem Thermostat können wir nichts Schalten. Es dient nur als Datenquelle.
      !// Deshalb überspringen wir das.
      iMaxEntry = iMaxEntry+1;
    }
    AktorenListe = "";
    while (iPos<RVI.Length()) {
      if (iEntry>iMaxEntry){
        AktorenListe = AktorenListe # RVI.Substr(iPos,1);
      } elseif (RVI.Substr(iPos,1)==";"){
        iEntry=iEntry+1;
      }
      iPos = iPos+1;
    }

    !// Aktoren zurücksetzen
    foreach(AktAktor,AktorenListe.Split(";")){
      objAktor = dom.GetObject(AktAktor);
      if (objAktor){
        if (HSFlag=="V"){
          !// VARIABLE. Hier ist der Datenpunkt identisch mit dem Aktor/Variablen-Objekt
          objDP = objAktor;
          Param="VARIABLE";
        }else{
          !// Datenpunkt bestimmen
          objDP = objAktor.DPByHssDP(Param);
        }
        if (objDP){
          if(HSFlag=="H"){
            !// SCHALTEN
            real istTemperatur = objDP.State();
            objDP.State(GT);
            if(log){logObj.State("Kein Schaltlisten Eintrag vorhanden für " # RVN # "- Ist: " # istTemperatur.ToString(1) # " Neu: " # GT.ToString(1) #" Parameter: " # Param);}
            if(DEBUG) {WriteLine("Kein Schaltlisten Eintrag vorhanden für " # RVN # "- Ist: " # istTemperatur.ToString(1) # " Neu: " # GT.ToString(1) #" Parameter: " # Param);}
          }else{
            !// SCHALTEN / VARIABLE
            boolean istZustand = objDP.State()!=0;
            if (istZustand)
            {
              objDP.State(0);
              if(log){logObj.State("Kein Schaltlisten Eintrag vorhanden für " # RVN # "! Schalter - " # AktAktor # " ausschalten. Parameter: " # Param);}
              if(DEBUG) {WriteLine("Kein Schaltlisten Eintrag vorhanden für " # RVN # "! Schalter - " # AktAktor # " ausschalten. Parameter: " # Param);}
            }
          }
        }else{
          if(log){logObj.State("Datenpunkt " # Param # " nicht vorhanden!");}
          if(DEBUG) {WriteLine("Datenpunkt " # Param # " nicht vorhanden!");}
        }
      }else{
        if(log){logObj.State(RaumLogName # ": " # AktAktor # " Objekt existiert nicht!");}
        if(DEBUG) {WriteLine(RaumLogName # ": " # AktAktor # " Objekt existiert nicht!");}
      }
    }
  }
}

!// -----------------------------------------------------------------

if(log){logObj.State("Ende Schaltskriptlauf=========================");}
WriteLine("Ende Schaltskriptlauf");

