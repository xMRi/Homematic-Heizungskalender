!// Übersicht aller Raumvariablen (HKG-Raum-*) als Markdown-Tabelle
!//================================================================================================
!// Stand:    22.09.2026
!// Autor:    Martin Richter    (heizkalender@m-ri.de) http://blog.m-ri.de/
!// Projekt:  Helmut Diedrichs  (helmut@diedrichs.de) https://diedrichs.de
!//================================================================================================
!// Durchsucht alle Systemvariablen nach dem Präfix HKG-Raum- und gibt sie als Markdown-Tabelle
!// mit aufgeschlüsselten Feldern aus. Findet auch verwaiste Variablen, die nicht in der
!// HK2-HKG-Liste stehen.
!//
!// Feld-Format der Raumvariable:
!//   Status;Modus;Heiztyp;Wohlfühltemp[/Grundtemp];Vorheizzeit[*Faktor];VorzeitAus;Sensor/Aktoren

!// Eingabe eines Namens Präfix (nur nötig, wenn die Namensvorgabe geändert wurde)
string vrp="";

!//#######---Ende Variabler Bereich---#############################################################

string suchPraefix = vrp # "HKG-Raum-";

!// Tabellenkopf
WriteLine("| Name | Status | Modus | Heiztyp | Wohlfühl | Grundtemp | Vorheizzeit | VorzeitAus | Sensor | Aktoren |");
WriteLine("| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |");

!// Über alle Systemvariablen iterieren und nach Präfix filtern
object oSysVars = dom.GetObject(ID_SYSTEM_VARIABLES);
string sVarId;
integer anzahl = 0;
foreach(sVarId, oSysVars.EnumUsedIDs()){
  object oVar = dom.GetObject(sVarId.ToInteger());
  if(!oVar){
    continue;
  }
  string name = oVar.Name();
  if(!name.StartsWith(suchPraefix)){
    continue;
  }

  string RVI = oVar.State();

  !// Felder zerlegen
  string status  = RVI.StrValueByIndex(";",0);
  string modus   = RVI.StrValueByIndex(";",1);
  string heiztyp = RVI.StrValueByIndex(";",2);
  string feld3   = RVI.StrValueByIndex(";",3);
  string wohlf   = feld3.StrValueByIndex("/",0);
  string grundt  = feld3.StrValueByIndex("/",1);
  string vorheiz = RVI.StrValueByIndex(";",4);
  string vorzAus = RVI.StrValueByIndex(";",5);

  !// Sensor = Feld 6 (bei HS der Thermostat als Datenquelle, sonst leer/erster Aktor)
  string sensor = RVI.StrValueByIndex(";",6);

  !// Aktoren = alles ab Feld 7 (offenes Ende, kann mehrere ;-getrennte Aktoren enthalten)
  string aktoren = "";
  integer iPos = 0;
  integer iEntry = 0;
  while(iPos<RVI.Length()){
    if(iEntry>=7){
      aktoren = aktoren # RVI.Substr(iPos,1);
    }elseif(RVI.Substr(iPos,1)==";"){
      iEntry = iEntry+1;
    }
    iPos = iPos+1;
  }

  !// Kurzer, lesbarer Name ohne Präfix. Pipe-Zeichen fuer Markdown escapen,
  !// da Raum-/Aktornamen "|" enthalten koennen (z.B. "EG|Saal").
  string kurzName = name.Replace(suchPraefix,"").Replace("|","\\|");
  sensor = sensor.Replace("|","\\|");
  aktoren = aktoren.Replace("|","\\|");

  WriteLine("| " # kurzName # " | " # status # " | " # modus # " | " # heiztyp # " | " #
            wohlf # " | " # grundt # " | " # vorheiz # " | " # vorzAus # " | " # sensor # " | " # aktoren # " |");
  anzahl = anzahl+1;
}

WriteLine("");
WriteLine("Gefundene Raumvariablen: " # anzahl.ToString());
