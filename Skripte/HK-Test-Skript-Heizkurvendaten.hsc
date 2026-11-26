!// Skript zur Ausgabe der Parameter für die KI-Heizkurvenoptimierung.
!//================================================================================================
!// Stand:    26.11.2026
!// Autor:    Martin Richter    (heizkalender@m-ri.de) http://blog.m-ri.de/
!// Projekt:  Helmut Diedrichs  (helmut@diedrichs.de) https://diedrichs.de
!//------------------------------------------------------------------------------------------------
!// Copyright (C) 2026 Martin Richter (xMRi-Software)
!// Dieser Teil des Heizkalenders ist freie Software und wird unter der GNU General Public License
!// Version 3 (GPLv3) oder neuer veröffentlicht.
!// Es besteht keinerlei Garantie oder Haftung. Nutzung auf eigene Verantwortung.
!//================================================================================================
!// Dieses Skript ermittelt die für die KI-gestützte Heizkurvenoptimierung benötigten
!// globalen Systemvariablen und individuellen Raumparameter des Heizkalenders.
!// Die ausgegebenen Daten können unverändert in die entsprechenden Abschnitte des
!// Eingabeformulars zur Heizkurvenoptimierung übernommen werden.
!// Das Skript verändert keine Systemvariablen oder Einstellungen des Heizkalenders.
!//
!// Weitere Informationen zur Vorgehensweise, zur Definition der Heizkurvenoptimierung
!// und zum Eingabeformular finden sich in der Dokumentation des Heizkalenders:
!// https://xmri.github.io/Homematic-Heizungskalender/
!//================================================================================================

string vrp="";

!//#######---Ende Variabler Bereich---#############################################################
!//Im Folgenden Hier keine Veränderungen vornehmen!

string varName;
string vid;
var sysVar;

!//------------------------------------------------------------------------------------------
WriteLine("___________________________________________________________________________");
WriteLine("Heizkurvenparameter vom " # system.Date().ToString());

!//------------------------------------------------------------------------------------------
!// Ausgabe der globalen Parameter der Heizkurve

WriteLine("___________________________________________________________________________");
WriteLine("Globale Parameter zur Heizkurvenoptimierung\n");

foreach(varName, ("HK2-A.Temp.Grenze;HK2-Grundtemperatur;HK2-Kurve;HK2-Kurvenanpassung;HK2-Kurvenversatz;HK2-VorzeitAus;HK2-HKG-Liste").Split(";")) {
  sysVar = dom.GetObject(vrp # varName);
  if (sysVar){
    WriteLine(sysVar.Name() # "=" # sysVar.Value());
  }else{
    WriteLine(vrp # varName # "=unbekannt");
  }
}

!//------------------------------------------------------------------------------------------
!// Ausgabe aller Raumvariablen des Heizkalenders

WriteLine("___________________________________________________________________________");
WriteLine("Raumparameter zur Heizkurvenoptimierung\n");

var svIDs = dom.GetObject(ID_SYSTEM_VARIABLES).EnumIDs();

foreach(vid, svIDs){
  sysVar = dom.GetObject(vid);
  if (sysVar.Name().StartsWith(vrp # "HKG-Raum-")){
    WriteLine(sysVar.Name() # "=" # sysVar.Value());
  }
}

!//------------------------------------------------------------------------------------------
WriteLine("___________________________________________________________________________");
WriteLine("Ausgabe beendet");