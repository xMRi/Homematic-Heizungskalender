!// Tool zur Kontrolle der Heizkurve
!//================================================================================================
!// Stand:    06.11.2026
!// Autoren:  Martin Richter    (heizkalender@m-ri.de) http://blog.m-ri.de/
!// Projekt:  Helmut Diedrichs  (helmut@diedrichs.de) https://diedrichs.de
!//------------------------------------------------------------------------------------------------
!// Copyright (C) 2026 Martin Richter (xMRi-Software)
!// Dieser Teil des Heizkalenders ist freie Software und wird unter der GNU General Public License
!// Version 3 (GPLv3) oder neuer veröffentlicht.
!// Es besteht keinerlei Garantie oder Haftung. Nutzung auf eigene Verantwortung.
!//================================================================================================
!//
!// Skript sollte alle 5min laufen ca. 30 Sekunden nach dem Schaltskript
!//

!// TT:  2026-11-06 Terminende-Doppellog verhindert: Bit 4 (16) als Guard gesetzt.
!// MRi: 2026-11-03 Aufteilung Skript2 Termine vorbereiten, Skript 3 Schalten
!// TT:  2026-11-02 AT bei allen 5 Events mitloggen (fuer Regressionstest Saettigungsmodell).
!//                 Zieltemperatur-Event am Terminende nachholen, falls IST >= ZIEL aber
!//                 das Event im normalen 5-min-Zyklus verpasst wurde.
!// MRi: 2026-10-19 Neuen Modus "V" für das setzen einer Variable eingebaut
!// TT:  2026-10-05 Log-Ausgabe: fehlendes Komma zwischen "Ist:" und "Ziel:" in allen
!//                 fuenf Ereignis-Zeilen ergaenzt.
!// TT:  2026-09-28 Log-Ausgabe: doppelten Raumnamen "Name (ID)-Name" auf "Name(ID)" reduziert
!//                 (Raumname nur noch im Multiraum-Fall angehaengt) und Leerzeichen vor der
!//                 Klammer entfernt.
!// TT:  2026-09-18 HSFlag von boolean auf string korrigiert (String-Vergleiche "H"/"S"/"HS");
!//                 strTemp-Shadowing im DEBUG-Block behoben (zeigte immer "Heizen:").
!//                 Fehlender Temperatur-Sensor (Feld 6) wird nun im Log gemeldet (einmal pro
!//                 Heizphase über Status-Bit 3) statt stumm übersprungen.
!// MRi: 2026-02-19 Heizen mit Schalten eingebaut, Schaltliste umgebaut
!// MRI: 2026-02-05 Leere Raumzuordnung berücksichtigen
!// MRi: 2026-01-13 HK1-R-Liste erhält nun auch den Namen der Resource getrennt mit Gleichheitszeichen

!//Eingabe eines Namens Präfix
!//Dies ist nur erforderlich wenn die Namensvorgabe beim erstellen den Systemvariablen geändert wurde.
!//Wird hier ein Präfix eingeben so muss dieser in allen Skripten auch angegeben werden.
string vrp="";

!//Debug Ausgaben Ein und Aus schalten. 0 = Aus, 1 = Ein
boolean DEBUG=0;

!// Logging in "Log" mit 1 zwingend einschalten oder mit -1 zwingend Ausschalten
!// Mit 0 wird die Einstellung aus der HKx-Logging übernommen.
!// log -1 macht hier keinen Sinn und beendet das Skript.
integer log=0;

!//#######---Ende Variabler Bereich---#############################################################
!//Im Folgenden Hier keine Veränderungen vornehmen!

!//-------------------------------------------------------------
integer NOW=system.Date().ToTime().ToInteger();
string  OffsetAT=dom.GetObject(vrp+"HK2-Kurve").State();
string SListe=dom.GetObject(vrp+"HK1-Schaltliste").State();
string VarNamen=dom.GetObject(vrp+"HK2-HKG-Liste").State();
string RIDI=dom.GetObject(vrp+"HK1-R-Liste").State();
integer ATG=dom.GetObject(vrp+"HK2-A.Temp.Grenze").State().ToFloat();
boolean Flag_Hand_Temp=dom.GetObject(vrp+"HK2-Hand-Temp").State();
boolean Flag_Hand_Grundtemp=dom.GetObject(vrp+"HK2-Hand-Grundtemp").State();
real AT=dom.GetObject(vrp+"HK2-Aussentemperatur").State().ToFloat();
real GTStandard=dom.GetObject(vrp+"HK2-Grundtemperatur").State().ToFloat();
real GT=GTStandard;
string AktAktor;
object objAktor;
object objDP;
string AGF;

!// Logging bestimmen
var logObj=dom.GetObject(vrp+"HK-LogHeizkurvenkontrolle");
var loggingObj=dom.GetObject(vrp+"HK-LoggingHeizkurvenkontrolle");

!// Prüfe ob logging erwartet wird
if (log<0) {
  !// Zwingend kein logging
  log = false;
  if(DEBUG)  {WriteLine("Logging ist nicht aktiviert. Abbruch!!!");}
  quit;
} elseif (log==0) {
!// Einstellung der Logging Variable prüfen
  if (loggingObj && loggingObj.State()!=0){
    log = true;
  }
} else {
  !// Logging einschalten
  log = true;
}

!// Logging ausschalten, wenn keine Variable vorhanden
if (!logObj){
  !// Ohne logging macht das keinen Snn
  if(DEBUG)  {WriteLine("Logging ist nicht aktiviert. Abbruch!!!");}
  quit;
}

!// Dazu benötigen wir auch eine Variable, in der wie zu den Räumen, den jeweiligen
!// Status und die maximale Temperatur speichern.

var objVar=dom.GetObject(vrp+"HK-RäumeHeizkurvenkontrolle");
if (!objVar){
  if(DEBUG)  {WriteLine("HK-RäumeHeizkurvenkontrolle ist nicht vorhanden. Abbruch!!!");}
  quit;
}
string RaumListe = objVar.State();
string bearbeiteteRaeume=";";

!// Baue eine simple Namensliste aus den HK2-HKG-Liste. Wir entfernen Prefix und im multiraum Fall auch die anderen Räume
!// Aus HKG-Raum-GrSaal, wird GrSaal. Aus HKG-Foyer wird Foyer
string RIDINamen=VarNamen.Replace("HKG-Raum-","").Replace("HKG-","");

WriteLine("Beginn Heizkurvenkontrolle");
if(DEBUG)  {WriteLine("Vollständige Raumliste: "+VarNamen);}

!// Beginn aussere Schleife------------------------------------------
!// Element von der Schaltliste nehmen und die dazu gehörige Raumvariablen suchen.
!// Wird die Raumvariable nicht gefunden wird der Eintrag übersprungen.

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

!// Schleife über die Schaltliste. ACHTUNG: Das ganzhe kann nur funktionieren, wenn die Schaltliste aufsteigend
!// aufgebaut ist.
string SLEintrag;
if(DEBUG){WriteLine("SListe=" # SListe);}
foreach(SLEintrag,SListe){
  if(DEBUG){WriteLine("SLEintrag=" # SLEintrag);}
  string AktSR=SLEintrag.StrValueByIndex(";",0);
  if(DEBUG){WriteLine("AktSR=" # AktSR);}
  !// Listenelement auslesen
  !// Parameter für aktuellen Schaltvorgang. Die Parameter werden später noch einmal gelesen
  !// und Final bestimmt. Auch das HSFlag wird aus der Raumbeschreibung gelesen.
  string HSFlag  = SLEintrag.StrValueByIndex(";",4);
  integer EIN     = SLEintrag.StrValueByIndex(";",1).ToTime().ToInteger();
  integer AUS     = SLEintrag.StrValueByIndex(";",2).ToTime().ToInteger();
  integer SDFlag  = SLEintrag.StrValueByIndex(";",3).ToInteger();
  real    RTemp   = SLEintrag.StrValueByIndex(";",3).ToFloat();

  if (SDFlag<0){
    !// Sollte es eine Dauerschaltung sein, ignorieren wir diesen Eintrag
    continue;
  }

  if((HSFlag=="H") || (HSFlag=="HS")){
    !// Sonderbefehl kontrollieren
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
    if(DEBUG){
      string strTemp = "Heizen: ";
      if (HSFlag=="HS"){
        strTemp = "Heizen+Schalten: ";
      }
      WriteLine("---Schaltlisteneintrag für Ressource (" # AktSR # ") " # strTemp # EIN.ToTime().Format("%X").Substr(0,5) # " / " #
                                            AUS.ToTime().Format("%X").Substr(0,5) # "  Parameter " # cap);
    }
  }

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

  if (!bGefunden){
    !//Wird keine Raumvariable gefunden wir brechen das Script komplett ab
    logObj.State(AktSR # " Raumvariable nicht gefunden, Abbruch Skript !!");
    if(DEBUG)  {WriteLine(AktSR # " Raumvariable nicht gefunden, Abbruch Skript !!");}
    continue;
  }

  !// Namen für das loggen ermitteln und Raumliste laden
  string RVNListe=VarNamen.StrValueByIndex(";",raumIndex);
  if (AktSRName==""){
    AktSRName=RIDINamen.StrValueByIndex(";",raumIndex);
    !// Im Multiraum Fall nehmen wir nur den ersten / primären Raum
    AktSRName=AktSRName.StrValueByIndex("+",0);
    if(AktSRName==""){
      AktSRName = AktSR;
    }
  }
  AktSRName = AktSRName # "(" # AktSR # ")";
  if(DEBUG)  {WriteLine("AktSRName=" # AktSRName);}

  if(DEBUG) {WriteLine(AktSRName # " Raumliste: "+RVNListe);}
  RVNListe=RVNListe.Split("+");

  !// Beginn innere Schleife-----------------------------------------
  !// In der haben wir eine Liste durch + getrennt
  string RVN;
  if(DEBUG){WriteLine("RVNListe=" # RVNListe);}
  foreach(RVN,RVNListe){
    if(DEBUG){WriteLine("----------------------------------------------");}
    if(DEBUG){WriteLine("RVN=" # RVN);}
    string RVI=dom.GetObject(RVN).State();
    if(DEBUG){WriteLine("RVI=" # RVI);}

    !// Erzeuge einen Namen ohne prefixe
    string RVNName = RVN.Replace(vrp#"HKG-Raum-","");
    if(DEBUG)  {WriteLine("RVNName=" # RVNName);}

    !// Anzeigename fuers Log. Im Normalfall ist der Raumname identisch mit dem
    !// Ressourcennamen (AktSRName ohne die "(ID)"), dann waere "Name(ID)-Name"
    !// doppelt. Nur im Multiraum-Fall haengen wir den konkreten Raumnamen an.
    string RaumLogName = AktSRName;
    if (AktSRName.StrValueByIndex("(",0)!=RVNName){
      RaumLogName = AktSRName # "-" # RVNName;
    }

    !// Unser Skript macht nur Sinn für Modus Heizen
    HSFlag = RVI.StrValueByIndex(";",1);
    if ((HSFlag=="S") || (HSFlag=="V")){
      if(DEBUG)  {WriteLine(RaumLogName # " Kein Heizvorgang");}
      continue;
    }

    !// Räume im Dauerschaltstatus werden ignoriert
    !// 0=Aus, 1=Ein, 2=Dauer AUS, 3=Dauer EIN
    integer aktuellerSchaltZustand = RVI.StrValueByIndex(";",0).ToInteger();
    if ((aktuellerSchaltZustand==3) ||(aktuellerSchaltZustand==2)){
      if(DEBUG)  {WriteLine(RaumLogName # " ist dauerhaft AN/AUS");}
      continue;
    }

    !// Räume merken, die geschaltet werden
    bearbeiteteRaeume = bearbeiteteRaeume # RVN # ";";

    !// Wir benötigen die Ein und Aussschaltzeit frisch, ebenso wie die Wohlfühltemperatur
    EIN = SLEintrag.StrValueByIndex(";",1).ToTime().ToInteger();
    AUS = SLEintrag.StrValueByIndex(";",2).ToTime().ToInteger();
    RTemp = SLEintrag.StrValueByIndex(";",3).ToFloat();

    !// Typ des Aktors bestimmen
    AGF=RVI.StrValueByIndex(";",2);

    !// Verhindern dass Ausschaltpunkt vor Einschaltpunkt liegt
    if((AUS<=EIN) || ((AUS+160)<NOW)){
      if(DEBUG)  {WriteLine(RaumLogName # " Einschaltzeit liegt nach Ausschaltzeit oder Ausschaltzeitpunkt überschritten");}
      continue;
    }

    !// Vorgegebene Temperaur oder Raumtemperatur bestimmen
    if(SDFlag<=0){
      !// Temperaturen individuell bestimmen
      RTemp=RVI.StrValueByIndex(";",3).StrValueByIndex("/",0).ToFloat();
      GT=RVI.StrValueByIndex(";",3).StrValueByIndex("/",1).ToFloat();
      if(GT==0){
        GT=GTStandard;
      }
    }

    !// Daten aus aktueller Raumliste bestimmen. Und die Daten aus der Raumliste entfernen.
    !//   Name
    !//   Messzustand
    !//   Bisherige maximal Temeratur
    if (DEBUG) { WriteLine("RaumListe=" # RaumListe); }
    string RaumParameter="";
    integer iPos = RaumListe.Find("#" # RVN # ";");
    if (iPos>=0){
      strTemp = RaumListe.Substr(iPos+1,RaumListe.Length()-iPos-1);
      integer iPos2 = strTemp.Find("#");
      if (iPos2<0){
        iPos2 = strTemp.Length();
      }
      RaumParameter = strTemp.Substr(0,iPos2);
      !// Alten Wert aus Raumliste entfernen, neuer Wert wird hinten angefügt
      RaumListe = RaumListe.Substr(0,iPos) # strTemp.Substr(iPos2,strTemp.Length()-iPos2);
    }
    if (DEBUG) { WriteLine("RaumListe=" # RaumListe); }
    if (DEBUG) { WriteLine("RaumParameter=" # RaumParameter); }

    !// status bitmap. Diese verhindert, dass ein/aus/Zieltmperatur öfters als einmal
    !// geloggt wird.
    !//   1 bit 0 = Heizung an
    !//   2 bit 1 = Zieltemperatur erreicht
    !//   4 bit 2 = Heizung ausgeschaltet
    !//   8 bit 3 = Hinweis "kein Temperatur-Sensor" bereits geloggt (nur einmal pro Heizphase)
    !//  16 bit 4 = Terminende bereits geloggt

    integer status = RaumParameter.StrValueByIndex(";",1).ToInteger();
    real maxTemperatur = RaumParameter.StrValueByIndex(";",2).ToFloat();

    !// istTemperatur bestimmen, wir benutzen nur den ersten Aktor dafür
    real istTemperatur = GT;
    AktAktor = RVI.StrValueByIndex(";",6);
    if(DEBUG) { WriteLine("AktAktor=" # AktAktor); }
    objAktor = dom.GetObject(AktAktor);
    if (AktAktor && objAktor){
      objDP =  objAktor.DPByHssDP("ACTUAL_TEMPERATURE");
      if (!objDP){
        objDP = objAktor.DPByHssDP("TEMPERATURE");
      }
      if (objDP){
        istTemperatur = objDP.State().ToFloat();
      }
    }else{
      !// Ohne Temperatur-Sensor (Feld 6 der Raumvariable) kann keine Heizkurve protokolliert
      !// werden. Wir unterscheiden "gar nicht konfiguriert" von "konfiguriert, aber nicht vorhanden".
      !// Der Hinweis wird nur einmal pro Heizphase geloggt (Bit 3), sonst liefe das Protokoll
      !// alle 5min voll. Dazu speichern wir den Raum mit gesetztem Bit 3 zurück in die RaumListe.
      if ((status & 8)==0){
        if (AktAktor==""){
          logObj.State          (RaumLogName # ": Kein Temperatur-Sensor konfiguriert (Feld 6 leer) - Heizkurvenkontrolle übersprungen.");
          if(DEBUG) {WriteLine(RaumLogName # ": Kein Temperatur-Sensor konfiguriert (Feld 6 leer) - Heizkurvenkontrolle übersprungen.");}
        }else{
          logObj.State          (RaumLogName # ": Temperatur-Sensor " # AktAktor # " existiert nicht - Heizkurvenkontrolle übersprungen.");
          if(DEBUG) {WriteLine(RaumLogName # ": Temperatur-Sensor " # AktAktor # " existiert nicht - Heizkurvenkontrolle übersprungen.");}
        }
        status = status | 8;
      }
      !// Merker (Bit 3) erhalten, damit der Hinweis nicht bei jedem Lauf erneut kommt.
      RaumListe = RaumListe # "#" # RVN # ";" # status # ";" # maxTemperatur.ToString(1);
      continue;
    }

    !// Neues maximum bestimmen
    maxTemperatur = maxTemperatur.Max(istTemperatur);

    !// Prüfen ob Heizbeginn erkannt wird. Nur wenn bit 0 = aus
    if ((aktuellerSchaltZustand==1) && ((status & 1)==0)){
      !// Sollten wir einen neuen Heizbeginn haben, setzen wir die maxTemperatur wieder auf istTemperatur
      maxTemperatur = istTemperatur;
      !// Heizbeginn erkannt
      strTemp = ((NOW-EIN)/60).ToString();
      if (!strTemp.StartsWith("-")){
        strTemp = "+" # strTemp;
      }
      logObj.State          (RaumLogName # " Heizbeginn: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", AT: " # AT.ToString(1));
      if (DEBUG) { WriteLine(RaumLogName # " Heizbeginn: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", AT: " # AT.ToString(1)); }
      !// bit 0 setzen und bit 2 zurücksetzen
      status = status & 251;
      status = status | 1;
    }

    !// Prüfen ob Heizende erkannt wird. Nur wenn bit 0 = ein und bit 2 = aus
    if ((aktuellerSchaltZustand==0) && ((status & 1)!=0) && ((status & 4)==0)){
      !// Heizbeginn erkannt
      strTemp = ((NOW-EIN)/60).ToString();
      if (!strTemp.StartsWith("-")){
        strTemp = "+" # strTemp;
      }
      logObj.State          (RaumLogName # " Heizende: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", Max.: " # maxTemperatur.ToString(1) # ", AT: " # AT.ToString(1));
      if (DEBUG) { WriteLine(RaumLogName # " Heizende: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", Max.: " # maxTemperatur.ToString(1) # ", AT: " # AT.ToString(1)); }
      !// Bit 0 löschen und bit 2 setzen
      status = status & 254;
      status = status | 4;
    }

    !// Warte auf Zieltemperatur. Nur wenn bit 1 = aus, und Heizphase an oder beendet (bit 0 und 2)
    if (((status & 2)==0) && ((status & 5)!=0)){
      if (istTemperatur>=RTemp){
        !// Zieltemperatur erreicht
        strTemp = ((NOW-EIN)/60).ToString();
        if (!strTemp.StartsWith("-")){
          strTemp = "+" # strTemp;
        }
        logObj.State          (RaumLogName # " Zieltemperatur: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", Max.: " # maxTemperatur.ToString(1) # ", AT: " # AT.ToString(1));
        if (DEBUG) { WriteLine(RaumLogName # " Zieltemperatur: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", Max.: " # maxTemperatur.ToString(1) # ", AT: " # AT.ToString(1)); }
        !// Bit 1 setzen
        status = status | 2;
      }
    }

    !// Der Terminanfang wird 160sec in Zukunft und Vergangenheit (320sec) geprüft. Damit wird ein 5min (300sec) Interval abgedeckt.
    !// Das Skript sollte alle 5min laufen.
    if (((EIN-160)<NOW) && ((EIN+160)>NOW)){
      !// Terminanfang erreicht
      strTemp = ((NOW-EIN)/60).ToString();
      if (!strTemp.StartsWith("-")){
        strTemp = "+" # strTemp;
      }
      logObj.State          (RaumLogName # " Terminbeginn: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", Max.: " # maxTemperatur.ToString(1) # ", AT: " # AT.ToString(1));
      if (DEBUG) { WriteLine(RaumLogName # " Terminbeginn: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", Max.: " # maxTemperatur.ToString(1) # ", AT: " # AT.ToString(1)); }
    }

    !// Der Terminende wird 160sec in Zukunft und Vergangenheit (320sec) geprüft. Damit wird ein 5min (300sec) Interval abgedeckt.
    !// Das Skript sollte alle 5min laufen.
    if(((AUS-160)<NOW) && ((AUS+160)>NOW)){
      !// Terminende erreicht
      strTemp = ((NOW-EIN)/60).ToString();
      if (!strTemp.StartsWith("-")){
        strTemp = "+" # strTemp;
      }
      if ((status & 16)==0){
        logObj.State          (RaumLogName # " Terminende: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", Max.: " # maxTemperatur.ToString(1) # ", AT: " # AT.ToString(1));
        if (DEBUG) { WriteLine(RaumLogName # " Terminende: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", Max.: " # maxTemperatur.ToString(1) # ", AT: " # AT.ToString(1)); }
        status = status | 16;
      }
      !// TT: Zieltemperatur nachholen, falls IST >= ZIEL aber das Event noch nicht geloggt wurde.
      !//     Das passiert, wenn die Zieltemperatur zwischen dem letzten 5-min-Lauf und dem
      !//     Terminende erreicht wurde, oder wenn die Heizung vor Terminende abgeschaltet wurde
      !//     und der Raum danach durch Nachwaerme noch auf ZIEL kam.
      if (((status & 2)==0) && (istTemperatur>=RTemp)){
        logObj.State          (RaumLogName # " Zieltemperatur: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", Max.: " # maxTemperatur.ToString(1) # ", AT: " # AT.ToString(1));
        if (DEBUG) { WriteLine(RaumLogName # " Zieltemperatur: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", Max.: " # maxTemperatur.ToString(1) # ", AT: " # AT.ToString(1)); }
        status = status | 2;
      }
      !// Setze den Status 0, wenn wir wirklich nicht mehr heizen. Andernfalls befinden wir uns schon wieder in
      !// einer neuen Heizphase. Jeder andere Status ist uns egal.
      if (aktuellerSchaltZustand==0){
        !// Wir heizen nicht mehr. Damit vergessen wir alles, weil der Ausschalttermin gefallen ist.
        status = 0;
      }
    }

    !// Wir speichern einen Raum nur, mit dem neuen Status. Wenn er sich nicht in einem unbeheizten Zustand (status==0)
    !// wird das in der nächsten Schleife korrigiert.
    !// Neuen RaumParameter zusammensezen
    RaumParameter = "#" # RVN # ";" # status # ";" # maxTemperatur.ToString(1);
    if (DEBUG) { WriteLine("RaumParameter=" # RaumParameter); }
    RaumListe = RaumListe # RaumParameter;
    if (DEBUG) { WriteLine("RaumListe=" # RaumListe); }
  }
  !// Ende innere Schleife-------------------------------------------
}
!// Ende äußere Schleife---------------------------------------------

if (DEBUG) { WriteLine("----------------------------------------------"); }

!//------------------------------------------------------------------
!// Nun gehen wir nochmal die Raumliste durch und löschen alle 0 Einträge
string neueRaumListe="";
if (DEBUG) { WriteLine("Raumliste=" # RaumListe); }
if (DEBUG) { WriteLine("bearbeiteteRaeume=" # bearbeiteteRaeume); }
foreach(RaumParameter,RaumListe.Split("#")){
  !// Nur wenn der Raum geschaltet wird und auch einen Schaltlisteneintrag hatte
  if ((RaumParameter.StrValueByIndex(";",1).ToInteger()!=0) && bearbeiteteRaeume.Contains(";" # RaumParameter.StrValueByIndex(";",0) # ";")){
    !// Diesen Eintrag übernehmen
    neueRaumListe = neueRaumListe # "#" # RaumParameter;
  }
}
if (DEBUG) { WriteLine("neueRaumliste=" # neueRaumListe); }

!//------------------------------------------------------------------
!// Neue RaumListen Daten speichern
if (objVar.State()!=neueRaumListe){
  objVar.State(neueRaumListe);
  if (RaumListe==""){
    if (DEBUG) { WriteLine("Neue Raumliste: Keine Termine"); }
  }else{
    if (DEBUG) { WriteLine("Neue Raumliste: "+neueRaumListe); }
  }
} else {
  if (DEBUG) { WriteLine("Raumliste unverändert"); }
}

!// -----------------------------------------------------------------

WriteLine("Ende Heizkurvenkontrolle");
