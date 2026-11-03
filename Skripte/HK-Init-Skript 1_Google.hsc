!// Skript zum Anlegen der Systemvariablen für Skript 1 (Google)
!//================================================================================================
!// Stand:    18.10.2026
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
!//   HKP-GK-V-3.2.1 Variablen zu Skript1_GoogleKalender_V1.2.c
!// Der ursprüngliche Code wurde geschrieben von:
!//   Lukas Helduser (Youtube: https://www.youtube.com/LukasvandeHaag) 
!// Ich (MRi) habe diesen Code dann erweitert, korrigiert und verbessert um sie an die Nutzung in
!// meiner Gemeinde anzupassen.
!//

!//Dieses Skript erstellt die nötigen Systemvariablen des Heizkalender für Skript 1 Google Kalender
!//Hinweis: Ein erneutes Ausführen dieses Programms ändert bestehende Variablen und ihren Inhalt nicht

!// MRi: 2026-11-03 Aufteilung Skript2 Termine vorbereiten, Skript 3 Schalten
!// TT:  2026-10-18 HK1-Vorlaufzeit: neue optionale Systemvariable (Integer, Default 720 min)

!//Eingabe eines Namens Präfix
!//Dies ist nur erforderlich wenn die Namensvorgabe abgeändert werden soll.
!//Wird hier ein Präfix eingeben so muss dieser in allen Skripten auch angegeben werden.
string vrp="";

!// Namen der Variablen, die angelegt werden sollen
string nm=  "HK1-Schaltliste;" #
            "HK1-GK-API-Key;" #
            "HK1-GK-Kalender-ID;" #
            "HK1-R-Liste;" #
            "HK1-Vorlaufzeit";

!// Beschreibungstexte
string be=  "Gelesene Termine aus Skript 1. Hier bitte nichts verändern!;" #
            "API-Key für den Google-Kalender;" #
            "ID des Google-Kalender;" #
            "Zuordnung der Räume aus der Ressourcenverwaltung;" #
            "Zeithorizont fuer Terminabfrage in Minuten (Default 720, max. 1380)";

!// Typen
string tp=  "string;" #
            "string;" #
            "string;" #
            "string;" #
            "integer";

!// Vorgabe Werte
string vl=  ";" #
            ";" #
            ";" #
            ";" #
            "720";

!// Einheit (z.B. °C)
string vu=  ";" #
            ";" #
            ";" #
            ";" #
            "min";

!// Zusätzliche Info Texte für
!//   - Boolean   - Werte für eine Variable durch + getrennt
!//   - Numerisch - min/max durch + getrennt
string wr=  ";" #
            ";" #
            ";" #
            ";" #
            "0+1380";

!// Protokollierungs Flags
string pr=  "1;" #
            "1;" #
            "1;" #
            "1;" #
            "1";                                                                 

!//------------------------------------------------------------------------------------------------
!// Ab hier Standard Code zum erzeugen von Variablen
integer i=0;

WriteLine("Start ...!");
while(true){
  if (nm.StrValueByIndex(";",i)==""){
    break;
  }
  string name=vrp+nm.StrValueByIndex(";",i);
  object  svObj  = dom.GetObject(name);
  if (!svObj){
    !// Variable existiert nicht
    object svObjects = dom.GetObject(ID_SYSTEM_VARIABLES);
    svObj = dom.CreateObject(OT_VARDP);
    svObjects.Add(svObj.ID());
  
    svObj.Name(name);
    svObj.DPInfo(be.StrValueByIndex(";",i));
    svObj.ValueUnit(vu.StrValueByIndex(";",i));
    svObj.DPArchive(pr.StrValueByIndex(";",i).ToInteger()!=0);
    svObj.Internal(false);
    svObj.Visible(true);

    !// Nach typ optionale Werte setzen
    string typ = tp.StrValueByIndex(";",i);
    if(typ=="string"){
      svObj.ValueType(ivtString);
      svObj.ValueSubType(istChar8859);
      svObj.State(vl.StrValueByIndex(";",i).Replace(",",";"));
    }elseif(typ=="integer"){
      svObj.ValueType(ivtFloat);
      svObj.ValueSubType(istGeneric);
      svObj.State(vl.StrValueByIndex(";",i).ToFloat());
      svObj.ValueMin(wr.StrValueByIndex(";",i).StrValueByIndex("+",0).ToInteger());
      svObj.ValueMax(wr.StrValueByIndex(";",i).StrValueByIndex("+",1).ToInteger());
    }elseif(typ=="boolean"){
      svObj.ValueType(ivtBinary);
      svObj.ValueSubType(istBool);
      svObj.ValueName0(wr.StrValueByIndex(";",i).StrValueByIndex("+",0));
      svObj.ValueName1(wr.StrValueByIndex(";",i).StrValueByIndex("+",1));    
      svObj.State(vl.StrValueByIndex(";",i).ToInteger());
    }else{
      quit;
    }
    WriteLine("Variable " # name # " angelegt")
  }else{
    WriteLine("Variable " # name # " existiert schon!")
  }
  i=i+1;
}

!// Update der ReGa Skript Engine. Siehe:
!//     https://homematic-forum.de/forum/viewtopic.php?t=45380
dom.RTUpdate(0);

WriteLine("Alles erledigt...!");
