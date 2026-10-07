!// Heizkalender Log ausgeben
!//================================================================================================
!// Stand:    21.09.2026
!// Autor:    Martin Richter    (heizkalender@m-ri.de) http://blog.m-ri.de/
!// Projekt:  Helmut Diedrichs  (helmut@diedrichs.de) https://diedrichs.de
!//------------------------------------------------------------------------------------------------
!// Copyright (C) 2026 Martin Richter (xMRi-Software)
!// Dieser Teil des Heizkalenders ist freie Software und wird unter der GNU General Public License
!// Version 3 (GPLv3) oder neuer veröffentlicht.
!// Es besteht keinerlei Garantie oder Haftung. Nutzung auf eigene Verantwortung.
!//================================================================================================
!//

!//Eingabe eines Namens Präfix
!//Dies ist nur erforderlich wenn die Namensvorgabe beim erstellen den Systemvariablen geändert wurde.
!//Wird hier ein Präfix eingeben so muss dieser in allen Skripten auch angegeben werden.
string vrp="";

!// Suchbegriff: nur Zeilen die diesen Text enthalten werden ausgegeben
!// Sinnvolle Suchbegriffe: HK2-Log, HK-Log, HK1-Log, HK2-Aussentemperatur, HK-LogHeizkurvenkontrolle und HK-RäumeHeizkurvenkontrolle
string Suchbegriff="HK2-Log";

!// Anzahl der neuesten Log-Dateien, die durchsucht werden sollen
integer AnzahlDateien=3;

!// Anzahl der zuletzt ausgegebenen Logeinträge
integer AnzahlEintraege=1000;

!//#######---Ende Variabler Bereich---#############################################################
!//Im Folgenden Hier keine Veränderungen vornehmen!

string stdout;
string stderr;
string dateien;

!// Neueste Dateien ermitteln
system.Exec("ls -t /media/usb1/HK-*.log 2>/dev/null | head -" # AnzahlDateien.ToString(),&dateien,&stderr);
dateien = dateien.Trim().Replace("\n"," ");

!// Keine Dateinamen ausgeben. Nur die Fundstellen
system.Exec("grep -h \"" # vrp # Suchbegriff # "\" " # dateien # " | sort | tail -n " # AnzahlEintraege.ToString(),&stdout,&stderr);

WriteLine(stdout);
