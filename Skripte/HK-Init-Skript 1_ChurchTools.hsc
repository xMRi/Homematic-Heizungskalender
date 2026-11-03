!// Skript zum Anlegen der Systemvariablen für Skript 1 (Churchtools)
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
!// TT:  2026-09-18 iPos>=0-Guard vor Substr ergänzt; rohe Debug-Ausgaben durch verständliche
!//                 Meldung ersetzt (kein Raum, Typ-Id).
!// MRi: 2026-02-19 Einlesen mehrerer Ressourcetypen
!// MRi: 2026-01-13 HK1-R-Liste erhält nun auch den Namen der Resource getrennt mit Gleichheitszeichen
!// MRi: 2025-12-21 Anlegen von zusätzlichen Räumen ermöglicht. Damit müssen nun keine Variablen mehr
!//                 manuell angelegt werden.

!//Eingabe eines Namens Präfix
!//Dies ist nur erforderlich wenn die Namensvorgabe abgeändert werden soll.
!//Wird hier ein Präfix eingeben so muss dieser in allen Skripten auch angegeben werden.
string vrp="";

!// Es ist möglich hier sofort ein API-Token für ChurchTools anzugeben. Da mit werden gleich weitere
!// Variablen für alle Ressourcen angelegt und die "HK1-R-Liste" befüllt. Ist ein API-Token bereits
!// in den Variablen angelegt wird dieses verwendet
string loginToken="";

!// Vorgegebene Organisations ID
string gemeindeName = "";

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
string nm=  "HK1-CT-Gemeindename;" #
            "HK1-Schaltliste;" #
            "HK1-R-Liste;" #
            "HK1-CT-Token;" #
            "HK2-HKG-Liste;" #
            "HK1-Vorlaufzeit";

!// Beschreibungstexte
string be=  "Name der Gemeinde in Churchtools;" #
            "Gelesene Termine aus Skript 1. Hier bitte nichts verändern!;" #
            "Zuordnung der Räume aus der Ressourcenverwaltung;" #
            "Sicherheitstoken für ChurchTools;" #
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
    WriteLine("Variable " # name # " angelegt")
  }else{
    WriteLine("Variable " # name # " existiert schon!")
  }
  i=i+1;
}

!//------------------------------------------------------------------------------------------------

!// Prüfe ob ein API-Token vorhanden ist
svObj = dom.GetObject(vrp # "HK1-CT-Token");
if(svObj.State()!=""){
  !// Aktuelles Token verwenden
  loginToken = svObj.State();
}elseif(loginToken!=""){
  !// Setze das aktuelle Token
  svObj.State(loginToken);
}

!// Prüfe ob eine gemeindeName vorhanden ist
svObj = dom.GetObject(vrp # "HK1-CT-Gemeindename");
if(svObj.State()!=""){
  !// Aktuelles Token verwenden
  gemeindeName = svObj.State();
}elseif(gemeindeName!=""){
  !// Setze das aktuelle Token
  svObj.State(gemeindeName);
}

!// Wenn ein API-Token vorhanden ist lesen wir die Ressource Liste
if (loginToken && gemeindeName){
  !// Wir versuchen die Ressource Liste zu lesen
  if (dom.GetObject(vrp # "HK1-R-Liste").State()!=""){
    WriteLine("Die Variablen für die ChurchTools Ressourcen wurden bereits gesetzt!");
  }else{
    !// URL aufbauen
    string cmd = "wget --timeout=3 -O - 'https://" # gemeindeName # ".church.tools/api/resource/masterdata?login_token=" # loginToken #"'";
    string stdout;
    string stderr;
    system.Exec(cmd, &stdout, &stderr);
    if (stdout.StartsWith("{\"data\":{\"resourceTypes\":[")){
      !// Zeichensatz fixen
      stdout = stdout.ToLatin();
      !// Unicode fixen
      stdout = stdout.Replace("\\u00e4","ä")
                     .Replace("\\u00c4","Ä")
                     .Replace("\\u00f6","ö")
                     .Replace("\\u00d6","Ö")
                     .Replace("\\u00fc","ü")
                     .Replace("\\u00dc","Ü")
                     .Replace("\\u00df","ß");


      !// Wir suchen die Ressource Raum/Room. Dazu spalten wir den Datenstring auf
      integer iPosRes = stdout.Find("\"resources\":[");
      if (iPosRes<0) {
        !// Es wurden keine Ressourcen gefunden.
        WriteLine("Raum Resourcen konnten nicht ermittelt werden!");
      }else{
        !// Ressource Type Raum finden ({"data":{"resourceTypes" überspringen)
        string ressourceTypes = stdout.Substr(26,iPosRes-26);

        !// Vernichte die id's die wir nicht wollen
        ressourceTypes = ressourceTypes.Replace("Person\":{\"id\":","");

        !// Suche die id für Räume
        string resTypeIds = ";";
        string resType;

        foreach(resType,ressourceTypes.Replace("{\"id\":","\t")){
          integer iPos = resType.Find("\"name\":\"");
          if (iPos>=0){
            integer iPos2 = resType.Substr(iPos+8,50).Find("\"");
            if (iPos2>=0){
              string name = resType.Substr(iPos+8,iPos2);
              if (name.ToUpper().Contains("RAUM") || name.ToUpper().Contains("RÄUME")){
                resTypeIds = resTypeIds # resType.ToInteger() # ";";
              }
            }
          }
        }

        !// Nur wenn wir eine Resource Type haben
        if(resTypeIds==";"){
          WriteLine("Der Ressourcen Typ für Räume wurde nicht gefunden!");
        }else{
          !// Wir bauen nun die raumliste auf. Diese erhält auch die Klartextnamen
          string resources = stdout.Substr(iPosRes+13,stdout.Length()-iPosRes-13);

          string raumListe = "";
          string raumNamen = "";

          !// Vernichte die id's die wir nicht wollen
          resources = resources.Replace("Person\":{\"id\":","");
          string res;
          foreach(res,resources.Replace("{\"id\":","\t")){
            !// Suche die resId und prüfe ob es passt
            integer iPos = res.Find("\"resourceTypeId\":");
            if (iPos<0){
              !// Ohne resourceTypeId können wir die Ressource nicht zuordnen -> überspringen
              WriteLine("Ressource ohne resourceTypeId übersprungen (Format unerwartet).");
              continue;
            }
            integer resTypeId = res.Substr(iPos+17,10).ToInteger();
            if(resTypeIds.Find(";" # resTypeId # ";")<0){
              !// Ressource ist kein Raum-Typ -> überspringen
              WriteLine("Ressource übersprungen (kein Raum, Typ-Id " # resTypeId # ").");
              continue;
            }

            !// Id holen
            integer resId = res.ToInteger();
            if (resId<=0){
              !// Fehler
              continue;
            }
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
              raumListe = raumListe #";";
            }
            raumListe = raumListe # resId # "=" # name;
            if (raumNamen){
              raumNamen = raumNamen # ";";
            }
            raumNamen = raumNamen # name;
          }
          !WriteLine(raumNamen);
          !WriteLine(raumListe);

          !// Wenn wir eine Raumliste haben dann setzen wir, wenn diese nicht leer ist
          svObj = dom.GetObject(vrp # "HK1-R-Liste");
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
          svObj = dom.GetObject(vrp # "HK2-HKG-Liste");
          if(svObj.State()!=""){
            !// Ist schon gesetzt
            WriteLine("Variable HK2-HKG-Liste ist bereits gefüllt: " # svObj.State());
            WriteLine("Ermittelte Daten: " # hkgListe);
          }else{
            svObj.State(hkgListe);
            WriteLine("Variable HK2-HKG-Liste wird gesetzt auf: " # hkgListe);
          }
        }
      }
    }else{
      !// Kein Zugriff möglich
      WriteLine("Fehler:\n" # stdout # "\n" # stderr);
    }
  }
}


!//------------------------------------------------------------------------------------------------

!// Update der ReGa Skript Engine. Siehe:
!//     https://homematic-forum.de/forum/viewtopic.php?t=45380
dom.RTUpdate(0);

WriteLine("Alles erledigt...!");
