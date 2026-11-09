!// Skript 1 um die Termine aus ChurchTools auszulesen (API)
!//================================================================================================
!// Stand:    07.11.2026
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
!//  HKP-CT-3.2.1 churchtools_Ressource_V2_8_8.c
!// Der ursprüngliche Code wurde geschrieben von:
!//   Lukas Helduser (Youtube: https://www.youtube.com/LukasvandeHaag)
!// Ich (MRi) habe diesen Code dann erweitert, korrigiert und verbessert um sie an die Nutzung in
!// meiner Gemeinde anzupassen.
!//
!// Skript sollte alle 30min laufen
!//

!// MRi: 2026-11-07 Schaltliste bis 30 Minuten nach dem spätesten raumbezogenen Ausschaltzeitpunkt halten.
!// MRi: 2026-11-07 Alte Changelogs entfernt
!// MRi: 2026-10-19 Neuen Modus "V" für das setzen einer Variable eingebaut
!// TT:  2026-10-18 HK1-Vorlaufzeit: zeitVorlauf aus optionaler Systemvariable lesen (Default 12h)
!// TT:  2026-10-01 DIVERGENZ-Hinweis entfernt: alle Skript-1-Varianten nutzen jetzt 12h Vorlauf.
!// TT:  2026-10-01 Vergangenheits-Check von <= auf < vereinheitlicht (wie andere
!//                 Skript-1-Varianten). 1-Sekunden-Divergenz am Nachlaufende entfernt.
!//                 Kommentarblock zum Zeitfenster aktualisiert.
!// TT:  2026-09-28 Log-Ausgabe: Leerzeichen zwischen Raumname und (ID) entfernt.
!// TT:  2026-09-28 Bugfix: False-Positive im Duplikat-Check (SLT.Find) fuer einstellige
!//                 Ressource-IDs (z.B. ID 1 wurde in ID 11 gefunden). Fix: Semikolon-Praefix.
!// TT:  2026-09-22 Konsistenzpruefung der benoetigten Systemvariablen ergaenzt (nur Warnung
!//                 im Log, kein Abbruch). CCU-verifiziert.
!// MRi: 2026-08-08 Sonderbefehle #GT# #NH# #NS# werden auch aus Titel und Subtitel gelesen
!// MRi: 2026-02-19 Heizen mit Schalten eingebaut, Schaltliste umgebaut
!// MRI: 2026-02-05 Leere Raumzuordnung berücksichtigen
!// MRi: 2026-01-13 HK1-R-Liste erhält nun auch den Namen der Resource getrennt mit Gleichheitszeichen
!// MRi: 2026-01-01 Skript gegen fehlende Raumvariablen gesichert

!//Eingabe eines Namens Präfix
!//Dies ist nur erforderlich wenn die Namensvorgabe beim erstellen den Systemvariablen geändert wurde.
!//Wird hier ein Präfix eingeben so muss dieser in allen Skripten auch angegeben werden.
string vrp="";

!//Debug Ausgaben Ein und Aus schalten. 0 = Aus, 1 = Ein
boolean DEBUG=0;

!// Zeitfenster fuer Termine: von (Terminstart minus zeitVorlauf) bis
!// (Terminende plus zeitNachlauf). Die Haltezeit zeitNachlauf haelt einen beendeten Termin
!// so lange in der Schaltliste, dass HK-Skript 3 ihn noch ausschalten kann.
!// Kein Heiz-Nachlauf.
integer zeitVorlauf=12*60;		!// 12 Stunden (Default, falls HK1-Vorlaufzeit nicht gesetzt)
object objVorlaufzeit = dom.GetObject(vrp#"HK1-Vorlaufzeit");
if(objVorlaufzeit) {
  zeitVorlauf = objVorlaufzeit.State().ToInteger();
}

!// Logging in "Log" mit 1 zwingend einschalten oder mit -1 zwingend Ausschalten
!// Mit 0 wird die Einstellunge aus der HKx-Logging übernommen
integer log=0;

!//################################################################################################
!//######------Skript Variablen und Skript Arbeitsteil. Vom Benutzer nicht zu verändern------######

!// Logging vorbereiten
var logObj=dom.GetObject(vrp+"HK1-Log");
var loggingObj=dom.GetObject(vrp+"HK1-Logging");

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

if(log){logObj.State("Beginn ChurchTools-Skriptlauf=====================");}
WriteLine("Beginn ChurchTools-Skriptlauf");

!// Konsistenzpruefung: benoetigte Systemvariablen vorhanden? Nur Warnung, kein Abbruch.
!// Fehlt eine Variable, liefert GetObject null und State() einen Leerstring - dann wuerde
!// still mit falschen Werten weitergerechnet. Init-Skripte anlegen, falls hier etwas fehlt.
string fehlendeVars = "";
string pruefVar;
foreach(pruefVar, "HK1-CT-Token;HK1-CT-Gemeindename;HK1-R-Liste;HK2-HKG-Liste;HK1-Schaltliste".Split(";")){
  if(!dom.GetObject(vrp # pruefVar)){
    fehlendeVars = fehlendeVars # pruefVar # " ";
  }
}
if(fehlendeVars!=""){
  if(log){logObj.State("WARNUNG: Fehlende Systemvariablen: " # fehlendeVars # "- bitte Init-Skript ausfuehren!");}
  WriteLine("WARNUNG: Fehlende Systemvariablen: " # fehlendeVars # "- bitte Init-Skript ausfuehren!");
}


!// Daten für den Zugriff setzen
string loginToken = dom.GetObject(vrp # "HK1-CT-Token").State();
string gemeindeName = dom.GetObject(vrp # "HK1-CT-Gemeindename").State();

!// Filter für Resourcen setzen
string RIdListe=dom.GetObject(vrp#"HK1-R-Liste").State();
string HKGListe=dom.GetObject(vrp#"HK2-HKG-Liste").State();
string RaumVar;
object objVar;

!// Die Raumvariable enthält die individuelle Ausschaltverschiebung in Feld 5.
!// Ein negativer Wert verschiebt das Ausschalten nach hinten. Die Schaltliste muss
!// daher bis 30 Minuten nach der spätesten individuellen Ausschaltzeit erhalten bleiben.
integer minRaumNachlauf=0;
integer raumNachlauf;
foreach(RaumVar, HKGListe.Replace("+",";").Split(";")){
  if(RaumVar!=""){
    objVar=dom.GetObject(RaumVar);
    if(objVar){
      raumNachlauf=objVar.State().StrValueByIndex(";",5).ToInteger();
      if(raumNachlauf<minRaumNachlauf){
        minRaumNachlauf=raumNachlauf;
      }
    }
  }
}
integer zeitNachlauf=30-minRaumNachlauf;
if(DEBUG){WriteLine("Schaltliste-Nachlauf: " # zeitNachlauf # " Minuten");}

!// Suche alle Ids der Ressourcen. Achtung es kann ein mit = abgetrennter Name vorhanden sein.
string filter="";
string RId;
foreach(RId,RIdListe.Split(";")){
  filter = filter # "&resource_ids[]=" # RId.StrValueByIndex("=",0);
}

if(DEBUG){
  WriteLine("HKGListe=" # HKGListe);
  WriteLine("RIdListe=" # RIdListe);
}

!// Start und Enddatum setzen, End Datum = 1+Tage
integer versatzGMT=(system.Date("%z").Substr(1,2)).ToInteger()*3600;
integer JETZT=system.Date().ToTime().ToInteger();
string startDatum = JETZT.ToTime().ToString("%F");
string endDatum = (JETZT+86400).ToTime().ToString("%F");

!// Zugriff auf ChurchTools API
string cmd = "wget --timeout=3 -O - 'https://" # gemeindeName # ".church.tools/api/bookings?login_token=" # loginToken #
                                        filter # "&from=" # startDatum # "&to=" # endDatum # "'";
if(DEBUG){
  WriteLine("Cmd:" # cmd);
}
string stdout;
string stderr;
system.Exec(cmd, &stdout, &stderr);

if(DEBUG){
  WriteLine("stdout:" # stdout);
  WriteLine("stderr:" # stderr);
}

!//------------------------------------------------------------------------------------------------

!// Neue Schaltliste
string SLT="";

!// Ergebnis prüfen
if (stdout.Contains("\"meta\":{\"count\":0}")){
  !// Keine Termine
  if(DEBUG){
    WriteLine("Keine Termine vorhanden!");
  }
}elseif(!stdout.StartsWith("{\"data\":[")){
  if (log){ logObj.State("Fehler beim Lesen der Event-Daten von ChurchTools!"); }
  if(DEBUG){
    WriteLine("Fehler beim Lesen der Event-Daten von ChurchTools!");
  }
  quit;
}else{
  !// Termine durchlesen
  string termine = stdout.Replace("\"booking\":{\"base\":{","\t");
  string termin;
  foreach(termin,termine){
    !// Schleife über all einzelnen Termine
    if(DEBUG){
      WriteLine("Termin Daten: " # termin);
    }
    integer iPos = termin.Find("\"resourceId\":");
    if (iPos<0){
      continue;
    }

    !// Id der Ressource bestimmen
    string resId=termin.Substr(iPos+13,10).ToInteger();

    !// Nun suchen wir über die Ressource Id den Raum Index und den Namen. Leider hat dieser auch einen
    !// Raumname optional, das gestaltet die Suche etwas schwieriger
    !// Wenn Variable nicht gefunden innerer Schleife für diesen Durchgang beenden
    boolean bGefunden = false;
    integer raumIndex = 0;
    string RaumName="";
    string RIdEintrag;
    foreach(RIdEintrag,RIdListe.Split(";")){
      RaumName = RIdEintrag.StrValueByIndex("=",1);
      if (RIdEintrag.StrValueByIndex("=",0)==resId){
        bGefunden = true;
        break;
      }
      raumIndex = raumIndex+1;
    }

    if (!bGefunden){
      !// Raum nicht in unserer Liste - dürfte eigentlich nicht passieren, da wir einen
      !// Filter für Resourcen haben.
      if(DEBUG){
        WriteLine("Raum Resource Id konnte nicht gefunden werden!");
      }
      continue;
    }

    !// In der Multiraumvariante haben wie mehere Raumeinträge durch + getrennt.
    !// MRi: Nach meinem Dafürhalten ist diese Information in der Schaltliste redundant.
    string RaumVarListe=HKGListe.StrValueByIndex(";",raumIndex);
    string RaumVar = RaumVarListe;
    if (!RaumVarListe){
      if (DEBUG) { WriteLine("Keine Raumzuordnung!"); }
      continue;
    }
    RaumVar=RaumVar.StrValueByIndex("+",0);
    if (RaumName==""){
      RaumName = RaumVarListe.Replace(vrp#"HKG-Raum-","");
    }

    object objVar = dom.GetObject(RaumVar);
    if ((!RaumVar) || (!objVar)){
      !// Raumvariable nicht vorhanden
      if(log) { logObj.State("Raumvariable " # RaumVar # " nicht vorhanden!"); }
      if (DEBUG) { WriteLine("Raumvariable " # RaumVar # " nicht vorhanden!"); }
      continue;
    }

    !// Dieses Flag ist eigentlich nicht nötig, aber wir platzieren es aus Gründen
    !// der Rückwärtskompatibilität. Früher wurde 0=Schalten/1=Heizen verwendet. ich
    !// übertrage jetz den originalen Parameter.
    string SchaltenHeizen=objVar.State().StrValueByIndex(";",1);

    !// Start und Enddatum holen.
    iPos = termin.Find("\"calculated\":{");
    string strTemp = termin.Substr(iPos+14,termin.Length()-iPos-14);
    startDatum=strTemp.Substr(strTemp.Find("\"startDate\":\"")+13,19).Replace("T"," ");
    if (DEBUG){
      WriteLine(startDatum);
    }
    startDatum=(startDatum.ToTime().ToInteger()+versatzGMT).ToString();

    endDatum=strTemp.Substr(strTemp.Find("\"endDate\":\"")+11,19).Replace("T"," ");
    if (DEBUG){
      WriteLine(endDatum);
    }
    endDatum=(endDatum.ToTime().ToInteger()+versatzGMT).ToString();

    !// Termine nur übernehmen wenn sie im Zeitrahmen liegen
    if ((startDatum.ToInteger()-(zeitVorlauf*60))>JETZT){
      !// Termin liegt in der Zukunft
      if (DEBUG){
        WriteLine("Termin liegt in der Zukunft");
      }
      continue;
    }
    if ((endDatum.ToInteger()+(zeitNachlauf*60))<JETZT){
      !// Termin liegt in der Vergangenheit
      if (DEBUG){
        WriteLine("Termin liegt in der Vergangenheit");
      }
      continue;
    }

    if (DEBUG){
      WriteLine("Termin:\t" # resId # " / " # RaumName # "\t" # startDatum.ToInteger().ToTime() # "\t" # endDatum.ToInteger().ToTime());
    }

    !// Wir suchen nun die folgenden Felder title, subtitle, description
    string toSearch;
    string strDesc="";
    foreach (toSearch, "title;subtitle;description".Split(";")) {
      iPos=termin.Find("\"" # toSearch # "\":\"");
      if (iPos>=0){
        !// Ende der Beschreibung finden
        strTemp = termin.Substr(iPos+toSearch.Length()+4);
        iPos = strTemp.Find("\",\"");
        if (iPos>=0) {
          strDesc = strDesc # " " # strTemp.Substr(0,iPos);
        }
      }
    }

    !// Beschreibung muss noch auf Tokens geprüft werden.
    !// #EIN#, #AUS#, #GT#, #NS#, #NH#, #NORMAL#, #RESET#, #<zahl><text>#
    string cap="0";
    !// Sonderbefehl suchen
    iPos = strDesc.Find("#");
    if (iPos>=0){
      strTemp = strDesc.Substr(iPos+1,strDesc.Length()-iPos-1);
      iPos = strTemp.Find("#");
      !// Ende vorhanden?
      if (iPos>=0){
        !// Englische (Dezimalpunkt) Deutsche (Dezimalkomma) Konvertierung
        strTemp = strTemp.Substr(0,iPos).ToUpper();
        strTemp.Replace(",",".");
        if (strTemp=="EIN"){
          !// Dauer EIN
          cap = "-2";
        }elseif(strTemp=="AUS"){
          !// Dauer AUS
          cap = "-1";
        }elseif((strTemp=="NORMAL") || (strTemp=="RESET")){
          !// Zurücksetzen RESET AUS/EIN
          cap = "-3";
        }elseif((strTemp=="GT")){
          !// Grundtemperatur GT
          cap = dom.GetObject(vrp+"HK2-Grundtemperatur").State().ToFloat().ToString(1);
        }elseif((strTemp=="NH") || (strTemp=="NS")){
          !// Nicht schalten/heizen (Es wird kein Listeneintrag erzeugt)
          cap = "";
        }else{
          !// Nimm die Zahl, die hier kommt.
          cap = strTemp.ToFloat();
          if ((cap>0) && (cap<30)){
            cap = cap.ToString(1);
          }else{
            cap = "0";
          }
        }
      }
    }

    !// Verhindern, dass doppelte Einträge erzeugt werden.
 	  string toadd = resId # ";" # startDatum.ToInteger().ToTime() # ";" # endDatum.ToInteger().ToTime() # ";" # cap # ";" # SchaltenHeizen # ";";
    !WriteLine(toadd);
    !// Semikolon-Praefix verhindert False-Positive: "1;" wuerde sonst in "11;" gefunden werden.
    if ((";" # SLT).Find(";" # toadd)<0){
      if (cap){
        !// Schalt Eintrag setzen
        SLT=SLT+toadd;
        if (log){
          cap = toadd.StrValueByIndex(";",3).ToInteger();
          if (toadd.StrValueByIndex(";",4).ToInteger()!=0){
            if (cap<0){
              cap = ("AUS;EIN;NORMAL").StrValueByIndex(";",(1+cap)*(-1));
            }elseif(cap==0){
              cap = "Normaltemperatur";
            }else{
              cap = toadd.StrValueByIndex(";",3).ToFloat().ToString(1);
            }
          }
            !// Klartext erzeugen
            strTemp = SchaltenHeizen;
            if (SchaltenHeizen=="H")  { strTemp = "Heizen"; }
            if (SchaltenHeizen=="S")  { strTemp = "Schalten"; }
            if (SchaltenHeizen=="HS") { strTemp = "Heizen/Schalten"; }
            if (SchaltenHeizen=="V")  { strTemp = "Variable"; }
            logObj.State("Raum: " # RaumName # "("+toadd.StrValueByIndex(";",0)+") - " #
                       toadd.StrValueByIndex(";",1).ToTime().Format("%X") # " / " #
                       toadd.StrValueByIndex(";",2).ToTime().Format("%X") #
                       " Parameter: " # cap # " " #
                       strTemp);
        }
      }else{
        !// Wir haben den Sonderbefehl NH/NS
        if (log){
          logObj.State("Raum: " # RaumName # "("+toadd.StrValueByIndex(";",0)+") - " #
                       toadd.StrValueByIndex(";",1).ToTime().Format("%X") # " / " #
                       toadd.StrValueByIndex(";",2).ToTime().Format("%X") #
                       " Nicht Heizen/Schalten (#NH#/#NS#)");
        }
      }
	  }
  }
}

!// Geänderte Schaltliste schreiben, aber nur wenn nötig.

if(DEBUG){
  WriteLine("SLT=" # SLT);
}

if (dom.GetObject(vrp+"HK1-Schaltliste").State()!=SLT){
  dom.GetObject(vrp+"HK1-Schaltliste").State(SLT);
  if (SLT==""){
    if (log){ logObj.State("Neue Schaltliste: Keine Termine"); }
  }else{
    if (log){ logObj.State("Neue Schaltliste: "+SLT); }
  }
} else {
  if (log){ logObj.State("Schaltliste unverändert"); }
}

!//------------------------------------------------------------------------------------------------

if(log){logObj.State("Ende ChurchTools-Skriptlauf=======================");}

WriteLine("Ende ChurchTools-Skriptlauf");
