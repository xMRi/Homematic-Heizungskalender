!// Skript zum Erstellen der Systemvariablen des Heizkalender für das Logging
!//================================================================================================
!// Stand:    23.02.2026
!// Autor:    Martin Richter    (heizkalender@m-ri.de) http://blog.m-ri.de/
!// Projekt:  Helmut Diedrichs  (helmut@diedrichs.de) https://diedrichs.de
!//------------------------------------------------------------------------------------------------
!// Copyright (C) 2026 Martin Richter (xMRi-Software)
!// Dieser Teil des Heizkalenders ist freie Software und wird unter der GNU General Public License 
!// Version 3 (GPLv3) oder neuer veröffentlicht.
!// Es besteht keinerlei Garantie oder Haftung. Nutzung auf eigene Verantwortung.
!//================================================================================================

!// Die Variablen HK1-Logging;HK1-Log;HK2-Logging;HK2-Log werden für das interne Logging in Skript1 und
!// Skript2 verwenden in der MRI.
!// HK-SystemProtokollSichern wird verwendet um das System Protokoll regelmässig auf einen
!// USB Stick zu speichern.
!//
!// Code stammt von:
!//   https://www.blogging-it.com/code-snippet-homematic-systemvariablen-ueber-ein-script-automatisch-erzeugen/hausautomatisierung-smart-home/homematic-ip/homematic-script.html
!// 
!// MRi:  2026-11-03 Neue Variable für Skript3, HK3-Log...
!//  


!//Eingabe eines Namens Präfix
!//Dies ist nur erforderlich wenn die Namensvorgabe abgeändert werden soll.
!//Wird hier ein Präfix eingeben so muss dieser in allen Skripten auch angegeben werden.
string vrp="";

!//################################################################################################
!//######------Skript Variablen und Skript Arbeitsteil. Vom Benutzer nicht zu verändern------######

!// Namen der Variablen, die angelegt werden sollen
string nm=  "HK-Logging;" #
            "HK-Log;" #
            "HK1-Logging;" #
            "HK1-Log;" #
            "HK2-Logging;" #
            "HK2-Log;" #
            "HK3-Logging;" #
            "HK3-Log;" #
            "HK-LoggingHeizkurvenkontrolle;" #
            "HK-LogHeizkurvenkontrolle;" #
            "HK-RäumeHeizkurvenkontrolle;";

!// Beschreibungstexte
string be=  "Flag um das Logging für Tools ein- und auszuschalten;" #
            "Variable um ein einfaches Log im System Protokoll zu erzeugen;" #
            "Flag um das Logging für Skript 1 ein- und auszuschalten;" #
            "Variable um ein einfaches Log im System Protokoll zu erzeugen;" #
            "Flag um das Logging für Skript 2 ein- und auszuschalten;" #
            "Variable um ein einfaches Log im System Protokoll zu erzeugen;" #
            "Flag um das Logging für Skript 3 ein- und auszuschalten;" #
            "Variable um ein einfaches Log im System Protokoll zu erzeugen;" #
            "Flag um das Logging für die Heizkurvenkontrolle ein- und auszuschalten;" #
            "Variable um ein einfaches Log im System Protokoll zu erzeugen;" #
            "Aktuelle Raumdaten in der Heizkurvenkontrolle;";

!// Typen
string tp=  "boolean;" #
            "string;" #
            "boolean;" #
            "string;" #
            "boolean;" #
            "string;" #
            "boolean;" #
            "string;" #
            "boolean;" #
            "string;" #
            "string;";

!// Vorgabe Werte
string vl=  "1;" #
            ";" #
            "1;" #
            ";" #
            "1;" #
            ";" #
            "1;" #
            ";" #
            "1;" #
            ";" #
            ";";

!// Einheit (z.B. °C)
string vu=  "";

!// Zusätzliche Info Texte für
!//   - Boolean   - Werte für eine Variable durch + getrennt
!//   - Numerisch - min/max durch + getrennt
string wr=  "Logging ausgeschaltet+Logging eingeschaltet;" #
            ";" #
            "Logging ausgeschaltet+Logging eingeschaltet;" #
            ";" #
            "Logging ausgeschaltet+Logging eingeschaltet;" #
            ";" #
            "Logging ausgeschaltet+Logging eingeschaltet;" #
            ";" #
            "Logging ausgeschaltet+Logging eingeschaltet;" #
            ";" #
            ";";


!// Protokollierungs Flags
string pr=  "1;" #
            "1;" #
            "1;" #
            "1;" #
            "1;" #
            "1;" #
            "1;" #
            "1;" #
            "1;" #
            "1;" #
            "1;";

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
      svObj.State(vl.StrValueByIndex(";",i));
    }elseif(typ=="integer"){
      svObj.ValueType(ivtFloat);
      svObj.ValueSubType(istGeneric);
      svObj.State(vl.StrValueByIndex(";",i).ToFloat());
      svObj.ValueMin(wr.StrValueByIndex(";",i).StrValueByIndex("+",0).ToFloat());
      svObj.ValueMax(wr.StrValueByIndex(";",i).StrValueByIndex("+",1).ToFloat());
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
