SYSVARS-InitValues.hsc
	Backup mit SDV. Direkt nach erzeugen mit den Init Skripten
		HK-Init-Variablen Logging.hsc
		HK-Init-Skript 2.hsc
	Anpassungen
		bupdate = false		Wenn die Variable existiert, wird sienicht verändert
		barchive = true		Archive Flag immer setzen

SYSVARS-InitValues_ChurchDesk.hsc
	Backup mit SDV. Direkt nach erzeugen mit den Init Skripten
		HK-Init-Skript 1_CurchDesk.hsc
	Anpassungen
		bupdate = false		Wenn die Variable existiert, wird sienicht verändert
		barchive = true		Archive Flag immer setzen

SYSVARS-InitValues_ChurchTools.hsc
	Backup mit SDV. Direkt nach erzeugen mit den Init Skripten
		HK-Init-Skript 1_CurchTools.hsc
	Anpassungen
		bupdate = false		Wenn die Variable existiert, wird sienicht verändert
		barchive = true		Archive Flag immer setzen

SYSVARS-InitValues.txt
	Ausgabe der SYSVARS mit dem entsprechenden Skript, dass zum Einlesen benutzt wird.
	Die Ids spielen keine Rolle hier. Nur Werte und initiale Beschreibung sind wichtg.
	Hier werden alle Variablen aufgeführt, die wir nutzen, also alle Variablen aus allen
	Init-Skripten.

Create_HK-Außentemperatur_Open_Meteo
Create_HK-Heizkurvenkontrolle		
Create_HK-Skript_1					
Create_HK-Skript_2					
Create_HK-Skript_3					
Create_HK-Systemprotokoll_sichern	
	Backup Skripte der Programme aus meinem Livesyste mit den korrekten 
	Zeitprogrammen und Bedingungen. Ersetz werden im Namen und im Skript 
	Platzhalter %1 für den Prefix und %2 für das Skript.
	Die Leerzeichen im Namen mussten durch unterstriche ersetzt werden.