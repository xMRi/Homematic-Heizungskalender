!// Skript 2 für das Schalten der Heizgruppen
!//================================================================================================
!// Stand:    10.10.2026
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
!// TT:  2026-10-05 Luftfeuchte: Wert 0 wird ignoriert (kein Sensor vorhanden, z.B. IP-Thermostat)
!// TT:  2026-10-05 Luftfeuchte: ACTUAL_HUMIDITY (IP) zuerst pruefen, HUMIDITY (Classic) als Fallback
!// TT:  2026-10-03 Luftfeuchte (HUMIDITY) optional in der Heizen-Logzeile ausgeben (nur wenn Datenpunkt vorhanden)
!// TT:  2026-10-03 Nachtschaltung: Log-Meldungen ueberarbeitet (Raumname-Praefix, Multi-Raum-Zusatz)
!// TT:  2026-10-02 Log-Text bei fehlendem Sensor/Aktor verstaendlicher formuliert (kein HomeMatic-Code mehr)
!// TT:  2026-10-01 Log-Text bei fehlendem Sensor/Aktor korrigiert: zeigt jetzt GT.Max(AT)-Wert
!// MRi: 2026-10-01 Wenn kein Temperatursensor vorhanden ist wird GT.Max(AT) für die Berechnung der
!//                 Vorheizzeit verwendet.
!// TT:  2026-09-28 Log-Ausgabe: doppelten Raumnamen "Name (ID)-Name" auf "Name(ID)" reduziert
!//                 (Raumname nur noch im Multiraum-Fall angehaengt) und Leerzeichen vor der
!//                 Klammer entfernt.
!// TT:  2026-09-18 Nachtschaltung: Relais-Zustand mit State() lesen statt State(0) (schrieb AUS
!//                 und lieferte falschen Ist-Zustand). CCU-verifiziert.
!// TT:  2026-09-16 Log-Ausgaben verbessert: Raumname in Thermostat-Fehlermeldungen ergänzt,
!//                 AT/GT/IST in Heizen-Zeile mit Bezeichnung und °C, Nachkommastellen vereinheitlicht.
!// MRi: 2026-08-08 Bugfix Heizen mit Schalten
!// MRi: 2026-02-19 Heizen mit Schalten eingebaut, Schaltliste umgebaut
!// MRI: 2026-02-05 Leere Raumzuordnung berücksichtigen
!// MRi: 2026-01-27 Begrenzung der Vorheizzeit nach unten auf mindestens 10%
!// MRi: 2026-01-13 HK1-R-Liste erhält nun auch den Namen der Resource getrennt mit Gleichheitszeichen
!// MRi: 2025-01-12 Bessere Behandlung von mehreren Aktoren in den Raumvars. minAktorNamenLaenge entfernt.
!// MRi: 2025-01-05 Begrenzung der Berücksichtigung der Raumtemperatur, Schaltzeiten korrekt berücksichtigen
!// MRi: 2026-01-01 Skript gegen fehlende Aktoren gesichert
!// MRi: 2025-12-29 Berücksichtigung der aktuellen Raumtemperatur bei der Vorheizzeit
!// MRi: 2025-12-22 Schaltskript arbeitete nicht für Schalten. Es wurde immer ein Heizvorgang angenommen
!// MRi: 2025-12-19 Log-Darstellung für Schalttemperaturen verbessert
!// MRi: 2025-12-18 Einfachere Parameter ermittlung je Typ der HomeMatic Geräte
!// MRi: 2025-12-17 Individuelle Absenktemperatur in Parameter 3 des RVI eingebaut, getrennt mit /
!// MRi: 2025-12-10 Grundsätzliche Überarbeitungen für Sonderbefehle #AUS# #EIN# #NORMAL#
!//                 Bessere Debugausgaben.
!// MRi: 2025-12-09 Einschaltverschiebung erhält optionalen Faktor (getrennt mit *)
!// MRi: 2025-12-08 Kosmetische Änderungen, Reduktion von State Aufrufen.
!// MRi: 2025-12-03 Schaltvorgänge reduzieren, wenn die entsprechende Temp. bereits gesetzt ist.
!// MRi: 2025-11-29 Beheizte Räume für die kein Schaltlisteneintrag vorhanden ist werden sofort abgeschaltet
!// MRi: 2025-11-26 HK1-R-ListeNamen fest eingebaut für verbessertes Logging
!// MRi: 2025-11-21 Kein Einschalten, wenn Schaltezeit <5min oder Ausschaltzeitpunkt vor Einschaltzeitpunkt liegt
!// MRi: 2025-11-20 Logging verbessert.
!// MRi: 2025-11-18 Logging verbessert, Behandlung der Grenztemperatur fürs Heizen Übersteuerung geändert
!// MRi: 2025-11-14 MultiRaumVariante, damit lassen sich mehrere Räume einer Ressource zuordnen.
!// MRi: 2025-11-13 Log-Ausgaben verbessert und präzisiert.
!// MRi: 2025-11-13 1. Ausschaltzyklen Übersprungsicher gemacht! Das Programm muss aber alle 5min laufen
!//                 2. Ebenfalls schalten wir alle Heizkörper auf Grundtemperatur zurück und setzen die
!//                    Raumvariablen zurück wenn HK2-Hand-Grundtemp gesetzt ist
!//                 3. Ist die Schaltliste leer prüfen wir ob noch ein Raum geschaltet ist.
!// MRi: 2025-11-11 Logging über System Variablen HK2-Log (Text) und HK2-Logging (boolean) eingebaut.
!//                 Damit das Logging korrekt arbeitet müssen beide Variablen vorhanden sein. Beide sollten
!//                 protokolliert werden. Alle Einträge finden sich dann im System Protokoll.
!// MRi: 2025-11-10 Interpolation der Vorlaufzeit aus der Außentemperatur über die HK2-Kurve

!//Eingabe eines Namens Präfix
!//Dies ist nur erforderlich wenn die Namensvorgabe beim erstellen den Systemvariablen geändert wurde.
!//Wird hier ein Präfix eingeben so muss dieser in allen Skripten auch angegeben werden.
string vrp="";

!//Debug Ausgaben Ein und Aus schalten. 0 = Aus, 1 = Ein
boolean DEBUG=0;

!// Logging in "Log" mit 1 zwingend einschalten oder mit -1 zwingend Ausschalten
!// Mit 0 wird die Einstellunge aus der HKx-Logging übernommen
integer log=0;

!// Temperaturanpassung (1=100% Berücksichtigung Ist/Soll Temperatur Differenz 0.5=50%, 0=0%)
real SollIstTemperaturAnpassung = 0.6;

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
string  OffsetAT=dom.GetObject(vrp+"HK2-Kurve").State();
integer GrundOffsetRaumAus=dom.GetObject(vrp+"HK2-VorzeitAus").State();
integer GrundOffsetRaumEin=dom.GetObject(vrp+"HK2-Kurvenversatz").State();
string SListe=dom.GetObject(vrp+"HK1-Schaltliste").State();
string VarNamen=dom.GetObject(vrp+"HK2-HKG-Liste").State();
string RIDI=dom.GetObject(vrp+"HK1-R-Liste").State();
real ATG=dom.GetObject(vrp+"HK2-A.Temp.Grenze").State().ToFloat();
boolean Flag_Hand_Temp=dom.GetObject(vrp+"HK2-Hand-Temp").State();
boolean Flag_Hand_Grundtemp=dom.GetObject(vrp+"HK2-Hand-Grundtemp").State();
real AT=dom.GetObject(vrp+"HK2-Aussentemperatur").State().ToFloat();
real GTStandard=dom.GetObject(vrp+"HK2-Grundtemperatur").State().ToFloat();
real GT=GTStandard;
string AktAktor;
string AktorenListe;
object objAktor;
object objDP;
string AGF;
string AGFParam;
string Param;

!// Logging vorbereiten
var logObj=dom.GetObject(vrp+"HK2-Log");
var loggingObj=dom.GetObject(vrp+"HK2-Logging");

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

if(log){logObj.State("Beginn Schaltskriptlauf=========================");}
WriteLine("Beginn Schaltskriptlauf");
if(SListe!=""){
  !// Log nur, wenn es auch was zu tun gibt
  !if(log) {logObj.State("Vollständige Raumliste: "+VarNamen);}
  if(DEBUG)  {WriteLine("Vollständige Raumliste: "+VarNamen);}
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
while (iPos<SListe.Length()) {
  if (SListe.Substr(iPos,1)==";"){
    iEntry=iEntry+1;
    if ((iEntry%5)==0){
      SListe = SListe.Substr(0,iPos) # "\t" # SListe.Substr(iPos+1,SListe.Length()-iPos-1);
    }
  }
  iPos = iPos+1;
}

!// Schleife über die Schaltliste
string SLEintrag;
if(DEBUG){WriteLine("SListe=" # SListe);}
foreach(SLEintrag,SListe){
  if(DEBUG){WriteLine("SLEintrag=" # SLEintrag);}
  string AktSR=SLEintrag.StrValueByIndex(";",0);
  if(DEBUG){WriteLine("AktSR=" # AktSR);}
  !// Listenelement auslesen
  !// Parameter für aktuellen Schaltvorgang. Die Parameter werden später noch einmal gelesen
  !// und Final bestimmt. Auch das HSFlag wird aus der Raumbeschreibung gelesen.
  string  HSFlag  = SLEintrag.StrValueByIndex(";",4);
  integer EIN     = SLEintrag.StrValueByIndex(";",1).ToTime().ToInteger();
  integer AUS     = SLEintrag.StrValueByIndex(";",2).ToTime().ToInteger();
  integer SDFlag  = SLEintrag.StrValueByIndex(";",3).ToInteger();
  real    RTemp   = SLEintrag.StrValueByIndex(";",3).ToFloat();

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
  if(HSFlag!="S"){
    !// Sonderbefehl kontrollieren und Raumtemperatur Sonderbefehl bestimmen
    string cap;
    if (SDFlag<0){
      cap = ("AUS;EIN;NORMAL").StrValueByIndex(";",(1+SDFlag)*(-1));
    }else{
      if (SDFlag==0){
        cap = "Normaltemperatur";
      }else{
        cap = RTemp.ToString(1);
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
    !// Schalten kennt kein Offset
    if(log) {logObj.State("---Schaltlisteneintrag für Ressource (" # AktSR # ") Schalten: " # EIN.ToTime().Format("%X").Substr(0,5) # " - " #
                                            AUS.ToTime().Format("%X").Substr(0,5));}
    if(DEBUG)  {WriteLine("---Schaltlisteneintrag für Ressource (" # AktSR # ") Schalten: " # EIN.ToTime().Format("%X").Substr(0,5) # " - " #
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
  if(log){logObj.State(AktSRName # " Raumliste: "+RVNListe);}
  if(DEBUG) {WriteLine(AktSRName # " Raumliste: "+RVNListe);}
  RVNListe=RVNListe.Split("+");

  !// Beginn innere Schleife-----------------------------------------
  !// In der MultiRaumVariante haben wir eine Liste durch + getrennt
  string RVN;
  if(DEBUG){WriteLine("RVNListe=" # RVNListe);}
  foreach(RVN,RVNListe){
    if(DEBUG){WriteLine("RVN=" # RVN);}
    string RVI=dom.GetObject(RVN).State();
    if(DEBUG){WriteLine("RVI=" # RVI);}
    if(log){logObj.State(AktSRName # " Raumvariable: "+RVN+"="+RVI);}

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

    !// Wir benötigen die Ein und Aussschaltzeit frisch, weil diese hier manipuliert wird.
    !// Sie wird frisch aus der Schaltliste bezogen!
    EIN = SLEintrag.StrValueByIndex(";",1).ToTime().ToInteger();
    AUS = SLEintrag.StrValueByIndex(";",2).ToTime().ToInteger();
    RTemp = SLEintrag.StrValueByIndex(";",3).ToFloat();

    !//Aktoren und Raumtemp setzen, und bestimmen ob Heizen oder Schalten oder beides
    HSFlag = RVI.StrValueByIndex(";",1);

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
      if(HSFlag!="S"){
        offsetRaumAn = offsetRaumAn-(GrundOffsetRaumEin*60);
        offsetRaumAus = offsetRaumAus-(GrundOffsetRaumAus*60);
      }
    }
    if(SDFlag<=0){
      !// Temperaturen individuell bestimmen
      RTemp=RVI.StrValueByIndex(";",3).StrValueByIndex("/",0).ToFloat();
      GT=RVI.StrValueByIndex(";",3).StrValueByIndex("/",1).ToFloat();
      if(GT==0){
        GT=GTStandard;
      }
      if((log))
      {
        if (SDFlag==-3)     {logObj.State(RaumLogName # " Sonderfunktion \"Normalisierung\": " # GT.ToString(1));}
        elseif(SDFlag==-1)  {logObj.State(RaumLogName # " Sonderfunktion \"AUS\": " # GT.ToString(1));}
        elseif(SDFlag==-2)  {logObj.State(RaumLogName # " Sonderfunktion \"EIN\": " # RTemp.ToString(1));}
      }
    }

    !//Nach aktueller Aussentemperatur den Offsetwert berechnen und am Einschaltzeitpunkt abziehen und Aktor Paramter setzen
    real ux=0.0;
    real uy=0.0;
    real lx=0.0;
    real ly=0.0;
    if (HSFlag!="S"){
      !// Schaltparameter bestimmen
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
        if(DEBUG)  {WriteLine("faktor1=" # faktor1.ToString(2));}

        !// Bestimme nun einen weiteren Faktor aus der ISTTemperatur und der Solltemperatur RTemp
        !// und der Grundtemperatur für den Raum (in diesem Fall wird nur die Temperatur, des ersten
        !// Aktors verwendet). Dadurch wird ein bereits warmer Raum nur so lange vorgeheizt, wie das
        !// die temperaturabhängige Vorheizzeit eben auch angibt, denn diese bezieht sich ja immer
        !// auf die Grundtemperatur.
        real ISTTemperatur = GT.Max(AT);
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

        !// faktor2 wird nach unten auf 0.2 begrenzt. Besonders wenn wir bereits in der Heizphase sind.
        !// Sonst verschiebt sich die EIN Zeit immer weiter auf die AUS-Zeit zu. Was dazu führen könnte,
        !// dass die Heizung ausgeschaltet wird. faktor2 ist also ein Wert >=0.2
        !// Die SollIstTemperaturAnpassung begrenzt die Anrechnung weil diese bei einer Fussbodenheizung zu
        !// stark begrenzt.
        real faktor2 = 1.0-(SollIstTemperaturAnpassung*((ISTTemperatur.Min(RTemp)-GT)/(RTemp-GT)));
        faktor2 = faktor2.Max(0.2);
        offsetRaumAn = (offsetRaumAn.ToFloat()*faktor2).ToInteger();
        offsetTempAn = (0.0-(faktor1*faktor2*offsetTempAn).ToInteger()*60).ToInteger();
        if(DEBUG)  {WriteLine("faktor2=" # faktor2.ToString(2) # " - " # AT.ToString(1) # "/" # GT.ToString(1) # "/" # ISTTemperatur.ToString(1) # "°C offsetRaumAn=" # (offsetRaumAn/60) # " offsetTempAn=" # (offsetTempAn/60));}
        !//if(log) {logObj.State("faktor2=" # faktor2.ToString(2) # " - " # AT.ToString(1) # "/" # GT.ToString(1) # "/" # ISTTemperatur.ToString(1) # "°C offsetRaumAn=" # (offsetRaumAn/60) # " offsetTempAn=" # (offsetTempAn/60));}

        !// Reale Schaltzeiten berechnen
        string logText = RaumLogName # " Heizen - AT " # AT.ToString(1) # "°C / GT " # GT.ToString(1) # "°C / IST " # ISTTemperatur.ToString(1) # "°C" # HUMText # " - " # EIN.ToTime().Format("%X").Substr(0,5) # " ";
        if (offsetRaumAn>0){ logText=logText#"+"; }elseif(offsetRaumAn==0){ logText=logText#"-"; }
        logText = logText # (offsetRaumAn/60) #"min ";
        if (offsetTempAn==0){ logText=logText#" - "; }
        logText = logText # (offsetTempAn/60) # "min = ";
        EIN = EIN + offsetRaumAn + offsetTempAn;
        logText = logText # EIN.ToTime().Format("%X").Substr(0,5) # " / " # AUS.ToTime().Format("%X").Substr(0,5) # " ";
        if (offsetRaumAus>0){ logText=logText#"+"; }elseif(offsetRaumAus==0){ logText=logText#"-"; }
        AUS = AUS + offsetRaumAus;
        logText = logText # (offsetRaumAus/60) # "min = " # AUS.ToTime().Format("%X").Substr(0,5);
        if(log) {logObj.State(logText);}
        if(DEBUG)  {WriteLine(logText);}
      }
    }else{
      !// Reale Schaltzeiten berechnen
      string logText = RaumLogName # " Schalten - " #EIN.ToTime().Format("%X").Substr(0,5) # " ";
      if (offsetRaumAn>0){ logText=logText#"+"; }elseif(offsetRaumAn==0){ logText=logText#"-"; }
      logText = logText # (offsetRaumAn/60) #"min ";
      EIN = EIN + offsetRaumAn;
      logText = logText # EIN.ToTime().Format("%X").Substr(0,5) # " / " # AUS.ToTime().Format("%X").Substr(0,5) # " ";
      if (offsetRaumAus>0){ logText=logText#"+"; }elseif(offsetRaumAus==0){ logText=logText#"-"; }
      AUS = AUS + offsetRaumAus;
      logText = logText # (offsetRaumAus/60) # "min = " # AUS.ToTime().Format("%X").Substr(0,5);
      if(log) {logObj.State(logText);}
      if(DEBUG)  {WriteLine(logText);}

      !// Parameter setzen
      Param="STATE";
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
              objDP = objAktor.DPByHssDP(Param);
              if (objDP){
                if(HSFlag=="H"){
                  objDP.State(GT);
                  if(log){logObj.State(AktAktor+" wird dauerhaft ausgeschaltet auf Temp.: "+GT.ToString(1));}
                  if(DEBUG) {WriteLine(AktAktor+" wird dauerhaft ausgeschaltet auf Temp.: "+GT.ToString(1));}
                }else{
                  objDP.State(0);
                  if(log){logObj.State(AktAktor+" wird dauerhaft ausgeschaltet. Parameter:" # Param);}
                  if(DEBUG) {WriteLine(AktAktor+" wird dauerhaft ausgeschaltet. Parameter:" # Param);}
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
          dom.GetObject(RVN).State("2;"+RVI.Substr(2,RVI.Length()-2));
          !// if(log){logObj.State(RaumLogName # " Schaltstatus setzen "+AktSR+" "+dom.GetObject(RVN).State().StrValueByIndex(";",0));}
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
              objDP = objAktor.DPByHssDP(Param);
              if (objDP){
                if(HSFlag=="H"){
                  objDP.State(RTemp);
                  if(log){logObj.State(AktAktor +" wird dauerhaft eingeschaltet auf Temp.: "+RTemp.ToString(1));}
                  if(DEBUG) {WriteLine(AktAktor +" wird dauerhaft eingeschaltet auf Temp.: "+RTemp.ToString(1));}
                }else{
                  objDP.State(1);
                  if(log){logObj.State(AktAktor +" wird dauerhaft eingeschaltet");}
                  if(DEBUG) {WriteLine(AktAktor +" wird dauerhaft eingeschaltet");}
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
          dom.GetObject(RVN).State("3;"+RVI.Substr(2,RVI.Length()-2));
          !// if(log){logObj.State(RaumLogName # " Schaltstatus setzen "+AktSR+" "+dom.GetObject(RVN).State().StrValueByIndex(";",0));}
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
              objDP = objAktor.DPByHssDP(Param);
              if (objDP){
                if(HSFlag=="H"){
                  objDP.State(GT);
                  if(log){logObj.State(AktAktor +" Rückstellung aus dauerhafter Schaltung Ein/Aus auf Grundtemperatur: "+GT.ToString(1));}
                  if(DEBUG) {WriteLine(AktAktor +" Rückstellung aus dauerhafter Schaltung Ein/Aus auf Grundtemperatur: "+GT.ToString(1));}
                }else{
                  objDP.State(0);
                  if(log){logObj.State(AktAktor +" Rückstellung aus dauerhafter Schaltung auf AUS. Parameter:" # Param);}
                  if(DEBUG) {WriteLine(AktAktor +" Rückstellung aus dauerhafter Schaltung auf AUS. Parameter:" # Param);}
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
          dom.GetObject(RVN).State("0;"+RVI.Substr(2,RVI.Length()-2));
          !// if(log){logObj.State(RaumLogName # " Schaltstatus setzen "+AktSR+" "+dom.GetObject(RVN).State().StrValueByIndex(";",0));}
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
              objDP = objAktor.DPByHssDP(Param);
              if (objDP){
                  if(HSFlag=="H"){
                    if(Flag_Hand_Temp!=false){
                      real istTemperatur = objDP.State();
                      if(istTemperatur==RTemp){
                        objDP.State(GT);
                        if(log) {logObj.State(RaumLogName # " " # AktAktor+" Ausschalten (mit Funktion Reglervorrang) - Ist: " # istTemperatur.ToString(1) # " Neu: " # GT.ToString(1) #" Parameter: " # Param);}
                        if(DEBUG)  {WriteLine(RaumLogName # " " # AktAktor+" Ausschalten (mit Funktion Reglervorrang) - Ist: " # istTemperatur.ToString(1) # " Neu: " # GT.ToString(1) #" Parameter: " # Param);}
                      }else{
                        if(log){logObj.State(RaumLogName # " " # AktAktor+" Reglervorrang bei AUS - Regler händisch verstellt auf Temp.: " # istTemperatur.ToString(1));}
                      }
                    }else{
                      objDP.State(GT);
                      if(log) {logObj.State(RaumLogName # " " # AktAktor+" Ausschalten (ohne Funktion Reglervorrang) auf Temp.: "+GT.ToString(1)+" Parameter: "+Param);}
                      if(DEBUG)  {WriteLine(RaumLogName # " " # AktAktor+" Ausschalten (ohne Funktion Reglervorrang) auf Temp.: "+GT.ToString(1)+" Parameter: "+Param);}
                    }
                }else{
                  objDP.State(0);
                  if(log) {logObj.State(RaumLogName # " " # AktAktor+" Ausschalten. Parameter: "+Param);}
                  if(DEBUG)  {WriteLine(RaumLogName # " " # AktAktor+" Ausschalten. Parameter: "+Param);}
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
          dom.GetObject(RVN).State("0;"+RVI.Substr(2,RVI.Length()-2));
          !// if(log){logObj.State(RaumLogName # " Schaltstatus setzen "+AktSR+" "+dom.GetObject(RVN).State().StrValueByIndex(";",0));}
          continue;
        }
      }
    }

    !//Einschalten (Status ==> 1)
    !//Liegt der Einschaltzeitpunkt in der Vergangenheit UND Ausschaltzeitpunkt in der Zukunft Heizung einschalten WENN diese noch nicht eingeschaltet ist.
    if(SDFlag>=0){
      !// Sollte die Außentemperatur über unserem Schwellenwert liegen, Heizen wir nicht
      if((HSFlag=="S") || (AT<ATG)){
        !// Und wir schalten nur ein wenn die Einschaltzeit mehr als 5min beträgt
        if(((EIN+300)<AUS) && (EIN<=NOW) && (AUS>NOW)){
          !// Da wir die Heizung einschalten, setzen wir den Raum in die Heizliste
          if (RVNListeAn.Find(RVN+";")<0){
            RVNListeAn=RVNListeAn+RVN+";";
          }
          !// Wir schalten aber nur, wenn er noch nicht geschaltet ist
          if(aktuellerSchaltZustand==0){
            foreach(AktAktor,AktorenListe.Split(";")){
              objAktor = dom.GetObject(AktAktor);
              if (objAktor){
                objDP = objAktor.DPByHssDP(Param);
                if (objDP){
                  if(HSFlag=="H"){
                    if(Flag_Hand_Temp!=false){
                      real istTemperatur = objDP.State();
                      if(istTemperatur==GT){
                        objDP.State(RTemp);
                        if(log) {logObj.State(AktAktor+" Einschalten (mit Funktion Reglervorrang) - Ist: " # istTemperatur.ToString(1) # " Neu: " # RTemp.ToString(1) #" Parameter: " # Param);}
                        if(DEBUG)  {WriteLine(AktAktor+" Einschalten (mit Funktion Reglervorrang) - Ist: " # istTemperatur.ToString(1) # " Neu: " # RTemp.ToString(1) #" Parameter: " # Param);}
                      }else{
                        if(log){logObj.State(AktAktor+" Reglervorrang bei EIN (Regeler händisch verstellt auf Temp.: " # istTemperatur.ToString(1));}
                        if(DEBUG) {WriteLine(AktAktor+" Reglervorrang bei EIN (Regeler händisch verstellt auf Temp.: " # istTemperatur.ToString(1));}
                      }
                    }else{
                      objDP.State(RTemp);
                      if(log) {logObj.State(AktAktor+" Einschalten (ohne Funktion Reglervorrang) auf Temp.: "+RTemp.ToString(1)+" Parameter: "+Param);}
                      if(DEBUG)  {WriteLine(AktAktor+" Einschalten (ohne Funktion Reglervorrang) auf Temp.: "+RTemp.ToString(1)+" Parameter: "+Param);}
                    }
                  }else{
                    objDP.State(1);
                    if(log) {logObj.State(AktAktor+" Einschalten "+Param);}
                    if(DEBUG)  {WriteLine(AktAktor+" Einschalten "+Param);}
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
            dom.GetObject(RVN).State("1;"+RVI.Substr(2,RVI.Length()-2));
            !// if(log){logObj.State(RaumLogName # " Schaltstatus setzen "+AktSR+" "+dom.GetObject(RVN).State().StrValueByIndex(";",0));}
            continue;
          }
        }
      }else{
          if(log){logObj.State(RaumLogName # " Heizen abgebrochen Aussentemperatur " # AT.ToString(1) # "°C größer Grenzwert " # ATG.ToString(1) # "°C");}
          if(DEBUG) {WriteLine(RaumLogName # " Heizen abgebrochen Aussentemperatur " # AT.ToString(1) # "°C größer Grenzwert " # ATG.ToString(1) # "°C");}
      }
    }
  }
  !// Ende innere Schleife-------------------------------------------
}
!// Ende äußere Schleife---------------------------------------------

!// Nachtschaltung---------------------------------------------------

!// Code für Prüfung der Nachschaltung immer zwischen 00:57 und 01:03 Uhr!
!// Die Nachtschaltung kontrolliert nur die Zustände 0,2,3. Ist noch ein normaler
!// Schaltzustand vorhanden, gehen wir davon aus, dass es einen Schaltlisten Eintrag gibt.

if((Flag_Hand_Grundtemp!=false) && (NOW.ToTime().Format("%H%M")>="0057") && (NOW.ToTime().Format("%H%M")<="0103")){
  if(log){logObj.State("Beginn Nachtabschaltung=========================");}
  if(DEBUG) {WriteLine("Beginn Nachtabschaltung");}

  !// Laufe über alle Einträge der Raumliste (je Eintrag ggf. mehrere Räume per +)
  string RVNGruppe;
  foreach(RVNGruppe,VarNamen.Split(";")) {
    if (!RVNGruppe){ continue; }

    !// Primaeren Raumnamen fuer den Log ermitteln (erster Eintrag vor dem +)
    string RVNPrimaer = RVNGruppe.StrValueByIndex("+",0);
    string RVNPrimaerName = RVNPrimaer.Replace(vrp#"HKG-Raum-","");

    !// Gruppenname fuer den Log aufbauen: "Primaer (inkl. Raum2, Raum3)"
    string GruppeLogName = RVNPrimaerName;
    string RVNZusatz;
    foreach(RVNZusatz,RVNGruppe.Split("+")) {
      if (!RVNZusatz){ continue; }
      string RVNZusatzName = RVNZusatz.Replace(vrp#"HKG-Raum-","");
      if (RVNZusatzName!=RVNPrimaerName){
        if (GruppeLogName==RVNPrimaerName){
          GruppeLogName = RVNPrimaerName # " (inkl. " # RVNZusatzName;
        }else{
          GruppeLogName = GruppeLogName # ", " # RVNZusatzName;
        }
      }
    }
    if (GruppeLogName!=RVNPrimaerName){ GruppeLogName = GruppeLogName # ")"; }
    if(log){logObj.State(GruppeLogName # ": Nachtschaltung prüfen");}
    if(DEBUG) {WriteLine(GruppeLogName # ": Nachtschaltung prüfen");}

    !// Laufe über alle Räume der Gruppe
    foreach(RVN,RVNGruppe.Split("+")) {
    if (!RVN){ continue; }
    string RVNName = RVN.Replace(vrp#"HKG-Raum-","");
    string RaumLogName = RVNPrimaerName;
    if (RVNName!=RVNPrimaerName){
      RaumLogName = RVNPrimaerName # " (inkl. " # RVNName # ")";
    }
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
          objDP = objAktor.DPByHssDP(Param);
          if (objDP){
            if(HSFlag=="H"){
              real istTemperatur = objDP.State();
              if(istTemperatur==RTemp){
                !// Heiztemperatur immer setzen. Es könnte eine Gruppe sein, die teilweise verstellt ist.
                objDP.State(RTemp);
                if(log){logObj.State(RaumLogName # ": " # AktAktor # " Nachtschaltung für \"" #
                                     ("Aus;Ein;Dauer-Aus;Dauer-Ein").StrValueByIndex(";",aktuellerSchaltZustand) #
                                     "\" bereits gesetzt auf Temp.: "+RTemp.ToString(1));}
                if(DEBUG) {WriteLine(RaumLogName # ": " # AktAktor # " Nachtschaltung für \"" #
                                     ("Aus;Ein;Dauer-Aus;Dauer-Ein").StrValueByIndex(";",aktuellerSchaltZustand) #
                                     "\" bereits gesetzt auf Temp.: "+RTemp.ToString(1));}
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
      }
    }
  }
  if(log){logObj.State("Ende Nachtabschaltung=========================");}
  if(DEBUG) {WriteLine("Ende Nachtabschaltung");}
}

!// Schaltlistenprüfung----------------------------------------------

!// Code für die Prüfung Schaltliste. Alle Räume, die jetzt beheizt werden müssen auch
!// in der RVNListeAn enthalten sein.
RVNListe = VarNamen;
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
  if((RVNListeAn.Find(RVN+";")<0) && (aktuellerSchaltZustand==1)){
    !// Reset der Heizvariablen von 1 auf 0. Da die Heizliste leer ist, sollte der Eintrag
    !// in der Raumliste auch auf 0 stehen.
    dom.GetObject(RVN).State("0;"+RVI.Substr(2,RVI.Length()-2));
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
        objDP = objAktor.DPByHssDP(Param);
        if (objDP){
          if(HSFlag=="H"){
            real istTemperatur = objDP.State();
            objDP.State(GT);
            if(log){logObj.State("Kein Schaltlisten Eintrag vorhanden für " # RVN # "- Ist: " # istTemperatur.ToString(1) # " Neu: " # GT.ToString(1) #" Parameter: " # Param);}
            if(DEBUG) {WriteLine("Kein Schaltlisten Eintrag vorhanden für " # RVN # "- Ist: " # istTemperatur.ToString(1) # " Neu: " # GT.ToString(1) #" Parameter: " # Param);}
          }else{
            boolean istZustand = objDP.State()!=0;
            if (istZustand)
            {
              objDP.State(0);
              if(log){logObj.State("Kein Schaltlisten Eintrag vorhanden für " # RVN # "! Schalter - "+AktAktor+" ausschalten. Parameter: "+Param);}
              if(DEBUG) {WriteLine("Kein Schaltlisten Eintrag vorhanden für " # RVN # "! Schalter - "+AktAktor+" ausschalten. Parameter: "+Param);}
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
