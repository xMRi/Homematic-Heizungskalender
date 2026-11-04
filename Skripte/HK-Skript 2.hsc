!// Skript 2 für das berechnen der Schaltzeiten
!//================================================================================================
!// Stand:    04.11.2026
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

!// Temperaturanpassung (1=100% Berücksichtigung Ist/Soll Temperatur Differenz 0.5=50%, 0=0%)
real SollIstTemperaturAnpassung = 0.95;

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
string  OffsetAT=dom.GetObject(vrp # "HK2-Kurve").State();
integer GrundOffsetRaumAus=dom.GetObject(vrp # "HK2-VorzeitAus").State();
integer GrundOffsetRaumEin=dom.GetObject(vrp # "HK2-Kurvenversatz").State();
string TerminListe=dom.GetObject(vrp # "HK1-Schaltliste").State();
string VarNamen=dom.GetObject(vrp # "HK2-HKG-Liste").State();
string RIDI=dom.GetObject(vrp # "HK1-R-Liste").State();
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
string HK2VLZListe="";
string SchaltListeAlt=dom.GetObject(vrp # "HK2-Schaltliste").State();
string SchaltListeNeu="";
integer zeitNachlauf=30;      !// 30 Minuten



!// Logging vorbereiten
var logObj=dom.GetObject(vrp # "HK2-Log");
var loggingObj=dom.GetObject(vrp # "HK2-Logging");

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

!// Baue eine simple Namensliste aus den HK2-HKG-Liste. Wir entfernen Prefix und im multiraum Fall auch die anderen Räume
!// Aus HKG-Raum-GrSaal, wird GrSaal. Aus HKG-Foyer wird Foyer
string RIDINamen=VarNamen.Replace("HKG-Raum-","").Replace("HKG-","");

if(log){logObj.State("Beginn Berechnung der Schaltzeiten==============");}
WriteLine("Beginn Schaltskriptlauf");
if(TerminListe!=""){
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

!// Index um über die Schaltliste mit jeweils 5 Einträgen zu schleifen
integer iPos = 0;
integer iEntry = 0;
while (iPos<TerminListe.Length()) {
  if (TerminListe.Substr(iPos,1)==";"){
    iEntry=iEntry+1;
    if ((iEntry%5)==0){
      TerminListe = TerminListe.Substr(0,iPos) # "\t" # TerminListe.Substr(iPos+1,TerminListe.Length()-iPos-1);
    }
  }
  iPos = iPos+1;
}

!// Schleife über die Schaltliste
string TLEintrag;
if(DEBUG){WriteLine("TerminListe=" # TerminListe);}
if(DEBUG){WriteLine("SchaltListeAlt=" # SchaltListeAlt);}
foreach(TLEintrag,TerminListe){
  if(DEBUG){WriteLine("TLEintrag=" # TLEintrag);}
  string AktSR=TLEintrag.StrValueByIndex(";",0);
  if(DEBUG){WriteLine("AktSR=" # AktSR);}
  !// Listenelement auslesen
  !// Parameter für aktuellen Schaltvorgang. Die Parameter werden hier als Original gespeichert.
  !// Das HSFlag in der Schaltlise ist nur Informativ
  string  HSFlag      = TLEintrag.StrValueByIndex(";",4);
  integer EIN_Org     = TLEintrag.StrValueByIndex(";",1);
  integer AUS_Org     = TLEintrag.StrValueByIndex(";",2);
  integer SDFlag_Org  = TLEintrag.StrValueByIndex(";",3);

  !// Arbeitswerte bestimmen
  integer EIN     = EIN_Org.ToTime().ToInteger();
  integer AUS     = AUS_Org.ToTime().ToInteger();
  integer SDFlag  = SDFlag_Org.ToInteger();

  !// Nun suchen wir über die Ressource Id den Raum Index und den Namen. Leider hat dieser auch einen
  !// Raumname optional, das gestaltet die Suche etwas schwieriger
  !// Wenn Variable nicht gefunden innerer Schleife für diesen Durchgang beenden
  boolean bGefunden = false;
  integer raumIndex = 0;
  string AktSRName="";
  string RIDIEintrag;
  foreach(RIDIEintrag,RIDI.Split(";")){
    !// Optionalen Namen suchen (getrennt durch =)
    AktSRName = RIDIEintrag.StrValueByIndex("=",1);
    if (RIDIEintrag.StrValueByIndex("=",0)==AktSR){
      bGefunden = true;
      break;
    }
    raumIndex = raumIndex+1;
  }

  !// Dieser Code hat keine Schaltwirkung, er ist rein informativ.
  if((HSFlag=="H") || (HSFlag=="HS")){
    !// HEIZEN Sonderbefehl kontrollieren und Raumtemperatur Sonderbefehl bestimmen
    string cap;
    if (SDFlag<0){
      cap = ("AUS;EIN;NORMAL").StrValueByIndex(";",(1+SDFlag)*(-1));
    }else{
      if (SDFlag==0){
        cap = "Normaltemperatur";
      }else{
        cap = SDFlag.ToString(1);
      }
    }

    string strTemp = "Heizen: ";
    if (HSFlag=="HS"){
      strTemp = "Heizen+Schalten: ";
    }
    if(log) {logObj.State("---Schaltlisteneintrag für Ressource " # AktSRName # "(" # AktSR # ") " # strTemp # EIN.ToTime().Format("%X").Substr(0,5) # " / " #
                                            AUS.ToTime().Format("%X").Substr(0,5) # "  Parameter " # cap);}
    if(DEBUG)  {WriteLine("---Schaltlisteneintrag für Ressource " # AktSRName # "(" # AktSR # ") " # strTemp # EIN.ToTime().Format("%X").Substr(0,5) # " / " #
                                            AUS.ToTime().Format("%X").Substr(0,5) # "  Parameter " # cap);}
  }else{
    !// SCHALTEN / VARIABLE kennt kein Offset
    string strTemp = "Schalten: ";
    if (HSFlag=="V"){
      strTemp = "Variable setzen: ";
    }
    if(log) {logObj.State("---Schaltlisteneintrag für Ressource " # AktSRName # "(" # AktSR # ") " # strTemp # EIN.ToTime().Format("%X").Substr(0,5) # " - " #
                                            AUS.ToTime().Format("%X").Substr(0,5));}
    if(DEBUG)  {WriteLine("---Schaltlisteneintrag für Ressource " # AktSRName # "(" # AktSR # ") " # strTemp # EIN.ToTime().Format("%X").Substr(0,5) # " - " #
                                            AUS.ToTime().Format("%X").Substr(0,5));}
  }

  if (!bGefunden){
    !//Wird keine Raumvariable gefunden wir brechen das Script komplett ab
    if(log) {logObj.State(AktSR # " Raumvariable nicht gefunden, Abbruch Skript !!");}
    if(DEBUG)  {WriteLine(AktSR # " Raumvariable nicht gefunden, Abbruch Skript !!");}
    continue;
  }

  !// Raumliste aus dem der HK2-HKG-Liste
  string RVNListe=VarNamen.StrValueByIndex(";",raumIndex);

  !// Wenn wir keinen Raumnamen haben, dann bauen wir uns einen. Optional ist der in der HK1-R-Liste
  !// getrennt mit =.
  if (AktSRName=="") {
    !// Namen für das loggen ermitteln und Raumliste laden
    string AktSRName=RIDINamen.StrValueByIndex(";",raumIndex);
    !// Im Multiraum Fall nehmen wir nur den ersten / primären Raum
    AktSRName=AktSRName.StrValueByIndex("+",0);
  }
  AktSRName = AktSRName # "(" # AktSR # ")";

  !// Wir haben multiRaumVariante eine Raumliste durch + getrennt.
  if(log){logObj.State(AktSRName # " Raumliste: " # RVNListe);}
  if(DEBUG) {WriteLine(AktSRName # " Raumliste: " # RVNListe);}
  RVNListe=RVNListe.Split("+");

  !// Beginn innere Schleife-----------------------------------------
  !// In der MultiRaumVariante haben wir eine Liste durch + getrennt
  string RVN;
  if(DEBUG){WriteLine("RVNListe=" # RVNListe);}
  foreach(RVN,RVNListe){
    !// Bei einer Multiraum Definition könnte es sein, dass der Raum, den wir jetzt bearbeiten
    !// wollen, bereits in unserer neuen Schalliste vorhanden ist, weil der Termin mit einem
    !// anderen Schallisten Eintrag bereits bearbeitet wurde.
    string SchaltListenIndex = RVN # ";" # EIN_Org # ";" # AUS_Org # ";" # SDFlag_Org # ";";
    if(DEBUG) {WriteLine(RVN # " SchaltListenIndex=" # SchaltListenIndex);}
    if (("#" # SchaltListeNeu).Contains("#" # SchaltListenIndex)) {
      continue;
    }

    !// Erzeuge einen Namen ohne prefixe
    string RVNName = RVN.Replace(vrp#"HKG-Raum-","");

    !// Anzeigename fuers Log. Im Normalfall ist der Raumname identisch mit dem
    !// Ressourcennamen (AktSRName ohne die " (ID)"), dann waere "Name (ID)-Name"
    !// doppelt. Nur im Multiraum-Fall (mehrere Raeume je Ressource) haengen wir
    !// den konkreten Raumnamen an.
    string RaumLogName = AktSRName;
    if (AktSRName.StrValueByIndex("(",0)!=RVNName){
      RaumLogName = AktSRName # "-" # RVNName;
    }

    !// Wir benötigen die Ein und Aussschaltzeit frisch, weil diese hier manipuliert wird
    !// sie frisch aus den Original Schaltlisten Daten bezogen!
    integer EIN     = EIN_Org.ToTime().ToInteger();
    integer AUS     = AUS_Org.ToTime().ToInteger();
    integer SDFlag  = SDFlag_Org.ToInteger();

    if(DEBUG){WriteLine("RVN=" # RVN);}
    string RVI=dom.GetObject(RVN).State();
    if(DEBUG){WriteLine("RVI=" # RVI);}

    !//Aktoren und Raumtemp setzen, und bestimmen ob Heizen oder Schalten oder beides
    HSFlag = RVI.StrValueByIndex(";",1);

    !// Nun suchen wir in der alten Schaliste den gleichen Termin.
    !// Dieser Termin ist in der Schalliste. Wir müssen nun kontrollieren ob dieser Eintrag
    !// bereits in der Schalphase ist, wen dies so ist wird er unverndert übernommen
    integer iPos = ("#" # SchaltListeAlt).Find("#" # SchaltListenIndex);
    if (iPos>=0) {
      string strTemp = SchaltListeAlt.Substr(iPos);
      integer iLen = strTemp.Find("#");
      if (iLen<0){
        iLen = strTemp.Length();
      }
      strTemp = strTemp.Substr(0,iLen);

      !// Alte berechnete Schaltzeiten bestimmen
      EIN = strTemp.StrValueByIndex(";",4).ToTime().ToInteger();
      AUS = strTemp.StrValueByIndex(";",5).ToTime().ToInteger();

      !// Ist der Eintrag überhaupt noch gültig, 30min nach Schaltende entfernen wie den Eintrag
      if ((AUS+(zeitNachlauf*60))<NOW){
        !// Schaltlisteeintrag ist abgelaufen und damit obsolet.
        if(DEBUG) {WriteLine(RVN # " Schaltlisteneintrag wird übersprungen!");}
        continue;
      }

      !// Befinden wir uns schon in der Schaltphase? Dann wird dieser Eintrag nicht mehr geändert
      if (EIN<NOW){
        !// Der Termin ist noch nicht abgeschaltet aber er befindet sich in der Heizphase.
        !// Wir beerechnen die EIN und UAS Zeiten nicht neu, den alten Eintrag unverändert
        !// in  den aktuellen Schaltdaten übernehmen
        SchaltListeNeu = SchaltListeNeu # strTemp # "#";
        
        !// Protokolleintrag mit Zeit erzeugen
        strTemp = "Schalten";    
        if (HSFlag=="H"){
          strTemp = "Heizen"; 
        }elseif (HSFlag=="HS"){
          strTemp = "Heizen / Schalten"; 
        } elseif (HSFlag=="V"){
          strTemp = "Variable setzen";
        } 

        !// Log Eintrag für Eintrag erzeugen, der in Schaltung ist. DIese Daten verändern sich nicht mehr
        if(log){logObj.State(RaumLogName # " - " # strTemp # " - " # EIN.ToTime().Format("%X").Substr(0,5) # " / " # AUS.ToTime().Format("%X").Substr(0,5)); };
        if(DEBUG) {WriteLine(RaumLogName # " - " # strTemp # " - " # EIN.ToTime().Format("%X").Substr(0,5) # " / " # AUS.ToTime().Format("%X").Substr(0,5)); };

        !// Übername der Daten in die HK2VLZListe
        if(DEBUG) {WriteLine(RVN # " Schaltlisteneintrag befindet sich im Heiz-/Schaltzustand und wird übernommen!");}
        HK2VLZListe = HK2VLZListe # RVN # ";" # ((EIN_Org.ToTime().ToInteger()-EIN)/60) # ";" # EIN.ToTime() # ";" # EIN_Org # ";" # AUS.ToTime() # ";" # ((AUS_Org.ToTime().ToInteger()-AUS)/60) # "~";
        continue;
      }

      !// Wenn wir hierher kommen, dann ist der Eintrag noch nicht in der Heizphase. In dem
      !// Fall berechnen wir die Daten des Schalteintrages wieder neu.
    }

    !// Originaldaten noch mal laden
    integer EIN     = EIN_Org.ToTime().ToInteger();
    integer AUS     = AUS_Org.ToTime().ToInteger();

    !// Dieser Termin ist noch nicht in der Schalliste oder er ist nicht in der Heizphase,
    !// wir berechnen nun die Schaltzeiten neu.
    if(log){logObj.State(AktSRName # " Raumvariable: " # RVN # "=" # RVI);}

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

    !// Typ des Aktors bestimmen
    AGF=RVI.StrValueByIndex(";",2);

    !// Schaltverzögerung berechnen
    integer offsetRaumAn=0;
    integer offsetRaumAus=0;
    if (SDFlag>=0){
      !// Die  Einschaltverschiebung, kann mit einem Faktor versehen sein.
      offsetRaumAn = 0-(RVI.StrValueByIndex(";",4).StrValueByIndex("*",0).ToInteger()*60);
      offsetRaumAus = 0-(RVI.StrValueByIndex(";",5).ToInteger()*60);

      !// Wir berücksichtigen die Offset Zeiten nur, bei normalen Heizvorgängen.
      if((HSFlag=="H") || (HSFlag=="HS")){
        offsetRaumAn = offsetRaumAn-(GrundOffsetRaumEin*60);
        offsetRaumAus = offsetRaumAus-(GrundOffsetRaumAus*60);
      }
    }

    !// Grundtemperatur bestimmen
    GT=RVI.StrValueByIndex(";",3).StrValueByIndex("/",1).ToFloat();
    if(GT==0){
      GT=GTStandard;
    }

    !// Temperaturen individuell bestimmen. Ist
    !//  SDFlag>0   individuelle Temperatur
    !//  SDFlag==0  Normaltemperatur verwenden
    !//  SDFlag==-1 AUS
    !//  SDFlag==-2 EIN
    !//  SDFlag==-3 RESET
    real RTemp = SDFlag.ToFloat();
    if(SDFlag<=0){
      !// Temperaturen individuell bestimmen nach Raumparameter
      RTemp=RVI.StrValueByIndex(";",3).StrValueByIndex("/",0).ToFloat();
      if((log))
      {
        if (SDFlag==-3)     {logObj.State(RaumLogName # " Sonderfunktion \"Normalisierung\": " # GT.ToString(1));}
        elseif(SDFlag==-1)  {logObj.State(RaumLogName # " Sonderfunktion \"AUS\": " # GT.ToString(1));}
        elseif(SDFlag==-2)  {logObj.State(RaumLogName # " Sonderfunktion \"EIN\": " # RTemp.ToString(1));}
      }
    }

    !// Bestimmen der Vorheiz-/Schaltzeiten
    real ISTTemperatur=0.0;

    !//Nach aktueller Aussentemperatur den Offsetwert berechnen und am Einschaltzeitpunkt abziehen und Aktor Paramter setzen
    real ux=0.0;
    real uy=0.0;
    real lx=0.0;
    real ly=0.0;
    if((HSFlag=="H") || (HSFlag=="HS")){
      !// HEIZEN / HEIZEN+SCHALTEN
      !// Parameter bestimmen für Temperatur
      AGFParam = "AGFParam"#AGF.ToUpper();
      Param = AGFParamIP;
      if (system.IsVar(AGFParam)){
        Param = system.GetVar(AGFParam);
      }

      !// Wir nutzen die Temperaturverschiebung nur, wenn wir einen normalen Schaltvorgang haben
      !// Spezial Befehle #EIN# #AUS# #NORMAL# werden zur normalen Zeit ausgeführt.
      if (SDFlag>=0){
        if(AT<-5.0){
          lx=-10.0;
          ly = OffsetAT.StrValueByIndex(";",0).ToFloat();
          ux=-5;
          uy = OffsetAT.StrValueByIndex(";",1).ToFloat();
        }elseif(AT<0.0){
          lx=-5.0;
          ly = OffsetAT.StrValueByIndex(";",1).ToFloat();
          ux=0.0;
          uy = OffsetAT.StrValueByIndex(";",2).ToFloat();
        }elseif(AT<8.0){
          lx=0.0;
          ly = OffsetAT.StrValueByIndex(";",2).ToFloat();
          ux=8.0;
          uy = OffsetAT.StrValueByIndex(";",3).ToFloat();
        }elseif(AT<10.0){
          lx=8.0;
          ly = OffsetAT.StrValueByIndex(";",3).ToFloat();
          ux=10.0;
          uy = OffsetAT.StrValueByIndex(";",4).ToFloat();
        }elseif(AT<12.0){
          lx=10.0;
          ly = OffsetAT.StrValueByIndex(";",4).ToFloat();
          ux=12.0;
          uy = OffsetAT.StrValueByIndex(";",5).ToFloat();
        }elseif(AT<15.0){
          lx=12.0;
          ly = OffsetAT.StrValueByIndex(";",5).ToFloat();
          ux=15.0;
          uy = OffsetAT.StrValueByIndex(";",6).ToFloat();
        }else{
          !// Alles andere wird mit 15.0 bis 17.5 interpoliert
          lx=15.0;
          ly = OffsetAT.StrValueByIndex(";",6).ToFloat();
          ux=17.5;
          uy = OffsetAT.StrValueByIndex(";",7).ToFloat();
        }

        !// linear Interpolieren
        real offsetTempAn = (((uy-ly)/(ux-lx))*(AT-lx))+ly;
        if (offsetTempAn<0){
          offsetTempAn = 0;
        }

        !// Bestimme den Verschiebungsfaktor zur Temperaturverschiebung. maximal 500%
        !// minimal 20%. Andere Werte setzen den Faktor auf
        real faktor1 = RVI.StrValueByIndex(";",4).StrValueByIndex("*",1).ToFloat();
        if (faktor1==0){
          faktor1 = 1.0;
        }
        faktor1 = faktor1.Max(0.20).Min(5.0);

        !// Bestimme nun einen weiteren Faktor aus der ISTTemperatur und der Solltemperatur RTemp
        !// und der Grundtemperatur für den Raum (in diesem Fall wird nur die Temperatur, des ersten
        !// Aktors verwendet). Dadurch wird ein bereits warmer Raum nur so lange vorgeheizt, wie das
        !// die temperaturabhängige Vorheizzeit eben auch angibt, denn diese bezieht sich ja immer
        !// auf die Grundtemperatur.
        ISTTemperatur = GT.Max(AT);
        AktAktor = RVI.StrValueByIndex(";",6);
        if(DEBUG) { WriteLine("AktAktor=" # AktAktor); }
        objAktor = dom.GetObject(AktAktor);
        if (AktAktor && objAktor){
          objDP = objAktor.DPByHssDP("ACTUAL_TEMPERATURE");
          if (!objDP){
            objDP = objAktor.DPByHssDP("TEMPERATURE");
          }
          if (objDP){
            ISTTemperatur = objDP.State().ToFloat();
            }else{
              if(log){logObj.State(RaumLogName # ": Thermostat-Aktor/Kanal " # AktAktor # " hat keinen Datenpunkt ACTUAL_TEMPERATURE/TEMPERATURE! Raumtemp.-Schaetzwert=" # ISTTemperatur.ToString(1) # "°C (Max aus Grundtemp./Aussentemp.)");}
              if(DEBUG) {WriteLine(RaumLogName # ": Thermostat-Aktor/Kanal " # AktAktor # " hat keinen Datenpunkt ACTUAL_TEMPERATURE/TEMPERATURE! Raumtemp.-Schaetzwert=" # ISTTemperatur.ToString(1) # "°C (Max aus Grundtemp./Aussentemp.)");}
            }
        }elseif(!AktAktor) {
          if(log){logObj.State(RaumLogName # ": Kein Thermostat-Aktor/Kanal zugeordnet, Raumtemp.-Schaetzwert=" # ISTTemperatur.ToString(1) # "°C (Max aus Grundtemp./Aussentemp.)");}
          if(DEBUG) {WriteLine(RaumLogName # ": Kein Thermostat-Aktor/Kanal zugeordnet, Raumtemp.-Schaetzwert=" # ISTTemperatur.ToString(1) # "°C (Max aus Grundtemp./Aussentemp.)");}
        }else{
          if(log){logObj.State(RaumLogName # ": Thermostat-Aktor/Kanal " # AktAktor # " existiert nicht!");}
          if(DEBUG) {WriteLine(RaumLogName # ": Thermostat-Aktor/Kanal " # AktAktor # " existiert nicht!");}
        }

        !// Luftfeuchte optional auslesen (nur wenn Datenpunkt vorhanden und Wert > 0).
        !// Wert 0 bedeutet: kein Sensor vorhanden (z.B. IP-Thermostat ohne Feuchtigkeitssensor).
        string HUMText = "";
        if (AktAktor && objAktor){
          objDP = objAktor.DPByHssDP("ACTUAL_HUMIDITY");
          if (!objDP){
            objDP = objAktor.DPByHssDP("HUMIDITY");
          }
          if (objDP){
            integer humVal = objDP.State().ToInteger();
            if (humVal > 0){
              HUMText = " / HUM " # humVal.ToString() # "%";
            }
          }
        }

        !// Die SollIstTemperaturAnpassung begrenzt die Anrechnung weil diese bei einer Fussbodenheizung zu
        !// stark begrenzt. Schutz vor Division durch 0.
        real faktor2 = 1.0;
        if ((RTemp-GT)!=0){
          !// Minderungsfaktor für bereits erreichte Temperatur > GT, oder Vergrößerungsfaktor wenn
          !// ISTTemperatur<GT
          faktor2 = 1.0-(SollIstTemperaturAnpassung*((ISTTemperatur.Min(RTemp)-GT)/(RTemp-GT)));
        }

        if(DEBUG)  {WriteLine("Vor Korrektur: offsetRaumAn=" # offsetRaumAn.ToInteger() # " offsetTempAn=" # offsetTempAn.ToInteger());}
        offsetRaumAn = (offsetRaumAn.ToFloat()*faktor2).ToInteger();
        offsetTempAn = (0.0-(faktor1*faktor2*offsetTempAn).ToInteger()*60).ToInteger();
        if(DEBUG)  {WriteLine("Korrektur: faktor1=" # faktor1.ToString(2) # " faktor2=" # faktor2.ToString(2) # " - " # AT.ToString(1) # "/" # GT.ToString(1) # "/" # ISTTemperatur.ToString(1) # "/" # RTemp.ToString(1) # "°C offsetRaumAn=" # (offsetRaumAn/60) # " offsetTempAn=" # (offsetTempAn/60));}
        !//if(log) {logObj.State("faktor2=" # faktor2.ToString(2) # " - " # AT.ToString(1) # "/" # GT.ToString(1) # "/" # ISTTemperatur.ToString(1) # "°C offsetRaumAn=" # (offsetRaumAn/60) # " offsetTempAn=" # (offsetTempAn/60));}

        !// Reale Schaltzeiten berechnen
        string logText = RaumLogName # " - Heizen - AT " # AT.ToString(1) # "°C / GT " # GT.ToString(1) # "°C / IST " # ISTTemperatur.ToString(1) # "°C / ZIEL " # RTemp.ToString(1) # "°C" # HUMText # " - " # EIN.ToTime().Format("%X").Substr(0,5) # " ";
        if (offsetRaumAn>0){ logText=logText#"+"; }elseif(offsetRaumAn==0){ logText=logText#"-"; }
        logText = logText # (offsetRaumAn/60) #"min ";
        if (offsetTempAn==0){ logText=logText#" - "; }
        logText = logText # (offsetTempAn/60) # "min = ";
        EIN = EIN + offsetRaumAn + offsetTempAn;
        logText = logText # EIN.ToTime().Format("%X").Substr(0,5) # " / " # AUS.ToTime().Format("%X").Substr(0,5) # " ";
        if (offsetRaumAus>0){ logText=logText#"+"; }elseif(offsetRaumAus==0){ logText=logText#"-"; }
        AUS = AUS + offsetRaumAus;
        logText = logText # (offsetRaumAus/60) # "min = " # AUS.ToTime().Format("%X").Substr(0,5);
        HK2VLZListe = HK2VLZListe # RVN # ";" # ((EIN_Org.ToTime().ToInteger()-EIN)/60) # ";" # EIN.ToTime() # ";" # EIN_Org # ";" # AUS.ToTime() # ";" # ((AUS_Org.ToTime().ToInteger()-AUS)/60) # "~";
        if(log) {logObj.State(logText);}
        if(DEBUG)  {WriteLine(logText);}
      }
    }else{
      !// SCHALTEN / VARIABLE kennt kein Offset
      string strTemp = " - Schalten - ";
      if (HSFlag=="V"){
        strTemp = " - Variable setzen - ";
      }

      !// Reale Schaltzeiten berechnen
      string logText = RaumLogName # strTemp #EIN.ToTime().Format("%X").Substr(0,5) # " ";
      if (offsetRaumAn>0){ logText=logText#"+"; }elseif(offsetRaumAn==0){ logText=logText#"-"; }
      logText = logText # (offsetRaumAn/60) #"min = ";
      EIN = EIN + offsetRaumAn;
      logText = logText # EIN.ToTime().Format("%X").Substr(0,5) # " / " # AUS.ToTime().Format("%X").Substr(0,5) # " ";
      if (offsetRaumAus>0){ logText=logText#"+"; }elseif(offsetRaumAus==0){ logText=logText#"-"; }
      AUS = AUS + offsetRaumAus;
      logText = logText # (offsetRaumAus/60) # "min = " # AUS.ToTime().Format("%X").Substr(0,5);
      HK2VLZListe = HK2VLZListe # RVN # ";" # ((EIN_Org.ToTime().ToInteger()-EIN)/60) # ";" # EIN.ToTime() # ";" # EIN_Org # ";" # AUS.ToTime() # ";" # ((AUS_Org.ToTime().ToInteger()-AUS)/60) # "~";
      if(log) {logObj.State(logText);}
      if(DEBUG)  {WriteLine(logText);}
    }

    !// Verhindern dass Ausschaltpunkt vor Einschaltpunkt liegt
    if(AUS<=EIN){
      !// Durch das überspringen des Raumes hier, wird ein Raum evtl. ausgeschaltet, weil er nicht mehr
      !// als zu heizen gilt.
      if(log) {logObj.State(RaumLogName # " Einschaltzeit liegt nach Ausschaltzeit");}
      if(DEBUG)  {WriteLine(RaumLogName # " Einschaltzeit liegt nach Ausschaltzeit");}
      continue;
    }

    !// Abgelaufene Termine bleiben erhalten, um einen Ausschaltvorgang auslösen zu lassen.

    !// Der Termin wurde berechnet, wir setzen nun die errechnenten Daten an die Originaldaten
    if(DEBUG) {WriteLine(RVN # " Schaltlisteneintrag wurde neu berechnet!");}
    if(DEBUG) {WriteLine(RVN # " Schaltlisteneintrag=" # SchaltListenIndex # EIN.ToTime() # ";" # AUS.ToTime() # ";" # AT.ToString(1) # ";" # ISTTemperatur.ToString(1) # "#");}
    SchaltListeNeu = SchaltListeNeu # SchaltListenIndex # EIN.ToTime() # ";" # AUS.ToTime() # ";" # AT.ToString(1) # ";" # ISTTemperatur.ToString(1) # "#";
  }
  !// Ende innere Schleife-------------------------------------------
}
!// Ende äußere Schleife---------------------------------------------

!// -----------------------------------------------------------------

if(DEBUG){WriteLine("SchaltListeNeu=" # SchaltListeNeu);}
object objSL = dom.GetObject(vrp#"HK2-Schaltliste");
if(objSL) {
  !// Nur schreiben nur wenn es sich ändert (das reduziert Einträge im Systemprotokoll bei Protokollierung der Variable)
  if(objSL.State()!=SchaltListeNeu) {
    objSL.State(SchaltListeNeu);
  }
}

!// -----------------------------------------------------------------

!// HK2-Schaltzeiten schreiben (optional, nur wenn Variable auf CCU vorhanden)
if(DEBUG){WriteLine("HK2VLZListe=" # HK2VLZListe);}
object objVLZ = dom.GetObject(vrp#"HK2-Schaltzeiten");
if(objVLZ) {
  !// Nur schreiben nur wenn es sich ändert (das reduziert Einträge im Systemprotokoll bei Protokollierung der Variable)
  if(objVLZ.State()!=HK2VLZListe) {
    objVLZ.State(HK2VLZListe);
  }
}

if(log){logObj.State("Ende Berechnung der Schaltzeiten==============");}
WriteLine("Ende Schaltskriptlauf");
