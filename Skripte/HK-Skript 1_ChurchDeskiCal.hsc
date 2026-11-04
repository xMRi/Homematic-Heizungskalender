!// Skript 1 um die Termine aus ChurchDesk auszulesen (iCal)
!//================================================================================================
!// Stand:    04.11.2026
!// Autoren:  Lukas Helduser    (Youtube: https://www.youtube.com/LukasvandeHaag)
!//           Martin Richter    (heizkalender@m-ri.de) http://blog.m-ri.de/
!// Projekt:  Helmut Diedrichs  (helmut@diedrichs.de) https://diedrichs.de
!//------------------------------------------------------------------------------------------------
!// Copyright (C) 2026 Martin Richter (xMRi-Software)
!// Dieser Teil des Heizkalenders ist freie Software und wird unter der GNU General Public License
!// Version 3 (GPLv3) oder neuer veröffentlicht.
!// Es besteht keinerlei Garantie oder Haftung. Nutzung auf eigene Verantwortung.
!//================================================================================================
!//
!// Dieser Code ersetzt die Datei:
!//  HKP-ICS-CD-3.1.1 ICal_ChurchDesk_V1.1.6.c
!// Der ursprüngliche Code wurde geschrieben von:
!//   Lukas Helduser (Youtube: https://www.youtube.com/LukasvandeHaag)
!// Ich (MRi) habe diesen Code dann erweitert, korrigiert und verbessert um sie an die Nutzung in
!// meiner Gemeinde anzupassen.
!//
!// Skript sollte alle 30min laufen
!//

!// TT:  2026-10-25 Bugfix: DTEND-Parsing ohne iPos-Pruefung. Bei fehlendem DTEND war
!//                 iPos=-1 und Substr las Datenmüll als Enddatum. Jetzt continue; bei iPos<0.
!// TT:  2026-10-25 Bugfix: Variable Shadowing bei strTemp. Die innere Deklaration
!//                 "string strTemp" im DESCRIPTION-Block ueberdeckte die aeussere Variable,
!//                 sodass Sonderbefehle (#EIN#, #AUS#, #GT# etc.) nie ausgewertet wurden.
!// TT:  2026-10-25 Bugfix: Fehlendes continue; bei HTTP-Fehler. Ohne continue; lief das Skript
!//                 mit leerem stdout in die Terminverarbeitung und erzeugte falsche Schaltzeiten.
!// MRi: 2026-10-19 Neuen Modus "V" für das setzen einer Variable eingebaut
!// TT:  2026-10-18 HK1-Vorlaufzeit: zeitVorlauf aus optionaler Systemvariable lesen (Default 12h)
!// TT:  2026-10-01 Vorlauf von 8h auf 12h vereinheitlicht (alle Skript-1-Varianten jetzt
!//                 12h). DIVERGENZ-Hinweis entfernt.
!// TT:  2026-10-01 Kommentarblock zum Zeitfenster aktualisiert.
!// TT:  2026-09-28 Log-Ausgabe: Leerzeichen zwischen Raumname und (ID) entfernt.
!// TT:  2026-09-28 Bugfix: False-Positive im Duplikat-Check (SLT.Find) fuer einstellige
!//                 Ressource-IDs (z.B. ID 1 wurde in ID 11 gefunden). Fix: Semikolon-Praefix.
!// MRi: 2026-06-21 Retry eingebaut, weil churchdesk unregelmässig Fehler liefert
!// MRi: 2026-02-19 Heizen mit Schalten eingebaut, Schaltliste umgebaut
!// MRI: 2026-02-16 Leere Raumzuordnung berücksichtigen
!// MRi: 2026-01-26 Sonderbefehle auch für das iCal Skript in der Terminbeschreibung
!// MRi: 2026-01-13 HK1-R-Liste erhält nun auch den Namen der Resource getrennt mit Gleichheitszeichen
!// MRi: 2026-01-01 Skript gegen fehlende Raumvariablen gesichert
!// MRi: 2025-12-09 Anpassung an ChurchDesk API
!// MRi: 2025-11-24 MultiRaumVariante, damit lassen sich mehrere Räume einer Ressource zuordnen.
!//                 korrektur nochmal für doppelte Schaltlisteneinträge

!//Eingabe eines Namens Präfix
!//Dies ist nur erforderlich wenn die Namensvorgabe beim erstellen den Systemvariablen geändert wurde.
!//Wird hier ein Präfix eingeben so muss dieser in allen Skripten auch angegeben werden.
string vrp="";

!//Debug ein oder aus
boolean DEBUG=0;

!// Zeitfenster fuer Termine: von (Terminstart minus zeitVorlauf) bis
!// (Terminende plus zeitNachlauf). Die Haltezeit zeitNachlauf haelt einen beendeten Termin
!// so lange in der Schaltliste, dass HK-Skript 3 ihn noch ausschalten kann.
!// Kein Heiz-Nachlauf.
integer zeitVorlauf=12*60;   !// 12 Stunden (Default, falls HK1-Vorlaufzeit nicht gesetzt)
object objVorlaufzeit = dom.GetObject(vrp#"HK1-Vorlaufzeit");
if(objVorlaufzeit) {
  zeitVorlauf = objVorlaufzeit.State().ToInteger();
}
integer zeitNachlauf=30;   !// 30 Minuten

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

if(log){logObj.State("Beginn ChurchDesk-Skriptlauf======================");}
WriteLine("Beginn ChurchDesk-Skriptlauf");

!// Daten für den Zugriff setzen
string apiToken = dom.GetObject(vrp#"HK1-CD-Token").State();
string organizationId = dom.GetObject(vrp#"HK1-CD-OrganisationsId").State();

!// Filter für Resourcen setzen
string RIdListe=dom.GetObject(vrp#"HK1-R-Liste").State();
string HKGListe=dom.GetObject(vrp#"HK2-HKG-Liste").State();

!// Suche alle Ids der Ressourcen. Achtung es kann ein mit = abgetrennter Name vorhanden sein.
string filter="";
string RId;
foreach(RId,RIdListe.Split(";")){
  if (filter){
    filter = filter # "|";
  }
  filter = filter # RId.StrValueByIndex("=",0);
}

if(DEBUG){
  WriteLine("HKGListe=" # HKGListe);
  WriteLine("RIdListe=" # RIdListe);
}


!// Start und Enddatum setzen, End Datum = 2+Tage
!// Start und Enddatum setzen, End Datum = 1+Tage
integer versatzGMT=(system.Date("%z").Substr(1,2)).ToInteger()*3600;
integer JETZT=system.Date().ToTime().ToInteger();
string startDatum = JETZT.ToTime().ToString("%F");
string endDatum = (JETZT+172800).ToTime().ToString("%F");

!// Neue Schaltliste
string SLT="";

string RIdEintrag;
integer raumIndex = -1;
foreach(RIdEintrag,RIdListe.Split(";")){
  !// Nun suchen wir über die Ressource Id den Raum Index und den Namen. Leider hat dieser auch einen
  !// Raumname optional, das gestaltet die Suche etwas schwieriger
  string RId = RIdEintrag.StrValueByIndex("=",0);
  string RaumName=RIdEintrag.StrValueByIndex("=",1);
  if(DEBUG){
    WriteLine("---------------------------------------------------------------------------------------");
    WriteLine("Raum: " # RId # " / " # RaumName );
  }

  !// Zuerst Ramzuordnung ermitteln.
  !// Ohne Raumzuordnung überspringen wir hier die Terminabfrage.
  !// Wir inkrementieren hier, weil sonst kein continue; möglich ist
  raumIndex = raumIndex+1;
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

  !// Zugriff auf ChurchDesk iCal.
  !// Wir bauen hier einen Retry ein, weil es scheinbar seit einiger Zeit Probleme mit dem Zugriff auf ChurchDesk gibt
  integer iRetry = 5;
  string stdout;
  string stderr;
  while (iRetry>0) {
    !// wget unterstützt leider nicht --secure-protocol=TLSv1_1
    string cmd = "wget --no-check-certificate --timeout=5 -O - 'https://api2.churchdesk.com/ical/resource/" # RId # "/public?organizationId="# organizationId #"'";
    !string cmd = "curl --insecure --tlsv1.1 --max-time 5 -L 'https://api2.churchdesk.com/ical/resource/" # RId # "/public?organizationId="# organizationId #"'";
    if(DEBUG){
      WriteLine("Cmd:" # cmd);
    }
    system.Exec(cmd, &stdout, &stderr);

    if(DEBUG){
      !WriteLine("stdout:" # stdout);
      !WriteLine("stderr:" # stderr);
    }

    if (stdout.StartsWith("BEGIN:VCALENDAR")){
      !// Es wurde ein Ergebnis zurückgegeben. Wir können die Retry Schleife abbrechen
      break;
    } else {
      !// Unerwünschtes Ergebnis/Fehler, also ein Retry mehr
      iRetry = iRetry-1;
      !// Verzögern
      string dummy;
      system.Exec("sleep 1", &dummy, &dummy);
    }
  }

  !// Tabs entfernen, sollten welche drin sein. Newlines setzen
  stdout = stdout.Replace("\t"," ").Replace("\r\n","\n");

  if (!stdout.StartsWith("BEGIN:VCALENDAR")){
    if (log){ logObj.State("Fehler beim Lesen der Event-Daten von ChurchDesk! " # RId); }
    if(DEBUG){
      WriteLine("Fehler beim Lesen der Event-Daten von ChurchDesk! " # RId);
      WriteLine("Out:\n" # stdout # "Err:\n" # stderr);
    }
    continue;
  }else{
    !// Zeitzone abschneiden
    integer iPos = stdout.Find("\nBEGIN:VEVENT\n");
    if (iPos<0){
      !// Termindaten fehlerhaft
      continue;
    }

    !// Laufe über alle Termine. Wir müssen das Newline erhalten, damit wir alle Tokens finden..
    string termine = stdout.Substr(iPos,stdout.Length()-iPos).Replace("\nEND:VEVENT\n","\t\n");
    string termin;
    foreach(termin,termine){
      !// Schleife über all einzelnen Termine
      if(DEBUG){
        !WriteLine("Termin Daten: " # termin);
      }

      !// Start und Enddatum holen.
      iPos = termin.Find("\nDTSTART:");
      if (iPos<0){
        !// Kein Termineintrag mehr
        continue;
      }
      startDatum=termin.Substr(iPos+9,13).Replace("T"," ");
      startDatum=startDatum.Substr(0,4)#"-"#startDatum.Substr(4,2)#"-"#startDatum.Substr(6,2)#" "#startDatum.Substr(9,2)#":"#startDatum.Substr(11,2);
      startDatum=(startDatum.ToTime().ToInteger()+versatzGMT).ToString();
      if (DEBUG){
        WriteLine(startDatum.ToInteger().ToTime());
      }

      iPos = termin.Find("\nDTEND:");
      if (iPos<0){
        !// Kein Enddatum gefunden
        continue;
      }
      endDatum=termin.Substr(iPos+7,13).Replace("T"," ");
      endDatum=endDatum.Substr(0,4)#"-"#endDatum.Substr(4,2)#"-"#endDatum.Substr(6,2)#" "#endDatum.Substr(9,2)#":"#endDatum.Substr(11,2);
      endDatum=(endDatum.ToTime().ToInteger()+versatzGMT).ToString();
      if (DEBUG){
        WriteLine(endDatum.ToInteger().ToTime());
      }

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
        WriteLine("Termin:\t" # RId # " / " # RaumName # "\t" # startDatum.ToInteger().ToTime() # "\t" # endDatum.ToInteger().ToTime());
      }

      !// Beschreibung (optional) des Termines extrahieren
      string strTemp = "";
      iPos = termin.Find("\nDESCRIPTION:");
      if (iPos>=0){
        strTemp = termin.Substr(iPos+13);
        iPos = strTemp.Find("\n");
        strTemp = strTemp.Substr(0,iPos);
        if (DEBUG){
          WriteLine("Beschreibung:" # strTemp);
        }
      }

      !// Nun nach Sonderbefehlen suchen
      !// #EIN#, #AUS#, #GT#, #NS#, #NH#, #NORMAL#, #RESET#, #<zahl><text>#
      string cap = "0";
      iPos = strTemp.Find("#");
      if (iPos>=0){
        strTemp = strTemp.Substr(iPos+1,strTemp.Length()-iPos-1);
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
      string toadd = RId # ";" # startDatum.ToInteger().ToTime() # ";" # endDatum.ToInteger().ToTime() # ";" # cap # ";" # SchaltenHeizen # ";";
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
}

!//------------------------------------------------------------------------------------------------

!// Geänderte Schaltliste schreiben

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

if(log){logObj.State("Ende ChurchDesk-Skriptlauf========================");}
WriteLine("Ende ChurchDesk-Skriptlauf");
