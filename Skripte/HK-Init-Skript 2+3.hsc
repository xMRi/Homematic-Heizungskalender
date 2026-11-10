!// Script zum Erzeugen der Systemvariablen des Heizkalenders für Skript 2+3
!//================================================================================================
!// Stand:    10.11.2026
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
!//   HKP-S2-V-3.1.1 Variablen zu Skript2_V1.3.c
!// Der ursprüngliche Code wurde geschrieben von:
!//   Lukas Helduser (Youtube: https://www.youtube.com/LukasvandeHaag)
!// Ich (MRi) habe diesen Code dann erweitert, korrigiert und verbessert um sie an die Nutzung in
!// meiner Gemeinde anzupassen.
!//
!// TT:   2026-11-10 HK2-Kurvenanpassung: optionaler Kurvenanpassungsfaktor fuer das Zwei-Geraden-Modell (0.3..1.0, Vorgabe 0.8)
!// MRi:  2026-11-03 Neue Variable für Skript3, HK2-Schaltliste
!// TT:   2026-10-25 HK2-Schaltzeiten: Schlüssel von ResID auf Raumvariablenname (RVN) umgestellt.
!// TT:   2026-10-19 HK2-Schaltzeiten ergaenzt (Ausgabe berechneter Schaltzeiten durch Skript 2)
!// TT:   2026-10-04 Beschreibung von HK2-Aussentemperatur praezisiert (gleitender Durchschnitt)

!// Dieses Skript erstellt die nötigen Systemvariablen des Heizkalenders für Skript 2+3. Diese
!// dienen der Berechnung und dem eigentlichen des Heizkalenders.
!// Hinweis: Ein erneutes Ausführen dieses Programms ändert bestehende Variablen und ihren Inhalt nicht

!// Eingabe eines Namens Präfix
!// Dies ist nur erforderlich wenn die Namensvorgabe abgeändert werden soll.
!// Wird hier ein Präfix eingeben so muss dieser in allen Skripten auch angegeben werden.
string vrp="";

!// Namen der Variablen, die angelegt werden sollen
string nm=  "HK2-HKG-Liste;" #
            "HK2-Grundtemperatur;" #
            "HK2-A.Temp.Grenze;" #
            "HK2-Aussentemperatur;" #
            "HK2-Hand-Temp;" #
            "HK2-Hand-Grundtemp;" #
            "HK2-VorzeitAus;" #
            "HK2-Kurvenversatz;" #
            "HK2-Kurve;" #
            "HK2-Kurvenanpassung;" #
            "HK2-Schaltliste;" #
            "HK2-Schaltzeiten";

!// Beschreibungstexte
string be=  "Liste der HK-Raum-Variablen;" #
            "Grundtemperatur;" #
            "Außentemperatur-Grenzwert für das Heizen;" #
            "Außentemperatur für Vorheizzeit-Berechnung (gleitender Durchschnitt);" #
            "Vorrang manuell eingestellte Temperatur beim Ausschalten;" #
            "Rückstellung auf Grundtemperatur;" #
            "Grundoffsetzeit Ausschalten;" #
            "Grundoffsetzeit Einschalten;" #
            "Hzg.-Vorlaufzeit: Eingeben in Minuten zu Außentemperaturen kleiner als -10, -5, 0, 8, 10, 12, 15, 17,5;" #
            "Kurvenanpassungsfaktor fuer das Zwei-Geraden-Modell der Vorheizzeit-Berechnung (0.3 bis 1.0). Vorgabe 0.8;" #
            "Berechnete Schaltzeiten pro Raum von Skript 2 für den Schaltvorgang. Hier bitte nichts verändern!;" #
            "Berechnete Schaltzeiten pro Raum von Skript 2 für das Addon. Hier bitte nichts verändern!";

!// Typen
string tp=  "string;" #
            "integer;" #
            "integer;" #
            "integer;" #
            "boolean;" #
            "boolean;" #
            "integer;" #
            "integer;" #
            "string;" #
            "integer;" #
            "string;" #
            "string";

!// Vorgabe Werte
!// Komma wird ersetzt durch Semikolon
string vl=  ";" #
            "16.0;" #
            "19.0;" #
            "0.0;" #
            "0;" #
            "1;" #
            "0;" #
            "0;" #
            "162,130,100,59,50,41,30,20;" #
            "0.8;" #
            ";" #
            "";

!// Einheit (z.B. °C)
string vu=  ";" #
            "°C;" #
            "°C;" #
            "°C;" #
            ";" #
            ";" #
            "min;" #
            "min;" #
            "min;" #
            ";" #
            ";" #
            "";

!// Zusätzliche Info Texte für
!//   - Boolean   - Werte für eine Variable durch + getrennt
!//   - Numerisch - min/max durch + getrennt
string wr=  ";" #
            "5+30;" #
            "-50+50;" #
            "-50+50;" #
            "Immer auf Grundtemperatur zurücksetzen+Manuelle Temperatur hat Vorrang;" #
            "Keine Rückstellung auf Grundtemperatur um 01:00 Uhr+Rückstellung auf Grundtemperatur um 01:00 Uhr;" #
            "0+120;" #
            "-100+100;" #
            ";" #
            "0.3+1.0;" #
            ";" #
            "";

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
            "1;" #
            "0";

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
