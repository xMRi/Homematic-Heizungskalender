!// Mini-Test: Raumvariable auslesen und Feld 3 zerlegen
!//================================================================================================
!// Stand:    22.09.2026
!// Autor:    Martin Richter    (heizkalender@m-ri.de) http://blog.m-ri.de/
!// Projekt:  Helmut Diedrichs  (helmut@diedrichs.de) https://diedrichs.de
!//================================================================================================

!// Name der auszulesenden Raumvariable
string RaumName = "HKG-Raum-EG|Saal";

!//#######---Ende Variabler Bereich---#############################################################

object oRaum = dom.GetObject(RaumName);
if(!oRaum){
  WriteLine("FEHLER: Systemvariable \"" # RaumName # "\" existiert nicht.");
  quit;
}

string RVI = oRaum.State();
WriteLine("Rohwert: " # RVI);

!// Feld 3: Wohlfuehltemp[/Grundtemp]
string Feld3     = RVI.StrValueByIndex(";",3);
real   RTemp     = Feld3.StrValueByIndex("/",0).ToFloat();
string sGT       = Feld3.StrValueByIndex("/",1);

WriteLine("Status:       " # RVI.StrValueByIndex(";",0));
WriteLine("Modus:        " # RVI.StrValueByIndex(";",1));
WriteLine("Heiztyp:      " # RVI.StrValueByIndex(";",2));
WriteLine("Feld 3 roh:   " # Feld3);
WriteLine("Wohlfuehl:    " # RTemp.ToString(1) # " °C");
WriteLine("Grundtemp:    " # sGT);
