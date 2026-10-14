!// HMIPServer Neustart
!//================================================================================================
!// Stand:    15.10.2026
!//================================================================================================
!// Startet den HMIPServer (Java-Prozess) neu. Dieser muss nach dem Anlegen, Umbenennen oder
!// Löschen von Diagrammen neu gestartet werden, da sonst ein interner Fehler (RRD already closed)
!// dazu führt, dass Diagramme keine Daten mehr anzeigen.
!// Kann als zeitgesteuertes CCU-Programm (z.B. nächtlich) eingesetzt werden.
!//================================================================================================
!//

!// HMIPServer neu starten
system.Exec("/etc/init.d/S62HMServer restart");

!// Systemvariable "HMIP-Log" anlegen falls nicht vorhanden
var logObj = dom.GetObject("HMIP-Log");
if (!logObj) {
  var svObjects = dom.GetObject(ID_SYSTEM_VARIABLES);
  logObj = dom.CreateObject(OT_VARDP);
  svObjects.Add(logObj.ID());
  logObj.Name("HMIP-Log");
  logObj.DPInfo("Variable um ein einfaches Log im System Protokoll zu erzeugen");
  logObj.ValueType(ivtString);
  logObj.ValueSubType(istChar8859);
  logObj.DPArchive(true);
  logObj.State("");
}

!// Eintrag ins Systemprotokoll schreiben
logObj.State("HMIPServer Neustart durchgeführt");
