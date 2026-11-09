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

#pragma once

#include "Controls.h"

// CRaumDlg dialog

class CRaumDlg : public CDialogEx
{
	DECLARE_DYNAMIC(CRaumDlg)

public:
	CRaumDlg(bool bModify, SRaumDaten &raum, CWnd* pParent = nullptr);   // standard constructor
	virtual ~CRaumDlg();

// Dialog Data
#ifdef AFX_DESIGN_TIME
	enum { IDD = IDD_ROOM };
#endif
	CEditText m_edName;
	CComboBox m_cbMode;
	CEditDouble m_edTemp;
	CEditDouble m_edTempG;
	CEditInt m_edVBegin;
	CEditInt m_edVEnde;
	CEditInt m_edVMin;
	CEditDouble m_edFaktor;
	CComboBox m_cbChannel1, m_cbChannel2, m_cbVariable;
	CComboBox m_cbDevTyp;

	CString m_strNameAlt;
	bool m_bModify;
	SRaumDaten &m_raum;
	// Map interner Index aus ListBox zu RaumModus Kürzeln
	// H=Heizen, S=Schalten, HS=Heizen+Schalten
	std::map<int,CString> m_mapRaumModus;

protected:
	void SetDevType(const CString &strDevType);
	CString GetDevType();
	CString GetDevMode();
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support

	DECLARE_MESSAGE_MAP()
	virtual BOOL OnInitDialog();
	virtual void OnOK();
	afx_msg void OnCbnSelchangeCbChannel1();
	afx_msg void OnCbnSelchangeCbMode();
	afx_msg void OnBnClickedBtTest();
};
