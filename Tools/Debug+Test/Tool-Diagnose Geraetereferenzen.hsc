!// Diagnose: Geraetereferenzen (Sensor/Aktoren) in den Raumvariablen pruefen
!//================================================================================================
!// Stand:    29.09.2026
!// Autor:    Martin Richter    (heizkalender@m-ri.de) http://blog.m-ri.de/
!// Projekt:  Helmut Diedrichs  (helmut@diedrichs.de) https://diedrichs.de
!//================================================================================================
!// READ-ONLY. Aendert nichts auf der CCU.
!//
!// Prueft fuer jede Raumvariable aus HK2-HKG-Liste, ob die im WERT referenzierten
!// Geraete (Temperatursensor in Feld 6, Schaltaktoren ab Feld 7) tatsaechlich als
!// Objekt auf der CCU existieren.
!//
!// Hintergrund: Der Raumvariablen-NAME folgt der ChurchTools-Konvention
!// (z.B. HKG-Raum-UG-Kueche), die Geraete-Referenzen im WERT folgen der technischen
!// CCU-Konvention (z.B. Temperatursensor_UG_Kueche, Schaltaktor_UG_Kueche). Wurde ein
!// Geraet umbenannt, nachdem der Wert gesetzt wurde, zeigt die Referenz ins Leere und
!// HK-Skript 2 kann still nicht heizen/schalten.
!//
!// Wert-Aufbau der Raumvariable (Semikolon-getrennt), Feld-Indizes 0-basiert:
!//   0=Status 1=Modus 2=Heiztyp 3=Wohlfuehltemp[/Grundtemp] 4=Vorheizzeit 5=VorzeitAus
!//   6=Sensor (Name[:Kanal])   7+=Schaltaktoren

!// Eingabe eines Namens Praefix (nur noetig wenn die Namensvorgabe geaendert wurde)
string vrp="";

!//#######---Ende Variabler Bereich---#############################################################

object oHKGListe = dom.GetObject(vrp # "HK2-HKG-Liste");
if(!oHKGListe){
  WriteLine("FEHLER: Systemvariable \"" # vrp # "HK2-HKG-Liste\" nicht gefunden!");
  quit;
}

string HKGListe = oHKGListe.State();
WriteLine("HK2-HKG-Liste: " # HKGListe);
WriteLine("");

integer anzOK      = 0;
integer anzFehler  = 0;

string RaumVarListe;
foreach(RaumVarListe, HKGListe.Split(";")){
  !// Im Multiraum-Fall sind mehrere Raumvariablen durch + getrennt.
  string RVN;
  foreach(RVN, RaumVarListe.Split("+")){

    object oRaum = dom.GetObject(RVN);
    if(!oRaum){
      WriteLine("[RAUMVAR FEHLT] " # RVN # " existiert nicht auf der CCU!");
      anzFehler = anzFehler+1;
      continue;
    }

    string RVI = oRaum.State();
    WriteLine("Raum: " # RVN);
    WriteLine("  Wert: " # RVI);

    string HSFlag = RVI.StrValueByIndex(";",1);

    !// --- Sensor (Feld 6) pruefen ---
    !// Kann einen :Kanal-Suffix tragen. Der Objektname ist der Teil vor dem ersten ":".
    string sensorFeld = RVI.StrValueByIndex(";",6);
    if(sensorFeld){
      string sensorName = sensorFeld.StrValueByIndex(":",0);
      if(sensorName){
        object oSensor = dom.GetObject(sensorName);
        if(oSensor){
          WriteLine("  Sensor  [ok]   " # sensorFeld);
          anzOK = anzOK+1;
        }else{
          WriteLine("  Sensor  [FEHLT] " # sensorFeld # "  -> Objekt \"" # sensorName # "\" nicht gefunden!");
          anzFehler = anzFehler+1;
        }
      }
    }

    !// --- Aktoren (Feld 7+) pruefen ---
    !// Alles ab dem 7. Feld ist die Aktorenliste (Semikolon-getrennt). Wir bauen sie
    !// mit derselben Logik wie HK-Skript 2 auf: alle Zeichen ab Feldgrenze iMaxEntry.
    !// iMaxEntry=6, im Modus HS +1 (erster Aktor ist Thermostat/Datenquelle, kein Schaltaktor).
    integer iPos = 0;
    integer iEntry = 1;
    integer iMaxEntry = 6;
    if(HSFlag=="HS"){
      iMaxEntry = iMaxEntry+1;
    }
    string AktorenListe = "";
    while(iPos<RVI.Length()){
      if(iEntry>iMaxEntry){
        AktorenListe = AktorenListe # RVI.Substr(iPos,1);
      }elseif(RVI.Substr(iPos,1)==";"){
        iEntry = iEntry+1;
      }
      iPos = iPos+1;
    }

    if(AktorenListe==""){
      WriteLine("  Aktoren [--]   keine Schaltaktoren (Modus " # HSFlag # ")");
    }else{
      string AktAktor;
      foreach(AktAktor, AktorenListe.Split(";")){
        if(AktAktor){
          object oAktor = dom.GetObject(AktAktor);
          if(oAktor){
            WriteLine("  Aktor   [ok]   " # AktAktor);
            anzOK = anzOK+1;
          }else{
            WriteLine("  Aktor   [FEHLT] " # AktAktor # "  -> Objekt nicht gefunden!");
            anzFehler = anzFehler+1;
          }
        }
      }
    }

    WriteLine("");
  }
}

WriteLine("================================================================");
WriteLine("Gefundene Referenzen OK:      " # anzOK.ToString());
WriteLine("Fehlende Referenzen (FEHLT):  " # anzFehler.ToString());
if(anzFehler>0){
  WriteLine("");
  WriteLine("WARNUNG: Es gibt tote Geraete-Referenzen. HK-Skript 2 kann fuer");
  WriteLine("         diese Raeume still nicht heizen/schalten. Wert der");
  WriteLine("         betroffenen Raumvariable auf den aktuellen Geraetenamen");
  WriteLine("         korrigieren (siehe Tool-Test Raumvariable setzen).");
}else{
  WriteLine("");
  WriteLine("Alle referenzierten Geraete existieren.");
}
