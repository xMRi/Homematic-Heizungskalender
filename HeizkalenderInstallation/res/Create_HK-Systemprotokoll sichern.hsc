!//======================================================
!// Dieser Part löscht das ältere Programm, falls es existiert
!// Ansonsten ist es nichts anderes als das Backup des originalen
!// Skriptes mit dem SDV.
integer progId = %1%;
object oPRG;
if (progId!=0) {
    oPRG = dom.GetObject(ID_PROGRAMS).Get(progId);
    if (oPRG) {
      dom.DeleteObject(progId);
    }
}
!//------------------------------------------------------
string sPRGName= "%2%HK-Systemprotokoll sichern";
WriteLine ("Backup/Restore CCU Programme by Black 2025");
WriteLine ("Backup erstellt vom SDV V5.04.06 LCL am 07.01.2026 19:21:25");
WriteLine ("CCU ProgrammName: \"" # sPRGName # "\"");
WriteLine ("CCU ProgrammInfo: \"Sichern des Systemprotokolls auf dem USB Stick\"");
WriteLine ("----------------------------");
!- Verwendete Kanäle
string sCHNList= "";
!- Verwendete Systemvariablen
string sSYSVARList= "";
!- Referenzierung von im Programm verwendeten HSS-Datenpunkten
!- Die Referenzierung erfolgt über den substituierten Kanal und die HSSID 
!- Ab hier bitte die Finger weg !!!
!- ----------------------------
string s= "";
string sID; object oID; boolean isOK= true; boolean valid; integer idType; string  idName; string okText= "\tOK....\t"; string errText = "\tERROR.\t";
WriteLine ("Test auf Existenz referenzierter Channels");
foreach (sID,sCHNList) {oID=channels.Get(sID); if (oID) { Write (okText);} else {isOK=false; Write (errText); } WriteLine (sID);}  
WriteLine ("Test auf Existenz und Typkonsistenz referenzierter Systemvariablen");
foreach (sID,s) {
 if (sID.StrValueByIndex ("|",0).ToInteger ()==ID_SYSTEM_VARIABLES) {
   idName= sSYSVARList.StrValueByIndex ("\t", ((sID.StrValueByIndex ("|",1)).ToInteger () ));
   oID=dom.GetObject (ID_SYSTEM_VARIABLES).Get (idName); valid= false;
   if (oID) {
     valid= ((oID.Type()== sID.StrValueByIndex ("|",3).ToInteger ()) && (oID.ValueType()== sID.StrValueByIndex ("|",2).ToInteger ()));}
   if (valid) {Write (okText); } else { Write (errText); isOK=false; }
   if (sID.StrValueByIndex ("|",3).ToInteger ()==OT_VARDP) {Write("SYSVAR\t");} else {Write ("ALARM\t");}
   WriteLine (idName);
 }
}
WriteLine ("Test auf Existenz und Typkonsistenz referenzierter Geräte-Datenpunkte");
foreach (sID,s) {
 if (sID.StrValueByIndex ("|",0).ToInteger ()==ID_DATAPOINTS) {
   idName= sCHNList.StrValueByIndex ("\t", ((sID.StrValueByIndex ("|",1)).ToInteger () ));
   oID= channels.Get (idName); valid= false;
   if (oID) {
     oID= oID.DPByHssDP ((sID.StrValueByIndex ("|",4)));
     if (oID) {
       valid= ((oID.Type()== sID.StrValueByIndex ("|",3).ToInteger ()) && (oID.ValueType()== sID.StrValueByIndex ("|",2).ToInteger ()));
     }
   }
   if (valid) {Write (okText); } else { Write (errText); isOK=false; }
   WriteLine (idName #"."# (sID.StrValueByIndex ("|",4)));
 }
}
if (!isOK) {WriteLine ("Startbedingungen nicht erfüllt, Restore wird abgebrochen"); quit;}
object oPRG= dom.GetObject (ID_PROGRAMS).Get (sPRGName);
if (oPRG) {isOK= false; WriteLine ("Programm existiert schon mit dem Namen \"" # oPRG.Name () # "\" --> Abbruch"); quit;}  
oPRG= dom.CreateObject (OT_PROGRAM,sPRGName);
if (!oPRG) {WriteLine ("Programm konnte nicht angelegt werden. --> Abbruch"); quit; }
dom.GetObject (ID_PROGRAMS).Add (oPRG.ID () );
oPRG.PrgInfo ("Sichern des Systemprotokolls auf dem USB Stick");
oPRG.Active (false);
oPRG.Enabled  (true);
oPRG.Visible  (true);
oPRG.Internal (false);
object oCND; object oSCND; object oDST; object oSDST; object oOBJ;
!-------- MainCondition 
oCND= oPRG.MainCondition();
oCND.CndOperatorType (1);
object oRULE= oPRG.Rule ();
!-------- Rule 0
oRULE.RuleOperatorType (2);
oRULE.ElseIfFlag (true);
oCND=oRULE.RuleAddCondition(); !- Condition 0
oCND.CndOperatorType (2);
oSCND=oCND.CndAddSingle (); !- Single Condition 0
oSCND.ConditionType(3);
oSCND.ConditionType2(13);
oSCND.OperatorType(1);
oSCND.NegateCondition(false);
oSCND.ConditionChannel(65535);
oSCND.LeftValType(24);
oSCND.LeftVal(@2026-01-07 19:21:26@);
oSCND.RightVal1ValType(18);
oSCND.RightVal2ValType(0);
oOBJ= dom.CreateObject (OT_CALENDARDP,"Zeitmodul");
dom.GetObject(ID_CALENDARDPS).Add(oOBJ);
oOBJ.TimerType(4);
oOBJ.Time(@1970-01-01 01:00:00@);
oOBJ.CalDuration(0);
oOBJ.TimeSeconds(0);
oOBJ.CalRepeatTime(@1970-01-01 01:00:00@);
oOBJ.Weekdays(0);
oOBJ.Period(1740);
oOBJ.Begin(@2025-12-15 00:00:00@);
oOBJ.End(@1970-01-01 01:00:00@);
oOBJ.CalRepetitionCount(0);
oOBJ.CalRepetitionValue(0);
oOBJ.SunOffsetType(0);
oSCND.RightVal1 (oOBJ.ID () );
!-------- Rule Destination
oDST=oRULE.RuleDestination();
oDST.BreakOnRestart (true);
oSDST=oDST.DestAddSingle (); !- Single Destination 0
oSDST.DestinationParam(20);
oSDST.DestinationValueType(20);
oSDST.DestinationChannel(65535);
oSDST.DestinationDP(65535);
oSDST.DestinationValueParamType(28);
oSDST.DestinationValueParam(@2026-01-07 00:00:40@);
oSDST.DestinationValue("%3%");
oPRG.Active (true);
dom.RTUpdate (0);
WriteLine ("Restore Programm von Program \"" # sPRGName # "\" erfolgreich durchgelaufen");
