!// Test - Ermitteln der Temperaturverschiebeung
!//================================================================================================
!// Stand:    18.12.2025;
!// Autoren:  Martin Richter    (heizkalender@m-ri.de) http://blog.m-ri.de/
!// Projekt:  Helmut Diedrichs  (helmut@diedrichs.de) https://diedrichs.de
!//------------------------------------------------------------------------------------------------
!// Copyright (C) 2026 Martin Richter (xMRi-Software)
!// Dieser Teil des Heizkalenders ist freie Software und wird unter der GNU General Public License 
!// Version 3 (GPLv3) oder neuer veröffentlicht.
!// Es besteht keinerlei Garantie oder Haftung. Nutzung auf eigene Verantwortung.
!//================================================================================================

!//
!//-------------------------------------------------------------

string vrp="CD_";
integer AT=dom.GetObject(vrp+"HK2-Aussentemperatur").State().ToFloat();
string  OffsetAT=dom.GetObject(vrp+"HK2-Kurve").State();

!//Nach aktueller Aussentemperatur den Offsetwert berechnen und am Einschaltzeitpunkt abziehen und Aktor Paramter setzen
real ux=0.0;
real uy=0.0;
real lx=0.0;
real ly=0.0;

!// Wir nutzen die Temperaturverschiebung nur, wenn wir einen normalen Schaltvorgang haben
!// Spezial Befehle #EIN# #AUS# #NORMAL# werden zur normalen Zeit ausgeführt.
if(AT<-5.0){
  lx=-10.0;
  ly = OffsetAT.StrValueByIndex(";",0).ToFloat();
  ux=-5;
  uy = OffsetAT.StrValueByIndex(";",1).ToFloat();
}elseif(AT<0.0){
  lx=-5.0;
  ly = OffsetAT.StrValueByIndex(";",1).ToFloat();
  ux=0.0;
  uy = OffsetAT.StrValueByIndex(";",2).ToFloat();
}elseif(AT<8.0){
  lx=0.0;
  ly = OffsetAT.StrValueByIndex(";",2).ToFloat();
  ux=8.0;
  uy = OffsetAT.StrValueByIndex(";",3).ToFloat();
}elseif(AT<10.0){
  lx=8.0;
  ly = OffsetAT.StrValueByIndex(";",3).ToFloat();
  ux=10.0;
  uy = OffsetAT.StrValueByIndex(";",4).ToFloat();
}elseif(AT<12.0){
  lx=10.0;
  ly = OffsetAT.StrValueByIndex(";",4).ToFloat();
  ux=12.0;
  uy = OffsetAT.StrValueByIndex(";",5).ToFloat();
}elseif(AT<15.0){
  lx=12.0;
  ly = OffsetAT.StrValueByIndex(";",5).ToFloat();
  ux=15.0;
  uy = OffsetAT.StrValueByIndex(";",6).ToFloat();
}elseif(AT<17.5){
  lx=15.0;
  ly = OffsetAT.StrValueByIndex(";",6).ToFloat();
  ux=17.5;
  uy = OffsetAT.StrValueByIndex(";",7).ToFloat();
}else{
  lx=0.0;
  ly=0.0;
}

!// linear Interpolieren
real offset=0.0;
if((lx!=0)||(ly!=0)){
  offset = (((uy-ly)/(ux-lx))*(AT-lx))+ly;
}else{
  offset = 0;
}
if (offset<0){
  offset = 0;
}

WriteLine(AT.ToString(1) # " - Offset = " # offset.ToInteger());
