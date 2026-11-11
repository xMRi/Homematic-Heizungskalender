!// Tool zur Kontrolle der Heizkurve
!//================================================================================================
!// Stand:    11.11.2026
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

!// MRi: 2026-11-11 Umstrukturierung der Arbeitsweise auf bleibenden Status und garantierte
!//                 Abarbeitung in zeitlicher Folge.
!// TT:  2026-11-10 Doppel-Termine: Guard auf bearbeiteteRaeume umgestellt (war RaumListe).
!//                 RaumListe-basierter Guard übersprang Räume in Folgeläufen fälschlich,
!//                 weil Bit 0 aus dem letzten Lauf noch gesetzt war. Keine Log-Einträge mehr
!//                 nach Heizbeginn. Fix: nur innerhalb des aktuellen Laufs prüfen.
!// MRi: 2026-11-08 Zieltemperatur erreicht wurde evtl. nicht geloggt.
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
boolean DEBUG=1;

!// Logging in "Log" mit 1 zwingend einschalten oder mit -1 zwingend Ausschalten
!// Mit 0 wird die Einstellung aus der HKx-Logging übernommen.
!// log -1 macht hier keinen Sinn und beendet das Skript.
integer log=0;

!//#######---Ende Variabler Bereich---#############################################################
!//Im Folgenden Hier keine Veränderungen vornehmen!

!//-------------------------------------------------------------
integer NOW=system.Date().ToTime().ToInteger();
string  OffsetAT=dom.GetObject(vrp+"HK2-Kurve").State();
string SListe=dom.GetObject(vrp # "HK2-Schaltliste").State();
string VarNamen=dom.GetObject(vrp+"HK2-HKG-Liste").State();
integer ATG=dom.GetObject(vrp+"HK2-A.Temp.Grenze").State().ToFloat();
boolean Flag_Hand_Temp=dom.GetObject(vrp+"HK2-Hand-Temp").State();
boolean Flag_Hand_Grundtemp=dom.GetObject(vrp+"HK2-Hand-Grundtemp").State();
real AT=dom.GetObject(vrp+"HK2-Aussentemperatur").State().ToFloat();
real GTStandard=dom.GetObject(vrp+"HK2-Grundtemperatur").State().ToFloat();
real GT=GTStandard;
string AktAktor;
object objAktor;
object objDP;

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

!// Schleife über die Schaltliste. ACHTUNG: Das ganzhe kann nur funktionieren, wenn die Schaltliste aufsteigend
!// aufgebaut ist.
string SLEintrag;
if(DEBUG){WriteLine("SListe=" # SListe);}
while(SListe!=""){
  if (DEBUG) { WriteLine("----------------------------------------------"); }

  !// Der nachfolgende Code nimmt den ersten Raum. Dann durchsucht er die Raumliste und bearbeitet
  !// Die Räume in aufsteigender Zeitfolge  
  
  !// Nimm den ersten Raum. Dann suche kleinsten Eintrag.
  SLEintrag = SListe.StrValueByIndex("#",0);
  if (SLEintrag==""){
    break;
  }

  !// Ersten Raumlisteneintrrag als Start nehmen
  string  RVN = SLEintrag.StrValueByIndex(";",0);

  !// Suche ob, es diesen Raum nochmal gibt. Dadurch dass wir mit dem Hashmark suchen,
  !// finden wir nicht den ersten Eintrag.
  string SListe2 = SListe.Substr(SLEintrag.Length()+1);
  integer iPos = ("#" # SListe2).Find("#" # RVN # ";");

  !// Wenn es keinen weiteren Eintrag gibt, nehmen wir diesen
  while (iPos>=0) {
    !// Rest String ab dem zweiten Eintrag nehmmen
    SListe2 = SListe2.Substr(iPos);
    !// Diesen Eintrag nehmen und prüfen ob der Heizbeginn früher liegt
    string SLEintrag2 = SListe2.StrValueByIndex("#",0);

    !// Prüfe und nimm den kleineren Eintrag
    if (SLEintrag.StrValueByIndex(";",4).ToTime().ToInteger()>SLEintrag2.StrValueByIndex(";",4).ToTime().ToInteger()){
      SLEintrag = SLEintrag2;
    }

    !// Nächsten Eintrag suchen
    iPos = SListe2.Find("#" # RVN # ";");
  }

  !// Wir haben nun den kleinsten Schaltlisten Eintrag für diesen Raum.
  !// Den entfernen wir nun aus der Schaltliste, weil wir ihn behandelt haben
  iPos = ("#" # SListe).Find("#" # SLEintrag # "#");
  if (iPos<0){
    if(DEBUG){WriteLine("Fataler Fehler. Heizlisteneintrag konnte nicht gefunden werden!");}
    quit;
  }
  !// Entferne ab der Position inkl. # Zeichen
  SListe = SListe.Substr(0,iPos) # SListe.Substr(iPos+SLEintrag.Length()+1);

  !// Diesen Eintrag nun bearbeiten
  if(DEBUG){WriteLine("SLEintrag=" # SLEintrag);}
  if (SLEintrag=="")
  {
    continue;
  }

  !// Schaltlistenelement auslesen
  !// Parameter für aktuellen Schaltvorgang. 
  string  RVN         = SLEintrag.StrValueByIndex(";",0);
  integer EIN_Termin  = SLEintrag.StrValueByIndex(";",1).ToTime().ToInteger();
  integer AUS_Termin  = SLEintrag.StrValueByIndex(";",2).ToTime().ToInteger();
  integer SDFlag      = SLEintrag.StrValueByIndex(";",3).ToInteger();
  real    RTemp       = SLEintrag.StrValueByIndex(";",3).ToFloat();
  integer EIN         = SLEintrag.StrValueByIndex(";",4).ToTime().ToInteger();
  integer AUS         = SLEintrag.StrValueByIndex(";",5).ToTime().ToInteger();

  !´// Raumbestimmen
  if(DEBUG){WriteLine("RVN=" # RVN);}
  string RVI=dom.GetObject(RVN).State();
  if(DEBUG){WriteLine("RVI=" # RVI);}

  !// Erzeuge einen Namen ohne prefixe
  string RVNName = RVN.Replace(vrp#"HKG-Raum-","");
  if(DEBUG)  {WriteLine("RVNName=" # RVNName);}
  
  !// Anzeigename fuers Log.
  string RaumLogName = RVNName # " - ";

  !// Unser Skript macht nur Sinn für Modus Heizen
  string HSFlag = RVI.StrValueByIndex(";",1);
  if ((HSFlag=="S") || (HSFlag=="V")){
    if(DEBUG)  {WriteLine(RaumLogName # " Kein Heizvorgang");}
    continue;
  }
  
  if (SDFlag<0){
    !// Sollte es eine Dauerschaltung sein, ignorieren wir diesen Eintrag
    if(DEBUG)  {WriteLine(RaumLogName # " Dauerschaltungen werden nicht behandelt");}
    continue;
  }
  
  !// Sollte der Termin weit in der Zukunft liegen warten wir noch.
  if (NOW<EIN) {
    !// Termine in der Zukunft überspringen
    if(DEBUG)  {WriteLine(RaumLogName # " Heizbeginn liegt in derZukunft");}
    continue;
  }
  

  !// Räume im Dauerschaltstatus werden ignoriert
  !// 0=Aus, 1=Ein, 2=Dauer AUS, 3=Dauer EIN
  integer aktuellerSchaltZustand = RVI.StrValueByIndex(";",0).ToInteger();
  if ((aktuellerSchaltZustand==3) ||(aktuellerSchaltZustand==2)){
    if(DEBUG)  {WriteLine(RaumLogName # " ist dauerhaft AN/AUS");}
    continue;
  }

  !// Daten aus aktueller Raumliste bestimmen. Und die Daten aus der Raumliste entfernen.
  !//   0. Name
  !//   1. Messzustand
  !//   2. Bisherige maximal Temeratur
  if (DEBUG) { WriteLine("RaumListe=" # RaumListe); }
  string strTemp;
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
  !// Im wechsel der Zustände werden mehr und mehr Bits gesetzt.
  !//   1 bit 0 = Heizung an
  !//   2 bit 1 = Zieltemperatur erreicht
  !//   4 bit 2 = Heizung ausgeschaltet
  !//   8 bit 3 = Hinweis "kein Temperatur-Sensor" bereits geloggt (nur einmal pro Heizphase)
  !//  16 bit 4 = Terminende bereits geloggt
  !//  32 bit 5 = Terminbeginn bereits geloggt  
  integer status = RaumParameter.StrValueByIndex(";",1).ToInteger();
  real maxTemperatur = RaumParameter.StrValueByIndex(";",2).ToFloat();

  !// Raum wurde im aktuellen Lauf schon verarbeitet. Wir behandeln diesen Termin nur, wenn der erste Termin bereits 
  !// im Heizende Zustand ist. Ansonsten warten wir bis der Heizende Zustand eintritt. Ab dem Moment kann
  !// ein neuer Heizvorgang starten.
  if (bearbeiteteRaeume.Contains(";" # RVN # ";") && (RaumListe!="")){
    !// Wir schauen nun im bisherigen Zustand, ob wir das Heizende erreicht haben, wenn 
    !// nicht überspringen wir den nächsten Eintrag, bis das Heizende, des aktuellen 
    !// Schaltlisteneintrag, den wir schon behandelt haben erreicht ist
    if ((status & 4)==0) {
      if(DEBUG) {WriteLine(RaumLogName # " Späterer Termin wird übersprungen, Raum wurde in diesem Lauf bereits verarbeitet und ist nicht am Heizende!");}
      continue;
    }else{
      if(DEBUG) {WriteLine(RaumLogName # " neuer Heizlisteneintrag wird bearbeitet, da das Heizende erreicht wurde!");}
    }   
  } else {
    !// Räume merken, die geschaltet werden. 
    bearbeiteteRaeume = bearbeiteteRaeume # RVN # ";";
  }

  !// Vorgegebene Temperaur oder Raumtemperatur bestimmen
  if(SDFlag<=0){
    !// Temperaturen individuell bestimmen
    RTemp=RVI.StrValueByIndex(";",3).StrValueByIndex("/",0).ToFloat();
  }
  
  !// Grundtemperatur bestimmen
  GT=RVI.StrValueByIndex(";",3).StrValueByIndex("/",1).ToFloat();
  if(GT==0){
    GT=GTStandard;
  }

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
        logObj.State        (RaumLogName # ": Kein Temperatur-Sensor konfiguriert (Feld 6 leer) - Heizkurvenkontrolle übersprungen.");
        if(DEBUG) {WriteLine(RaumLogName # ": Kein Temperatur-Sensor konfiguriert (Feld 6 leer) - Heizkurvenkontrolle übersprungen.");}
      }else{
        logObj.State        (RaumLogName # ": Temperatur-Sensor " # AktAktor # " existiert nicht - Heizkurvenkontrolle übersprungen.");
        if(DEBUG) {WriteLine(RaumLogName # ": Temperatur-Sensor " # AktAktor # " existiert nicht - Heizkurvenkontrolle übersprungen.");}
      }
      !// setzt Bit 3 (kein Temperatur-Sensor vorhande)
      status = status | 8;
    }
    !// Merker (Bit 3) erhalten, damit der Hinweis nicht bei jedem Lauf erneut kommt.
    RaumListe = RaumListe # "#" # RVN # ";" # status # ";" # maxTemperatur.ToString(1);
    continue;
  }

  !// Neues maximum bestimmen
  maxTemperatur = maxTemperatur.Max(istTemperatur);
  if (DEBUG) { WriteLine("maxTemperatur =" # maxTemperatur.ToString(1) #  " istTemperatur=" # istTemperatur.ToString(1)); }
  
  !// Prüfen ob Heizbeginn erkannt wird. Nur wenn bit 0 = aus
  if ((aktuellerSchaltZustand==1) && ((status & 1)==0)){
    !// Sollten wir einen neuen Heizbeginn haben, setzen wir die maxTemperatur wieder auf istTemperatur
    maxTemperatur = istTemperatur;
    !// Heizbeginn erkannt
    strTemp = ((NOW-EIN_Termin)/60).ToString();
    if (!strTemp.StartsWith("-")){
      strTemp = "+" # strTemp;
    }
    logObj.State          (RaumLogName # " Heizbeginn: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", AT: " # AT.ToString(1));
    if (DEBUG) { WriteLine(RaumLogName # " Heizbeginn: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", AT: " # AT.ToString(1)); }
    !// setzt Bit 0 (Heizvorgang), löscht alle anderen Zustände
    status =  1;     
  }

  !// Prüfen ob Heizende erkannt wird. Nur wenn bit 0 = ein und bit 2 = aus.
  !// Also Heizen wurde gestartet und Heizende noch nicht geloggt
  if ((aktuellerSchaltZustand==0) && ((status & 1)!=0) && ((status & 4)==0)){
    !// Heizende erkannt
    strTemp = ((NOW-EIN_Termin)/60).ToString();
    if (!strTemp.StartsWith("-")){
      strTemp = "+" # strTemp;
    }
    logObj.State          (RaumLogName # " Heizende: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", Max.: " # maxTemperatur.ToString(1) # ", AT: " # AT.ToString(1));
    if (DEBUG) { WriteLine(RaumLogName # " Heizende: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", Max.: " # maxTemperatur.ToString(1) # ", AT: " # AT.ToString(1)); }
    !// setzt Bit 2 (Heizung ausgeschaltet)
    status = status | 4;    
  }

  !// Warte auf Zieltemperatur. Nur wenn bit 1 = aus und Terminende noch nicht erreicht
  if (((status & 2)==0) && ((status & 16)==0) && (istTemperatur>=RTemp)) {
    !// Zieltemperatur erreicht
    strTemp = ((NOW-EIN_Termin)/60).ToString();
    if (!strTemp.StartsWith("-")){
      strTemp = "+" # strTemp;
    }
    logObj.State          (RaumLogName # " Zieltemperatur: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", Max.: " # maxTemperatur.ToString(1) # ", AT: " # AT.ToString(1));
    if (DEBUG) { WriteLine(RaumLogName # " Zieltemperatur: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", Max.: " # maxTemperatur.ToString(1) # ", AT: " # AT.ToString(1)); }
    !// Setzt Bit 1 (Zieltemperatur erreicht)
    status = status | 2;  
  }

  !// Der Terminanfang wird geprüft und genau einmal geloggt (Bit 5)
  if (((status & 32)==0) && (EIN_Termin<=NOW) && (NOW<=AUS_Termin)){
    !// Terminanfang erreicht
    strTemp = ((NOW-EIN_Termin)/60).ToString();
    if (!strTemp.StartsWith("-")){
      strTemp = "+" # strTemp;
    }
    logObj.State          (RaumLogName # " Terminbeginn: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", Max.: " # maxTemperatur.ToString(1) # ", AT: " # AT.ToString(1));
    if (DEBUG) { WriteLine(RaumLogName # " Terminbeginn: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", Max.: " # maxTemperatur.ToString(1) # ", AT: " # AT.ToString(1)); }
    !// Setzt Bit 5 (Terminanfang geloggt)
    status = status | 32;   
  }

  !// Der Terminende prüfen
  if(((status & 16)==0) && (AUS_Termin<=NOW)){
    !// Terminende erreicht
    strTemp = ((NOW-EIN_Termin)/60).ToString();
    if (!strTemp.StartsWith("-")){
      strTemp = "+" # strTemp;
    }
    logObj.State          (RaumLogName # " Terminende: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", Max.: " # maxTemperatur.ToString(1) # ", AT: " # AT.ToString(1));
    if (DEBUG) { WriteLine(RaumLogName # " Terminende: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", Max.: " # maxTemperatur.ToString(1) # ", AT: " # AT.ToString(1)); }
    !// Setzt Bit 4 (Terminende geloggt)
    status = status | 16; 
  }

  !// Wir speichern einen Raum nur, mit dem neuen Status. Wenn er sich nicht in einem unbeheizten Zustand (status==0)
  !// wird das in der nächsten Schleife korrigiert.
  !// Neuen RaumParameter zusammensezen
  RaumParameter = "#" # RVN # ";" # status # ";" # maxTemperatur.ToString(1);
  if (DEBUG) { WriteLine("RaumParameter=" # RaumParameter); }
  RaumListe = RaumListe # RaumParameter;
  if (DEBUG) { WriteLine("RaumListe=" # RaumListe); }
}

if (DEBUG) { WriteLine("----------------------------------------------"); }

!//------------------------------------------------------------------
!// Nun gehen wir nochmal die Raumliste durch und löschen alle Einträge, die nicht mehr in 
!// der Schaltliste vorhanden sind.
string neueRaumListe="";
if (DEBUG) { WriteLine("Raumliste=" # RaumListe); }
if (DEBUG) { WriteLine("bearbeiteteRaeume=" # bearbeiteteRaeume); }
foreach(RaumParameter,RaumListe.Split("#")){
  !// Wenn kein Schaltlisteneintrag da war löschen wir den Eintrag weil er nicht mehr benötigt wird.
  if (bearbeiteteRaeume.Contains(";" # RaumParameter.StrValueByIndex(";",0) # ";")){
    !// Diesen Eintrag übernehmen. Wir haben ihn behandelt.
    neueRaumListe = neueRaumListe # "#" # RaumParameter;
  }
}
if (DEBUG) { WriteLine("neueRaumliste=" # neueRaumListe); }

!//------------------------------------------------------------------
!// Neue RaumListen Daten speichern
if (objVar.State()!=neueRaumListe){
  !// objVar.State(neueRaumListe);
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
