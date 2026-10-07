!// Mini-Test: Ein Feld einer Raumvariable setzen
!//================================================================================================
!// Stand:    22.09.2026
!// Autor:    Martin Richter    (heizkalender@m-ri.de) http://blog.m-ri.de/
!// Projekt:  Helmut Diedrichs  (helmut@diedrichs.de) https://diedrichs.de
!//================================================================================================
!// Setzt ein einzelnes Semikolon-getrenntes Feld einer Raumvariable auf einen neuen Wert.
!// Alle anderen Felder bleiben unveraendert.
!// Feld-Indizes (0-basiert):
!//   0 = Status (0=AUS, 1=EIN, 2=Dauer-AUS, 3=Dauer-EIN)
!//   1 = Modus (H/S/HS)
!//   2 = Heiztyp (IP/RT/TC/IT/SW)
!//   3 = Wohlfuehltemp[/Grundtemp]
!//   4 = Vorheizzeit[*Faktor]
!//   5 = VorzeitAus
!//   6+ = Sensor / Aktorenliste

!// Name der zu aendernden Raumvariable
string RaumName = "HKG-Raum-EG|Saal";

!// Index des zu setzenden Feldes (0-basiert, siehe oben)
integer FeldIndex = 3;

!// Neuer Wert fuer dieses Feld
string NeuerWert = "20";

!//#######---Ende Variabler Bereich---#############################################################

object oRaum = dom.GetObject(RaumName);
if(!oRaum){
  WriteLine("FEHLER: Systemvariable \"" # RaumName # "\" existiert nicht.");
  quit;
}

string RVI = oRaum.State();
WriteLine("Vorher:  " # RVI);

!// Raumvariable feldweise neu aufbauen, nur das gewuenschte Feld ersetzen
string RVINeu = "";
integer i = 0;
string sFeld;
foreach(sFeld, RVI.Split(";")){
  if(i==FeldIndex){ sFeld = NeuerWert; }
  if(i==0){ RVINeu = sFeld; } else { RVINeu = RVINeu # ";" # sFeld; }
  i = i+1;
}

oRaum.State(RVINeu);
WriteLine("Nachher: " # oRaum.State());
