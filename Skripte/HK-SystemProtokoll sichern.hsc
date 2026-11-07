!// Sichern des Systemprotokolls auf dem USB Stick
!//================================================================================================
!// Stand:    23.01.2026
!// Autor:    Martin Richter    (heizkalender@m-ri.de) http://blog.m-ri.de/
!// Projekt:  Helmut Diedrichs  (helmut@diedrichs.de) https://diedrichs.de
!//------------------------------------------------------------------------------------------------
!// Copyright (C) 2026 Martin Richter (xMRi-Software)
!// Dieser Teil des Heizkalenders ist freie Software und wird unter der GNU General Public License
!// Version 3 (GPLv3) oder neuer veröffentlicht.
!// Es besteht keinerlei Garantie oder Haftung. Nutzung auf eigene Verantwortung.
!//================================================================================================
!//
!// Das grundsätzliche Problem ist, das das Systemprotokoll fülchtig ist. Alte Einträge werden
!// automatisch verworfen, wenn es voll wird. Weiterhin überlebt es auch keinen Reboot der CCU
!// Für einen Reboot sollte also unbedingt unser Programm Tool-Reboot benutzt werden um vor dem
!// Reboot das Protokoll zu sichern.
!// Für das Sichern wird eine Systemvariable benutzt, in der der letzte Protokoll Eintrag gespeichert
!// wird.
!//
!// Das Skript sollte 17/23/29min laufen.
!// Die Anzahl der zu erhaltenen LOG Dateien kann eingestellt werden.
!// Eine Log-Datei wird ca. 250KB bis 1MB groß, je nach Anzahl der Schaltvorgänge.

!// MRi: 2026-01-14 Wöchentliche oder tägliche Logs erlauben

!// Der Pfad sollte keine Leerzeichen enthalten
string pfad = "/media/usb1/";
!// Prefix für den Namen, er wird dann mit dem Datum und der Extension .LOG erweitert:
!// Also z.B. HK-LOG_2025-11-20.log!
string prefix = "HK-Log_";
!// Anzahl der Dateien die erhalten bleiben sollen. Die ältesten Dateien werden automatisch gelöscht.
integer AnzahlDateien=30;

!// Debug Mouds, wir haben mehrere Levels 0
integer DEBUG=0;

!// Wöchentliche Logs = 1, Logs getrennt für jeden Tag = 0
boolean bWoechentlicheLogs = true;

!//#######---Ende Variabler Bereich---####################################################################
!//Im Folgenden Hier keine Veränderungen vornehmen!

string cmd = "";
string stdout;
string stderr;
string dateiname;

!// Prüfen ob USB1 überhaupt verfügbar ist
dateiname = pfad;
if (dateiname.EndsWith("/")) {
  !// Ausgabe in mount hat kein endenden Slash
  dateiname = dateiname.Substr(0,dateiname.Length()-1);
}
system.Exec("mount | grep " # dateiname, &stdout, &stderr);
if (!stdout) {
    WriteLine(pfad # " is NOT available.");
    quit;
}

!// Cleanup. Lösche so viele Dateien, biss nur noch die entsprechende Anzahl übrig sind.
cmd = "ls -w 1 -r '" # pfad # prefix #"'*.log";
!if(DEBUG){WriteLine(cmd);}
system.Exec(cmd,&stdout,&stderr);
!if(DEBUG){WriteLine(stdout);}
!if(DEBUG){WriteLine(stderr);}

integer cnt=0;
foreach(dateiname,stdout.Trim().Split("\n")) {
  if (cnt>=AnzahlDateien){
    if(DEBUG){WriteLine("Löschen=" # dateiname);}
    cmd = "rm '" # dateiname #"' &";
    !if(DEBUG){WriteLine(cmd);}
    system.Exec(cmd);
  }
  cnt=cnt+1;
}

!// Maximale Anzahl des Systemprotokolls
integer cnt = dom.GetHistoryDataCount();
if (cnt==0){
  if(DEBUG){WriteLine("Keine Daten Systemprotokoll Daten. Abbruch!");}
  quit;
}
integer rCount;
integer start=0;
!// Suche die letzte Datei, die wir haben
cmd = "ls -w 1 '" # pfad # prefix #"'*.log | tail -n 1";
!if(DEBUG){WriteLine(cmd);}
stdout = "";
system.Exec(cmd,&stdout,&stderr);
!if(DEBUG){WriteLine(stdout);}
!if(DEBUG){WriteLine(stderr);}
if (stdout!=""){
  !// Wir haben eine Datei und holen die letzte Zeile
  dateiname = stdout.Trim();
  if(DEBUG){WriteLine("dateiname=" # dateiname);}
  cmd = "tail -n 1 '" # dateiname # "'";
  !if(DEBUG){WriteLine("cmd="#cmd);}
  stdout="";
  system.Exec(cmd,&stdout,&stderr);
  !if(DEBUG){WriteLine("stdout="# stdout);}
  !if(DEBUG){WriteLine("stderr="# stderr);}
  if (stdout!=""){
    !// Binary search um den Start mit diesem Datum zu finden
    string suchtext = stdout.StrValueByIndex("\t",0);
    if(DEBUG){WriteLine("Letzte geschriebene Daten. suchtext=" # suchtext);}
    integer low = 0;
    integer high = cnt-1;
    while(low<=high){
      integer mid = (low + high) / 2;
      string sDatum = dom.GetHistoryData(mid,1,&rCount).StrValueByIndex(";",3);
      !if(DEBUG){WriteLine(low # "-" # mid # "-" # high # "-" # sDatum);}
      if(sDatum==suchtext){
        break;
      }elseif(sDatum<suchtext) {
        low = mid + 1;
      }else{
        high = mid - 1;
      }
    }

    !// Mid ist nun unser StartIndex
    start = mid;
  }

  !// Wenn wir den Start haben, gehen wir so weit zurück bis wir den ersten Datensatz
  !// mit diesem Datum haben. Es is möglich, das wir nicht auf dem ersten Datenatz landen
  !// mit der binären Suche
  while((start>0)){
    if(dom.GetHistoryData(start-1,1,&rCount).StrValueByIndex(";",3)!=suchtext){
      break;
    }
    start=start-1;
  }
}else{
  !// Wir haben keine Datei. Also stoppen wir hier und schreiben ab Zeile 1
  if(DEBUG){WriteLine("Keine zulezt geschriebenen Daten gefunden!");}
}
if(DEBUG){WriteLine("Start des Speicherns bei Systemprotokolleintrag=" # start);}

!// Teile des nachfolgenden Codes wurden aus dem folgenden Thread übernommen:
!//     https://homematic-forum.de/forum/viewtopic.php?f=19&t=75602&p=847023#p735221

!// Wir starten im Modus Suchen
boolean modusSuchen=true;
string sDatensaetze = dom.GetHistoryData(start,cnt-start,&rCount);
string sDatensatz;
string logLine;
string letzterGeschriebenerDatensatz;
string aktDatum="";
string aktDateTime="";

while (true){
  string zuSchreiben="";

  !// Wir durchlaufen jetzt das Protokoll, entweder suchen wir oder wir schreiben
  integer iDatensatz = 0;
  while (true){
    !// Bestimme wieviele Datensätze in der nächsten Gruppe sind
    sDatensatz = sDatensaetze.StrValueByIndex("\t",iDatensatz);
    if (!sDatensatz){
      break;
    }
    integer iGroupIndex = sDatensatz.StrValueByIndex(";",0).ToInteger();
    integer iNaechsteGruppe = iDatensatz;
    while(sDatensaetze.StrValueByIndex("\t",iNaechsteGruppe).ToInteger()==iGroupIndex){
      iNaechsteGruppe = iNaechsteGruppe+1;
    }

    !// Teste auf Dateiwechsel
    string sDateTime = sDatensatz.StrValueByIndex(";",3);
    string stmpDate = sDateTime.StrValueByIndex(" ",0);
    string stmpTime = sDateTime.StrValueByIndex(" ",1);

    !// Wir loggen tagesweise oder wochenweise
    if (bWoechentlicheLogs){
      !// Wohenanfang suchen
      stmpDate = (stmpDate.ToTime().ToInteger()-((stmpDate.ToTime().Format("%u").ToInteger()-1)*86400)).ToTime().Format("%F");
    }
    !if(DEBUG){WriteLine("aktDatum=" # aktDatum # " stmpDate="#stmpDate);}

    if ((aktDatum=="") || (aktDatum!=stmpDate)){
      !// Start? Dann ist aktDatum leer. Ansonsten bestehende Daten speichern
      if(DEBUG){WriteLine("Datum=" # stmpDate);}
      if (aktDatum){
        !// Alte Daten speichern, wenn vorhanden
        if (zuSchreiben.Length()>0){
          !// Zeilenschaltung entfernen, denn den haben wir schon
          if(DEBUG){WriteLine("Dateiname="#dateiname);}
          if(DEBUG){WriteLine("Daten schreiben 1: " # dateiname # " Bytes: " # zuSchreiben.Length());}
          cmd = "echo -n '" # zuSchreiben # "' >> '" # dateiname # "' &";
          if (!DEBUG){
            system.Exec(cmd);
          }
          zuSchreiben = "";
        }else{
          !// Sollten wir gerade in den Schreibmodus gegangen sein, aber nun einen Dateiwechsel
          !// haben, dann hatten wir gerade den letzten Datensatz gefunden. Und wir suchen auch in dern
          !// neuen Datei weiter
          modusSuchen = true;
        }
      }

      !// Datumswechsel. Neue Datei.
      aktDatum = stmpDate;
      aktDateTime = sDateTime;
      !// neuen Dateiname setzen
      dateiname = pfad # prefix # aktDatum # ".log";
      if(DEBUG){WriteLine("Dateiname="#dateiname);}
      if(modusSuchen){
        !// Wir laden den zuletzt gelesenen Datensatz
        cmd = "tail -n 1 '" # dateiname # "'";
        !if(DEBUG){WriteLine("cmd="#cmd);}
        stdout="";
        system.Exec(cmd,&stdout,&stderr);
        !if(DEBUG){WriteLine("stdout="# stdout);}
        !if(DEBUG){WriteLine("stderr="# stderr);}

        !// Evtl. diesen Datensatz suchen, wenn da was war, ist kein Datensatz (keine Datei vorhanden)
        !// gehen wir sofort in den Schreibmodus
        letzterGeschriebenerDatensatz = stdout.Trim();
        !if(DEBUG){WriteLine("letzterGeschriebenerDatensatz=" # letzterGeschriebenerDatensatz);}
        modusSuchen = (letzterGeschriebenerDatensatz!="");
        if(DEBUG){WriteLine("modusSuchen=" # modusSuchen # " letzterGeschriebenerDatensatz=" # letzterGeschriebenerDatensatz);}
      }
    }

    !// Wenn Datum und Zeit nicht passt können wir das überspringen
    if(modusSuchen && letzterGeschriebenerDatensatz && !letzterGeschriebenerDatensatz.StartsWith(sDateTime)){
      !// Kein Treffer, wir sind im Suchmodus
      iDatensatz = iNaechsteGruppe;
      continue;
    }

    !// Daten der nächsten Gruppe zusammenbauen
    string sCollectedNames = "";
    string sCollectedValues = "";
    string sCollectedDateTimes = "";

    while(iDatensatz<iNaechsteGruppe) {
      sDatensatz = sDatensaetze.StrValueByIndex("\t",iDatensatz);
      if(DEBUG){WriteLine("sDatensatz="#sDatensatz);}
      string sDatapointId = sDatensatz.StrValueByIndex(";",1);
      string sRecordedValue = sDatensatz.StrValueByIndex(";",2);
      string sDateTime = sDatensatz.StrValueByIndex(";",3);

      !// zu loggende Daten aufbauen
      string sDatapointName = "";
      object oHistDP = dom.GetObject( sDatapointId );
      if( oHistDP ) {
        object oDP = dom.GetObject( oHistDP.ArchiveDP() );
        if( oDP ) {
          sDatapointName = oDP.Name();
          boolean bSysVar = (oDP.IsTypeOf(OT_VARDP) || oDP.IsTypeOf(OT_ALARMDP));
          if( !bSysVar ) {
            object oCH = dom.GetObject( oDP.Channel() );
            if( oCH ) {
              sDatapointName = oCH.Name();
            }
           }
        }

        string sRet = "";
        object to = dom.GetObject( oDP.ID());
        if( to ) {
          if( to.IsTypeOf( OT_VARDP ) || to.IsTypeOf( OT_ALARMDP ) ) {
            integer itoVT = to.ValueType();
            integer itoST = to.ValueSubType();
            boolean btoLogic  = ( (itoVT==ivtBinary)  && (itoST==istBool)    );
            boolean btoList   = ( (itoVT==ivtInteger) && (itoST==istEnum)    );
            boolean btoNumber = ( (itoVT==ivtFloat)   && (itoST==istGeneric) );
            boolean btoAlarm  = ( (itoVT==ivtBinary)  && (itoST==istAlarm)   );
            boolean btoString  = ( (itoVT==ivtString)  && (itoST==istChar8859));
    !// MRi: Wir geben den  Variablen Typ nicht aus
    !        if( (btoLogic || btoAlarm) && ((sRecordedValue == "0") || (sRecordedValue == "")) ) {
    !          sRet=sRet#to.ValueName0(); } else { sRet=sRet#to.ValueName1();
    !        }
            if( (btoList) && (sRecordedValue == "") ) {
              sRet=sRet#web.webGetValueFromList(to.ValueList(),0); } else { sRet=sRet#web.webGetValueFromList(to.ValueList(),sRecordedValue.ToInteger());
            }
            if( btoNumber ) {
              if (sRecordedValue == "") {
                real n = 0.0;
                sRet = sRet # n.ToString() # " (" # n.ToString(2);
              } else {
                sRet = sRet # sRecordedValue.ToString() # " (" # sRecordedValue.ToString(2);
              }
              if( to.ValueUnit() == "" ) { sRet = sRet # ")"; }
            }
            if (btoString) {
        !// MRi: Wir entfernen Zeilenschaltungen und Sicherheitshalber tauschen wir DoubleQuotes n single Quotes
              sRet = sRet # sRecordedValue;
              sRet = sRet.Replace("\"", "\'");
              sRet = sRet.Replace("\r\n", " ");
              sRet = sRet.Replace("\r", " ");
              sRet = sRet.Replace("\n", " ");
            }
            if( to.ValueUnit() != "" ) {
              sRet=sRet#" "#to.ValueUnit();
              if( btoNumber ) { sRet = sRet # ")"; }
            }
          } else {
            string tsShortKey = to.HSSID();
            string tsLongKey = to.HSSID();
            object toCH = dom.GetObject( to.Channel() );
            if( toCH ) { tsLongKey = toCH.ChnLabel()#"|"#tsLongKey; }

            boolean tbOptionList = ( (to.ValueType() == ivtInteger) && (to.ValueSubType() == istEnum) );
            boolean tbAction = ( to.ValueSubType() == istAction );
            boolean tbBinary = ( to.ValueType() == ivtBinary );
            boolean tbRead = (to.Operations() & OPERATION_READ);
            boolean tbEvent = (to.Operations() & OPERATION_EVENT);
            boolean tbWrite = (to.Operations() & OPERATION_WRITE);

            boolean bBinary = ( to.ValueTypeStr() == "Binary" );
            boolean bFloat = ( to.ValueTypeStr() == "Float" );
            boolean bSpecial = false;

            string sVUTmp = to.ValueUnit().ToString();
            string sSpace = " ";

            real fVal1 = 0.0;
            real fVal2 = 0.0;
            string sSpecial = "";
            string stmpSV;
            foreach(stmpSV,oDP.EnumSpecialIDs()) {
               fVal1 = oDP.GetSpecialValue(stmpSV);
               fVal2 = sRecordedValue.ToFloat();
               if( fVal1 == fVal2 ) {
                 bSpecial = true;
                 sSpecial = stmpSV;
                 sRecordedValue = "";
                 sVUTmp = "";
                 sSpace = "";
               }
            }

            if( tbBinary && (tbRead || tbAction) ) {
              if( sRecordedValue == "0" ) {
                tsShortKey = tsShortKey#"=FALSE";
                tsLongKey = tsLongKey#"=FALSE";
              } else {
                tsShortKey = tsShortKey#"=TRUE";
                tsLongKey = tsLongKey#"=TRUE";
              }
            }

            if( tbOptionList ) {
              tsShortKey = tsShortKey#"="#web.webGetValueFromList( to.ValueList(), sRecordedValue );
              tsLongKey = tsLongKey#"="#web.webGetValueFromList( to.ValueList(), sRecordedValue );
            }

            if( bSpecial ) {
              tsShortKey = tsShortKey#"="#sSpecial;
              tsLongKey = tsLongKey#"="#sSpecial;
            }

            string sVTmp = tsLongKey ;
            if( !sVTmp.Length() ) { sVTmp = tsShortKey; }

            if( !bSpecial ) {
              if( sVUTmp == "100%" ) {
                sRecordedValue = sRecordedValue.ToFloat() * 100;
                sRecordedValue = sRecordedValue.ToString();
                sVUTmp = "%";
              }

              if( sVUTmp == "degree" ) { sVUTmp = "°"; }

              if( bBinary ) { sRecordedValue = ""; sSpace = ""; }

              if( bFloat ) { sRecordedValue = sRecordedValue.ToFloat().ToString(2); }

              if( (!bBinary) && (!bFloat) ) {
                if (((toCH.Label() != "HmIPW-DRAP") && (toCH.Label() != "HmIP-HAP")) || (sVUTmp == "°C") || (sVUTmp == "V")) {
                  sRecordedValue = sRecordedValue.ToInteger();
                  sRecordedValue = sRecordedValue.ToString(0);
                }
              }

              if( tbOptionList ) { sRecordedValue = ""; sVUTmp = ""; sSpace = ""; }
            }

            sVTmp = sVTmp#sSpace#sRecordedValue#sVUTmp;
            sRet = sVTmp;
          }
        }

        sRecordedValue = sRet;

        sCollectedNames = sDatapointName;
        sCollectedDateTimes = sDateTime;

        if(sCollectedValues) {
          sCollectedValues = sCollectedValues # ", ";
        }
        sCollectedValues = sCollectedValues # sRecordedValue;
      }

      !// Auf nächsten Datehnsatz
      iDatensatz = iDatensatz+1;
    }

    !// Logline bauen
    logLine=sCollectedDateTimes#"\t"#sCollectedNames#"\t"#sCollectedValues;
    if(DEBUG){WriteLine("logline=" # logLine.Trim());}

    !// Prüfe ob wir die Zeile erreicht haben.
    if (modusSuchen){
      if (logLine==letzterGeschriebenerDatensatz){
        if(DEBUG){WriteLine("Datensatz gefunden!\nAb jetzt Daten schreiben!");}
        modusSuchen = false;
      }
    }else{
      !// Wir sammeln die Daten
      zuSchreiben = zuSchreiben # logLine # "\n";

      !// Wenn wir die maximale Größe von 10000 erreicht haben müssen wir schreiben
      !// Bei einer größe über 120000 Bytes versagt echo, aber da wir einen Append nutzen,
      !// ist das kein Problem, den Befehl mehrfach auszuführen
      if (zuSchreiben.Length()>10000){
        !// Zeilenschaltung entfernen, denn den haben wir schon
        if(DEBUG){WriteLine("Daten schreiben 2: " # dateiname # " Bytes: " # zuSchreiben.Length());}
        string cmd = "echo -n '" # zuSchreiben # "' >> '" # dateiname # "' &";
        if (!DEBUG){
          system.Exec(cmd);
        }
        zuSchreiben = "";
      }
    }
  }

  !// Wir haben die Liste einmal durch.
  if (modusSuchen){
    !// Wenn wir hierher kommen, dann haben wir keinen passenden datensatz gefunden
    !// Wir starten von vorne und schreiben jetzt
    if(DEBUG){if(DEBUG){WriteLine("Modus: Suchen. Stop! Keine Daten gefunden, alle Daten sammeln");}}
    modusSuchen = false;
    aktDatum = "";
  }else{
    !// Jetzt haben wir alle Daten zum schreiben fertig
    !if(DEBUG){if(DEBUG){WriteLine(zuSchreiben);}}
    if(DEBUG){if(DEBUG){WriteLine("Modus: Schreiben. Stop! Gefundene Daten schreiben");}}
    break;
  }
}

!// Rest schreiben
if (zuSchreiben.Length()>0){
  !// Zeilenschaltung entfernen, denn den haben wir schon
  if(DEBUG){WriteLine("Daten schreiben 3: " # dateiname # " Bytes: " # zuSchreiben.Length());}
  string cmd = "echo -n '" # zuSchreiben # "' >> '" # dateiname # "' &";
  if (!DEBUG){
    system.Exec(cmd);
  }
}else{
  if(DEBUG){WriteLine("Daten schreiben 3: Keine Daten zu schreiben " # dateiname);}
}

WriteLine("Alles fertig...");


