!// Skript 1 um die Termine aus Google auszulesen
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
!//  HKP-GK-3.2.1 Googlekalender_V3_4_4.c
!// Der ursprüngliche Code wurde geschrieben von:
!//   Lukas Helduser (Youtube: https://www.youtube.com/LukasvandeHaag)
!// Ich (MRi) habe diesen Code dann erweitert, korrigiert und verbessert um sie an die Nutzung in
!// meiner Gemeinde anzupassen.
!//
!// Skript sollte alle 30min laufen
!//

!// MRi: 2026-10-19 Neuen Modus "V" für das setzen einer Variable eingebaut
!// TT:  2026-10-18 HK1-Vorlaufzeit: zeitVorlauf aus optionaler Systemvariable lesen (Default 12h)
!// TT:  2026-10-01 Vorlauf von 8h auf 12h vereinheitlicht (alle Skript-1-Varianten jetzt
!//                 12h). DIVERGENZ-Hinweis entfernt.
!// TT:  2026-10-01 Kommentarblock zum Zeitfenster aktualisiert.
!// TT:  2026-09-28 Log-Ausgabe: Leerzeichen zwischen Raumname und (ID) entfernt.
!// TT:  2026-09-28 Bugfix: False-Positive im Duplikat-Check (SLT.Find) fuer einstellige
!//                 Ressource-IDs (z.B. ID 1 wurde in ID 11 gefunden). Fix: Semikolon-Praefix.
!// MRi: 2026-02-19 Heizen mit Schalten eingebaut, Schaltliste umgebaut
!// MRI: 2026-02-16 Leere Raumzuordnung berücksichtigen
!// MRi: 2026-01-28 Komplettes Neuschreiben und Anpassen an neue Version

!//Eingabe eines Namens Präfix
!//Dies ist nur erforderlich wenn die Namensvorgabe beim erstellen den Systemvariablen geändert wurde.
!//Wird hier ein Präfix eingeben so muss dieser in allen Skripten auch angegeben werden.
string vrp="";

!//Debug ein oder aus
boolean DEBUG=0;

!// Logging in "Log" mit 1 zwingend einschalten oder mit -1 zwingend Ausschalten
!// Mit 0 wird die Einstellung aus der HKx-Logging übernommen
integer log=0;

!// Zeitfenster fuer Termine: von (Terminstart minus zeitVorlauf) bis
!// (Terminende plus zeitNachlauf). Die Haltezeit zeitNachlauf haelt einen beendeten Termin
!// so lange in der Schaltliste, dass HK-Skript 3 ihn noch ausschalten kann.
!// Kein Heiz-Nachlauf.
integer zeitVorlauf=12*60;		!// 12 Stunden (Default, falls HK1-Vorlaufzeit nicht gesetzt)
object objVorlaufzeit = dom.GetObject(vrp#"HK1-Vorlaufzeit");
if(objVorlaufzeit) {
  zeitVorlauf = objVorlaufzeit.State().ToInteger();
}
integer zeitNachlauf=30;		!// 30 Minuten


!// Der Code wurde in weiten teilen von der ChurchDesk iCal Variante genommen

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

if(log){logObj.State("Beginn Google-Skriptlauf==========================");}
WriteLine("Beginn Google-Skriptlauf");

!// Filter für Resourcen setzen
string RIdListe=dom.GetObject(vrp#"HK1-R-Liste").State();
string HKGListe=dom.GetObject(vrp#"HK2-HKG-Liste").State();

if(DEBUG){
  WriteLine("HKGListe=" # HKGListe);
  WriteLine("RIdListe=" # RIdListe);
}

!// Start und Enddatum setzen, End Datum = 1+Tage
integer versatzGMT=(system.Date("%z").Substr(1,2)).ToInteger()*3600;
integer JETZT=system.Date().ToTime().ToInteger();
string startDatum = JETZT.ToTime().ToString("%FT00:00:00Z");
string endDatum = (JETZT+(86400*10)).ToTime().ToString("%FT23:59:59Z");


!// Neue Schaltliste
string SLT="";

!// Zugriff auf Google
string strKalId = dom.GetObject(vrp+"HK1-GK-Kalender-ID").State();
string strApiKey = dom.GetObject(vrp+"HK1-GK-API-Key").State();
!// evtl. doppelten Teil, des API-Keys entfernen. Relativ Zeitzone Berlin. prettyPrint=false!
strKalId = strKalId.Replace("@group.calendar.google.com","");
string cmd = "wget --timeout=5 -O - 'https://www.googleapis.com/calendar/v3/calendars/" # strKalId #
                "@group.calendar.google.com/events?" #
                "orderBy=startTime&singleEvents=true&prettyPrint=false&timeZone=Europe/Berlin" #
                "&timeMin=" # startDatum #
                "&timeMax=" # endDatum #
                "&key=" # strApiKey # "'";
if(DEBUG){
  WriteLine("---------------------------------------------------------------------------------------");
  WriteLine("Cmd:" # cmd);
}
string stdout;
string stderr;
system.Exec(cmd, &stdout, &stderr);

if(DEBUG){
  !WriteLine("stdout:" # stdout);
  !WriteLine("stderr:" # stderr);
}

!// Tabs entfernen, sollten welche drin sein. Newlines setzen
stdout = stdout.Replace("\t"," ").Replace("\r\n","\n");

if (!stdout.StartsWith("{\"kind\":\"calendar#events\"")){
  if (log){ logObj.State("Fehler beim Lesen der Event-Daten von Google! Ursachen: API-Key falsch, Kalender-ID falsch, Kalender nicht öffentlich."); }
  if(DEBUG){
    WriteLine("Fehler beim Lesen der Event-Daten von Google! Ursachen: API-Key falsch, Kalender-ID falsch, Kalender nicht öffentlich.");
  }
  quit;
}

integer iPos;
iPos = stdout.Find(",\"items\":[");
if (iPos<=0) {
  if(DEBUG){
    WriteLine("Keine Termindaten gefunden!");
  }
} elseif (stdout.Substr(iPos+10,1)=="]") {
  !// Keine Termine vorhanden
  if(DEBUG){
    WriteLine("Keine Termine vorhanden!");
  }
} else {
  !// Termindaten abschneiden und von UTF8 umwandeln
  stdout = stdout.Substr(iPos+10).ToLatin();

  !// Schleife über alle Räume
  string RIdEintrag;
  integer raumIndex = -1;
  foreach(RIdEintrag,RIdListe.Split(";")) {
    !// Nun suchen wir über die Ressource Id den Raum Index und den Namen. Leider hat dieser auch einen
    !// Raumname optional, das gestaltet die Suche etwas schwieriger
    string RId = RIdEintrag.StrValueByIndex("=",0);
    string RaumName=RIdEintrag.StrValueByIndex("=",1);
    if(DEBUG){
      WriteLine("---------------------------------------------------------------------------------------");
      WriteLine("Raum: " # RId # " / " # RaumName );
    }

    !// In der Multiraumvariante haben wie mehere Raumeinträge durch + getrennt.
    !// Wir inkrementieren hier, weil sonst kein continue; möglich ist
    !// MRi: Nach meinem Dafürhalten ist diese Information in der Schaltliste redundant.
    raumIndex = raumIndex+1;
    string RaumVarListe=HKGListe.StrValueByIndex(";",raumIndex);
    string RaumVar = RaumVarListe;
    if (!RaumVarListe){
      if (DEBUG) { WriteLine("Keine Raumzuordnung!"); }
      continue;
    }
    RaumVar=RaumVar.StrValueByIndex("+",0);
    if (RaumName==""){
      RaumName = RaumVarListe.Replace(vrp # "HKG-Raum-","");
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

    !// In den Terminen muss eine Summary vorhanden sein.
    iPos = stdout.Find(",\"summary\":\"");
    if (iPos<0) {
      if (log){ logObj.State("Fehler beim Lesen der Event-Daten von Google! Ursachen: Termindetails nicht freigegeben."); }
      if(DEBUG){
        WriteLine("Fehler beim Lesen der Event-Daten von Google! Ursachen: Termindetails nicht freigegeben.");
      }
      quit;
    }
    !// Laufe über alle Termine. Wir müssen das Newline erhalten, damit wir alle Tokens finden..
    string termine = stdout.Replace("{\"kind\":\"calendar#event\"","\t");
    string termin;
    foreach(termin,termine){
      !// Schleife über all einzelnen Termine
      if(DEBUG){
        !WriteLine("Termin Daten: " # termin);
      }

      !// Jetzt prüfen wir, ob dieser Raum in diesem Termin vorkommt.
      iPos = termin.Find(",\"summary\":\"");
      if (iPos<0){
        !// Keine Summary vorhanden.
        continue;
      }
      string strTemp = termin.Substr(iPos+12);
      iPos = strTemp.Find("\",\"");
      strTemp = strTemp.Substr(0,iPos);
      if (DEBUG){
        WriteLine("Titel:" # strTemp);
      }

      !// Prüfen ob der Raum mit einem Hashtag im Titel vorkommt.
      !// Dabei erlauben wir, dass der RIdEintrag keinen HashTag hat
      if ((!strTemp.ToUpper().Contains("#" # RId.Trim("#").ToUpper())) && (!strTemp.ToUpper().Contains("#" # RaumName.Trim("#").ToUpper()))){
        !// Dieser Raum kommt nicht in der Beschreibung vorbereiten
        if (DEBUG){
          WriteLine("Termin ist nicht für diesen Raum");
        }
        continue;
      }

      !// Start und Enddatum holen.
      iPos = termin.Find(",\"start\":{\"dateTime\":\"");
      startDatum=termin.Substr(iPos+22,19).Replace("T"," ");
      startDatum=startDatum.ToTime().ToInteger();
      if (DEBUG){
        WriteLine(startDatum.ToInteger().ToTime());
      }

      iPos = termin.Find(",\"end\":{\"dateTime\":\"");
      endDatum=termin.Substr(iPos+20,19).Replace("T"," ");
      endDatum=endDatum.ToTime().ToInteger();
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
      iPos = termin.Find(",\"description\":\"");
      if (iPos>=0){
        strTemp = termin.Substr(iPos+16);
        iPos = strTemp.Find("\",\"");
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

if(log){logObj.State("Ende Google-Skriptlauf============================");}
WriteLine("Ende Google-Skriptlauf");
