!// Skript 2 für das berechnen der Schaltzeiten
!//================================================================================================
!// Stand:    10.11.2026
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
!// TT:  2026-11-10 Kurvenanpassungsfaktor ueber optionale Systemvariable HK2-Kurvenanpassung konfigurierbar (0.3..1.0, Vorgabe 0.8)
!// MRi: 2026-11-09 Minimale Heizzeit (default 15min) eingeführt
!// TT:  2026-11-08 Konfigurierbare Mindest-Vorlaufzeit pro Raum (Feld 4: Vorheizzeit*Faktor*MindestMin, Default 15min)
!// TT:  2026-11-08 faktor1/faktor2 umbenannt in faktor1HK2Kurve/faktor2HeizBedarf für bessere Lesbarkeit
!// MRi: 2026-11-07 Lösung falls keine aktuelle Raumtemperatur ermittelt werden kann.
!// TT:  2026-11-06 SDFlag-Parsing in Freeze-Wiederherstellung: ToTime() entfernt (war falsch fuer Integer-Werte)
!// MRi: 2026-11-06 Anpassung der Temperaturberechnung aus Ist- und Zieltemperatur
!// MRi: 2026-11-06 Diverse Fixes Aufgrund einer statischen Code-Analyse
!// MRi: 2026-11-06 Alter Schaltliste wird nicht korrekt übernommen
!// MRi: 2026-11-03 Optimierungen Sonderschaltungen und Außentemperaturgrenze
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
boolean DEBUG=0;

!// Logging in "Log" mit 1 zwingend einschalten oder mit -1 zwingend Ausschalten
!// Mit 0 wird die Einstellunge aus der HKx-Logging übernommen
integer log=0;

!// Kurvenanpassung an eine logarithmische Sättigungskurve.
!// Ersetzt die Kurve durch 2 Geraden, Wert<=1, bei 1==Gerade, 0.9==Gute Näherung, 0.8==Sicherheit (mehr Bauch in der Mitte)
real Kurvenanpassung = 0.8;
var svKA = dom.GetObject(vrp # "HK2-Kurvenanpassung");
if (svKA) {
    Kurvenanpassung = svKA.Value().ToFloat();
    if ((Kurvenanpassung < 0.3)) { Kurvenanpassung = 0.3; }
    if ((Kurvenanpassung > 1.0)) { Kurvenanpassung = 1.0; }
}

!//#######---Ende Variabler Bereich---#############################################################
!//Im Folgenden Hier keine Veränderungen vornehmen!

!//-------------------------------------------------------------
integer NOW=system.Date().ToTime().ToInteger();
string  OffsetAT=dom.GetObject(vrp # "HK2-Kurve").State();
integer GrundOffsetRaumAus=dom.GetObject(vrp # "HK2-VorzeitAus").State();
integer GrundOffsetRaumEin=dom.GetObject(vrp # "HK2-Kurvenversatz").State();
string TerminListe=dom.GetObject(vrp # "HK1-Schaltliste").State();
string VarNamen=dom.GetObject(vrp # "HK2-HKG-Liste").State();
string RIDI=dom.GetObject(vrp # "HK1-R-Liste").State();
real ATG=dom.GetObject(vrp # "HK2-A.Temp.Grenze").State().ToFloat();
real AT=dom.GetObject(vrp # "HK2-Aussentemperatur").State().ToFloat();
real GTStandard=dom.GetObject(vrp # "HK2-Grundtemperatur").State().ToFloat();
real GT=GTStandard;
string AktAktor;
string AktorenListe;
object objAktor;
object objDP;
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
WriteLine("Beginn Berechnung der Schaltzeiten");
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
    if(DEBUG) {WriteLine("SchaltListenIndex=" # SchaltListenIndex);}
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
    object objRVN = dom.GetObject(RVN);
    if (!objRVN){
      if(log) {logObj.State("Raumvariable " # RVN # " wurde nicht gefunden!");}
      if(DEBUG)  {WriteLine("Raumvariable " # RVN # " wurde nicht gefunden!");}
      continue;
    }
    string RVI=objRVN.State();
    if(DEBUG){WriteLine("RVI=" # RVI);}

    !//Aktoren und Raumtemp setzen, und bestimmen ob Heizen oder Schalten oder beides
    HSFlag = RVI.StrValueByIndex(";",1);

    !// Nun suchen wir in der alten Schaliste den gleichen Termin.
    !// Dieser Termin ist in der Schalliste. Wir müssen nun kontrollieren ob dieser Eintrag
    !// bereits in der Schalphase ist, wen dies so ist wird er unverndert übernommen
    string strAlterListenEintrag="";
    integer iPos = ("#" # SchaltListeAlt).Find("#" # SchaltListenIndex);
    if (iPos>=0) {
      if(DEBUG) {WriteLine("SchaltlistenIndex gefunden!")};
      strAlterListenEintrag = SchaltListeAlt.Substr(iPos);
      integer iLen = strAlterListenEintrag.Find("#");
      if (iLen<0){
        iLen = strAlterListenEintrag.Length();
      }
      strAlterListenEintrag = strAlterListenEintrag.Substr(0,iLen);
      if(DEBUG) {WriteLine("strAlterListenEintrag=" # strAlterListenEintrag);}

      !// Alte berechnete Schaltzeiten bestimmen
      SDFlag  = strAlterListenEintrag.StrValueByIndex(";",3).ToInteger();
      EIN     = strAlterListenEintrag.StrValueByIndex(";",4).ToTime().ToInteger();
      AUS     = strAlterListenEintrag.StrValueByIndex(";",5).ToTime().ToInteger();

      !// Ist der Eintrag überhaupt noch gültig, 30min nach Schaltende entfernen wie den Eintrag
      if ((AUS+(zeitNachlauf*60))<NOW){
        !// Schaltlisteeintrag ist abgelaufen und damit obsolet.
        if(DEBUG) {WriteLine(RVN # " Schaltlisteneintrag wird übersprungen!");}
        continue;
      }

      !// Wir prüfen den alten Schaltlisteneintrag. Befinden wir uns schon in der Schaltphase?
      !// Dann wird dieser Eintrag nicht mehr geändert.
      !// Das gilt nicht für Sonderbefehle (SDFlag<0).
      if ((EIN<NOW) && (SDFlag>=0)){
        !// Der Termin ist noch nicht abgeschaltet aber er befindet sich in der Heizphase.
        !// Wir beerechnen die EIN und UAS Zeiten nicht neu, den alten Eintrag unverändert
        !// in  den aktuellen Schaltdaten übernehmen
        SchaltListeNeu = SchaltListeNeu # strAlterListenEintrag # "#";

        !// Protokolleintrag mit Zeit erzeugen
        string strTemp = "Schalten";
        if (HSFlag=="H"){
          strTemp = "Heizen";
        }elseif (HSFlag=="HS"){
          strTemp = "Heizen / Schalten";
        } elseif (HSFlag=="V"){
          strTemp = "Variable setzen";
        }

        !// Log Eintrag für Eintrag erzeugen, der in Schaltung ist. Diese Daten verändern sich nicht mehr
        if(log){logObj.State(RaumLogName # " - " # strTemp # " - " # EIN.ToTime().Format("%X").Substr(0,5) # " / " # AUS.ToTime().Format("%X").Substr(0,5)); };
        if(DEBUG) {WriteLine(RaumLogName # " - " # strTemp # " - " # EIN.ToTime().Format("%X").Substr(0,5) # " / " # AUS.ToTime().Format("%X").Substr(0,5)); };

        !// Übername der Daten in die HK2VLZListe
        if(DEBUG) {WriteLine(RVN # " Schaltlisteneintrag befindet sich im Heiz-/Schaltzustand und wird übernommen!");}
        HK2VLZListe = HK2VLZListe # RVN # ";" # ((EIN_Org.ToTime().ToInteger()-EIN)/60) # ";" # EIN.ToTime() # ";" # EIN_Org # ";" # AUS.ToTime() # ";" # ((AUS_Org.ToTime().ToInteger()-AUS)/60) # "~";
        continue;
      }

      !// Wenn wir hierher kommen, dann ist der Eintrag noch nicht in der Heizphase. In dem
      !// Fall berechnen wir die Daten des Schalteintrages wieder neu. Der alte Schaltlisteeintrag
      !// strAlterListenEintrag wird evtl. benutzt um einen Thermostatausfall auszugleichen.
    }

    !// Originaldaten noch mal laden
    EIN     = EIN_Org.ToTime().ToInteger();
    AUS     = AUS_Org.ToTime().ToInteger();
    SDFlag  = SDFlag_Org.ToInteger();

    !// Dieser Termin ist noch nicht in der Schaltliste oder er ist nicht in der Heizphase,
    !// wir berechnen nun die Schaltzeiten neu.
    if(log){logObj.State(AktSRName # " Raumvariable: " # RVN # "=" # RVI);}

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
    !//  SDFlag==0  Normaltemperatur verwenden aus Raumvariable
    !//  SDFlag==-1 AUS
    !//  SDFlag==-2 EIN
    !//  SDFlag==-3 RESET
    real RTemp = SDFlag.ToFloat();
    if(SDFlag<=0){
      !// Temperaturen individuell bestimmen nach Raumparameter
      RTemp=RVI.StrValueByIndex(";",3).StrValueByIndex("/",0).ToFloat();
    }

    !// Bestimmen der Vorheiz-/Schaltzeiten
    real ISTTemperatur=0.0;

    if (SDFlag>=0){
      !// Normaler Heiz- bzw. Schaltvorgang
      !//Nach aktueller Aussentemperatur den Offsetwert berechnen und am Einschaltzeitpunkt abziehen und Aktor Paramter setzen
      if((HSFlag=="H") || (HSFlag=="HS")){
        !// HEIZEN / HEIZEN+SCHALTEN

        real ux=0.0;
        real uy=0.0;
        real lx=0.0;
        real ly=0.0;
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

        !// faktor1HK2Kurve: Raumspezifischer Multiplikator auf die HK2-Kurve (aus Feld 4 der Raumvariable, Default 1.0, Bereich 0.20-5.0)
        real faktor1HK2Kurve = RVI.StrValueByIndex(";",4).StrValueByIndex("*",1).ToFloat();
        if (faktor1HK2Kurve==0){
          faktor1HK2Kurve = 1.0;
        }
        faktor1HK2Kurve = faktor1HK2Kurve.Max(0.20).Min(5.0);

        !// MindestVorlaufzeit: Untergrenze für die Gesamtvorlaufzeit in Minuten (aus Feld 4, dritter *-Wert, Default 15min, Bereich 1-480)
        !// Wert 0 oder fehlendes Feld gilt als nicht konfiguriert und setzt den Default.
        !// Der Clamp ist nicht deaktivierbar: er verhindert, dass faktor2HeizBedarf die Vorlaufzeit bei IST nahe ZIEL auf null wegrechnet.
        integer MindestVorlaufzeit = RVI.StrValueByIndex(";",4).StrValueByIndex("*",2).ToInteger();
        if (MindestVorlaufzeit==0){
          MindestVorlaufzeit = 15;
        }
        MindestVorlaufzeit = MindestVorlaufzeit.Max(1).Min(480);

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

        !// Wenn wir keine IstTemperatur gemeldet bekommen (also 0°C), dann übernehmen wir einfach den alten Schaltlisten 
        !// Eintrag. Eine Berechnung mit 0°C würde eine utopische Vorheizzeit auslösen. 
        if (ISTTemperatur==0){
          !// Log schreiben, das wir keine Temperaturdaten haben
          if(log){logObj.State(RaumLogName # ": Thermostat-Aktor/Kanal " # AktAktor # " liefert aktuell keine Daten!");}
          if(DEBUG) {WriteLine(RaumLogName # ": Thermostat-Aktor/Kanal " # AktAktor # " liefert aktuell keine Daten!");}
          
          !// Wir suchen den vorherigen Schaltlisten Eintrag. 
          if (strAlterListenEintrag!=""){
            !// Wir haben ja alles schon berechnet. Es wird sich kaum etwas geändert haben, also behalten wir vorerst diese 
            !// alten Daten.
            SchaltListeNeu = SchaltListeNeu # strAlterListenEintrag # "#";
            if(log){logObj.State(RaumLogName # ": Alter Schaltlisteneintrag wird übernommen, es erfolgt vorerst keine Neuberechnung!");}
            if(DEBUG) {WriteLine(RaumLogName # ": Alter Schaltlisteneintrag wird übernommen, es erfolgt vorerst keine Neuberechnung!");}
          }else{
            !// Wir haben scheinbar noch nie Berechnung durchgeführt. In diesem Fall hoffen wir, dass der nächste Zyklus
            !// Erfolg hat. SOnst wird die Heizungnie eingeschaltet!!!
            if(log){logObj.State(RaumLogName # ": Neuberechnung verschoben auf den nächsten Berechnungszyklus!");}
            if(DEBUG) {WriteLine(RaumLogName # ": Neuberechnung verschoben auf den nächsten Berechnungszyklus!");}
          }
          continue;
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

        !// Wir nutzen die Temperaturverschiebung nur, wenn wir einen normalen Schaltvorgang haben
        !// Wenn die Außentemperaturgrenze erreicht ist brechen wir alle Heizvorgänge ab. Hier heißt das einfach, wir
        !// ignorieren diesen Schaltlisten eintrag und nehmen den nächtsen.
        if(AT>=ATG){
          if(log){logObj.State(RaumLogName # " Heizen abgebrochen Aussentemperatur " # AT.ToString(1) # "°C größer Grenzwert " # ATG.ToString(1) # "°C");}
          if(DEBUG) {WriteLine(RaumLogName # " Heizen abgebrochen Aussentemperatur " # AT.ToString(1) # "°C größer Grenzwert " # ATG.ToString(1) # "°C");}
          continue;
        }

        !// Hier berechnen wir mit Hilfe von zwei Geraden eine Näherung an die logarithmische Sättigungskurve.
        !// Ziel ist es die vorgegebene maximale Vorheizzeit von GT /Grundtemperatur) auf RTemp (Wohlfühltemperatur)
        !// zu kürzen weil wir evtl. eine von GT abweichende ISTTemperatur haben.
        !// Die Kurvenanpassung gibt an um wieviel der Bauch der Kurve von der Gerade entfernt sein soll (0.9 Ist
        !// ca. 10%). D.h. genau zwischen GT und RTemp haben wir eine höhere Vorheiztemperatur als 50%.
        !// faktor2HeizBedarf: Dämpfungsfaktor nach Zwei-Geraden-Modell; reduziert die gesamte VLZ proportional zum verbleibenden Heizbedarf.
        !// Kurvenanpassung steuert die Krümmung. Bei IST=GT: 1.0 (volle VLZ), bei IST=Ziel: 0.0 (keine VLZ)
        real faktor2HeizBedarf = 1.0;
        if ((RTemp-GT)!=0){
          if (ISTTemperatur<((GT+(RTemp-GT)/2))) {
            faktor2HeizBedarf = 1.0-(Kurvenanpassung*((ISTTemperatur.Min(RTemp)-GT)/(RTemp-GT)));
            if(DEBUG) {WriteLine("faktor2HeizBedarf:" # faktor2HeizBedarf);}
          } else {
            faktor2HeizBedarf = (2.0-Kurvenanpassung)*(1.0-((ISTTemperatur.Min(RTemp)-GT)/(RTemp-GT)));
            if(DEBUG) {WriteLine("faktor2HeizBedarf:" # faktor2HeizBedarf);}
          }
        }

        if(DEBUG)  {WriteLine("Vor Korrektur: offsetRaumAn=" # offsetRaumAn.ToInteger() # " offsetTempAn=" # offsetTempAn.ToInteger());}
        offsetRaumAn = (offsetRaumAn.ToFloat()*faktor2HeizBedarf).ToInteger();
        offsetTempAn = (0.0-(faktor1HK2Kurve*faktor2HeizBedarf*offsetTempAn).ToInteger()*60).ToInteger();
        if(DEBUG)  {WriteLine("Korrektur: faktor1HK2Kurve=" # faktor1HK2Kurve.ToString(2) # " faktor2HeizBedarf=" # faktor2HeizBedarf.ToString(2) # " - " # AT.ToString(1) # "/" # GT.ToString(1) # "/" # ISTTemperatur.ToString(1) # "/" # RTemp.ToString(1) # "°C offsetRaumAn=" # (offsetRaumAn/60) # " offsetTempAn=" # (offsetTempAn/60));}
        if(DEBUG)  {WriteLine("Nach Korrektur: offsetRaumAn=" # offsetRaumAn.ToInteger() # " offsetTempAn=" # offsetTempAn.ToInteger());}

        !// Mögliche Log-Ausgabe
        !//if(log) {logObj.State("faktor2HeizBedarf=" # faktor2HeizBedarf.ToString(2) # " - " # AT.ToString(1) # "/" # GT.ToString(1) # "/" # ISTTemperatur.ToString(1) # "°C offsetRaumAn=" # (offsetRaumAn/60) # " offsetTempAn=" # (offsetTempAn/60));}
        
        !// Reale Schaltzeiten berechnen
        !// Mindest-Vorlaufzeit: Obergrenze für den (negativen) Gesamtoffset; Offsets sind negativ (Vorverschiebung).
        !// MindestSekunden ist negativ, .Min() wählt den betragsmäßig größeren Wert (weiter in der Vergangenheit).
        integer gesamtOffset = offsetRaumAn + offsetTempAn;
        integer MindestSekunden = 0 - (MindestVorlaufzeit * 60);
        integer gesamtOffsetKorr = gesamtOffset.Min(MindestSekunden);
        string mindestHinweis = "";
        if (gesamtOffsetKorr < gesamtOffset) {
          mindestHinweis = " [Mindest]";
        }
        string logText = RaumLogName # " - Heizen - AT " # AT.ToString(1) # "°C / GT " # GT.ToString(1) # "°C / IST " # ISTTemperatur.ToString(1) # "°C / ZIEL " # RTemp.ToString(1) # "°C" # HUMText # " - " # EIN.ToTime().Format("%X").Substr(0,5) # " ";
        if (offsetRaumAn>0){ logText=logText#"+"; }elseif(offsetRaumAn==0){ logText=logText#"-"; }
        logText = logText # (offsetRaumAn/60) #"min ";
        if (offsetTempAn==0){ logText=logText#" - "; }
        logText = logText # (offsetTempAn/60) # "min" # mindestHinweis # " = ";
        EIN = EIN + gesamtOffsetKorr;
        logText = logText # EIN.ToTime().Format("%X").Substr(0,5) # " / " # AUS.ToTime().Format("%X").Substr(0,5) # " ";
        if (offsetRaumAus>0){ logText=logText#"+"; }elseif(offsetRaumAus==0){ logText=logText#"-"; }
        AUS = AUS + offsetRaumAus;
        logText = logText # (offsetRaumAus/60) # "min = " # AUS.ToTime().Format("%X").Substr(0,5);
        HK2VLZListe = HK2VLZListe # RVN # ";" # ((EIN_Org.ToTime().ToInteger()-EIN)/60) # ";" # EIN.ToTime() # ";" # EIN_Org # ";" # AUS.ToTime() # ";" # ((AUS_Org.ToTime().ToInteger()-AUS)/60) # "~";
        if(log) {logObj.State(logText);}
        if(DEBUG)  {WriteLine(logText);}
      }else{
        !// SCHALTEN / VARIABLE kennt keine Vorheizzeiten
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
    }else{
        !// Spezial Befehle #EIN# #AUS# #NORMAL# werden zur normalen Zeit ausgeführt.
        !// Sonderbefehle werden ganz ohne Versatz ausgeführt.

        string strTemp = "???";
        if (SDFlag==-3){
          strTemp = "\"RESET\": " # GT.ToString(1);
        }elseif(SDFlag==-1){
          strTemp = "\"AUS\": " # GT.ToString(1);
        }elseif(SDFlag==-2){
          strTemp = "\"EIN\": " # RTemp.ToString(1);
        }

        !// Log Eintrag für Eintrag erzeugen.
        if(log){logObj.State(RaumLogName # " - Sonderfunktion - " # strTemp # " - " # EIN.ToTime().Format("%X").Substr(0,5) # " / " # AUS.ToTime().Format("%X").Substr(0,5)); };
        if(DEBUG) {WriteLine(RaumLogName # " - Sonderfunktion - " # strTemp # " - " # EIN.ToTime().Format("%X").Substr(0,5) # " / " # AUS.ToTime().Format("%X").Substr(0,5)); };
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
WriteLine("Ende Berechnung der Schaltzeiten");
