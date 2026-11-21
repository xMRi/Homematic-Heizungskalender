!// Tool zur Kontrolle der Heizkurve
!//================================================================================================
!// Stand:    22.11.2026
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

!// MRi: 2026-11-22 Einfachere Ermittlung, des aktuellen Termines
!// MRi: 2026-11-21 Wenn ein Termin in der AUS Pahse ist, darf er für einen Heizbeginn nicht 
!//                 berücksichtigt werden. Er gehört vermutlich zu einem späteren SLListen Eintrag.
!// TT:  2026-11-15 ATLog-Format vereinfacht: kein °C-Suffix (war "[akt X.X°C]", neu "[Akt: X.X]").
!// TT:  2026-11-14 ATLog-Format: eckige Klammern statt runde (war "(akt=X.X)", neu "[akt X.X°C]").
!// TT:  2026-11-13 Überlappende Termine: ausTerminMax (Feld 3 in RaumParameter) trackt das
!//                 Maximum aller AUS_Termin-Werte. Terminende und Zieltemperatur-Guard nutzen
!//                 ausTerminMax statt AUS_Termin des ersten Eintrags.
!//                 Bugfix: RaumParameter wird im bearbeiteteRaeume-Guard zurückgespeichert —
!//                 verhindert Datenverlust und falsches Heizbeginn bei 3+ überlappenden Einträgen.
!//                 Bugfix Finding 1: abschliessendes # in SListe-Suche ergaenzt (letzter Eintrag).
!//                 Bugfix Finding 2: Null-Check fuer dom.GetObject(RVN) ergaenzt (continue).
!//                 Bugfix Finding 3: status-Reset auf (status & 32) bei neuem Heizvorgang.
!//                 Bugfix Finding 4: Bit-0-Guard bei Zieltemperatur-Pruefung ergaenzt.
!//                 ATLog: akt= auf eine Dezimalstelle formatiert (war roher CCU-Float).
!//                 AT-Logausgabe: AT mit optionaler aktueller Temperatur.
!// TT:  2026-11-13 Bereinigungsblock loggt "Termin entfernt", wenn ein Raum während einer aktiven
!//                 Heizphase aus der Schaltliste gelöscht wurde (Bit 0 gesetzt, Bit 4 nicht).
!// TT:  2026-11-12 Code-Review: Tippfehler behoben, ungenutzte Variablen entfernt,
!//                 vrp+ auf vrp# korrigiert, Guard RaumListe!="" auf RaumParameter!=""
!//                 umgestellt, Heizbeginn-Reset erhält Bit 5, Union-Wert Feld 3 dokumentiert.
!// MRi: 2026-11-12 Ablaufen der HK2-Schaltliste führte zu Fehler.
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
boolean DEBUG=0;

!// Logging in "Log" mit 1 zwingend einschalten oder mit -1 zwingend Ausschalten
!// Mit 0 wird die Einstellung aus der HKx-Logging übernommen.
!// log -1 macht hier keinen Sinn und beendet das Skript.
integer log=0;

!//#######---Ende Variabler Bereich---#############################################################
!//Im Folgenden Hier keine Veränderungen vornehmen!

!//-------------------------------------------------------------
integer NOW=system.Date().ToTime().ToInteger();
string SListe=dom.GetObject(vrp # "HK2-Schaltliste").State();
string VarNamen=dom.GetObject(vrp # "HK2-HKG-Liste").State();
real ATDurchschnitt=dom.GetObject(vrp # "HK2-Aussentemperatur").State().ToFloat();
real AT=ATDurchschnitt;
!// ATLog zeigt den Durchschnitt und optional die aktuelle AT.
!// Format: "4.1 [Akt: 8.8]" oder nur "4.1" ohne Variable.
string ATLog = AT.ToString(1);
var svATAkt = dom.GetObject(vrp # "HK2-Aussentemperatur-Aktuell");
if (svATAkt) { ATLog = ATLog # " [Akt: " # svATAkt.State().ToFloat().ToString(1) # "]"; }
real GTStandard=dom.GetObject(vrp # "HK2-Grundtemperatur").State().ToFloat();
real GT=GTStandard;
string AktAktor;
object objAktor;
object objDP;

!// Logging bestimmen
var logObj=dom.GetObject(vrp # "HK-LogHeizkurvenkontrolle");
var loggingObj=dom.GetObject(vrp # "HK-LoggingHeizkurvenkontrolle");

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
  !// Ohne logging macht das keinen Sinn
  if(DEBUG)  {WriteLine("Logging ist nicht aktiviert. Abbruch!!!");}
  quit;
}

!// Dazu benötigen wir auch eine Variable, in der wie zu den Räumen, den jeweiligen
!// Status und die maximale Temperatur speichern.

var objVar=dom.GetObject(vrp # "HK-RäumeHeizkurvenkontrolle");
if (!objVar){
  if(DEBUG)  {WriteLine("HK-RäumeHeizkurvenkontrolle ist nicht vorhanden. Abbruch!!!");}
  quit;
}
string RaumListe = objVar.State();
string bearbeiteteRaeume=";";

!// Baue eine simple Namensliste aus den HK2-HKG-Liste. Wir entfernen Prefix und im multiraum Fall auch die anderen Räume
!// Aus HKG-Raum-GrSaal, wird GrSaal. Aus HKG-Foyer wird Foyer
WriteLine("Beginn Heizkurvenkontrolle");
if(DEBUG)  {WriteLine("Vollständige Raumliste: "+VarNamen);}

!// Schleife über die Schaltliste.
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
  string RVN = SLEintrag.StrValueByIndex(";",0);
  if(DEBUG){WriteLine("RVN=" # RVN);}

  !// Wir merken und den aktuellen Termin.
  !// 1. Liegt AUS in der Vergangenheit, dann ist es der Termin mit dem größten AUS. A^lso
  !//    der Termin der am nähesten an NOW liegt.
  !// 2. Liegt EIN in der Vergangebnheit und AUS in der Zukunft ist es der Termin mit dem kleinsten 
  !//    EIN. D.h. der Termin, der schon am längsten im System liegt
  !// Nur dieser Termin muss behandelt werden. Alle anderen Termine sind nicht relevant.
  !// Jeder Raum wird damit immer nur einmal hier behandelt, mit einem relevanten Termin.
  string SLEintrag = "";

  !// Wir arbeiten jetzt alle Einträge zu diesem einen speziellen Raum ab und versuchen
  !// den aktuellen Termin zu finden, der aktuell relevant ist.
  while (true){
    !// Suche ob, es diesen Raum nochmal gibt. Dadurch dass wir mit dem Hashmark suchen,
    !// finden wir nicht den ersten Eintrag.
    integer iPos = ("#" # SListe).Find("#" # RVN # ";");
    if (iPos<0){
      !// wir haben keinen Eintrag mehr für diesen Raum.
      break;
    }

    !// Wenn es keinen weiteren kleineren Eintrag gibt, nehmen wir diesen
    while (iPos>=0){
      !// Rest String ab dem zweiten Eintrag nehmen
      string SListe2 = SListe.Substr(iPos);

      !// Diesen gefundenen Eintrag für den Raum RVN prüfen
      string SLEintrag2 = SListe2.StrValueByIndex("#",0);
      
      !// Diesen Eintrag suchen wirt nun in der Schaltliste, weil wir ihn behandeln.
      !// Abschliessendes # noetig damit auch der letzte Eintrag (ohne nachfolgendes #) gefunden wird
      iPos = ("#" # SListe # "#").Find("#" # SLEintrag2 # "#");
      if (iPos<0){
        if(DEBUG){WriteLine("Fataler Fehler. Heizlisteneintrag konnte nicht gefunden werden!");}
        quit;
      }

      !WriteLine("SLEintrag    =" # SLEintrag);
      !WriteLine("SLEintrag2   =" # SLEintrag2);

      !// Was haben wir bisher? Kein Eintrag, dann nehmen wir den ersten
      if (SLEintrag==""){
        !// Dies ist der erste Eintrag, Termine in der Zukunft werden später ignoriert
        SLEintrag = SLEintrag2;
      }else{
        !// Liegt der AUS Termin in der Vergangenheit, nehmen wir den größten
        !// In der EIN-Phase nehmen wir den der am ältesten ist.
        integer EIN1 = SLEintrag.StrValueByIndex(";",4).ToTime().ToInteger();
        integer AUS1 = SLEintrag.StrValueByIndex(";",5).ToTime().ToInteger();
        integer EIN2 = SLEintrag2.StrValueByIndex(";",4).ToTime().ToInteger();
        integer AUS2 = SLEintrag2.StrValueByIndex(";",5).ToTime().ToInteger();

        !// aktuellen Termin prüfen
        if(NOW<EIN1){
          !// Der aktuelle Termin liegt in der Zukunft, wir nehmen immer den Neuen
          !// Der evtl. auch in der Zukunft liegt. Ist egal. Termine in der Zukunft
          !// werden später sowieso ignoriert
          SLEintrag = SLEintrag2;
        }elseif(NOW<EIN2){
          !// Der neue Termin liegt in der Zukunft, wir ignorieren ihn
        }elseif((EIN1<=NOW) && (NOW<=AUS1)){
          !// Der aktuelle Termin ist in der EIN Phase ist
          if ((EIN2<=NOW) && (NOW<=AUS2)){
            !// Der zweite Termin auch in der EIN-Phase?
            !// Anderfalls ist der zweite Termin ist in der AUS Phase oder in der Zukunft, also bleibenden
            !// wir bei dem alten SLEintrag
            if (EIN2<EIN1){
              !// Wir nehmen den ältesten Termin
              SLEintrag = SLEintrag2;
            }
          }
        }else{
          !// Der erste Termin ist in der AUS-Phase. Der neue Termin muss alt sein oder EIN.
          !// Liegt der zweite Termin in der EIN-Phase nehmen wir den.
          if ((EIN2<=NOW) && (NOW<=AUS2)){
            !// Der neue Termin ist in der EIN-Phase, wir nehmen den
            SLEintrag = SLEintrag2;
          }elseif(AUS1<AUS2){
            !// Beide Termine liegen in der AUS-Phase wir nehmen den der näher an NOW Liegt
            SLEintrag = SLEintrag2;
          }
        }
      }
      !WriteLine("SLEintrag neu=" # SLEintrag);

      !// Entferne den bearbeiteten Eintrag ab der Position inkl. # Zeichen
      SListe = SListe.Substr(0,iPos) # SListe.Substr(iPos+SLEintrag2.Length()+1);

      !// Nächsten Eintrag für diesen Raum suchen. Wir durchsuchen den Rest der Liste.
      !// Der behandelte Eintrag wurde ja entfernt.
      iPos = ("#" # SListe).Find("#" # RVN # ";");
    }
  }

  !// Diesen Eintrag nun bearbeiten
  if(DEBUG){WriteLine("SLEintrag=" # SLEintrag);}
  if (SLEintrag==""){
    continue;
  }

  !// Schaltlistenelement auslesen
  !// Parameter für aktuellen Schaltvorgang.
  string  RVN         = SLEintrag.StrValueByIndex(";",0);
  integer EIN_Termin  = SLEintrag.StrValueByIndex(";",1).ToTime().ToInteger();
  integer AUS_Termin  = SLEintrag.StrValueByIndex(";",2).ToTime().ToInteger();
  !// Feld 3 ist ein Union-Wert: negativ = Dauerschaltung (Flag), >= 0 = Solltemperatur in °C.
  !// SDFlag prüft den Typ, RTemp liest den Temperaturwert. RTemp ist nur gültig wenn SDFlag >= 0.
  integer SDFlag      = SLEintrag.StrValueByIndex(";",3).ToInteger();
  real    RTemp       = SLEintrag.StrValueByIndex(";",3).ToFloat();
  integer EIN         = SLEintrag.StrValueByIndex(";",4).ToTime().ToInteger();
  integer AUS         = SLEintrag.StrValueByIndex(";",5).ToTime().ToInteger();

  !// Raumbestimmen
  object objRVN = dom.GetObject(RVN);
  if (!objRVN){
    if(log){logObj.State("Raumvariable " # RVN # " wurde nicht gefunden!");}
    if(DEBUG){WriteLine("Raumvariable " # RVN # " wurde nicht gefunden!");}
    continue;
  }
  string RVI=objRVN.State();
  if(DEBUG){WriteLine("RVI=" # RVI);}

  !// Erzeuge einen Namen ohne prefixe
  string RVNName = RVN.Replace(vrp#"HKG-Raum-","");
  if(DEBUG)  {WriteLine("RVNName=" # RVNName);}

  !// Anzeigename fuers Log.
  string RaumLogName = RVNName # " - ";

  !// Unser Skript macht nur Sinn für Modus Heizen
  string HSFlag = RVI.StrValueByIndex(";",1);
  if ((HSFlag=="S") || (HSFlag=="V")){
    if(DEBUG)  {WriteLine(RaumLogName # "Kein Heizvorgang");}
    continue;
  }

  if (SDFlag<0){
    !// Sollte es eine Dauerschaltung sein, ignorieren wir diesen Eintrag
    if(DEBUG)  {WriteLine(RaumLogName # "Dauerschaltungen werden nicht behandelt");}
    continue;
  }

  !// Sollte der Termin weit in der Zukunft liegen warten wir noch.
  if (NOW<EIN) {
    !// Termine in der Zukunft überspringen
    if(DEBUG)  {WriteLine(RaumLogName # "Heizbeginn liegt in der Zukunft");}
    continue;
  }

  !// Räume im Dauerschaltstatus werden ignoriert
  !// 0=Aus, 1=Ein, 2=Dauer AUS, 3=Dauer EIN
  integer aktuellerSchaltZustand = RVI.StrValueByIndex(";",0).ToInteger();
  if ((aktuellerSchaltZustand==3) || (aktuellerSchaltZustand==2)){
    if(DEBUG)  {WriteLine(RaumLogName # "ist dauerhaft AN/AUS");}
    continue;
  }
  if(DEBUG)  {WriteLine(RaumLogName # "aktuellerSchaltZustand=" # aktuellerSchaltZustand);}

  !// Daten aus aktueller Raumliste bestimmen. Und die Daten aus der Raumliste entfernen.
  !//   0. Name (RVN)
  !//   1. Messzustand (status bitmap)
  !//   2. Bisherige maximale Temperatur
  !//   3. ausTerminMax — maximaler AUS_Termin über alle überlappenden Einträge (integer, optional)
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

  !// status bitmap. Diese verhindert, dass ein/aus/Zieltemperatur öfters als einmal
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
  !// Maximaler AUS_Termin über alle überlappenden Einträge dieses Raums (Feld 3).
  !// Rückwärtskompatibel: bei alten Daten ohne Feld 3 ergibt ToInteger() 0.
  integer ausTerminMax = RaumParameter.StrValueByIndex(";",3).ToInteger();

  !// AUS_Termin des aktuellen Eintrags berücksichtigen (für überlappende Termine)
  if (AUS_Termin > ausTerminMax) {
    ausTerminMax = AUS_Termin;
  }

  !// Raum wurde im aktuellen Lauf schon verarbeitet. Wir behandeln diesen Termin nur, wenn der erste Termin bereits
  !// im Heizende Zustand ist. Ansonsten warten wir bis der Heizende Zustand eintritt. Ab dem Moment kann
  !// ein neuer Heizvorgang starten.
  if (bearbeiteteRaeume.Contains(";" # RVN # ";") && (RaumParameter!="")){
    !// Wir schauen nun im bisherigen Zustand, ob wir das Heizende erreicht haben, wenn
    !// nicht überspringen wir den nächsten Eintrag, bis das Heizende, des aktuellen
    !// Schaltlisteneintrag, den wir schon behandelt haben erreicht ist
    if ((status & 4)==0) {
      if(DEBUG) {WriteLine(RaumLogName # "Späterer Termin wird übersprungen, Raum wurde in diesem Lauf bereits verarbeitet und ist nicht am Heizende!");}
      !// RaumParameter zurückspeichern — ohne dieses Save geht er beim continue verloren
      !// und ein dritter überlappender Eintrag würde fälschlich ein neues Heizbeginn starten.
      RaumListe = RaumListe # "#" # RVN # ";" # status # ";" # maxTemperatur.ToString(1) # ";" # ausTerminMax;
      continue;
    }else{
      if(DEBUG) {WriteLine(RaumLogName # "neuer Heizlisteneintrag wird bearbeitet, da das Heizende erreicht wurde!");}
      !// Bits des abgeschlossenen Heizvorgangs zuruecksetzen, damit Heizbeginn des neuen Eintrags
      !// geloggt wird. Bit 5 (Terminbeginn) bleibt erhalten, damit er nicht doppelt geloggt wird.
      status = (status & 32);
    }
  }

  !// Vorgegebene Temperatur oder Raumtemperatur bestimmen
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
        logObj.State        (RaumLogName # "Fehler: Kein Temperatur-Sensor konfiguriert (Feld 6 leer) - Heizkurvenkontrolle übersprungen.");
        if(DEBUG) {WriteLine(RaumLogName # "Fehler: Kein Temperatur-Sensor konfiguriert (Feld 6 leer) - Heizkurvenkontrolle übersprungen.");}
      }else{
        logObj.State        (RaumLogName # "Fehler: Temperatur-Sensor " # AktAktor # " existiert nicht - Heizkurvenkontrolle übersprungen.");
        if(DEBUG) {WriteLine(RaumLogName # "Fehler: Temperatur-Sensor " # AktAktor # " existiert nicht - Heizkurvenkontrolle übersprungen.");}
      }
      !// setzt Bit 3 (kein Temperatur-Sensor vorhanden)
      status = status | 8;
    }

    !// Räume merken, die wir bearbeitet haben.
    bearbeiteteRaeume = bearbeiteteRaeume # RVN # ";";
    !// Merker (Bit 3) erhalten, damit der Hinweis nicht bei jedem Lauf erneut kommt.
    RaumListe = RaumListe # "#" # RVN # ";" # status # ";" # maxTemperatur.ToString(1) # ";" # ausTerminMax;
    continue;
  }

  !// Neues maximum bestimmen
  maxTemperatur = maxTemperatur.Max(istTemperatur);
  if (DEBUG) { WriteLine("maxTemperatur =" # maxTemperatur.ToString(1) #  " istTemperatur=" # istTemperatur.ToString(1)); }

  !// Prüfen ob Heizbeginn erkannt wird. Nur wenn bit 0 = aus.
  if ((aktuellerSchaltZustand==1) && ((status & 1)==0)){
    !// Die Heizung ist an. Wir prüfen ob dieser Schaltlisteneintrag zu einem alten Termin gerhört, dessen Ausschalttermin schon
    !// erreicht wurde: Da die  Heizung an ist, muss jemand anderes (vermutlich ein späterer Termin) diesen Eintrag geschaltet
    !// haben. Wir bearbeiten diesen Eintrag nicht!
    if (AUS<NOW){
      if (DEBUG) { WriteLine(RaumLogName # " ist bereits in der AUS-Phase, aber Heizung ist an. Es muss noch einen späteren Termin geben, der dies ausgelöst hat!"); }
      continue;
    }
    !// Sollten wir einen neuen Heizbeginn haben, setzen wir die maxTemperatur wieder auf istTemperatur
    maxTemperatur = istTemperatur;
    !// Heizbeginn erkannt
    strTemp = ((NOW-EIN_Termin)/60).ToString();
    if (!strTemp.StartsWith("-")){
      strTemp = "+" # strTemp;
    }
    logObj.State          (RaumLogName # "Heizbeginn: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", AT: " # ATLog);
    if (DEBUG) { WriteLine(RaumLogName # "Heizbeginn: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", AT: " # ATLog); }
    !// setzt Bit 0 (Heizvorgang), löscht alle anderen Zustände außer Bit 5 (Terminbeginn bereits geloggt)
    status = 1 | (status & 32);
  }

  !// Prüfen ob Heizende erkannt wird. Nur wenn bit 0 = ein und bit 2 = aus.
  !// Also Heizen wurde gestartet und Heizende noch nicht geloggt
  if ((aktuellerSchaltZustand==0) && ((status & 1)!=0) && ((status & 4)==0)){
    !// Heizende erkannt
    strTemp = ((NOW-EIN_Termin)/60).ToString();
    if (!strTemp.StartsWith("-")){
      strTemp = "+" # strTemp;
    }
    logObj.State          (RaumLogName # "Heizende: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", Max.: " # maxTemperatur.ToString(1) # ", AT: " # ATLog);
    if (DEBUG) { WriteLine(RaumLogName # "Heizende: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", Max.: " # maxTemperatur.ToString(1) # ", AT: " # ATLog); }
    !// setzt Bit 2 (Heizung ausgeschaltet)
    status = status | 4;
  }

  !// Warte auf Zieltemperatur. Nur wenn bit 0 = ein, bit 1 = aus und Terminende noch nicht erreicht
  if (((status & 1)!=0) && ((status & 2)==0) && ((status & 16)==0) && (istTemperatur>=RTemp)) {
    !// Zieltemperatur erreicht
    strTemp = ((NOW-EIN_Termin)/60).ToString();
    if (!strTemp.StartsWith("-")){
      strTemp = "+" # strTemp;
    }
    logObj.State          (RaumLogName # "Zieltemperatur: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", Max.: " # maxTemperatur.ToString(1) # ", AT: " # ATLog);
    if (DEBUG) { WriteLine(RaumLogName # "Zieltemperatur: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", Max.: " # maxTemperatur.ToString(1) # ", AT: " # ATLog); }
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
    logObj.State          (RaumLogName # "Terminbeginn: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", Max.: " # maxTemperatur.ToString(1) # ", AT: " # ATLog);
    if (DEBUG) { WriteLine(RaumLogName # "Terminbeginn: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", Max.: " # maxTemperatur.ToString(1) # ", AT: " # ATLog); }
    !// Setzt Bit 5 (Terminanfang geloggt)
    status = status | 32;
  }

  !// Der Terminende prüfen (ausTerminMax statt AUS_Termin: bei überlappenden Terminen
  !// zählt das Ende des letzten Termins, damit Zieltemperatur nicht zu früh blockiert wird)
  if(((status & 16)==0) && (ausTerminMax<=NOW)){
    !// Terminende erreicht
    strTemp = ((NOW-EIN_Termin)/60).ToString();
    if (!strTemp.StartsWith("-")){
      strTemp = "+" # strTemp;
    }
    logObj.State          (RaumLogName # "Terminende: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", Max.: " # maxTemperatur.ToString(1) # ", AT: " # ATLog);
    if (DEBUG) { WriteLine(RaumLogName # "Terminende: " # strTemp # "min, Ist: " # istTemperatur.ToString(1) # ", Ziel: " # RTemp.ToString(1) # ", Max.: " # maxTemperatur.ToString(1) # ", AT: " # ATLog); }
    !// Setzt Bit 4 (Terminende geloggt)
    status = status | 16;
  }

  !// Wir speichern einen Raum nur, mit dem neuen Status. Wenn er sich nicht in einem unbeheizten Zustand (status==0)
  !// wird das in der nächsten Schleife korrigiert.
  !// Neuen RaumParameter zusammensetzen (Feld 3: ausTerminMax für überlappende Termine)
  RaumParameter = "#" # RVN # ";" # status # ";" # maxTemperatur.ToString(1) # ";" # ausTerminMax;
  if (DEBUG) { WriteLine("RaumParameter=" # RaumParameter); }
  RaumListe = RaumListe # RaumParameter;
  if (DEBUG) { WriteLine("RaumListe=" # RaumListe); }

  !// Räume merken, die wir bearbeitet haben.
  bearbeiteteRaeume = bearbeiteteRaeume # RVN # ";";
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
  } else {
    !// Raum ist aus der Schaltliste gelöscht worden.
    !// Wenn Heizphase aktiv war (Bit 0) und Terminende noch nicht geloggt (Bit 4), einen Eintrag schreiben.
    integer statusAlt = RaumParameter.StrValueByIndex(";",1).ToInteger();
    string  rvnAlt    = RaumParameter.StrValueByIndex(";",0);
    real    maxAlt    = RaumParameter.StrValueByIndex(";",2).ToFloat();
    if (((statusAlt & 1)!=0) && ((statusAlt & 16)==0) && (rvnAlt!="")) {
      string rvnNameAlt = rvnAlt.Replace(vrp # "HKG-Raum-","");
      logObj.State(rvnNameAlt # " - Termin entfernt: Max.: " # maxAlt.ToString(1) # ", AT: " # ATLog);
    }
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

