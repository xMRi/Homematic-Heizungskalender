!- Anpassung bupdate = false    Wenn die Variable existiert, wird sie nicht verändert
!- Anpassungen barchive = true  Archive Flag immer setzen
!- Anpassung an den Prefix %1%
!//======================================================
!-          Backup SystemVariablen vom 05.01.2026 17:10:16
!-        Erstellt vom Script Developer V5.04.06 LCL by Black
!-------------------- Diese Zeilen Anpassen -------------------------
boolean bcreate = true; !- Anlegen, wenn noch nicht exitierte
boolean bupdate = false; !- Wert Updaten, wenn vorhanden und gleicher Typ
boolean barchive= true; !- false: immer restore mit DPArchive (false), true: restore mit altem Wert
!--------------------------------------------------------------------
string sID; object oSV; string svName; object oCHN; object rSV= dom.GetObject (ID_SYSTEM_VARIABLES);
string neut=" neu angelegt"; string altt=" exisitiert schon";integer act= 0; integer neu= 0;
!------------
svName= "%1%HK-Log"; oSV=rSV.Get (svName);
if (oSV) {
	if ((oSV.ValueType()==20) && (oSV.ValueSubType()==11) && bupdate && (oSV.Type()!=OT_ALARMDP)) {
		WriteLine (svName # altt);act=act+1;
		oSV.Variable ("");}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (20); oSV.ValueSubType (11);
	oSV.DPInfo("Variable um ein einfaches Log im System Protokoll zu erzeugen"); oSV.ValueUnit(""); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (true && barchive);
		oSV.Variable ("");
	WriteLine (svName # neut);}
!------------
svName= "%1%HK-Logging"; oSV=rSV.Get (svName);
if (oSV) {
	if ((oSV.ValueType()==2) && (oSV.ValueSubType()==2) && bupdate && (oSV.Type()!=OT_ALARMDP)) {
		WriteLine (svName # altt);act=act+1;
		oSV.Variable (true);}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (2); oSV.ValueSubType (2);
	oSV.DPInfo("Flag um das Logging für Tools ein- und auszuschalten"); oSV.ValueUnit(""); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (true && barchive);
	oSV.ValueName0 ("Logging ausgeschaltet"); oSV.ValueName1 ("Logging eingeschaltet");
	oSV.Variable (true);
	WriteLine (svName # neut);}
!------------
svName= "%1%HK-LoggingHeizkurvenkontrolle"; oSV=rSV.Get (svName);
if (oSV) {
	if ((oSV.ValueType()==2) && (oSV.ValueSubType()==2) && bupdate && (oSV.Type()!=OT_ALARMDP)) {
		WriteLine (svName # altt);act=act+1;
		oSV.Variable (true);}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (2); oSV.ValueSubType (2);
	oSV.DPInfo("Flag um das Logging für die Heizkurvenkontrolle ein- und auszuschalten"); oSV.ValueUnit(""); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (true && barchive);
	oSV.ValueName0 ("Logging ausgeschaltet"); oSV.ValueName1 ("Logging eingeschaltet");
	oSV.Variable (true);
	WriteLine (svName # neut);}
!------------
svName= "%1%HK-LogHeizkurvenkontrolle"; oSV=rSV.Get (svName);
if (oSV) {
	if ((oSV.ValueType()==20) && (oSV.ValueSubType()==11) && bupdate && (oSV.Type()!=OT_ALARMDP)) {
		WriteLine (svName # altt);act=act+1;
		oSV.Variable ("");}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (20); oSV.ValueSubType (11);
	oSV.DPInfo("Variable um ein einfaches Log im System Protokoll zu erzeugen"); oSV.ValueUnit(""); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (true && barchive);
		oSV.Variable ("");
	WriteLine (svName # neut);}
!------------
svName= "%1%HK-RäumeHeizkurvenkontrolle"; oSV=rSV.Get (svName);
if (oSV) {
	if ((oSV.ValueType()==20) && (oSV.ValueSubType()==11) && bupdate && (oSV.Type()!=OT_ALARMDP)) {
		WriteLine (svName # altt);act=act+1;
		oSV.Variable ("");}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (20); oSV.ValueSubType (11);
	oSV.DPInfo("Aktuelle Raumdaten in der Heizkurvenkontrolle"); oSV.ValueUnit(""); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (true && barchive);
		oSV.Variable ("");
	WriteLine (svName # neut);}
!------------
svName= "%1%HK1-Log"; oSV=rSV.Get (svName);
if (oSV) {
	if ((oSV.ValueType()==20) && (oSV.ValueSubType()==11) && bupdate && (oSV.Type()!=OT_ALARMDP)) {
		WriteLine (svName # altt);act=act+1;
		oSV.Variable ("");}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (20); oSV.ValueSubType (11);
	oSV.DPInfo("Variable um ein einfaches Log im System Protokoll zu erzeugen"); oSV.ValueUnit(""); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (true && barchive);
		oSV.Variable ("");
	WriteLine (svName # neut);}
!------------
svName= "%1%HK1-Logging"; oSV=rSV.Get (svName);
if (oSV) {
	if ((oSV.ValueType()==2) && (oSV.ValueSubType()==2) && bupdate && (oSV.Type()!=OT_ALARMDP)) {
		WriteLine (svName # altt);act=act+1;
		oSV.Variable (true);}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (2); oSV.ValueSubType (2);
	oSV.DPInfo("Flag um das Logging für Skript 1 ein- und auszuschalten"); oSV.ValueUnit(""); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (true && barchive);
	oSV.ValueName0 ("Logging ausgeschaltet"); oSV.ValueName1 ("Logging eingeschaltet");
	oSV.Variable (true);
	WriteLine (svName # neut);}
!------------
svName= "%1%HK2-A.Temp.Grenze"; oSV=rSV.Get (svName);
if (oSV) {
	if ((oSV.ValueType()==4) && (oSV.ValueSubType()==0) && bupdate && (oSV.Type()!=OT_ALARMDP)) {
		WriteLine (svName # altt);act=act+1;
		oSV.Variable ("19.000000".ToFloat());}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (4); oSV.ValueSubType (0);
	oSV.DPInfo("Außentemperatur-Grenzwert für das Heizen"); oSV.ValueUnit("°C"); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (true && barchive);
	oSV.Variable ("19.000000".ToFloat ()); oSV.ValueMin ("-50".ToFloat()); oSV.ValueMax ("50".ToFloat ());
	WriteLine (svName # neut);}
!------------
svName= "%1%HK2-Aussentemperatur"; oSV=rSV.Get (svName);
if (oSV) {
	if ((oSV.ValueType()==4) && (oSV.ValueSubType()==0) && bupdate && (oSV.Type()!=OT_ALARMDP)) {
		WriteLine (svName # altt);act=act+1;
		oSV.Variable ("0.000000".ToFloat());}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (4); oSV.ValueSubType (0);
	oSV.DPInfo("Zu verwendende Außentemperatur"); oSV.ValueUnit("°C"); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (true && barchive);
	oSV.Variable ("0.000000".ToFloat ()); oSV.ValueMin ("-50".ToFloat()); oSV.ValueMax ("50".ToFloat ());
	WriteLine (svName # neut);}
!------------
svName= "%1%HK2-Grundtemperatur"; oSV=rSV.Get (svName);
if (oSV) {
	if ((oSV.ValueType()==4) && (oSV.ValueSubType()==0) && bupdate && (oSV.Type()!=OT_ALARMDP)) {
		WriteLine (svName # altt);act=act+1;
		oSV.Variable ("16.000000".ToFloat());}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (4); oSV.ValueSubType (0);
	oSV.DPInfo("Grundtemperatur"); oSV.ValueUnit("°C"); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (true && barchive);
	oSV.Variable ("16.000000".ToFloat ()); oSV.ValueMin ("5".ToFloat()); oSV.ValueMax ("30".ToFloat ());
	WriteLine (svName # neut);}
!------------
svName= "%1%HK2-Hand-Grundtemp"; oSV=rSV.Get (svName);
if (oSV) {
	if ((oSV.ValueType()==2) && (oSV.ValueSubType()==2) && bupdate && (oSV.Type()!=OT_ALARMDP)) {
		WriteLine (svName # altt);act=act+1;
		oSV.Variable (true);}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (2); oSV.ValueSubType (2);
	oSV.DPInfo("Rückstellung auf Grundtemperatur"); oSV.ValueUnit(""); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (true && barchive);
	oSV.ValueName0 ("Keine Rückstellung auf Grundtemperatur um 01:00 Uhr"); oSV.ValueName1 ("Rückstellung auf Grundtemperatur um 01:00 Uhr");
	oSV.Variable (true);
	WriteLine (svName # neut);}
!------------
svName= "%1%HK2-Hand-Temp"; oSV=rSV.Get (svName);
if (oSV) {
	if ((oSV.ValueType()==2) && (oSV.ValueSubType()==2) && bupdate && (oSV.Type()!=OT_ALARMDP)) {
		WriteLine (svName # altt);act=act+1;
		oSV.Variable (false);}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (2); oSV.ValueSubType (2);
	oSV.DPInfo("Vorrang manuell eingestellte Temperatur beim Ausschalten"); oSV.ValueUnit(""); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (true && barchive);
	oSV.ValueName0 ("Immer auf Grundtemperatur zurücksetzen"); oSV.ValueName1 ("Manuelle Temperatur hat Vorrang");
	oSV.Variable (false);
	WriteLine (svName # neut);}
!------------
svName= "%1%HK2-HKG-Liste"; oSV=rSV.Get (svName);
if (oSV) {
	if ((oSV.ValueType()==20) && (oSV.ValueSubType()==11) && bupdate && (oSV.Type()!=OT_ALARMDP)) {
		WriteLine (svName # altt);act=act+1;
		oSV.Variable ("");}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (20); oSV.ValueSubType (11);
	oSV.DPInfo("Liste der HK-Raum-Variablen"); oSV.ValueUnit(""); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (true && barchive);
		oSV.Variable ("");
	WriteLine (svName # neut);}
!------------
svName= "%1%HK2-Kurve"; oSV=rSV.Get (svName);
if (oSV) {
	if ((oSV.ValueType()==20) && (oSV.ValueSubType()==11) && bupdate && (oSV.Type()!=OT_ALARMDP)) {
		WriteLine (svName # altt);act=act+1;
		oSV.Variable ("162;130;100;59;50;41;30;20");}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (20); oSV.ValueSubType (11);
	oSV.DPInfo("Hzg.-Vorlaufzeit: Eingeben in Minuten zu Außentemperaturen kleiner als -10, -5, 0, 8, 10, 12, 15, 17,5"); oSV.ValueUnit("min"); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (true && barchive);
		oSV.Variable ("162;130;100;59;50;41;30;20");
	WriteLine (svName # neut);}
!------------
svName= "%1%HK2-Kurvenversatz"; oSV=rSV.Get (svName);
if (oSV) {
	if ((oSV.ValueType()==4) && (oSV.ValueSubType()==0) && bupdate && (oSV.Type()!=OT_ALARMDP)) {
		WriteLine (svName # altt);act=act+1;
		oSV.Variable ("0.000000".ToFloat());}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (4); oSV.ValueSubType (0);
	oSV.DPInfo("Grundoffsetzeit Einschalten"); oSV.ValueUnit("min"); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (true && barchive);
	oSV.Variable ("0.000000".ToFloat ()); oSV.ValueMin ("-100".ToFloat()); oSV.ValueMax ("100".ToFloat ());
	WriteLine (svName # neut);}
!------------
svName= "%1%HK2-Log"; oSV=rSV.Get (svName);
if (oSV) {
	if ((oSV.ValueType()==20) && (oSV.ValueSubType()==11) && bupdate && (oSV.Type()!=OT_ALARMDP)) {
		WriteLine (svName # altt);act=act+1;
		oSV.Variable ("");}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (20); oSV.ValueSubType (11);
	oSV.DPInfo("Variable um ein einfaches Log im System Protokoll zu erzeugen"); oSV.ValueUnit(""); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (true && barchive);
		oSV.Variable ("");
	WriteLine (svName # neut);}
!------------
svName= "%1%HK2-Logging"; oSV=rSV.Get (svName);
if (oSV) {
	if ((oSV.ValueType()==2) && (oSV.ValueSubType()==2) && bupdate && (oSV.Type()!=OT_ALARMDP)) {
		WriteLine (svName # altt);act=act+1;
		oSV.Variable (true);}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (2); oSV.ValueSubType (2);
	oSV.DPInfo("Flag um das Logging für Skript 2 ein- und auszuschalten"); oSV.ValueUnit(""); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (true && barchive);
	oSV.ValueName0 ("Logging ausgeschaltet"); oSV.ValueName1 ("Logging eingeschaltet");
	oSV.Variable (true);
	WriteLine (svName # neut);}
!------------
svName= "%1%HK2-VorzeitAus"; oSV=rSV.Get (svName);
if (oSV) {
	if ((oSV.ValueType()==4) && (oSV.ValueSubType()==0) && bupdate && (oSV.Type()!=OT_ALARMDP)) {
		WriteLine (svName # altt);act=act+1;
		oSV.Variable ("0.000000".ToFloat());}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (4); oSV.ValueSubType (0);
	oSV.DPInfo("Grundoffsetzeit Ausschalten"); oSV.ValueUnit("min"); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (true && barchive);
	oSV.Variable ("0.000000".ToFloat ()); oSV.ValueMin ("0".ToFloat()); oSV.ValueMax ("120".ToFloat ());
	WriteLine (svName # neut);}
!------------
svName= "%1%HK1-Schaltliste"; oSV=rSV.Get (svName);
if (oSV) {
	if ((oSV.ValueType()==20) && (oSV.ValueSubType()==11) && bupdate && (oSV.Type()!=OT_ALARMDP)) {
		WriteLine (svName # altt);act=act+1;
		oSV.Variable ("");}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (20); oSV.ValueSubType (11);
	oSV.DPInfo("Gelesene Termine aus Skript 1. Hier bitte nichts verändern!"); oSV.ValueUnit(""); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (true && barchive);
		oSV.Variable ("");
	WriteLine (svName # neut);}
!------------
svName= "%1%HK1-R-Liste"; oSV=rSV.Get (svName);
if (oSV) {
	if ((oSV.ValueType()==20) && (oSV.ValueSubType()==11) && bupdate && (oSV.Type()!=OT_ALARMDP)) {
		WriteLine (svName # altt);act=act+1;
		oSV.Variable ("");}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (20); oSV.ValueSubType (11);
	oSV.DPInfo("Zuordnung der Räume aus der Ressourcenverwaltung"); oSV.ValueUnit(""); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (true && barchive);
		oSV.Variable ("");
	WriteLine (svName # neut);}
!------------
svName= "%1%HK2-HKG-Liste"; oSV=rSV.Get (svName);
if (oSV) {
	if ((oSV.ValueType()==20) && (oSV.ValueSubType()==11) && bupdate && (oSV.Type()!=OT_ALARMDP)) {
		WriteLine (svName # altt);act=act+1;
		oSV.Variable ("");}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (20); oSV.ValueSubType (11);
	oSV.DPInfo("Liste der HK-Raum-Variablen"); oSV.ValueUnit(""); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (true && barchive);
		oSV.Variable ("");
	WriteLine (svName # neut);}
!------------
svName= "%1%HK1-Vorlaufzeit"; oSV=rSV.Get (svName);
if (oSV) {
	if ((oSV.ValueType()==4) && (oSV.ValueSubType()==0) && bupdate && (oSV.Type()!=OT_ALARMDP)) {
		WriteLine (svName # altt);act=act+1;
		oSV.Variable ("720.000000".ToFloat());}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (4); oSV.ValueSubType (0);
	oSV.DPInfo("Zeithorizont für Terminabfrage in Minuten (Default 720, max. 1380)"); oSV.ValueUnit("min"); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (true && barchive);
	oSV.Variable ("720.000000".ToFloat ()); oSV.ValueMin ("0".ToFloat()); oSV.ValueMax ("1380".ToFloat ());
	WriteLine (svName # neut);}
!------------
svName= "%1%HK2-Schaltzeiten"; oSV=rSV.Get (svName);
if (oSV) {
	if ((oSV.ValueType()==20) && (oSV.ValueSubType()==11) && bupdate && (oSV.Type()!=OT_ALARMDP)) {
		WriteLine (svName # altt);act=act+1;
		oSV.Variable ("");}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (20); oSV.ValueSubType (11);
	oSV.DPInfo("Berechnete Schaltzeiten pro Raum von Skript 2 für das Addon. Hier bitte nichts verändern!"); oSV.ValueUnit(""); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (false && barchive); !// Keine Protokollierung
		oSV.Variable ("");
	WriteLine (svName # neut);}
!------------
svName= "%1%HK2-HKK-Zieltemperatur"; oSV=rSV.Get (svName);
if (oSV) {
	if ((oSV.ValueType()==20) && (oSV.ValueSubType()==11) && bupdate && (oSV.Type()!=OT_ALARMDP)) {
		WriteLine (svName # altt);act=act+1;
		oSV.Variable ("");}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (20); oSV.ValueSubType (11);
	oSV.DPInfo("Heizkurvenkontrolle Zieltemperatur: Kritisch-vor;Perfekt-von;Perfekt-bis;Kritisch-nach"); oSV.ValueUnit(""); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (true && barchive);
		oSV.Variable ("-90;-60;-30;-15");
	WriteLine (svName # neut);}
!------------
svName= "%1%HK3-Log"; oSV=rSV.Get (svName);
if (oSV) {
	if ((oSV.ValueType()==20) && (oSV.ValueSubType()==11) && bupdate && (oSV.Type()!=OT_ALARMDP)) {
		WriteLine (svName # altt);act=act+1;
		oSV.Variable ("");}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (20); oSV.ValueSubType (11);
	oSV.DPInfo("Variable um ein einfaches Log im System Protokoll zu erzeugen"); oSV.ValueUnit(""); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (true && barchive);
		oSV.Variable ("");
	WriteLine (svName # neut);}
!------------
svName= "%1%HK3-Logging"; oSV=rSV.Get (svName);
if (oSV) {
	if ((oSV.ValueType()==2) && (oSV.ValueSubType()==2) && bupdate && (oSV.Type()!=OT_ALARMDP)) {
		WriteLine (svName # altt);act=act+1;
		oSV.Variable (true);}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (2); oSV.ValueSubType (2);
	oSV.DPInfo("Flag um das Logging für Skript 3 ein- und auszuschalten"); oSV.ValueUnit(""); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (true && barchive);
	oSV.ValueName0 ("Logging ausgeschaltet"); oSV.ValueName1 ("Logging eingeschaltet");
	oSV.Variable (true);
	WriteLine (svName # neut);}
!------------
svName= "%1%HK2-Schaltliste"; oSV=rSV.Get (svName);
if (oSV) {
	if ((oSV.ValueType()==20) && (oSV.ValueSubType()==11) && bupdate && (oSV.Type()!=OT_ALARMDP)) {
		WriteLine (svName # altt);act=act+1;
		oSV.Variable ("");}
} elseif (bcreate) {
	neu=neu+1;oSV = dom.CreateObject (1089); rSV.Add (oSV.ID()); oSV.Name (svName); oSV.ValueType (20); oSV.ValueSubType (11);
	oSV.DPInfo("Berechnete Schaltzeiten pro Raum von Skript 2 für den Schaltvorgang. Hier bitte nichts verändern!"); oSV.ValueUnit(""); oSV.Internal(false); oSV.Visible(true); oSV.Unerasable(false);
	oSV.DPArchive (false && barchive); !// Keine Protokollierung
		oSV.Variable ("");
	WriteLine (svName # neut);}
!------------
dom.RTUpdate(0);
WriteLine ("------------------");
WriteLine (act # " bestehende Systemvariablen aktualisiert");
WriteLine (neu # " neue Systemvariablen angelegt");
