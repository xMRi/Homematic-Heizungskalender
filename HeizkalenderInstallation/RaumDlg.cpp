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
#include "ScriptEngine.h"
#include "RaumDlg.h"


// CRaumDlg dialog

IMPLEMENT_DYNAMIC(CRaumDlg, CDialogEx)

CRaumDlg::CRaumDlg(bool bModify, SRaumDaten &raum, CWnd* pParent /*=nullptr*/)
	: CDialogEx(IDD_ROOM, pParent)
	, m_bModify{ bModify } 
	, m_raum{ raum }
{

}

CRaumDlg::~CRaumDlg()
{
}

void CRaumDlg::SetDevType(const CString& strDevType)
{
	DWORD dwMode = MAKELPARAM(strDevType[0], strDevType[1]);
	m_cbDevTyp.SetCurSel(0);
	for (int i = 0, n = m_cbDevTyp.GetCount(); i<n; ++i)
	{
		if (m_cbDevTyp.GetItemData(i)==dwMode)
		{
			m_cbDevTyp.SetCurSel(i);
			break;
		}
	}
}

CString CRaumDlg::GetDevType()
{
	CString strVal = _T("IP");
	int nSel = m_cbDevTyp.GetCurSel();
	if (nSel>=0)
	{
		// Ersten Buchstaben nehmen
		auto dwMode = m_cbDevTyp.GetItemData(nSel);
		strVal = CString{ TCHAR(LOWORD(dwMode)) } + TCHAR(HIWORD(dwMode));
	}
	return strVal;
}


CString CRaumDlg::GetDevMode()
{
	CString strVal = _T("H");
	int nSel = m_cbMode.GetCurSel();
	if (nSel>=0)
		// Substring nehmen
		strVal = m_mapRaumModus[nSel];		
	return strVal;
}

static void SelectCBEntry(CComboBox& cb, CString const& strAktor)
{
	cb.SetWindowText(strAktor);
	int nSel = cb.FindStringExact(-1, strAktor);
	if (nSel>=0)
		cb.SetCurSel(nSel);
}

void CRaumDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);
	DDX_Control(pDX, IDC_ED_NAME, m_edName);
	DDX_Control(pDX, IDC_ED_TEMP, m_edTemp);
	DDX_Control(pDX, IDC_ED_GRUNDTEMP, m_edTempG);
	DDX_Control(pDX, IDC_ED_VORZEIT_AN, m_edVBegin);
	DDX_Control(pDX, IDC_ED_VORZEIT_AUS, m_edVEnde);
	DDX_Control(pDX, IDC_ED_FAKTOR, m_edFaktor);
	DDX_Control(pDX, IDC_CB_AKTOR1, m_cbChannel1);
	DDX_Control(pDX, IDC_CB_AKTOR2, m_cbChannel2);

	if (pDX->m_bSaveAndValidate)
	{
		m_raum.m_strMode = GetDevMode();
		m_raum.m_strDevTyp = GetDevType();

		CString strAktor1, strAktor2;
		if (m_cbChannel1.IsWindowEnabled())
			DDX_Text(pDX,IDC_CB_AKTOR1,strAktor1);
		if (m_cbChannel2.IsWindowEnabled())
			DDX_Text(pDX,IDC_CB_AKTOR2,strAktor2);

		//// Im Modus Schalten und Heizen müssen beide Werte angegeben werden
		//if (m_raum.m_strMode==_T("HS") && (strAktor1.IsEmpty() || strAktor2.IsEmpty())) 
		//{
		//	AfxMessageBox(IDP_AKTOREN_FUER_HEIZENSCHALTEN_LEER);
		//	pDX->Fail();        // throws exception
		//}

		m_raum.m_strAktor = strAktor1;
		if (!strAktor2.IsEmpty())
		{
			m_raum.m_strAktor += _T(';');
			m_raum.m_strAktor += strAktor2;
		}
	}
	else if (m_cbMode.GetSafeHwnd())
	{
		// Raum Modus übersetzten
		int n = -1;
		for (auto const& e: m_mapRaumModus)
		{
			if (e.second==m_raum.m_strMode)
			{
				n = e.first;
				break;
			}
		}
		m_cbMode.SetCurSel(n);
		OnCbnSelchangeCbMode();

		// Modus Heizen/Schalten oder beides
		CString strAktor1, strAktor2;
		if (m_cbChannel1.IsWindowEnabled() && m_cbChannel2.IsWindowEnabled())
		{
			strAktor1 = StrValueByIndex(m_raum.m_strAktor, 0, _T(';'));
			int iPos = m_raum.m_strAktor.Find(_T(';'));
			if (iPos>=0)
				strAktor2 = m_raum.m_strAktor.Mid(iPos+1);
		}
		else if (m_cbChannel1.IsWindowEnabled())
		{
			strAktor1 = m_raum.m_strAktor;
		}
		else if (m_cbChannel2.IsWindowEnabled())
		{
			strAktor2 = m_raum.m_strAktor;
		}
		
		SelectCBEntry(m_cbChannel1, strAktor1);
		OnCbnSelchangeCbChannel1();
		SelectCBEntry(m_cbChannel2, strAktor2);
			
		// Device Typ setzen
		SetDevType(m_raum.m_strDevTyp); 
	}
	DDX_Control(pDX, IDC_CB_MODE, m_cbMode);
	DDX_Control(pDX, IDC_CB_GERAETETYP, m_cbDevTyp);

	DDX_Text(pDX,IDC_ED_NAME, m_raum.m_strName);
	DDX_EditDouble(pDX,IDC_ED_TEMP, m_raum.m_dblTemp);
	DDX_EditDouble(pDX,IDC_ED_GRUNDTEMP, m_raum.m_dblTempG);
	DDX_EditInt(pDX,IDC_ED_VORZEIT_AN, m_raum.m_iVBegin);
	DDX_EditInt(pDX,IDC_ED_VORZEIT_AUS, m_raum.m_iVEnde);
	DDX_EditDouble(pDX,IDC_ED_FAKTOR, m_raum.m_dblFaktor);
}

BEGIN_MESSAGE_MAP(CRaumDlg, CDialogEx)
	ON_BN_CLICKED(IDC_BT_TEST, &CRaumDlg::OnBnClickedBtTest)
	ON_CBN_SELCHANGE(IDC_CB_MODE, &CRaumDlg::OnCbnSelchangeCbMode)
	ON_CBN_SELCHANGE(IDC_CB_AKTOR1, &CRaumDlg::OnCbnSelchangeCbChannel1)
END_MESSAGE_MAP()


// CRaumDlg message handlers

BOOL CRaumDlg::OnInitDialog()
{
	CDialogEx::OnInitDialog();

	// Alten Namen merken
	m_strNameAlt = m_raum.m_strName;

	// Titel setzen
	CString strTitle;
	GetWindowText(strTitle);
	SetWindowText(strTitle + m_raum.m_strName);

	CString strMode{ CStringRes(IDS_RAUM_MODUS) };
	auto lstRaumModus = SplitString(strMode, _T('\t'));
	for (auto str : lstRaumModus)
	{
		int n = m_cbMode.AddString(StrValueByIndex(str,0,_T(';')));
		m_mapRaumModus[n] = StrValueByIndex(str, 1, _T(';'));
	}

	// IP- Thermostate-Aktoren-Gerätetyp (Kanal 1)
	// RT- Kennung Kanal Klassik-Thermostate-Aktoren-Gerätetyp (Kanal 4)
	// TC- Kennung Kanal Klassik-Thermostate-Aktoren-Gerätetyp (Kanal 4)
	// IT- Kennung Kanal Klassik-Thermostate-Aktoren-Gerätetyp (Kanal 4)
	// SW- Kennung Kanal Klassik-Schalter-Aktoren-Gerätetyp (Kanal 1 bzw. 2)
	//		HM-LC-Sw1-FM HM-LC-Sw1PBU-FM, HM-LC-Sw2-FM, HM-ES-PMSw1-DR HM-LC-Sw1-PCB
	//		Kennung Kanal IP-Schalter-Aktoren-Gerätetyp (Kanal 1)
	//		SW  Noch unerprobt
	CString strDevTyp{ CStringRes(IDS_RAUM_DEVTYP) };
	for (auto str : SplitString(strDevTyp,_T(';')))
	{
		int n = m_cbDevTyp.AddString(str);
		if (n>=0)
		{
			DWORD dwMode = MAKELPARAM(str[0],str[1]);
			m_cbDevTyp.SetItemData(n,dwMode);
		}
	}	

	m_edName.LimitText(64);
	m_edName.SetDisallowedCharList(UNERLAUBTE_ZEICHEN_FUER_RAEUME);	
	m_edTemp.SetMinMax(0,30);
	m_edTemp.SetPrecision(1);
	m_edTemp.CreateSpinBtnCtrl();
	m_edTempG.SetMinMax(0,30);
	m_edTempG.SetPrecision(1);
	m_edTempG.CreateSpinBtnCtrl();
	m_edVBegin.SetMinMax(-60*8,60*8);
	m_edVBegin.SetStepValue(5);
	m_edVBegin.CreateSpinBtnCtrl();
	m_edVEnde.SetMinMax(-60*8,60*8);
	m_edVEnde.SetStepValue(5);
	m_edVEnde.CreateSpinBtnCtrl();
	m_edFaktor.SetMinMax(0.25,3.0);
	m_edFaktor.SetPrecision(2);
	m_edFaktor.CreateSpinBtnCtrl();
	m_edFaktor.SetStepValue(0.25);
	
	// Endgültige Daten laden
	UpdateData(FALSE);
	return TRUE;  
}

struct {
	PCTSTR pszMode, pszParam;
} 
static const aGeraeteTypen[] = {
	_T("IP"), _T("SET_POINT_TEMPERATURE"),
	_T("RT"), _T("SET_TEMPERATURE"),
	_T("IT"), _T("SET_TEMPERATURE"),
	_T("TC"), _T("SETPOINT"),
	_T("SW"), _T("STATE"),
	_T("SW"), _T("TEMPERATURE"),
};

void CRaumDlg::OnBnClickedBtTest()
{
	// Schalten Testen können wir noch nicht
	int nSel = m_cbMode.GetCurSel();
	if (nSel==-1)
		return;

	CString strModus = 	GetDevMode();			

	// Es kann sein, dass der Typ manuell eingegeben wurde.
	CString strChannel;
	CString strParam;

	// Bestimme den gewählten Aktor
	CString strAktor1, strAktor2;
	auto GetData = [](CComboBox& cb, CString& strAktor)
		{
			if (cb.IsWindowEnabled())
			{
				int nSel = cb.GetCurSel();
				if (nSel<0)
					cb.GetWindowText(strAktor);
				else
					cb.GetLBText(nSel, strAktor);
			}
		};
	GetData(m_cbChannel1, strAktor1);
	GetData(m_cbChannel2, strAktor2);

	// Get Schalten oder Heizen
	bool bError = false;
	auto Test = [&](CString& strChannel, CString strMode, CString &strAllMessages)
		{
			// Wähle den Gerätetyp
			CString strDevTyp = _T("IP");
			int nSel = m_cbDevTyp.GetCurSel();
			if (nSel>=0)
			{
				// Ersten Buchstaben nehmen
				auto dwMode = m_cbDevTyp.GetItemData(nSel);
				strDevTyp = CString{ TCHAR(LOWORD(dwMode)) } + TCHAR(HIWORD(dwMode));
			}
			CString strParam;
			if (strMode==_T("S"))
				strDevTyp = _T("SW");
			for (auto const& e : aGeraeteTypen)
			{
				if (e.pszMode==strDevTyp)
				{
					strParam = e.pszParam;
					break;
				}
			}

			// Es können mehrere Aktoren durch Semikolon getrennt werden
			for (auto strCh : SplitString(strChannel, _T(';')))
			{
				// Suche den Channel
				CStringA strTestSkript =
					R"x(
var ch = dom.GetObject("%1%");
if (!ch){
  WriteLine("Kanal wurde nicht gefunden");
  WriteLine("");
} else {
!// Aktueller Wert der Einstellung 
  if ("%2%"!=""){
    var dp = ch.DPByHssDP("%2%");
    if (!dp) {
      WriteLine("Fehler# - Datenpunkt/Parameter \"%2%\" wurde nicht gefunden");
    } else {
	  WriteLine(dp.State());
    }
  }else{
    WriteLine("");
  }
  string dpNames = "%3%";
  if (dpNames!=""){
    string dpName;
	string strResult;
    foreach(dpName,dpNames){
	  var dp = ch.DPByHssDP(dpName);
	  if (!dp) {
	    strResult = "Fehler#  - Datenpunkt/Parameter \"" # dpName # "\" wurde nicht gefunden";
	  } else {
	    strResult = dp.State();
        break;
	  }
    }
    WriteLine(strResult);
  }
}
)x";
				if (strMode==_T("HS"))
					strParam = _T("");
				strTestSkript.Replace("%1%", CStringA{ strCh });
				strTestSkript.Replace("%2%", CStringA{ strParam });
				strTestSkript.Replace("%3%", strMode.Find(_T("H"))>=0 ? "ACTUAL_TEMPERATURE\tTEMPERATURE" : "");

				CStringA strOut;
				CScriptEngine engine;
				if (engine.ExecuteScript(strTestSkript, strOut))
				{
					CString strMsg;
					CString strOutW{ strOut };
					CString strResult1{ StrValueByIndex(strOutW,0,_T('\n')) },
							strResult2{ StrValueByIndex(strOutW,1,_T('\n')) };
					strResult1.Replace(_T("#"), _T("\r\n"));
					strResult2.Replace(_T("#"), _T("\r\n"));
					if (strMode==_T("S"))
					{
						// Schalter haben nur ein Ergebis AN/AUS
						if (IsBool(strResult1))
							strResult1 = StrValueByIndex(
								CStringRes(IDS_AN_AUS),
								StringToBool(StrValueByIndex(strOutW, 0, _T('\n'))),
								_T(';')
							);
					}
					strMsg.FormatMessage(strMode==_T("H") ? IDP_TEST_AKTOR_HEIZEN : 
										 strMode==_T("S") ? IDP_TEST_AKTOR_SCHALTEN :
											IDP_TEST_AKTOR_HEIZENSCHALTEN,
						strCh.GetString(),
						strResult1.GetString(), strResult2.GetString()
					);
					AppendTextWithDelimiter(strAllMessages, strMsg, _T("\n\n"));
				}
				else
				{
					AppendTextWithDelimiter(strAllMessages, engine.GetLastErrorText(), _T("\n\n"));
					bError = true;
				}
			}
		};
	
	CString strAllMessages;
	Test(strAktor1, strModus, strAllMessages);
	Test(strAktor2, _T("S"), strAllMessages);
	if (!strAllMessages.IsEmpty())
		AfxMessageBox(strAllMessages);
}


void CRaumDlg::OnCbnSelchangeCbMode()
{
	int nSel = m_cbMode.GetCurSel();
	if (nSel<0)
		return;

	CString strModus = 	GetDevMode();			
	m_cbChannel1.EnableWindow(strModus.Find(_T("H"))>=0);
	m_cbChannel2.EnableWindow(strModus.Find(_T("S"))>=0);

	auto Clear = [](CComboBox& cb)
		{
			if (!cb.IsWindowEnabled())
				cb.SetCurSel(-1);				
		};
	Clear(m_cbChannel1);
	Clear(m_cbChannel2);

	// Controls enablen/disable je nach Modus
	bool bModusHeizen = strModus==_T("H");
	bool bModusHeizenSchalten = strModus==_T("HS");
	m_edTemp.EnableWindow(bModusHeizen || bModusHeizenSchalten);
	m_edTempG.EnableWindow(bModusHeizen);
	m_edFaktor.EnableWindow(bModusHeizen || bModusHeizenSchalten);
	if (!bModusHeizen)
		SetDevType(_T("SW"));
	m_cbDevTyp.EnableWindow(bModusHeizen);

	// Devices laden listen Löschen und alte Werte erhalten
	CString strAktor1, strAktor2;
	m_cbChannel1.GetWindowText(strAktor1);
	m_cbChannel1.ResetContent();
	m_cbChannel2.GetWindowText(strAktor2);
	m_cbChannel2.ResetContent();
	auto const &lst = theApp.m_lstDevices;
	for (auto const& e : lst)
	{
		// Wir müssen auf doppelte Namen achten.
		if (e.ChannelTypeHeizung())
		{
			// Entweder benötigen wir die Soll-Temperatur für den Modus Heizen oder die Ist-Temperatur für den Modus Heizen+Schalten. 
			if ((strModus==_T("H") && e.IsSetPointTemperature()) ||
				(strModus==_T("HS") && e.IsActualTemperature()))
			{
				if (m_cbChannel1.FindStringExact(-1, e.m_strName)==-1)
					m_cbChannel1.AddString(e.m_strName);
			}
		}
		else 
		{
			if (e.IsState() && e.CanWrite())
			{
				if (m_cbChannel2.FindStringExact(-1, e.m_strName)==-1)
					m_cbChannel2.AddString(e.m_strName);
			}
		}
	}
	SelectCBEntry(m_cbChannel1, strAktor1);
	OnCbnSelchangeCbChannel1();
	SelectCBEntry(m_cbChannel2, strAktor2);
}

void CRaumDlg::OnOK()
{
	// Daten laden
	if (!UpdateData(TRUE))
		return;

	// Ein Name muss angegeben werden
	if (m_raum.m_strName.IsEmpty())
	{
		AfxMessageBox(IDP_RAUM_NAME_FEHLT);
		return;
	}

	// Prüfen ob der Name geändert wurde und ob wir ein Duplikat haben
	if (!m_bModify || (m_bModify && m_strNameAlt!=m_raum.m_strName))
	{
		// Prüfe ob der Name exisitert 
		if (theApp.m_lstSysVars.Find(theApp.AddRoomPrefix(m_raum.m_strName)))
		{
			CString strMsg;
			strMsg.FormatMessage(IDP_RAUM_NAME_EXISTIERT, m_raum.m_strName.GetString());
			AfxMessageBox(strMsg);
			return;
		}
	}

	CDialogEx::OnOK();
}

void CRaumDlg::OnCbnSelchangeCbChannel1()
{
	// Wenn wir den Channel 1 benutzen, dann ist das entweder ein Temperatursensor, oder ein Aktor,
	// der über  SetPointTemperature verfügt.
	int nSel = m_cbChannel1.GetCurSel();
	if (nSel<0)
		return;

	CString strChannel;
	m_cbChannel1.GetLBText(nSel,strChannel);

	// Suche den Channel. Achte darauf wenn wir Schalten und Heizen, dass wir den Kanal nehmen.
	CString strModus{GetDevMode()};
	if (strModus==_T("S"))
		// Im Schaltmods verlassen wir das hier einfach.
		return;

	// SUche einen passenden Device
	CDataDevice const* pDev = nullptr;
	for (const auto& e : theApp.m_lstDevices)
	{
		if (!e.m_bDeleted && e.m_strName==strChannel && 
			((strModus==_T("H") && e.IsSetPointTemperature()) || 
			 (strModus==_T("HS") && e.IsActualTemperature())))
		{
			pDev = &e;
			break;
		}
	}
	if (!pDev)
		return;

	// Wir kennen nun den Device. Holle den Datapoint und dort den hinteren Part
	CString strDataPoint{ pDev->m_strDataPoint };
	CString strParam{ StrValueByIndex(strDataPoint,2,_T('.')) };

	// IP- Thermostate-Aktoren-Gerätetyp (Kanal 1)
	//	SET_POINT_TEMPERATURE, SETPOINT
	// RT- Kennung Kanal Klassik-Thermostate-Aktoren-Gerätetyp (Kanal 4)
	//	SET_TEMPERATURE, 
	// TC- Kennung Kanal Klassik-Thermostate-Aktoren-Gerätetyp (Kanal 4)
	//  SET_POINT
	// IT- Kennung Kanal Klassik-Thermostate-Aktoren-Gerätetyp (Kanal 4)
	// SW- Kennung Kanal Schalter-Aktoren-Gerätetyp (IP+Klassik Kanal 1, 2 oder 3)
	CString strType{ _T("SW") };
	for (auto const& e : aGeraeteTypen)
	{
		if (strParam.CompareNoCase(e.pszParam)==0)
		{
			strType = e.pszMode;
			break;
		}
	}

	// Suche und setze diesen Mode
	SetDevType(strType);
}
