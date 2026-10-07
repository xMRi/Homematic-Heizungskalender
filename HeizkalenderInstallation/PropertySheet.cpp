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
#include <Shlwapi.h>
#include "HeizkalenderInstallation.h"
#include "RessourceDlg.h"
#include "RaumDlg.h"
#include "SysVarDlg.h"
#include "AboutDlg.h"
#include "PropertySheet.h"

BOOL CPageBase::OnQueryCancel()
{
	// Daten ändern bei Bedarf, damit die nächste Prüfung auch auf dem Settings DIalog funktioniert
	// wenn die Escape Taste gedrückt wird
	if (!UpdateData())
		return FALSE;

	// Prüfe auf Datenänderungen
	if (!theApp.IsDataModified())
		return TRUE;
	else 
		return AfxMessageBox(IDP_QUERY_DATA_MODIFIED,MB_ICONQUESTION|MB_DEFBUTTON2|MB_YESNO)==IDYES;
}

BOOL CPageBase::OnApply()
{
	// Da wir am Ende noch eine Nachricht anzeigen wollen, müssen wir es machen 
	// bevor der Dialog geschlossen wird.
	if (theApp.IsDataModified())
	{
		// Prüfe ob alle Seiten besucht wurden. Wenn es Änderngen gab, diese sollten nie unkontrolliert	bleiben.
		auto *pParent = STATIC_DOWNCAST(CInstallationsWizard,GetParent());
		if (theApp.IsRaumListeModified() && !pParent->m_pageResources.m_bSeiteBesucht)
		{
			AfxMessageBox(IDP_RAUMLISTE_KONTROLLIEREN);
			pParent->SetActivePage(&pParent->m_pageResources);
			return FALSE;
		}
		
		if (theApp.m_bNoProgramUpdate && !theApp.m_bForceUpdate)
		{
			AfxMessageBox(IDP_PROGRAMME_NICHT_AKTUALISIERT);
		}
		else if (theApp.IsProgramsModified() && !pParent->m_pagePrograms.m_bSeiteBesucht)
		{
			AfxMessageBox(IDP_PROGRAMME_KONTROLLIEREN);
			pParent->SetActivePage(&pParent->m_pagePrograms);
			return FALSE;
		}

		if (theApp.IsSysVarsModified() && !pParent->m_pageSysVar.m_bSeiteBesucht)
		{
			AfxMessageBox(IDP_SYSVARS_KONTROLLIEREN);
			pParent->SetActivePage(&pParent->m_pageSysVar);
			return FALSE;
		}

		// Sollen die Änderungen wirklich ausgeführt werden?
		if (AfxMessageBox(theApp.m_bSimulation ? IDP_QUERY_UPDATE_SIMUATION : IDP_QUERY_UPDATE_CCU,MB_ICONQUESTION|MB_DEFBUTTON2|MB_YESNO)==IDYES)
		{
			if (theApp.m_bSimulation)
				theApp.UpdateSimulation();
			else
				theApp.UpdateCCU();
			// Wir löschen alles, weil wir wieder hier bei OnOK vorbeikommen und weil
			// nun alle Listen leer sind, können wir das Programm sofort verlassen.
			theApp.ClearAll();
			return TRUE;
		}
		else
			return FALSE;
	}
	else if (!theApp.m_lstPrograms.empty() || !theApp.m_lstSysVars.empty())
	{
		// Informaieren wenn da Daten waren und es ist nicht zu tun.
		AfxMessageBox(IDP_CCU_NO_UPDATE);
		// Wir löschen alles, weil wir wieder hier bei OnOK vorbeikommen und weil
		// nun alle Listen leer sind, können wir das Programm sofort verlassen.
		theApp.ClearAll();
	}
	return TRUE;
}

BOOL CPageBase::OnSetActive()
{
	m_bSeiteBesucht = true;
	return __super::OnSetActive();
}

//-----------------------------------------------------------------------------

// InstallationsWizard

IMPLEMENT_DYNAMIC(CInstallationsWizard, CMFCPropertySheet)

CInstallationsWizard::CInstallationsWizard()
	: CMFCPropertySheet(IDS_TITLE)
{
	// Hide buttons
	m_psh.dwFlags &= ~PSH_HASHELP;
	m_psh.dwFlags |= PSH_NOAPPLYNOW;

	// Set style
	SetLook( CMFCPropertySheet::PropSheetLook_List,230);

	// Add pages
	AddPage(&m_pageConnect);
	AddPage(&m_pagePrograms);
	AddPage(&m_pageSettings);
	AddPage(&m_pageResources);
	AddPage(&m_pageRooms);
	AddPage(&m_pageSysVar);
}

CInstallationsWizard::~CInstallationsWizard()
{
}


BEGIN_MESSAGE_MAP(CInstallationsWizard, CMFCPropertySheet)
END_MESSAGE_MAP()


BOOL CInstallationsWizard::OnInitDialog()
{
	BOOL bResult = CMFCPropertySheet::OnInitDialog();

	return bResult;
}

//-----------------------------------------------------------------------------

CPageConnect::CPageConnect()
	: CPageBase(IDD_PAGE_CONNECT,IDS_PAGE_CONNECT)
{
	// Preset data from the registry
	if (!theApp.m_bSimulation)
	{
		theApp.m_strCCU_host = theApp.GetProfileString(_T("Connection"), _T("Host"));
		theApp.m_strCCU_username = theApp.GetProfileString(_T("Connection"), _T("UserName"));
		theApp.m_strCCU_password = theApp.GetProfileString(_T("Connection"), _T("Password"));
		theApp.m_iCCU_port = theApp.GetProfileInt(_T("Connection"), _T("Port"), 8181);
		theApp.m_strPrefix = theApp.GetProfileString(_T("Connection"), _T("Prefix"));
	}
	else
	{
		theApp.m_strCCU_host = 
		theApp.m_strCCU_username = 
		theApp.m_strCCU_password =  CStringRes(IDS_SIMULATION);
	}
}

BEGIN_MESSAGE_MAP(CPageConnect, CPageBase)
	ON_BN_CLICKED(IDC_BT_CONNECT, &CPageConnect::OnBnClickedBtConnect)
	ON_BN_CLICKED(IDC_ABOUT, &CPageConnect::OnBnClickedAbout)
	ON_CBN_SELCHANGE(IDC_CB_MODE, &CPageConnect::OnCbnSelchangeCbMode)
	ON_BN_CLICKED(IDC_BT_READRES, &CPageConnect::OnBnClickedBtReadres)
END_MESSAGE_MAP()

void CPageConnect::DoDataExchange(CDataExchange* pDX)
{
	CPageBase::DoDataExchange(pDX);
	DDX_Control(pDX, IDC_ED_HOST, m_edHost);
	DDX_Control(pDX, IDC_ED_USERNAME, m_edUserName);
	DDX_Control(pDX, IDC_ED_PASSWORD, m_edPassword);
	DDX_Control(pDX, IDC_ED_PREFIX, m_edPrefix);
	DDX_Control(pDX, IDC_CB_MODE, m_cbScript1Mode);
	DDX_Control(pDX, IDC_ED_CHURCHNAME, m_edCTChurchName);
	DDX_Control(pDX, IDC_ED_LOGINTOKEN, m_edCTLoginToken);
	DDX_Control(pDX, IDC_ED_ORGAID, m_edCDOrgaId);
	DDX_Control(pDX, IDC_ED_APITOKEN, m_edCDApiToken);
	DDX_Control(pDX, IDC_ED_ICALURL, m_ediCalUrl);
	DDX_Control(pDX, IDC_ED_GOOGLE_APIKEY, m_edGoogleApiKey);
	DDX_Control(pDX, IDC_ED_GOOGLE_KALID, m_edGoogleKalId);
	DDX_Control(pDX, IDC_ED_RAUMLISTE, m_edRaumListe);
	DDX_Text(pDX, IDC_ED_HOST, theApp.m_strCCU_host);
	DDX_Text(pDX, IDC_ED_USERNAME, theApp.m_strCCU_username);
	DDX_Text(pDX, IDC_ED_PASSWORD, theApp.m_strCCU_password);
	DDX_Text(pDX, IDC_ED_PREFIX, theApp.m_strPrefix);

	// Text felder
	{
		struct {
			UINT	m_uiId;
			PCTSTR  m_pzVarName;
		}
		const aVarListText[] =
		{
			IDC_ED_CHURCHNAME,		_T("HK1-CT-Gemeindename"), 
			IDC_ED_LOGINTOKEN,		_T("HK1-CT-Token"),
			IDC_ED_ORGAID,			_T("HK1-CD-OrganisationsId"),
			IDC_ED_APITOKEN,		_T("HK1-CD-Token"),
			IDC_ED_ICALURL,			_T("HK1-ICS-Url"),
			IDC_ED_GOOGLE_APIKEY,	_T("HK1-GK-API-Key"),
			IDC_ED_GOOGLE_KALID,	_T("HK1-GK-Kalender-ID"),
			IDC_ED_RAUMLISTE,		_T("HK1-R-Liste"),
		};
		// Wenn wir eine RaumListe haben, dann müssen wir die Validieren.
		if (pDX->m_bSaveAndValidate && m_edRaumListe.IsWindowVisible())
		{
			// Überprüfe das format der eingegebenen Raumliste
			pDX->PrepareEditCtrl(IDC_ED_RAUMLISTE);
			CString strRaumListeAlt;
			GetDlgItemText(IDC_ED_RAUMLISTE, strRaumListeAlt);

			// Leere Namen sind nicht erlaubt.
			CString strTemp, strId, strRaumListeNeu;
			strTemp = strRaumListeAlt;
			strTemp.Trim(UNERLAUBTE_ZEICHEN_FUER_RAEUME);
			for (auto strId : SplitString(strTemp, _T(';')))
			{
				CString s1 = CleanupNameForRoom(StrValueByIndex(strId, 0, _T('='))),
						s2 = CleanupNameForRoom(StrValueByIndex(strId, 1, _T('=')));
				if (!s2.IsEmpty())
					AppendTextWithDelimiter(s1,s2,_T("="));
				AppendTextWithDelimiter(strRaumListeNeu, s1, _T(';'));
			}
			if (strRaumListeNeu.IsEmpty() || strRaumListeAlt!=strRaumListeNeu)
			{
				SetDlgItemText(IDC_ED_RAUMLISTE, strRaumListeNeu);
				AfxMessageBox(IDP_RAUMLISTE_UNGUELTIG);
				pDX->Fail();        // throws exception
			}
		}
		// Process text fields
		for (auto const& e : aVarListText)
		{
			if (theApp.m_bConnected && GetDlgItem(e.m_uiId)->IsWindowVisible())
			{
				// Nur wenn die Variablen Liste gelesen ist.
				auto* pVar = theApp.m_lstSysVars.Find(theApp.AddPrefix(e.m_pzVarName));
				ASSERT(pVar);
				CString strText = pVar->m_strContent;
				DDX_Text(pDX, e.m_uiId, strText);
				if (pDX->m_bSaveAndValidate)
				{
					strText.Trim();
					pVar->SetContent(strText);
				}
			}
		}
	}

}

static UINT auiCtrlsChurchTools[] = 
{ 
	IDC_ST_CHURCHTOOL1, IDC_ED_CHURCHNAME, IDC_ST_CHURCHTOOL2, IDC_ED_LOGINTOKEN, IDC_BT_READRES, 0
};
static UINT auiCtrlsChurchDesk[] = 
{ 
	IDC_ST_CHURCHDESK1, IDC_ED_ORGAID, IDC_ST_CHURCHDESK2, IDC_ED_APITOKEN, IDC_BT_READRES, 0
};
static UINT auiCtrlsiCal[] = 
{ 
	IDC_ST_ICALURL, IDC_ED_ICALURL, IDC_ST_RAUMLISTE, IDC_ED_RAUMLISTE, IDC_BT_READRES, 0
};
static UINT auiCtrlsGoogle[] = 
{ 
	IDC_ST_GOOGLE1, IDC_ED_GOOGLE_APIKEY, IDC_ST_GOOGLE2, IDC_ED_GOOGLE_KALID, IDC_ST_RAUMLISTE, IDC_ED_RAUMLISTE, IDC_BT_READRES, 0
};

struct {
	ModeScript1 m_mode;
	UINT const	*m_puiCtrls;
} const aCtrlsForModes[] = {
	ModeScript1::ChurchToolsAPI,	auiCtrlsChurchTools,
	ModeScript1::ChurchDeskAPI,		auiCtrlsChurchDesk,
	ModeScript1::ChurchDeskiCal,	auiCtrlsChurchDesk,
	ModeScript1::Google,			auiCtrlsGoogle,
	ModeScript1::iCal,				auiCtrlsiCal,
};


BOOL CPageConnect::OnInitDialog()
{
	CPageBase::OnInitDialog();

	LOGFONT logfont;
	GetFont()->GetObject(sizeof(LOGFONT),&logfont);
	logfont.lfWeight = FW_BOLD;
	if (m_fontBold.CreateFontIndirect(&logfont))
	{
		// Set bold font
		static const UINT uiBoldCtrls[] = 
		{
			IDC_ST_VERSION, 0
		};
		for (int i=0; uiBoldCtrls[i]; ++i)
		{
			CWnd *pWnd = GetDlgItem(uiBoldCtrls[i]);
			if (pWnd)
				pWnd->SetFont(&m_fontBold);
		}
	}

	m_cbScript1Mode.EnableWindow(FALSE);

	// Keine Leerzeichen für Raumliste erlauben
	m_edRaumListe.SetEditType(CEditText::fTypeNumeric | CEditText::fTypeAlpha | CEditText::fTypePunct | CEditText::fTypeUnderscore);
	CString strDisallowedChars{ UNERLAUBTE_ZEICHEN_FUER_RAEUME };
	strDisallowedChars.Remove(_T('='));
	strDisallowedChars.Remove(_T(';')); 
	m_edRaumListe.SetDisallowedCharList(strDisallowedChars);

	CString strMask, strText;
	GetDlgItemText(IDC_ST_VERSION,strMask);
	strText.FormatMessage(strMask, theApp.m_strAppVersion.GetString(), theApp.m_strScriptVersion.GetString());
	SetDlgItemText(IDC_ST_VERSION,strText);

	// Alle COntrols disdablen
	for (auto const& e : aCtrlsForModes)
	{
		for (auto const *p = e.m_puiCtrls; *p; ++p)
		{
			CWnd* pWnd = GetDlgItem(*p);
			pWnd->EnableWindow(FALSE);
			pWnd->ShowWindow(SW_HIDE);
		}
	}

	// Fill combo box
	struct {
		ModeScript1 m_mode;
		UINT	m_uiIdText;
	} aListModesForCombo[] = {
		ModeScript1::ChurchToolsAPI,	IDS_MODE_CHURCHTOOLS,
		ModeScript1::ChurchDeskAPI,		IDS_MODE_CHURCHDESK_API,
		ModeScript1::ChurchDeskiCal,	IDS_MODE_CHURCHDESK_ICAL,
		ModeScript1::iCal,				IDS_MODE_ICAL,
		ModeScript1::Google,			IDS_MODE_GOOGLE,
	};
	for (auto const& e : aListModesForCombo)
	{
		auto n = m_cbScript1Mode.AddString(CStringRes(e.m_uiIdText));
		if (n>=0)
			m_cbScript1Mode.SetItemData(n,static_cast<int>(e.m_mode));
	}

	// Falls dies eine Simulation ist eine Warnung anzeigen.
	if (theApp.m_bSimulation)
	{
		UINT const aCtrls[] = { IDC_ED_HOST, IDC_ED_USERNAME, IDC_ED_PASSWORD };
		for (auto uiCtrl : aCtrls)
			STATIC_DOWNCAST(CEdit,GetDlgItem(uiCtrl))->SetReadOnly(TRUE);
		AfxMessageBox(IDP_SIMULATION_GESTARTET);
	}
	return TRUE;  
}

BOOL CPageConnect::OnKillActive()
{
	if (m_bBlockFirstOnKillActive)
	{
		m_bBlockFirstOnKillActive = false;
		return TRUE;
	}

	if (!theApp.m_bConnected)
	{
		AfxMessageBox(IDP_NEED_CONNECTION);
		return FALSE;
	}
	if (theApp.m_modeScript1==ModeScript1::Unknown)
	{
		AfxMessageBox(IDP_NEED_MODE);
		return FALSE;
	}

	return __super::OnKillActive();
}

void CPageConnect::OnBnClickedAbout()
{
	CAboutDlg dlg;
	dlg.DoModal();
}

void SwitchToMode(CComboBox& cb, ModeScript1 mode)
{
	for (int i = 0, n = cb.GetCount(); i<n; ++i)
	{
		if (cb.GetItemData(i)==static_cast<int>(theApp.m_modeScript1))
		{
			cb.SetCurSel(i);
			return;
		}
	}
	cb.SetCurSel(-1);
}

void CPageConnect::OnCbnSelchangeCbMode()
{
	int nSel = m_cbScript1Mode.GetCurSel();
	if (nSel<0)
		return;

	ModeScript1 newMode = static_cast<ModeScript1>(m_cbScript1Mode.GetItemData(nSel));
	if (theApp.m_modeScript1==newMode)
		return;

	// Daten sichern für die jetzt sichtbaren Controls
	UpdateData(TRUE);

	// Collect all control Ids
	std::set<UINT> setCtrls;
	UINT const *pCtrlsNew=nullptr;
	UINT const *pCtrlsOld=nullptr;
	for (auto const &e : aCtrlsForModes)
	{
		if (e.m_mode==newMode)
			pCtrlsNew = e.m_puiCtrls;
		if (e.m_mode==theApp.m_modeScript1)
			pCtrlsOld = e.m_puiCtrls;
		for (auto const *p = e.m_puiCtrls; *p; ++p)
			setCtrls.emplace(*p);
	}

	// Prüfen ob die Raumliste gefüllt ist und der Modus sich ändert
	auto *pVar = theApp.m_lstSysVars.Find(theApp.AddPrefix(HK1_RAUMLISTE));
	ASSERT(pVar);
	if (theApp.m_modeScript1!=ModeScript1::Unknown && pVar && !pVar->m_strContent.IsEmpty())
	{
		// Es wurden bereis Raumdaten und Ressourcen eingelesen. Diese müssen entfernt werden, weil Sie 
		// Quelle für die Ressourcen geändert wird.
		if (AfxMessageBox(IDP_QUERY_MODE_SWITCH_WARNING_RES, MB_ICONQUESTION|MB_DEFBUTTON2|MB_YESNO)!=IDYES)
		{
			// Alten Modus wieder setzen.
			SwitchToMode(m_cbScript1Mode, theApp.m_modeScript1);
			return;
		}
	}
	if (pCtrlsOld)
	{
		bool bAnyFilled = false;
		for (auto const *p = pCtrlsOld; *p; ++p)
		{
			CEditText *pEdit = DYNAMIC_DOWNCAST(CEditText,GetDlgItem(*p));
			if (pEdit && !pEdit->GetValue().IsEmpty())
			{
				bAnyFilled = true;
				break;
			}
		}
		if (bAnyFilled)
		{
			if (AfxMessageBox(IDP_QUERY_MODE_SWITCH_WARNING,MB_ICONQUESTION|MB_DEFBUTTON2|MB_YESNO)!=IDYES)
			{
				// Alten Modus wieder setzen.
				SwitchToMode(m_cbScript1Mode, theApp.m_modeScript1);
				return;
			}
		}
	}

	// Neue Controls anzeigen
	if (pCtrlsNew)
	{
		for (auto const *p = pCtrlsNew; *p; ++p)
		{
			setCtrls.erase(*p);
			CWnd* pWnd = GetDlgItem(*p);
			pWnd->EnableWindow(TRUE);
			pWnd->ShowWindow(SW_SHOW);
		}
		GotoDlgCtrl(GetDlgItem(*pCtrlsNew));
	}

	// Alte verstecken.
	for (auto e : setCtrls)
	{
		CWnd* pWnd = GetDlgItem(e);
		pWnd->EnableWindow(FALSE);
		pWnd->ShowWindow(SW_HIDE);
	}

	// Wir vollziehen jetzt einen Moduswechsel. Das führt dazu, dass die alten Raumliste gelöscht wird.
	if (theApp.m_modeScript1!=ModeScript1::Unknown)
	{
		// Raumlisten löschen
		auto *pVarRaumListe1 = theApp.m_lstSysVars.Find(theApp.AddPrefix(HK1_RAUMLISTE));
		auto *pVarRaumListe2 = theApp.m_lstSysVars.Find(theApp.AddPrefix(HK2_RAUMLISTE));
		ASSERT(pVarRaumListe1 && pVarRaumListe2);
		pVarRaumListe1->ClearContent();
		pVarRaumListe2->ClearContent();
	}

	// Set new mode
	theApp.m_modeScript1 = newMode;

	// Programme aktualisieren
	theApp.FixScript1AfterModeChange();

	// Daten noch mal einlesen, für die jetzt sichtbaren Controls
	UpdateData(FALSE);
}

void CPageConnect::OnBnClickedBtConnect()
{
	UpdateData();

	if (theApp.m_bSimulation)
	{
		if (!theApp.ConnectToSimulation())
			return;
	}
	else
	{
		if (!theApp.ConnectToCCU())
			return;
	}
	
	// Geladene Daten prüfen
	if (!theApp.AnalyseLoadedData())
		return;

	// Wenn wir einen Connect haben können wir die Programme aktualisieren
	theApp.UpdatePrograms();

	// Connect succeeded, Daten sichern
	theApp.m_bConnected = true;
	// Save all data we just used.
	if (!theApp.m_bSimulation)
	{
		theApp.WriteProfileString(_T("Connection"), _T("Host"), theApp.m_strCCU_host);
		theApp.WriteProfileString(_T("Connection"), _T("UserName"), theApp.m_strCCU_username);
		theApp.WriteProfileString(_T("Connection"), _T("Password"), theApp.m_strCCU_password);
		theApp.WriteProfileString(_T("Connection"), _T("Prefix"), theApp.m_strPrefix);
	}

	// Modus in combobox setzen.
	theApp.m_modeScript1 = theApp.m_modeScript1Installed;
	for (int i = 0, n = m_cbScript1Mode.GetCount(); i<n; ++i)
	{
		if (m_cbScript1Mode.GetItemData(i)==static_cast<int>(theApp.m_modeScript1Installed))
		{
			m_cbScript1Mode.SetCurSel(i);
			break;
		}
	}

	// Wir wollen eine Änderung erzwingen!
	theApp.m_modeScript1 = ModeScript1::Unknown;
	OnCbnSelchangeCbMode();

	// Disable all controls, for a connect, we are allowe dto do this only once
	UINT aIds[] = { IDC_ED_HOST, IDC_ED_USERNAME, IDC_ED_PASSWORD, IDC_ED_PREFIX};
	for (UINT id : aIds)
		static_cast<CEdit*>(GetDlgItem(id))->SetReadOnly(TRUE);
	GetDlgItem(IDC_BT_CONNECT)->EnableWindow(FALSE);
	m_cbScript1Mode.EnableWindow(TRUE);

	// Wenn wir jetzt keinen Modus haben sehen wir alt aus.
	if (theApp.m_modeScript1Installed==ModeScript1::Unknown)
	{
		if (theApp.m_lstPrograms.empty())
			// Aus den vorliegenden Daten, kann kein Modus ermittelt werden
			AfxMessageBox(IDP_CHOOSE_NEW_MODE);
		else
			// Aus den vorliegenden Daten, kann kein Modus ermittelt werden
			AfxMessageBox(IDP_CHOOSE_MODE_MANUAL);
	}

	// Daten laden
	UpdateData(FALSE);
}

void CPageConnect::OnBnClickedBtReadres()
{
	// Prüfe zuerst die beiden Felder, für die Verbindungsdaten.
	UINT auiIds[] = { IDC_ED_CHURCHNAME, IDC_ED_LOGINTOKEN, IDC_ED_ORGAID, IDC_ED_APITOKEN };
	bool bAnyEmpty = false;
	// Wenn es sichtbar und leer ist fehlt ein Eigabefeld
	for (auto uiId : auiIds)
	{
		CString strText;
		GetDlgItemText(uiId,strText);
		if (strText.IsEmpty() && GetDlgItem(uiId)->IsWindowVisible())
			bAnyEmpty = true;
	}
	if (bAnyEmpty)
	{
		AfxMessageBox(IDP_LOGIN_DATA_REQUIERED);
		return;
	}

	// Daten umladen
	UpdateData(TRUE);
	theApp.ReadResources();
}

//-----------------------------------------------------------------------------

CPageSettings::CPageSettings()
	: CPageBase(IDD_PAGE_SETTINGS,IDS_PAGE_SETTINGS)
{
}

BEGIN_MESSAGE_MAP(CPageSettings, CPageBase)
END_MESSAGE_MAP()

void CPageSettings::DoDataExchange(CDataExchange* pDX)
{
	CPageBase::DoDataExchange(pDX);

	DDX_Control(pDX, IDC_ED_ATEMPGRENZE, m_edATempGrenze);
	DDX_Control(pDX, IDC_ED_GRUNDTEMP, m_edGrungTemp);
	// Muss aufsteigend sein
	ASSERT(
		IDC_ED_KURVE_1<IDC_ED_KURVE_2 &&
		IDC_ED_KURVE_2<IDC_ED_KURVE_3 &&
		IDC_ED_KURVE_3<IDC_ED_KURVE_4 &&
		IDC_ED_KURVE_4<IDC_ED_KURVE_5 &&
		IDC_ED_KURVE_5<IDC_ED_KURVE_6 &&
		IDC_ED_KURVE_6<IDC_ED_KURVE_7 &&
		IDC_ED_KURVE_7<IDC_ED_KURVE_8 &&
		(IDC_ED_KURVE_8-IDC_ED_KURVE_1+1)==_countof(m_edKurve)
	);
	for (int i=0; i<_countof(m_edKurve); ++i)
		DDX_Control(pDX, IDC_ED_KURVE_1+i, m_edKurve[i]);

	// Schalter
	{
		struct {
			UINT	m_uiId;
			PCTSTR  m_pzVarName;
		}
		const aVarListBool[] =
		{
			IDC_CH_LOG,				_T("HK-Logging"),
			IDC_CH_LOG1,			_T("HK1-Logging"),
			IDC_CH_LOG2,			_T("HK2-Logging"),
			IDC_CH_LOG_HEIZKURVE,	_T("HK-LoggingHeizkurvenkontrolle"),
			IDC_CH_HANDTEMP,		_T("HK2-Hand-Temp"),
			IDC_CH_HANDGRUNDTEMP,	_T("HK2-Hand-Grundtemp"),
		};

		for (auto const& e : aVarListBool)
		{
			auto* pVar = theApp.m_lstSysVars.Find(theApp.AddPrefix(e.m_pzVarName));
			ASSERT(pVar);
			BOOL bVal = StringToBool(pVar->m_strContent);
			DDX_Check(pDX, e.m_uiId, bVal);
			if (pDX->m_bSaveAndValidate)
				pVar->SetContent(BoolToString(bVal));
		}
	}

	// Int felder
	{
		struct {
			UINT	m_uiId;
			PCTSTR  m_pzVarName;
		}
		const aVarListDouble[] =

		{
			IDC_ED_ATEMPGRENZE,		_T("HK2-A.Temp.Grenze"),
			IDC_ED_GRUNDTEMP,		_T("HK2-Grundtemperatur"),
		};
		for (auto const& e : aVarListDouble)
		{
			auto* pVar = theApp.m_lstSysVars.Find(theApp.AddPrefix(e.m_pzVarName));
			ASSERT(pVar);
			double dblVal = StringToDouble(pVar->m_strContent);
			DDX_EditDouble(pDX, e.m_uiId, dblVal);
			if (pDX->m_bSaveAndValidate)
				pVar->SetContent(DoubleToString(dblVal, 1));
		}
	}

	// Grundtemperatur aufbauen
	{
		auto* pVar = theApp.m_lstSysVars.Find(theApp.AddPrefix(_T("HK2-Kurve")));
		ASSERT(pVar);
		if (!pDX->m_bSaveAndValidate)
		{
			CString strValue { pVar->m_strContent };
			for (int i = 0; i<_countof(m_edKurve); ++i)
			{
				int val = StringToInt(StrValueByIndex(strValue,i,_T(';')));
				DDX_EditInt(pDX,IDC_ED_KURVE_1+i,val);
			}
		}
		else
		{
			CString strValue;
			int iValPrev = 9999;
			for (int i = 0; i<_countof(m_edKurve); ++i)
			{
				int iVal = 0;
				DDX_EditInt(pDX,IDC_ED_KURVE_1+i,iVal);
				if (!strValue.IsEmpty())
					strValue += _T(";");
				strValue += IntToString(iVal);
				if (iVal>=iValPrev)
				{
					AfxMessageBox(IDP_KURVEN_WERTE_AUFSTEIGEND);
					pDX->Fail();
					return;
				}
				iValPrev = iVal;
			}
			pVar->SetContent(strValue);
		}
	}
}

BOOL CPageSettings::OnInitDialog()
{
	CPageBase::OnInitDialog();

	m_edGrungTemp.SetMinMax(0,30);
	m_edGrungTemp.SetPrecision(1);
	m_edGrungTemp.CreateSpinBtnCtrl();
	m_edATempGrenze.SetMinMax(0,30);
	m_edATempGrenze.SetPrecision(1);
	m_edATempGrenze.CreateSpinBtnCtrl();
	for (int i = 0; i<_countof(m_edKurve); ++i)
	{
		auto& ed = m_edKurve[i];
		ed.SetMinMax(0,60*24);
		ed.CreateSpinBtnCtrl();
	}

	return TRUE;  
}


//-----------------------------------------------------------------------------

CPagePrograms::CPagePrograms()
	: CPageBase(IDD_PAGE_PROGRAMS,IDS_PAGE_PROGRAMS)
{
}

BEGIN_MESSAGE_MAP(CPagePrograms, CPageBase)
	ON_NOTIFY(LVN_ITEMCHANGED, IDC_LC_DATA, &CPagePrograms::OnLvnItemchangedLcData)
	ON_BN_CLICKED(IDC_BT_WINMERGE, &CPagePrograms::OnBnClickedBtWinmerge)
	ON_NOTIFY(NM_DBLCLK, IDC_LC_DATA, &CPagePrograms::OnNMDblclkLcData)
END_MESSAGE_MAP()

static CString GetWinMergePath()
{
	CString strPath;

	// Open HKLM key (64-bit aware)
	CRegKey regKey;
	LONG result = regKey.Open(
		HKEY_LOCAL_MACHINE,
		_T("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\App Paths\\WinMerge.exe"),
		KEY_READ | KEY_WOW64_64KEY
	);

	if (result != ERROR_SUCCESS)
		return strPath;

	// Read default value (the exe path)
	ULONG bufferSize = _MAX_PATH;
	VERIFY(regKey.QueryStringValue(nullptr,CStrBuf(strPath,_MAX_PATH),&bufferSize)==ERROR_SUCCESS);
	return strPath;
}
void CPagePrograms::EnableControls()
{
	m_btWinMerge.EnableWindow(m_lcData.GetSelectedCount()>0);
}

void CPagePrograms::DoDataExchange(CDataExchange* pDX)
{
	CPageBase::DoDataExchange(pDX);

	if (!pDX->m_bSaveAndValidate && m_lcData.GetSafeHwnd())
	{
		m_lcData.DeleteAllItems();
		auto& lst = theApp.m_lstPrograms;
		for (auto const& p : lst)
		{
			int n = m_lcData.InsertItem(m_lcData.GetItemCount(), p.m_strName);
			if (n>=0)
			{
				// Suche den eintrag in der originalen liste
				m_lcData.SetItemData(n, reinterpret_cast<DWORD_PTR>(&p));
				m_lcData.SetItemText(n, COL_DATE_INSTALLED, !p.m_bNew ? DateToString(p.m_date) : _T(""));
				m_lcData.SetItemText(n, COL_DATE_UPDATE, p.m_pAppProg ? DateToString(p.m_pAppProg->m_date) : _T(""));

				bool bIsScript1 = p.m_strName==theApp.AddPrefix(HK1_SKRIPT_1);
				UINT uiText = 0;
				if (theApp.m_bNoProgramUpdate && !theApp.m_bForceUpdate)
					uiText = IDS_INST_IGNORED;
				else if (p.m_bNew && p.m_id==0)
					uiText = IDS_INST_NEW;
				else if (p.m_bNew && p.m_id!=0)
					uiText = IDS_INST_REPLACED;
				else if (p.m_bModified || (bIsScript1 && theApp.IsModeScript1Modified()))
					uiText = IDS_INST_UPDATED;
				else if (p.m_pAppProg)
					uiText = IDS_INST_NOACTION;
				else if (!p.m_pAppProg)
					uiText = IDS_INST_IGNORED;
				if (uiText)
					m_lcData.SetItemText(n, COL_INFO, CStringRes(uiText));
			}
		}
	}

	DDX_Control(pDX, IDC_LC_DATA, m_lcData);
	DDX_Control(pDX, IDC_BT_WINMERGE, m_btWinMerge);
	EnableControls();
}


BOOL CPagePrograms::OnInitDialog()
{
	CPageBase::OnInitDialog();

	m_lcData.SetExtendedStyle(m_lcData.GetExtendedStyle()
		| LVS_EX_FULLROWSELECT | LVS_EX_INFOTIP | LVS_EX_DOUBLEBUFFER
	);

	// Get width of list box
	CRect rect;
	m_lcData.GetClientRect(rect);

	CString strTitle{ MAKEINTRESOURCE(IDS_TITLE_PROGRAMS) };

	m_lcData.InsertColumn(COL_NAME,StrValueByIndex(strTitle,COL_NAME,_T(';')), LVCFMT_LEFT, m_lcData.GetStringWidth(CString(_T('9'), 35)));
	m_lcData.InsertColumn(COL_DATE_INSTALLED,StrValueByIndex(strTitle,COL_DATE_INSTALLED,_T(';')),LVCFMT_LEFT,m_lcData.GetStringWidth(CString(_T('9'),14)));
	m_lcData.InsertColumn(COL_DATE_UPDATE,StrValueByIndex(strTitle,COL_DATE_UPDATE,_T(';')),LVCFMT_LEFT,m_lcData.GetStringWidth(CString(_T('9'),14)));

	// Rest errechnen
	for (int i=0; i<3; ++i)
		rect.right -= m_lcData.GetColumnWidth(i);

	m_lcData.InsertColumn(COL_INFO,StrValueByIndex(strTitle,3,_T(';')),LVCFMT_LEFT,max(rect.Width(),m_lcData.GetStringWidth(CString(_T('9'),26))));

	UpdateData(FALSE);
	return TRUE;  
}

void CPagePrograms::OnLvnItemchangedLcData(NMHDR* pNMHDR, LRESULT* pResult)
{
	// LPNMLISTVIEW pNMLV = reinterpret_cast<LPNMLISTVIEW>(pNMHDR);
	EnableControls();
	*pResult = 0;
}

void CPagePrograms::OnBnClickedBtWinmerge()
{
	CString strWinMergePath = GetWinMergePath();
	if (strWinMergePath.IsEmpty() || !PathFileExists(strWinMergePath))
	{
		AfxMessageBox(IDP_WINMERGE_NICHT_GEFUNDEN);
		return;
	}

	// Aktuelles Skrip laden und in eine Temp Datei schreiben
	int nSel = m_lcData.GetNextItem(-1, LVNI_SELECTED);
	if (nSel<0)
		return;
	auto* pProg = reinterpret_cast<CDataProgram*>(m_lcData.GetItemData(nSel));
	if (!pProg || !pProg->m_pAppProg)
		return;

	// Copy des aktuellen Inhalts speichern
	try
	{
		auto Write = [](CString const& strFileNamePrefix, CString const& strFileName, CStringA const &strSkriptA, CString const &strProgPrefix)
		{
			CString strPath;
			GetTempPath2(_MAX_PATH, CStrBuf(strPath, _MAX_PATH));
			::PathAppend(CStrBuf(strPath, _MAX_PATH), strFileNamePrefix+strFileName+_T(".hsc"));

			CFile file;
			if (file.Open(strPath, CFile::modeCreate | CFile::modeWrite | CFile::typeBinary))
			{
				// 2. Calculate the required buffer size for UTF-8 (CP_UTF8)
				CString strSkript{ strSkriptA };

				// Programmmpräfix einfügen
				if (!strProgPrefix.IsEmpty())
					// Achtung! Manche Skripte wie das Sichern des Systemprotokolls haben keinen vrp Eintrag!
					strSkript.Replace(_T("string vrp=\"\";"), _T("string vrp=\"") + strProgPrefix + _T("\";"));
				// Zeilenenden anpassen
				strSkript.Replace(_T("\n"), _T("\r\n")); 
				int nLen = WideCharToMultiByte(CP_UTF8, 0, strSkript, strSkript.GetLength(), NULL, 0, NULL, NULL);

				if (nLen > 0)
				{
					// 3. Perform the conversion to a temporary byte buffer
					CStringA strUTF8;
					WideCharToMultiByte(CP_UTF8, 0, strSkript, strSkript.GetLength(), CStrBufA(strUTF8, nLen), nLen, NULL, NULL);

					// 4. Write the raw bytes directly to the file (No BOM is written)
					file.Write(strUTF8.GetString(), nLen);
				}

				file.Close();
			}
			return strPath;
		};

		CString strPathNew{Write(_T("New_"), pProg->m_strName, pProg->m_pAppProg->m_strSkript, theApp.m_strPrefix)},
				strPathOld{Write(_T("Old_"), pProg->m_strName, pProg->m_strSkriptAlt, _T("")) };

		// Nun Winmerge starten
		// Exit auf Escape, Schreibgeschützt links+rechts, eigene Beschreibung, Keine MRU
		ShellExecute(
			nullptr, 
			_T("open"), 
			strWinMergePath, 
			_T("/e /u /wl /wr /dl \"") + CStringRes(IDS_VERSION_NEU) + _T(": ")+ pProg->m_strName + _T("\" ") +
				_T("/dr \"") + CStringRes(IDS_VERSION_ALT) + _T(": ") + pProg->m_strName +
				_T("\" \"") + strPathNew + _T("\" \"") + strPathOld + _T("\""), 
			nullptr, 
			SW_SHOWNORMAL);
		}
	catch (CException* e)
	{
		e->ReportError();
		e->Delete();
		return;
	}
}

void CPagePrograms::OnNMDblclkLcData(NMHDR* pNMHDR, LRESULT* pResult)
{
	// LPNMITEMACTIVATE pNMItemActivate = reinterpret_cast<LPNMITEMACTIVATE>(pNMHDR);
	OnBnClickedBtWinmerge();
	*pResult = 0;
}

//-----------------------------------------------------------------------------

CPageRooms::CPageRooms()
	: CPageBase(IDD_PAGE_ROOMS,IDS_PAGE_ROOMS)
{
}

BEGIN_MESSAGE_MAP(CPageRooms, CPageBase)
	ON_BN_CLICKED(IDC_BT_NEW, &CPageRooms::OnBnClickedBtNew)
	ON_BN_CLICKED(IDC_BT_MODIFY, &CPageRooms::OnBnClickedBtModify)
	ON_BN_CLICKED(IDC_BT_DELETE, &CPageRooms::OnBnClickedBtDelete)
	ON_NOTIFY(LVN_ITEMCHANGED, IDC_LC_DATA, &CPageRooms::OnLvnItemchangedLcData)
	ON_NOTIFY(NM_DBLCLK, IDC_LC_DATA, &CPageRooms::OnNMDblclkLcRooms)
	ON_NOTIFY(LVN_KEYDOWN, IDC_LC_DATA, &CPageRooms::OnKeydownLcData)
END_MESSAGE_MAP()

void CPageRooms::EnableControls()
{
	auto nSel = m_lcData.GetSelectedCount();
	m_btModify.EnableWindow(nSel!=0);
	m_btDelete.EnableWindow(nSel!=0);
}

BOOL CPageRooms::OnSetActive()
{
	auto *pVar = theApp.m_lstSysVars.Find(theApp.AddPrefix(HK1_RAUMLISTE));
	if (!pVar || pVar->m_strContent.IsEmpty())
	{
		CPropertySheet* pSheet = static_cast<CPropertySheet*>(GetParent());
		AfxMessageBox(IDP_NO_ROOMS);
		pSheet->PostMessage(PSM_SETCURSEL,0);
		return FALSE;
	}
	return __super::OnSetActive();
}

void CPageRooms::DoDataExchange(CDataExchange* pDX)
{
	CPageBase::DoDataExchange(pDX);

	if (!pDX->m_bSaveAndValidate && m_lcData.GetSafeHwnd())
	{
		m_lcData.DeleteAllItems();
		auto& lst = theApp.m_lstSysVars;
		for (auto & e : lst)
		{
			if (!theApp.IsMatchingRoomPrefix(e.m_strName))
				continue;
			if (e.m_bDeleted)
				continue;

			int n = m_lcData.InsertItem(m_lcData.GetItemCount(), theApp.RemoveRoomPrefix(e.m_strName));
			if (n>=0)
			{
				m_lcData.SetItemData(n,reinterpret_cast<DWORD_PTR>(&e));
				m_lcData.SetItemText(n, COL_SH, StrValueByIndex(e.m_strContent,1,_T(';')));
				m_lcData.SetItemText(n, COL_TEMP, StrValueByIndex(StrValueByIndex(e.m_strContent,3,_T(';')),0,_T('/')));
				m_lcData.SetItemText(n, COL_EIN, StrValueByIndex(StrValueByIndex(e.m_strContent,4,_T(';')),0,_T('*')));
				m_lcData.SetItemText(n, COL_AUS, StrValueByIndex(e.m_strContent,5,_T(';')));
				// 6 Einträge überspringen
				int iPos=0;
				for (int i = 0; i<6; ++i, ++iPos)
				{
					iPos = e.m_strContent.Find(_T(';'), iPos);
					if (iPos<0)
						break;
				}
				if (iPos<0)
					iPos = e.m_strContent.GetLength();
				m_lcData.SetItemText(n, COL_HEIZGR, e.m_strContent.Mid(iPos));
				UINT uiText = 0;
				if (e.m_bNew)
					uiText = IDS_NEW;
				else if (e.m_bModified || e.m_bModifiedName)
					uiText = IDS_UPDATE;
				if (uiText)
					m_lcData.SetItemText(n, COL_INFO, CStringRes(uiText));
			}
		}
		EnableControls();
	}

	DDX_Control(pDX, IDC_LC_DATA, m_lcData);
	DDX_Control(pDX, IDC_BT_NEW, m_btNew);
	DDX_Control(pDX, IDC_BT_DELETE, m_btDelete);
	DDX_Control(pDX, IDC_BT_MODIFY, m_btModify);
}

BOOL CPageRooms::OnInitDialog()
{
	CPageBase::OnInitDialog();

	m_lcData.SetExtendedStyle(m_lcData.GetExtendedStyle()
		| LVS_EX_FULLROWSELECT | LVS_EX_INFOTIP | LVS_EX_DOUBLEBUFFER
	);

	// Get width of list box
	CRect rect;
	m_lcData.GetClientRect(rect);

	CString strTitle{ MAKEINTRESOURCE(IDS_TITLE_ROOMS) };

	m_lcData.InsertColumn(COL_NAME,		StrValueByIndex(strTitle, COL_NAME,		_T(';')), LVCFMT_LEFT,  m_lcData.GetStringWidth(CString(_T('9'), 15)));
	m_lcData.InsertColumn(COL_SH,		StrValueByIndex(strTitle, COL_SH,		_T(';')), LVCFMT_LEFT,  m_lcData.GetStringWidth(CString(_T('9'), 5)));
	m_lcData.InsertColumn(COL_TEMP,		StrValueByIndex(strTitle, COL_TEMP,		_T(';')), LVCFMT_RIGHT, m_lcData.GetStringWidth(CString(_T('9'), 7)));
	m_lcData.InsertColumn(COL_EIN,		StrValueByIndex(strTitle, COL_EIN,		_T(';')), LVCFMT_RIGHT, m_lcData.GetStringWidth(CString(_T('9'), 8)));
	m_lcData.InsertColumn(COL_AUS,		StrValueByIndex(strTitle, COL_AUS,		_T(';')), LVCFMT_RIGHT, m_lcData.GetStringWidth(CString(_T('9'), 8)));
	m_lcData.InsertColumn(COL_HEIZGR,	StrValueByIndex(strTitle, COL_HEIZGR,	_T(';')), LVCFMT_LEFT,  1);
	m_lcData.InsertColumn(COL_INFO,		StrValueByIndex(strTitle, COL_INFO,		_T(';')), LVCFMT_LEFT,  m_lcData.GetStringWidth(CString(_T('9'), 14)));

	// Rest errechnen
	for (int i = 0; i<7; ++i)
		rect.right -= m_lcData.GetColumnWidth(i);

	// Rest für Spalte 
	auto iWidth = m_lcData.GetStringWidth(CString(_T('9'), 20));
	m_lcData.SetColumnWidth(COL_HEIZGR,max(iWidth,rect.Width()));

	// Daten laden 
	UpdateData(FALSE);
	return TRUE;
}

void CPageRooms::OnNMDblclkLcRooms(NMHDR* pNMHDR, LRESULT* pResult)
{
	// LPNMITEMACTIVATE pNMItemActivate = reinterpret_cast<LPNMITEMACTIVATE>(pNMHDR);
	OnBnClickedBtModify();
	*pResult = 0;
}

void CPageRooms::OnLvnItemchangedLcData(NMHDR* pNMHDR, LRESULT* pResult)
{
	// LPNMLISTVIEW pNMLV = reinterpret_cast<LPNMLISTVIEW>(pNMHDR);
	EnableControls();
	*pResult = 0;
}

void CPageRooms::OnBnClickedBtNew()
{
	CString strRaumName { theApp.GenerateNewRoomName(CStringRes(IDS_NEW_ROOM))};
	SRaumDaten raum{ strRaumName, RAUM_DEFAULT + strRaumName};

	CRaumDlg dlg{ false, raum };
	if (dlg.DoModal()!=IDOK)
		return;

	CString strName, strContent;
	raum.GetAsString(strName,strContent);

	// Suche einen bestehenden Raum
	strName = theApp.AddRoomPrefix(strName);
	auto *pRaum = theApp.m_lstSysVars.Find(strName);
	if (pRaum && pRaum->m_bDeleted)
	{
		// Gelöschten Raum mit gleichem Namen aktualsieren.
		pRaum->m_bDeleted = false;
		pRaum->SetContent(strContent);
	}
	else if (!pRaum)
	{
		CDataSystemVariable data{};
		data.InitNeuerRaum(strName);
		data.m_bNew = true;
		data.m_strContent = strContent;
		theApp.m_lstSysVars.push_back(data);
	}

	// Daten neu laden
	UpdateData(FALSE);
}

void CPageRooms::OnBnClickedBtModify()
{
	// Hole den selektieren Eintrag.
	int nSel = m_lcData.GetNextItem(-1, LVNI_SELECTED);
	if (nSel<0)
		return;

	auto *pRaum = reinterpret_cast<CDataSystemVariable*>(m_lcData.GetItemData(nSel));
	if (!pRaum)
		return;

	CString strRaumNameAlt { theApp.RemoveRoomPrefix(pRaum->m_strName) };
	SRaumDaten raum{ strRaumNameAlt, pRaum->m_strContent };
	
	CRaumDlg dlg{ true, raum };
	if (dlg.DoModal()!=IDOK)
		return;

	CString strRaumNameNeu, strContent;
	raum.GetAsString(strRaumNameNeu,strContent);

	// Heizparameter belassen.
	auto CutFirst = [](CString const& str)
		{
			int iPos = str.Find(_T(';'));
			if (iPos>=0)
				return str.Mid(iPos);
			else
				return str;
		};
	strContent = StrValueByIndex(pRaum->m_strContent,0,_T(';')) + CutFirst(strContent);
	pRaum->SetContent(strContent);

	// Hier muss in jedem Fall ein Update erfolgen.
	if (strRaumNameNeu!=strRaumNameAlt)
	{
		strRaumNameAlt = theApp.AddRoomPrefix(strRaumNameAlt);
		strRaumNameNeu = theApp.AddRoomPrefix(strRaumNameNeu);
		ASSERT(theApp.m_lstSysVars.Find(strRaumNameNeu)==nullptr);
		pRaum->m_bModified = true;
		pRaum->m_strName = strRaumNameNeu;
		// Wir müsen aber nun auch in der mapRaumListe den Namen umändern.
		CMapRaumListe mapRaumListe;
		theApp.LoadRoomMapFromSysVars(mapRaumListe);
		// Suche den Raumnamen und entferne ihn.
		for (auto &e : mapRaumListe)
		{
			auto iCnt = e.second.m_lstRaeume.size();
			e.second.m_lstRaeume.remove(strRaumNameAlt);
			// Wenn der Name entfernt wurde, fügen wir den neuen hinzu
			if (iCnt!=e.second.m_lstRaeume.size())
				e.second.m_lstRaeume.push_back(strRaumNameNeu);
		}
		theApp.SaveRoomMapToSysVars(mapRaumListe);
	}

	// Daten neu laden
	UpdateData(FALSE);

	// Wenn es keinen Rename gab, die gleiche Zeile wieder selektieren
	if (strRaumNameNeu==strRaumNameAlt)
		m_lcData.SetItemState(nSel,LVIS_SELECTED|LVIS_FOCUSED, LVIS_SELECTED|LVIS_FOCUSED);
}

void CPageRooms::OnBnClickedBtDelete()
{
	// Hole den selektieren Eintrag.
	int nSel = m_lcData.GetNextItem(-1, LVNI_SELECTED);
	if (nSel<0)
		return;

	auto *pRaum = reinterpret_cast<CDataSystemVariable*>(m_lcData.GetItemData(nSel));
	if (!pRaum)
		return;

	CString strMsg;
	strMsg.FormatMessage(IDP_QUERY_DELETE_ROOM,theApp.RemoveRoomPrefix(pRaum->m_strName).GetString());	
	if (AfxMessageBox(strMsg,MB_ICONQUESTION|MB_DEFBUTTON2|MB_YESNO)!=IDYES)
		return;

	// Raum löschen
	pRaum->m_bDeleted = true;

	// Jetzt aus der Map entfernen
	CMapRaumListe mapRaumListe;
	theApp.LoadRoomMapFromSysVars(mapRaumListe);
	// Suche den Raumnamen und entferne ihn.
	for (auto &e : mapRaumListe)
	{
		e.second.m_lstRaeume.remove(pRaum->m_strName);
	}
	theApp.SaveRoomMapToSysVars(mapRaumListe);

	// Daten neu laden
	UpdateData(FALSE);
	auto nMax = m_lcData.GetItemCount();
	m_lcData.SetItemState(min(nSel,nMax-1),LVIS_SELECTED|LVIS_FOCUSED, LVIS_SELECTED|LVIS_FOCUSED);
	m_lcData.EnsureVisible(min(nSel,nMax-1),FALSE);
}

void CPageRooms::OnKeydownLcData(NMHDR* pNMHDR, LRESULT* pResult)
{
	LPNMLVKEYDOWN pLVKeyDow = reinterpret_cast<LPNMLVKEYDOWN>(pNMHDR);
	if (pLVKeyDow->wVKey==VK_DELETE)
		OnBnClickedBtDelete();
	*pResult = 0;
}

//-----------------------------------------------------------------------------

CPageSysvar::CPageSysvar()
	: CPageBase(IDD_PAGE_SYSVARS,IDS_PAGE_SYSVAR)
{
}

BEGIN_MESSAGE_MAP(CPageSysvar, CPageBase)
	ON_BN_CLICKED(IDC_BT_INFO, &CPageSysvar::OnBnClickedBtInfo)
	ON_NOTIFY(LVN_ITEMCHANGED, IDC_LC_DATA, &CPageSysvar::OnLvnItemchangedLcData)
	ON_NOTIFY(NM_DBLCLK, IDC_LC_DATA, &CPageSysvar::OnNMDblclkLcData)
END_MESSAGE_MAP()

void CPageSysvar::EnableControls()
{
	m_btInfo.EnableWindow(m_lcData.GetSelectedCount()>0);
}

void CPageSysvar::DoDataExchange(CDataExchange* pDX)
{
	CPageBase::DoDataExchange(pDX);
	
	if (!pDX->m_bSaveAndValidate && m_lcData.GetSafeHwnd())
	{
		m_lcData.DeleteAllItems();
		auto &lst = theApp.m_lstSysVars;
		for (auto const & e : lst)
		{
			if (!theApp.IsMatchingSysVar(e.m_strName))
				continue;
			if (!theApp.IsSysVarCompatibeWithModeScript1(theApp.RemovePrefix(e.m_strName),theApp.m_modeScript1))
				continue;
			if (e.m_bDeleted)
				continue;

			int n = m_lcData.InsertItem(m_lcData.GetItemCount(),e.m_strName);
			if (n>=0)
			{
				// Zeiger setzen
				m_lcData.SetItemData(n, reinterpret_cast<DWORD_PTR>(&e));

				// Suche den eintrag in der originalen liste
				m_lcData.SetItemText(n,COL_CONTENT,e.m_strContent);
				UINT uiText=0;
				if (e.m_bNew)
					uiText = IDS_NEW;
				else if (e.m_bModified || e.m_bModifiedName)
					uiText = IDS_UPDATE;
				if (uiText)
					m_lcData.SetItemText(n,COL_INFO,CStringRes(uiText));
			}
		}
	}

	DDX_Control(pDX, IDC_LC_DATA, m_lcData);
	DDX_Control(pDX, IDC_BT_INFO, m_btInfo);
}

BOOL CPageSysvar::OnInitDialog()
{
	CPageBase::OnInitDialog();

	m_lcData.SetExtendedStyle(m_lcData.GetExtendedStyle()
		| LVS_EX_FULLROWSELECT | LVS_EX_INFOTIP | LVS_EX_DOUBLEBUFFER
	);

	// Get width of list box
	CRect rect;
	m_lcData.GetClientRect(rect);

	CString strTitle{ MAKEINTRESOURCE(IDS_TITLE_SYSVARS) };

	m_lcData.InsertColumn(COL_NAME,		StrValueByIndex(strTitle, COL_NAME,		_T(';')), LVCFMT_LEFT, m_lcData.GetStringWidth(CString(_T('9'), 25)));
	m_lcData.InsertColumn(COL_CONTENT,	StrValueByIndex(strTitle, COL_CONTENT,	_T(';')), LVCFMT_LEFT, 1);
	m_lcData.InsertColumn(COL_INFO,		StrValueByIndex(strTitle, COL_INFO,		_T(';')), LVCFMT_LEFT, m_lcData.GetStringWidth(CString(_T('9'), 14)));

	// Rest errechnen
	for (int i = 0; i<3; ++i)
		rect.right -= m_lcData.GetColumnWidth(i);

	// Rest für Spalte 2
	 m_lcData.SetColumnWidth(COL_CONTENT,rect.Width());

	// Datenb laden 
	UpdateData(FALSE);
	
	return TRUE;
}

void CPageSysvar::OnBnClickedBtInfo()
{
	// Aktuelles Skrip laden und in eine Temp Datei schreiben
	int nSel = m_lcData.GetNextItem(-1, LVNI_SELECTED);
	if (nSel<0)
		return;
	auto* pSysVar = reinterpret_cast<CDataSystemVariable const *>(m_lcData.GetItemData(nSel));
	if (!pSysVar)
		return;

	CSysVarDlg dlg;
	dlg.m_pSysVar = pSysVar;
	dlg.DoModal();
}

void CPageSysvar::OnLvnItemchangedLcData(NMHDR* pNMHDR, LRESULT* pResult)
{
	// LPNMLISTVIEW pNMLV = reinterpret_cast<LPNMLISTVIEW>(pNMHDR);
	EnableControls();
	*pResult = 0;
}

void CPageSysvar::OnNMDblclkLcData(NMHDR* pNMHDR, LRESULT* pResult)
{
	// LPNMITEMACTIVATE pNMItemActivate = reinterpret_cast<LPNMITEMACTIVATE>(pNMHDR);
	OnBnClickedBtInfo();
	*pResult = 0;
}

//-----------------------------------------------------------------------------

CPageResources::CPageResources()
	: CPageBase(IDD_PAGE_RESOURCES,IDS_PAGE_RESOURCES)
{
}

BEGIN_MESSAGE_MAP(CPageResources, CPageBase)
	ON_BN_CLICKED(IDC_BT_MODIFY, &CPageResources::OnBnClickedBtModify)
	ON_NOTIFY(LVN_ITEMCHANGED, IDC_LC_DATA, &CPageResources::OnLvnItemchangedLcRooms)
	ON_NOTIFY(NM_DBLCLK, IDC_LC_DATA, &CPageResources::OnNMDblclkLcRooms)
	ON_BN_CLICKED(IDC_BT_DELETE, &CPageResources::OnBnClickedBtDelete)
	ON_NOTIFY(LVN_KEYDOWN, IDC_LC_DATA, &CPageResources::OnKeydownLcData)
//	ON_NOTIFY(HDN_ITEMDBLCLICK, 0, &CPageResources::OnItemdblclickLcData)
	ON_NOTIFY(HDN_ITEMCLICK, 0, &CPageResources::OnItemclickLcData)
END_MESSAGE_MAP()

void CPageResources::EnableControls()
{
	auto nSel = m_lcData.GetSelectedCount();
	m_btModify.EnableWindow(nSel!=0);
}

BOOL CPageResources::OnSetActive()
{
	auto *pVar = theApp.m_lstSysVars.Find(theApp.AddPrefix(HK1_RAUMLISTE));
	if (!pVar || pVar->m_strContent.IsEmpty())
	{
		CPropertySheet* pSheet = static_cast<CPropertySheet*>(GetParent());
		AfxMessageBox(IDP_NO_ROOMS);
		pSheet->PostMessage(PSM_SETCURSEL,0);
		return FALSE;
	}
	return __super::OnSetActive();
}

static int CALLBACK SortFunc(LPARAM lParam1, LPARAM lParam2, LPARAM lParamSort)
{
	auto const &pData1 = reinterpret_cast<CMapRaumListe::value_type*>(lParam1);
	auto const &pData2 = reinterpret_cast<CMapRaumListe::value_type*>(lParam2);

	if (lParamSort==CPageResources::COL_ID)
		return ::StrCmpLogicalW(pData1->first,pData2->first);
	else if (lParamSort==CPageResources::COL_NAME)
		return ::StrCmpLogicalW(pData1->second.m_strResourceName,pData2->second.m_strResourceName);
	else 
		return ::StrCmpLogicalW(ListToString(pData1->second.m_lstRaeume,_T(";")), ListToString(pData2->second.m_lstRaeume,_T(";")));
}

void CPageResources::DoDataExchange(CDataExchange* pDX)
{
	CPageBase::DoDataExchange(pDX);

	if (!pDX->m_bSaveAndValidate && m_lcData.GetSafeHwnd())
	{
		m_lcData.DeleteAllItems();

		theApp.LoadRoomMapFromSysVars(m_mapRaeume);
		
		for (auto const& e : m_mapRaeume)
		{
			int n = m_lcData.InsertItem(m_lcData.GetItemCount(), e.first);
			if (n>=0)
			{
				// Ist für das Sortieren nötig
				m_lcData.SetItemData(n,reinterpret_cast<DWORD_PTR>(&e));
				m_lcData.SetItemText(n, COL_NAME, e.second.m_strResourceName);
				auto lst = e.second.m_lstRaeume;
				CString strRaeume;
				for (auto& e : lst)	
					AppendTextWithDelimiter(strRaeume,theApp.RemoveRoomPrefix(e),_T("; "));
				m_lcData.SetItemText(n, COL_ROOMS, strRaeume);
			}
		}
		m_lcData.SortItems(SortFunc, COL_ID);
	}

	DDX_Control(pDX, IDC_LC_DATA, m_lcData);
	DDX_Control(pDX, IDC_BT_MODIFY, m_btModify);
}

BOOL CPageResources::OnInitDialog()
{
	CPageBase::OnInitDialog();

	m_lcData.SetExtendedStyle(m_lcData.GetExtendedStyle()
		| LVS_EX_FULLROWSELECT | LVS_EX_INFOTIP | LVS_EX_DOUBLEBUFFER
	);

	// Get width of list box
	CRect rect;
	m_lcData.GetClientRect(rect);

	CString strTitle{ MAKEINTRESOURCE(IDS_TITLE_RESOURCES) };

	m_lcData.InsertColumn(COL_ID,		StrValueByIndex(strTitle, COL_ID,		_T(';')), LVCFMT_LEFT,  m_lcData.GetStringWidth(CString(_T('9'), 8)));
	m_lcData.InsertColumn(COL_NAME,		StrValueByIndex(strTitle, COL_NAME,		_T(';')), LVCFMT_LEFT,  m_lcData.GetStringWidth(CString(_T('9'), 18)));
	m_lcData.InsertColumn(COL_ROOMS,	StrValueByIndex(strTitle, COL_ROOMS,	_T(';')), LVCFMT_LEFT,	1);

	// Rest errechnen
	for (int i = 0; i<3; ++i)
		rect.right -= m_lcData.GetColumnWidth(i);

	// Rest für Spalte 
	m_lcData.SetColumnWidth(COL_ROOMS,rect.Width());

	// Daten laden 
	UpdateData(FALSE);

	return TRUE;
}

void CPageResources::OnNMDblclkLcRooms(NMHDR* pNMHDR, LRESULT* pResult)
{
	// LPNMITEMACTIVATE pNMItemActivate = reinterpret_cast<LPNMITEMACTIVATE>(pNMHDR);
	OnBnClickedBtModify();
	*pResult = 0;
}

void CPageResources::OnLvnItemchangedLcRooms(NMHDR* pNMHDR, LRESULT* pResult)
{
	// LPNMLISTVIEW pNMLV = reinterpret_cast<LPNMLISTVIEW>(pNMHDR);
	EnableControls();
	*pResult = 0;
}

void CPageResources::OnBnClickedBtDelete()
{
	int nSel = m_lcData.GetNextItem(-1, LVNI_SELECTED);
	if (nSel<0)
		return;

	CString strMsg, strRes, strName;
	strRes = m_lcData.GetItemText(nSel, COL_ID);
	strName = m_lcData.GetItemText(nSel, COL_NAME);

	strMsg.FormatMessage(IDP_QUERY_DELETE_RESOURCE,strRes.GetString(),strName.GetString());	
	if (AfxMessageBox(strMsg,MB_ICONQUESTION|MB_DEFBUTTON2|MB_YESNO)!=IDYES)
		return;

	CMapRaumListe mapRaumListe;
	theApp.LoadRoomMapFromSysVars(mapRaumListe);
	mapRaumListe.erase(strRes);
	theApp.SaveRoomMapToSysVars(mapRaumListe);

	// Anzeige aktualisieren
	UpdateData(FALSE);
	auto nMax = m_lcData.GetItemCount();
	m_lcData.SetItemState(min(nSel,nMax-1),LVIS_SELECTED|LVIS_FOCUSED, LVIS_SELECTED|LVIS_FOCUSED);
	m_lcData.EnsureVisible(min(nSel,nMax-1),FALSE);
}

void CPageResources::OnBnClickedBtModify()
{
	CMapRaumListe mapRaeume;
	theApp.LoadRoomMapFromSysVars(mapRaeume);

	int nSel = m_lcData.GetNextItem(-1, LVNI_SELECTED);
	if (nSel<0)
		return;

	CRessourceDlg dlg;
	dlg.m_strResName = m_lcData.GetItemText(nSel,0);
	dlg.m_strTitel = m_lcData.GetItemText(nSel,1);

	// Alle Räume ermitteln.
	auto& lst = theApp.m_lstSysVars;
	for (auto& e : lst)
	{
		if (!theApp.IsMatchingRoomPrefix(e.m_strName))
			continue;
		if (e.m_bDeleted)
			continue;
		dlg.m_lstAlleRaeume.emplace(e.m_strName);
	}

	// Alle zugeordneten ressourcen laden 
	for (auto const &r : mapRaeume[dlg.m_strResName].m_lstRaeume)
	{
		dlg.m_lstSelektierteRaeume.emplace(r);
	}

	if (dlg.DoModal()!=IDOK)
		return;

	// Suche den Raum
	auto it = mapRaeume.find(dlg.m_strResName);
	if (it==mapRaeume.end())
	{
		ASSERT(FALSE);
		return;
	}

	// Selektiete Räume übernehmen
	it->second.m_lstRaeume.clear();
	for (auto const e : dlg.m_lstSelektierteRaeume)
		it->second.m_lstRaeume.push_back(e);

	// Speichern
	theApp.SaveRoomMapToSysVars(mapRaeume);

	// Alles neu laden
	UpdateData(FALSE);
	m_lcData.SetItemState(nSel,LVIS_SELECTED|LVIS_FOCUSED, LVIS_SELECTED|LVIS_FOCUSED);
}

void CPageResources::OnKeydownLcData(NMHDR* pNMHDR, LRESULT* pResult)
{
	LPNMLVKEYDOWN pLVKeyDow = reinterpret_cast<LPNMLVKEYDOWN>(pNMHDR);
	if (pLVKeyDow->wVKey==VK_DELETE)
		OnBnClickedBtDelete();
	*pResult = 0;
}



void CPageResources::OnItemclickLcData(NMHDR* pNMHDR, LRESULT* pResult)
{
	LPNMHEADER phdr = reinterpret_cast<LPNMHEADER>(pNMHDR);
	if (phdr->iItem==COL_NAME || phdr->iItem==COL_ID || phdr->iItem==COL_ROOMS)
	{
		m_lcData.SortItems(SortFunc,phdr->iItem);
	}
	*pResult = 0;
}
