// Heizkalender-Installer
// Copyright (C) 2026 Martin Richter (xMRi-Software) - heizkalender@m-ri.de
//
// Dieses Programm ist freie Software: Sie können es unter den Bedingungen
// der GNU General Public License, wie von der Free Software Foundation
// veröffentlicht, weitergeben und/oder modifizieren, entweder gemäß
// Version 3 der Lizenz oder (nach Ihrer Wahl) jeder späteren Version.
//
// Dieses Programm wird in der Hoffnung verteilt, dass es nützlich ist,
// jedoch OHNE JEDE GEWÄHRLEISTUNG; sogar ohne die implizite Gewährleistung
// der MARKTFÄHIGKEIT oder EIGNUNG FÜR EINEN BESTIMMTEN ZWECK.
// Weitere Details finden Sie in der GNU General Public License.
//
// Sie sollten eine Kopie der GNU General Public License zusammen mit
// diesem Programm erhalten haben. Falls nicht, siehe
// <https://www.gnu.org/licenses/>.
// 
// SPDX-License-Identifier: GPL-3.0-or-later

#include "pch.h"
#include "HeizkalenderInstallation.h"
#include "FileVersionInfo.h"
#include "PropertySheet.h"
#include "ScriptEngine.h"
#include "WarningDlg.h"
#include "WGetEngine.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif

class CInstallerCommandLineInfo : public CCommandLineInfo
{
public:
	// Construction
	CInstallerCommandLineInfo()
	{
	}

	// Overwritten virtual
	void ParseParam(const TCHAR* pszParam, BOOL bFlag, BOOL bLast) override;
#ifdef _UNICODE
	void ParseParam(const char* pszParam, BOOL bFlag, BOOL bLast) override;
#endif

	bool m_bSimulation = {};
	bool m_bForceUpdate = {};
	CString m_strScriptDir;
};

#ifdef _UNICODE
void CInstallerCommandLineInfo::ParseParam(const TCHAR* pszParam,BOOL bFlag,BOOL bLast)
{
	ParseParam(CT2CA(pszParam),bFlag,bLast);
}
#endif

void CInstallerCommandLineInfo::ParseParam(const char* pszParam, BOOL bFlag, BOOL bLast)
{
	if (bFlag)
	{
		if (_strnicmp(pszParam, "scripts:", 8)==0 ||
		    _strnicmp(pszParam, "skripte:", 8)==0)
		{
			// Pfad auf scripte
			pszParam += 8;
			m_strScriptDir = pszParam;
			::PathUnquoteSpaces(CStrBuf(m_strScriptDir, 0));
		}
		else if (_stricmp(pszParam, "simulation")==0)
		{
			m_bSimulation = true;
		}
		else if (_stricmp(pszParam, "force")==0)
		{
			m_bForceUpdate = true;
		}
		else
			ParseParamFlag(pszParam);
	}
	else
		ParseParamNotFlag(pszParam);

	// Standard implementation
	ParseLast(bLast);
}


// CHeizkalenderInstallationApp

BEGIN_MESSAGE_MAP(CHeizkalenderInstallationApp, CWinApp)
	ON_COMMAND(ID_HELP, &CWinApp::OnHelp)
END_MESSAGE_MAP()


// CHeizkalenderInstallationApp-Erstellung

CHeizkalenderInstallationApp::CHeizkalenderInstallationApp()
	: m_bConnected{false}
	, m_bSimulation{false}
	, m_bForceUpdate{false}
	, m_bNoProgramUpdate{ false }
	, m_dateMaxPrograms{0.0}
	, m_modeScript1{ModeScript1::Unknown}
	, m_modeScript1Installed{ModeScript1::Unknown}
{
	// Locale auf englisch setzen
	std::setlocale(LC_ALL, "C");
	std::locale::global(std::locale("C"));

	// Version bestimmen
	auto *pName = m_strAppPath.GetBuffer(_MAX_PATH);
	::GetModuleFileName(NULL, pName, _MAX_PATH);
	::PathRemoveExtension(pName);
	m_strAppName = ::PathFindFileName(pName);
	::PathRemoveFileSpec(pName);
	m_strAppPath.ReleaseBuffer();

	CFileVersionInfo fvi;
	fvi.GetFileVersionInfo();
	m_strAppVersion.Format(_T("%d.%d.%d"), HIWORD(fvi.dwFileVersionMS),LOWORD(fvi.dwFileVersionMS),HIWORD(fvi.dwFileVersionLS));

	// Alle notwendigen Dateien festlegen
	PCSTR const aFiles[] = {
		"HK-Außentemperatur-Open-Meteo",
		"HK-Heizkurvenkontrolle",
		"HK-Skript 1",
		"HK-Skript 2",
		"HK-Skript 3",
		"HK-Systemprotokoll sichern",
	};	
	for (auto* pName : aFiles)
		m_setProgramNames.emplace(pName);
}


// Das einzige CHeizkalenderInstallationApp-Objekt

CHeizkalenderInstallationApp theApp;

// CHeizkalenderInstallationApp-Initialisierung

BOOL CHeizkalenderInstallationApp::InitInstance()
{
	// InitCommonControlsEx() ist für Windows XP erforderlich, wenn ein Anwendungsmanifest
	// die Verwendung von ComCtl32.dll Version 6 oder höher zum Aktivieren
	// von visuellen Stilen angibt.  Ansonsten treten beim Erstellen von Fenstern Fehler auf.
	INITCOMMONCONTROLSEX InitCtrls;
	InitCtrls.dwSize = sizeof(InitCtrls);

	// Legen Sie dies fest, um alle allgemeinen Steuerelementklassen einzubeziehen,
	// die Sie in Ihrer Anwendung verwenden möchten.
	InitCtrls.dwICC = ICC_WIN95_CLASSES;
	InitCommonControlsEx(&InitCtrls);

	CWinApp::InitInstance();

	if (!AfxSocketInit())
	{
		AfxMessageBox(IDP_SOCKETS_INIT_FAILED);
		return FALSE;
	}

	// Shell-Manager erstellen, falls das Dialogfeld
	// Shellbaumansicht- oder Shelllistenansicht-Steuerelemente enthält.
	std::unique_ptr<CShellManager> pShellManager{ new CShellManager };

	//Visuellen Manager "Windows Native" aktivieren, um Designs für MFC-Steuerelemente zu aktivieren
	CMFCVisualManager::SetDefaultManager(RUNTIME_CLASS(CMFCVisualManagerWindows));

	// Standardinitialisierung
	SetRegistryKey(_T("xMRi-Software"));

	//------------------------------------------------------------------------

	CInstallerCommandLineInfo cmdInfo;
	ParseCommandLine(cmdInfo);
	m_strScriptPath = m_strAppPath;
	if (!cmdInfo.m_strScriptDir.IsEmpty())
		m_strScriptPath = cmdInfo.m_strScriptDir;
	m_bSimulation = cmdInfo.m_bSimulation;
	m_bForceUpdate = cmdInfo.m_bForceUpdate;

	// Warnungs dialog anzeigen
	if (GetProfileInt(_T("General"), _T("ShowWarning"), TRUE))
	{
		CWarningDlg dlg;
		dlg.DoModal();
		if (dlg.m_bDontShowAgain)
			WriteProfileInt(_T("General"), _T("ShowWarning"), FALSE);
	}

	// Standard Skripte alle laden und letztes Datum bestimmen
	CString strMissing;
	COleDateTime dateMax{ 0.0 };
	struct {
		PCSTR m_pFileName;
		bool  m_bNeedsPrefixClause;
	} const aFiles[] = {
		"HK-Außentemperatur-Open-Meteo",	true,
		"HK-Heizkurvenkontrolle",			true,
		"HK-Skript 1_ChurchDeskAPI",		true,
		"HK-Skript 1_ChurchDeskiCal",		true,
		"HK-Skript 1_ChurchTools",			true,
		"HK-Skript 1_iCal",					true,
		"HK-Skript 1_Google",				true,
		"HK-Skript 2",						true,
		"HK-Skript 3",						true,
		"HK-Systemprotokoll sichern",		false,
	};
	for (auto const &e : aFiles)
	{
		CString strName { e.m_pFileName };
		CString strFileName, str;
		auto* pFileName = strFileName.GetBuffer(_MAX_PATH);
		::PathCombine(pFileName,m_strScriptPath,strName);
		::PathAddExtension(pFileName,_T(".hsc"));
		strFileName.ReleaseBuffer();

		if (GetFileContent(strFileName, str))
		{
			CDataProgram data{ 0, strName, CString{} };
			data.m_strSkript = CStringA{ str };
			data.m_strSkriptBeschreibung = StrValueByIndex(str,0,_T('\n'));
			int iPos = data.m_strSkript.Find("Stand:");
			if (iPos>=0)
			{
				auto date = ParseDate(data.m_strSkript.GetString()+iPos+6);
				data.m_date = date;
				if (date>dateMax)
					dateMax = date;
			}
			// Manche Skripte müssen für den Prefix dieses Statement enthalten!
			//		string vrp="";
			if (data.m_strSkriptBeschreibung.IsEmpty() || !IsDateValid(data.m_date) ||
				(e.m_bNeedsPrefixClause && data.m_strSkript.Find("string vrp=\"\";")<0)) 
			{
				CString strError;
				strError.FormatMessage(IDP_FILE_INVALID,::PathFindFileName(strFileName));
				AfxMessageBox(strError);
				return FALSE;
			}
			m_lstAppPrograms.push_back(data);
		}
		else
		{
			AppendTextWithDelimiter(strMissing,strName,_T("\n\t"));
		}
	}

	if (!strMissing.IsEmpty())
	{
		CString strError;
		strError.FormatMessage(IDP_FILES_MISSING,strMissing.GetString());
		AfxMessageBox(strError);
		return FALSE;
	}

	if (dateMax.GetYear()>2000)
		m_strScriptVersion = DateToString(dateMax);
	m_dateMaxPrograms = dateMax;

	// Optionale Skripte finden (beginnen alle mit Tool)
	CFileFind finder;
	BOOL bWorking = finder.FindFile(m_strScriptPath + _T("\\Tool-*.hsc"));
	while (bWorking)
	{
		bWorking = finder.FindNextFile();

		// . und .. überspringen
		if (finder.IsDots())
			continue;

		// Nur Dateien (keine Verzeichnisse)
		if (!finder.IsDirectory())
		{
			CString strFileName = finder.GetFilePath(), str;    
			if (GetFileContent(strFileName, str))
			{
				CString strName = ::PathFindFileName(strFileName);
				::PathRemoveExtension(CStrBuf(strName, 0));
				CDataProgram data{ 0, strName, CString{} };
				data.m_strSkript = CStringA{ str };
				data.m_strSkriptBeschreibung = StrValueByIndex(str,0,_T('\n'));
				int iPos = data.m_strSkript.Find("Stand:");
				if (iPos>=0)
				{
					auto date = ParseDate(data.m_strSkript.GetString()+iPos+6);
					data.m_date = date;
					if (date>dateMax)
						dateMax = date;
				}
				// Typ und Stand sollten wir ermitteln können
				if (data.m_strSkriptBeschreibung.IsEmpty() || !IsDateValid(data.m_date)) 
					continue;

				m_lstAppTools.push_back(data);
			}
		}
	}
	finder.Close();
	
	// Default Daten laden. D.h die Daten aus der Vorgabe
	{
		CStringA strData;
		VERIFY(LoadStringFromResource(strData,_T("SYSVARS-InitValues"),_T("TEXT")));
		m_lstSysVarsDefault.LoadFromString(strData);

		// Alle Ids auf 0 setzen! Damit können wir die Daten kpieren und in der neuen
		// Liste ist dieser Eintrag als neu zu erkennen.
		for( auto &e : m_lstSysVarsDefault)
			e.m_id = 0;
	}

	CInstallationsWizard dlg;
	m_pMainWnd = &dlg;
	dlg.DoModal();

	ControlBarCleanUp();

	// Da das Dialogfeld geschlossen wurde, FALSE zurückliefern, sodass wir die
	//  Anwendung verlassen, anstatt das Nachrichtensystem der Anwendung zu starten.
	return FALSE;
}

bool CHeizkalenderInstallationApp::ConnectToSimulation()
{
	ClearAll();

	if (GetProfileInt(_T("Simulation"), _T("Simulation"), FALSE))
	{
		if (AfxMessageBox(IDP_QUERY_SIMULATION_LADEN, MB_ICONQUESTION|MB_DEFBUTTON1|MB_YESNO)!=IDYES)
		{
			CRegKey regKey{ GetAppRegistryKey() };
			regKey.RecurseDeleteKey(_T("Simulation"));
		}
	}

	// Lade den entsprechenden Abschnitt für SysVars
	CRegKey regKey{ GetSectionKey(_T("Simulation")) };
	CRegKey regKeyVars;
	if (regKeyVars.Open(regKey,_T("SystemVariablen"),KEY_READ | KEY_WRITE)==ERROR_SUCCESS)
	{
		// Alle variablen lesen
		for (DWORD i = 0; true; ++i)
		{
			CString strName, strData;
			DWORD dwValueType = 0, dwDataLen = 2048;
			LONG lResult = 0;
			do {
				DWORD dwNameLen = _MAX_PATH;
				lResult = RegEnumValue(regKeyVars, i, CStrBuf(strName, dwNameLen), &dwNameLen, nullptr, &dwValueType, reinterpret_cast<BYTE*>(static_cast<PTSTR>(CStrBuf(strData, dwDataLen/sizeof(TCHAR)))), &dwDataLen);
			} while (lResult==ERROR_MORE_DATA);

			if (lResult!=ERROR_SUCCESS)
				break;

			// String Daten speichern
			strData.Replace(_T("\\t"),_T("\t"));
			CDataSystemVariable data{ strData };
			m_lstSysVars.push_back(data);
		}
	}

	// Lade den entsprechenden Abschnitt für Programme
	CRegKey regKeyProgs;
	if (regKeyProgs.Open(regKey,_T("Programme"),KEY_READ | KEY_WRITE)==ERROR_SUCCESS)
	{
		// Alle variablen lesen
		for (DWORD i = 0; true; ++i)
		{
			CString strName, strData;
			DWORD dwValueType = 0, dwDataLen = 10*1024;
			LONG lResult = 0;
			do {
				DWORD dwNameLen = _MAX_PATH;
				lResult = RegEnumValue(regKeyProgs, i, CStrBuf(strName, dwNameLen), &dwNameLen, nullptr, &dwValueType, reinterpret_cast<BYTE*>(static_cast<PTSTR>(CStrBuf(strData, dwDataLen/sizeof(TCHAR)))), &dwDataLen);
			} while (lResult==ERROR_MORE_DATA);

			if (lResult!=ERROR_SUCCESS)
				break;

			// String Daten speichern
			strData.Replace(_T("\\t"),_T("\t"));
			CDataProgram data{ strData };
			m_lstPrograms.push_back(data);
		}
	}

	return true;
}

bool CHeizkalenderInstallationApp::ConnectToCCU()
{
	ClearAll();
	return LoadSystemVariablesFromCCU() && LoadProgramsFromCCU(m_strPrefix) && LoadDevicesFromCCU();
}

bool CHeizkalenderInstallationApp::AnalyseLoadedData()
{
//-----------------------------------------------------------------------------
	//// Prüfen ob wir alle Programme kennen
	//CString strProgs;
	//for (auto const& e : m_lstPrograms)
	//{
	//	// Prüfe ob wir den Namen kennen
	//	if (m_setProgramNames.find(RemovePrefix(e.m_strName))==m_setProgramNames.end())
	//		AppendTextWithDelimiter(strProgs,e.m_strName,_T("\n\t"));
	//}

	// Versuche den aktuellen Modus für Skript 1 zu bestimmen.
	// Als erstes versuchen wir das die Variablen zu erkennen.
	auto *pVarCTGemeineName = m_lstSysVars.Find(AddPrefix(_T("HK1-CT-Gemeindename")));
	auto *pVarCTToken = m_lstSysVars.Find(AddPrefix(_T("HK1-CT-Token")));
	auto *pVarCDOrganisationsId = m_lstSysVars.Find(AddPrefix(_T("HK1-CD-OrganisationsId")));
	auto *pVarCDToken = m_lstSysVars.Find(AddPrefix(_T("HK1-CD-Token")));
	auto *pVarICalUrl = m_lstSysVars.Find(AddPrefix(_T("HK1-ICS-Url")));
	auto *pVarGoogleApiKey = m_lstSysVars.Find(AddPrefix(_T("HK1-GK-API-Key")));
	auto *pVarGoogleCalId = m_lstSysVars.Find(AddPrefix(_T("HK1-GK-Kalender-ID")));
	if (pVarCTGemeineName && pVarCTToken)
	{
		m_modeScript1Installed = ModeScript1::ChurchToolsAPI;
	}
	else if (pVarCDOrganisationsId && pVarCDToken)
	{
		// Nur anhand der Tokens können wir nicht die Zugriffsart bestimmen. Wir
		// brauchen aus dem Skript 1 die erste Zeile.
		auto pProg = m_lstPrograms.Find(GetScript1Name());
		CString strLine1 = pProg ? pProg->m_strSkriptBeschreibung : CString{};
		strLine1.MakeUpper();
		if (strLine1.Find(_T("CHURCHDESK"))>=0 && strLine1.Find(_T("API"))>=0)
			m_modeScript1Installed = ModeScript1::ChurchDeskAPI;
		else if (strLine1.Find(_T("CHURCHDESK"))>=0 && strLine1.Find(_T("ICAL"))>=0)
			m_modeScript1Installed = ModeScript1::ChurchDeskiCal;
	}
	else if (pVarICalUrl)
	{
		m_modeScript1Installed = ModeScript1::iCal;
	}
	else if (pVarGoogleApiKey && pVarGoogleCalId)
	{
		m_modeScript1Installed = ModeScript1::Google;
	}

	// Wenn wir diesen Modus nicht kennen versuchen wir das Programm zu erkennen
	auto const *pProg = m_lstPrograms.Find(AddPrefix(HK1_SKRIPT_1));
	if (m_modeScript1Installed==ModeScript1::Unknown && pProg)
	{
		// Wir haben ein Programm. Untersuche Zeile 1.
		CString strLine1 = pProg->m_strSkriptBeschreibung;
		strLine1.MakeUpper();
		if (strLine1.Find(_T("CHURCHTOOLS"))>=0)
			m_modeScript1Installed = ModeScript1::ChurchToolsAPI;
		if (strLine1.Find(_T("CHURCHDESK"))>=0)
		{
			if (strLine1.Find(_T("API"))>=0)
				m_modeScript1Installed = ModeScript1::ChurchDeskAPI;
			else if (strLine1.Find(_T("ICAL"))>=0)
				m_modeScript1Installed = ModeScript1::ChurchDeskiCal;
		}
		else if (strLine1.Find(_T("ICAL"))>=0)
		{
			m_modeScript1Installed = ModeScript1::iCal;
		}
		else if (strLine1.Find(_T("GOOGLE"))>=0)
		{
			m_modeScript1Installed = ModeScript1::Google;
		}
	}

	// Suche ob alle Programme eine Version haben
	CString strProgs;
	strProgs.Empty();
	// Get a temporary copy, rename the Script1 into the standard name
	auto lstAppScripts = m_lstAppPrograms;
	if (m_modeScript1Installed!=ModeScript1::Unknown)
	{
		auto *pProg = lstAppScripts.Find(RemovePrefix(GetScript1Name()));
		if (pProg)
			pProg->m_strName = HK1_SKRIPT_1;
	}

	for (auto& p : m_lstPrograms)
	{
		// Suche das gleiche Programm 
		bool bProgramIsNewer = p.m_date.m_dt!=0 && p.m_date>m_dateMaxPrograms;
		if (!bProgramIsNewer)
		{
			// Try to find the same programm.
			if (RemovePrefix(p.m_strName).CompareNoCase(HK1_SKRIPT_1)==0)
			{
				auto *pProg = lstAppScripts.Find(RemovePrefix(p.m_strName));
				if (pProg && pProg->m_date.m_dt && pProg->m_date<p.m_date)
				{
					bProgramIsNewer = true;
				}
			}
		}
		if (bProgramIsNewer)
			AppendTextWithDelimiter(strProgs,p.m_strName,_T("\n\t"));
	}
		
	if (!strProgs.IsEmpty())
	{
		// Sollten wir neuere Programme haben, melden wir einen Fehler.
		// Und ignorieren alle Programme. Wir wollen nicht, dass der Benutzer ein älteres Skript installiert.

		CString strError;
		strError.FormatMessage(IDP_NEWER_PROGRAMS, strProgs.GetString());
		AfxMessageBox(strError,MB_ICONWARNING|MB_OK);

		// Keine Programme installieren
		if (!m_bForceUpdate)
			m_bNoProgramUpdate = true;
	}

//---------------------------------------------------------------------------

	// Einige Variablen können neue Namen bekommen haben. Wir benennen diese
	// Variablen um, erhalten aber den Inhalt, und auch die Id ändert sich nicht.
	struct 
	{
		PCTSTR pszOld, pszNew;
	} 
	const aVarsZumUmbenennen[] = 
	{
		_T("HK1-ICS-CD-Churchdesk-ID"),	_T("HK1-CD-OrganisationsId"),
	};

	for (auto const &e : aVarsZumUmbenennen)
	{
		// Wenn es die alte Variable existiert und die neue nicht, benenne die 
		// alte Variable um.
		auto *pVarAlt = m_lstSysVars.Find(AddPrefix(e.pszOld)),
				*pVarNeu = m_lstSysVars.Find(AddPrefix(e.pszNew));
		if (pVarAlt && !pVarNeu)
		{
			// Setze den neuen Namen und setze das Modified-Flag. Dadurch
			// wird die Variable umbenannt.
			pVarAlt->m_strName = AddPrefix(e.pszNew);
			// Wir müssen erzwingen, dass die Variable als modified weiter 
			// behandelt wird, deshalb manipulieren, wir den alten Inhalt.
			pVarAlt->m_bModifiedName = pVarAlt->m_bModified = true;
		}
	}

//-----------------------------------------------------------------------------

	// Nun geht es an die Systemvariablen. Wir übertragen alle benötigten 
	// Systemvariablen, in die Liste, die wir haben. Bei einer Änderung 	
	// der Definition (Datentyp, Beschreibung) wird die Variable neu angelegt
	for (auto const& e : m_lstSysVarsDefault)
	{
		auto strVarName = AddPrefix(e.m_strName);
		auto *pVar = m_lstSysVars.Find(strVarName);
		if (pVar)
		{
			// Wir legen die Variable nur neu an wenn der Datentyp nicht stimmt.
			// DIe Beschreibung wird später bei einem Update korrigiert.
			if (pVar->m_dataType!=e.m_dataType)
			{
				// Neu erzeugen, aber Inhalt erhalten. bNew==true && id!=0
				// Name, Id, Inhalt werden übernommen.
				CDataSystemVariable data { e };
				data.m_strName = strVarName;
				data.m_id = pVar->m_id;
				data.m_strContent = pVar->m_strContent;
				data.m_bNew = true;
				// Replace entry completely
				*pVar = data;
			}
		}
		else
		{
			// Fehlende Variable anlegen
			CDataSystemVariable data { e };
			data.m_strName = strVarName;
			data.m_bNew = true;
			m_lstSysVars.push_back(data);
		}
	}

//-----------------------------------------------------------------------------
	
	// Wir prüfen die Raumvariablen, alle Raumvariablen müssen den 
	// RaumPrefix haben
	std::set<CString> setZuKorrigieren;
	std::set<CString> setFehlen;
	CMapRaumListe mapRaeume;
	LoadRoomMapFromSysVars(mapRaeume);
	for (auto & e : mapRaeume)
	{
		auto &lstRaumListe{ e.second.m_lstRaeume };

		// Alle zugeordneten Räume untersuchen. Alle müssen den Raum-Prefix haben
		for (auto &strRaum : lstRaumListe)
		{
			auto *pVar = m_lstSysVars.Find(strRaum);
			if (!pVar)
			{
				// Raum variable nicht da. Muss angelegt werden. Evtl. wird der Name korrigiert
				CString strNeuerName = AddRoomPrefix(CleanupNameForRoom(RemoveRoomPrefix(strRaum)));
				auto *pVar = m_lstSysVars.Find(strNeuerName);
				// Evtl. exisitiert dieser Name schon, dann nehmen wir ihn.
				if (!pVar)
				{
					CDataSystemVariable data;
					data.InitNeuerRaum(strNeuerName);
					m_lstSysVars.push_back(data);
				}
				setFehlen.emplace(strRaum);
				// Neuen Namen verwenden
				strRaum = strNeuerName;
			}
			else if (strRaum!=AddRoomPrefix(CleanupNameForRoom(RemoveRoomPrefix(strRaum))))
			{
				// Hier stimmt was nicht. Diese Variablen müssen neu aufgebaut werden.
				setZuKorrigieren.emplace(strRaum);
			}
		}
	}

	if (!setFehlen.empty())
	{
		CString strError;
		strError.FormatMessage(IDP_RAUMVAR_NAMEN_FEHLEN,SetToString(setFehlen,_T("\n\t")).GetString());			
		AfxMessageBox(strError);
	}

	if (!setZuKorrigieren.empty())
	{
		CString strError;
		strError.FormatMessage(IDP_RAUMVAR_NAMEN_KORREKTUR,SetToString(setZuKorrigieren,_T("\n\t")).GetString());			
		AfxMessageBox(strError);

		// Wir nehmen jetzt die Räume mit Namen, die keinen korrekten Prefix haben und kopieren diese.
		for (auto &n : setZuKorrigieren)
		{
			// Suche den alten Inhalt und erzeuge eine Kopie
			auto *pVar = m_lstSysVars.Find(n);
			if (!pVar)
				continue;				
			CString strNeuerName = AddRoomPrefix(GenerateNewRoomName(RemoveRoomPrefix(CleanupNameForRoom(n))));			
			// Variable umbennen.
			pVar->m_bModifiedName = true;
			pVar->m_strName = strNeuerName;

			// Nun den alten Namen finden und ersetzen
			for (auto &e : mapRaeume)
			{
				auto &lstRaumListe{ e.second.m_lstRaeume };

				// Alle zugeordneten Räume untersuchen. Alle müssen den Raum-Prefix haben
				for (auto &strRaum : lstRaumListe)
				{
					// Alten Namen bei Bedarf ersetzen.
					if (strRaum==n)						
						strRaum = strNeuerName;
				}
			}
		}
	}

	// Neue Raumvariablen speichern
	if (!setFehlen.empty() || !setZuKorrigieren.empty())
		SaveRoomMapToSysVars(mapRaeume);

	return true;
}

void CHeizkalenderInstallationApp::ClearAll()
{
	m_modeScript1 = m_modeScript1Installed = ModeScript1::Unknown;
	m_lstSysVars.clear();
	m_lstPrograms.clear();
	m_lstDevices.clear();
}

bool CHeizkalenderInstallationApp::IsModeScript1Modified()
{
	return (m_modeScript1Installed!=m_modeScript1);
}

bool CHeizkalenderInstallationApp::IsRaumListeModified()
{
	auto *pVarRaumListe1 = m_lstSysVars.Find(AddPrefix(HK1_RAUMLISTE));
	return pVarRaumListe1 && pVarRaumListe1->m_bModified;
}

bool CHeizkalenderInstallationApp::IsDataModified()
{
	if (IsModeScript1Modified())
		return true;
	if (m_modeScript1Installed!=m_modeScript1)
		return true;
	if (IsProgramsModified())
		return true;
	if (IsSysVarsModified())
		return true;
	return false;
}

bool CHeizkalenderInstallationApp::IsProgramsModified()
{
	for (auto& p : m_lstPrograms)
	{
		if (p.m_bNew || p.m_bModified || p.m_bDeleted)
			return true;
	}
	return false;
}

bool CHeizkalenderInstallationApp::IsSysVarsModified()
{
	for (auto& sv : m_lstSysVars)
	{
		if ((sv.m_bNew || sv.m_bModified || sv.m_bModifiedName || sv.m_bDeleted) && IsSysVarCompatibeWithModeScript1(theApp.RemovePrefix(sv.m_strName),theApp.m_modeScript1))
			return true;
	}
	return false;
}

bool CHeizkalenderInstallationApp::IsSysVarCompatibeWithModeScript1(CString const& strName, ModeScript1 mode)
{
	ModeScript1 modeField = ModeScript1::Unknown;
	if (strName==_T("HK1-CT-Gemeindename") || strName==_T("HK1-CT-Token"))
		modeField  = ModeScript1::ChurchToolsAPI;
	else if (strName==_T("HK1-CD-OrganisationsId") || strName==_T("HK1-CD-Token"))
		modeField  = ModeScript1::ChurchDeskAPI;
	else if (strName==_T("HK1-ICS-Url"))
		modeField  = ModeScript1::iCal;
	else if (strName==_T("HK1-GK-API-Key") || strName==_T("HK1-GK-Kalender-ID"))
		modeField  = ModeScript1::Google;

	if (modeField==ModeScript1::Unknown)
		// Unbekannte Felder sind immer erlaubt
		return true; 

	if (mode==ModeScript1::ChurchDeskAPI || mode==ModeScript1::ChurchDeskiCal)
		// ChurchDesk ist immer ChurchDeskAPI
		mode = ModeScript1::ChurchDeskAPI;

	// Alle anderen Kombintation müssen passen
	return mode==modeField;
}

bool CHeizkalenderInstallationApp::LoadSystemVariablesFromCCU()
{
	CStringA strEnumVars;
	strEnumVars =
		R"x(
!// Ausgabe alle Systemvariablen: Name, Inhalt, Beschreibung, Type, Protokolliert, Sichtbar
string vid;
foreach(vid, dom.GetObject(ID_SYSTEM_VARIABLES).EnumIDs()){
  object sysVar = dom.GetObject(vid);
  WriteLine(vid # "\t" # 
			sysVar.Name() # "\t" # 
            sysVar.Value() # "\t" # 
            sysVar.DPInfo() # "\t" # 
            sysVar.ValueType() # "\t" #  
            sysVar.DPArchive() # "\t" # 
            sysVar.Visible());
}
)x";

	CStringA strOut;
	CScriptEngine engine;
	m_lstSysVars.clear();
	if (engine.ExecuteScript(strEnumVars, strOut))
	{
		m_lstSysVars.LoadFromString(strOut);

		// Nun die Daten protokollieren
		try
		{
			CString strPath;
			GetTempPath2(_MAX_PATH,CStrBuf(strPath,_MAX_PATH));
			::PathAppend(CStrBuf(strPath,_MAX_PATH),m_strAppName);
			strPath += _T("_SysVars.log");

			CStdioFile file(strPath,CFile::modeCreate | CFile::modeWrite | CFile::typeText);
			file.Write(strOut.GetBuffer(), strOut.GetLength());
		}
		catch (CException* e)
		{
			e->ReportError();
			e->Delete();
		}
		return true;
	}
	else
	{
		CString strError;
		strError.FormatMessage(IDS_VERBINDUNGSAUGBAU_FEHLGESCHLAGEN,engine.GetLastErrorText().GetString());
		AfxMessageBox(strError,MB_OK|MB_ICONERROR);
		return false;
	}
}

bool CHeizkalenderInstallationApp::LoadProgramsFromCCU(const CString &strPrefix)
{
	CStringA strEnumProgs = 
R"x(
!// Ausgabe alle Programme: Id, Name, Beschreibung, Aktiv, Script
string vrp="%1%";
string sProgramId;
foreach(sProgramId, dom.GetObject(ID_PROGRAMS).EnumUsedIDs()) {
  object oProgram = dom.GetObject(sProgramId);
  if (oProgram) {
    string sName = oProgram.Name();
    if ((vrp!="") && (!sName.StartsWith(vrp))){
      continue;
    }
    string sDesc = oProgram.PrgInfo().Trim();
    boolean bActive = oProgram.Active();
    string sScript="";
    object oRule = oProgram.Rule();
    if(oRule)
    {
      object oRuleDestination = oRule.RuleDestination();
      if(oRuleDestination)
      {
        integer iDestinationSingleCount = oRuleDestination.DestSingleCount();
        if(iDestinationSingleCount > 0)
        {
          string strEnum;
          foreach(strEnum, system.GenerateEnum(0,(iDestinationSingleCount - 1)))
          {
            object oRuleSingleDestination = oRuleDestination.DestSingleDestination(strEnum);
            if(oRuleSingleDestination)
            {
              integer iDestinationValueType = oRuleSingleDestination.DestinationValueType();
              if(iDestinationValueType == ivtString)
              {
                sScript = oRuleSingleDestination.DestinationValue();
				sScript = sScript.Replace("\r\n", "\n")
								 .Replace("%", "%25")
								 .Replace("\n", "%0A")
								 .Replace("\t", "%09");									 	
              }
            }
          }
        }
      }
    }
    WriteLine(sProgramId # "\t" # sName # "\t" # sDesc # "\t" # bActive # "\t" # sScript );
  }
}
)x";
	strEnumProgs.Replace("%1%", CStringA{ strPrefix });

	CStringA strOut;
	CScriptEngine engine;
	m_lstPrograms.clear();
	if (engine.ExecuteScript(strEnumProgs, strOut))
	{
		m_lstPrograms.LoadFromString(strOut);

		// Nun die Daten protokollieren
		try
		{
			CString strPath;
			GetTempPath2(_MAX_PATH,CStrBuf(strPath,_MAX_PATH));
			::PathAppend(CStrBuf(strPath,_MAX_PATH),m_strAppName);
			strPath += _T("_Programs.log");

			CStdioFile file(strPath,CFile::modeCreate | CFile::modeWrite | CFile::typeText);
			file.Write(strOut.GetBuffer(), strOut.GetLength());
		}
		catch (CException* e)
		{
			e->ReportError();
			e->Delete();
		}
		return true;
	}
	else
	{
		AfxMessageBox(engine.GetLastErrorText(),MB_OK|MB_ICONERROR);
		return false;
	}
}

bool CHeizkalenderInstallationApp::LoadDevicesFromCCU()
{
	// Achtung die Liste der devices kann doppelte Einträge enthalten!!!!
	// Das liegt daran, dass mehere Datenpunkte einen Treffer erzeugen können.
	CStringA strEnumDevices = 
		R"x(
!//  ChannelType ictHSS 17, ictHSSBinaryActuator 3, ictBinaryActuator 26
!// Ausgabe: DevName, Gerätetyp, Channelname, ChannelType, DataPoint, Operation
string datapoint;
foreach (datapoint, dom.GetObject(ID_DATAPOINTS).EnumUsedNames())
{
  !// Wir suchen nur die Schlüsselworte SET_POINT_TEMPERATURE, SET_TEMPERATURE, SETPOINT, STATE, TEMPERATURE
  if (datapoint.EndsWith(".SET_POINT_TEMPERATURE") ||
      datapoint.EndsWith(".SET_TEMPERATURE") ||
      datapoint.EndsWith(".SETPOINT") ||
	  datapoint.EndsWith(".ACTUAL_TEMPERATURE") ||
      datapoint.EndsWith(".TEMPERATURE") ||
      datapoint.EndsWith(".STATE")) {
    ! WriteLine(datapoint);
    var dp = dom.GetObject(datapoint);
    var ch = dom.GetObject(dp.Channel());
    var dv = dom.GetObject(ch.Device());
    if ((ch.ChannelType()==ictHSS) || (ch.ChannelType()==ictHSSBinaryActuator) || (ch.ChannelType()==ictBinaryActuator) || (ch.ChannelType()==ictWeatherStation))
    {
      WriteLine(dv.Name() # "\t" # dv.Label() # "\t" # ch.Name() # "\t" # ch.ChannelType() # "\t" # datapoint # "\t" # dp.Operations());
    }
  }
}
)x";

	CStringA strOut;
	CScriptEngine engine;
	m_lstDevices.clear();
	if (engine.ExecuteScript(strEnumDevices, strOut))
	{
		m_lstDevices.LoadFromString(strOut);

		// Nun die Daten protokollieren
		try
		{
			CString strPath;
			GetTempPath2(_MAX_PATH,CStrBuf(strPath,_MAX_PATH));
			::PathAppend(CStrBuf(strPath,_MAX_PATH),m_strAppName);
			strPath += _T("_Devices.log");

			CStdioFile file(strPath,CFile::modeCreate | CFile::modeWrite | CFile::typeText);
			file.Write(strOut.GetBuffer(), strOut.GetLength());
		}
		catch (CException* e)
		{
			e->ReportError();
			e->Delete();
		}
		return true;
	}
	else
	{
		AfxMessageBox(engine.GetLastErrorText(),MB_OK|MB_ICONERROR);
		return false;
	}
	return false;
}


double CHeizkalenderInstallationApp::GetGrundTemperatur()
{
	auto *pVar = m_lstSysVars.Find(AddPrefix(HK2_GRUNDTEMP));
	if (!pVar)
		return 16.0;
	return StringToDouble(pVar->m_strContent);
}

bool CHeizkalenderInstallationApp::SaveRoomMapToSysVars(CMapRaumListe const& mapRaeume)
{
	auto *pVarRaumListe1 = m_lstSysVars.Find(AddPrefix(HK1_RAUMLISTE));
	auto *pVarRaumListe2 = m_lstSysVars.Find(AddPrefix(HK2_RAUMLISTE));
	ASSERT(pVarRaumListe1 && pVarRaumListe2);

	// Um den Rythmus der Trennze3ichen zu erhalten benutzen wir nicht AppendTextWithDelimiter, sondern bauen die 
	// Liste direkt auf und enfernen am Ende das Semikolon
	CString strListe1, strListe2;
	for (auto const &e : mapRaeume)
	{ 
		// Raum Ids mit Raumnamen aufbauen
		strListe1 += e.first;
		if (!e.second.m_strResourceName.IsEmpty())
			strListe1 += _T('=') + e.second.m_strResourceName;
		strListe1 += _T(';');

		// Weitere Raumliste aufbauen
		auto const &lst = e.second.m_lstRaeume;
		CString strRaeume{ ListToString(lst,_T("+"),false) };
		strListe2 += strRaeume+_T(';');
	}
	// Überflüssige Semikolons entfernen
	strListe1.TrimRight(_T(';'));
	strListe2.TrimRight(_T(';'));

	pVarRaumListe1->SetContent(strListe1);
	pVarRaumListe2->SetContent(strListe2);		

	auto CreateSetFromList = [](CString strList)
		{
			// Set aufbauen
			std::multiset<CString> setRes;
			for (auto str : SplitString(strList, _T(';')))
				setRes.emplace(str);
			return setRes;
		};

	// Die Liste 1+2 ändert sich eigentlich nicht. Aber, da wir einen Set benutzen kann sich die Reihenfolge ändern. 
	// Deshalb bilden wir aus altem Inhalt einen set nd aus dem neuen Inhalt und alten Inhalt. 
	// Ist der identisch dann löschen iwr das Modified flag. 
	if (pVarRaumListe1->m_bModified)
		pVarRaumListe1->m_bModified = CreateSetFromList(pVarRaumListe1->m_strContent)!=CreateSetFromList(pVarRaumListe1->m_strContentOld);
	if (pVarRaumListe2->m_bModified)
		pVarRaumListe2->m_bModified = CreateSetFromList(pVarRaumListe2->m_strContent)!=CreateSetFromList(pVarRaumListe2->m_strContentOld);
	return pVarRaumListe1->m_bModified || pVarRaumListe2->m_bModified;
}

CString CHeizkalenderInstallationApp::GenerateNewRoomName(CString strTemplate)
{
	strTemplate = CleanupNameForRoom(strTemplate);
	CString strRaumName{ strTemplate };
	for (int i=0; m_lstSysVars.Find(AddRoomPrefix(strRaumName)); ++i)
		strRaumName = strTemplate + _T("_") + IntToString(i);
	return strRaumName;
}

void CHeizkalenderInstallationApp::LoadRoomMapFromSysVars(CMapRaumListe &mapRaeume)
{
	auto *pVarRaumListe1 = m_lstSysVars.Find(AddPrefix(HK1_RAUMLISTE));
	auto *pVarRaumListe2 = m_lstSysVars.Find(AddPrefix(HK2_RAUMLISTE));
	ASSERT(pVarRaumListe1 && pVarRaumListe2);
	CString strListe1 { pVarRaumListe1->m_strContent };
	CString strListe2 { pVarRaumListe2->m_strContent };

	mapRaeume.clear();
	int i=0;
	for (auto strId : SplitString(strListe1,_T(';')))
	{
		CString strRaumName = StrValueByIndex(strId,1,_T('='));
		strId = StrValueByIndex(strId,0,_T('='));
		auto &e = mapRaeume[strId];
		e.m_strResourceName = strRaumName;

		auto strRaeume{ StrValueByIndex(strListe2, i ,_T(';')) };
		auto &lst = e.m_lstRaeume;
		for (auto strRaum : SplitString(strRaeume,_T('+')))
			lst.push_back(strRaum);
		++i;
	}
}

CString CHeizkalenderInstallationApp::RemovePrefix(CString const str) const
{
	if (str.Left(m_strPrefix.GetLength())==m_strPrefix)
		return str.Mid(m_strPrefix.GetLength());
	else
		return str;
}

CString CHeizkalenderInstallationApp::AddPrefix(CString const& str) const
{
	return m_strPrefix+str;
}

bool CHeizkalenderInstallationApp::IsMatchingSysVar(CString const& str) const
{
	return IsMatchingPrefix(str) && RemovePrefix(str).Left(2)==_T("HK");
}

bool CHeizkalenderInstallationApp::IsMatchingPrefix(CString const& str) const
{
	return m_strPrefix.IsEmpty() || str.Left(m_strPrefix.GetLength())==m_strPrefix;
}

CString CHeizkalenderInstallationApp::AddRoomPrefix(CString const& str) const
{
	return AddPrefix(HKG_RAUM_PREFIX+str);
}

CString CHeizkalenderInstallationApp::RemoveRoomPrefix(CString str) const
{
	str = RemovePrefix(str);
	CString strPrefix{ HKG_RAUM_PREFIX };
	if (str.Left(strPrefix.GetLength())==strPrefix)
		return str.Mid(strPrefix.GetLength());
	else
		return str;
}

bool CHeizkalenderInstallationApp::IsMatchingRoomPrefix(CString str) const
{
	if (!IsMatchingPrefix(str))
		return false;
	str = RemovePrefix(str);
	CString strPrefix{ HKG_RAUM_PREFIX };
	return str.Left(strPrefix.GetLength())==strPrefix;
}

void CHeizkalenderInstallationApp::ReadResources()
{
	auto* pVarRaumListe1 = m_lstSysVars.Find(AddPrefix(HK1_RAUMLISTE));
	auto* pVarRaumListe2 = m_lstSysVars.Find(AddPrefix(HK2_RAUMLISTE));
	ASSERT(pVarRaumListe1 && pVarRaumListe2);
	CString strListe1{ pVarRaumListe1->m_strContent };
	CString strListe2{ pVarRaumListe2->m_strContent };

	// Warnung anzeigen
	if (!pVarRaumListe1->m_strContent.IsEmpty() || !pVarRaumListe2->m_strContent.IsEmpty())
	{
		if (AfxMessageBox(IDP_QUERY_RAUMLISTEN_NICHT_LEER, MB_ICONQUESTION|MB_DEFBUTTON2|MB_YESNO)!=IDYES)
			return;
	}

	CMapRaumListe mapRaeumeNeu;
	if (m_modeScript1==ModeScript1::ChurchToolsAPI)
	{
		if (!ReadResourcesChurchTool(mapRaeumeNeu))
			return;
	}
	else if (m_modeScript1==ModeScript1::ChurchDeskAPI || m_modeScript1==ModeScript1::ChurchDeskiCal)
	{
		if (!ReadResourcesChurchDesk(mapRaeumeNeu))
			return;
	}
	else if (m_modeScript1==ModeScript1::iCal || m_modeScript1==ModeScript1::Google)
	{
		// Eigentlich ist gemäß des Syntaxes nichts zu tun, da es keine Raumressourcen gibt, die wir lesen können.
		LoadRoomMapFromSysVars(mapRaeumeNeu);
	}
	else
	{
		ASSERT(FALSE);
		return;
	}

	CMapRaumListe mapRaeumeAlt;
	LoadRoomMapFromSysVars(mapRaeumeAlt);

	// Nun übernehmen wir die bisherigen zugeordneten Raumvairiablen Namen
	for (auto const& e : mapRaeumeAlt)
	{
		// Suche den Raum in der alten Raumliste
		auto it = mapRaeumeNeu.find(e.first);
		// Die Resource mag, da sein, aber evtl. ist die Raumliste einfach nur leer
		if (it!=mapRaeumeNeu.end() && !e.second.m_lstRaeume.empty())
		{
			// Wir kennen die Raumvariable und übernehmen sie, aber wir ergänzen evtl. den 
			// Ressourcennamen, wenn er in den neuen Daten drin steckt.
			CString strResName{ it->second.m_strResourceName };
			it->second = e.second;
			if (it->second.m_strResourceName.IsEmpty())
				it->second.m_strResourceName = strResName;			
		}
	}

	// Jetzt müssen wir schauen, ob es neue Raumnamen gibt, für die es 
	// noch keine Raumvariable gibt.
	for (auto const& e : mapRaeumeNeu)
	{
		auto &lst = e.second.m_lstRaeume;
		for (auto& strRaum : lst)
		{
			auto* pVar = m_lstSysVars.Find(strRaum);
			if (!pVar)
			{
				// Neuen Raum erzeugen.
				CDataSystemVariable data{};
				data.InitNeuerRaum(strRaum);
				m_lstSysVars.push_back(data);
			}
		}
	}

	// Jetzt bauen wir die neue Raumvariable zusammen.
	if (SaveRoomMapToSysVars(mapRaeumeNeu))
		AfxMessageBox(IDP_RAUMLISTE_WURDE_AKTUALISIERT);
	else
		AfxMessageBox(IDP_RAUMLISTE_WURDE_NICHT_AKTUALISIERT);
}

bool CHeizkalenderInstallationApp::ReadResourcesChurchTool(CMapRaumListe &mapRaeume)
{
	bool bReadAllResources = false;
	switch (AfxMessageBox(IDP_QUERY_ALLE_RESSOURCEN_LESEN, MB_ICONQUESTION|MB_DEFBUTTON2|MB_YESNOCANCEL))
	{
	case IDYES:
		bReadAllResources = true;
		break;
	case IDNO:
		bReadAllResources = false;
		break;
	default:
		return false;
	}
	mapRaeume.clear();

	// Gemeinde bestimmen
	auto *pVarGemeinde = m_lstSysVars.Find(AddPrefix(_T("HK1-CT-Gemeindename")));

	// Token bestimmen	
	auto *pVarToken = m_lstSysVars.Find(AddPrefix(_T("HK1-CT-Token")));
	ASSERT(pVarToken);
	
	// Resource Daten von Churchtools lesen
	CWGetEngine engine;
	CString strURL = _T("https://") + pVarGemeinde->m_strContent +_T(".church.tools/api/resource/masterdata?login_token=") + pVarToken->m_strContent;
	CString strResult;

	// Prüfen 
	CString strToken(_T("{\"data\":{\"resourceTypes\":["));
	if (!engine.Get(strURL, strResult) || strResult.Left(strToken.GetAllocLength())!=strToken)
	{
		CString strError;
		strError.FormatMessage(IDP_LESEN_VON_CHURCHTOOLS_FEHLGESCHLAGEN,engine.GetLastErrorText().GetString());
		AfxMessageBox(strError,MB_OK|MB_ICONERROR);
		return false;
	}

	// Umlaute aus ISO-8859-1 tauschen, dazu sind nur die letzten 2 Bytes nötig
	//	strResult.Replace(_T("\\u00e4"),_T("ä"));
	//	strResult.Replace(_T("\\u00c4"),_T("Ä"));
	//	strResult.Replace(_T("\\u00f6"),_T("ö"));
	//	strResult.Replace(_T("\\u00d6"),_T("Ö"));
	//	strResult.Replace(_T("\\u00fc"),_T("ü"));
	//	strResult.Replace(_T("\\u00dc"),_T("Ü"));
	//	strResult.Replace(_T("\\u00df"),_T("ß"));
	auto IsHex = [](TCHAR c)
		{
			return (c>=_T('0') && c<=_T('9')) || ((c>=_T('a') && c<=_T('f')) || (c>=_T('A') && c<=_T('F')));
		};
	auto ToHex = [](TCHAR c)
		{
			return (c>=_T('0') && c<=_T('9')) ? c-_T('0') :
				   (c>=_T('a') && c<=_T('f')) ? c-_T('a')+10 : c-_T('A')+10;
		};
	for (int iPos = strResult.Find(_T("\\u00")); iPos>=0; iPos=strResult.Find(_T("\\u00"), iPos+1))
	{
		if (iPos+5<strResult.GetLength())
		{
			if (IsHex(strResult[iPos+4]) && IsHex(strResult[iPos+5]))
			{
				// Zeichen aus Hex kodieren und ersetzen
				TCHAR c = static_cast<TCHAR>((ToHex(strResult[iPos+4])<<4) | ToHex(strResult[iPos+5]));
				strResult = strResult.Mid(0,iPos) + c + strResult.Mid(iPos+6); 
			}
		}
	}

	// Erst müssen wir die Ressource Typ Id für Räume finden!
	int iPosRes = strResult.Find(_T("\"resources\":["));
	std::set<int> setResTypeIds;
	if (iPosRes>=0) 
	{
		// Ausschneiden
		CString strRessourceTypes{ strResult.Mid(26,iPosRes-26) };
		strRessourceTypes.Replace(_T("Person\":{\"id\":"),_T(""));

		strRessourceTypes.Replace(_T("{\"id\":"),_T("\t"));
		strRessourceTypes.Trim(_T("\t"));

		for (auto strResType : SplitString(strRessourceTypes))
		{
			int iPos = strResType.Find(_T("\"name\":\""));
			if (iPos>=0)
			{
				int iPos2 = strResType.Find(_T("\""),iPos+8);
				if (iPos2>=0){
					CString strName = strResType.Mid(iPos+8,iPos2-iPos-8);
					strName.MakeUpper();
					if (bReadAllResources || strName.Find(_T("RAUM"))>=0 || strName.Find(_T("RÄUME"))>=0)
						setResTypeIds.emplace(StringToInt(strResType));
				}
			}
		}
	}

	if (!setResTypeIds.empty())
	{
		// Jetzt suchen wir die Räume und deren Ids
		CString strResources { strResult.Mid(iPosRes+13) };

		// Vernichte die id's die wir nicht wollen
		strResources.Replace(_T("Person\":{\"id\":"),_T(""));
		strResources.Replace(_T("{\"id\":"),_T("\t"));
		strResources.Trim(_T("\t"));

		for (CString strRes : SplitString(strResources))
		{
			// Suche die resId und prüfe ob es passt
			int iPos = strRes.Find(_T("\"resourceTypeId\":"));
			if (setResTypeIds.find(StringToInt(strRes.Mid(iPos+17, 10)))==setResTypeIds.end())
				// Resource passt nicht (kein Raum)
				continue;

			// Id holen
			int resId = StringToInt(strRes);
			if (resId<=0)
			{
				// Fehler
				continue;
			}
			// Namen suchen
			iPos = strRes.Find(_T(",\"name\":\""));
			if (iPos<0){
				// Fehler
				continue;
			}

			// Namen finden
			strRes = strRes.Mid(iPos+9);
			int iPosEnd = strRes.Find(_T("\",\""));
			if (iPos<0){
				// Fehler
				continue;
			}
			CString strName{ strRes.Mid(0,iPosEnd) };

			// In die Map Eintragen
			auto &e = mapRaeume[IntToString(resId)];
			e.m_strResourceName = CleanupNameForRoom(strName);
			CString strVarName { AddRoomPrefix(e.m_strResourceName) };
			e.m_lstRaeume.push_back(strVarName);
		}
	}
	return true;
}

bool CHeizkalenderInstallationApp::ReadResourcesChurchDesk(CMapRaumListe &mapRaeume)
{
	mapRaeume.clear();

	// Token bestimmen
	auto *pVarOrgaId = m_lstSysVars.Find(AddPrefix(_T("HK1-CD-OrganisationsId")));
	ASSERT(pVarOrgaId);
	auto *pVarApiKey = m_lstSysVars.Find(AddPrefix(_T("HK1-CD-Token")));
	ASSERT(pVarApiKey);

	// Resource Daten von Churchtools lesen
	CWGetEngine engine;
	CString strURL = 
		_T("https://api2.churchdesk.com/api/v3.0.0/events/resources?partnerToken=") +
		pVarApiKey->m_strContent + _T("&organizationId=") + 
		pVarOrgaId->m_strContent;
	CString strResult;

	// Prüfen 
	if (!engine.Get(strURL, strResult, true) || strResult.Left(1)!=_T("["))
	{
		CString strError;
		strError.FormatMessage(IDP_LESEN_VON_CHURCHDESK_FEHLGESCHLAGEN,engine.GetLastErrorText().GetString());
		AfxMessageBox(strError,MB_OK|MB_ICONERROR);
		return false;
	}

	CString strResources { strResult };
	strResources.Replace(_T("{\"id\":"),_T("\t"));
	for (auto strRes : SplitString(strResources))
	{
		// Bei Color 0 ist das der Gemeinde-Eintrag, den überspringen wir.
		int iPos = strRes.Find(_T("\"color\":"));
		if (iPos<0 || StringToInt(strRes.Mid(iPos+8,10))==0){
			// Den Gemeinde-Eintrag kann man beim buchen nicht benutzen.
			// Einen anderen Indikator als die Farbe habe ich nicht gefunden.
			continue;
		}
		
		// OK gültiger Eintrag, Ressource Id laden
		int resId = StringToInt(strRes);

		// Namen suchen
		iPos = strRes.Find(_T(",\"name\":\""));
		if (iPos<0)
			continue;
		int iPosEnd = strRes.Find(_T("\",\""),iPos);
		if (iPosEnd<0)
			continue;
		CString strName = strRes.Mid(iPos+9,iPosEnd-iPos-9);

		// In die Map eintragen
		auto &e = mapRaeume[IntToString(resId)];
		e.m_strResourceName = CleanupNameForRoom(strName);
		CString strVarName { AddRoomPrefix(e.m_strResourceName) };
		e.m_lstRaeume.push_back(strVarName);
	}

	return true;
}

static CStringA CreateUpdateScriptForProgram(int id, CStringA& strScript)
{
	CStringA strUpdateProgram = R"x(
object oProgram = dom.GetObject(%1%);
if (oProgram && oProgram.Type()==OT_PROGRAM) {
  string sName = oProgram.Name();
  object oRule = oProgram.Rule();
  if(oRule)
  {
    object oRuleDestination = oRule.RuleDestination();
    if(oRuleDestination)
    {
      integer iDestinationSingleCount = oRuleDestination.DestSingleCount();
      if(iDestinationSingleCount > 0)
      {
        string strEnum;
        foreach(strEnum, system.GenerateEnum(0,(iDestinationSingleCount - 1)))
        {
          object oRuleSingleDestination = oRuleDestination.DestSingleDestination(strEnum);
          if(oRuleSingleDestination)
          {
            integer iDestinationValueType = oRuleSingleDestination.DestinationValueType();
            if(iDestinationValueType == ivtString)
            {
              oRuleSingleDestination.DestinationValue("%2%");
			  WriteLine("Update script for program " # %1% # " " # sName);
            }
          }
        }
      }
    }
  }
}
)x";
	strUpdateProgram.Replace("%1%", CStringA{IntToString(id)});
	strUpdateProgram.Replace("%2%", strScript);
	return strUpdateProgram;
}

CString CHeizkalenderInstallationApp::GetNameFromScrip1Mode(ModeScript1 mode)
{
	// Bestimme den Scriptnamen, den wir brauchen.
	switch (mode) 
	{
	case ModeScript1::ChurchDeskAPI:
		return _T("ChurchDeskAPI");
		break;
	case ModeScript1::ChurchDeskiCal:
		return _T("ChurchDeskiCal");
		break;
	case ModeScript1::ChurchToolsAPI:
		return _T("ChurchTools");
		break;
	case ModeScript1::iCal:
		return _T("iCal");
		break;
	case ModeScript1::Google:
		return _T("Google");
		break;
	case ModeScript1::Unknown:
		return _T("Unknown");
		break;
	default:
		ASSERT(FALSE);
		return _T("");
		break;
	}
}

void CHeizkalenderInstallationApp::UpdatePrograms()
{
	// Keine Updates für Programme und kein Force gesetzt?
	if (m_bNoProgramUpdate && !m_bForceUpdate)
		return;

	// Wir laufen über alle Hauptprogramme und bestimmen was wir machen müssen-
	// 1. Update, wenn Line1 und Datum gesetzt ist, und Datum neuer ist
	//    m_bModified = true, Id!=0
	// 2. Insert, wenn Eintrag fehlt (id=0)
	//    m_bNew = true, Id==0
	// 3. Delete, wenn Id gesetzt ist, aber Update nicht erkannt wird (Line1 oder Datum fehlen)
	//	  m_bNew = true, Id!=0
	CString strScript1Prefix{HK1_SKRIPT_1},
			strScript1Name;
	strScript1Name += strScript1Prefix + _T("_") + GetNameFromScrip1Mode(m_modeScript1Installed);
	
	for (auto& pApp : m_lstAppPrograms)
	{
		// Speziell ist es wenn wir ein Skript 1 haben.
		bool bIsScript1 = false;
		if (pApp.m_strName.Left(strScript1Prefix.GetLength())==strScript1Prefix)
		{
			if (pApp.m_strName!=strScript1Name)
				// Skript passt nicht
				continue;
			bIsScript1 = true;
		}

		// Wir suchen das passende Programm
		auto *pInst = m_lstPrograms.Find(AddPrefix(bIsScript1 ? strScript1Prefix : pApp.m_strName));
		ASSERT(!pApp.m_bNew && !pApp.m_bModified && !pApp.m_bDeleted);
		if (pInst && !pInst->m_strSkriptBeschreibung.IsEmpty() && IsDateValid(pInst->m_date))
		{
			// Fall 1: Wir können die Version komplett bestimmen. Nun zählt das Datum
			// Oder wir haben Skript 1 und der Modus wurde getauscht.
			pInst->m_pAppProg = &pApp;
			if (pInst->m_date<pApp.m_date || m_bForceUpdate)
			{
				// Update Skript
				pInst->m_bModified = true;
				pInst->m_strSkript = pApp.m_strSkript;
			}
		}
		else
		{
			// Neuen Eintrag als Kopie vorbereiten
			auto dataProg = pApp;
			ASSERT(dataProg.m_id==0);
			dataProg.m_strName = AddPrefix(bIsScript1 ? strScript1Prefix : dataProg.m_strName);
			dataProg.m_bNew = true;
			dataProg.m_pAppProg = &pApp;

			// Haben wir überhaupt was gefunden? Wenn ja stimmte das Datum nicht, oder Zeile 1 war leer
			if (!pInst)
			{
				// Fall 2:  Wir fügen den neuen Eintrag hinzu
				ASSERT(dataProg.m_id==0);
				m_lstPrograms.push_back(dataProg);
			}
			else
			{
				// Fall 3: Irgendwas stimmt nicht mit dem installierten Programm. 
				// Wir ersetzen es, erhalten aber die Id, die wir ersetzen müssen.
				dataProg.m_id = pInst->m_id;
				ASSERT(dataProg.m_id!=0);
				dataProg.m_date = pInst->m_date;
				*pInst = dataProg;
			}
		}
	}

	// Jetzt laufen wir noch über alle Nebenprogramme und bestimmen was wir machen müssen-
	// 1. Update, wenn Line1 und Datum gesetzt ist, und Datum neuer ist
	//    m_bModified = true, Id!=0
	// 2. In allen anderen Fällen (Fehlen, oder es stimmt was nicht) ignorieren wir 
	//    das Programm
	for (auto& pApp : m_lstAppTools)
	{
		// Wir suchen das passende Programm
		auto *pInst = m_lstPrograms.Find(AddPrefix(pApp.m_strName));
		ASSERT(!pApp.m_bNew && !pApp.m_bModified && !pApp.m_bDeleted);
		if (pInst && !pInst->m_strSkriptBeschreibung.IsEmpty() && IsDateValid(pInst->m_date))
		{
			// Fall 1: Wir können die Version komplett bestimmen. Nun zählt das Datum
			// und wir können updaten
			pInst->m_pAppProg = &pApp;
			if (pInst->m_date<pApp.m_date || m_bForceUpdate)
			{
				// Update Skript
				pInst->m_bModified = true;
				pInst->m_strSkript = pApp.m_strSkript;
			}
		}
		else
		{
			// Das Tool ist nicht installiert oder fehlerhaft.
			// Letzten Endes ignorieren wir es... 
			// Der nachfolgende Code ist nur für die Vollständigkeit...
			auto dataProg = pApp;
			ASSERT(dataProg.m_id==0);
			dataProg.m_strName = AddPrefix(dataProg.m_strName);
			dataProg.m_bNew = true;
			dataProg.m_pAppProg = &pApp;

			// Haben wir überhaupt was gefunden? Wenn ja stimmte das Datum nicht, oder Zeile 1 war leer
			if (!pInst)
			{
				// Fall 2:  Neu
				//	Also ignorieren wir es!
			}
			else
			{
				// Fall 3: Irgendwas stimmt nicht mit dem installierten Programm. 
				//	Also ignorieren wir es!
			}
		}
	}
}

void CHeizkalenderInstallationApp::FixScript1AfterModeChange()
{
	// Wir müssen evtl. noch das Skript 1 ändern oder himnzufügen
	if (IsModeScript1Modified() && m_modeScript1!=ModeScript1::Unknown)
	{
		// Welches Skript benötigen wir
		CString strScript1Prefix{HK1_SKRIPT_1},
			strScript1Name{HK1_SKRIPT_1};

		// Bestimme den Scriptnamen, den wir brauchen.
		strScript1Name += _T("_") + GetNameFromScrip1Mode(m_modeScript1);

		auto *pApp = m_lstAppPrograms.Find(strScript1Name);
		ASSERT(pApp);
		auto *pInst = m_lstPrograms.Find(AddPrefix(strScript1Prefix));
		if (pInst)
		{
			// Update Skript
			pInst->m_bModified = true;
			pInst->m_strSkript = pApp->m_strSkript;
			pInst->m_pAppProg = pApp;
		}
		else
		{
			// Neuen Eintrag als Kopie vorbereiten
			auto dataProg = *pApp;
			ASSERT(dataProg.m_id==0);
			dataProg.m_strName = AddPrefix(strScript1Prefix);
			dataProg.m_bNew = true;
			dataProg.m_pAppProg = pApp;
			ASSERT(!dataProg.m_bModified);
			m_lstPrograms.push_back(dataProg);
		}
	}
}

void CHeizkalenderInstallationApp::UpdateSimulation()
{
	// Vor dem Update müssen wir das Skript 1 setzen
	FixScript1AfterModeChange();

	CRegKey regKey{ GetSectionKey(_T("Simulation")) };

	// Speichern der entsprechenden Abschnitt für SysVars
	CRegKey regKeyVars;
	regKey.DeleteSubKey(_T("SystemVariablen"));
	if (regKeyVars.Create(regKey,_T("SystemVariablen"))==ERROR_SUCCESS)
	{
		// Variablen speichern. Wir holen eine Kopie
		int i = 1;
		for (auto e: m_lstSysVars)
		{
			e.m_id = i++;
			CString strData{ e.GetDataAsLine() };
			strData.Replace(_T("\t"),_T("\\t"));
			regKeyVars.SetStringValue(e.m_strName, strData);
		}
	}

	// Lade den entsprechenden Abschnitt für Programme
	CRegKey regKeyProgs;
	regKey.DeleteSubKey(_T("Programme"));
	if (regKeyProgs.Create(regKey,_T("Programme"))==ERROR_SUCCESS)
	{
		// Variablen speichern. Wir holen eine Kopie
		int i = 1;
		for (auto p: m_lstPrograms)
		{
			p.m_id = i++;
			CString strData{ p.GetDataAsLine() };
			strData.Replace(_T("\t"),_T("\\t"));
			regKeyProgs.SetStringValue(p.m_strName, strData);
		}
	}

	// Merker setzen für Simulation
	WriteProfileInt(_T("Simulation"), _T("Simulation"), TRUE);
}

void CHeizkalenderInstallationApp::UpdateCCU()
{
	// Vor dem Update müssen wir das Skript 1 setzen
	FixScript1AfterModeChange();

	// Baue ein Skript auf, dass nmun die Programmänderungen übernimmt.
	CStringA strScriptForUpdate;

	// Laufe über alle Programme.
	if (!m_bNoProgramUpdate || m_bForceUpdate)
	{
		for (auto& p : m_lstPrograms)
		{
			auto strScript = p.m_strSkript;
			if (!m_strPrefix.IsEmpty())
				// Achtung! Manche Skripte wie das Sichern des Systemprotokolls haben keinen vrp Eintrag!
				strScript.Replace("string vrp=\"\";", "string vrp=\"" + CStringA{ m_strPrefix } + "\";");
			strScript.Replace("\\", "\\\\");	// Backslash 
			strScript.Replace("\r\n", "\n");	// Unix newline
			strScript.Replace("\n", "\\n");		// Newline
			strScript.Replace("\t", "\\t");		// Tab
			strScript.Replace("\"", "\\\"");	// Doublequote
			strScript.Replace("\'", "\\\'");	// Singlequote
			if (p.m_bNew)
			{
				// Es kann sein, dass wir den alten Eintrag löschen müssen
				ASSERT(p.m_id==0);
				// Wir brauchen jetzt ein kom,plettes Script um ein Programm anzulegen.
				auto strProgName = _T("Create_") + RemovePrefix(p.m_strName);
				strProgName.Replace(_T(" "), _T("_"));

				// Baue den Namen für die Ressource auf.
				CStringA strUpdateTemplate;
				if (!LoadStringFromResource(strUpdateTemplate, strProgName, _T("SCRIPT"), true))
				{
					ASSERT(FALSE);
					continue;
				}

				// Zu ändernde Daten einfügen.
				CStringA strUpdate = strUpdateTemplate;
				strUpdate.Replace("%1%", CStringA{ IntToString(p.m_id) });
				strUpdate.Replace("%2%", CStringA{ m_strPrefix });
				strUpdate.Replace("%3%", strScript);
				strScriptForUpdate += strUpdate;
				strScriptForUpdate += "\n!//##########################################################\n";
			}
			else if (p.m_bModified)
			{
				ASSERT(p.m_id!=0);
				CStringA strUpdate;
				strUpdate = CreateUpdateScriptForProgram(p.m_id, strScript);
				strScriptForUpdate += strUpdate;
				strScriptForUpdate += "\n!//##########################################################\n";
			}
		}
	}

	// Nun geht es an die Systemvarablen, wir suchen alle Ids, die einen recreate brauchen oder gelöscht werden müssen
	CString strSVids;
	for (auto & e : m_lstSysVars)
	{
		// Variablen, die nicht zum Modus passen löschen wir.
		if (IsMatchingPrefix(e.m_strName) && !IsSysVarCompatibeWithModeScript1(RemovePrefix(e.m_strName),m_modeScript1))
			e.m_bDeleted = true;

		if ((e.m_bNew || e.m_bDeleted) && e.m_id)
			AppendTextWithDelimiter(strSVids,IntToString(e.m_id),_T("\t"));
	}

	// Delete Varoables
	if (!strSVids.IsEmpty())
	{
		CStringA strUpdateVar = R"x(
string sIds = "%1%";
object oSV;
string sId;
foreach(sId,sIds) {
	oSV = dom.GetObject (ID_SYSTEM_VARIABLES).Get(sId);
	if (oSV) {
		dom.DeleteObject(sId);
	}
}
)x";
		strUpdateVar.Replace("%1%", CStringA{ strSVids });
		// An die Liste aller Statements anfügen
		strScriptForUpdate += strUpdateVar;
	}

	// Skript zum Anlegen aller normalen Variablen ablaufen lasse, wenn es was zu tun gibt
	// Dieses Skript legt nur an, ändert aber nichts.
	bool bAnyNew = false;
	for (auto& e : m_lstSysVars)
	{
		if (e.m_bNew && IsSysVarCompatibeWithModeScript1(RemovePrefix(e.m_strName),m_modeScript1))
		{
			bAnyNew = true;
			break;
		}
	}
	if (bAnyNew)
	{
		CStringA strUpdateTemplate;
		if (LoadStringFromResource(strUpdateTemplate, _T("SYSVARS-Init"), _T("SCRIPT"), true))
		{
			// Zu ändernde Daten einfügen.
			CStringA strUpdate = strUpdateTemplate;
			strUpdate.Replace("%1%", CStringA{ m_strPrefix });

			strScriptForUpdate += strUpdate;
			strScriptForUpdate += "\n!//##########################################################\n";
		}
		else
		{
			ASSERT(FALSE);
		}
	}

	// Lade Skript für Variablen des Modus für Skript 1
	CString strName;
	if (m_modeScript1==ModeScript1::ChurchToolsAPI)
		strName = _T("ChurchTools");
	else if (m_modeScript1==ModeScript1::ChurchDeskAPI || m_modeScript1==ModeScript1::ChurchDeskiCal)
		strName = _T("ChurchDesk");
	else if (m_modeScript1==ModeScript1::iCal)
		strName = _T("iCal");
	else if (m_modeScript1==ModeScript1::Google)
		strName = _T("Google");

	// Skript zum anlegen aller normalen Variablen ablaufen lassen.
	if (!strName.IsEmpty() && bAnyNew)
	{
		CStringA strUpdateTemplate;
		if (LoadStringFromResource(strUpdateTemplate, _T("SYSVARS-Init-")+strName, _T("SCRIPT"), true))
		{
			// Zu ändernde Daten einfügen.
			CStringA strUpdate = strUpdateTemplate;
			strUpdate.Replace("%1%", CStringA{ m_strPrefix });

			strScriptForUpdate += strUpdate;
			strScriptForUpdate += "\n!//##########################################################\n";
		}
		else
		{
			ASSERT(FALSE);
		}
	}

	// Jetzt bauen wir das Script auf, um die nicht benutzen Systemvariablen zu löschen
	for (auto const& e : m_lstSysVars)
	{
		if (e.m_bDeleted && e.m_id)
		{
			CStringA strDeleteVar = R"x(
object oSV = dom.GetObject (ID_SYSTEM_VARIABLES).Get(%1%);
if (oSV) {
  dom.DeleteObject(oSV);
}
)x";
			strDeleteVar.Replace("%1%", CStringA{ IntToString(e.m_id) });

			// An die Liste aller Statements anfügen
			strScriptForUpdate += strDeleteVar;
		}
	}

	// Jetzt bauen wir das Script auf, um Raumvariablen neu anzulegen
	for (auto const& e : m_lstSysVars)
	{
		// Wir legen nur Raumvariablen so an. Alle anderen Variablen werden mit 
		// den SYSVARS-Init Skripts angelegt.
		if (e.m_bNew && !e.m_bDeleted && IsMatchingRoomPrefix(e.m_strName))
		{
			CStringA strCreateVar = R"x(
object oSV = dom.CreateObject(1089);
dom.GetObject(ID_SYSTEM_VARIABLES).Add(oSV.ID()); 
oSV.Name("%1%"); 
oSV.ValueType(20); 
oSV.ValueSubType(11);
oSV.DPInfo("Raumbeschreibung für HK-Skript 2"); 
oSV.ValueUnit(""); 
oSV.Internal(false); 
oSV.Visible(true); 
oSV.Unerasable(false);
oSV.DPArchive (true);
oSV.Variable(%2%);
!//--------------------
)x";
			strCreateVar.Replace("%1%", CStringA{ e.m_strName });
			strCreateVar.Replace("%2%", CStringA{ e.m_dataType==DataType::vtString ? QuoteString(e.m_strContent) : e.m_strContent });

			// An die Liste aller Statements anfügen
			strScriptForUpdate += strCreateVar;
		}
	}

	// Jetzt bauen wir das Script auf, um die Systemvariablen ändern, dass schließt Namensänderungen 
	// ein und auch Änderungen der Beschreibung ein. Hier ist es wichtig, dass auch neu angelegte 
	// Variablen hier erst Ihren eigentlichn Inhalt bekommen. 
	// Die SYSVARS-Init-Skripte zuvor haben die Variablen nur angelegt.
	for (auto const& e : m_lstSysVars)
	{
		auto const *pSysVarDefault = m_lstSysVarsDefault.Find(RemovePrefix(e.m_strName));
		bool bBeschreibungGeaendert = (pSysVarDefault && e.m_strDescription!=pSysVarDefault->m_strDescription);
		CString strNeueBeschreibung{ bBeschreibungGeaendert ? pSysVarDefault->m_strDescription : _T("") };
		if (((e.m_bNew || e.m_bModified || e.m_bModifiedName) || bBeschreibungGeaendert) && !e.m_bDeleted)
		{
			CStringA strUpdateVar = R"x(
object oSV = dom.GetObject (ID_SYSTEM_VARIABLES).Get(%1%);
if (oSV) {
  if (%1%!="%2%") {
    oSV.Name("%2%");
  }
  if (%4%!="") {
	oSV.DPInfo(%4%);
  }
  if (oSV.State()!=%3%) {
    oSV.State(%3%);
  }
}
!//--------------------
)x";
			// Es besteht die Mögliochkeit, dass die Variable schon da ist, wenn 
			// nicht müssen wir über den Namen die Variable aktualisieren
			if (e.m_id && !e.m_bNew)
				strUpdateVar.Replace("%1%", CStringA{ IntToString(e.m_id) });
			else 
				strUpdateVar.Replace("%1%", CStringA{ QuoteString(e.m_strName) });
			strUpdateVar.Replace("%2%", CStringA{ e.m_strName });
			strUpdateVar.Replace("%3%", CStringA{ e.m_dataType==DataType::vtString ? QuoteString(e.m_strContent) : e.m_strContent });
			strUpdateVar.Replace("%4%",CStringA{ QuoteString(strNeueBeschreibung) });

			// An die Liste aller Statements anfügen
			strScriptForUpdate += strUpdateVar;
		}
	}

	// Hide Some vars
	{
		PCTSTR const aFields[] = {
			_T("HK-Log"), _T("HK1-Log"), _T("HK2-Log"), _T("HK-LogHeizkurvenkontrolle")
		};
		for (auto const *pName : aFields)
		{
			CString strName{ AddPrefix(pName) };
			auto* pVar = m_lstSysVars.Find(strName);
			if (pVar && pVar->m_bVisible)
			{
				CStringA strUpdateVar = R"x(	
object oSV = dom.GetObject (ID_SYSTEM_VARIABLES).Get("%1%");
if (oSV) {
  oSV.Visible(false);
}
!//--------------------
)x";
				// Variablen Liste einsetzen
				strUpdateVar.Replace("%1%", CStringA(strName));
				strScriptForUpdate += strUpdateVar;
			}
		}
		strScriptForUpdate += "\n!//##########################################################\n";
	}

	// Dom Update noch mal aufrufen
	strScriptForUpdate += R"x(
dom.RTUpdate(0);
)x";

	// Nun das Skript speichern
	try
	{
		CString strPath;
		GetTempPath2(_MAX_PATH,CStrBuf(strPath,_MAX_PATH));
		::PathAppend(CStrBuf(strPath,_MAX_PATH),m_strAppName);
		strPath += _T("_update.log");

		CStdioFile file(strPath,CFile::modeCreate | CFile::modeWrite | CFile::typeText);
		file.Write(strScriptForUpdate.GetBuffer(), strScriptForUpdate.GetLength());
	}
	catch (CException* e)
	{
		e->ReportError();
		e->Delete();
	}

	// Finally we update the CCU and execute the script
	CStringA strOut;
	CScriptEngine engine;
	if (engine.ExecuteScript(strScriptForUpdate, strOut))
	{
		AfxMessageBox(IDP_CCU_UPDATE_SUCCESSFUL);
	}
	else
	{
		CString strError;
		strError.FormatMessage(IDP_CCU_UPDATE_FAILED,engine.GetLastErrorText().GetString());
		AfxMessageBox(strError,MB_OK|MB_ICONERROR);
	}
}
