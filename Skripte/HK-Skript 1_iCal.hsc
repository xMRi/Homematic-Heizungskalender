!// Skript 1 um die Termine aus iCal auszulesen
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
!//  HKP-ICS-A-3.1.1  ICal_Skript1_V1.3.2
!// Der ursprüngliche Code wurde geschrieben von:
!//   Lukas Helduser (Youtube: https://www.youtube.com/LukasvandeHaag)
!// Ich (MRi) habe diesen Code dann erweitert, korrigiert und verbessert um sie an die Nutzung in
!// meiner Gemeinde anzupassen.
!//
!// Skript sollte alle 30min laufen
!//

!// MRi: 2026-11-07 Schaltliste bis 30 Minuten nach dem spätesten raumbezogenen Ausschaltzeitpunkt halten.
!// TT:  2026-10-25 Bugfix: Variable Shadowing bei strTemp. Die innere Deklaration
!//                 "string strTemp" im DESCRIPTION-Block ueberdeckte die aeussere Variable,
!//                 sodass Sonderbefehle (#EIN#, #AUS#, #GT# etc.) nie ausgewertet wurden.
!// MRi: 2026-10-19 Neuen Modus "V" für das setzen einer Variable eingebaut
!// TT:  2026-10-18 HK1-Vorlaufzeit: zeitVorlauf aus optionaler Systemvariable lesen (Default 12h)
!// TT:  2026-10-01 Vorlauf von 8h auf 12h vereinheitlicht (alle Skript-1-Varianten jetzt
!//                 12h). DIVERGENZ-Hinweis entfernt.
!// TT:  2026-10-01 Kommentarblock zum Zeitfenster aktualisiert.
!// TT:  2026-09-28 Log-Ausgabe: Leerzeichen zwischen Raumname und (ID) entfernt.
!// TT:  2026-09-28 Bugfix: False-Positive im Duplikat-Check (SLT.Find) fuer einstellige
!//                 Ressource-IDs (z.B. ID 1 wurde in ID 11 gefunden). Fix: Semikolon-Praefix.
!// TT:  2026-09-18 RRULE-Fixes: DAILY-Tippfehler ("DAYLY"), iMaxCount-Default ohne COUNT (brach
!//                 sofort ab), UNTIL nun korrekt aus dem RRULE-Wert. Ungetestet (kein iCal vorhanden).
!// MRi: 2026-02-19 Heizen mit Schalten eingebaut, Schaltliste umgebaut
!// MRi: 2026-02-16 RRULE eingebaut
!// MRI: 2026-02-16 Leere Raumzuordnung berücksichtigen
!// MRi: 2026-01-28 Komplettes Neuschreiben und Anpassen an neue Version
!// MRi: 2025-11-24 MultiRaumVariante, damit lassen sich mehrere Räume einer Ressource zuordnen.

!//Eingabe eines Namens Präfix
!//Dies ist nur erforderlich wenn die Namensvorgabe beim erstellen den Systemvariablen geändert wurde.
!//Wird hier ein Präfix eingeben so muss dieser in allen Skripten auch angegeben werden.
string vrp="";

!//Debug Ausgaben Ein und Aus schalten. 0 = Aus, 1 = Ein
boolean DEBUG=0;

!// Zeitfenster fuer Termine: bis zeitVorlauf vor Terminstart, und noch die
!// Haltezeit nach Terminende. Umgesetzt als minDatum = JETZT - zeitNachlauf
!// (wirkt wie Terminende plus Haltezeit). zeitNachlauf haelt einen beendeten
!// Termin in der Schaltliste, damit HK-Skript 3 ihn noch ausschalten kann.
!// Kein Heiz-Nachlauf.
integer zeitVorlauf=12*60;   !// 12 Stunden (Default, falls HK1-Vorlaufzeit nicht gesetzt)
object objVorlaufzeit = dom.GetObject(vrp#"HK1-Vorlaufzeit");
if(objVorlaufzeit) {
  zeitVorlauf = objVorlaufzeit.State().ToInteger();
}

!// Logging in "Log" mit 1 zwingend einschalten oder mit -1 zwingend Ausschalten
!// Mit 0 wird die Einstellunge aus der HKx-Logging übernommen
integer log=0;

!//################################################################################################
!//######------Skript Variablen und Skript Arbeitsteil. Vom Benutzer nicht zu verändern------######

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

if(log){logObj.State("Beginn iCal-Skriptlauf============================");}
WriteLine("Beginn iCal-Skriptlauf");

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
  if (filter){
    filter = filter # "|";
  }
  filter = filter # RId.StrValueByIndex("=",0);
}

if(DEBUG){
  WriteLine("HKGListe=" # HKGListe);
  WriteLine("RIdListe=" # RIdListe);
}

!// testDatum und Enddatum setzen, End Datum = 2+Tage
integer versatzGMT=(system.Date("%z").Substr(1,2)).ToInteger()*3600;
integer JETZT=system.Date().ToTime().ToInteger();
integer minDatum = JETZT-(zeitNachlauf*60);
integer maxDatum = JETZT+(zeitVorlauf*60);
string startDatum;
string endDatum;
integer dauer;

!// Neue Schaltliste
string SLT="";

!// Zugriff auf iCal
string strURL = dom.GetObject(vrp+"HK1-ICS-Url").State();
string cmd = "wget --timeout=5 -O - '" # strURL # "'";
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
stdout = stdout.ToLatin().Replace("\t"," ").Replace("\r\n","\n");

if (!stdout.StartsWith("BEGIN:VCALENDAR")){
  if (log){ logObj.State("Fehler beim Lesen der Event-Daten von iCal!"); }
  if(DEBUG){
    WriteLine("Fehler beim Lesen der Event-Daten von iCal!");
  }
  quit;
}

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


  !// Zeitzone abschneiden
  integer iPos = stdout.Find("\nBEGIN:VEVENT\n");
  if (iPos<0){
    !// Termindaten fehlerhaft
    continue;
  }

  !// In der Multiraumvariante haben wie mehere Raumeinträge durch + getrennt.
  !// MRi: Nach meinem Dafürhalten st diese Information in der Schaltliste redundant.
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

  !// Laufe über alle Termine. Wir müssen das Newline erhalten, damit wir alle Tokens finden..
  string termine = stdout.Substr(iPos,stdout.Length()-iPos).Replace("\nEND:VEVENT\n","\t\n");
  string termin;
  foreach(termin,termine){
    !// Schleife über all einzelnen Termine
    if(DEBUG){
      !WriteLine("Termin Daten: " # termin);
    }

    !// Jetzt prüfen wir, ob dieser Raum in diesem Termin vorkommt.
    iPos = termin.Find("\nSUMMARY:");
    if (iPos<0){
      !// Keine Summary vorhanden
      continue;
    }
    string strTemp = termin.Substr(iPos+9);
    iPos = strTemp.Find("\n");
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
    iPos = termin.Find("\nDTSTART:");
    if (iPos>=0){
      !// Kein Timzone Eintrag
      startDatum=termin.Substr(iPos+9,13).Replace("T"," ");
      startDatum=startDatum.Substr(0,4)#"-"#startDatum.Substr(4,2)#"-"#startDatum.Substr(6,2)#" "#startDatum.Substr(9,2)#":"#startDatum.Substr(11,2);
      startDatum=(startDatum.ToTime().ToInteger()+versatzGMT);
    } else {
      !// Möglicher Zeitzonen Eintrag
      iPos = termin.Find("\nDTSTART;TZID=");
      !// Sollte die aktuelle Timezone sein.
      strTemp = termin.Substr(iPos+14);
      iPos = strTemp.Find(":");
      startDatum=strTemp.Substr(iPos+1,13).Replace("T"," ");
      startDatum=startDatum.Substr(0,4)#"-"#startDatum.Substr(4,2)#"-"#startDatum.Substr(6,2)#" "#startDatum.Substr(9,2)#":"#startDatum.Substr(11,2);
      startDatum=startDatum.ToTime().ToInteger();
    }
    if (DEBUG){
      WriteLine(startDatum.ToInteger().ToTime());
    }

    iPos = termin.Find("\nDTEND:");
    if (iPos>=0){
      !// Kein Timzone Eintrag
      endDatum=termin.Substr(iPos+7,13).Replace("T"," ");
      endDatum=endDatum.Substr(0,4)#"-"#endDatum.Substr(4,2)#"-"#endDatum.Substr(6,2)#" "#endDatum.Substr(9,2)#":"#endDatum.Substr(11,2);
      endDatum=(endDatum.ToTime().ToInteger()+versatzGMT);
    } else {
      !// Möglicher Zeitzonen Eintrag
      iPos = termin.Find("\nDTEND;TZID=");
      !// Sollte die aktuelle Timezone sein.
      strTemp = termin.Substr(iPos+12);
      iPos = strTemp.Find(":");
      endDatum=strTemp.Substr(iPos+1,13).Replace("T"," ");
      endDatum=endDatum.Substr(0,4)#"-"#endDatum.Substr(4,2)#"-"#endDatum.Substr(6,2)#" "#endDatum.Substr(9,2)#":"#endDatum.Substr(11,2);
      endDatum=endDatum.ToTime().ToInteger();
    }
    if (DEBUG){
      WriteLine(endDatum.ToInteger().ToTime());
    }

    !// Mit der Dauer können wir leicher ein neues Endatum aus einem Startdatum errechnen
    integer dauer = endDatum-startDatum;

    !// Wenn es einen RRULE Eintrag gibt müssen wir den berücksichtigen
    iPos = termin.Find("\nRRULE:");
    string strRRULE = "";
    if (iPos>=0){
      strTemp = termin.Substr(iPos+7);
      iPos = strTemp.Find("\n");
      strRRULE = strTemp.Substr(0,iPos);

      !// Auf nicht erlaubte Schlüsselwörter prüfen.
      boolean bFehler = false;
      foreach(strTemp, "BYMONTH\tBYMONTHDAY\tBYYEARDAY\tBYWEEKNO\tBYSETPOS\tBYHOUR \tBYMINUTE\tBYSECOND"){
        if (strRRULE.Find(strTemp)>=0){
          if (DEBUG){
            WriteLine("RRULE Schlüsselwort " #strTemp # " in " # strRRULE # "wird nicht unterstützt!!!");
          }
          if(log) { logObj.State("RRULE Schlüsselwort " #strTemp # " in " # strRRULE # "wird nicht unterstützt!!!"); }
          bFehler = true;
        }
      }
      if (bFehler){
        continue;
      }
    }

    !// Termine nur übernehmen wenn sie im Zeitrahmen liegen
    boolean bMatch = true;
    if ((startDatum<=maxDatum) && ((startDatum+dauer)>=minDatum)) {
      bMatch = true;
    } else {
      bMatch = false;
      if (DEBUG){
        WriteLine("Termin nicht im Zeitraum");
      }
    }

    !// RRULE benutzen, wenn wir keinen direkten Treffer haben
    if ((!bMatch) && (strRRULE != "")){
      if (DEBUG){
        WriteLine("RRULE:" # strRRULE);
      }
      string strFreq = "";
      if     (strRRULE.Find("FREQ=DAILY")   >= 0) { strFreq = "DAILY"; }
      elseif (strRRULE.Find("FREQ=WEEKLY")  >= 0) { strFreq = "WEEKLY"; }
      elseif (strRRULE.Find("FREQ=MONTHLY") >= 0) { strFreq = "MONTHLY"; }
      elseif (strRRULE.Find("FREQ=YEARLY")  >= 0) { strFreq = "YEARLY"; }
      else {
        if (DEBUG){
          WriteLine("RRULE Schlüsselwort in " # strRRULE # " wird nicht unterstützt!!!");
        }
        if(log) { logObj.State("RRULE Schlüsselwort in " # strRRULE # " wird nicht unterstützt!!!"); }
        continue;
      }

      integer iInterval = 1;
      if (strRRULE.Find("INTERVAL=") >= 0) {
        iInterval = strRRULE.Substr(strRRULE.Find("INTERVAL=")+9).ToInteger();
      }

      !// Ohne COUNT= gilt keine Anzahlbegrenzung; Sentinel 9999 statt 0, damit die Schleife
      !// nicht sofort abbricht. Begrenzt wird dann durch maxDatum (Zeitfenster) bzw. UNTIL.
      integer iMaxCount = 9999;
      if (strRRULE.Find("COUNT=") >= 0) {
        iMaxCount = strRRULE.Substr(strRRULE.Find("COUNT=")+6).ToInteger();
      }

      integer timeUntil = JETZT+(zeitVorlauf*60);
      if (strRRULE.Find("UNTIL=") >= 0) {
        !// UNTIL-Wert (Format YYYYMMDDTHHMMSSZ) aus der RRULE lesen und wie DTEND parsen.
        string sUNTIL = strRRULE.Substr(strRRULE.Find("UNTIL=")+6, 15).Replace("T"," ");
        sUNTIL = sUNTIL.Substr(0,4)#"-"#sUNTIL.Substr(4,2)#"-"#sUNTIL.Substr(6,2)#" "#sUNTIL.Substr(9,2)#":"#sUNTIL.Substr(11,2);
        timeUntil = sUNTIL.ToTime().ToInteger()+versatzGMT;
      }

      string strBYDAY = "";
      iPos = strRRULE.Find("BYDAY=");
      if (iPos>= 0) {
        strBYDAY = strRRULE.Substr(iPos);
        iPos = strBYDAY.Find(";");
        if (iPos<0) {
          iPos  = strBYDAY.Length();
        }else{
          strBYDAY = strBYDAY.Substr(0,iPos);
        }
      }

      !// Schleife um die Daten zu erzeugen.
      integer iCount = 0;
      integer testDatum = startDatum;
      while (true){
        if (testDatum>maxDatum){
          if (DEBUG){
            WriteLine("RRULE NO MATCH: maximales Datum (Heizkalender) erreicht");
          }
          break;
        }
        if (testDatum>timeUntil){
          if (DEBUG){
            WriteLine("RRULE NO MATCH: maximales Datum (UNTIL) erreicht");
          }
          break;
        }
        if (iCount>=iMaxCount){
          if (DEBUG){
            WriteLine("RRULE NO MATCH: maximale Anzahl (COUNT) erreicht");
          }
          break;
        }

        boolean bDayOk = true;
        integer wday = testDatum.ToTime().Format("%w").ToInteger();  !// MONDAY = 1

        if (DEBUG){
          WriteLine("RRULE Test:" # testDatum.ToTime() # " Wochentag: " # wday);
        }

        !// WEEKLY + BYDAY
        if ((strFreq=="WEEKLY") && (strBYDAY != ""))
        {
          bDayOk = false;

          if ((wday == 0) && (strBYDAY.Find("SU") >= 0))  { bDayOk = true; }
          if ((wday == 1) && (strBYDAY.Find("MO") >= 0))  { bDayOk = true; }
          if ((wday == 2) && (strBYDAY.Find("TU") >= 0))  { bDayOk = true; }
          if ((wday == 3) && (strBYDAY.Find("WE") >= 0))  { bDayOk = true; }
          if ((wday == 4) && (strBYDAY.Find("TH") >= 0))  { bDayOk = true; }
          if ((wday == 5) && (strBYDAY.Find("FR") >= 0))  { bDayOk = true; }
          if ((wday == 6) && (strBYDAY.Find("SA") >= 0))  { bDayOk = true; }
        }

        !// MONTHLY + BYDAY mit Ordinal (z.B. 2MO)
        if ((strFreq == "MONTHLY") && (strBYDAY != ""))
        {
          integer wDayByDay;

          strTemp = strBYDAY.Substr(strBYDAY.Find("MO"));
          integer ord = 1;  !// default 1. Montag
          !// Prüfe auf 2MO, -1MO etc.
          if (strTemp.Length() >= 3)
          {
            ord = strTemp.Substr(0, strTemp.Length()-2).ToInteger();
          }

          !// Berechne n-ten Wochentag im Monat
          integer y = testDatum.ToTime().Year();
          integer m = testDatum.ToTime().Month();

          testDatum = (y # "-" # m # "-01 00:00:00").ToTime().ToInteger();
          wday = testDatum.ToTime().Format("%w").ToInteger();

          !// weekday der BYDAY
          if (strTemp.Find("MO") >= 0) { wDayByDay = 1; }
          if (strTemp.Find("TU") >= 0) { wDayByDay = 2; }
          if (strTemp.Find("WE") >= 0) { wDayByDay = 3; }
          if (strTemp.Find("TH") >= 0) { wDayByDay = 4; }
          if (strTemp.Find("FR") >= 0) { wDayByDay = 5; }
          if (strTemp.Find("SA") >= 0) { wDayByDay = 6; }
          if (strTemp.Find("SU") >= 0) { wDayByDay = 0; }

          integer d = 1 + ((wDayByDay - wday + 7) % 7) + (ord-1)*7;
          integer maxDay = 31;
          if ((m == 4) || (m == 6) || (m == 9) || (m == 11)){
            maxDay = 30;
          } elseif (m == 2){
            maxDay = 28;
            if (((y % 4) == 0) && (((y % 100) != 0) || ((y % 400) == 0))){
              maxDay = 29;
            }
          }

          if (d > maxDay){
            d = maxDay;
          }

          testDatum = (y # "-" # m # "-" # d # " " # startDatum.ToTime().Format("%T")).ToTime().ToInteger();
          bDayOk = true;
        }

        !// Nur wenn der Tag OK ist
        if (bDayOk)
        {
          iCount = iCount + 1;
          if ((testDatum<=maxDatum) && ((testDatum+dauer)>=minDatum)){
            bMatch = true;
            if (DEBUG){
              WriteLine("RRULE MATCH");
            }
            break;
          }
        }

        if (strFreq == "DAILY"){
          testDatum = testDatum + (86400 * iInterval);
        }elseif (strFreq == "WEEKLY"){
          testDatum = testDatum + 86400;
        }elseif ((strFreq == "MONTHLY") || (strFreq == "YEARLY")){
          integer y = testDatum.ToTime().Year();
          integer m = testDatum.ToTime().Month();
          integer d = testDatum.ToTime().Day();

          if (strFreq == "MONTHLY") { m = m + iInterval; }
          if (strFreq == "YEARLY")  { y = y + iInterval; }

          while (m > 12){
            m = m - 12;
            y = y + 1;
          }
          integer maxDay = 31;
          if ((m == 4) || (m == 6) || (m == 9) || (m == 11)){
            maxDay = 30;
          } elseif (m == 2){
            maxDay = 28;
            if (((y % 4) == 0) && (((y % 100) != 0) || ((y % 400) == 0))){
              maxDay = 29;
            }
          }

          if (d > maxDay){
            d = maxDay;
          }

          testDatum = (y # "-" # m # "-" # d # " " # testDatum.ToTime().Format("%T")).ToTime().ToInteger();
          !// WriteLine("Neu:"# testDatum.ToTime());
        }
      }

      startDatum = testDatum;
      endDatum = startDatum+dauer;

      if (!bMatch){
        continue;
      }
    }

    !// Nur wenn wir einen Trreffer haben
    if (!bMatch){
      continue;
    }

    !// In Text umwandeln
    startDatum = startDatum.ToInteger().ToString();
    endDatum = endDatum.ToInteger().ToString();

    if (DEBUG){
      WriteLine("Termin:\t" # RId # " / " # RaumName # "\t" # startDatum.ToInteger().ToTime() # "\t" # endDatum.ToInteger().ToTime());
    }

    !// Beschreibung (optional) des Termines extrahieren
    string strTemp = "";
    iPos = termin.Find("\nDESCRIPTION:");
    if (iPos>=0) {
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

if(log){logObj.State("Ende iCal-Skriptlauf==============================");}
WriteLine("Ende iCal-Skriptlauf");
