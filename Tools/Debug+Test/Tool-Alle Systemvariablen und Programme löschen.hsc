!// Skript zum Erstellen der Systemvariablen des Heizkalender für das Logging
!//================================================================================================
!// Stand:    06.10.2026
!// Autor:    Martin Richter    (heizkalender@m-ri.de) http://blog.m-ri.de/
!// Projekt:  Helmut Diedrichs  (helmut@diedrichs.de) https://diedrichs.de
!//------------------------------------------------------------------------------------------------
!// Copyright (C) 2026 Martin Richter (xMRi-Software)
!// Dieser Teil des Heizkalenders ist freie Software und wird unter der GNU General Public License 
!// Version 3 (GPLv3) oder neuer veröffentlicht.
!// Es besteht keinerlei Garantie oder Haftung. Nutzung auf eigene Verantwortung.
!//================================================================================================

!//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!// ACHTUNG DIESES SKRIPT SOLLTE NUR GANZ BEWUSST EINGESETZT WERDEN!!!!
!// ES KÖNTEN  WICHTIGE DATEN GELÖSCHT WERDEN!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!//Sicherheitsfunktion die entfernt werden muss für die Ausführung!
quit;
!//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!// Leerer Prefix mit einem Blank " ", löscht alle Variablen mit "HK" oder "Tool-".
!// Andere Prefixe ChurchDesk cd_, Prefix ChurchTools ct_
string vrps=" ;cd_;ct_";

!//################################################################################################
!//######------Skript Variablen und Skript Arbeitsteil. Vom Benutzer nicht zu verändern------######

!// Skript zum löschen von SystemVariablen mit bestimmten Prefixen.
string svName;
object svObject;

string vrp="";
foreach(vrp,vrps.Split(";")){
  vrp=vrp.Trim();
  WriteLine("Prefix:" #vrp);
  foreach(svName, dom.GetObject(ID_SYSTEM_VARIABLES).EnumUsedNames()){
    !WriteLine("Systemvariable " # svName);
    if ((svName.ToUpper().StartsWith((vrp#"HK").ToUpper())) || (svName.ToUpper().StartsWith((vrp#"Tool-").ToUpper()))) {
      WriteLine("Systemvariable \"" # svName # "\" gelöscht");
      svObject = dom.GetObject(ID_SYSTEM_VARIABLES).Get(svName);
      dom.DeleteObject(svObject);
    }
  }

  foreach(svName, dom.GetObject(ID_PROGRAMS).EnumUsedNames()){
    !WriteLine("Programm " # svName);
    if ((svName.ToUpper().StartsWith((vrp#"HK").ToUpper())) || (svName.ToUpper().StartsWith((vrp#"Tool-").ToUpper()))) {
      WriteLine("Programm \"" # svName # "\" gelöscht");
      svObject = dom.GetObject(ID_PROGRAMS).Get(svName);
      dom.DeleteObject(svObject);
    }
  }
}

!// Alles aktualisieren
dom.RTUpdate(0);

WriteLine("Alles fertig...");
