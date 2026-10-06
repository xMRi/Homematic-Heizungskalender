!// Diagnose: Raumzuordnung zwischen HK1-R-Liste und HK2-HKG-Liste prüfen
!//================================================================================================
!// Stand:    28.09.2026
!// Autor:    Martin Richter    (heizkalender@m-ri.de) http://blog.m-ri.de/
!// Projekt:  Helmut Diedrichs  (helmut@diedrichs.de) https://diedrichs.de
!//================================================================================================
!// Prüft, ob jede ChurchTools-Ressource (HK1-R-Liste) korrekt einer Raumvariable
!// (HK2-HKG-Liste) zugeordnet ist und ob die Raumvariable auf der CCU existiert.
!//
!// Hilft beim Nachstellen von Fällen, in denen ein Termin lautlos ignoriert wurde:
!// - Ressource-ID nicht in HK1-R-Liste → Termin wird ohne Log übersprungen
!// - Index in HK1-R-Liste hat keine entsprechende Position in HK2-HKG-Liste
!// - Raumvariable existiert nicht auf der CCU

!// Eingabe eines Namens Präfix (nur nötig wenn die Namensvorgabe geändert wurde)
string vrp="";

!//#######---Ende Variabler Bereich---#############################################################

object oRListe    = dom.GetObject(vrp # "HK1-R-Liste");
object oHKGListe  = dom.GetObject(vrp # "HK2-HKG-Liste");

if(!oRListe){
  WriteLine("FEHLER: Systemvariable \"" # vrp # "HK1-R-Liste\" nicht gefunden!");
  quit;
}
if(!oHKGListe){
  WriteLine("FEHLER: Systemvariable \"" # vrp # "HK2-HKG-Liste\" nicht gefunden!");
  quit;
}

string RIdListe  = oRListe.State();
string HKGListe  = oHKGListe.State();

WriteLine("HK1-R-Liste:   " # RIdListe);
WriteLine("HK2-HKG-Liste: " # HKGListe);
WriteLine("");
WriteLine("Index | Ressource-ID | CT-Name (optional) | Raumvariable (HKG-Liste) | Existiert?");
WriteLine("------+--------------+--------------------+--------------------------+-----------");

integer idx = 0;
string RIdEintrag;
foreach(RIdEintrag, RIdListe.Split(";")){
  string resId   = RIdEintrag.StrValueByIndex("=",0);
  string ctName  = RIdEintrag.StrValueByIndex("=",1);
  string raumVar = HKGListe.StrValueByIndex(";",idx);

  !// Nur den ersten Eintrag bei Multi-Raum (+) prüfen
  string raumVarPruef = raumVar.StrValueByIndex("+",0);

  string existiert = "NEIN (!)";
  if(raumVarPruef){
    object oRV = dom.GetObject(raumVarPruef);
    if(oRV){ existiert = "ja"; }
  } else {
    existiert = "LEER (!)";
  }

  if(ctName==""){  ctName = "(kein Name)"; }

  WriteLine(idx.ToString() # "     | " # resId # "           | " # ctName # "                 | " # raumVar # "       | " # existiert);

  idx = idx+1;
}

WriteLine("");
WriteLine("Eintraege in HK1-R-Liste:  " # idx.ToString());

!// Anzahl HKG-Liste bestimmen
integer idxHKG = 0;
string hkgEintrag;
foreach(hkgEintrag, HKGListe.Split(";")){
  idxHKG = idxHKG+1;
}
WriteLine("Eintraege in HK2-HKG-Liste: " # idxHKG.ToString());

if(idx != idxHKG){
  WriteLine("");
  WriteLine("WARNUNG: Anzahl stimmt nicht ueberein! Index-Versatz moeglich.");
}
