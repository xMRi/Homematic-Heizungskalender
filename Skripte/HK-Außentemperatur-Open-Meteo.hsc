!// Bestimmen der Außentemperatur für den Heizkalender
!//================================================================================================
!// Stand:    15.11.2026
!// Autor:    Martin Richter    (heizkalender@m-ri.de) http://blog.m-ri.de/
!// Projekt:  Helmut Diedrichs  (helmut@diedrichs.de) https://diedrichs.de
!//------------------------------------------------------------------------------------------------
!// Copyright (C) 2026 Martin Richter (xMRi-Software)
!// Dieser Teil des Heizkalenders ist freie Software und wird unter der GNU General Public License
!// Version 3 (GPLv3) oder neuer veröffentlicht.
!// Es besteht keinerlei Garantie oder Haftung. Nutzung auf eigene Verantwortung.
!//================================================================================================
!//
!// Doku siehe hier https://open-meteo.com/en/docs/dwd-api?forecast_days=1
!//
!// Dieser Aufruf liefert eine Temperatur Prognose für die entsprechenden Geokoordinaten für
!// die nächsten 24h und die Daten der letzten 24h.
!// Die Geokoordinaten selbst werden aus den Daten der CCU3 ausgelesen.
!// In dieser Variante ist es möglich eine Durchschnittstemperatur zu nutzen, die dadurch
!// den Temperaturverlauf nach oben/unten abdämpft. Die Anzahl der Stunden kann zwischen
!// 1h und 24h eingestellt werden für die Vergangenheit und 24h für die Prognose in die Zukunft
!// angegeben werden.
!//
!// Das Skript sollte jede volle Stunde laufen

!// TT: 2026-11-15 Division durch Null bei n==0 behoben; aktuellerWert initialisiert;
!// TT: 2026-11-14 DWD ICON-D2 statt icon_seamless (dwd-icon-Endpunkt, models=icon_d2);
!//                past_days von 2 auf 1 reduziert; stundenZurueck.Min(48) auf Min(24),
!//                ueberspringen-Formel von h+48 auf h+24 angepasst;
!//                current=temperature_2m aus URL entfernt (wird nicht ausgewertet).
!// TT: 2026-11-13 aktuelle AT-Stunde ergaenzt (HK2-Aussentemperatur-Aktuell, optional).
!//                Log-Text in Variable atLogText ausgelagert.
!// TT: 2026-10-04 Log-Eintrag um Zeitfenster ergaenzt (Fenster: -Xh/+Yh);
!//                Tippfehler in Kommentaren korrigiert; + durch # in DEBUG-Ausgaben ersetzt;
!//                Abbruch mit Log-Eintrag wenn keine Geokoordinaten in der CCU hinterlegt
!// TT: 2026-09-16 Robustheit verbessert: pos<0-Prüfung nach Find() eingebaut, verhindert
!//                falsches Parsen bei fehlgeschlagener/unvollständiger wget-Antwort.
!//                lat/lon: unnötige ToFloat()-Konversion und redundante ToString()-Aufrufe entfernt.
!// TT: 2026-09-16 Bugfix: + durch # bei URL-Konkatenation ersetzt. Der +-Operator interpretierte
!//                lat/lon (zahlenähnliche Strings) numerisch und schnitt die URL ab, so dass wget
!//                nur eine unvollständige URL erhielt und keine Temperaturdaten lieferte.

!//Eingabe eines Namens Präfix
!//Dies ist nur erforderlich wenn die Namensvorgabe abgeändert werden soll.
!//Wird hier ein Präfix eingeben so muss dieser in allen Skripten auch angegeben werden.
string vrp="";

!//Debug Ausgaben Ein und Aus schalten. 0 = Aus, 1 = Ein
boolean DEBUG=0;

!// Max Stunden in die Vergangenheit für die die Durchschnittstemperatur ermittelt werden soll
!// Maximal dürfen hier 24h eingegeben werden. Und ebenso die Voraussage für die nächsten Stunden,
!// es können maximal 24h voraus berücksichtigt werden. Über diese komplette Anzahl von Stunden
!// wird der Durchschnitt berechnet.
!// Laut Chat/GPT ist 18/6 ein guter Wert für Fussbodenheizungen. Bei normalen Heizkörpern bietet sich
!// 12/3 an. Das thermische Gedächtnis von Häusern liegt bei ca. 10h.
!// Da unsere Termine selten länger als 3h sind wird die Vorheizzeit kaum von der Zukunft beeinflusst
integer stundenZurueck = 18;    !// maximal 24h
integer stundenVoraus = 6;      !// Maximal 24h

!// Logging in "Log" mit 1 zwingend einschalten oder mit -1 zwingend Ausschalten
!// Mit 0 wird die Einstellung aus der HKx-Logging übernommen
integer log=0;

!//#######---Ende Variabler Bereich---#############################################################
!//Im Folgenden Hier keine Veränderungen vornehmen!

!// Logging vorbereiten
var logObj=dom.GetObject(vrp+"HK-Log");
var loggingObj=dom.GetObject(vrp+"HK-Logging");

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

!// Variablen
string error="kein";
string command;
string stemp;
string lat=system.Latitude();
string lon=system.Longitude();

if (DEBUG){
  WriteLine(lat # "\n");
  WriteLine(lon # "\n");
}

!// Abbruch wenn keine Geokoordinaten in der CCU hinterlegt sind
if (lat=="" || lon=="" || lat.ToFloat()==0.0 || lon.ToFloat()==0.0){
  if(log){logObj.State("Open-Meteo: Keine Geokoordinaten in der CCU hinterlegt. Bitte in den CCU-Einstellungen eintragen.");}
  WriteLine("Open-Meteo: Keine Geokoordinaten in der CCU hinterlegt!");
} else {

  !// Temperaturwerte lesen: 24h davor (past_days=1), heute+morgen voraus (forecast_days=2).
  !// DWD ICON-D2: 2,2km Aufloesung, Zentraleuropa, alle 3h aktualisiert.
  !// forecast_days=2 noetig damit das 6h-Voraus-Fenster auch abends genug Daten hat.
  command = "wget --timeout=3 -O - 'https://api.open-meteo.com/v1/dwd-icon?latitude=" # lat # "&longitude=" # lon # "&models=icon_d2&hourly=temperature_2m&past_days=1&forecast_days=2&timezone=Europe%2FBerlin'";

  !// Da es immer wieder mal zu Fehlern kommt, wiederholen wir die Anfrage im Abstand von 1 Sekunde mehrfach
  integer iRetry = 10;
  while (iRetry>0) {
    system.Exec(command, &stemp, &error);
    if (DEBUG){
      WriteLine(command # "\n");
      WriteLine(stemp # "\n");
    }

    !// passenden eintrag finden
    !// 18 = Länge von "temperature_2m":[ -> Sprung hinter die öffnende Klammer
    integer pos=stemp.Find("\"temperature_2m\":[");
    boolean bError = false;
    if (pos<0) {
      bError = true;
    } else {
      !// Ende der Temperaturdaten suchen
      stemp=stemp.Substr(pos+18,1000);
      pos=stemp.Find("]");
      if (pos<0) {
        bError = true;
      }
    }

    !// Fehlerbehandlung wenn Daten nicht gefunden wurden -> Retries
    if (bError){
      !// Schließende Klammer fehlt -> Antwort abgeschnitten
      if(log){logObj.State("Open-Meteo: Antwort unvollständig, Retry " # (11-iRetry) # "/10");}
      if(DEBUG){WriteLine("Open-Meteo: Antwort unvollständig, Retry " # (11-iRetry) # "/10\n");}
      iRetry = iRetry-1;
      string dummy;
      system.Exec("sleep 1", &dummy, &dummy);
      continue;
    }

    !// Daten extrahieren.
    stemp=stemp.Substr(0,pos);
    if (DEBUG){
      WriteLine(stemp # "\n");
    }

    !// Alle Einträge summieren und Mittelwert bilden
    string temp;
    real summe=0.0;
    integer n=0;

    !// Bestimmen ab wann wir von den alten Daten Temperaturen übernehmen.
    !// Array beginnt 24h vor Mitternacht (past_days=1). Heute 00:00 = Index 24.
    integer h = system.Date("%H").ToInteger();

    !// Begrenzungen festlegen
    stundenZurueck = stundenZurueck.Min(24).Max(1);
    stundenVoraus = stundenVoraus.Min(24).Max(0);
    integer ueberspringen = h+24-stundenZurueck;

    if (DEBUG){
      WriteLine("Uhrzeit:        " # h);
      WriteLine("Stunden zurück: " # stundenZurueck.ToInteger());
      WriteLine("Stunden voraus: " # stundenVoraus.ToInteger());
      WriteLine("Überspringen:   " # ueberspringen);
      WriteLine("---------");

      integer i=0;
      foreach (temp, stemp.Split(","))
      {
        WriteLine((i % 24) # ": " # temp);
        i = i+1;
      }
      WriteLine("---------");
    }

    !// Werte berechnen
    integer i=0;
    real aktuellerWert = 0.0;
    real tempWert = 0.0;
    foreach (temp, stemp.Split(","))
    {
      !// Werte bis zur aktuellen Stunde überspringen wir.
      if ((i>h) && i>ueberspringen){
        tempWert = temp.ToFloat();
        if (DEBUG){
          WriteLine((i % 24) # ": " # temp);
        }
        !// Durchschnitt: nur die ersten stundenZurueck+stundenVoraus Werte
        if (n<(stundenZurueck+stundenVoraus)){
          summe = summe+tempWert;
          n = n+1;
        }
        if (n==stundenZurueck){
          aktuellerWert = tempWert;
          if (DEBUG){
            WriteLine("<-- Aktueller Wert");
          }
        }
        !// Abbruch wenn Durchschnitt fertig
        if (n>=(stundenZurueck+stundenVoraus)) {
          break;
        }
      }
      i = i+1;
    }

    if (DEBUG){
      WriteLine("---------");
      WriteLine(summe);
      WriteLine(n);
    }
    !// Ergebnis schreiben
    if (n!=0){
      temp = (summe/n).ToString(1);
      string atLogText = "Akt. AT= " # aktuellerWert.ToString(1) # "°C / Durchschn. AT= " # temp # "°C (Fenster: -" # stundenZurueck.ToInteger() # "h/+" # stundenVoraus.ToInteger() # "h)";
      WriteLine(atLogText);
      if (log) { logObj.State(atLogText); }
      dom.GetObject(vrp+"HK2-Aussentemperatur").State(temp);
      !// Optionale Variable: aktuelle Temperatur (wird nur geschrieben wenn sie existiert)
      var svAkt = dom.GetObject(vrp+"HK2-Aussentemperatur-Aktuell");
      if (svAkt) { svAkt.State(aktuellerWert.ToString(1)); }
      break;
    } else {
      if (log) { logObj.State("Keine Werte für die Außentemperatur gefunden!"); }
      !// Unerwünschtes Ergebnis/Fehler, also ein Retry mehr
      iRetry = iRetry-1;
      !// Verzögern
      string dummy;
      system.Exec("sleep 1", &dummy, &dummy);
    }
  }

}
