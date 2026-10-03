!// Skript zum Testen der Einstellungen für den Heizkalender.
!//================================================================================================
!// Stand:    03.10.2026
!// Autor:    Martin Richter    (heizkalender@m-ri.de) http://blog.m-ri.de/
!// Projekt:  Helmut Diedrichs  (helmut@diedrichs.de) https://diedrichs.de
!//------------------------------------------------------------------------------------------------
!// Copyright (C) 2026 Martin Richter (xMRi-Software)
!// Dieser Teil des Heizkalenders ist freie Software und wird unter der GNU General Public License
!// Version 3 (GPLv3) oder neuer veröffentlicht.
!// Es besteht keinerlei Garantie oder Haftung. Nutzung auf eigene Verantwortung.
!//================================================================================================
!//
!// TT:  2026-10-03 Modus HS (Heizen+Schalten) erkannt und korrekt ausgegeben.
!// TT:  2026-09-18 Syntaxfehler behoben (fehlende Klammern/Semikolon), + auf # umgestellt.

!//------------------------------------------------------------------------------------------
!// Heizliste dekodieren und prüfen

string vrp="";

!//#######---Ende Variabler Bereich---#############################################################
!//Im Folgenden Hier keine Veränderungen vornehmen!

!//-------------------------------------------------------------
!// Schaltparameter Varablen

!// IP- Thermostate-Aktoren-Gerätetyp (Kanal 1)
!//   BWTH_V1, BWTH_V2, TRVB_V1, TRV-C_V1, TRV, TRV-V1, TRV-V2, TRV-V3, TRV-V4, C_V2, WTH-2_V1, WTH-2_V2, WTH2_V3, WTH-BV1, WTH_V1, WT-V1
string AGFParamIP="SET_POINT_TEMPERATURE";

!// RT- Kennung Kanal Klassik-Thermostate-Aktoren-Gerätetyp (Kanal 4)
!//   HM-CC-RT-DN HM-CC-RT-DN
string AGFParamRT="SET_TEMPERATURE";

!// TC- Kennung Kanal Klassik-Thermostate-Aktoren-Gerätetyp (Kanal 4)
!//   HM-CC-TC
string AGFParamTC="SETPOINT";

!// IT- Kennung Kanal Klassik-Thermostate-Aktoren-Gerätetyp (Kanal 4)
!//   HM-TC-IT-WM-W-EU
string AGFParamIT="SET_TEMPERATURE";

!// SW- Kennung Kanal Klassik-Schalter-Aktoren-Gerätetyp (Kanal 1 bzw. 2)
!//   HM-LC-Sw1-FM HM-LC-Sw1PBU-FM, HM-LC-Sw2-FM, HM-ES-PMSw1-DR HM-LC-Sw1-PCB
!// Kennung Kanal IP-Schalter-Aktoren-Gerätetyp (Kanal 1)
!//   SW  Noch unerprobt
string AGFParamSW="STATE";

string stemp="";
string stext="";
integer i=0;

!//------------------------------------------------------------------------------------------
WriteLine("___________________________________________________________________________");
WriteLine("Test Skript Lauf vom " # system.Date().ToString());

!//------------------------------------------------------------------------------------------
!// Dekodieren der Schaltliste in Klartext

WriteLine("___________________________________________________________________________");

string SListe=dom.GetObject(vrp # "HK1-Schaltliste").State();
WriteLine("HK1-Schaltliste=" # SListe);
i = 0;
while (true) {
  stemp = SListe.StrValueByIndex(";",i);
  if(stemp==""){
    break;
  }
  if ((i%5)==0){
    WriteLine("\nSchaltzeiten Raum=" # stemp);
  } elseif ((i%5)==1) {
    WriteLine("Zeit Start=" # stemp);
  } elseif ((i%5)==2) {
    WriteLine("Zeit Ende=" # stemp);
  } elseif ((i%5)==3) {
    WriteLine("Temperatur=" # stemp);
  } elseif ((i%5)==4) {
    WriteLine("Heizen/Schalten=" # stemp);
  }
  i=i+1;
}

!//------------------------------------------------------------------------------------------
!// Logging überprüfen

WriteLine("___________________________________________________________________________");
WriteLine("Logging Status\n");

var obj=dom.GetObject(vrp # "HK-Logging");
if (obj){
  if (obj.State()!=0){
    stemp = "ein";
  }else{
    stemp = "aus";
  }
  WriteLine("HK-Logging: Allgemeines Logging ist " # stemp # "geschaltet");
}else{
  WriteLine("HK-Logging: Flag für allgemeines Logging existiert nicht");
}
if (dom.GetObject(vrp # "HK-Log")){
  WriteLine("HK-Log: Log-Variable (allgemein) existiert");
}else{
  WriteLine("HK-Log: Log-Variable (allgemein) existiert nicht");
}

obj=dom.GetObject(vrp # "HK1-Logging");
if (obj){
  if (obj.State()!=0){
    stemp = "ein";
  }else{
    stemp = "aus";
  }
  WriteLine("HK1-Logging: Logging Script 1 ist " # stemp # "geschaltet");
}else{
  WriteLine("HK1-Logging: Log-Variable für Script 1 existiert nicht");
}
if (dom.GetObject(vrp # "HK1-Log")){
  WriteLine("HK1-Log: Log-Variable für Script 1 existiert");
}else{
  WriteLine("HK1-Log: Log-Variable für Script 1 existiert nicht");
}

obj=dom.GetObject(vrp # "HK2-Logging");
if (obj){
  if (obj.State()!=0){
    stemp = "ein";
  }else{
    stemp = "aus";
  }
  WriteLine("HK2-Logging: Logging Script 2 ist " # stemp # "geschaltet");
}else{
  WriteLine("HK2-Logging: Log-Variable für Script 2 existiert nicht");
}
if (dom.GetObject(vrp # "HK2-Log")){
  WriteLine("HK2-Log: Log-Variable für Script 2 existiert");
}else{
  WriteLine("HK2-Log: Log-Variable für Script 2 existiert nicht");
}

!//------------------------------------------------------------------------------------------
!// Ausgabe Der Churchtools Raumliste und deren Raum Parameter

WriteLine("___________________________________________________________________________");

string hk1RaumListe=dom.GetObject(vrp # "HK1-R-Liste").State();
string hk2RaumListe=dom.GetObject(vrp # "HK2-HKG-Liste").State();
string hk1RaumListeNamen=hk2RaumListe.Replace(vrp # "HKG-Raum-","").Replace("HKG-","");
WriteLine("HK1-R-Liste=" # hk1RaumListe);
WriteLine("HK1-R-Liste Namen=" # hk1RaumListeNamen);
WriteLine("HK2-HKG-Liste=" # hk2RaumListe);

string ListeRaumVariablen = ";";
i=0;
string RListe;
string RName;
var Raum;
string RaumDef;
foreach(RListe, hk2RaumListe.Split(";")){
  RName = "";
  if (hk1RaumListeNamen!=""){
    RName = " (" # hk1RaumListeNamen.StrValueByIndex(";",i) # ")";
  }

  WriteLine("_____________________________\nRaum: \t" # (i+1).ToString() # RName);
  WriteLine("Churchtools Resource: \t" # hk1RaumListe.StrValueByIndex(";",i));
  if (RListe.Find("+")>=0){
    WriteLine ("Zugeordnete Raeume: \t" # RListe);
  }
  foreach(RName,RListe.Split("+")){
    if (!RName){
      continue;
    }
    !// Raumdaten ausgeben.
    WriteLine("Raum: " # RName);

    if (ListeRaumVariablen.Find(";" # RName # ";")<0){
      ListeRaumVariablen = ListeRaumVariablen # RName # ";";
    }
  }
  i=i+1;
}

WriteLine("___________________________________________________________________________");
foreach(RName,ListeRaumVariablen.Split(";")){
  if (!RName){
      continue;
  }

  Raum = dom.GetObject(RName);
  if (!Raum){
    WriteLine("FEHLER!!! Raumvariable " # RName # " nicht vorhanden!!!");
    continue;
  }
  RaumDef = Raum.State();

  !// Raumdaten ausgeben.
  WriteLine("Raum: \t" # RName);
  WriteLine("Raumvariable:\t" # RaumDef);

  !// Wert #0 Raumstatus
  stemp = RaumDef.StrValueByIndex(";",0);
  stext = "Raum Status: \t" # stemp;
  if(stemp=="0"){
      stext = stext # " ausgeschaltet";
  }elseif(stemp=="1"){
      stext = stext # " eingeschaltet";
  }elseif(stemp=="2"){
      stext = stext # " generell eingeschaltet";
  }elseif(stemp=="3"){
      stext = stext # " generell ausgeschaltet";
  }else{
      stext = stext # " UNBEKANNT!!! FEHLER!!!";
  }
  WriteLine(stext);

  !// Wert #1 Heizen Schalten
  stemp = RaumDef.StrValueByIndex(";",1);
  stext = "Modus:\t\t\t" # stemp;
  if(stemp=="H"){
      stext = stext # " Heizen";
  }elseif(stemp=="S"){
      stext = stext # " Schalten";
  }elseif(stemp=="HS"){
      stext = stext # " Heizen+Schalten";
  }else{
      stext = stext # " UNBEKANNT!!! FEHLER!!!";
  }
  WriteLine(stext);

  !// Wert #2 Gerätebauart
  stemp = RaumDef.StrValueByIndex(";",2);
  stext = "Gerätebauart: \t" # stemp;

  if(stemp=="IP"){
    stext = stext # "=IP-Thermostate-Aktoren-Gerätetyp (Kanal 1)";
  }elseif(stemp=="RT"){
    stext = stext # "=Klassik-Thermostate-Aktoren-Gerätetyp (Kanal 4)";
  }elseif(stemp=="TC"){
    stext = stext # "=Klassik-Thermostate-Aktoren-Gerätetyp (Kanal 2)";
  }elseif(stemp=="IT"){
    stext = stext # "=Klassik-Thermostate-Aktoren-Gerätetyp (Kanal 2)";
  }elseif(stemp=="SW"){
    stext = stext # "=Klassik-Schalter-Aktoren-Gerätetyp (Kanal 1/2)";
  }else{
    stext = stext # " UNBEKANNT!!! FEHLER!!!";
  }
  WriteLine(stext);

  !// Wert #3 Wohlfühl-Temperaturvorgabe
  WriteLine("Temperatur: \t" # RaumDef.StrValueByIndex(";",3).StrValueByIndex("/",0).ToFloat().ToString(1));
  string stemp = RaumDef.StrValueByIndex(";",3).StrValueByIndex("/",1);
  if (stemp){
    !// Optionale abweichende Grundtemperatur
    WriteLine("Abw. Grundt.: \t" # stemp.ToFloat().ToString(1));
  }

  !// Wert #4 Vorlaufzeit
  WriteLine("Vorlaufzeit: \t" # RaumDef.StrValueByIndex(";",4).ToInteger().ToString());
  string stemp = RaumDef.StrValueByIndex(";",4).StrValueByIndex("*",1);
  if (stemp){
    !// Optionale Kurvenkorrektur
    WriteLine("Kurvenkorr.:\t" # stemp.ToFloat().ToString(2));
  }

  !// Wert #5 Nachlaufzeit
  WriteLine("Nachlaufzeit: \t" # RaumDef.StrValueByIndex(";",5).ToInteger().ToString());

  !// Kanäle ausgeben
  string Aktor="";
  string Param="";
  stemp = RaumDef.StrValueByIndex(";",2);
  if(stemp=="RT"){Param="SET_TEMPERATURE";}
  elseif(stemp=="TC"){Param="SETPOINT";}
  elseif(stemp=="IP"){Param="SET_POINT_TEMPERATURE";}
  elseif(stemp=="IT"){Param="SET_TEMPERATURE";}
  else{Param="";}

  !// DUP: AktorenListe-Block, identisch zu HK-Skript 2.hsc. Aenderungen dort mitziehen.
  !// AktorenListe aufbauen. Das ist alles ab der siebte Eintrag der Raumliste. Das dient dazu
  !// Die Liste für spätere Schaltvorgänge bereit zu halten. Der alte Code hat damit gerechnet
  !// Das ein Aktorname eine Mindestlänge hat.
  integer iPos = 0;
  integer iEntry = 1;
  string AktorenListe = "";
  while (iPos<RaumDef.Length()) {
    if (iEntry>6){
      AktorenListe = AktorenListe # RaumDef.Substr(iPos,1);
    } elseif (RaumDef.Substr(iPos,1)==";"){
      iEntry=iEntry+1;
    }
    iPos = iPos+1;
  }

  WriteLine("Aktoren:");
  foreach(Aktor,AktorenListe.Split(";")){
    stemp = "\t" # Aktor;
    if (Param!=""){
      obj = dom.GetObject(Aktor);
      if (obj){
        obj=obj.DPByHssDP(Param);
        if (obj){
          stemp = stemp # " \t " # Param # "=" # obj.State();
        }else{
          stemp = stemp # " \t FEHLER!!! Param " # Param # " unbekannt im System!";
        }
      }else{
        stemp = stemp # " \t FEHLER!!! Aktor unbekannt im System!";
      }
    }
    WriteLine(stemp);
  }

  ListeRaumVariablen = ListeRaumVariablen.Replace(";"# RName # ";", ";");
  if (ListeRaumVariablen.Length()>1){
    WriteLine("_____________________________");
  }
}

!//------------------------------------------------------------------------------------------
!// Ausgabe aller Systemvariablen. Damit kann man Einstellungen protokollieren.

WriteLine("___________________________________________________________________________");
WriteLine("System Variablen zum Heizkalender\n");

string svListStr = "";
string vid;
var svIDs = dom.GetObject(ID_SYSTEM_VARIABLES).EnumIDs();

foreach(vid, svIDs){
    var sysVar = dom.GetObject(vid);
    if (sysVar.Name().StartsWith(vrp # "HK") || sysVar.Name().StartsWith(vrp # "Tool-")) {
      svListStr = svListStr # sysVar.Name() # "=" #  sysVar.Value() # "\n";
    }
}

WriteLine(svListStr);

WriteLine("___________________________________________________________________________");
WriteLine("Alles fertig...");
