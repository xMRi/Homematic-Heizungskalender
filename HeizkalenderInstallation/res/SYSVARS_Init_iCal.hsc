!- Anpassung bupdate = false    Wenn die Variable existiert, wird sie nicht verändert
!- Anpassungen barchive = true  Archive Flag immer setzen
!- Anpassung an den Prefix %1%
!//======================================================
!-          Backup SystemVariablen vom 29.01.2026 11:07:05
!-        Erstellt vom Script Developer V5.04.06 LCL by Black
!-------------------- Diese Zeilen Anpassen -------------------------
boolean bcreate = true; !- Anlegen, wenn noch nicht exitierte
boolean bupdate = false; !- Wert Updaten, wenn vorhanden und gleicher Typ
boolean barchive= true; !- false: immer restore mit DPArchive (false), true: restore mit altem Wert 
!--------------------------------------------------------------------
string sID; object oSV; string svName; object oCHN; object rSV= dom.GetObject (ID_SYSTEM_VARIABLES);
string neut=" neu angelegt"; string altt=" exisitiert schon";integer act= 0; integer neu= 0;
!------------
svName= "%1%HK1-ICS-Url"; oSV=rSV.Get (svName);
if (oSV) { 
	if ((oSV.ValueType()==20) && (oSV.ValueSubType()==11) && bupdate && (oSV.Type()!=OT_ALARMDP)) { 
		WriteLine (svName # altt);act=act+1;
		oSV.Variable ("");}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (20); oSV.ValueSubType (11);
	oSV.DPInfo("URL des iCal Kalender"); oSV.ValueUnit(""); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (false && barchive); !// Keine Protokollierung
		oSV.Variable ("");
	WriteLine (svName # neut);}
dom.RTUpdate(0);
WriteLine ("------------------");
WriteLine (act # " bestehende Systemvariablen aktualisiert");
WriteLine (neu # " neue Systemvariablen angelegt");
