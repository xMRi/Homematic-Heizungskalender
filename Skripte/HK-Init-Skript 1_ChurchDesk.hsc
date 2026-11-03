!// Skript zum Anlegen der Systemvariablen für Skript 1 (ChurchDesk)
!//================================================================================================
!// Stand:    18.10.2026
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
!//   HKP-CT-V--3.2.1 Variablen zu Skript1_ChurchTools_V1.4.c
!// Der ursprüngliche Code wurde geschrieben von:
!//   Lukas Helduser (Youtube: https://www.youtube.com/LukasvandeHaag)
!// Ich (MRi) habe diesen Code dann erweitert, korrigiert und verbessert um sie an die Nutzung in
!// meiner Gemeinde anzupassen.
!//

!// Dieses Skript erstellt die nötigen Systemvariablen des Heizkalender für Skript 1 ChurchDesk
!// Hinweis: Ein erneutes Ausführen dieses Programms ändert bestehende Variablen und ihren Inhalt nicht
!// Tipp: Sie sollten unbedingt die Variablen organizationId und apiToken vorbelegen, weil dann
!// automatisch alle benötigten Variablen automatisch erzeugt.


!// MRi: 2026-11-03 Aufteilung Skript2 Termine vorbereiten, Skript 3 Schalten
!// TT:  2026-10-18 HK1-Vorlaufzeit: neue optionale Systemvariable (Integer, Default 720 min)
!// TT:  2026-09-18 color-Guard iPos>=0 statt iPos&& (verfehlte Position 0 / -1).
!// MRi: 2026-01-13 HK1-R-Liste erhält nun auch den Namen der Resource getrennt mit Gleichheitszeichen
!// MRi: 2025-12-21 Anlegen von zusätzlichen Räumen ermöglicht. Damit müssen nun keine Variablen mehr
!//                 manuell angelegt werden.

!//Eingabe eines Namens Präfix
!//Dies ist nur erforderlich wenn die Namensvorgabe abgeändert werden soll.
!//Wird hier ein Präfix eingeben so muss dieser in allen Skripten auch angegeben werden.
string vrp="";

!// Vorgegebene Organisations ID
string organizationId = "";

!// Es ist möglich hier sofort ein API-Token für ChurchDesk anzugeben. Da mit werden gleich weitere
!// Variablen für alle Ressourcen angelegt und die "HK1-R-Liste" befüllt. Ist ein API-Token bereits
!// in den Variablen angelegt wird dieses verwendet
string apiToken="";

!// Weitere einzurichtende Räume, für die keine Ressourcen vorhanden sind- Für diese werden auch
!// Raum Variablen angelegt.
string zusaetzlicheRaumNamen = "";

!// Vorgabe für Raumnamen Prefix
string raumNamenPreFix =  vrp#"HKG-Raum-";

!// Vorgabe für Raumlisten Variablen
string raumVorgabePreFix = "0;H;IP;20;0;30;Heizgruppe: ";
string raumVorgabePostFix = ":1";

!//################################################################################################
!//######------Skript Variablen und Skript Arbeitsteil. Vom Benutzer nicht zu verändern------######

!// Namen der Variablen, die angelegt werden sollen
string nm=  "HK1-Schaltliste;" #
            "HK1-R-Liste;" #
            "HK1-CD-OrganisationsId;" #
            "HK1-CD-Token;" #
            "HK2-HKG-Liste;" #
            "HK1-Vorlaufzeit";

!// Beschreibungstexte
string be=  "Gelesene Termine aus Skript 1. Hier bitte nichts verändern!;" #
            "Zuordnung der Räume aus der Ressourcenverwaltung;" #
            "Organisations ID in ChurchDesk;" #
            "API-Token für ChurchDesk;" #
            "Liste der HK-Raum-Variablen;" #
            "Zeithorizont fuer Terminabfrage in Minuten (Default 720, max. 1380)";

!// Typen
string tp=  "string;" #
            "string;" #
            "string;" #
            "string;" #
            "string;" #
            "integer";

!// Vorgabe Werte
string vl=  ";" #
            ";" #
            ";" #
            ";" #
            ";" #
            "720";

!// Einheit (z.B. °C)
string vu=  ";" #
            ";" #
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
            ";" #
            "0+1380";

!// Protokollierungs Flags
string pr=  "1;" #
            "1;" #
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
    WriteLine("Variable " # name # " angelegt");
  }else{
    WriteLine("Variable " # name # " existiert schon!");
  }
  i=i+1;
}

!//------------------------------------------------------------------------------------------------

!// Prüfe ob ein API-Token vorhanden ist
svObj = dom.GetObject(vrp#"HK1-CD-Token");
if(svObj.State()!=""){
  !// Aktuelles Token verwenden
  apiToken = svObj.State();
}elseif(apiToken!=""){
  !// Setze das aktuelle Token
  svObj.State(apiToken);
}

!// Prüfe ob eine OrganisationsId vorhanden ist
svObj = dom.GetObject(vrp#"HK1-CD-OrganisationsId");
if(svObj.State()!=""){
  !// Aktuelles Token verwenden
  organizationId = svObj.State();
}elseif(organizationId!=""){
  !// Setze das aktuelle Token
  svObj.State(organizationId);
}

!// Wenn ein API-Token vorhandne ist lesen wir die Ressource Liste
if (apiToken && organizationId){
  !// Wir versuchen die Ressource Liste zu lesen
  if (dom.GetObject(vrp#"HK1-R-Liste").State()!=""){
    WriteLine("Die Variablen für die ChurchDesk Ressourcen wurden bereits gesetzt!");
  }else{
    !// URL aufbauen
    string cmd = "wget --timeout=3 -O - 'https://api2.churchdesk.com/api/v3.0.0/events/resources?partnerToken=" # apiToken # "&organizationId=" # organizationId #"'";
    string stdout;
    string stderr;
    system.Exec(cmd, &stdout, &stderr);

    if (stdout.StartsWith("[")){
      !// Zeichensatz fixen
      stdout = stdout.ToLatin();

      !// Wir bauen nun die raumliste auf. Diese erhält auch die Klartextnamen
      string raumListe = "";
      string raumNamen = "";
      !// Nun die Ressourcen separieren "{\"id\":"
      string res;
      !// Achtung der Spli ersetzt nur das erste Zeichen durch \t
      foreach(res,stdout.Split("{\"id\":")){
        if (!res.StartsWith("\"id\":")){
          !// Fehler, falsches format
          continue;
        }

        !// Bei Color 0 ist das der Gemeinde-Eintrag, den überspringen wir.
        integer iPos = res.Find("\"color\":");
        if (iPos>=0 && res.Substr(iPos+8,10).ToInteger()==0){
          !// Den Gemeinde-Eintrag kann man beim buchen nicht benutzen.
          !// Einen anderen Indikator als die Farbe habe ich nicht gefunden.
          continue;
        }

        !// Id holen
        integer resId = res.Substr(5,10).ToInteger();

        !// Namen suchen
        integer iPos = res.Find(",\"name\":\"");
        if (iPos<0){
          !// Fehler
          continue;
        }

        !// Namen finden
        res = res.Substr(iPos+9,res.Length()-9);
        integer iPosEnd = res.Find("\",\"");
        if (iPosEnd<0){
          !// Fehler
          continue;
        }

        !// Namen bereinigen
        name = res.Substr(0,iPosEnd);
        name = name.Replace(" ","").Replace("\'","").Replace("\"","").Replace(":","").Replace("+","").Replace("#","").Replace(";","").Replace(".","").Replace("=","");

        !// Die Raumliste bekommt zusätzlich die Raumnamen im Klartext abgetrennt mit =. Das erleichtert
        !// dem Installer eine bessere Funktionalität für den Benutzer.
        if (raumListe){
          raumListe = raumListe # ";";
        }
        raumListe = raumListe # resId # "=" # name ;
        if (raumNamen){
          raumNamen = raumNamen # ";";
        }
        raumNamen = raumNamen # name;
      }

      !// Wenn wir eine Raumliste haben dann setzen wir, wenn diese nicht leer ist
      svObj = dom.GetObject(vrp#"HK1-R-Liste");
      if(svObj.State()!=""){
        !// Ist schon gesetzt
        WriteLine("Variable HK1-R-Liste ist bereits gefüllt: " # svObj.State());
        WriteLine("Ermittelte Daten: " # raumListe);
      }else{
        svObj.State(raumListe);
        WriteLine("Variable HK1-R-Liste wird gesetzt auf: " # raumListe);
      }

      !// Weitere Räume hinzufügen, wenn diese nicht schon in der Liste sind
      foreach(name,zusaetzlicheRaumNamen.Split(";")){
        !// Namen bereinigen
        name = name.Replace(" ","").Replace("\'","").Replace("\"","").Replace(":","").Replace("+","").Replace("#","").Replace(";","").Replace(".","").Replace("=","");
        if (name && ((";" # raumNamen # ";").Find(";" # name # ";")<0)){
          if(!raumNamen.EndsWith(";")){
            raumNamen = raumNamen # ";";
          }
          raumNamen = raumNamen # name;
        }
      }

      !// Raum Variablen anlegen und HK2-HKG-Liste füllen
      string hkgListe = "";
      integer iRaeume=0;
      foreach(name,raumNamen.Split(";")){
        !// Variablen Name erzeugen
        name = raumNamenPreFix # name;

        !// Wir fügen den Raum nur zur HKG-Liste, wenn er auch zu einer Ressource gehört
        if (raumListe.StrValueByIndex(";",iRaeume).Trim()){
          if (hkgListe){
            hkgListe = hkgListe # ";";
          }
          hkgListe = hkgListe+name;
        }
        iRaeume = iRaeume+1;

        svObj = dom.GetObject(name);
        if (svObj){
          WriteLine("Raumvariable " # name # " existiert bereits! Wert: " # svObj.State());
        }else{
          !// Variable anlegen
          object svObjects = dom.GetObject(ID_SYSTEM_VARIABLES);
          svObj = dom.CreateObject(OT_VARDP);
          svObjects.Add(svObj.ID());

          svObj.Name(name);
          svObj.ValueType(ivtString);
          svObj.ValueSubType(istChar8859);
          svObj.DPInfo("Raumbeschreibung für HK-Skript 2");
          svObj.DPArchive(true);
          svObj.Internal(false);
          svObj.Visible(true);
          svObj.DPArchive(true);

          !// Vorgabe machen
          svObj.State(raumVorgabePreFix # name.Replace(raumNamenPreFix,"") # raumVorgabePostFix);
          WriteLine("Raumvariable " # name # " angelegt! Wert: " # svObj.State());
        }
      }

      !// HK2-HKG-Liste ändern
      svObj = dom.GetObject(vrp#"HK2-HKG-Liste");
      if(svObj.State()!=""){
        !// Ist schon gesetzt
        WriteLine("Variable " # vrp # "HK2-HKG-Liste ist bereits gefüllt: " # svObj.State());
        WriteLine("Ermittelte Daten: " # hkgListe);
      }else{
        svObj.State(hkgListe);
        WriteLine("Variable HK2-HKG-Liste wird gesetzt auf: " # hkgListe);
      }
    }else{
      !// Kein Zugriff möglich
      WriteLine("Fehler:\n" # cmd # "\n" # stdout # "\n" # stderr);
    }
  }
}

!//------------------------------------------------------------------------------------------------

!// Update der ReGa Skript Engine. Siehe:
!//     https://homematic-forum.de/forum/viewtopic.php?t=45380
dom.RTUpdate(0);

WriteLine("Alles erledigt...!");
